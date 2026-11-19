\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = huellas, pg_catalog;

CREATE OR REPLACE VIEW historial_alojamiento AS
SELECT e.id_estancia, e.animal_codigo, e.ingreso_id, e.ubicacion_id, u.tipo_ubicacion, u.nombre_descripcion,
       e.fecha_inicio_real, e.fecha_fin_real, e.fecha_inicio_prevista, e.fecha_fin_prevista,
       u.persona_oferente_id, oferente.nombre_identificacion AS oferente_hogar,
       e.aprobacion_hogar_id, e.actor_entrada_id, e.actor_salida_id, e.condicion_alojamiento,
       e.condicion_especial, e.valoracion_sanitaria,
       CASE WHEN u.tipo_ubicacion = 'HOGAR_TEMPORAL'
            THEN coalesce(e.fecha_fin_real, statement_timestamp()) > u.disponibilidad_hasta
       END AS rebasa_oferta
FROM estancia e
JOIN ubicacion u ON u.id_ubicacion = e.ubicacion_id
LEFT JOIN persona oferente ON oferente.id_persona = u.persona_oferente_id;

CREATE OR REPLACE VIEW ubicacion_actual AS
SELECT * FROM historial_alojamiento WHERE fecha_fin_real IS NULL;

CREATE OR REPLACE VIEW ocupacion_actual AS
SELECT u.id_ubicacion, u.nombre_descripcion, u.tipo_ubicacion, u.codigo_hogar, u.capacidad,
       c.ocupacion, u.capacidad - c.ocupacion AS saldo_fisico,
       CASE u.tipo_ubicacion
           WHEN 'HOGAR_TEMPORAL' THEN
               tstzrange(u.disponibilidad_desde, u.disponibilidad_hasta, '[)') @> statement_timestamp()
               AND EXISTS (
                   SELECT FROM participacion p
                   WHERE p.persona_id = u.persona_oferente_id AND p.tipo_participacion = 'HOGAR_TEMPORAL'
                     AND p.estado_aprobacion_registro = 'APROBADO'
                     AND p.fecha_aprobacion_registro < statement_timestamp()
                     AND tstzrange(p.fecha_inicio, p.fecha_fin, '[)') @> statement_timestamp()
               )
               AND EXISTS (SELECT FROM ubicacion_especie_aceptada s WHERE s.ubicacion_id = u.id_ubicacion)
           WHEN 'AREA_INTERNA' THEN true
       END AS oferta_vigente
FROM ubicacion u
CROSS JOIN LATERAL (
    SELECT count(*) AS ocupacion FROM estancia e JOIN ubicacion ue ON ue.id_ubicacion = e.ubicacion_id
    WHERE e.fecha_fin_real IS NULL
      AND (ue.id_ubicacion = u.id_ubicacion OR ue.codigo_hogar = u.codigo_hogar)
) c;

GRANT SELECT ON historial_alojamiento, ubicacion_actual, ocupacion_actual TO huellas_g05_operador;
COMMIT;

-- Verificación sobre la base cargada o después de ejecutar las pruebas.
SET TIME ZONE 'America/Costa_Rica';
SELECT id_estancia, animal_codigo, ingreso_id, nombre_descripcion, actor_entrada_id, oferente_hogar
FROM huellas.ubicacion_actual ORDER BY animal_codigo;
SELECT id_estancia, animal_codigo, ingreso_id, ubicacion_id, fecha_inicio_real, fecha_fin_real,
       fecha_inicio_prevista, fecha_fin_prevista, persona_oferente_id, aprobacion_hogar_id,
       actor_entrada_id, actor_salida_id, condicion_especial, valoracion_sanitaria, rebasa_oferta
FROM huellas.historial_alojamiento ORDER BY animal_codigo, fecha_inicio_real;
SELECT id_ubicacion, nombre_descripcion, tipo_ubicacion, ocupacion, capacidad, saldo_fisico, oferta_vigente
FROM huellas.ocupacion_actual ORDER BY id_ubicacion;
