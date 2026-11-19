\set ON_ERROR_STOP on
SET application_name = 'huellas_g05_animal_b';
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_backend_pid() AS sesion_b, id_estancia, animal_codigo, ubicacion_id
FROM ubicacion_actual WHERE ingreso_id = 13;
DO $$
DECLARE
    origen bigint;
BEGIN
    SELECT id_estancia INTO STRICT origen FROM estancia WHERE ingreso_id = 13 AND ubicacion_id = 3;
    -- Hora posterior a la elección de A. La causa del rechazo es la lectura desactualizada.
    PERFORM mover_animal(13, origen, 9, '2026-10-07 10:00', 7, NULL,
        '2026-10-07 10:00', '2026-10-08 10:00', NULL, 'Sin incidencia sanitaria en el traslado');
    RAISE EXCEPTION 'C2: se esperaba P1006, origen cambió tras el COMMIT de A';
EXCEPTION WHEN SQLSTATE 'P1006' THEN
    RAISE NOTICE 'C2: % %', SQLSTATE, SQLERRM;
END
$$;
COMMIT;
SELECT id_estancia, ingreso_id, ubicacion_id, persona_oferente_id, aprobacion_hogar_id, actor_entrada_id
FROM ubicacion_actual WHERE ingreso_id = 13;
