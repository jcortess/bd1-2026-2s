\set ON_ERROR_STOP on
SET search_path = huellas, pg_catalog;
SET TIME ZONE 'America/Costa_Rica';

DO $$
BEGIN
    IF (SELECT count(*) FROM estancia WHERE ubicacion_id = 7) <> 1
       OR NOT EXISTS (SELECT FROM ubicacion_actual WHERE ingreso_id = 11 AND animal_codigo = 'HS-11'
          AND ubicacion_id = 7 AND actor_entrada_id = 1 AND fecha_inicio_real = '2026-10-06 09:00'
          AND condicion_alojamiento = 'AISLAMIENTO')
       OR EXISTS (SELECT FROM estancia WHERE ingreso_id = 12)
       OR NOT EXISTS (SELECT FROM ocupacion_actual WHERE id_ubicacion = 7 AND ocupacion = 1
                      AND capacidad = 1 AND saldo_fisico = 0) THEN
        RAISE EXCEPTION 'C1: estado final incorrecto';
    END IF;
    IF (SELECT count(*) FROM estancia WHERE ingreso_id = 13) <> 2
       OR NOT EXISTS (SELECT FROM estancia WHERE ingreso_id = 13 AND animal_codigo = 'HS-13'
          AND ubicacion_id = 3 AND fecha_inicio_real = '2026-10-06 08:00'
          AND fecha_fin_real = '2026-10-07 09:00' AND actor_salida_id = 1)
       OR NOT EXISTS (SELECT FROM ubicacion_actual WHERE ingreso_id = 13 AND animal_codigo = 'HS-13'
          AND ubicacion_id = 8 AND fecha_inicio_real = '2026-10-07 09:00'
          AND fecha_fin_prevista = '2026-10-08 09:00' AND actor_entrada_id = 1
          AND persona_oferente_id = 2 AND aprobacion_hogar_id = 2
          AND condicion_especial = 'Seguir el acuerdo de Casa X'
          AND valoracion_sanitaria = 'Sin incidencia sanitaria en el traslado')
       OR EXISTS (SELECT FROM estancia WHERE ingreso_id = 13 AND ubicacion_id = 9)
       OR NOT EXISTS (SELECT FROM ocupacion_actual WHERE id_ubicacion = 8 AND ocupacion = 1 AND capacidad = 2)
       OR NOT EXISTS (SELECT FROM ocupacion_actual WHERE id_ubicacion = 9 AND ocupacion = 0 AND capacidad = 2) THEN
        RAISE EXCEPTION 'C2: estado final incorrecto';
    END IF;
END
$$;

SELECT id_estancia, animal_codigo, ingreso_id, ubicacion_id, fecha_inicio_real, fecha_fin_real,
       persona_oferente_id, aprobacion_hogar_id, actor_entrada_id, actor_salida_id
FROM historial_alojamiento WHERE ingreso_id IN (11,12,13) ORDER BY ingreso_id, fecha_inicio_real;
SELECT id_ubicacion, ocupacion, capacidad, saldo_fisico FROM ocupacion_actual WHERE id_ubicacion IN (7,8,9)
ORDER BY id_ubicacion;
