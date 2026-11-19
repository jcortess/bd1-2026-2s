\set ON_ERROR_STOP on
SET application_name = 'huellas_g05_cupo_b';
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_backend_pid() AS sesion_b, capacidad, ocupacion FROM ocupacion_actual WHERE id_ubicacion = 7;
DO $$
BEGIN
    PERFORM mover_animal(12, NULL, 7, '2026-10-06 09:00', 7, 'AISLAMIENTO');
    RAISE EXCEPTION 'C1: se esperaba P1014, último cupo ocupado tras el COMMIT de A';
EXCEPTION WHEN SQLSTATE 'P1014' THEN
    RAISE NOTICE 'C1: % %', SQLSTATE, SQLERRM;
END
$$;
COMMIT;
SELECT animal_codigo, ingreso_id, ubicacion_id, actor_entrada_id
FROM ubicacion_actual WHERE ingreso_id IN (11,12) ORDER BY ingreso_id;
