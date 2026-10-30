-- =====================================================================
-- 04_rutinas.sql
-- Funciones y procedimientos PL/pgSQL
-- Requiere haber ejecutado 01_esquema.sql y 02_datos.sql
-- Orden oficial: 01 -> 02 -> 04 -> 03 -> 05
-- =====================================================================

-- ---------------------------------------------------------------------
-- F1. fn_solicitudes_cliente
-- Propósito: consultar las solicitudes de un cliente, con rango de fechas opcional.
-- Parámetros:
--   p_tipo_id, p_numero_id : identificación del cliente
--   p_desde, p_hasta       : rango de fechas opcional (NULL = sin límite)
-- Retorno: tabla (id_solicitud, fecha, nivel_servicio, destino)
-- Regla: si el cliente no existe se rechaza, en vez de devolver vacío
--        (vacío significaría "el cliente no tiene solicitudes", que es distinto).
-- Ejemplos:
--   SELECT * FROM fn_solicitudes_cliente('CEDULA_JURIDICA','3-101-111111');
--     -> 3 filas (solicitudes 4, 5 y 6)
--   SELECT * FROM fn_solicitudes_cliente('CEDULA_JURIDICA','3-101-111111',
--                                        '2026-10-01', '2026-10-31');
--     -> 2 filas (solicitudes 5 y 6)
--   SELECT * FROM fn_solicitudes_cliente('DIMEX','155800000001');
--     -> 0 filas (existe, pero no tiene solicitudes)
--   SELECT * FROM fn_solicitudes_cliente('DIMEX','999');
--     -> ERROR: El cliente (DIMEX, 999) no existe
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
-- Propósito: clasificar una solicitud según su urgencia, combinando
--            el nivel de servicio (solicitud) y el contrato (cliente).
-- Parámetro: p_id_solicitud
-- Retorno: 'CRITICA', 'ALTA', 'NORMAL' o 'BAJA'
-- Regla (PROPUESTA, el equipo debe confirmarla):
--   MISMO_DIA                                -> CRITICA
--   EXPRESS con cliente CONTRATO_CORPORATIVO -> CRITICA
--   EXPRESS (otros clientes)                 -> ALTA
--   ESTANDAR                                 -> NORMAL
--   ECONOMICO                                -> BAJA
-- El orden de los WHEN importa: se aplica el primero que se cumpla.
-- Ejemplos:
--   SELECT fn_prioridad_solicitud(6);  -> 'CRITICA'
--   SELECT fn_prioridad_solicitud(5);  -> 'CRITICA'
--   SELECT fn_prioridad_solicitud(2);  -> 'ALTA'
--   SELECT fn_prioridad_solicitud(4);  -> 'BAJA'
--   SELECT fn_prioridad_solicitud(999);-> ERROR: La solicitud 999 no existe
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
-- Propósito: registrar un contacto de una organización junto con su primera
--            facultad y su primer medio de contacto (3 tablas, una operación).
-- Parámetros: identificación del cliente, nombre del contacto, facultad,
--             tipo de medio y valor del medio.
-- Validaciones previas:
--   1. El cliente debe existir.
--   2. El cliente debe ser una organización (PERSONA_JURIDICA): RN-02 y S-02
--      indican que solo las organizaciones registran contactos. Es una regla
--      entre dos tablas (contacto y cliente) que un CHECK no puede expresar.
-- La facultad se inserta junto con el contacto porque S-02 exige al menos una.
-- Las restricciones declarativas (dominios, valor no vacío, claves) siguen en
-- el esquema: el procedimiento NO las reemplaza.
-- Atomicidad: si algo falla, no se guarda nada.
-- Ejemplos:
--   Exitoso:   CALL sp_registrar_contacto('CEDULA_JURIDICA','3-102-222222',
--              'Andrés Rojas Mora','AUTORIZAR_CARGOS','CORREO',
--              'andres.rojas@cafemontana.example');
--   Rechazado: CALL sp_registrar_contacto('CEDULA_FISICA','2-2222-2222',
--              'Tía Marta','SOLICITAR_SERVICIOS','TELEFONO','8888-0099');
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
-- C3. fn_reporte_prioridades  (técnica: CURSOR EXPLÍCITO)
-- Propósito: recorrer las solicitudes una por una y calcular la prioridad
--            de cada una con fn_prioridad_solicitud.
-- Retorno: tabla (id_solicitud, nombre_cliente, prioridad)
-- Ejemplo: SELECT * FROM fn_reporte_prioridades();
--   -> 7 filas: 1 NORMAL, 2 ALTA, 3 BAJA, 4 BAJA, 5 CRITICA, 6 CRITICA, 7 NORMAL
--
-- Justificación y discusión:
--   El cursor se usa aquí con fines didácticos: procesa fila por fila y
--   permite aplicar lógica procedural a cada una. Existe una alternativa
--   más simple y normalmente más rápida con SQL basado en conjuntos
--   (un solo SELECT), que da el mismo resultado:
--
--   SELECT s.id_solicitud,
--          c.nombre_razon_social AS nombre_cliente,
--          fn_prioridad_solicitud(s.id_solicitud) AS prioridad
--   FROM solicitud s
--   JOIN cliente c ON c.tipo_id = s.tipo_id AND c.numero_id = s.numero_id
--   ORDER BY s.id_solicitud;
--
--   El cursor tendría sentido si cada fila requiriera varios pasos
--   dependientes entre sí, o si se procesara un volumen grande por lotes.
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