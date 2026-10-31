-- LABORATORIO 3 - TALLER RUTA 27
-- GRUPO 02
-- Archivo: 05_pruebas.sql
-- Responsable: Rachel
-- Pruebas de integridad y procedimientos.

-- Las pruebas se ejecutan dentro de una
-- transacción que se revierte al finalizar.
-- Los casos inválidos se capturan mediante
-- bloques EXCEPTION para continuar ejecutando.

BEGIN;

-- =========================================
-- PRUEBA 01: REGISTRAR CLIENTE VÁLIDO
-- =========================================
-- Precondición: tablas creadas y datos cargados.
-- Esperado: inserción exitosa.

INSERT INTO cliente
(cliente_id, identificacion, nombre_razon_social, tipo_cliente)
VALUES
(999001, 'FICT-PRUEBA01', 'Cliente de Prueba', 'Persona');

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM cliente WHERE cliente_id = 999001
    ) THEN
        RAISE EXCEPTION 'P01: No se registró el cliente';
    END IF;

    RAISE NOTICE 'P01 APROBADA: cliente registrado';
END;
$$;


-- =========================================
-- PRUEBA 02: PROCEDIMIENTO VÁLIDO
-- =========================================
-- Esperado: crear una orden y su estado inicial.

CALL sp_registrar_orden(
    9901,
    '1HGCM82633A123456',
    101,
    101,
    101,
    201,
    86000,
    '1/2',
    'Revisión general de prueba'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM orden_trabajo
        WHERE orden_id = 9901
    ) OR NOT EXISTS (
        SELECT 1 FROM historial_orden
        WHERE orden_id = 9901 AND estado = 'Recibida'
    ) THEN
        RAISE EXCEPTION 'P02: La orden o su historial no existe';
    END IF;

    RAISE NOTICE 'P02 APROBADA: orden e historial creados';
END;
$$;


-- =========================================
-- PRUEBA 03: HALLAZGO VÁLIDO
-- =========================================
-- Esperado: registrar un hallazgo de urgencia alta.

INSERT INTO hallazgo (
    hallazgo_id, orden_id, sintoma_comprobado,
    posible_causa, urgencia, recomendacion
)
VALUES (
    4901, 9901, 'Ruido en motor',
    'Posible desgaste', 'Alta',
    'Realizar diagnóstico mecánico'
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hallazgo
        WHERE hallazgo_id = 4901
    ) THEN
        RAISE EXCEPTION 'P03: No se registró el hallazgo';
    END IF;

    RAISE NOTICE 'P03 APROBADA: hallazgo registrado';
END;
$$;


-- =========================================
-- PRUEBA 04: IDENTIFICACIÓN DUPLICADA
-- =========================================
-- Esperado: PostgreSQL rechaza el duplicado.

DO $$
DECLARE
    v_rechazado BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO cliente
        (cliente_id, identificacion,
         nombre_razon_social, tipo_cliente)
        VALUES
        (999002, 'FICT-P001', 'Duplicado', 'Persona');

    EXCEPTION WHEN unique_violation THEN
        v_rechazado := TRUE;
    END;

    IF NOT v_rechazado THEN
        RAISE EXCEPTION 'P04: No se rechazó el duplicado';
    END IF;

    RAISE NOTICE 'P04 APROBADA: duplicado rechazado';
END;
$$;


-- =========================================
-- PRUEBA 05: ORDEN INEXISTENTE
-- =========================================
-- Esperado: rechazo por clave foránea.

DO $$
DECLARE
    v_rechazado BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO historial_orden
        (orden_id, estado, personal_id)
        VALUES
        (999999, 'Recibida', 201);

    EXCEPTION WHEN foreign_key_violation THEN
        v_rechazado := TRUE;
    END;

    IF NOT v_rechazado THEN
        RAISE EXCEPTION 'P05: No se rechazó la FK inválida';
    END IF;

    RAISE NOTICE 'P05 APROBADA: referencia inválida rechazada';
END;
$$;


-- =========================================
-- PRUEBA 06: URGENCIA NO PERMITIDA
-- =========================================
-- Esperado: rechazo por restricción CHECK.

DO $$
DECLARE
    v_rechazado BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO hallazgo
        (hallazgo_id, orden_id, sintoma_comprobado,
         urgencia, recomendacion)
        VALUES
        (4902, 9001, 'Falla de prueba',
         'Urgentísima', 'Revisar');

    EXCEPTION WHEN check_violation THEN
        v_rechazado := TRUE;
    END;

    IF NOT v_rechazado THEN
        RAISE EXCEPTION 'P06: No se rechazó urgencia inválida';
    END IF;

    RAISE NOTICE 'P06 APROBADA: urgencia inválida rechazada';
END;
$$;


-- =========================================
-- PRUEBA 07: KILOMETRAJE NEGATIVO
-- =========================================
-- Esperado: procedimiento rechaza operación
-- y comunica el motivo mediante RAISE EXCEPTION.

DO $$
DECLARE
    v_rechazado BOOLEAN := FALSE;
BEGIN
    BEGIN
        CALL sp_registrar_orden(
            9902,
            '1HGCM82633A123456',
            101, 101, 101, 201,
            -50,
            '1/2',
            'Orden con kilometraje inválido'
        );

    EXCEPTION WHEN raise_exception THEN
        v_rechazado := TRUE;
    END;

    IF NOT v_rechazado THEN
        RAISE EXCEPTION 'P07: No se rechazó kilometraje negativo';
    END IF;

    RAISE NOTICE 'P07 APROBADA: kilometraje negativo rechazado';
END;
$$;


-- =========================================
-- FINALIZACIÓN
-- =========================================
-- ROLLBACK revierte las inserciones de prueba
-- para conservar la base original.

ROLLBACK;