\set ON_ERROR_STOP on
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
DO $$
BEGIN
    IF EXISTS (SELECT FROM estancia WHERE ingreso_id IN (11,12,13) OR ubicacion_id IN (7,8,9)) THEN
        RAISE EXCEPTION 'Se requiere una base sin los movimientos de la prueba de concurrencia';
    END IF;
END
$$;
-- HS-13 parte de atención externa. El único cupo de la ubicación 7 sigue libre.
SELECT mover_animal(13, NULL, 3, '2026-10-06 08:00', 1) AS estancia_origen;
COMMIT;
SELECT id_estancia, animal_codigo, ingreso_id, ubicacion_id, actor_entrada_id
FROM ubicacion_actual WHERE ingreso_id = 13;
SELECT id_ubicacion, capacidad, ocupacion, saldo_fisico FROM ocupacion_actual WHERE id_ubicacion IN (7,8,9)
ORDER BY id_ubicacion;
