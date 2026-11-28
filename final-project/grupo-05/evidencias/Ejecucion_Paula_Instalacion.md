# Transcripción PostgreSQL: sql/09_instalar_bloque_paula.sql

Base nueva: `huellas_g05_paula_20261124_c`. Código de salida: `0`.

```text
BEGIN
CREATE SCHEMA
CREATE EXTENSION
SET
DO
REVOKE
GRANT
CREATE DOMAIN
CREATE DOMAIN
CREATE DOMAIN
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
COMMIT
BEGIN
SET
CREATE FUNCTION
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE FUNCTION
REVOKE
GRANT
GRANT
COMMIT
BEGIN
SET
SET
INSERT 0 8
INSERT 0 2
INSERT 0 8
INSERT 0 17
INSERT 0 1
INSERT 0 17
INSERT 0 11
INSERT 0 7
COMMIT
BEGIN
SET
CREATE VIEW
CREATE VIEW
CREATE VIEW
GRANT
COMMIT
SET
 id_estancia | animal_codigo | ingreso_id | nombre_descripcion | actor_entrada_id | oferente_hogar 
-------------+---------------+------------+--------------------+------------------+----------------
(0 rows)

 id_estancia | animal_codigo | ingreso_id | ubicacion_id | fecha_inicio_real | fecha_fin_real | fecha_inicio_prevista | fecha_fin_prevista | persona_oferente_id | aprobacion_hogar_id | actor_entrada_id | actor_salida_id | condicion_especial | valoracion_sanitaria | rebasa_oferta 
-------------+---------------+------------+--------------+-------------------+----------------+-----------------------+--------------------+---------------------+---------------------+------------------+-----------------+--------------------+----------------------+---------------
(0 rows)

 id_ubicacion |       nombre_descripcion        |  tipo_ubicacion  | ocupacion | capacidad | saldo_fisico | oferta_vigente 
--------------+---------------------------------+------------------+-----------+-----------+--------------+----------------
            1 | Sala de convivencia             | AREA_INTERNA     |         0 |         2 |            2 | t
            2 | Casa A, primera oferta          | HOGAR_TEMPORAL   |         0 |         1 |            1 | f
            3 | Centro de atención ficticio     | ATENCION_EXTERNA |         0 |           |              | 
            4 | Casa pendiente                  | HOGAR_TEMPORAL   |         0 |         1 |            1 | f
            5 | Casa con participación corta    | HOGAR_TEMPORAL   |         0 |         1 |            1 | f
            6 | Casa A, segunda oferta          | HOGAR_TEMPORAL   |         0 |         1 |            1 | f
            7 | Aislamiento de un cupo          | AREA_INTERNA     |         0 |         1 |            1 | t
            8 | Casa X                          | HOGAR_TEMPORAL   |         0 |         2 |            2 | f
            9 | Casa Y                          | HOGAR_TEMPORAL   |         0 |         2 |            2 | f
           10 | Casa con aprobación al límite   | HOGAR_TEMPORAL   |         0 |         1 |            1 | f
           11 | Casa sin especies por confirmar | HOGAR_TEMPORAL   |         0 |         1 |            1 | f
(11 rows)

BEGIN
SET
CREATE DOMAIN
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE TABLE
CREATE INDEX
CREATE TABLE
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
COMMIT
BEGIN
SET
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE TRIGGER
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE TRIGGER
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
REVOKE
REVOKE
GRANT
GRANT
COMMIT
BEGIN
SET
SET
INSERT 0 4
INSERT 0 1
 setval 
--------
    104
(1 row)

 setval 
--------
    104
(1 row)

INSERT 0 1
INSERT 0 1
INSERT 0 2
INSERT 0 17
INSERT 0 2
 setval 
--------
   1002
(1 row)

INSERT 0 2
INSERT 0 4
INSERT 0 2
COMMIT
BEGIN
SET
DO
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE FUNCTION
REVOKE
GRANT
COMMIT
SET
 id_solicitud | clave_operacion | solicitante_id | fecha_solicitud | informacion_vivienda | integrantes_hogar | experiencia_animales | condiciones_cuidado | decision_id | fecha_decision | estado | responsable_id | razon | es_general 
--------------+-----------------+----------------+-----------------+----------------------+-------------------+----------------------+---------------------+-------------+----------------+--------+----------------+-------+------------
(0 rows)

 solicitud_id | animal_codigo | fecha_interes 
--------------+---------------+---------------
(0 rows)

 id_solicitud | solicitante_id | estado 
--------------+----------------+--------
(0 rows)

 solicitud_id | fecha | id_evento_solicitud | tipo_evento | resultado_actividad | estado_resultante | responsable_id | razon 
--------------+-------+---------------------+-------------+---------------------+-------------------+----------------+-------
(0 rows)

 id_compatibilidad | clave_operacion | solicitud_id | animal_codigo | ingreso_id | fecha | responsable_id | participacion_responsable_id | resultado | valoracion_hogar | razon | observaciones | actividad_contexto_id | solicitante_id | informacion_vivienda | integrantes_hogar | experiencia_animales | condiciones_cuidado | tipo_actividad | resultado_actividad | observaciones_actividad | estado_solicitud | decision_id 
-------------------+-----------------+--------------+---------------+------------+-------+----------------+------------------------------+-----------+------------------+-------+---------------+-----------------------+----------------+----------------------+-------------------+----------------------+---------------------+----------------+---------------------+-------------------------+------------------+-------------
(0 rows)

 rechazada | posterior | solicitante_id 
-----------+-----------+----------------
(0 rows)

 id_evaluacion | animal_codigo | ingreso_id |    fecha_evaluacion    |   tipo_evaluacion    | veterinario_id | registro_veterinario_id |         motivo         |              observaciones               |  peso  |           recomendaciones           |                 diagnosticos                  
---------------+---------------+------------+------------------------+----------------------+----------------+-------------------------+------------------------+------------------------------------------+--------+-------------------------------------+-----------------------------------------------
             1 | HS-01         |          1 | 2026-10-04 08:00:00-06 | INICIAL              |                |                         |                        | Evaluación inicial ficticia al ingreso   |        |                                     | Sin diagnóstico
          1001 | HS-01         |          1 | 2026-10-05 09:00:00-06 | REVISION_VETERINARIA |              7 |                       8 | Control de piel y oído | Lesión leve y oído sensible              | 12.400 | Control profesional según evolución | Dermatitis (CONFIRMADO), Otitis (PROVISIONAL)
          1002 | HS-01         |          1 | 2026-10-06 09:00:00-06 | REVISION_VETERINARIA |              7 |                       8 | Revisión de evolución  | Piel en recuperación; oído sin hallazgos | 12.450 | Mantener seguimiento                | Dermatitis (CONFIRMADO), Otitis (DESCARTADO)
(3 rows)

 codigo_interno | revisiones | registros_confirmados 
----------------+------------+-----------------------
 HS-01          |          2 |                     2
 HS-02          |          0 |                     0
 HS-03          |          0 |                     0
 HS-04          |          0 |                     0
 HS-05          |          0 |                     0
 HS-06          |          0 |                     0
 HS-07          |          0 |                     0
 HS-08          |          0 |                     0
 HS-09          |          0 |                     0
 HS-10          |          0 |                     0
 HS-11          |          0 |                     0
 HS-12          |          0 |                     0
 HS-13          |          0 |                     0
 HS-14          |          0 |                     0
 HS-15          |          0 |                     0
 HS-16          |          0 |                     0
 HS-17          |          0 |                     0
(17 rows)

 id_cambio | animal_codigo | ingreso_id |         fecha          | estado_disponibilidad | responsable_id | participacion_responsable_id |        observacion_general         |                            valoracion_sanitaria                             
-----------+---------------+------------+------------------------+-----------------------+----------------+------------------------------+------------------------------------+-----------------------------------------------------------------------------
         1 | HS-01         |          1 | 2026-10-05 10:00:00-06 | HABILITADO            |              1 |                            1 | Decisión del equipo registrada     | Se considera compatible el cuidado domiciliario con el seguimiento indicado
         2 | HS-02         |          2 | 2026-10-05 10:00:00-06 | HABILITADO            |              1 |                            1 | Habilitación atribuible de ejemplo | Condición valorada por el equipo; sin automatismo por diagnóstico
(2 rows)

 relacion_reserva 
------------------
 
(1 row)


```
