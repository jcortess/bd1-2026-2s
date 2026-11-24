\set ON_ERROR_STOP on
SET search_path=huellas,pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT crear_solicitud('050c0000-0000-0000-0000-000000000001',101,'2026-10-12 08:00',
    'Casa carrera COMMIT','Familia ficticia','Experiencia declarada','Cuidados declarados',1);
SELECT crear_solicitud('050c0000-0000-0000-0000-000000000002',102,'2026-10-12 08:00',
    'Casa carrera ROLLBACK','Familia ficticia','Experiencia declarada','Cuidados declarados',1);
COMMIT;
SELECT id_solicitud,clave_operacion,decision_id,estado FROM estado_actual_solicitud
WHERE clave_operacion IN ('050c0000-0000-0000-0000-000000000001','050c0000-0000-0000-0000-000000000002');
