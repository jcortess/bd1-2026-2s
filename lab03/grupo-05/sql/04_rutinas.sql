
-- C1. Función 1: Contar revisiones veterinarias de un animal

CREATE OR REPLACE FUNCTION contar_revisiones_animal(
    p_codigo_animal VARCHAR
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM evaluacion_salud
    WHERE animal_codigo = p_codigo_animal
      AND tipo_evaluacion = 'REVISION_VETERINARIA';

    RETURN v_total;
END;
$$;

-- C1. Función 2: Consultar el estado de una aplicación

CREATE OR REPLACE FUNCTION estado_aplicacion(
    p_id_aplicacion INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_planificada DATE;
    v_fecha_real DATE;
BEGIN
    SELECT fecha_planificada, fecha_real
    INTO STRICT v_fecha_planificada, v_fecha_real
    FROM aplicacion_indicacion
    WHERE id_aplicacion = p_id_aplicacion;

    IF v_fecha_real IS NOT NULL THEN
        RETURN 'REALIZADA';
    ELSIF v_fecha_planificada < CURRENT_DATE THEN
        RETURN 'VENCIDA';
    ELSE
        RETURN 'PROGRAMADA';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'No existe la aplicación con ID %',
            p_id_aplicacion;
END;
$$;



-- C2. Procedimiento: Registrar una aplicación realizada

CREATE OR REPLACE PROCEDURE registrar_aplicacion(
    p_id_aplicacion INTEGER,
    p_fecha_real DATE,
    p_responsable_id INTEGER,
    p_observaciones TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_fecha_real DATE;
BEGIN
    -- Verificar que la aplicación exista
    SELECT fecha_real
    INTO v_fecha_real
    FROM aplicacion_indicacion
    WHERE id_aplicacion = p_id_aplicacion
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No existe la aplicación con ID %',
            p_id_aplicacion;
    END IF;

    -- Evitar registrar dos veces una aplicación
    IF v_fecha_real IS NOT NULL THEN
        RAISE EXCEPTION
            'La aplicación % ya fue realizada',
            p_id_aplicacion;
    END IF;

    -- Validar los datos obligatorios
    IF p_fecha_real IS NULL
       OR p_responsable_id IS NULL
       OR NULLIF(BTRIM(p_observaciones), '') IS NULL THEN
        RAISE EXCEPTION
            'Debe indicar fecha, responsable y observaciones';
    END IF;

    -- Registrar la aplicación
    UPDATE aplicacion_indicacion
    SET fecha_real = p_fecha_real,
        responsable_id = p_responsable_id,
        observaciones = p_observaciones
    WHERE id_aplicacion = p_id_aplicacion;

END;
$$;



-- C3. Procedimiento para generar un reporte temporal
-- de aplicaciones veterinarias pendientes.

CREATE OR REPLACE PROCEDURE generar_reporte_pendientes()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS pg_temp.reporte_pendientes;

    CREATE TEMP TABLE reporte_pendientes
    ON COMMIT PRESERVE ROWS
    AS
    SELECT
        a.codigo_interno,
        a.nombre AS nombre_animal,
        i.descripcion AS indicacion,
        ap.fecha_planificada,
        CASE
            WHEN ap.fecha_planificada < CURRENT_DATE
                THEN 'VENCIDA'
            ELSE 'PROGRAMADA'
        END AS estado
    FROM aplicacion_indicacion ap
    JOIN indicacion i
        ON ap.indicacion_id = i.id_indicacion
    JOIN evaluacion_salud e
        ON i.evaluacion_id = e.id_evaluacion
    JOIN animal a
        ON e.animal_codigo = a.codigo_interno
    WHERE ap.fecha_real IS NULL;
END;
$$;

