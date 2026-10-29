-- Laboratorio 03 - Grupo 01
-- Subsistema de Atención médica, diagnóstico y tratamiento clínico
-- Caso: Clínica Los Robles (Proyecto 1 - v2.1)
-- Archivo: 04_rutinas.sql
-- Motor: PostgreSQL 14+

-- ============================================================================
-- PARTE C1: FUNCIONES EN PL/pgSQL (8 PUNTOS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- C1.1 Función de valor calculado: fn_calcular_dias_tratamiento
-- Regla de Negocio: RN-25 (Fechas previstas de inicio y fin de tratamiento).
-- Propósito: Calcula la duración en días calendario prescrita para un tratamiento.
-- Retorno: INTEGER con los días totales (inclusivo), o NULL si es de término indefinido.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calcular_dias_tratamiento(
    p_id_tratamiento INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_inicio DATE;
    v_fin DATE;
    v_duracion_dias INTEGER;
BEGIN
    -- Obtener las fechas del tratamiento
    SELECT fecha_inicio_prevista, fecha_fin_prevista
    INTO v_inicio, v_fin
    FROM tratamiento
    WHERE id_tratamiento = p_id_tratamiento;

    -- Si el tratamiento no existe, se notifica
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El tratamiento con ID % no existe en el sistema.', p_id_tratamiento;
    END IF;

    -- Si no tiene fecha de fin definida, la duración es abierta/indefinida
    IF v_fin IS NULL THEN
        RETURN NULL;
    END IF;

    -- Cálculo de días calendario (diferencia inclusiva)
    v_duracion_dias := (v_fin - v_inicio) + 1;
    RETURN v_duracion_dias;
END;
$$;

COMMENT ON FUNCTION fn_calcular_dias_tratamiento(INTEGER) IS 
'Calcula la duración en días de un tratamiento con base en sus fechas previstas (RN-25).';


-- ----------------------------------------------------------------------------
-- C1.2 Función con decisión de negocio: fn_determinar_prioridad_consulta
-- Reglas de Negocio: RN-20 (Diagnóstico principal/confirmado), RN-21 (Tratamientos producidos).
-- Propósito: Clasifica la severidad/prioridad de una atención médica en ALTA, MEDIA o BAJA.
-- Estructura de decisión: IF-ELSIF-ELSE evaluando diagnósticos confirmados y polifarmacia.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_determinar_prioridad_consulta(
    p_id_consulta INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_tiene_confirmado_principal BOOLEAN := FALSE;
    v_cant_diagnosticos INTEGER := 0;
    v_cant_tratamientos INTEGER := 0;
    v_prioridad TEXT;
BEGIN
    -- Verificar existencia de la consulta
    IF NOT EXISTS (SELECT 1 FROM consulta WHERE id_consulta = p_id_consulta) THEN
        RAISE EXCEPTION 'La consulta médica con ID % no existe.', p_id_consulta;
    END IF;

    -- Evaluar si existe diagnóstico Principal y Confirmado
    SELECT EXISTS (
        SELECT 1 
        FROM consulta_diagnostico_nm
        WHERE id_consulta = p_id_consulta
          AND tipo_categoria = 'Principal'
          AND condicion = 'Confirmado'
    ) INTO v_tiene_confirmado_principal;

    -- Contar diagnósticos totales y tratamientos prescritos
    SELECT COUNT(*) INTO v_cant_diagnosticos
    FROM consulta_diagnostico_nm
    WHERE id_consulta = p_id_consulta;

    SELECT COUNT(*) INTO v_cant_tratamientos
    FROM tratamiento
    WHERE id_consulta = p_id_consulta;

    -- Estructura de decisión clínica
    IF v_tiene_confirmado_principal AND (v_cant_tratamientos >= 2 OR v_cant_diagnosticos >= 3) THEN
        v_prioridad := 'ALTA';
    ELSIF v_tiene_confirmado_principal OR v_cant_tratamientos >= 1 THEN
        v_prioridad := 'MEDIA';
    ELSE
        v_prioridad := 'BAJA';
    END IF;

    RETURN v_prioridad;
END;
$$;

COMMENT ON FUNCTION fn_determinar_prioridad_consulta(INTEGER) IS 
'Evalúa y clasifica la complejidad/prioridad clínica de una consulta mediante IF-ELSIF (RN-20, RN-21).';


-- ============================================================================
-- PARTE C2: PROCEDIMIENTO ALMACENADO CON VALIDACIONES (10 PUNTOS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- C2. Procedimiento de negocio: sp_sustituir_tratamiento
-- Regla de Negocio: RN-26 (Sustitución de indicaciones y transición de estado).
-- Valida:
--   1. Existencia del tratamiento a sustituir.
--   2. Que el tratamiento anterior esté activo (no 'Suspendido' ni 'Sustituido').
--   3. Que el tratamiento anterior no haya sido sustituido previamente (unicidad 1:1).
--   4. Coherencia de fechas (la nueva indicación no puede iniciar antes de la anterior).
-- Modifica:
--   - Actualiza tratamiento anterior a estado 'Sustituido'.
--   - Inserta el nuevo tratamiento con FK recursiva hacia el anterior.
--   - Vincula el nuevo tratamiento a los diagnósticos del anterior (RN-21).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_sustituir_tratamiento(
    p_id_tratamiento_previo INTEGER,
    p_id_nuevo_tratamiento INTEGER,
    p_tipo_tratamiento TEXT,
    p_instrucciones TEXT,
    p_fecha_inicio DATE,
    p_fecha_fin DATE,
    p_dosis TEXT DEFAULT NULL,
    p_frecuencia TEXT DEFAULT NULL,
    p_cantidad_sesiones INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_consulta_id INTEGER;
    v_estado_previo TEXT;
    v_inicio_previo DATE;
    v_reg_diag RECORD;
BEGIN
    -- 1. Validación de existencia y obtención de estado actual
    SELECT id_consulta, estado_actual, fecha_inicio_prevista
    INTO v_consulta_id, v_estado_previo, v_inicio_previo
    FROM tratamiento
    WHERE id_tratamiento = p_id_tratamiento_previo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Operación rechazada: El tratamiento previo ID % no existe.', p_id_tratamiento_previo;
    END IF;

    -- 2. Validación de regla de negocio: no sustituir tratamientos finalizados o ya reemplazados
    IF v_estado_previo IN ('Suspendido', 'Sustituido', 'Completado') THEN
        RAISE EXCEPTION 'Operación rechazada: No se puede sustituir un tratamiento en estado "%". Solo se sustituyen tratamientos Planificados o Iniciados.', v_estado_previo;
    END IF;

    -- 3. Validación de unicidad de sustitución (RN-26 / S-15)
    IF EXISTS (SELECT 1 FROM tratamiento WHERE id_tratamiento_sustituido = p_id_tratamiento_previo) THEN
        RAISE EXCEPTION 'Operación rechazada: El tratamiento ID % ya fue sustituido por otra indicación médica.', p_id_tratamiento_previo;
    END IF;

    -- 4. Validación temporal de negocio
    IF p_fecha_inicio < v_inicio_previo THEN
        RAISE EXCEPTION 'Operación rechazada: La fecha de inicio del nuevo tratamiento (%) no puede ser anterior al inicio del tratamiento original (%).', p_fecha_inicio, v_inicio_previo;
    END IF;

    -- 5. Actualización del tratamiento anterior (Transición a estado 'Sustituido')
    UPDATE tratamiento
    SET estado_actual = 'Sustituido',
        fecha_fin_prevista = LEAST(COALESCE(fecha_fin_prevista, p_fecha_inicio), p_fecha_inicio)
    WHERE id_tratamiento = p_id_tratamiento_previo;

    -- 6. Inserción de la nueva prescripción vinculada recursivamente
    INSERT INTO tratamiento (
        id_tratamiento,
        id_consulta,
        id_tratamiento_sustituido,
        tipo_tratamiento,
        instrucciones,
        fecha_inicio_prevista,
        fecha_fin_prevista,
        estado_actual,
        dosis,
        frecuencia,
        cantidad_sesiones
    ) VALUES (
        p_id_nuevo_tratamiento,
        v_consulta_id,
        p_id_tratamiento_previo,
        p_tipo_tratamiento,
        p_instrucciones,
        p_fecha_inicio,
        p_fecha_fin,
        'Iniciado',
        p_dosis,
        p_frecuencia,
        p_cantidad_sesiones
    );

    -- 7. Heredar automáticamente los diagnósticos asociados al tratamiento previo (RN-21)
    FOR v_reg_diag IN (
        SELECT codigo_diagnostico 
        FROM tratamiento_diagnostico_nm 
        WHERE id_tratamiento = p_id_tratamiento_previo
    ) LOOP
        INSERT INTO tratamiento_diagnostico_nm (id_tratamiento, codigo_diagnostico)
        VALUES (p_nuevo_tratamiento, v_reg_diag.codigo_diagnostico)
        ON CONFLICT DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Tratamiento % sustituido exitosamente por nuevo tratamiento %.', p_id_tratamiento_previo, p_id_nuevo_tratamiento;
END;
$$;

COMMENT ON PROCEDURE sp_sustituir_tratamiento IS 
'Aplica la sustitución clínica de un tratamiento validando precondiciones y actualizando estado (RN-26).';


-- ============================================================================
-- PARTE C3: TÉCNICA PROCEDIMENTAL ADICIONAL — CURSOR EXPLÍCITO (7 PUNTOS)
-- ============================================================================

-- Justificación técnica:
-- Se implementa un CURSOR EXPLÍCITO para procesar secuencialmente el historial
-- de versiones de observaciones de una consulta (RN-19), construyendo un reporte
-- consolidado de auditoría médica sin saturar la memoria de una sola lectura.
--
-- Discusión de alternativa basada en conjuntos (SQL Set-Based):
-- Esta concatenación secuencial puede resolverse de forma declarativa y más concisa
-- con `STRING_AGG(contenido_observacion, E'\n' ORDER BY num_version)`.
-- Se implementa con cursor explícito con fines de demostración técnica de la semana 12.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_auditar_evolucion_consulta_cursor(
    p_id_consulta INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    -- Declaración de cursor explícito
    cur_observaciones CURSOR FOR
        SELECT consecutivo_observacion, num_version, contenido_observacion, es_vigente
        FROM observacion_clinica
        WHERE id_consulta = p_id_consulta
        ORDER BY consecutivo_observacion, num_version;

    v_consecutivo INTEGER;
    v_version INTEGER;
    v_contenido TEXT;
    v_es_vigente BOOLEAN;
    v_reporte TEXT := '--- AUDITORÍA DE EVOLUCIÓN CLÍNICA (CONSULTA ' || p_id_consulta || ') ---' || E'\n';
BEGIN
    -- Apertura del cursor
    OPEN cur_observaciones;

    LOOP
        -- Recuperación fila por fila
        FETCH cur_observaciones INTO v_consecutivo, v_version, v_contenido, v_es_vigente;
        EXIT WHEN NOT FOUND;

        v_reporte := v_reporte || Format(
            '[Nota #%s - Rev. %s] (Vigente: %s): %s',
            v_consecutivo,
            v_version,
            CASE WHEN v_es_vigente THEN 'SÍ' ELSE 'NO (Histórico)' END,
            v_contenido
        ) || E'\n';
    END LOOP;

    -- Cierre del cursor
    CLOSE cur_observaciones;

    RETURN v_reporte;
END;
$$;

COMMENT ON FUNCTION fn_auditar_evolucion_consulta_cursor(INTEGER) IS 
'Demostración de cursor explícito para recorrer la evolución clínica de notas (Semana 12).';