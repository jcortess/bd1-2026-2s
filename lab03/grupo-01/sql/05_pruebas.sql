-- Laboratorio 03 - Grupo 01
-- Clinica Los Robles / B3: Pruebas de integridad
-- Requiere: 01_esquema.sql y 02_datos.sql ejecutados previamente.
-- PostgreSQL 14+
-- IMPORTANTE: Ejecutar el archivo COMPLETO como script en una sola conexion.
-- Las inserciones validas se revierten al final para no alterar los datos de B1.

BEGIN;

-- Tabla temporal de evidencia: desaparece al finalizar la transaccion.
CREATE TEMP TABLE b3_resultados (
    id_prueba TEXT PRIMARY KEY,
    descripcion TEXT NOT NULL,
    resultado_esperado TEXT NOT NULL,
    resultado_observado TEXT NOT NULL,
    conclusion TEXT NOT NULL
) ON COMMIT DROP;

DO $$
DECLARE
    v_constraint TEXT;
    v_column TEXT;
BEGIN
    -- P01: VALIDA / RN-16, RN-17
    -- Precondicion: 5099 no existe como id_consulta.
    -- Sentencia: registrar una urgencia sin cita y con paciente/medico obligatorios.
    BEGIN
        INSERT INTO consulta (
            id_consulta, id_paciente, id_medico, id_cita,
            fecha_hora_inicio, motivo_clinico, resumen_general
        ) VALUES (
            5099, 100245, 200317, NULL,
            '2026-10-20 08:30:00',
            'Atencion urgente ficticia para pruebas',
            'Registro temporal valido, sin cita previa.'
        );

        INSERT INTO b3_resultados VALUES (
            'P01', 'Consulta de urgencia sin cita', 'Aceptacion',
            'INSERT aceptado', 'CUMPLE'
        );
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P01', 'Consulta de urgencia sin cita', 'Aceptacion',
            format('Error inesperado [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P02: VALIDA / RN-19, S-13
    -- Precondicion: P01 inserto la consulta 5099.
    -- Sentencia: agregar la version 1 de una observacion a esa consulta.
    BEGIN
        INSERT INTO observacion_clinica (
            id_consulta, consecutivo_observacion, num_version,
            contenido_observacion, fecha_hora_registro, es_vigente
        ) VALUES (
            5099, 1, 1,
            'Observacion ficticia para verificar insercion valida.',
            '2026-10-20 08:35:00', TRUE
        );

        INSERT INTO b3_resultados VALUES (
            'P02', 'Observacion version 1 con FK valida', 'Aceptacion',
            'INSERT aceptado', 'CUMPLE'
        );
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P02', 'Observacion version 1 con FK valida', 'Aceptacion',
            format('Error inesperado [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P03: VALIDA / RN-21, RN-25
    -- Precondicion: P01 inserto la consulta 5099; 7099 no existe.
    -- Sentencia: agregar tratamiento planificado con fechas y sesiones validas.
    BEGIN
        INSERT INTO tratamiento (
            id_tratamiento, id_consulta, id_tratamiento_sustituido,
            tipo_tratamiento, instrucciones, fecha_inicio_prevista,
            fecha_fin_prevista, estado_actual, dosis, frecuencia,
            cantidad_sesiones
        ) VALUES (
            7099, 5099, NULL,
            'Procedimiento', 'Dos controles clinicos ficticios.',
            '2026-10-20', '2026-10-22', 'Planificado',
            NULL, NULL, 2
        );

        INSERT INTO b3_resultados VALUES (
            'P03', 'Tratamiento con fechas y sesiones validas', 'Aceptacion',
            'INSERT aceptado', 'CUMPLE'
        );
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P03', 'Tratamiento con fechas y sesiones validas', 'Aceptacion',
            format('Error inesperado [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P04: INVALIDA / unicidad de clave primaria, RN-20
    -- Precondicion: el diagnostico J00 ya existe en B1.
    -- Sentencia: intentar duplicar su codigo.
    BEGIN
        INSERT INTO diagnostico (
            codigo_diagnostico, descripcion_diagnostico
        ) VALUES ('J00', 'Duplicado intencional para prueba');

        INSERT INTO b3_resultados VALUES (
            'P04', 'Codigo de diagnostico duplicado', 'Rechazo por PK',
            'INSERT aceptado indebidamente', 'NO CUMPLE'
        );
    EXCEPTION WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
        INSERT INTO b3_resultados VALUES (
            'P04', 'Codigo de diagnostico duplicado', 'Rechazo por PK',
            'Rechazado por ' || COALESCE(v_constraint, '(sin nombre)'),
            CASE WHEN v_constraint = 'pk_diagnostico' THEN 'CUMPLE' ELSE 'NO CUMPLE' END
        );
    WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P04', 'Codigo de diagnostico duplicado', 'Rechazo por PK',
            format('Error diferente [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P05: INVALIDA / integridad referencial, RN-19
    -- Precondicion: no existe la consulta 999999.
    -- Sentencia: intentar insertar una observacion para una consulta inexistente.
    BEGIN
        INSERT INTO observacion_clinica (
            id_consulta, consecutivo_observacion, num_version,
            contenido_observacion, fecha_hora_registro, es_vigente
        ) VALUES (
            999999, 1, 1, 'Observacion sin consulta existente.',
            '2026-10-20 09:00:00', TRUE
        );

        INSERT INTO b3_resultados VALUES (
            'P05', 'Observacion con consulta inexistente', 'Rechazo por FK',
            'INSERT aceptado indebidamente', 'NO CUMPLE'
        );
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
        INSERT INTO b3_resultados VALUES (
            'P05', 'Observacion con consulta inexistente', 'Rechazo por FK',
            'Rechazado por ' || COALESCE(v_constraint, '(sin nombre)'),
            CASE WHEN v_constraint = 'fk_observacion_consulta' THEN 'CUMPLE' ELSE 'NO CUMPLE' END
        );
    WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P05', 'Observacion con consulta inexistente', 'Rechazo por FK',
            format('Error diferente [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P06: INVALIDA / rango de version, RN-19, S-13
    -- Precondicion: P01 inserto la consulta 5099.
    -- Sentencia: intentar registrar num_version = 0.
    BEGIN
        INSERT INTO observacion_clinica (
            id_consulta, consecutivo_observacion, num_version,
            contenido_observacion, fecha_hora_registro, es_vigente
        ) VALUES (
            5099, 2, 0, 'Version invalida de prueba.',
            '2026-10-20 09:05:00', TRUE
        );

        INSERT INTO b3_resultados VALUES (
            'P06', 'Version de observacion igual a cero', 'Rechazo por CHECK',
            'INSERT aceptado indebidamente', 'NO CUMPLE'
        );
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
        INSERT INTO b3_resultados VALUES (
            'P06', 'Version de observacion igual a cero', 'Rechazo por CHECK',
            'Rechazado por ' || COALESCE(v_constraint, '(sin nombre)'),
            CASE WHEN v_constraint = 'ck_observacion_version_positiva' THEN 'CUMPLE' ELSE 'NO CUMPLE' END
        );
    WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P06', 'Version de observacion igual a cero', 'Rechazo por CHECK',
            format('Error diferente [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P07: INVALIDA / estado de tratamiento, RN-26
    -- Precondicion: P01 inserto la consulta 5099; 7098 no existe.
    -- Sentencia: intentar utilizar un estado no admitido por el modelo.
    BEGIN
        INSERT INTO tratamiento (
            id_tratamiento, id_consulta, id_tratamiento_sustituido,
            tipo_tratamiento, instrucciones, fecha_inicio_prevista,
            fecha_fin_prevista, estado_actual, dosis, frecuencia,
            cantidad_sesiones
        ) VALUES (
            7098, 5099, NULL,
            'Medicamento', 'Pauta ficticia para probar rechazo.',
            '2026-10-20', '2026-10-21', 'Activo',
            NULL, NULL, NULL
        );

        INSERT INTO b3_resultados VALUES (
            'P07', 'Estado de tratamiento no permitido', 'Rechazo por CHECK',
            'INSERT aceptado indebidamente', 'NO CUMPLE'
        );
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
        INSERT INTO b3_resultados VALUES (
            'P07', 'Estado de tratamiento no permitido', 'Rechazo por CHECK',
            'Rechazado por ' || COALESCE(v_constraint, '(sin nombre)'),
            CASE WHEN v_constraint = 'ck_tratamiento_estado' THEN 'CUMPLE' ELSE 'NO CUMPLE' END
        );
    WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P07', 'Estado de tratamiento no permitido', 'Rechazo por CHECK',
            format('Error diferente [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;

    -- P08: INVALIDA / obligatoriedad del medico responsable, RN-17
    -- Precondicion: 5098 no existe como id_consulta.
    -- Sentencia: intentar insertar una consulta sin id_medico.
    BEGIN
        INSERT INTO consulta (
            id_consulta, id_paciente, id_medico, id_cita,
            fecha_hora_inicio, motivo_clinico, resumen_general
        ) VALUES (
            5098, 100245, NULL, NULL,
            '2026-10-20 10:00:00',
            'Consulta sin medico: caso invalido',
            'Solo para verificar obligatoriedad.'
        );

        INSERT INTO b3_resultados VALUES (
            'P08', 'Consulta sin medico responsable', 'Rechazo por NOT NULL',
            'INSERT aceptado indebidamente', 'NO CUMPLE'
        );
    EXCEPTION WHEN not_null_violation THEN
        GET STACKED DIAGNOSTICS v_column = COLUMN_NAME;
        INSERT INTO b3_resultados VALUES (
            'P08', 'Consulta sin medico responsable', 'Rechazo por NOT NULL',
            'Rechazado por columna ' || COALESCE(v_column, '(sin nombre)'),
            CASE WHEN v_column = 'id_medico' THEN 'CUMPLE' ELSE 'NO CUMPLE' END
        );
    WHEN OTHERS THEN
        INSERT INTO b3_resultados VALUES (
            'P08', 'Consulta sin medico responsable', 'Rechazo por NOT NULL',
            format('Error diferente [%s]: %s', SQLSTATE, SQLERRM), 'NO CUMPLE'
        );
    END;
END;
$$ LANGUAGE plpgsql;

-- Evidencia de cada prueba, lista para captura de pantalla o transcripcion.
SELECT
    id_prueba,
    descripcion,
    resultado_esperado,
    resultado_observado,
    conclusion
FROM b3_resultados
ORDER BY id_prueba;

-- Resumen: se esperan 8 pruebas con conclusion CUMPLE.
SELECT
    COUNT(*) AS pruebas_totales,
    COUNT(*) FILTER (WHERE conclusion = 'CUMPLE') AS cumplen,
    COUNT(*) FILTER (WHERE conclusion = 'NO CUMPLE') AS no_cumplen
FROM b3_resultados;

-- Eliminar todos los registros insertados durante las pruebas.
-- Los datos originales de B1 permanecen intactos.
ROLLBACK;
