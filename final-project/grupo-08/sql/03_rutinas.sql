-- =====================================================================
-- 03_rutinas.sql
-- Proyecto final IC-4301 - Grupo 08: Envíos Conecta
-- Requiere: 01_esquema.sql y 02_datos.sql.
--
-- PARTE 1. Rutinas reutilizadas de Lab03 (04_rutinas.sql), sin cambios.
-- PARTE 2. Rutinas de los procesos G08-P01, G08-P02 y G08-P03.
-- =====================================================================


-- =====================================================================
-- PARTE 1. RUTINAS REUTILIZADAS DE LAB03 (sin modificación)
-- =====================================================================

-- ---------------------------------------------------------------------
-- F1. fn_solicitudes_cliente
-- Solicitudes de un cliente, con rango de fechas opcional.
-- Rechaza un cliente inexistente en vez de devolver vacío.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_solicitudes_cliente(
    p_tipo_id   VARCHAR,
    p_numero_id VARCHAR,
    p_desde     DATE DEFAULT NULL,
    p_hasta     DATE DEFAULT NULL
)
RETURNS TABLE (
    id_solicitud   INTEGER,
    fecha          DATE,
    nivel_servicio VARCHAR,
    destino        VARCHAR
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM cliente c
                   WHERE c.tipo_id = p_tipo_id
                     AND c.numero_id = p_numero_id) THEN
        RAISE EXCEPTION 'El cliente (%, %) no existe', p_tipo_id, p_numero_id;
    END IF;

    RETURN QUERY
    SELECT s.id_solicitud, s.fecha, s.nivel_servicio, s.destino
    FROM solicitud s
    WHERE s.tipo_id   = p_tipo_id
      AND s.numero_id = p_numero_id
      AND (p_desde IS NULL OR s.fecha >= p_desde)
      AND (p_hasta IS NULL OR s.fecha <= p_hasta)
    ORDER BY s.fecha, s.id_solicitud;
END;
$$;

-- ---------------------------------------------------------------------
-- F2. fn_prioridad_solicitud
-- PROPUESTA DIDÁCTICA de Lab03: no es una prioridad oficial de transporte
-- (anexo G08, secciones D y F). No se usa en P01, P02 ni P03.
--   MISMO_DIA                                -> CRITICA
--   EXPRESS con cliente CONTRATO_CORPORATIVO -> CRITICA
--   EXPRESS (otros clientes)                 -> ALTA
--   ESTANDAR                                 -> NORMAL
--   ECONOMICO                                -> BAJA
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_prioridad_solicitud(p_id_solicitud INTEGER)
RETURNS VARCHAR
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_nivel     VARCHAR;
    v_condicion VARCHAR;
BEGIN
    SELECT s.nivel_servicio, c.condicion_contractual
      INTO v_nivel, v_condicion
    FROM solicitud s
    JOIN cliente c ON c.tipo_id   = s.tipo_id
                  AND c.numero_id = s.numero_id
    WHERE s.id_solicitud = p_id_solicitud;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La solicitud % no existe', p_id_solicitud;
    END IF;

    RETURN CASE
        WHEN v_nivel = 'MISMO_DIA'                                        THEN 'CRITICA'
        WHEN v_nivel = 'EXPRESS' AND v_condicion = 'CONTRATO_CORPORATIVO' THEN 'CRITICA'
        WHEN v_nivel = 'EXPRESS'                                          THEN 'ALTA'
        WHEN v_nivel = 'ESTANDAR'                                         THEN 'NORMAL'
        ELSE 'BAJA'
    END;
END;
$$;

-- ---------------------------------------------------------------------
-- P1. sp_registrar_contacto
-- Alta atómica de un contacto con su primera facultad y su primer medio.
-- Es la ruta de escritura admitida para contactos: garantiza al menos una
-- facultad (S-02). La regla "solo organizaciones" también la garantizan
-- los triggers del esquema (CAM-011).
-- Limitación: no recibe descripción, así que no registra medios de tipo OTRO.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_contacto(
    p_tipo_id    VARCHAR,
    p_numero_id  VARCHAR,
    p_nombre     VARCHAR,
    p_facultad   VARCHAR,
    p_tipo_medio VARCHAR,
    p_valor      VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo_cliente VARCHAR;
    v_id_contacto  INTEGER;
BEGIN
    SELECT c.tipo_cliente
      INTO v_tipo_cliente
    FROM cliente c
    WHERE c.tipo_id = p_tipo_id
      AND c.numero_id = p_numero_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se puede registrar el contacto: el cliente (%, %) no existe',
            p_tipo_id, p_numero_id;
    END IF;

    IF v_tipo_cliente <> 'PERSONA_JURIDICA' THEN
        RAISE EXCEPTION 'No se puede registrar el contacto: el cliente (%, %) no es una organización (RN-02)',
            p_tipo_id, p_numero_id;
    END IF;

    INSERT INTO contacto (tipo_id, numero_id, nombre)
    VALUES (p_tipo_id, p_numero_id, p_nombre)
    RETURNING id_contacto INTO v_id_contacto;

    INSERT INTO facultad_contacto (id_contacto, facultad)
    VALUES (v_id_contacto, p_facultad);

    INSERT INTO medio_contacto_contacto (id_contacto, tipo_medio, valor)
    VALUES (v_id_contacto, p_tipo_medio, p_valor);

    RAISE NOTICE 'Contacto % registrado con id %', p_nombre, v_id_contacto;
END;
$$;

-- ---------------------------------------------------------------------
-- C3. fn_reporte_prioridades (cursor explícito, con fines didácticos)
-- Equivale a un SELECT basado en conjuntos con fn_prioridad_solicitud.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reporte_prioridades()
RETURNS TABLE (
    id_solicitud   INTEGER,
    nombre_cliente VARCHAR,
    prioridad      VARCHAR
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    cur_sol CURSOR FOR
        SELECT s.id_solicitud, c.nombre_razon_social
        FROM solicitud s
        JOIN cliente c ON c.tipo_id   = s.tipo_id
                      AND c.numero_id = s.numero_id
        ORDER BY s.id_solicitud;
    v_id     INTEGER;
    v_nombre VARCHAR;
BEGIN
    OPEN cur_sol;
    LOOP
        FETCH cur_sol INTO v_id, v_nombre;
        EXIT WHEN NOT FOUND;

        id_solicitud   := v_id;
        nombre_cliente := v_nombre;
        prioridad      := fn_prioridad_solicitud(v_id);
        RETURN NEXT;
    END LOOP;
    CLOSE cur_sol;
END;
$$;


-- =====================================================================
-- PARTE 2. RUTINAS DE LOS PROCESOS (a cargo de la persona 2)
-- =====================================================================

-- ---------------------------------------------------------------------
-- P01.1 sp_crear_envio
-- Proceso: G08-P01 (crear envíos y paquetes).
-- Propósito: crear una guía a partir de una solicitud, con todos sus
--   paquetes, copiando las direcciones usadas y la cotización (RN-04, RN-08).
-- Entradas: guía, solicitud, pagador, remitente, destinatario, tarifa,
--   servicio, dirección de origen y de destino, y la lista de paquetes en
--   JSON. Cada paquete: peso (kg), largo, ancho y alto (cm), descripcion,
--   politica (PERMITIDO, PROHIBIDO, EXIGE_RESPALDO) y, opcionales,
--   respaldo (texto) y condiciones (lista: FRAGIL, REFRIGERACION,
--   PRUEBA_IDENTIDAD).
-- Modifica: ENVIO, PAQUETE y CONDICION_MANEJO_PAQUETE.
-- Precondiciones: solicitud, pagador, participantes y tarifa existentes.
-- Rechazos (ERRCODE check_violation, salvo indicación):
--   ck_envio_paquetes_requeridos  lista de paquetes vacía o inválida
--   fk_envio_tarifa               tarifa inexistente (foreign_key_violation)
--   ck_envio_tarifa_pagador       tarifa de contrato de otro cliente (CAM-013)
--   ck_envio_tarifa_vigente       fecha fuera de la vigencia (CAM-013)
--   ck_envio_tarifa_servicio      servicio distinto al de la tarifa
--   ck_envio_tarifa_rango         peso o volumen fuera de los rangos
--   pk_envio                      guía duplicada (unique_violation)
--   además, las restricciones de ENVIO y PAQUETE del esquema.
-- Transacción: envío, paquetes y condiciones en una sola operación; si
--   algo falla no queda nada. La tarifa se lee con FOR SHARE para que no
--   cambie mientras se usa. La revisión del paquete es otra rutina (P01.2).
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_crear_envio(
    p_numero_guia         VARCHAR,
    p_id_solicitud        INTEGER,
    p_tipo_id_pagador     VARCHAR,
    p_numero_id_pagador   VARCHAR,
    p_id_remitente        INTEGER,
    p_id_destinatario     INTEGER,
    p_id_tarifa           INTEGER,
    p_servicio            VARCHAR,
    p_origen_provincia    VARCHAR,
    p_origen_canton       VARCHAR,
    p_origen_distrito     VARCHAR,
    p_origen_otras_senas  VARCHAR,
    p_destino_provincia   VARCHAR,
    p_destino_canton      VARCHAR,
    p_destino_distrito    VARCHAR,
    p_destino_otras_senas VARCHAR,
    p_paquetes            JSONB,
    p_fecha_creacion      DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tarifa    tarifa%ROWTYPE;
    v_peso      NUMERIC := 0;
    v_volumen   NUMERIC := 0;
    v_num       SMALLINT := 0;
    v_p         RECORD;
    v_condicion TEXT;
BEGIN
    -- 1. La lista de paquetes debe ser un arreglo JSON no vacío (S-06, RN-07)
    IF p_paquetes IS NULL
       OR jsonb_typeof(p_paquetes) <> 'array'
       OR jsonb_array_length(p_paquetes) = 0 THEN
        RAISE EXCEPTION 'El envío % debe incluir al menos un paquete', p_numero_guia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_envio_paquetes_requeridos';
    END IF;

    -- 2. Leer la tarifa y bloquearla mientras se usa
    SELECT * INTO v_tarifa
    FROM tarifa t
    WHERE t.id_tarifa = p_id_tarifa
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La tarifa % no existe', p_id_tarifa
            USING ERRCODE = 'foreign_key_violation', CONSTRAINT = 'fk_envio_tarifa';
    END IF;

    -- 3. La tarifa debe ser aplicable (CAM-013)
    IF v_tarifa.tipo_id IS NOT NULL
       AND (v_tarifa.tipo_id <> p_tipo_id_pagador
            OR v_tarifa.numero_id <> p_numero_id_pagador) THEN
        RAISE EXCEPTION 'La tarifa % es de contrato de otro cliente y no aplica al pagador (%, %)',
            p_id_tarifa, p_tipo_id_pagador, p_numero_id_pagador
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_envio_tarifa_pagador';
    END IF;

    IF p_fecha_creacion < v_tarifa.vigencia_inicio
       OR (v_tarifa.vigencia_fin IS NOT NULL AND p_fecha_creacion > v_tarifa.vigencia_fin) THEN
        RAISE EXCEPTION 'La tarifa % no está vigente el %', p_id_tarifa, p_fecha_creacion
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_envio_tarifa_vigente';
    END IF;

    IF v_tarifa.nivel_servicio <> p_servicio THEN
        RAISE EXCEPTION 'El servicio % no corresponde a la tarifa % (%)',
            p_servicio, p_id_tarifa, v_tarifa.nivel_servicio
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_envio_tarifa_servicio';
    END IF;

    -- 4. Totales declarados para la cotización: peso en kg, volumen en m3 (CAM-009)
    SELECT sum(x.peso), sum(x.largo * x.ancho * x.alto / 1000000)
      INTO v_peso, v_volumen
    FROM jsonb_to_recordset(p_paquetes)
         AS x(peso NUMERIC, largo NUMERIC, ancho NUMERIC, alto NUMERIC);

    IF v_peso IS NULL OR v_volumen IS NULL THEN
        RAISE EXCEPTION 'Todos los paquetes del envío % deben indicar peso y dimensiones', p_numero_guia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_envio_paquetes_requeridos';
    END IF;

    IF v_peso    NOT BETWEEN v_tarifa.rango_peso_min    AND v_tarifa.rango_peso_max
       OR v_volumen NOT BETWEEN v_tarifa.rango_volumen_min AND v_tarifa.rango_volumen_max THEN
        RAISE EXCEPTION 'El envío % (% kg, % m3) está fuera de los rangos de la tarifa %',
            p_numero_guia, round(v_peso, 3), round(v_volumen, 6), p_id_tarifa
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_envio_tarifa_rango';
    END IF;

    -- 5. Envío con direcciones y cotización copiadas (RN-04, RN-08, S-03)
    INSERT INTO envio (numero_guia, id_solicitud, id_recoleccion,
        tipo_id_pagador, numero_id_pagador,
        id_participante_remitente, id_participante_destinatario, id_tarifa,
        fecha_creacion, servicio,
        origen_provincia, origen_canton, origen_distrito, origen_otras_senas,
        destino_provincia, destino_canton, destino_distrito, destino_otras_senas,
        precio_cotizado, cotiz_zona_origen, cotiz_zona_destino,
        cotiz_peso, cotiz_volumen, cotiz_condiciones)
    VALUES (p_numero_guia, p_id_solicitud, NULL,
        p_tipo_id_pagador, p_numero_id_pagador,
        p_id_remitente, p_id_destinatario, p_id_tarifa,
        p_fecha_creacion, p_servicio,
        p_origen_provincia, p_origen_canton, p_origen_distrito, p_origen_otras_senas,
        p_destino_provincia, p_destino_canton, p_destino_distrito, p_destino_otras_senas,
        v_tarifa.precio, v_tarifa.zona_origen, v_tarifa.zona_destino,
        round(v_peso, 3), round(v_volumen, 6), v_tarifa.condicion_especial);

    -- 6. Paquetes numerados dentro del envío, sin revisión (RN-07)
    FOR v_p IN
        SELECT *
        FROM jsonb_to_recordset(p_paquetes)
             AS x(peso NUMERIC, largo NUMERIC, ancho NUMERIC, alto NUMERIC,
                  descripcion VARCHAR, politica VARCHAR, respaldo VARCHAR,
                  condiciones JSONB)
    LOOP
        v_num := v_num + 1;

        INSERT INTO paquete (numero_guia, num_paquete,
            peso_declarado, largo_declarado, ancho_declarado, alto_declarado,
            descripcion, politica_contenido, documento_respaldo)
        VALUES (p_numero_guia, v_num,
            v_p.peso, v_p.largo, v_p.ancho, v_p.alto,
            v_p.descripcion, v_p.politica, v_p.respaldo);

        IF v_p.condiciones IS NOT NULL THEN
            FOR v_condicion IN SELECT jsonb_array_elements_text(v_p.condiciones)
            LOOP
                INSERT INTO condicion_manejo_paquete (numero_guia, num_paquete, condicion)
                VALUES (p_numero_guia, v_num, v_condicion);
            END LOOP;
        END IF;
    END LOOP;

    RAISE NOTICE 'Envío % creado con % paquetes (% kg, % m3, precio %)',
        p_numero_guia, v_num, round(v_peso, 3), round(v_volumen, 6), v_tarifa.precio;
END;
$$;

-- ---------------------------------------------------------------------
-- P01.2 sp_registrar_revision
-- Proceso: G08-P01.
-- Propósito: registrar la revisión inicial de un paquete: quién, cuándo,
--   resultado y razón (RN-11).
-- Entradas: guía, número de paquete, revisor, resultado (ACEPTADO,
--   RETENIDO, RECHAZADO), razón y, opcional, documento de respaldo.
-- Modifica: PAQUETE (columnas revision_* y documento_respaldo).
-- Precondiciones: el paquete existe y aún no tiene revisión; el revisor
--   existe y es OPERADOR_SEDE.
-- Rechazos:
--   fk_paquete_envio               paquete inexistente (foreign_key_violation)
--   ck_paquete_revision_unica      el paquete ya fue revisado (RN-11: un único resultado)
--   ck_paquete_revisor_operador    el revisor no es operador de sede
--   y del esquema: ck_paquete_prohibido_rechazado, ck_paquete_respaldo_exigido,
--   ck_paquete_revision_razon (CAM-006).
-- Transacción: una sola actualización. Un rechazo o una retención se
--   guarda como decisión con su razón, pero no deja el paquete como
--   aceptado. FOR UPDATE evita que dos sesiones revisen el mismo paquete.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_revision(
    p_numero_guia VARCHAR,
    p_num_paquete INTEGER,
    p_id_revisor  INTEGER,
    p_resultado   VARCHAR,
    p_razon       VARCHAR DEFAULT NULL,
    p_respaldo    VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_paquete paquete%ROWTYPE;
BEGIN
    SELECT * INTO v_paquete
    FROM paquete p
    WHERE p.numero_guia = p_numero_guia
      AND p.num_paquete = p_num_paquete
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El paquete (%, %) no existe', p_numero_guia, p_num_paquete
            USING ERRCODE = 'foreign_key_violation', CONSTRAINT = 'fk_paquete_envio';
    END IF;

    IF v_paquete.revision_resultado IS NOT NULL THEN
        RAISE EXCEPTION 'El paquete (%, %) ya tiene revisión inicial (%)',
            p_numero_guia, p_num_paquete, v_paquete.revision_resultado
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_paquete_revision_unica';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM funcion_personal f
                   WHERE f.id_personal = p_id_revisor
                     AND f.funcion = 'OPERADOR_SEDE') THEN
        RAISE EXCEPTION 'La persona % no es operadora de sede y no puede revisar paquetes', p_id_revisor
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_paquete_revisor_operador';
    END IF;

    -- Las reglas de política, respaldo y razón las verifica el esquema (CAM-006)
    UPDATE paquete
       SET revision_fecha_hora = now(),
           revision_resultado  = p_resultado,
           revision_razon      = p_razon,
           id_personal_revisor = p_id_revisor,
           documento_respaldo  = COALESCE(p_respaldo, documento_respaldo)
     WHERE numero_guia = p_numero_guia
       AND num_paquete = p_num_paquete;

    RAISE NOTICE 'Paquete (%, %) revisado: %', p_numero_guia, p_num_paquete, p_resultado;
END;
$$;

-- ---------------------------------------------------------------------
-- P01.3 sp_registrar_medicion
-- Proceso: G08-P01.
-- Propósito: agregar una medición de un paquete sin reemplazar las
--   anteriores y, si se indica, usarla para clasificar y cobrar (RN-10, S-07).
-- Entradas: guía, número de paquete, sede, peso (kg), largo, ancho y alto
--   (cm), y si la medición pasa a ser la aplicada.
-- Modifica: MEDICION (nueva fila) y, opcionalmente, PAQUETE.num_medicion_aplicada.
-- Precondiciones: el paquete y la sede existen.
-- Rechazos:
--   fk_medicion_paquete   paquete inexistente (foreign_key_violation)
--   y del esquema: fk_medicion_sede, ck_medicion_valores.
-- Transacción: medición y medición aplicada juntas. El paquete se bloquea
--   con FOR UPDATE: si dos sesiones miden el mismo paquete, la segunda
--   espera y toma el número siguiente; ninguna sobrescribe a la otra
--   (concurrencia de P01; las mediciones no se modifican, CAM-014).
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_medicion(
    p_numero_guia VARCHAR,
    p_num_paquete INTEGER,
    p_id_sede     INTEGER,
    p_peso        NUMERIC,
    p_largo       NUMERIC,
    p_ancho       NUMERIC,
    p_alto        NUMERIC,
    p_aplicar     BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_num SMALLINT;
BEGIN
    PERFORM 1
    FROM paquete p
    WHERE p.numero_guia = p_numero_guia
      AND p.num_paquete = p_num_paquete
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El paquete (%, %) no existe', p_numero_guia, p_num_paquete
            USING ERRCODE = 'foreign_key_violation', CONSTRAINT = 'fk_medicion_paquete';
    END IF;

    SELECT COALESCE(max(m.num_medicion), 0) + 1
      INTO v_num
    FROM medicion m
    WHERE m.numero_guia = p_numero_guia
      AND m.num_paquete = p_num_paquete;

    INSERT INTO medicion (numero_guia, num_paquete, num_medicion, id_sede,
                          fecha_hora, peso, largo, ancho, alto)
    VALUES (p_numero_guia, p_num_paquete, v_num, p_id_sede,
            now(), p_peso, p_largo, p_ancho, p_alto);

    IF p_aplicar THEN
        UPDATE paquete
           SET num_medicion_aplicada = v_num
         WHERE numero_guia = p_numero_guia
           AND num_paquete = p_num_paquete;
    END IF;

    RAISE NOTICE 'Medición % registrada para el paquete (%, %)', v_num, p_numero_guia, p_num_paquete;
END;
$$;

-- =====================================================================
-- G08-P02. PREPARAR SALIDAS Y MANIFIESTOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- P02.0 sp_validar_vehiculo_disponible  (uso interno de P02)
-- Propósito: verificar que un vehículo pueda usarse en un intervalo:
--   condición OPERATIVO y sin periodo fuera de servicio que se cruce
--   con [inicio, fin) (RN-20, CAM-025).
-- Rechazos (check_violation):
--   ck_asignacion_vehiculo_existente       vehículo inexistente
--   ck_asignacion_vehiculo_operativo       en mantenimiento o fuera de servicio
--   ck_asignacion_vehiculo_fuera_servicio  periodo fuera de servicio en el intervalo
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_validar_vehiculo_disponible(
    p_id_vehiculo INTEGER,
    p_inicio      TIMESTAMPTZ,
    p_fin         TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_condicion VARCHAR;
BEGIN
    SELECT v.condicion_operativa INTO v_condicion
    FROM vehiculo v
    WHERE v.id_interno = p_id_vehiculo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El vehículo % no existe', p_id_vehiculo
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_asignacion_vehiculo_existente';
    END IF;

    IF v_condicion <> 'OPERATIVO' THEN
        RAISE EXCEPTION 'El vehículo % no está operativo (%)', p_id_vehiculo, v_condicion
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_asignacion_vehiculo_operativo';
    END IF;

    IF EXISTS (SELECT 1
               FROM periodo_fuera_servicio pf
               WHERE pf.id_interno = p_id_vehiculo
                 AND tstzrange(pf.inicio, pf.fin, '[)') && tstzrange(p_inicio, p_fin, '[)')) THEN
        RAISE EXCEPTION 'El vehículo % tiene un periodo fuera de servicio entre % y %',
            p_id_vehiculo, p_inicio, p_fin
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_asignacion_vehiculo_fuera_servicio';
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- P02.1 fn_crear_salida
-- Propósito: crear una salida fechada de una ruta del catálogo (RN-13).
-- Entradas: ruta y fecha.
-- Devuelve: el id de la salida, en estado PLANIFICADA.
-- Modifica: SALIDA_RUTA.
-- Rechazos: fk_salida_ruta_ruta (ruta inexistente).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_crear_salida(
    p_id_ruta INTEGER,
    p_fecha   DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO salida_ruta (id_ruta, fecha, estado)
    VALUES (p_id_ruta, p_fecha, 'PLANIFICADA')
    RETURNING id_salida INTO v_id;

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------
-- P02.2 sp_agregar_paquete_salida
-- Propósito: incluir un paquete en el manifiesto de una salida (RN-13, CAM-026).
-- Entradas: salida, guía y paquete.
-- Modifica: SALIDA_PAQUETE.
-- Precondiciones: la salida está PLANIFICADA; el paquete está ACEPTADO y
--   no está en otra salida PLANIFICADA, CONFIRMADA o EN_RUTA.
-- Rechazos (check_violation, salvo indicación):
--   ck_salida_existente           salida inexistente
--   ck_salida_planificada         la salida ya fue confirmada o iniciada
--   fk_salida_paquete_paquete     paquete inexistente (foreign_key_violation)
--   ck_salida_paquete_aceptado    paquete no aceptado (retenido, rechazado o sin revisar)
--   ck_salida_paquete_una_activa  el paquete está en otra salida activa
--   pk_salida_paquete             el paquete ya está en esta salida (unique_violation)
-- Transacción: la salida y el paquete se bloquean con FOR UPDATE, así una
--   confirmación o una inclusión concurrente del mismo paquete espera.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_agregar_paquete_salida(
    p_id_salida   INTEGER,
    p_numero_guia VARCHAR,
    p_num_paquete INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado    VARCHAR;
    v_resultado VARCHAR;
BEGIN
    SELECT s.estado INTO v_estado
    FROM salida_ruta s
    WHERE s.id_salida = p_id_salida
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe', p_id_salida
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_existente';
    END IF;

    IF v_estado <> 'PLANIFICADA' THEN
        RAISE EXCEPTION 'La salida % está % y su manifiesto ya está cerrado', p_id_salida, v_estado
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_planificada';
    END IF;

    SELECT p.revision_resultado INTO v_resultado
    FROM paquete p
    WHERE p.numero_guia = p_numero_guia
      AND p.num_paquete = p_num_paquete
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El paquete (%, %) no existe', p_numero_guia, p_num_paquete
            USING ERRCODE = 'foreign_key_violation', CONSTRAINT = 'fk_salida_paquete_paquete';
    END IF;

    IF v_resultado IS DISTINCT FROM 'ACEPTADO' THEN
        RAISE EXCEPTION 'El paquete (%, %) no está aceptado (%)',
            p_numero_guia, p_num_paquete, COALESCE(v_resultado, 'sin revisión')
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_paquete_aceptado';
    END IF;

    IF EXISTS (SELECT 1
               FROM salida_paquete sp
               JOIN salida_ruta s ON s.id_salida = sp.id_salida
               WHERE sp.numero_guia = p_numero_guia
                 AND sp.num_paquete = p_num_paquete
                 AND sp.id_salida <> p_id_salida
                 AND s.estado IN ('PLANIFICADA', 'CONFIRMADA', 'EN_RUTA')) THEN
        RAISE EXCEPTION 'El paquete (%, %) ya está en otra salida activa', p_numero_guia, p_num_paquete
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_paquete_una_activa';
    END IF;

    INSERT INTO salida_paquete (id_salida, numero_guia, num_paquete)
    VALUES (p_id_salida, p_numero_guia, p_num_paquete);
END;
$$;

-- ---------------------------------------------------------------------
-- P02.3 fn_asignar_salida
-- Propósito: asignar una persona y un vehículo a una salida (RN-13, RN-20,
--   RN-21, RN-22).
-- Entradas: salida, persona, vehículo, función e intervalo [inicio, fin).
-- Devuelve: el id de la asignación.
-- Modifica: ASIGNACION.
-- Precondiciones: la salida está PLANIFICADA; el vehículo está disponible.
-- Rechazos:
--   ck_salida_existente, ck_salida_planificada
--   los de sp_validar_vehiculo_disponible (CAM-025)
--   y del esquema: ex_asignacion_personal_traslape,
--   ex_asignacion_vehiculo_traslape (CAM-015), fk_asignacion_funcion_personal (CAM-016).
-- Transacción: dos sesiones que asignan el mismo recurso en horarios
--   superpuestos: la segunda espera y es rechazada por la exclusión.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_asignar_salida(
    p_id_salida   INTEGER,
    p_id_personal INTEGER,
    p_id_vehiculo INTEGER,
    p_funcion     VARCHAR,
    p_inicio      TIMESTAMPTZ,
    p_fin         TIMESTAMPTZ
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR;
    v_id     INTEGER;
BEGIN
    SELECT s.estado INTO v_estado
    FROM salida_ruta s
    WHERE s.id_salida = p_id_salida
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe', p_id_salida
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_existente';
    END IF;

    IF v_estado <> 'PLANIFICADA' THEN
        RAISE EXCEPTION 'La salida % está % y ya no admite asignaciones', p_id_salida, v_estado
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_planificada';
    END IF;

    CALL sp_validar_vehiculo_disponible(p_id_vehiculo, p_inicio, p_fin);

    INSERT INTO asignacion (id_personal, id_vehiculo, id_salida, inicio, fin, funcion_ejercida)
    VALUES (p_id_personal, p_id_vehiculo, p_id_salida, p_inicio, p_fin, p_funcion)
    RETURNING id_asignacion INTO v_id;

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------
-- P02.4 fn_sustituir_asignacion
-- Propósito: cambiar la persona o el vehículo de una asignación antes de
--   ejecutar la operación, conservando la original y el motivo (RN-23, CAM-027).
-- Entradas: asignación original, nueva persona, nuevo vehículo, función y motivo.
-- Devuelve: el id de la nueva asignación (misma operación e intervalo que
--   la original).
-- Modifica: ASIGNACION (la original pasa a vigente = false; se inserta la nueva).
-- Precondiciones: la original está vigente; su salida está PLANIFICADA
--   (o su recolección, PLANIFICADA).
-- Rechazos:
--   ck_asignacion_existente      asignación inexistente
--   ck_asignacion_vigente        la asignación ya fue sustituida
--   ck_salida_planificada        la salida ya fue confirmada o iniciada
--   ck_recoleccion_planificada   la recolección ya no está planificada
--   los de sp_validar_vehiculo_disponible y del esquema (traslapes,
--   función de la persona, motivo obligatorio).
-- Transacción: si la nueva asignación falla, nada cambia y la original
--   sigue vigente («sustitución fallida conserva plan previo válido»).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_sustituir_asignacion(
    p_id_asignacion INTEGER,
    p_id_personal   INTEGER,
    p_id_vehiculo   INTEGER,
    p_funcion       VARCHAR,
    p_motivo        VARCHAR
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_original asignacion%ROWTYPE;
    v_estado   VARCHAR;
    v_id       INTEGER;
BEGIN
    SELECT * INTO v_original
    FROM asignacion a
    WHERE a.id_asignacion = p_id_asignacion
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La asignación % no existe', p_id_asignacion
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_asignacion_existente';
    END IF;

    IF NOT v_original.vigente THEN
        RAISE EXCEPTION 'La asignación % ya fue sustituida', p_id_asignacion
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_asignacion_vigente';
    END IF;

    IF v_original.id_salida IS NOT NULL THEN
        SELECT s.estado INTO v_estado
        FROM salida_ruta s
        WHERE s.id_salida = v_original.id_salida
        FOR UPDATE;

        IF v_estado <> 'PLANIFICADA' THEN
            RAISE EXCEPTION 'La salida % está %: ya no se pueden sustituir sus asignaciones',
                v_original.id_salida, v_estado
                USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_planificada';
        END IF;
    ELSE
        SELECT r.estado INTO v_estado
        FROM recoleccion r
        WHERE r.id_recoleccion = v_original.id_recoleccion
        FOR UPDATE;

        IF v_estado <> 'PLANIFICADA' THEN
            RAISE EXCEPTION 'La recolección % está %: ya no se pueden sustituir sus asignaciones',
                v_original.id_recoleccion, v_estado
                USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_recoleccion_planificada';
        END IF;
    END IF;

    CALL sp_validar_vehiculo_disponible(p_id_vehiculo, v_original.inicio, v_original.fin);

    -- La original deja de ocupar el recurso, pero se conserva (CAM-015)
    UPDATE asignacion SET vigente = FALSE WHERE id_asignacion = p_id_asignacion;

    INSERT INTO asignacion (id_personal, id_vehiculo, id_recoleccion, id_salida,
        id_asignacion_sustituida, inicio, fin, funcion_ejercida, motivo_cambio)
    VALUES (p_id_personal, p_id_vehiculo, v_original.id_recoleccion, v_original.id_salida,
        p_id_asignacion, v_original.inicio, v_original.fin, p_funcion, p_motivo)
    RETURNING id_asignacion INTO v_id;

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------
-- P02.5 sp_confirmar_salida
-- Propósito: dar por preparada una salida (CAM-025, CAM-026, CAM-027).
-- Entradas: salida.
-- Modifica: SALIDA_RUTA.estado = CONFIRMADA (cierra el manifiesto).
-- Verifica: al menos un paquete; al menos un CONDUCTOR vigente; un único
--   vehículo vigente, disponible en cada asignación; peso y volumen del
--   manifiesto (medición aplicada o declarado, S-07) dentro de la
--   capacidad; vehículo refrigerado si algún paquete tiene REFRIGERACION.
-- Rechazos (check_violation):
--   ck_salida_existente, ck_salida_planificada
--   ck_salida_con_paquetes, ck_salida_con_conductor, ck_salida_un_vehiculo
--   ck_salida_capacidad_peso, ck_salida_capacidad_volumen, ck_salida_refrigeracion
--   y los de sp_validar_vehiculo_disponible.
-- Transacción: la salida se bloquea con FOR UPDATE; ningún paquete ni
--   asignación puede agregarse mientras se revisa. Si falla, la salida
--   sigue PLANIFICADA.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_confirmar_salida(p_id_salida INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado     VARCHAR;
    v_vehiculo   vehiculo%ROWTYPE;
    v_vehiculos  INTEGER;
    v_asig       RECORD;
    v_peso       NUMERIC;
    v_volumen    NUMERIC;
BEGIN
    SELECT s.estado INTO v_estado
    FROM salida_ruta s
    WHERE s.id_salida = p_id_salida
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe', p_id_salida
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_existente';
    END IF;

    IF v_estado <> 'PLANIFICADA' THEN
        RAISE EXCEPTION 'La salida % está % y no puede confirmarse', p_id_salida, v_estado
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_planificada';
    END IF;

    -- Manifiesto no vacío
    IF NOT EXISTS (SELECT 1 FROM salida_paquete sp WHERE sp.id_salida = p_id_salida) THEN
        RAISE EXCEPTION 'La salida % no tiene paquetes en su manifiesto', p_id_salida
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_con_paquetes';
    END IF;

    -- Al menos un conductor vigente
    IF NOT EXISTS (SELECT 1 FROM asignacion a
                   WHERE a.id_salida = p_id_salida
                     AND a.vigente
                     AND a.funcion_ejercida = 'CONDUCTOR') THEN
        RAISE EXCEPTION 'La salida % no tiene un conductor asignado', p_id_salida
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_con_conductor';
    END IF;

    -- Un único vehículo entre las asignaciones vigentes
    SELECT count(DISTINCT a.id_vehiculo) INTO v_vehiculos
    FROM asignacion a
    WHERE a.id_salida = p_id_salida AND a.vigente;

    IF v_vehiculos <> 1 THEN
        RAISE EXCEPTION 'La salida % tiene % vehículos distintos asignados; debe tener uno', p_id_salida, v_vehiculos
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_un_vehiculo';
    END IF;

    SELECT v.* INTO v_vehiculo
    FROM vehiculo v
    WHERE v.id_interno = (SELECT a.id_vehiculo FROM asignacion a
                          WHERE a.id_salida = p_id_salida AND a.vigente
                          LIMIT 1);

    -- Disponibilidad del vehículo en cada asignación vigente
    FOR v_asig IN
        SELECT a.inicio, a.fin FROM asignacion a
        WHERE a.id_salida = p_id_salida AND a.vigente
    LOOP
        CALL sp_validar_vehiculo_disponible(v_vehiculo.id_interno, v_asig.inicio, v_asig.fin);
    END LOOP;

    -- Carga del manifiesto: medición aplicada o, si no hay, lo declarado (S-07)
    SELECT sum(COALESCE(m.peso, p.peso_declarado)),
           sum(COALESCE(m.largo, p.largo_declarado)
             * COALESCE(m.ancho, p.ancho_declarado)
             * COALESCE(m.alto,  p.alto_declarado) / 1000000)
      INTO v_peso, v_volumen
    FROM salida_paquete sp
    JOIN paquete p
      ON p.numero_guia = sp.numero_guia AND p.num_paquete = sp.num_paquete
    LEFT JOIN medicion m
      ON m.numero_guia = p.numero_guia
     AND m.num_paquete = p.num_paquete
     AND m.num_medicion = p.num_medicion_aplicada
    WHERE sp.id_salida = p_id_salida;

    IF v_peso > v_vehiculo.capacidad_peso THEN
        RAISE EXCEPTION 'La carga de la salida % (% kg) supera la capacidad del vehículo % (% kg)',
            p_id_salida, round(v_peso, 3), v_vehiculo.placa, v_vehiculo.capacidad_peso
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_capacidad_peso';
    END IF;

    IF v_volumen > v_vehiculo.capacidad_volumen THEN
        RAISE EXCEPTION 'El volumen de la salida % (% m3) supera la capacidad del vehículo % (% m3)',
            p_id_salida, round(v_volumen, 6), v_vehiculo.placa, v_vehiculo.capacidad_volumen
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_capacidad_volumen';
    END IF;

    -- Refrigeración (RN-20, condiciones)
    IF NOT v_vehiculo.refrigerado
       AND EXISTS (SELECT 1
                   FROM salida_paquete sp
                   JOIN condicion_manejo_paquete c
                     ON c.numero_guia = sp.numero_guia AND c.num_paquete = sp.num_paquete
                   WHERE sp.id_salida = p_id_salida
                     AND c.condicion = 'REFRIGERACION') THEN
        RAISE EXCEPTION 'La salida % lleva paquetes refrigerados y el vehículo % no es refrigerado',
            p_id_salida, v_vehiculo.placa
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_refrigeracion';
    END IF;

    UPDATE salida_ruta SET estado = 'CONFIRMADA' WHERE id_salida = p_id_salida;

    RAISE NOTICE 'Salida % confirmada: % kg de % kg, % m3 de % m3, vehículo %',
        p_id_salida, round(v_peso, 3), v_vehiculo.capacidad_peso,
        round(v_volumen, 6), v_vehiculo.capacidad_volumen, v_vehiculo.placa;
END;
$$;

-- ---------------------------------------------------------------------
-- P02.6 sp_iniciar_salida
-- Propósito: registrar la partida de una salida confirmada (S-12, CAM-026).
-- Entradas: salida.
-- Modifica: SALIDA_RUTA.estado = EN_RUTA.
-- Rechazos (check_violation): ck_salida_existente, ck_salida_confirmada.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_iniciar_salida(p_id_salida INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR;
BEGIN
    SELECT s.estado INTO v_estado
    FROM salida_ruta s
    WHERE s.id_salida = p_id_salida
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La salida % no existe', p_id_salida
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_existente';
    END IF;

    IF v_estado <> 'CONFIRMADA' THEN
        RAISE EXCEPTION 'La salida % está % y solo puede iniciarse si está confirmada', p_id_salida, v_estado
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_salida_confirmada';
    END IF;

    UPDATE salida_ruta SET estado = 'EN_RUTA' WHERE id_salida = p_id_salida;
END;
$$;

-- =====================================================================
-- G08-P03. REGISTRAR SEGUIMIENTO E INCIDENCIAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- P03.1 fn_registrar_evento
-- Propósito: registrar un movimiento o situación de un paquete (RN-12, RN-24).
-- Entradas: guía, paquete, momento en que ocurrió el hecho, responsable,
--   tipo de evento, situación, condición y, opcionales, sede, descripción
--   de la ubicación, salida y observaciones.
-- Devuelve: el id del evento creado.
-- Modifica: EVENTO_SEGUIMIENTO (una fila nueva; nunca modifica anteriores).
-- Precondiciones: el paquete y el responsable existen; si se indica una
--   salida, el paquete está en su manifiesto.
-- Rechazos:
--   fk_evento_seguimiento_paquete        paquete inexistente (foreign_key_violation)
--   ck_evento_seguimiento_momento        hecho con fecha futura
--   y del esquema: ck_evento_seguimiento_ubicacion (CAM-007),
--   fk_evento_seguimiento_salida_paquete (CAM-018), dominios.
-- Transacción: una sola inserción. El momento de registro lo pone la base,
--   así se distingue un hecho registrado después de ocurrir (CAM-003).
--   Dos sesiones pueden registrar eventos del mismo paquete a la vez:
--   ambos se conservan y el actual se determina por el orden de CAM-003.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_registrar_evento(
    p_numero_guia           VARCHAR,
    p_num_paquete           INTEGER,
    p_momento               TIMESTAMPTZ,
    p_id_personal           INTEGER,
    p_tipo_evento           VARCHAR,
    p_situacion             VARCHAR,
    p_condicion             VARCHAR,
    p_id_sede               INTEGER DEFAULT NULL,
    p_descripcion_ubicacion VARCHAR DEFAULT NULL,
    p_id_salida             INTEGER DEFAULT NULL,
    p_observaciones         VARCHAR DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM paquete p
                   WHERE p.numero_guia = p_numero_guia
                     AND p.num_paquete = p_num_paquete) THEN
        RAISE EXCEPTION 'El paquete (%, %) no existe', p_numero_guia, p_num_paquete
            USING ERRCODE = 'foreign_key_violation', CONSTRAINT = 'fk_evento_seguimiento_paquete';
    END IF;

    IF p_momento > now() THEN
        RAISE EXCEPTION 'El momento del evento (%) no puede ser futuro', p_momento
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_evento_seguimiento_momento';
    END IF;

    INSERT INTO evento_seguimiento (numero_guia, num_paquete, momento, id_personal,
        id_sede, descripcion_ubicacion, id_salida,
        tipo_evento, situacion, condicion, observaciones)
    VALUES (p_numero_guia, p_num_paquete, p_momento, p_id_personal,
        p_id_sede, p_descripcion_ubicacion, p_id_salida,
        p_tipo_evento, p_situacion, p_condicion, p_observaciones)
    RETURNING id_evento INTO v_id;

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------
-- P03.2 fn_corregir_evento
-- Propósito: corregir un evento registrado por error sin modificarlo ni
--   borrarlo (RN-25): se crea un evento nuevo que lo reemplaza.
-- Entradas: evento original, autor de la corrección, motivo y los datos
--   correctos del evento.
-- Devuelve: el id del evento de corrección.
-- Modifica: EVENTO_SEGUIMIENTO (una fila nueva).
-- Precondiciones: el evento original existe y no fue corregido antes.
-- Rechazos:
--   fk_evento_seguimiento_corregido   evento original inexistente
--   uq_evento_seguimiento_corregido   el evento ya tiene corrección (unique_violation)
--   ck_evento_seguimiento_correccion  corrección sin motivo
--   y las mismas reglas de un evento normal.
-- Transacción: el evento original se bloquea con FOR UPDATE; si dos sesiones
--   corrigen el mismo evento, la segunda espera y luego es rechazada.
--   La corrección es del mismo paquete que el original (CAM-018).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_corregir_evento(
    p_id_evento_original    INTEGER,
    p_id_autor              INTEGER,
    p_motivo                VARCHAR,
    p_momento               TIMESTAMPTZ,
    p_tipo_evento           VARCHAR,
    p_situacion             VARCHAR,
    p_condicion             VARCHAR,
    p_id_sede               INTEGER DEFAULT NULL,
    p_descripcion_ubicacion VARCHAR DEFAULT NULL,
    p_id_salida             INTEGER DEFAULT NULL,
    p_observaciones         VARCHAR DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_original evento_seguimiento%ROWTYPE;
    v_id       INTEGER;
BEGIN
    SELECT * INTO v_original
    FROM evento_seguimiento e
    WHERE e.id_evento = p_id_evento_original
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El evento % no existe', p_id_evento_original
            USING ERRCODE = 'foreign_key_violation', CONSTRAINT = 'fk_evento_seguimiento_corregido';
    END IF;

    IF EXISTS (SELECT 1 FROM evento_seguimiento e
               WHERE e.id_evento_corregido = p_id_evento_original) THEN
        RAISE EXCEPTION 'El evento % ya fue corregido', p_id_evento_original
            USING ERRCODE = 'unique_violation', CONSTRAINT = 'uq_evento_seguimiento_corregido';
    END IF;

    IF p_momento > now() THEN
        RAISE EXCEPTION 'El momento del evento (%) no puede ser futuro', p_momento
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_evento_seguimiento_momento';
    END IF;

    INSERT INTO evento_seguimiento (numero_guia, num_paquete, momento, id_personal,
        id_sede, descripcion_ubicacion, id_salida, id_evento_corregido,
        tipo_evento, situacion, condicion, observaciones, motivo_correccion)
    VALUES (v_original.numero_guia, v_original.num_paquete, p_momento, p_id_autor,
        p_id_sede, p_descripcion_ubicacion, p_id_salida, p_id_evento_original,
        p_tipo_evento, p_situacion, p_condicion, p_observaciones, p_motivo)
    RETURNING id_evento INTO v_id;

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------
-- P03.3 fn_registrar_incidencia
-- Propósito: registrar una incidencia que afecta uno o varios paquetes,
--   cada uno con su propio resultado (RN-17, RN-18).
-- Entradas: responsable de atención, tipo, descripción, lista de paquetes
--   en JSON ([{"guia": "...", "paquete": 1}, ...]) y fecha.
-- Devuelve: el id de la incidencia.
-- Modifica: INCIDENCIA (estado ABIERTA) e INCIDENCIA_PAQUETE (cada
--   paquete en PENDIENTE, CAM-021).
-- Rechazos:
--   ck_incidencia_paquetes_requeridos  lista vacía o inválida
--   y del esquema: fk_incidencia_paquete_paquete (paquete inexistente),
--   pk_incidencia_paquete (paquete repetido), dominios.
-- Transacción: la incidencia y todos sus paquetes en una sola operación.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_registrar_incidencia(
    p_id_personal INTEGER,
    p_tipo        VARCHAR,
    p_descripcion VARCHAR,
    p_paquetes    JSONB,
    p_fecha       DATE DEFAULT CURRENT_DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id INTEGER;
BEGIN
    IF p_paquetes IS NULL
       OR jsonb_typeof(p_paquetes) <> 'array'
       OR jsonb_array_length(p_paquetes) = 0 THEN
        RAISE EXCEPTION 'La incidencia debe afectar al menos un paquete'
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_paquetes_requeridos';
    END IF;

    INSERT INTO incidencia (id_personal, tipo, fecha, descripcion, estado)
    VALUES (p_id_personal, p_tipo, p_fecha, p_descripcion, 'ABIERTA')
    RETURNING id_incidencia INTO v_id;

    INSERT INTO incidencia_paquete (id_incidencia, numero_guia, num_paquete)
    SELECT v_id, x.guia, x.paquete
    FROM jsonb_to_recordset(p_paquetes) AS x(guia VARCHAR, paquete INTEGER);

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------
-- P03.4 sp_resolver_paquete_incidencia
-- Propósito: determinar el resultado de una incidencia para un paquete (RN-18).
-- Entradas: incidencia, guía, paquete y resultado (RESUELTO o SIN_SOLUCION).
-- Modifica: INCIDENCIA_PAQUETE.resultado; la incidencia pasa de ABIERTA a
--   EN_ATENCION.
-- Rechazos (check_violation):
--   ck_incidencia_existente            incidencia inexistente
--   ck_incidencia_no_resuelta          la incidencia ya está RESUELTA
--   ck_incidencia_paquete_afectado     el paquete no está en la incidencia
--   ck_incidencia_paquete_resultado    resultado fuera del dominio o PENDIENTE
-- Transacción: la incidencia se bloquea con FOR UPDATE, así dos sesiones que
--   resuelven la misma incidencia se ejecutan una tras otra sin perder datos.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_resolver_paquete_incidencia(
    p_id_incidencia INTEGER,
    p_numero_guia   VARCHAR,
    p_num_paquete   INTEGER,
    p_resultado     VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR;
BEGIN
    SELECT i.estado INTO v_estado
    FROM incidencia i
    WHERE i.id_incidencia = p_id_incidencia
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La incidencia % no existe', p_id_incidencia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_existente';
    END IF;

    IF v_estado = 'RESUELTA' THEN
        RAISE EXCEPTION 'La incidencia % ya está resuelta', p_id_incidencia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_no_resuelta';
    END IF;

    IF p_resultado NOT IN ('RESUELTO', 'SIN_SOLUCION') THEN
        RAISE EXCEPTION 'Resultado inválido: %', p_resultado
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_paquete_resultado';
    END IF;

    UPDATE incidencia_paquete
       SET resultado = p_resultado
     WHERE id_incidencia = p_id_incidencia
       AND numero_guia   = p_numero_guia
       AND num_paquete   = p_num_paquete;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El paquete (%, %) no está afectado por la incidencia %',
            p_numero_guia, p_num_paquete, p_id_incidencia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_paquete_afectado';
    END IF;

    IF v_estado = 'ABIERTA' THEN
        UPDATE incidencia SET estado = 'EN_ATENCION' WHERE id_incidencia = p_id_incidencia;
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- P03.5 sp_cerrar_incidencia
-- Propósito: marcar una incidencia como RESUELTA con su resolución (RN-17).
-- Entradas: incidencia y texto de la resolución.
-- Modifica: INCIDENCIA (estado y resolución).
-- Rechazos (check_violation):
--   ck_incidencia_existente          incidencia inexistente
--   ck_incidencia_no_resuelta        ya estaba resuelta
--   ck_incidencia_sin_pendientes     algún paquete sigue PENDIENTE
--   y del esquema: ck_incidencia_resolucion (resolución vacía).
-- Transacción: la incidencia se bloquea con FOR UPDATE; una resolución
--   concurrente de un paquete termina antes de comprobar los pendientes.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_cerrar_incidencia(
    p_id_incidencia INTEGER,
    p_resolucion    VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado     VARCHAR;
    v_pendientes INTEGER;
BEGIN
    SELECT i.estado INTO v_estado
    FROM incidencia i
    WHERE i.id_incidencia = p_id_incidencia
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La incidencia % no existe', p_id_incidencia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_existente';
    END IF;

    IF v_estado = 'RESUELTA' THEN
        RAISE EXCEPTION 'La incidencia % ya está resuelta', p_id_incidencia
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_no_resuelta';
    END IF;

    SELECT count(*) INTO v_pendientes
    FROM incidencia_paquete ip
    WHERE ip.id_incidencia = p_id_incidencia
      AND ip.resultado = 'PENDIENTE';

    IF v_pendientes > 0 THEN
        RAISE EXCEPTION 'La incidencia % tiene % paquetes pendientes y no puede cerrarse',
            p_id_incidencia, v_pendientes
            USING ERRCODE = 'check_violation', CONSTRAINT = 'ck_incidencia_sin_pendientes';
    END IF;

    UPDATE incidencia
       SET estado = 'RESUELTA', resolucion = p_resolucion
     WHERE id_incidencia = p_id_incidencia;
END;
$$;