-- IC-4301 | Laboratorio 3 | Grupo 04 | Alquileres El Roble
-- Script de pruebas de funciones, procedimiento y triggers (05_pruebas.sql)

BEGIN;

-- =============================================================================
-- 1. PRUEBAS DE CASOS VÁLIDOS
-- =============================================================================

-- Prueba 1.1: Ejecutar función que verifica si una persona tiene una facultad
-- La persona 2 (Felipe Salazar) tiene asignada la facultad 1
SELECT 
    'Prueba 1.1 (Validar facultad)' AS prueba,
    public.fn_persona_tiene_facultad(2, 1) AS resultado_esperado_true;

-- Prueba 1.2: Ejecutar función que cuenta autorizaciones activas
-- El cliente 1 (Carlos Hidalgo) tiene 1 autorización activa
SELECT 
    'Prueba 1.2 (Contar autorizaciones)' AS prueba,
    public.fn_contar_autorizaciones_activas(1) AS total_activas;

-- Prueba 1.3: Probar el procedimiento almacenado (insertar nueva autorización)
-- Registrar autorización para el cliente 2, persona 4 (Bryan Morales) con facultades 2 y 3
CALL public.sp_registrar_autorizacion(
    2, 
    4, 
    '2026-10-01 00:00:00-06'::timestamp with time zone, 
    '2027-10-01 00:00:00-06'::timestamp with time zone, 
    ARRAY[2, 3]::bigint[]
);

COMMIT;


-- =============================================================================
-- 2. PRUEBAS DE CASOS RECHAZADOS (Pertenecen a bloques independientes)
-- =============================================================================

-- Prueba 2.1: Probar Trigger - Intentar insertar fechas inconsistentes (Fin < Inicio)
-- Debería fallar con el error personalizado del trigger
DO $$
BEGIN
    INSERT INTO public.autorizacion (id_cliente, id_persona, inicio_vigencia, fin_vigencia)
    VALUES (1, 2, '2026-12-01 00:00:00-06', '2026-01-01 00:00:00-06');
    RAISE NOTICE 'ERROR: El trigger no bloqueo la fecha invalida.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'EXITO (Trigger capturo el error): %', SQLERRM;
END;
$$;

-- Prueba 2.2: Probar Procedimiento - Intentar registrar autorización con un cliente que NO existe
DO $$
BEGIN
    CALL public.sp_registrar_autorizacion(
        999, 
        1, 
        '2026-01-01 00:00:00-06'::timestamp with time zone, 
        NULL, 
        ARRAY[1]::bigint[]
    );
    RAISE NOTICE 'ERROR: El procedimiento no valido el cliente inexistente.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'EXITO (Procedimiento capturo el error): %', SQLERRM;
END;
$$;