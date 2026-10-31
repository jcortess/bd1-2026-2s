
-- LABORATORIO 3 - TALLER RUTA 27


-- ==========================================
-- FUNCION 1: TOTAL DE ORDENES POR CLIENTE
-- ==========================================
-- Cuenta las visitas facturadas a un cliente.

CREATE OR REPLACE FUNCTION fn_total_ordenes_cliente(
    p_cliente_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO v_total
    FROM orden_trabajo
    WHERE cliente_factura_id = p_cliente_id;

    RETURN v_total;
END;
$$;


-- ==========================================
-- FUNCION 2: PRIORIDAD DE UNA ORDEN
-- ==========================================
-- Determina la prioridad segun el hallazgo
-- mas urgente registrado en una orden.

CREATE OR REPLACE FUNCTION fn_prioridad_orden(
    p_orden_id INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_nivel INTEGER;
BEGIN
    SELECT MAX(
        CASE urgencia
            WHEN 'Baja' THEN 1
            WHEN 'Media' THEN 2
            WHEN 'Alta' THEN 3
            WHEN 'Crítica' THEN 4
        END
    )
    INTO v_nivel
    FROM hallazgo
    WHERE orden_id = p_orden_id;

    IF v_nivel IS NULL THEN
        RETURN 'Sin hallazgos';

    ELSIF v_nivel = 4 THEN
        RETURN 'Atención inmediata';

    ELSIF v_nivel = 3 THEN
        RETURN 'Revisión prioritaria';

    ELSIF v_nivel = 2 THEN
        RETURN 'Atención programada';

    ELSE
        RETURN 'Baja prioridad';
    END IF;
END;
$$;


-- ==========================================
-- PROCEDIMIENTO: REGISTRAR ORDEN
-- ==========================================
-- Registra una orden de trabajo y su estado
-- inicial, despues de validar condiciones.

CREATE OR REPLACE PROCEDURE sp_registrar_orden(
    p_orden_id INTEGER,
    p_vin VARCHAR(17),
    p_cliente_factura_id INTEGER,
    p_entregado_por_cliente_id INTEGER,
    p_autorizador_cliente_id INTEGER,
    p_receptor_id INTEGER,
    p_kilometraje_ingreso INTEGER,
    p_nivel_combustible VARCHAR(10),
    p_motivo_informado TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar identificador.
    IF p_orden_id IS NULL OR p_orden_id <= 0 THEN
        RAISE EXCEPTION
            'El identificador de orden debe ser positivo';
    END IF;

    -- Validar kilometraje.
    IF p_kilometraje_ingreso IS NULL
       OR p_kilometraje_ingreso < 0 THEN
        RAISE EXCEPTION
            'El kilometraje de ingreso no puede ser negativo ni nulo';
    END IF;

    -- Comprobar que el vehiculo exista.
    IF NOT EXISTS (
        SELECT 1
        FROM vehiculo
        WHERE vin = p_vin
    ) THEN
        RAISE EXCEPTION
            'No existe el vehículo con VIN %', p_vin;
    END IF;

    -- Evitar registrar una orden duplicada.
    IF EXISTS (
        SELECT 1
        FROM orden_trabajo
        WHERE orden_id = p_orden_id
    ) THEN
        RAISE EXCEPTION
            'Ya existe la orden %', p_orden_id;
    END IF;

    -- Crear la orden de trabajo.
    INSERT INTO orden_trabajo (
        orden_id,
        vin,
        cliente_factura_id,
        entregado_por_cliente_id,
        autorizador_cliente_id,
        receptor_id,
        kilometraje_ingreso,
        nivel_combustible,
        motivo_informado
    )
    VALUES (
        p_orden_id,
        p_vin,
        p_cliente_factura_id,
        p_entregado_por_cliente_id,
        p_autorizador_cliente_id,
        p_receptor_id,
        p_kilometraje_ingreso,
        p_nivel_combustible,
        p_motivo_informado
    );

    -- Registrar el estado inicial.
    INSERT INTO historial_orden (
        orden_id,
        estado,
        personal_id
    )
    VALUES (
        p_orden_id,
        'Recibida',
        p_receptor_id
    );
END;
$$;


-- ==========================================
-- COMPROBACION DE FUNCIONES
-- ==========================================

-- El cliente 101 tiene dos ordenes.
SELECT fn_total_ordenes_cliente(101)
    AS visitas_cliente_101;

-- La orden 9003 tiene un hallazgo critico.
SELECT fn_prioridad_orden(9003)
    AS prioridad_orden_9003;

-- La orden 9005 no tiene hallazgos.
SELECT fn_prioridad_orden(9005)
    AS prioridad_orden_sin_hallazgos;


-- ==========================================
-- TECNICA ADICIONAL: TABLA TEMPORAL
-- ==========================================
-- Crea un resumen de las prioridades
-- de las ordenes durante esta sesion.

DROP TABLE IF EXISTS pg_temp.tmp_resumen_prioridades;

CREATE TEMP TABLE tmp_resumen_prioridades AS
SELECT
    o.orden_id,
    v.placa,
    fn_prioridad_orden(o.orden_id) AS prioridad
FROM orden_trabajo o
JOIN vehiculo v
    ON v.vin = o.vin;

-- Mostrar los resultados.
SELECT *
FROM tmp_resumen_prioridades
ORDER BY orden_id;

-- ALTERNATIVA SIN TABLA TEMPORAL:
-- Esta consulta directa es mas sencilla
-- cuando el resumen solo se utiliza una vez.

-- SELECT
--     o.orden_id,
--     v.placa,
--     fn_prioridad_orden(o.orden_id) AS prioridad
-- FROM orden_trabajo o
-- JOIN vehiculo v
--     ON v.vin = o.vin;
