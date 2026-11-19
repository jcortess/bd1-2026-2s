\set ON_ERROR_STOP on
SET application_name = 'huellas_g05_cupo_a';
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT pg_backend_pid() AS sesion_a,
       mover_animal(11, NULL, 7, '2026-10-06 09:00', 1, 'AISLAMIENTO') AS estancia_reservada_en_a;
\prompt 'Abra la sesion B y compruebe la espera. Luego pulse Intro para confirmar A: ' confirmar
COMMIT;
SELECT id_estancia, animal_codigo, ingreso_id, ubicacion_id, actor_entrada_id FROM ubicacion_actual
WHERE ingreso_id = 11;
