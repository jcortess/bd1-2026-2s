
\set ON_ERROR_STOP on

SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

\echo ==== PRUEBAS ADICIONALES DE COBERTURA JEANK ====

-- PJ-13: Una solicitud aprobada no genera reservas automaticamente.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM estado_actual_solicitud
        WHERE id_solicitud = 3
          AND estado = 'APROBADA'
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-13: solicitud no aprobada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM reserva
        WHERE solicitud_id = 3
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-13: reserva automatica';
    END IF;

    RAISE NOTICE 'PJ-13: SUPERADA';
END;
$$;


-- PJ-14 y PJ-15: Restriccion finalizada y reserva independiente.

BEGIN;

UPDATE restriccion_persona
SET fecha_fin = '2026-10-09 08:00:00-06'
WHERE persona_afectada_id = 103
  AND fecha_fin IS NULL;

COMMIT;

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

SELECT registrar_reserva(
    '31000000-0000-0000-0000-000000000001',
    3,
    'HS-03',
    3,
    '2026-10-09 08:00:00-06',
    1
) AS reserva_adicional \gset

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM reserva
        WHERE clave_operacion =
            '31000000-0000-0000-0000-000000000001'
          AND fecha_fin_reserva IS NULL
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-15: reserva no registrada';
    END IF;

    RAISE NOTICE 'PJ-15: SUPERADA - RESTRICCION FINALIZADA';
END;
$$;

BEGIN;

SET LOCAL ROLE huellas_g05_operador;

SELECT finalizar_reserva(
    :reserva_adicional,
    '2026-10-09 09:00:00-06',
    1
);

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM reserva
        WHERE clave_operacion =
            '31000000-0000-0000-0000-000000000001'
          AND fecha_fin_reserva =
            '2026-10-09 09:00:00-06'
    ) OR EXISTS (
        SELECT 1 FROM adopcion WHERE ingreso_id = 3
    ) OR NOT EXISTS (
        SELECT 1 FROM ingreso
        WHERE id_ingreso = 3 AND fecha_cierre IS NULL
    ) OR NOT EXISTS (
        SELECT 1 FROM estancia
        WHERE ingreso_id = 3 AND fecha_fin_real IS NULL
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-14: cierre incorrecto';
    END IF;

    RAISE NOTICE 'PJ-14: SUPERADA - RESERVA FINALIZADA SIN ADOPCION';
END;
$$;


-- PJ-16: Reingreso asociado a otro animal.

DO $$
DECLARE
    v_origen bigint;
BEGIN
    SELECT id_adopcion INTO STRICT v_origen
    FROM adopcion
    WHERE animal_codigo = 'HS-01'
      AND ingreso_id = 1
      AND tipo_finalizacion = 'DEVOLUCION_VOLUNTARIA';

    BEGIN
        INSERT INTO ingreso (
            animal_codigo,
            fecha_ingreso,
            lugar_ingreso,
            condicion_general,
            circunstancia_ingreso,
            detalle_circunstancia,
            adopcion_origen_id,
            receptor_devolucion_id
        )
        VALUES (
            'HS-02',
            '2026-10-12 09:00:00-06',
            'Recepcion del refugio',
            'Animal estable',
            'DEVOLUCION',
            'Prueba ficticia de origen incorrecto',
            v_origen,
            1
        );

        RAISE EXCEPTION 'FALLO PJ-16: reingreso incorrecto aceptado';

    EXCEPTION
        WHEN SQLSTATE 'P3052' THEN
            RAISE NOTICE 'PJ-16: RECHAZO ESPERADO - % - %',
                SQLERRM, SQLSTATE;
    END;

    IF EXISTS (
        SELECT 1 FROM ingreso
        WHERE animal_codigo = 'HS-02'
          AND adopcion_origen_id = v_origen
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-16: quedaron efectos parciales';
    END IF;

    RAISE NOTICE 'PJ-16: SUPERADA';
END;
$$;


-- PJ-18: Traslado sin organizacion de destino.

DO $$
DECLARE
    v_constraint text;
BEGIN
    BEGIN
        INSERT INTO resultado_etapa (
            ingreso_id,
            tipo_resultado,
            fecha,
            circunstancias,
            responsable_id,
            organizacion_destino_id,
            condiciones_traslado
        )
        VALUES (
            3,
            'TRASLADO',
            '2026-10-13 10:00:00-06',
            'Traslado ficticio',
            1,
            NULL,
            'Transporte seguro'
        );

        RAISE EXCEPTION 'FALLO PJ-18: traslado incompleto aceptado';

    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS
                v_constraint = CONSTRAINT_NAME;

            IF v_constraint IS DISTINCT FROM
                'resultado_traslado_chk'
            THEN
                RAISE;
            END IF;

            RAISE NOTICE 'PJ-18: RECHAZO ESPERADO - % - %',
                v_constraint, SQLSTATE;
    END;

    IF EXISTS (
        SELECT 1 FROM resultado_etapa WHERE ingreso_id = 3
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-18: quedaron efectos parciales';
    END IF;

    RAISE NOTICE 'PJ-18: SUPERADA';
END;
$$;


-- PJ-17: Traslado valido y cierre de etapa.

BEGIN;

SELECT id_estancia AS estancia_traslado
FROM estancia
WHERE ingreso_id = 3
  AND fecha_fin_real IS NULL
\gset

INSERT INTO resultado_etapa (
    ingreso_id,
    tipo_resultado,
    fecha,
    circunstancias,
    responsable_id,
    organizacion_destino_id,
    condiciones_traslado
)
VALUES (
    3,
    'TRASLADO',
    '2026-10-13 10:00:00-06',
    'Traslado ficticio a organizacion colaboradora',
    1,
    1,
    'Transporte seguro y entrega documentada'
);

SELECT _cerrar_etapa_alojamiento(
    3,
    :estancia_traslado,
    '2026-10-13 10:00:00-06',
    1
);

COMMIT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM resultado_etapa r
        JOIN ingreso i ON i.id_ingreso = r.ingreso_id
        WHERE r.ingreso_id = 3
          AND r.tipo_resultado = 'TRASLADO'
          AND r.organizacion_destino_id = 1
          AND i.fecha_cierre = r.fecha
    ) OR EXISTS (
        SELECT 1 FROM estancia
        WHERE ingreso_id = 3 AND fecha_fin_real IS NULL
    ) OR EXISTS (
        SELECT 1 FROM adopcion WHERE ingreso_id = 3
    ) THEN
        RAISE EXCEPTION 'FALLO PJ-17: traslado inconsistente';
    END IF;

    RAISE NOTICE 'PJ-17: SUPERADA';
END;
$$;


-- PC-08: Asociacion clinica duplicada.

DO $$
DECLARE
    v_constraint text;
BEGIN
    BEGIN
        INSERT INTO indicacion_diagnostico (
            indicacion_id,
            evaluacion_id,
            diagnostico_id
        )
        VALUES (2001, 1001, 1);

        RAISE EXCEPTION 'FALLO PC-08: duplicado aceptado';

    EXCEPTION
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS
                v_constraint = CONSTRAINT_NAME;

            IF v_constraint IS DISTINCT FROM
                'indicacion_diagnostico_pkey'
            THEN
                RAISE;
            END IF;

            RAISE NOTICE 'PC-08: RECHAZO ESPERADO - % - %',
                v_constraint, SQLSTATE;
    END;

    IF (
        SELECT count(*)
        FROM indicacion_diagnostico
        WHERE indicacion_id = 2001
          AND diagnostico_id = 1
    ) <> 1 THEN
        RAISE EXCEPTION 'FALLO PC-08: asociacion inconsistente';
    END IF;

    RAISE NOTICE 'PC-08: SUPERADA';
END;
$$;


-- PC-09: Inmutabilidad del historial clinico.

DO $$
DECLARE
    v_original text;
BEGIN
    SELECT descripcion INTO STRICT v_original
    FROM indicacion
    WHERE id_indicacion = 2001;

    BEGIN
        UPDATE indicacion
        SET descripcion = 'Modificacion historica no permitida'
        WHERE id_indicacion = 2001;

        RAISE EXCEPTION 'FALLO PC-09: modificacion aceptada';

    EXCEPTION
        WHEN SQLSTATE 'P2001' THEN
            RAISE NOTICE 'PC-09: RECHAZO ESPERADO - % - %',
                SQLERRM, SQLSTATE;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM indicacion
        WHERE id_indicacion = 2001
          AND descripcion = v_original
    ) THEN
        RAISE EXCEPTION 'FALLO PC-09: historial alterado';
    END IF;

    RAISE NOTICE 'PC-09: SUPERADA';
END;
$$;


-- Evidencia persistida.

\echo ==== ESTADO FINAL DE LAS RESERVAS ====

SELECT id_reserva,
       solicitud_id,
       animal_codigo,
       fecha_reserva,
       fecha_fin_reserva
FROM reserva
ORDER BY id_reserva;

\echo ==== RESTRICCIONES ====

SELECT *
FROM restriccion_persona
WHERE persona_afectada_id = 103;

\echo ==== RESULTADO DEL TRASLADO ====

SELECT r.id_resultado,
       r.tipo_resultado,
       r.organizacion_destino_id,
       r.fecha,
       i.fecha_cierre
FROM resultado_etapa r
JOIN ingreso i ON i.id_ingreso = r.ingreso_id
WHERE r.ingreso_id = 3;

\echo ==== INTEGRIDAD CLINICA ====

SELECT * FROM indicacion_diagnostico
ORDER BY indicacion_id, diagnostico_id;

SELECT * FROM indicacion
WHERE id_indicacion = 2001;

\echo ==== CONTROL DE ADOPCIONES ====

SELECT * FROM v_control_adopciones_jeank;

\echo ==== FIN DE PRUEBAS ADICIONALES ====
