-- Universidad Horizonte: integridad contextual, temporal e historica (PostgreSQL 17).

BEGIN;
SET LOCAL search_path TO public;

-- Los instantes ficticios usan UTC-06:00; se fija ese desplazamiento al obtener la fecha academica,
-- sin depender del TimeZone de la sesion.
CREATE OR REPLACE FUNCTION public.uh_fecha_academica(p_instante TIMESTAMPTZ)
RETURNS DATE LANGUAGE sql IMMUTABLE STRICT AS $$
    SELECT (p_instante AT TIME ZONE INTERVAL '-06:00')::DATE;
$$;

-- Reconstruye el plan por traslados; el destino rige desde el instante exacto del cambio.
CREATE OR REPLACE FUNCTION public.uh_plan_aplicable(
    p_id_admision INTEGER, p_instante TIMESTAMPTZ
) RETURNS INTEGER
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(
        (SELECT t.id_version_origen
           FROM public.traslado_plan AS t
          WHERE t.id_admision = p_id_admision AND t.fecha > p_instante
          ORDER BY t.fecha, t.id_traslado LIMIT 1),
        (SELECT a.id_version_plan
           FROM public.admision AS a WHERE a.id_admision = p_id_admision)
    );
$$;
CREATE OR REPLACE FUNCTION public.uh_version_utilizada(
    p_solicitud INTEGER, p_version INTEGER
) RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.solicitud_matricula s
        WHERE s.id_solicitud=p_solicitud AND
             (s.id_version_plan_evaluada=p_version OR EXISTS (
                 SELECT 1 FROM public.historial_solicitud h
                 WHERE h.id_solicitud=s.id_solicitud AND h.tipo_evento='transicion'
                   AND h.estado_nuevo='matriculada'
                   AND public.uh_plan_aplicable(s.id_admision,h.fecha_evento)=p_version
             ))
    );
$$;


-- El bloqueo comun se adquiere antes de los bloqueos por fila para reducir conflictos de orden
-- entre sesiones.
CREATE OR REPLACE FUNCTION public.uh_serializar_contexto()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    -- Se rechazan REPEATABLE READ y SERIALIZABLE para releer el estado tras esperar el bloqueo.
    IF current_setting('transaction_isolation') NOT IN ('read committed','read uncommitted') THEN
        RAISE EXCEPTION 'La integridad entre relaciones requiere READ COMMITTED'
            USING ERRCODE = '25001';
    END IF;
    PERFORM pg_advisory_xact_lock(4301, 3);
    IF TG_TABLE_NAME IN ('grupo','solicitud_matricula') AND TG_OP IN ('INSERT','UPDATE') THEN
        PERFORM set_config('universidad.auditoria_' || TG_TABLE_NAME || '_' || lower(TG_OP),'pendiente',TRUE);
        IF TG_TABLE_NAME='grupo' AND TG_OP='UPDATE' THEN
            PERFORM set_config('universidad.claves_grupo','{}',TRUE);
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

-- Controles inmediatos de identidad, historial y transiciones, previos a la validacion diferida.
CREATE OR REPLACE FUNCTION public.uh_bloquear_contexto()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_grupo_nuevo INTEGER;
    v_grupo_anterior INTEGER;
    v_version_nueva INTEGER;
    v_curso_nuevo TEXT;
    v_comprobar BOOLEAN := TRUE;
BEGIN
    -- En una actualizacion curricular tambien se comprueba el contexto de destino.
    IF TG_OP = 'UPDATE' THEN
        IF TG_TABLE_NAME = 'requisito_curso' THEN
            v_version_nueva := NEW.id_version_plan;
            v_curso_nuevo := NEW.codigo_curso_objetivo;
        ELSIF TG_TABLE_NAME = 'participacion_plan' THEN
            v_version_nueva := NEW.id_version_plan;
        END IF;
    END IF;
    -- La cancelacion debe resultar de una transicion auditable, no de un alta directa.
    IF TG_TABLE_NAME='grupo' AND TG_OP='INSERT' THEN
        IF NEW.estado_oferta='cancelada' THEN
            RAISE EXCEPTION 'Una oferta cancelada requiere alta previa y transicion auditada'
                USING ERRCODE='23514', CONSTRAINT='uh_grupo_cancelacion_sin_historia';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'solicitud_matricula' THEN
        IF ROW(NEW.id_solicitud,NEW.id_admision,NEW.id_grupo,
               NEW.id_solicitud_anterior,NEW.id_version_plan_evaluada,NEW.fecha_solicitud)
           IS DISTINCT FROM
           ROW(OLD.id_solicitud,OLD.id_admision,OLD.id_grupo,
               OLD.id_solicitud_anterior,OLD.id_version_plan_evaluada,OLD.fecha_solicitud) THEN
            RAISE EXCEPTION 'La identidad y el contexto inicial de la solicitud son historicos'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_contexto_inmutable';
        END IF;
    END IF;

    -- Los traslados y reconocimientos registrados no pueden reescribirse ni eliminarse.
    IF TG_TABLE_NAME IN ('traslado_plan', 'reconocimiento_academico')
       AND TG_OP IN ('UPDATE','DELETE') THEN
        RAISE EXCEPTION 'El traslado o reconocimiento registrado es inmutable'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_trayectoria_inmutable';
    END IF;

    IF TG_TABLE_NAME = 'excepcion_requisito' AND TG_OP IN ('UPDATE','DELETE') THEN
        RAISE EXCEPTION 'Una autorizacion de excepcion registrada es inmutable'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_excepcion_inmutable';
    END IF;

    -- Una regla curricular sin vigencia propia no puede alterarse si ya afecto solicitudes de esa
    -- version y curso.
    IF TG_TABLE_NAME = 'requisito_curso' THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (
                SELECT 1 FROM public.solicitud_matricula s
                JOIN public.grupo g ON g.id_grupo = s.id_grupo
                WHERE public.uh_version_utilizada(s.id_solicitud,NEW.id_version_plan)
                  AND g.codigo_curso = NEW.codigo_curso_objetivo
            ) THEN
                RAISE EXCEPTION 'No se puede incorporar retroactivamente una regla a solicitudes ya evaluadas'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_requisito_historico';
            END IF;
        ELSIF TG_OP IN ('UPDATE','DELETE') THEN
            IF EXISTS (
                SELECT 1 FROM public.solicitud_matricula s
                JOIN public.grupo g ON g.id_grupo = s.id_grupo
                WHERE (public.uh_version_utilizada(s.id_solicitud,OLD.id_version_plan)
                       AND g.codigo_curso = OLD.codigo_curso_objetivo)
                   OR (public.uh_version_utilizada(s.id_solicitud,v_version_nueva)
                       AND g.codigo_curso = v_curso_nuevo)
            ) THEN
                RAISE EXCEPTION 'No se puede reescribir una regla utilizada historicamente'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_requisito_historico';
            END IF;
        END IF;
    END IF;

    -- La participacion de una version utilizada por solicitudes queda protegida frente a cambios
    -- retroactivos.
    IF TG_TABLE_NAME = 'participacion_plan' THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (SELECT 1 FROM public.solicitud_matricula sm
                       WHERE public.uh_version_utilizada(sm.id_solicitud,NEW.id_version_plan)) THEN
                RAISE EXCEPTION 'La version utilizada no admite participaciones nuevas retroactivas'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_participacion_historica';
            END IF;
        ELSIF TG_OP IN ('UPDATE','DELETE') THEN
            IF EXISTS (SELECT 1 FROM public.solicitud_matricula sm
                       WHERE public.uh_version_utilizada(sm.id_solicitud,OLD.id_version_plan)
                          OR public.uh_version_utilizada(sm.id_solicitud,v_version_nueva)) THEN
                RAISE EXCEPTION 'La participacion curricular usada historicamente no puede reescribirse'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_participacion_historica';
            END IF;
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'periodo_academico' AND TG_OP = 'UPDATE' THEN
      IF (NEW.fecha_inicio,NEW.fecha_finalizacion) IS DISTINCT FROM
         (OLD.fecha_inicio,OLD.fecha_finalizacion) THEN
        IF EXISTS (
            SELECT 1 FROM public.grupo g
            JOIN public.solicitud_matricula sm ON sm.id_grupo = g.id_grupo
            WHERE g.id_periodo = OLD.id_periodo
        ) THEN
            RAISE EXCEPTION 'No se pueden reescribir fechas lectivas de un periodo con decisiones registradas'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_periodo_historico';
        END IF;
      END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'admision' THEN
        IF (NEW.numero_institucional,NEW.id_sede,NEW.fecha_ingreso) IS DISTINCT FROM
           (OLD.numero_institucional,OLD.id_sede,OLD.fecha_ingreso)
           AND (EXISTS (SELECT 1 FROM public.solicitud_matricula s
                        WHERE s.id_admision = OLD.id_admision)
                OR EXISTS (SELECT 1 FROM public.traslado_plan t
                           WHERE t.id_admision = OLD.id_admision)
                OR EXISTS (SELECT 1 FROM public.reconocimiento_academico r
                           WHERE r.id_admision = OLD.id_admision)) THEN
            RAISE EXCEPTION 'La identidad y sede de una admision con antecedentes no pueden reescribirse'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_admision_historia';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'grupo' THEN
        IF (NEW.numero_grupo,NEW.codigo_curso,NEW.id_periodo,
            NEW.id_sede,NEW.modalidad) IS DISTINCT FROM
           (OLD.numero_grupo,OLD.codigo_curso,OLD.id_periodo,
            OLD.id_sede,OLD.modalidad)
           AND (EXISTS (SELECT 1 FROM public.solicitud_matricula s
                        WHERE s.id_grupo = OLD.id_grupo)
                OR EXISTS (SELECT 1 FROM public.historial_oferta h
                           WHERE h.id_grupo = OLD.id_grupo)) THEN
            RAISE EXCEPTION 'No se puede reescribir el contexto de una oferta historica'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_grupo_contexto_historico';
        END IF;
    END IF;

    -- No se reescriben creditos ni escuela de un curso utilizado en decisiones historicas.
    IF TG_TABLE_NAME = 'curso' AND TG_OP = 'UPDATE' THEN
        IF (NEW.cantidad_creditos,NEW.id_escuela)
            IS DISTINCT FROM (OLD.cantidad_creditos,OLD.id_escuela)
           AND (
              EXISTS (
                SELECT 1 FROM public.participacion_plan p
                WHERE p.codigo_curso=OLD.codigo_institucional
                  AND (EXISTS (SELECT 1 FROM public.admision a
                               WHERE a.id_version_plan=p.id_version_plan)
                       OR EXISTS (SELECT 1 FROM public.solicitud_matricula s
                                  WHERE s.id_version_plan_evaluada=p.id_version_plan)
                       OR EXISTS (SELECT 1 FROM public.traslado_plan t
                                  WHERE t.id_version_origen=p.id_version_plan
                                     OR t.id_version_destino=p.id_version_plan))
              )
              OR EXISTS (
                SELECT 1 FROM public.grupo g
                WHERE g.codigo_curso=OLD.codigo_institucional
                  AND (EXISTS (SELECT 1 FROM public.solicitud_matricula sm
                               WHERE sm.id_grupo=g.id_grupo)
                       OR EXISTS (SELECT 1 FROM public.historial_oferta h
                                  WHERE h.id_grupo=g.id_grupo))
              )
           ) THEN
            RAISE EXCEPTION 'No se alteran creditos o escuela de un curso utilizado historicamente'
                USING ERRCODE='23514', CONSTRAINT='uh_curso_historico';
        END IF;
    END IF;

    -- Se preservan sede y ubicacion de espacios usados historicamente; la capacidad tiene una
    -- validacion independiente.
    IF TG_TABLE_NAME = 'espacio' AND TG_OP = 'UPDATE' THEN
        IF (NEW.id_sede,NEW.ubicacion) IS DISTINCT FROM
           (OLD.id_sede,OLD.ubicacion)
           AND EXISTS (
               SELECT 1 FROM public.bloque_horario b
               JOIN public.grupo g ON g.id_grupo=b.id_grupo
               WHERE b.id_espacio=OLD.id_espacio
                 AND (EXISTS (SELECT 1 FROM public.solicitud_matricula sm
                              WHERE sm.id_grupo=g.id_grupo)
                      OR EXISTS (SELECT 1 FROM public.historial_oferta h
                                 WHERE h.id_grupo=g.id_grupo))
           ) THEN
            RAISE EXCEPTION 'La sede y ubicacion de un espacio historico son estables'
                USING ERRCODE='23514', CONSTRAINT='uh_espacio_historico';
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'version_plan_estudios' AND TG_OP = 'UPDATE' THEN
      IF (NEW.id_carrera, NEW.inicio_vigencia) IS DISTINCT FROM
         (OLD.id_carrera, OLD.inicio_vigencia) THEN
        IF EXISTS (SELECT 1 FROM public.admision a
                   WHERE a.id_version_plan = OLD.id_version_plan)
           OR EXISTS (SELECT 1 FROM public.traslado_plan t
                      WHERE t.id_version_origen = OLD.id_version_plan
                         OR t.id_version_destino = OLD.id_version_plan)
           OR EXISTS (SELECT 1 FROM public.reconocimiento_academico r
                      WHERE r.id_version_plan = OLD.id_version_plan)
           OR EXISTS (SELECT 1 FROM public.solicitud_matricula s
                      WHERE s.id_version_plan_evaluada = OLD.id_version_plan) THEN
            RAISE EXCEPTION 'Los datos curriculares de una version utilizada historicamente son estables'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_version_identidad_historica';
        END IF;
      END IF;
    END IF;

    -- Los cambios de bloques o docentes no deben alterar el contexto de decisiones anteriores, que
    -- carece de versiones propias.
    IF TG_TABLE_NAME IN ('bloque_horario','grupo_docente') THEN
        IF TG_OP = 'INSERT' THEN
            v_grupo_nuevo := NEW.id_grupo;
        ELSIF TG_OP = 'DELETE' THEN
            v_grupo_anterior := OLD.id_grupo;
        ELSE
            v_grupo_nuevo := NEW.id_grupo;
            v_grupo_anterior := OLD.id_grupo;
        END IF;
        IF TG_OP = 'UPDATE' THEN
            v_comprobar := NEW IS DISTINCT FROM OLD;
        END IF;
        IF v_comprobar THEN
            IF EXISTS (
                SELECT 1 FROM public.grupo g
                WHERE g.id_grupo IN (v_grupo_nuevo,v_grupo_anterior)
                  AND (EXISTS (SELECT 1 FROM public.solicitud_matricula sm
                               WHERE sm.id_grupo = g.id_grupo)
                       OR (g.estado_oferta = 'cancelada' AND EXISTS (
                           SELECT 1 FROM public.historial_oferta h
                           WHERE h.id_grupo = g.id_grupo AND h.tipo_cambio = 'apertura')))
            ) THEN
                RAISE EXCEPTION 'No se pueden reescribir bloques o docentes de una oferta con antecedentes'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_oferta_contexto_historico';
            END IF;
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP = 'INSERT' THEN
        IF NEW.estado IN ('retirada', 'anulada') THEN
            RAISE EXCEPTION 'Retiro y anulacion requieren una transicion desde solicitud existente'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_estado_inicial';
        END IF;
        IF NEW.momento_transicion IS NOT NULL THEN
            RAISE EXCEPTION 'El registro inicial no representa una transicion posterior'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_momento_inicial';
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP = 'UPDATE' THEN
        IF NEW.estado IS NOT DISTINCT FROM OLD.estado
           AND OLD.razon_rechazo_espera IS NOT NULL
           AND NEW.razon_rechazo_espera IS DISTINCT FROM OLD.razon_rechazo_espera THEN
            RAISE EXCEPTION 'El motivo de una decision registrada requiere una transicion documentada'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_razon_historica';
        END IF;
        IF OLD.orden_espera IS NOT NULL
           AND NEW.orden_espera IS DISTINCT FROM OLD.orden_espera THEN
            RAISE EXCEPTION 'No se puede reescribir el orden historico de espera'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_espera_orden_inmutable';
        END IF;
        -- No se reutiliza una posicion de espera historica al ingresar de nuevo en la cola.
        IF OLD.estado <> 'en_espera' AND NEW.estado = 'en_espera'
           AND OLD.orden_espera IS NOT NULL THEN
            RAISE EXCEPTION 'Reingresar a la cola requiere una solicitud nueva'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_espera_reingreso_historico';
        END IF;
        IF NEW.estado IS NOT DISTINCT FROM OLD.estado
           AND NEW.momento_transicion IS DISTINCT FROM OLD.momento_transicion THEN
            RAISE EXCEPTION 'El momento de transicion requiere un cambio de estado'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_momento_inmutable';
        END IF;
    END IF;

    -- La primera asignacion de resultados se permite solo despues del cierre lectivo.
    IF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP IN ('INSERT','UPDATE') THEN
        v_comprobar := (TG_OP = 'INSERT');
        IF TG_OP = 'UPDATE' THEN
            v_comprobar := (NEW.calificacion IS DISTINCT FROM OLD.calificacion
                OR NEW.resultado_academico IS DISTINCT FROM OLD.resultado_academico);
        END IF;
        IF v_comprobar AND NEW.estado IN ('matriculada','retirada','anulada')
           AND (NEW.calificacion IS NOT NULL OR NEW.resultado_academico IS NOT NULL)
           AND EXISTS (
               SELECT 1 FROM public.grupo g
               JOIN public.periodo_academico p ON p.id_periodo = g.id_periodo
               WHERE g.id_grupo = NEW.id_grupo
                 AND p.fecha_finalizacion >=
                     public.uh_fecha_academica(clock_timestamp())
           ) THEN
            RAISE EXCEPTION 'El resultado academico requiere finalizar el periodo lectivo'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_resultado_antes_fin_periodo';
        END IF;
    END IF;

    -- Los rechazos se conservan aunque la admision no habilite matricula ni espera.
    IF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP = 'INSERT' THEN
        IF NEW.estado IN ('matriculada', 'en_espera') AND NOT EXISTS (
            SELECT 1 FROM public.admision a
            WHERE a.id_admision = NEW.id_admision AND a.activa
        ) THEN
            RAISE EXCEPTION 'Una nueva matricula o espera requiere admision activa: %', NEW.id_admision
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_admision_activa';
        END IF;
    ELSIF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP = 'UPDATE' THEN
        IF NEW.estado IN ('matriculada', 'en_espera')
           AND NEW.estado IS DISTINCT FROM OLD.estado
           AND NOT EXISTS (
               SELECT 1 FROM public.admision a
               WHERE a.id_admision = NEW.id_admision AND a.activa
           ) THEN
            RAISE EXCEPTION 'La transicion a matricula o espera requiere admision activa: %', NEW.id_admision
                USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_admision_activa';
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP IN ('INSERT', 'UPDATE') THEN
        v_comprobar := NEW.estado = 'en_espera';
        IF TG_OP = 'UPDATE' THEN
            v_comprobar := v_comprobar
                AND NEW.estado IS DISTINCT FROM OLD.estado;
        END IF;
        IF v_comprobar THEN
            IF NOT EXISTS (SELECT 1 FROM public.grupo g
                           WHERE g.id_grupo = NEW.id_grupo
                             AND g.estado_oferta = 'abierta') THEN
                RAISE EXCEPTION 'No se incorpora a espera una oferta no abierta'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_espera_oferta_abierta';
            END IF;
        END IF;
        IF TG_OP = 'INSERT' THEN
            IF NEW.estado = 'matriculada' AND NOT EXISTS (
                SELECT 1 FROM public.grupo g
                WHERE g.id_grupo = NEW.id_grupo AND g.estado_oferta = 'abierta') THEN
                RAISE EXCEPTION 'No se confirma matricula en una oferta no abierta'
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_matricula_oferta_abierta';
            END IF;
        ELSIF NEW.estado = 'matriculada' AND (NEW.estado IS DISTINCT FROM OLD.estado
                                              OR NEW.id_grupo IS DISTINCT FROM OLD.id_grupo)
           AND NOT EXISTS (SELECT 1 FROM public.grupo g
                           WHERE g.id_grupo = NEW.id_grupo AND g.estado_oferta = 'abierta') THEN
            RAISE EXCEPTION 'No se confirma matricula en una oferta no abierta'
                USING ERRCODE = '23514', CONSTRAINT = 'uh_matricula_oferta_abierta';
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'solicitud_matricula' AND TG_OP = 'UPDATE' THEN
        IF NEW.estado IS DISTINCT FROM OLD.estado THEN
            IF NOT (
                (OLD.estado = 'matriculada' AND NEW.estado IN ('retirada','anulada'))
                OR (OLD.estado = 'en_espera' AND NEW.estado IN ('matriculada','rechazada','anulada'))
                OR (OLD.estado = 'rechazada' AND NEW.estado IN ('en_espera','matriculada','anulada'))
            ) THEN
                RAISE EXCEPTION 'Transicion academica no permitida: % a %', OLD.estado, NEW.estado
                    USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_transicion_valida';
            END IF;
            IF NEW.momento_transicion IS NOT DISTINCT FROM OLD.momento_transicion THEN
                NEW.momento_transicion := clock_timestamp();
            END IF;
        END IF;
    END IF;

    IF TG_TABLE_NAME='grupo' AND TG_OP='UPDATE' THEN
        IF NEW.id_grupo IS DISTINCT FROM OLD.id_grupo THEN
            PERFORM set_config('universidad.claves_grupo',
                (current_setting('universidad.claves_grupo')::JSONB ||
                 jsonb_build_object(NEW.id_grupo::TEXT,OLD.id_grupo))::TEXT,TRUE);
        END IF;
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

-- Los historiales son inmutables. Las transiciones se registran desde el hecho; la evaluacion de
-- espera es una excepcion explicita.
CREATE OR REPLACE FUNCTION public.uh_proteger_historial()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION 'Los eventos historicos registrados son inmutables'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_inmutable';
    END IF;
    IF TG_TABLE_NAME = 'historial_solicitud' THEN
        IF NEW.tipo_evento = 'evaluacion_espera' THEN
            RETURN NEW;
        END IF;
    END IF;
    IF pg_trigger_depth() < 2 THEN
        RAISE EXCEPTION 'El evento se registra mediante el cambio efectivo del hecho'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_evento_automatico';
    END IF;
    RETURN NEW;
END;
$$;

-- Los cambios de oferta requieren autor y motivo en el contexto transaccional
-- (universidad.autorizador y universidad.motivo).
CREATE OR REPLACE FUNCTION public.uh_registrar_cambio_oferta(
    nueva public.grupo, anterior public.grupo, operacion TEXT
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_aut INTEGER;
    v_motivo TEXT;
    v_id INTEGER;
    v_fecha TIMESTAMPTZ;
    v_tipo TEXT;
BEGIN
    -- instante_efectivo permite preparar eventos historicos ficticios; fuera de ese contexto se usa
    -- el reloj del servidor.
    v_fecha := COALESCE(
        NULLIF(current_setting('universidad.instante_efectivo', TRUE), '')::TIMESTAMPTZ,
        clock_timestamp()
    );
    IF operacion = 'INSERT' THEN
        IF nueva.estado_oferta <> 'abierta' THEN RETURN; END IF;
        v_tipo := 'apertura';
    ELSIF nueva.estado_oferta IS NOT DISTINCT FROM anterior.estado_oferta
          AND nueva.capacidad IS NOT DISTINCT FROM anterior.capacidad THEN
        RETURN;
    ELSE
        v_tipo := CASE nueva.estado_oferta
                    WHEN 'abierta' THEN 'apertura'
                    WHEN 'cerrada' THEN 'cierre'
                    ELSE 'cancelacion' END;
    END IF;

    v_aut := NULLIF(current_setting('universidad.autorizador', TRUE), '')::INTEGER;
    v_motivo := NULLIF(btrim(current_setting('universidad.motivo', TRUE)), '');
    IF v_aut IS NULL OR v_motivo IS NULL THEN
        RAISE EXCEPTION 'El cambio de oferta requiere autorizador y motivo en la transaccion'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_oferta_auditoria_obligatoria';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.persona_autorizadora
                   WHERE id_autorizador = v_aut) THEN
        RAISE EXCEPTION 'Autorizador de oferta inexistente: %', v_aut
            USING ERRCODE = '23503';
    END IF;

    IF operacion = 'INSERT' THEN
        SELECT COALESCE(MAX(id_cambio), 0) + 1 INTO v_id FROM public.historial_oferta;
        INSERT INTO public.historial_oferta
            (id_cambio, id_grupo, tipo_cambio, estado_anterior, estado_nuevo,
             fecha_cambio, motivo, id_responsable)
        VALUES (v_id, nueva.id_grupo, 'apertura', NULL,
                nueva.estado_oferta, v_fecha, v_motivo, v_aut);
    ELSIF nueva.estado_oferta IS DISTINCT FROM anterior.estado_oferta THEN
        SELECT COALESCE(MAX(id_cambio), 0) + 1 INTO v_id FROM public.historial_oferta;
        INSERT INTO public.historial_oferta
            (id_cambio, id_grupo, tipo_cambio, estado_anterior, estado_nuevo,
             fecha_cambio, motivo, id_responsable)
        VALUES (v_id, nueva.id_grupo, v_tipo, anterior.estado_oferta,
                nueva.estado_oferta, v_fecha, v_motivo, v_aut);
    END IF;
    IF operacion = 'UPDATE' THEN
        IF nueva.capacidad IS DISTINCT FROM anterior.capacidad THEN
            SELECT COALESCE(MAX(id_cambio), 0) + 1 INTO v_id FROM public.historial_oferta;
            INSERT INTO public.historial_oferta
                (id_cambio, id_grupo, tipo_cambio, cupo_anterior, cupo_nuevo,
                 fecha_cambio, motivo, id_responsable)
            VALUES (v_id, nueva.id_grupo, 'cambio_cupo', anterior.capacidad,
                    nueva.capacidad, v_fecha, v_motivo, v_aut);
        END IF;
    END IF;
    RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION public.uh_registrar_transicion_solicitud(
    nueva public.solicitud_matricula, anterior public.solicitud_matricula, operacion TEXT
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_id INTEGER;
    v_actor INTEGER;
    v_estado_previo TEXT;
    v_instante TIMESTAMPTZ;
BEGIN
    IF operacion = 'UPDATE' THEN
        IF nueva.estado IS NOT DISTINCT FROM anterior.estado THEN RETURN; END IF;
        v_estado_previo := anterior.estado;
        v_instante := COALESCE(nueva.momento_transicion, clock_timestamp());
    ELSE
        v_estado_previo := NULL;
        v_instante := CASE WHEN nueva.estado='matriculada' THEN COALESCE(
            NULLIF(current_setting('universidad.instante_adjudicacion',TRUE),'')::TIMESTAMPTZ,
            nueva.fecha_solicitud) ELSE nueva.fecha_solicitud END;
    END IF;
    v_actor := NULLIF(current_setting('universidad.autorizador', TRUE), '')::INTEGER;
    IF operacion = 'UPDATE' AND nueva.estado = 'anulada' AND v_actor IS NULL THEN
        RAISE EXCEPTION 'La anulacion administrativa requiere identificacion del actor'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_anulacion_actor';
    END IF;
    SELECT COALESCE(MAX(id_evento), 0) + 1 INTO v_id FROM public.historial_solicitud;
    INSERT INTO public.historial_solicitud
        (id_evento, id_solicitud, tipo_evento, estado_anterior, estado_nuevo,
         fecha_evento, motivo, id_actor)
    VALUES (
        v_id, nueva.id_solicitud, 'transicion',
        v_estado_previo,
        nueva.estado, v_instante,
        CASE WHEN nueva.estado IN ('rechazada','en_espera')
             THEN nueva.razon_rechazo_espera
             ELSE NULLIF(btrim(current_setting('universidad.motivo', TRUE)), '')
        END, v_actor
    );
    RETURN;
END;
$$;

-- La asignacion inicial de nota no crea correccion; los cambios posteriores conservan OLD/NEW y
-- requieren autorizacion.
CREATE OR REPLACE FUNCTION public.uh_registrar_cambio_calificacion(
    nueva public.solicitud_matricula, anterior public.solicitud_matricula, operacion TEXT
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_aut INTEGER;
    v_motivo TEXT;
    v_id INTEGER;
BEGIN
    IF nueva.calificacion IS NOT DISTINCT FROM anterior.calificacion
       AND nueva.resultado_academico IS NOT DISTINCT FROM anterior.resultado_academico THEN
        RETURN;
    END IF;
    IF anterior.calificacion IS NULL AND anterior.resultado_academico IS NULL
       AND NOT EXISTS (
           SELECT 1 FROM public.historial_correccion_calificacion h
           WHERE h.id_solicitud = nueva.id_solicitud
       ) THEN
        RETURN;
    END IF;
    v_aut := NULLIF(current_setting('universidad.autorizador', TRUE), '')::INTEGER;
    v_motivo := NULLIF(btrim(current_setting('universidad.motivo', TRUE)), '');
    IF v_aut IS NULL OR v_motivo IS NULL THEN
        RAISE EXCEPTION 'La correccion academica requiere autorizador y motivo'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_correccion_auditoria_obligatoria';
    END IF;
    SELECT COALESCE(MAX(id_correccion), 0) + 1 INTO v_id
      FROM public.historial_correccion_calificacion;
    INSERT INTO public.historial_correccion_calificacion
        (id_correccion, id_solicitud, calificacion_anterior, calificacion_nueva,
         resultado_anterior, resultado_nuevo, fecha_correccion, motivo, id_autorizador)
    VALUES (v_id, nueva.id_solicitud, anterior.calificacion, nueva.calificacion,
            anterior.resultado_academico, nueva.resultado_academico,
            clock_timestamp(), v_motivo, v_aut);
    RETURN;
END;
$$;

-- El estado historico usa la ultima transicion hasta el instante; los empates se ordenan por
-- id_evento.
CREATE OR REPLACE FUNCTION public.uh_estado_en_instante(
    p_id_solicitud INTEGER, p_instante TIMESTAMPTZ
) RETURNS TEXT LANGUAGE sql STABLE AS $$
    SELECT h.estado_nuevo
    FROM public.historial_solicitud h
    WHERE h.id_solicitud = p_id_solicitud
      AND h.tipo_evento = 'transicion'
      AND h.fecha_evento <= p_instante
    ORDER BY h.fecha_evento DESC,h.id_evento DESC
    LIMIT 1;
$$;

-- El estado historico de la oferta se reconstruye a partir de sus eventos, no del estado vigente.
CREATE OR REPLACE FUNCTION public.uh_oferta_en_instante(
    p_id_grupo INTEGER, p_instante TIMESTAMPTZ
) RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT COALESCE((
        SELECT h.estado_nuevo = 'abierta'
        FROM public.historial_oferta h
        WHERE h.id_grupo = p_id_grupo
          AND h.tipo_cambio <> 'cambio_cupo'
          AND h.fecha_cambio <= p_instante
        ORDER BY h.fecha_cambio DESC, h.id_cambio DESC LIMIT 1
    ), FALSE);
$$;

-- El cupo historico se obtiene del cambio posterior mas cercano o, si no existe, del cupo vigente.
CREATE OR REPLACE FUNCTION public.uh_cupo_en_instante(
    p_id_grupo INTEGER, p_instante TIMESTAMPTZ
) RETURNS INTEGER LANGUAGE sql STABLE AS $$
    SELECT COALESCE(
        (SELECT h.cupo_anterior
         FROM public.historial_oferta h
         WHERE h.id_grupo = p_id_grupo
           AND h.tipo_cambio = 'cambio_cupo'
           AND h.fecha_cambio > p_instante
         ORDER BY h.fecha_cambio, h.id_cambio LIMIT 1),
        (SELECT g.capacidad FROM public.grupo g WHERE g.id_grupo = p_id_grupo)
    );
$$;

-- No existe fecha de carga de la primera nota en el modelo: el cierre lectivo es un limite
-- temporal, no prueba de su registro.
CREATE OR REPLACE FUNCTION public.uh_resultado_en_instante(
    p_id_solicitud INTEGER, p_instante TIMESTAMPTZ
) RETURNS TEXT LANGUAGE sql STABLE AS $$
    SELECT CASE
        WHEN p.fecha_finalizacion >= public.uh_fecha_academica(p_instante)
          OR NOT EXISTS (
              SELECT 1 FROM public.historial_solicitud h
              WHERE h.id_solicitud = s.id_solicitud
                AND h.tipo_evento = 'transicion'
                AND h.estado_nuevo = 'matriculada'
                AND h.fecha_evento <= p_instante
          ) THEN NULL
        WHEN EXISTS (
            SELECT 1 FROM public.historial_correccion_calificacion h
            WHERE h.id_solicitud = p_id_solicitud
              AND h.fecha_correccion > p_instante
        ) THEN (
            SELECT h.resultado_anterior
            FROM public.historial_correccion_calificacion h
            WHERE h.id_solicitud = p_id_solicitud
              AND h.fecha_correccion > p_instante
            ORDER BY h.fecha_correccion,h.id_correccion LIMIT 1
        ) ELSE s.resultado_academico END
    FROM public.solicitud_matricula s
    JOIN public.grupo g ON g.id_grupo = s.id_grupo
    JOIN public.periodo_academico p ON p.id_periodo = g.id_periodo
    WHERE s.id_solicitud = p_id_solicitud;
$$;

-- La misma comprobacion de requisitos se utiliza al adjudicar y al reevaluar candidatos en espera.
CREATE OR REPLACE FUNCTION public.uh_requisitos_satisfechos(
    p_solicitud INTEGER, p_instante TIMESTAMPTZ
) RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT NOT EXISTS (
        SELECT 1 FROM public.solicitud_matricula s
        JOIN public.grupo g ON g.id_grupo = s.id_grupo
        JOIN public.requisito_curso r
          ON r.id_version_plan = public.uh_plan_aplicable(s.id_admision,p_instante)
         AND r.codigo_curso_objetivo = g.codigo_curso
        WHERE s.id_solicitud=p_solicitud
          AND NOT EXISTS (
              SELECT 1 FROM public.excepcion_requisito e
              WHERE e.id_solicitud = s.id_solicitud
                AND e.id_requisito = r.id_requisito
                AND e.fecha_autorizacion <= p_instante
          )
          AND NOT EXISTS (
              SELECT 1 FROM public.reconocimiento_academico rec
              WHERE rec.id_admision = s.id_admision
                AND rec.id_version_plan = public.uh_plan_aplicable(s.id_admision,p_instante)
                AND rec.codigo_curso_satisfecho = r.codigo_curso_exigido
                AND rec.fecha_resolucion <= p_instante
          )
          AND NOT EXISTS (
              SELECT 1 FROM public.solicitud_matricula aprob
              JOIN public.grupo ga ON ga.id_grupo = aprob.id_grupo
              JOIN public.periodo_academico pa ON pa.id_periodo = ga.id_periodo
              WHERE aprob.id_admision = s.id_admision
                AND ga.codigo_curso = r.codigo_curso_exigido
                AND pa.fecha_finalizacion < public.uh_fecha_academica(p_instante)
                AND public.uh_resultado_en_instante(
                      aprob.id_solicitud,p_instante) = 'aprobado'
          )
          AND NOT (
              r.tipo_requisito = 'Correquisito' AND EXISTS (
                  SELECT 1 FROM public.solicitud_matricula co
                  JOIN public.grupo gc ON gc.id_grupo = co.id_grupo
                  WHERE co.id_solicitud <> s.id_solicitud
                    AND co.id_admision = s.id_admision
                    AND gc.id_periodo = g.id_periodo
                    AND gc.codigo_curso = r.codigo_curso_exigido
                    AND public.uh_estado_en_instante(co.id_solicitud,p_instante)='matriculada'
              )
          )
    );
$$;

CREATE OR REPLACE FUNCTION public.uh_candidato_elegible(
    p_solicitud INTEGER, p_instante TIMESTAMPTZ
) RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT a.activa AND a.fecha_ingreso <= public.uh_fecha_academica(p_instante)
       AND public.uh_oferta_en_instante(g.id_grupo,p_instante)
       AND public.uh_requisitos_satisfechos(s.id_solicitud,p_instante)
       AND NOT EXISTS (
           SELECT 1 FROM public.solicitud_matricula otra
           JOIN public.admision oa ON oa.id_admision=otra.id_admision
           JOIN public.grupo og ON og.id_grupo=otra.id_grupo
           JOIN public.periodo_academico op ON op.id_periodo=og.id_periodo
           WHERE otra.id_solicitud<>s.id_solicitud
             AND oa.numero_institucional=a.numero_institucional
             AND public.uh_estado_en_instante(otra.id_solicitud,p_instante)='matriculada'
             AND ((og.codigo_curso=g.codigo_curso AND og.id_periodo=g.id_periodo)
                  OR EXISTS (
                      SELECT 1 FROM public.bloque_horario b
                      JOIN public.bloque_horario ob ON ob.id_grupo=og.id_grupo
                      WHERE b.id_grupo=g.id_grupo AND b.dia_semana=ob.dia_semana
                        AND b.hora_inicio<ob.hora_fin AND ob.hora_inicio<b.hora_fin
                        AND GREATEST(p.fecha_inicio,op.fecha_inicio)
                            + ((b.dia_semana-EXTRACT(ISODOW FROM
                                GREATEST(p.fecha_inicio,op.fecha_inicio))::INTEGER+7)%7)
                            <= LEAST(p.fecha_finalizacion,op.fecha_finalizacion)))
       )
    FROM public.solicitud_matricula s
    JOIN public.admision a ON a.id_admision=s.id_admision
    JOIN public.grupo g ON g.id_grupo=s.id_grupo
    JOIN public.periodo_academico p ON p.id_periodo=g.id_periodo
    WHERE s.id_solicitud=p_solicitud;
$$;

CREATE OR REPLACE FUNCTION public.uh_validar_integridad()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.admision a
        WHERE NOT EXISTS (SELECT 1 FROM public.contacto_estudiante c
                          WHERE c.numero_institucional=a.numero_institucional)
    ) THEN
        RAISE EXCEPTION 'El estudiante admitido requiere un medio de contacto'
            USING ERRCODE='23514', CONSTRAINT='uh_estudiante_contacto';
    END IF;

    -- Los intentos rechazados pueden preceder al ingreso; las adjudicaciones y esperas, no.
    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        JOIN public.solicitud_matricula s ON s.id_solicitud=h.id_solicitud
        JOIN public.admision a ON a.id_admision=s.id_admision
        WHERE h.tipo_evento='transicion'
          AND h.estado_nuevo IN ('matriculada','en_espera')
          AND public.uh_fecha_academica(h.fecha_evento) < a.fecha_ingreso
    ) THEN
        RAISE EXCEPTION 'Decision anterior al ingreso de la admision'
            USING ERRCODE='23514', CONSTRAINT='uh_solicitud_antes_ingreso';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.admision a
        JOIN public.version_plan_estudios v ON v.id_version_plan = a.id_version_plan
        WHERE NOT EXISTS (
            SELECT 1 FROM public.carrera_sede cs
             WHERE cs.id_carrera = v.id_carrera AND cs.id_sede = a.id_sede
        )
    ) THEN
        RAISE EXCEPTION 'Admision con carrera y sede incompatibles'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_admision_carrera_sede';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.traslado_plan t
        JOIN public.admision a ON a.id_admision = t.id_admision
        JOIN public.version_plan_estudios o ON o.id_version_plan = t.id_version_origen
        JOIN public.version_plan_estudios d ON d.id_version_plan = t.id_version_destino
        JOIN public.version_plan_estudios actual ON actual.id_version_plan = a.id_version_plan
        WHERE o.id_carrera <> d.id_carrera OR o.id_carrera <> actual.id_carrera
           OR public.uh_fecha_academica(t.fecha) < a.fecha_ingreso
           OR public.uh_fecha_academica(t.fecha) < d.inicio_vigencia
           OR (d.fin_vigencia IS NOT NULL
               AND public.uh_fecha_academica(t.fecha) > d.fin_vigencia)
           OR NOT EXISTS (SELECT 1 FROM public.carrera_sede cs
                          WHERE cs.id_carrera = o.id_carrera AND cs.id_sede = a.id_sede)
    ) THEN
        RAISE EXCEPTION 'Traslado entre carreras, sedes o fechas incompatibles'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_traslado_contexto';
    END IF;
    IF EXISTS (
        WITH orden AS (
            SELECT t.*, LAG(t.id_version_destino) OVER (
                       PARTITION BY t.id_admision ORDER BY t.fecha,t.id_traslado
                   ) AS destino_previo,
                   LAG(t.fecha) OVER (
                       PARTITION BY t.id_admision ORDER BY t.fecha,t.id_traslado
                   ) AS fecha_previa,
                   ROW_NUMBER() OVER (
                       PARTITION BY t.id_admision ORDER BY t.fecha DESC,t.id_traslado DESC
                   ) AS rn_desc
              FROM public.traslado_plan t
        )
        SELECT 1 FROM orden o
        JOIN public.admision a ON a.id_admision = o.id_admision
        WHERE (o.destino_previo IS NOT NULL AND o.id_version_origen <> o.destino_previo)
           OR (o.fecha_previa IS NOT NULL AND o.fecha <= o.fecha_previa)
           OR (o.rn_desc = 1 AND a.id_version_plan <> o.id_version_destino)
    ) THEN
        RAISE EXCEPTION 'Secuencia de traslados o version actual inconsistente'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_traslado_secuencia';
    END IF;

    -- La version inicial debe estar vigente al ingresar, aunque caduque posteriormente.
    IF EXISTS (
        SELECT 1 FROM public.admision a
        JOIN public.version_plan_estudios v ON v.id_version_plan = COALESCE(
            (SELECT t.id_version_origen FROM public.traslado_plan t
             WHERE t.id_admision = a.id_admision
             ORDER BY t.fecha, t.id_traslado LIMIT 1), a.id_version_plan)
        WHERE a.fecha_ingreso < v.inicio_vigencia
           OR (v.fin_vigencia IS NOT NULL AND a.fecha_ingreso > v.fin_vigencia)
    ) THEN
        RAISE EXCEPTION 'Version inicial fuera de su vigencia al ingresar'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_admision_vigencia_inicial';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.reconocimiento_academico r
        JOIN public.admision a ON a.id_admision = r.id_admision
        WHERE r.id_version_plan <> public.uh_plan_aplicable(r.id_admision, r.fecha_resolucion)
           OR public.uh_fecha_academica(r.fecha_resolucion) < a.fecha_ingreso
    ) THEN
        RAISE EXCEPTION 'Reconocimiento ajeno al plan historico de la admision'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_reconocimiento_trayectoria';
    END IF;

    -- Se conservan bloques y responsable de toda oferta que llego a publicarse.
    IF EXISTS (
        SELECT 1 FROM public.grupo g
        WHERE (g.estado_oferta = 'abierta'
               OR EXISTS (SELECT 1 FROM public.historial_oferta h
                          WHERE h.id_grupo = g.id_grupo AND h.tipo_cambio = 'apertura'))
          AND (NOT EXISTS (SELECT 1 FROM public.grupo_docente d
                            WHERE d.id_grupo = g.id_grupo AND d.rol = 'responsable')
               OR NOT EXISTS (SELECT 1 FROM public.bloque_horario b
                               WHERE b.id_grupo = g.id_grupo))
    ) THEN
        RAISE EXCEPTION 'Oferta abierta sin docente responsable o bloque horario'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_grupo_publicacion';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.bloque_horario b
        JOIN public.grupo g ON g.id_grupo = b.id_grupo
        LEFT JOIN public.espacio e ON e.id_espacio = b.id_espacio
        WHERE (b.es_presencial AND (g.modalidad = 'virtual'
               OR e.id_sede <> g.id_sede
               OR (g.estado_oferta <> 'cancelada' AND g.capacidad > e.capacidad)))
           OR (NOT b.es_presencial AND g.modalidad = 'presencial')
    ) THEN
        RAISE EXCEPTION 'Bloque incompatible con sede, modalidad o espacio fisico'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_bloque_espacio_contexto';
    END IF;

    -- El solapamiento espacial exige coincidencia efectiva de fecha lectiva, dia y franja horaria.
    IF EXISTS (
        SELECT 1 FROM public.bloque_horario b1
        JOIN public.bloque_horario b2 ON b1.id_bloque < b2.id_bloque
                  AND b1.id_espacio = b2.id_espacio
                  AND b1.dia_semana = b2.dia_semana
                  AND b1.hora_inicio < b2.hora_fin
                  AND b2.hora_inicio < b1.hora_fin
        JOIN public.grupo g1 ON g1.id_grupo = b1.id_grupo
        JOIN public.grupo g2 ON g2.id_grupo = b2.id_grupo
        JOIN public.periodo_academico p1 ON p1.id_periodo = g1.id_periodo
        JOIN public.periodo_academico p2 ON p2.id_periodo = g2.id_periodo
        WHERE b1.es_presencial AND b2.es_presencial
          AND g1.id_grupo <> g2.id_grupo
          AND g1.estado_oferta <> 'cancelada'
          AND g2.estado_oferta <> 'cancelada'
          AND p1.fecha_inicio <= p2.fecha_finalizacion
          AND p2.fecha_inicio <= p1.fecha_finalizacion
          AND GREATEST(p1.fecha_inicio, p2.fecha_inicio)
              + ((b1.dia_semana - EXTRACT(ISODOW FROM
                   GREATEST(p1.fecha_inicio, p2.fecha_inicio))::INTEGER + 7) % 7)
              <= LEAST(p1.fecha_finalizacion, p2.fecha_finalizacion)
    ) THEN
        RAISE EXCEPTION 'Espacio asignado a horarios lectivos incompatibles'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_espacio_solapamiento';
    END IF;

    -- La version se comprueba historicamente; la sede del grupo no tiene que coincidir con la de
    -- admision.
    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s
        JOIN public.admision a ON a.id_admision = s.id_admision
        JOIN public.grupo g ON g.id_grupo = s.id_grupo
        WHERE s.id_version_plan_evaluada <>
              public.uh_plan_aplicable(s.id_admision, s.fecha_solicitud)
          OR ((s.estado NOT IN ('rechazada', 'anulada')
               OR EXISTS (SELECT 1 FROM public.historial_solicitud h
                          WHERE h.id_solicitud = s.id_solicitud
                            AND h.tipo_evento = 'transicion'
                            AND h.estado_nuevo IN ('matriculada','en_espera')))
              AND NOT EXISTS (
              SELECT 1 FROM public.ventana_periodo v
              WHERE v.id_periodo = g.id_periodo
                AND (v.tipo_ventana = 'matricula'
                     OR (s.id_solicitud_anterior IS NOT NULL
                         AND v.tipo_ventana = 'modificacion'))
                AND s.fecha_solicitud >= v.inicio AND s.fecha_solicitud < v.fin
          ))
    ) THEN
        RAISE EXCEPTION 'Solicitud fuera de ventana o version de plan historica'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_contexto';
    END IF;

    -- La oferta debe estar publicada al adjudicar o entrar en espera; los cambios posteriores no
    -- modifican esa validez.
    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        JOIN public.solicitud_matricula s ON s.id_solicitud = h.id_solicitud
        WHERE h.tipo_evento = 'transicion'
          AND h.estado_nuevo IN ('matriculada','en_espera')
          AND NOT public.uh_oferta_en_instante(s.id_grupo,h.fecha_evento)
    ) THEN
        RAISE EXCEPTION 'Solicitud adjudicada antes de publicarse la oferta o cuando estaba cerrada'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_oferta_publicacion_historica';
    END IF;

    -- Se conserva el plan de solicitud y se recalcula el aplicable en cada evento de adjudicacion.

    -- La excepcion debe corresponder al requisito pertinente y haberse autorizado antes de
    -- matricular.
    IF EXISTS (
        SELECT 1 FROM public.excepcion_requisito e
        JOIN public.solicitud_matricula s ON s.id_solicitud = e.id_solicitud
        JOIN public.grupo g ON g.id_grupo = s.id_grupo
        JOIN public.requisito_curso r ON r.id_requisito = e.id_requisito
        WHERE r.id_version_plan IS DISTINCT FROM public.uh_plan_aplicable(
                  s.id_admision,e.fecha_autorizacion)
           OR r.codigo_curso_objetivo <> g.codigo_curso
    ) THEN
        RAISE EXCEPTION 'Excepcion ajena al requisito, curso o version evaluada'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_excepcion_contexto';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.excepcion_requisito e
        WHERE EXISTS (
            SELECT 1 FROM public.historial_solicitud h
            WHERE h.id_solicitud = e.id_solicitud
              AND h.tipo_evento = 'transicion' AND h.estado_nuevo = 'matriculada'
            GROUP BY h.id_solicitud
            HAVING e.fecha_autorizacion > MIN(h.fecha_evento)
        )
    ) THEN
        RAISE EXCEPTION 'Excepcion autorizada despues de confirmar la matricula'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_excepcion_temporal';
    END IF;

    -- Convencion del cambio de grupo: retiro de origen y matricula de destino comparten instante
    -- efectivo y deben confirmarse en una misma transaccion. La igualdad de fechas no garantiza por
    -- si sola la atomicidad.
    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s
        JOIN public.solicitud_matricula ant ON ant.id_solicitud = s.id_solicitud_anterior
        JOIN public.grupo g ON g.id_grupo = s.id_grupo
        JOIN public.grupo ga ON ga.id_grupo = ant.id_grupo
        WHERE s.id_admision <> ant.id_admision
           OR g.codigo_curso <> ga.codigo_curso OR g.id_periodo <> ga.id_periodo
           OR s.id_grupo = ant.id_grupo OR s.fecha_solicitud < ant.fecha_solicitud
           OR NOT EXISTS (
                SELECT 1 FROM public.historial_solicitud h
                WHERE h.id_solicitud = ant.id_solicitud
                  AND h.tipo_evento = 'transicion' AND h.estado_nuevo = 'matriculada'
                  AND h.fecha_evento <= s.fecha_solicitud
                  AND NOT EXISTS (
                      SELECT 1 FROM public.historial_solicitud posterior
                      WHERE posterior.id_solicitud = ant.id_solicitud
                        AND posterior.tipo_evento = 'transicion'
                        AND posterior.fecha_evento < s.fecha_solicitud
                        AND (posterior.fecha_evento, posterior.id_evento)
                            > (h.fecha_evento, h.id_evento)
                  )
           )
           OR EXISTS (
                SELECT 1 FROM public.historial_solicitud destino
                WHERE destino.id_solicitud=s.id_solicitud
                  AND destino.tipo_evento='transicion' AND destino.estado_nuevo='matriculada'
                  AND NOT EXISTS (
                      SELECT 1 FROM public.historial_solicitud origen
                      JOIN public.ventana_periodo v ON v.id_periodo=g.id_periodo
                      WHERE origen.id_solicitud=ant.id_solicitud
                        AND origen.tipo_evento='transicion' AND origen.estado_anterior='matriculada'
                        AND origen.estado_nuevo='retirada' AND origen.fecha_evento=destino.fecha_evento
                        AND v.tipo_ventana='modificacion'
                        AND destino.fecha_evento>=v.inicio AND destino.fecha_evento<v.fin
                  )
           )
    ) THEN
        RAISE EXCEPTION 'Antecedente de cambio de grupo incompatible'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_antecedente';
    END IF;
    IF EXISTS (
        WITH RECURSIVE anc AS (
            SELECT s.id_solicitud AS origen, s.id_solicitud_anterior AS siguiente,
                   ARRAY[s.id_solicitud] AS visitados, FALSE AS ciclo
            FROM public.solicitud_matricula s WHERE s.id_solicitud_anterior IS NOT NULL
            UNION ALL
            SELECT anc.origen, s.id_solicitud_anterior,
                   anc.visitados || s.id_solicitud,
                   s.id_solicitud = ANY(anc.visitados)
            FROM anc JOIN public.solicitud_matricula s ON s.id_solicitud = anc.siguiente
            WHERE anc.siguiente IS NOT NULL AND NOT anc.ciclo
        ) SELECT 1 FROM anc WHERE ciclo
    ) THEN
        RAISE EXCEPTION 'Ciclo en antecedentes de solicitudes'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_solicitud_ciclo';
    END IF;

    -- La exclusividad del curso se comprueba por estudiante, incluso entre admisiones distintas.
    IF EXISTS (
        SELECT 1 FROM public.grupo g
        WHERE (SELECT COUNT(*) FROM public.solicitud_matricula s
               WHERE s.id_grupo = g.id_grupo AND s.estado = 'matriculada') > g.capacidad
    ) THEN
        RAISE EXCEPTION 'Cupo confirmado superior a capacidad del grupo'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_grupo_cupo';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s1
        JOIN public.solicitud_matricula s2 ON s1.id_solicitud < s2.id_solicitud
        JOIN public.admision a1 ON a1.id_admision = s1.id_admision
        JOIN public.admision a2 ON a2.id_admision = s2.id_admision
        JOIN public.grupo g1 ON g1.id_grupo = s1.id_grupo
        JOIN public.grupo g2 ON g2.id_grupo = s2.id_grupo
        WHERE s1.estado = 'matriculada' AND s2.estado = 'matriculada'
          AND a1.numero_institucional = a2.numero_institucional
          AND g1.codigo_curso = g2.codigo_curso AND g1.id_periodo = g2.id_periodo
    ) THEN
        RAISE EXCEPTION 'Matricula activa duplicada por estudiante, curso y periodo'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_matricula_duplicada';
    END IF;

    -- La ocupacion se verifica en el instante historico de cada adjudicacion y cambio de cupo.
    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        JOIN public.solicitud_matricula s ON s.id_solicitud = h.id_solicitud
        WHERE h.tipo_evento = 'transicion' AND h.estado_nuevo = 'matriculada'
          AND (SELECT COUNT(*) FROM public.solicitud_matricula ocup
               WHERE ocup.id_grupo = s.id_grupo
                 AND public.uh_estado_en_instante(
                     ocup.id_solicitud, h.fecha_evento) = 'matriculada'
              ) > public.uh_cupo_en_instante(s.id_grupo,h.fecha_evento)
    ) OR EXISTS (
        SELECT 1 FROM public.historial_oferta h
        WHERE h.tipo_cambio = 'cambio_cupo'
          AND (SELECT COUNT(*) FROM public.solicitud_matricula ocup
               WHERE ocup.id_grupo = h.id_grupo
                 AND public.uh_estado_en_instante(
                     ocup.id_solicitud, h.fecha_cambio) = 'matriculada'
              ) > h.cupo_nuevo
    ) THEN
        RAISE EXCEPTION 'Ocupacion historica superior al cupo autorizado en el instante'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_cupo_historico';
    END IF;

    -- La exclusividad historica no se pierde por retiros posteriores.
    IF EXISTS (
        WITH tr AS (
            SELECT s.id_solicitud, a.numero_institucional,
                   g.codigo_curso, g.id_periodo,
                   h.estado_nuevo, h.fecha_evento AS inicio,
                   LEAD(h.fecha_evento) OVER (
                       PARTITION BY h.id_solicitud
                       ORDER BY h.fecha_evento,h.id_evento
                   ) AS fin
            FROM public.historial_solicitud h
            JOIN public.solicitud_matricula s ON s.id_solicitud=h.id_solicitud
            JOIN public.admision a ON a.id_admision=s.id_admision
            JOIN public.grupo g ON g.id_grupo=s.id_grupo
            WHERE h.tipo_evento='transicion'
        )
        SELECT 1 FROM tr x JOIN tr y
          ON x.id_solicitud < y.id_solicitud
         AND x.numero_institucional=y.numero_institucional
         AND x.codigo_curso=y.codigo_curso
         AND x.id_periodo=y.id_periodo
        WHERE x.estado_nuevo='matriculada' AND y.estado_nuevo='matriculada'
          AND (x.fin IS NULL OR y.inicio < x.fin)
          AND (y.fin IS NULL OR x.inicio < y.fin)
    ) THEN
        RAISE EXCEPTION 'Matriculas historicamente simultaneas del mismo curso y periodo'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_matricula_duplicada_historica';
    END IF;

    -- Los retiros posteriores tampoco eliminan conflictos horarios que existieron entre matriculas.
    IF EXISTS (
        WITH trans AS (
            SELECT s.id_solicitud, a.numero_institucional, g.id_grupo,
                   h.estado_nuevo, h.fecha_evento AS inicio,
                   LEAD(h.fecha_evento) OVER (
                       PARTITION BY h.id_solicitud
                       ORDER BY h.fecha_evento, h.id_evento
                   ) AS fin
            FROM public.historial_solicitud h
            JOIN public.solicitud_matricula s ON s.id_solicitud=h.id_solicitud
            JOIN public.admision a ON a.id_admision=s.id_admision
            JOIN public.grupo g ON g.id_grupo=s.id_grupo
            WHERE h.tipo_evento = 'transicion'
        )
        SELECT 1 FROM trans x JOIN trans y
          ON x.id_solicitud < y.id_solicitud
         AND x.numero_institucional = y.numero_institucional
        JOIN public.grupo g1 ON g1.id_grupo=x.id_grupo
        JOIN public.grupo g2 ON g2.id_grupo=y.id_grupo
        JOIN public.periodo_academico p1 ON p1.id_periodo=g1.id_periodo
        JOIN public.periodo_academico p2 ON p2.id_periodo=g2.id_periodo
        JOIN public.bloque_horario b1 ON b1.id_grupo=g1.id_grupo
        JOIN public.bloque_horario b2 ON b2.id_grupo=g2.id_grupo
        WHERE x.estado_nuevo='matriculada' AND y.estado_nuevo='matriculada'
          AND (x.fin IS NULL OR y.inicio < x.fin)
          AND (y.fin IS NULL OR x.inicio < y.fin)
          AND p1.fecha_inicio <= p2.fecha_finalizacion
          AND p2.fecha_inicio <= p1.fecha_finalizacion
          AND b1.dia_semana = b2.dia_semana
          AND b1.hora_inicio < b2.hora_fin
          AND b2.hora_inicio < b1.hora_fin
          AND GREATEST(p1.fecha_inicio,p2.fecha_inicio)
              + ((b1.dia_semana - EXTRACT(ISODOW FROM
                    GREATEST(p1.fecha_inicio,p2.fecha_inicio))::INTEGER + 7) % 7)
              <= LEAST(p1.fecha_finalizacion,p2.fecha_finalizacion)
    ) THEN
        RAISE EXCEPTION 'Choque de horarios en matriculas historicamente simultaneas'
            USING ERRCODE='23514', CONSTRAINT='uh_horario_historico';
    END IF;

    -- Cada adjudicacion se contrasta con los requisitos satisfechos en su instante efectivo.
    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        WHERE h.tipo_evento='transicion' AND h.estado_nuevo='matriculada'
          AND NOT public.uh_requisitos_satisfechos(h.id_solicitud,h.fecha_evento)
    ) THEN
        RAISE EXCEPTION 'Adjudicacion historica sin requisito previo o correquisito satisfecho'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_matricula_requisitos';
    END IF;

    -- Una nota puede permanecer asociada a una solicitud que fue matriculada y despues retirada o
    -- anulada.
    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s
        WHERE (s.calificacion IS NOT NULL OR s.resultado_academico IS NOT NULL)
          AND NOT EXISTS (
              SELECT 1 FROM public.historial_solicitud h
              WHERE h.id_solicitud = s.id_solicitud
                AND h.tipo_evento = 'transicion' AND h.estado_nuevo = 'matriculada'
          )
    ) THEN
        RAISE EXCEPTION 'Resultado academico sin matricula registrada'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_resultado_sin_matricula';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s1
        JOIN public.solicitud_matricula s2 ON s1.id_solicitud < s2.id_solicitud
        JOIN public.admision a1 ON a1.id_admision = s1.id_admision
        JOIN public.admision a2 ON a2.id_admision = s2.id_admision
        JOIN public.grupo g1 ON g1.id_grupo = s1.id_grupo
        JOIN public.grupo g2 ON g2.id_grupo = s2.id_grupo
        JOIN public.periodo_academico p1 ON p1.id_periodo = g1.id_periodo
        JOIN public.periodo_academico p2 ON p2.id_periodo = g2.id_periodo
        JOIN public.bloque_horario b1 ON b1.id_grupo = g1.id_grupo
        JOIN public.bloque_horario b2 ON b2.id_grupo = g2.id_grupo
        WHERE s1.estado = 'matriculada' AND s2.estado = 'matriculada'
          AND a1.numero_institucional = a2.numero_institucional
          AND p1.fecha_inicio <= p2.fecha_finalizacion
          AND p2.fecha_inicio <= p1.fecha_finalizacion
          AND b1.dia_semana = b2.dia_semana
          AND GREATEST(p1.fecha_inicio, p2.fecha_inicio)
              + ((b1.dia_semana - EXTRACT(ISODOW FROM
                   GREATEST(p1.fecha_inicio, p2.fecha_inicio))::INTEGER + 7) % 7)
              <= LEAST(p1.fecha_finalizacion, p2.fecha_finalizacion)
          AND b1.hora_inicio < b2.hora_fin AND b2.hora_inicio < b1.hora_fin
    ) THEN
        RAISE EXCEPTION 'Choque de horario entre matriculas del mismo estudiante'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_matricula_horario';
    END IF;

    -- El ingreso a espera requiere que no existiera cupo disponible en ese instante.
    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        JOIN public.solicitud_matricula s ON s.id_solicitud=h.id_solicitud
        WHERE h.tipo_evento='transicion' AND h.estado_nuevo='en_espera'
          AND (SELECT COUNT(*) FROM public.solicitud_matricula ocup
               WHERE ocup.id_grupo=s.id_grupo
                 AND public.uh_estado_en_instante(ocup.id_solicitud,h.fecha_evento)
                     ='matriculada') < public.uh_cupo_en_instante(s.id_grupo,h.fecha_evento)
    ) THEN
        RAISE EXCEPTION 'Ingreso en espera cuando el grupo aun dispone de cupo'
            USING ERRCODE='23514', CONSTRAINT='uh_espera_sin_ocupacion_completa';
    END IF;

    -- La posicion de cola exige un ingreso a espera documentado, y viceversa.
    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s
        WHERE (s.orden_espera IS NOT NULL) IS DISTINCT FROM EXISTS (
            SELECT 1 FROM public.historial_solicitud h
            WHERE h.id_solicitud=s.id_solicitud AND h.tipo_evento='transicion'
              AND h.estado_nuevo='en_espera'
        )
    ) THEN
        RAISE EXCEPTION 'Posicion de espera sin ingreso o ingreso sin posicion'
            USING ERRCODE='23514', CONSTRAINT='uh_espera_posicion_historica';
    END IF;

    -- El orden depende del ingreso efectivo a espera; los empates se resuelven por id_solicitud.
    IF EXISTS (
        SELECT 1 FROM public.solicitud_matricula s1
        JOIN public.solicitud_matricula s2 ON s1.id_solicitud < s2.id_solicitud
        JOIN LATERAL (
            SELECT h.fecha_evento AS fecha_espera
            FROM public.historial_solicitud h
            WHERE h.id_solicitud = s1.id_solicitud
              AND h.tipo_evento = 'transicion' AND h.estado_nuevo = 'en_espera'
            ORDER BY h.fecha_evento DESC, h.id_evento DESC LIMIT 1
        ) e1 ON TRUE
        JOIN LATERAL (
            SELECT h.fecha_evento AS fecha_espera
            FROM public.historial_solicitud h
            WHERE h.id_solicitud = s2.id_solicitud
              AND h.tipo_evento = 'transicion' AND h.estado_nuevo = 'en_espera'
            ORDER BY h.fecha_evento DESC, h.id_evento DESC LIMIT 1
        ) e2 ON TRUE
        WHERE s1.id_grupo = s2.id_grupo
          AND public.uh_estado_en_instante(s1.id_solicitud,
                  GREATEST(e1.fecha_espera,e2.fecha_espera))='en_espera'
          AND public.uh_estado_en_instante(s2.id_solicitud,
                  GREATEST(e1.fecha_espera,e2.fecha_espera))='en_espera'
          AND ((ROW(e1.fecha_espera, s1.id_solicitud)
                < ROW(e2.fecha_espera, s2.id_solicitud)
                AND s1.orden_espera >= s2.orden_espera)
            OR (ROW(e2.fecha_espera, s2.id_solicitud)
                < ROW(e1.fecha_espera, s1.id_solicitud)
                AND s2.orden_espera >= s1.orden_espera))
    ) THEN
        RAISE EXCEPTION 'Orden de espera contrario al ingreso de solicitudes'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_espera_orden';
    END IF;

    -- Cada omision de un candidato anterior exige evaluacion motivada en el mismo instante de la
    -- promocion; no basta un evento antiguo.
    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        JOIN public.solicitud_matricula s ON s.id_solicitud=h.id_solicitud
        JOIN public.solicitud_matricula ant ON ant.id_grupo=s.id_grupo
             AND ant.orden_espera<s.orden_espera
        WHERE h.tipo_evento='transicion' AND h.estado_anterior='en_espera'
          AND h.estado_nuevo='matriculada'
          AND public.uh_estado_en_instante(ant.id_solicitud,h.fecha_evento)='en_espera'
          AND NOT EXISTS (
              SELECT 1 FROM public.historial_solicitud ev
              WHERE ev.id_solicitud=ant.id_solicitud AND ev.tipo_evento='evaluacion_espera'
                AND ev.fecha_evento=h.fecha_evento
                AND NULLIF(btrim(ev.motivo),'') IS NOT NULL
          )
    ) THEN
        RAISE EXCEPTION 'Falta la evaluacion del candidato anterior en la promocion'
            USING ERRCODE='23514', CONSTRAINT='uh_espera_prioridad';
    END IF;

    -- El ultimo evento debe concordar con el estado actual y la cadena de transiciones.
    IF EXISTS (
        WITH trans AS (
            SELECT h.*,
              LAG(h.estado_nuevo) OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_evento, h.id_evento
              ) AS previo,
              LAG(h.fecha_evento) OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_evento, h.id_evento
              ) AS fecha_previa,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_evento DESC, h.id_evento DESC
              ) AS ult,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_evento, h.id_evento
              ) AS ordinal
            FROM public.historial_solicitud h WHERE h.tipo_evento = 'transicion'
        )
        SELECT 1 FROM trans t
        JOIN public.solicitud_matricula s ON s.id_solicitud = t.id_solicitud
        WHERE (t.ordinal = 1 AND (t.estado_anterior IS NOT NULL
                                    OR t.fecha_evento < s.fecha_solicitud))
           OR (t.ordinal > 1 AND (t.estado_anterior IS DISTINCT FROM t.previo
                                   OR t.fecha_evento < t.fecha_previa))
           OR (t.ult = 1 AND t.estado_nuevo IS DISTINCT FROM s.estado)
           OR (t.ult = 1 AND t.ordinal = 1 AND s.momento_transicion IS NOT NULL)
           OR (t.ult = 1 AND t.ordinal > 1
               AND s.momento_transicion IS DISTINCT FROM t.fecha_evento)
    ) OR EXISTS (
        SELECT 1 FROM public.solicitud_matricula s WHERE NOT EXISTS (
            SELECT 1 FROM public.historial_solicitud h
            WHERE h.id_solicitud = s.id_solicitud AND h.tipo_evento = 'transicion'
        )
    ) THEN
        RAISE EXCEPTION 'Historial de transiciones incompatible con solicitud actual'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_solicitud';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.historial_solicitud h
        JOIN public.solicitud_matricula s ON s.id_solicitud = h.id_solicitud
        JOIN public.grupo g ON g.id_grupo = s.id_grupo
        WHERE h.fecha_evento < s.fecha_solicitud
           OR (h.tipo_evento = 'evaluacion_espera'
               AND (h.estado_anterior IS DISTINCT FROM 'en_espera'
                    AND h.estado_anterior IS NOT NULL
                    OR h.estado_nuevo IS DISTINCT FROM 'en_espera'
                       AND h.estado_nuevo IS NOT NULL
                    OR NOT EXISTS (
                        SELECT 1 FROM public.historial_solicitud previa
                        WHERE previa.id_solicitud = h.id_solicitud
                          AND previa.tipo_evento = 'transicion'
                          AND (previa.fecha_evento, previa.id_evento)
                              <= (h.fecha_evento, h.id_evento)
                          AND previa.estado_nuevo = 'en_espera'
                          AND NOT EXISTS (
                              SELECT 1 FROM public.historial_solicitud posterior
                              WHERE posterior.id_solicitud = h.id_solicitud
                                AND posterior.tipo_evento = 'transicion'
                                AND (posterior.fecha_evento, posterior.id_evento)
                                    <= (h.fecha_evento, h.id_evento)
                                AND (posterior.fecha_evento, posterior.id_evento)
                                    > (previa.fecha_evento, previa.id_evento)
                          )
                    )))
           OR (h.tipo_evento='transicion' AND h.estado_anterior IS NULL
               AND h.estado_nuevo='matriculada' AND h.fecha_evento>s.fecha_solicitud
               AND NOT EXISTS (
                   SELECT 1 FROM public.ventana_periodo v
                   WHERE v.id_periodo=g.id_periodo
                     AND (v.tipo_ventana='matricula' OR
                          (s.id_solicitud_anterior IS NOT NULL AND v.tipo_ventana='modificacion'))
                     AND h.fecha_evento>=v.inicio AND h.fecha_evento<v.fin))
           OR (h.tipo_evento = 'transicion' AND h.estado_anterior = 'rechazada'
               AND h.estado_nuevo IN ('matriculada','en_espera')
               AND NOT EXISTS (
                   SELECT 1 FROM public.ventana_periodo v
                   WHERE v.id_periodo = g.id_periodo
                     AND v.tipo_ventana IN ('matricula','modificacion')
                     AND h.fecha_evento >= v.inicio AND h.fecha_evento < v.fin))
           OR (h.tipo_evento = 'transicion' AND h.estado_nuevo = 'retirada'
               AND h.estado_anterior = 'matriculada'
               AND NOT EXISTS (
                   SELECT 1 FROM public.ventana_periodo v
                   WHERE v.id_periodo = g.id_periodo AND v.tipo_ventana = 'retiro'
                     AND h.fecha_evento >= v.inicio AND h.fecha_evento < v.fin)
               AND NOT EXISTS (
                   SELECT 1 FROM public.solicitud_matricula destino
                   JOIN public.grupo gd ON gd.id_grupo = destino.id_grupo
                   JOIN public.ventana_periodo vm ON vm.id_periodo = gd.id_periodo
                   WHERE destino.id_solicitud_anterior = s.id_solicitud
                     AND vm.tipo_ventana = 'modificacion'
                     AND h.fecha_evento >= vm.inicio AND h.fecha_evento < vm.fin
                     AND destino.fecha_solicitud >= vm.inicio
                     AND destino.fecha_solicitud < vm.fin
                     AND EXISTS (
                         SELECT 1 FROM public.historial_solicitud hd
                         WHERE hd.id_solicitud = destino.id_solicitud
                           AND hd.tipo_evento = 'transicion'
                           AND hd.estado_nuevo = 'matriculada'
                    AND hd.fecha_evento = h.fecha_evento
                           AND hd.fecha_evento >= vm.inicio
                           AND hd.fecha_evento < vm.fin)))
    ) THEN
        RAISE EXCEPTION 'Evaluacion de espera o retiro fuera de contexto'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_evento_temporal';
    END IF;

    -- Una oferta abierta requiere un evento de apertura registrado.
    IF EXISTS (
        SELECT 1 FROM public.grupo g
        WHERE g.estado_oferta = 'abierta' AND NOT EXISTS (
              SELECT 1 FROM public.historial_oferta h
              WHERE h.id_grupo = g.id_grupo AND h.tipo_cambio = 'apertura'
          )
    ) THEN
        RAISE EXCEPTION 'Oferta publicada sin evento historico de apertura'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_oferta_apertura';
    END IF;

    -- Los eventos de estado y cupo deben ser cronologicamente coherentes con los valores vigentes.
    IF EXISTS (
        WITH estados AS (
            SELECT h.*,
              LAG(h.estado_nuevo) OVER (
                  PARTITION BY h.id_grupo ORDER BY h.fecha_cambio,h.id_cambio
              ) AS previo,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_grupo ORDER BY h.fecha_cambio,h.id_cambio
              ) AS n,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_grupo ORDER BY h.fecha_cambio DESC,h.id_cambio DESC
              ) AS ult
            FROM public.historial_oferta h WHERE h.tipo_cambio <> 'cambio_cupo'
        )
        SELECT 1 FROM estados x JOIN public.grupo g ON g.id_grupo = x.id_grupo
        WHERE (x.n > 1 AND x.estado_anterior IS DISTINCT FROM x.previo)
           OR (x.ult = 1 AND g.estado_oferta IS DISTINCT FROM x.estado_nuevo)
    ) OR EXISTS (
        WITH cupos AS (
            SELECT h.*,
              LAG(h.cupo_nuevo) OVER (
                  PARTITION BY h.id_grupo ORDER BY h.fecha_cambio,h.id_cambio
              ) AS previo,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_grupo ORDER BY h.fecha_cambio,h.id_cambio
              ) AS n,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_grupo ORDER BY h.fecha_cambio DESC,h.id_cambio DESC
              ) AS ult
            FROM public.historial_oferta h WHERE h.tipo_cambio = 'cambio_cupo'
        )
        SELECT 1 FROM cupos x JOIN public.grupo g ON g.id_grupo = x.id_grupo
        WHERE (x.n > 1 AND x.cupo_anterior IS DISTINCT FROM x.previo)
           OR (x.ult = 1 AND g.capacidad IS DISTINCT FROM x.cupo_nuevo)
    ) THEN
        RAISE EXCEPTION 'Historial de oferta incoherente con cambios sucesivos'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_oferta';
    END IF;

    -- Las correcciones sucesivas deben encadenarse y concordar con el expediente actual.
    IF EXISTS (
        WITH hist AS (
            SELECT h.*,
              LAG(h.calificacion_nueva) OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_correccion,h.id_correccion
              ) AS cal_prev,
              LAG(h.resultado_nuevo) OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_correccion,h.id_correccion
              ) AS res_prev,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_correccion,h.id_correccion
              ) AS n,
              ROW_NUMBER() OVER (
                  PARTITION BY h.id_solicitud ORDER BY h.fecha_correccion DESC,h.id_correccion DESC
              ) AS ult
            FROM public.historial_correccion_calificacion h
        )
        SELECT 1 FROM hist x JOIN public.solicitud_matricula s
          ON s.id_solicitud = x.id_solicitud
        WHERE (x.n > 1 AND (x.calificacion_anterior IS DISTINCT FROM x.cal_prev
                             OR x.resultado_anterior IS DISTINCT FROM x.res_prev))
           OR (x.ult = 1 AND (s.calificacion IS DISTINCT FROM x.calificacion_nueva
                             OR s.resultado_academico IS DISTINCT FROM x.resultado_nuevo))
    ) THEN
        RAISE EXCEPTION 'Correccion academica no coincide con expediente e historial'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_historial_calificacion';
    END IF;
END;
$$;

-- La auditoria del lote se completa antes de la comprobacion diferida; sus inserciones internas no
-- necesitan otra validacion independiente.
CREATE OR REPLACE FUNCTION public.uh_validar_trigger()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF pg_trigger_depth()=1 OR TG_TABLE_NAME NOT IN
       ('historial_oferta','historial_solicitud','historial_correccion_calificacion') THEN
        PERFORM public.uh_validar_integridad();
    END IF;
    RETURN NULL;
END;
$$;

-- El cambio de version de una admision requiere un traslado concordante, aunque no haya otras
-- decisiones.
CREATE OR REPLACE FUNCTION public.uh_validar_cambio_plan()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id_version_plan IS DISTINCT FROM OLD.id_version_plan
       AND NOT EXISTS (
           SELECT 1 FROM public.traslado_plan t
           WHERE t.id_admision = NEW.id_admision
             AND t.id_version_origen = OLD.id_version_plan
             AND t.id_version_destino = NEW.id_version_plan
       ) THEN
        RAISE EXCEPTION 'Cambio de plan sin traslado de origen y destino registrados'
            USING ERRCODE = '23514', CONSTRAINT = 'uh_admision_traslado_obligatorio';
    END IF;
    RETURN NULL;
END;
$$;

-- TRUNCATE no activa triggers por fila; se bloquea para impedir eludir la proteccion del historial.
CREATE OR REPLACE FUNCTION public.uh_rechazar_truncamiento()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'TRUNCATE no es una operacion de negocio permitida sobre las relaciones del modelo'
        USING ERRCODE = '23514', CONSTRAINT = 'uh_truncamiento_prohibido';
    RETURN NULL;
END;
$$;

DO $$
DECLARE v_tabla TEXT;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY[
        'estudiante','admision','carrera','sede','version_plan_estudios',
        'periodo_academico','curso','escuela','grupo','bloque_horario',
        'espacio','solicitud_matricula','docente','contacto_estudiante',
        'carrera_sede','participacion_plan','requisito_curso','traslado_plan',
        'reconocimiento_academico','persona_autorizadora','ventana_periodo',
        'grupo_docente','historial_oferta','historial_solicitud',
        'excepcion_requisito','historial_correccion_calificacion'
    ] LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS uh_rechazar_truncamiento ON public.%I',v_tabla);
        EXECUTE format('CREATE TRIGGER uh_rechazar_truncamiento BEFORE TRUNCATE ON public.%I FOR EACH STATEMENT EXECUTE FUNCTION public.uh_rechazar_truncamiento()',v_tabla);
    END LOOP;
END;
$$;

-- Se serializan escrituras relevantes por sentencia y se verifica el estado mediante constraint
-- triggers diferibles.
DO $$
DECLARE
    v_tabla TEXT;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY[
        'curso', 'admision', 'carrera_sede', 'version_plan_estudios',
        'traslado_plan', 'reconocimiento_academico', 'requisito_curso',
        'participacion_plan', 'periodo_academico', 'ventana_periodo',
        'grupo', 'grupo_docente', 'bloque_horario', 'espacio',
        'solicitud_matricula', 'excepcion_requisito', 'historial_oferta',
        'historial_solicitud', 'historial_correccion_calificacion','contacto_estudiante'
    ] LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS uh_serializar_contexto ON public.%I', v_tabla);
        EXECUTE format('CREATE TRIGGER uh_serializar_contexto BEFORE INSERT OR UPDATE OR DELETE ON public.%I FOR EACH STATEMENT EXECUTE FUNCTION public.uh_serializar_contexto()', v_tabla);
        EXECUTE format('DROP TRIGGER IF EXISTS uh_bloquear_contexto ON public.%I', v_tabla);
        EXECUTE format('CREATE TRIGGER uh_bloquear_contexto BEFORE INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.uh_bloquear_contexto()', v_tabla);
        EXECUTE format('DROP TRIGGER IF EXISTS uh_validar_contexto ON public.%I', v_tabla);
        EXECUTE format('CREATE CONSTRAINT TRIGGER uh_validar_contexto AFTER INSERT OR UPDATE OR DELETE ON public.%I DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.uh_validar_trigger()', v_tabla);
    END LOOP;
END;
$$;

-- Los historiales no se reescriben ni eliminan; las evaluaciones de espera se admiten como
-- registros expresos.
DO $$
DECLARE
    v_tabla TEXT;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY[
        'historial_oferta', 'historial_solicitud',
        'historial_correccion_calificacion'
    ] LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS uh_proteger_historial ON public.%I', v_tabla);
        EXECUTE format('CREATE TRIGGER uh_proteger_historial BEFORE INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.uh_proteger_historial()', v_tabla);
    END LOOP;
END;
$$;

DROP TRIGGER IF EXISTS uh_validar_cambio_plan ON public.admision;
CREATE CONSTRAINT TRIGGER uh_validar_cambio_plan
AFTER UPDATE OF id_version_plan ON public.admision
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
EXECUTE FUNCTION public.uh_validar_cambio_plan();

-- Para omitir a una persona anterior en espera se exige evaluacion motivada en el instante de la
-- promocion, no en otro momento.
CREATE OR REPLACE FUNCTION public.uh_validar_promocion(
    nueva public.solicitud_matricula, anterior public.solicitud_matricula
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF anterior.estado='en_espera' AND nueva.estado='matriculada' AND EXISTS (
        SELECT 1 FROM public.solicitud_matricula ant
        WHERE ant.id_grupo=nueva.id_grupo AND ant.id_solicitud<>nueva.id_solicitud
          AND ant.orden_espera<anterior.orden_espera
          AND public.uh_estado_en_instante(ant.id_solicitud,nueva.momento_transicion)='en_espera'
          AND (public.uh_candidato_elegible(ant.id_solicitud,nueva.momento_transicion)
               OR NOT EXISTS (
                   SELECT 1 FROM public.historial_solicitud ev
                   WHERE ev.id_solicitud=ant.id_solicitud
                     AND ev.tipo_evento='evaluacion_espera'
                     AND ev.fecha_evento=nueva.momento_transicion
                     AND NULLIF(btrim(ev.motivo),'') IS NOT NULL))
    ) THEN
        RAISE EXCEPTION 'La promocion omite una solicitud anterior elegible o sin evaluacion'
            USING ERRCODE='23514', CONSTRAINT='uh_espera_prioridad';
    END IF;
END;
$$;

-- Las tablas de transicion permiten auditar sentencias multirregistro. Un marcador evita procesar
-- el lote varias veces sin omitir las validaciones.
CREATE OR REPLACE FUNCTION public.uh_auditar_lote()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_marca TEXT := 'universidad.auditoria_' || TG_TABLE_NAME || '_' || lower(TG_OP);
    v_grupo public.grupo;
    v_solicitud public.solicitud_matricula;
    v_par RECORD;
BEGIN
    IF current_setting(v_marca,TRUE)='registrado' THEN RETURN NULL; END IF;
    PERFORM set_config(v_marca,'registrado',TRUE);
    IF TG_TABLE_NAME='grupo' THEN
        IF TG_OP='INSERT' THEN
            FOR v_grupo IN SELECT * FROM nuevas ORDER BY id_grupo LOOP
                PERFORM public.uh_registrar_cambio_oferta(v_grupo,NULL,'INSERT');
            END LOOP;
        ELSE
            FOR v_par IN
                SELECT ROW(n.*)::public.grupo AS nueva, ROW(a.*)::public.grupo AS anterior
                FROM nuevas n JOIN anteriores a ON a.id_grupo=COALESCE(
                    (current_setting('universidad.claves_grupo')::JSONB ->> n.id_grupo::TEXT)::INTEGER,
                    n.id_grupo)
                ORDER BY n.id_grupo
            LOOP
                PERFORM public.uh_registrar_cambio_oferta(v_par.nueva,v_par.anterior,'UPDATE');
            END LOOP;
        END IF;
    ELSE
        IF TG_OP='INSERT' THEN
            FOR v_solicitud IN SELECT * FROM nuevas ORDER BY id_solicitud LOOP
                PERFORM public.uh_registrar_transicion_solicitud(v_solicitud,NULL,'INSERT');
            END LOOP;
        ELSE
            FOR v_par IN
                SELECT ROW(n.*)::public.solicitud_matricula AS nueva,
                       ROW(a.*)::public.solicitud_matricula AS anterior
                FROM nuevas n JOIN anteriores a USING (id_solicitud)
                ORDER BY n.id_solicitud
            LOOP
                PERFORM public.uh_registrar_transicion_solicitud(v_par.nueva,v_par.anterior,'UPDATE');
                PERFORM public.uh_registrar_cambio_calificacion(v_par.nueva,v_par.anterior,'UPDATE');
            END LOOP;
            FOR v_par IN
                SELECT ROW(n.*)::public.solicitud_matricula AS nueva,
                       ROW(a.*)::public.solicitud_matricula AS anterior
                FROM nuevas n JOIN anteriores a USING (id_solicitud)
                WHERE a.estado='en_espera' AND n.estado='matriculada'
                ORDER BY n.id_solicitud
            LOOP
                PERFORM public.uh_validar_promocion(v_par.nueva,v_par.anterior);
            END LOOP;
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS uh_auditar_oferta ON public.grupo;
DROP TRIGGER IF EXISTS uh_auditar_solicitud ON public.solicitud_matricula;
DROP TRIGGER IF EXISTS uh_auditar_calificacion ON public.solicitud_matricula;
DO $$
DECLARE v_tabla TEXT;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY['grupo','solicitud_matricula'] LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS uh_auditar_alta ON public.%I',v_tabla);
        EXECUTE format('CREATE TRIGGER uh_auditar_alta AFTER INSERT ON public.%I REFERENCING NEW TABLE AS nuevas FOR EACH ROW EXECUTE FUNCTION public.uh_auditar_lote()',v_tabla);
        EXECUTE format('DROP TRIGGER IF EXISTS uh_auditar_actualizacion ON public.%I',v_tabla);
        EXECUTE format('CREATE TRIGGER uh_auditar_actualizacion AFTER UPDATE ON public.%I REFERENCING OLD TABLE AS anteriores NEW TABLE AS nuevas FOR EACH ROW EXECUTE FUNCTION public.uh_auditar_lote()',v_tabla);
    END LOOP;
END;
$$;

-- La comprobacion final incluye la semilla, anterior a la instalacion de los triggers.
SELECT public.uh_validar_integridad();
COMMIT;
