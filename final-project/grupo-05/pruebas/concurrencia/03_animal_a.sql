\set ON_ERROR_STOP on
SET application_name = 'huellas_g05_animal_a';
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN ISOLATION LEVEL READ COMMITTED;
SET LOCAL ROLE huellas_g05_operador;
SELECT id_estancia AS origen_id FROM ubicacion_actual WHERE ingreso_id = 13 AND ubicacion_id = 3 \gset
SELECT pg_backend_pid() AS sesion_a, :origen_id AS origen,
       mover_animal(13, :origen_id, 8, '2026-10-07 09:00', 1, NULL,
           '2026-10-07 09:00', '2026-10-08 09:00', 'Seguir el acuerdo de Casa X',
           'Sin incidencia sanitaria en el traslado') AS traslado_a;
\prompt 'Abra la sesion B y compruebe la espera. Luego pulse Intro para confirmar A: ' confirmar
COMMIT;
SELECT id_estancia, ingreso_id, ubicacion_id, persona_oferente_id, aprobacion_hogar_id, actor_entrada_id
FROM ubicacion_actual WHERE ingreso_id = 13;
