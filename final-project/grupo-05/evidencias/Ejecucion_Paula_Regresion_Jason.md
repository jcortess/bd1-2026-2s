# Regresión del guion original de Jason

Base nueva `huellas_g05_paula_regresion_20261124`, con el esquema de ambos bloques y los antecedentes clínicos de Paula. Se ejecuta el archivo de Jason intacto.


## sql/09_instalar_bloque_paula.sql

Código de salida `0`.

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


## pruebas/01_bloque_jason.sql

Código de salida `0`.

```text
SET
SET
CREATE FUNCTION
CREATE FUNCTION
BEGIN
SET
 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

COMMIT
 comprueba 
-----------
 
(1 row)

BEGIN
SET
 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

COMMIT
 comprueba 
-----------
 
(1 row)

BEGIN
SET
 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

COMMIT
 comprueba 
-----------
 
(1 row)

BEGIN
SET
 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

COMMIT
 comprueba 
-----------
 
(1 row)

BEGIN
 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 comprueba 
-----------
 
(1 row)

 comprueba 
-----------
 
(1 row)

 espera 
--------
 
(1 row)

INSERT 0 1
 comprueba 
-----------
 
(1 row)

ROLLBACK
BEGIN
SET
 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

 espera 
--------
 
(1 row)

ROLLBACK
BEGIN
SET
 espera 
--------
 
(1 row)

ROLLBACK
 comprueba 
-----------
 
(1 row)

 id_estancia | animal_codigo | ingreso_id | ubicacion_id |       fecha_inicio_real       |        fecha_fin_real         | fecha_inicio_prevista  |   fecha_fin_prevista   | persona_oferente_id | aprobacion_hogar_id | actor_entrada_id | actor_salida_id |   condicion_especial    |           valoracion_sanitaria            | rebasa_oferta 
-------------+---------------+------------+--------------+-------------------------------+-------------------------------+------------------------+------------------------+---------------------+---------------------+------------------+-----------------+-------------------------+-------------------------------------------+---------------
           1 | HS-01         |          1 |            1 | 2026-10-04 08:00:00-06        | 2026-10-05 00:00:00-06        |                        |                        |                     |                     |                1 |               7 |                         |                                           | 
           3 | HS-01         |          1 |            2 | 2026-10-05 00:00:00-06        | 2026-10-10 00:00:00-06        | 2026-10-05 00:00:00-06 | 2026-10-10 00:00:00-06 |                   2 |                   2 |                7 |               1 | Reposo según el acuerdo | Se valoró recuperación y se acordó reposo | f
           7 | HS-01         |          1 |            3 | 2026-10-10 00:00:00-06        |                               |                        |                        |                     |                     |                1 |                 |                         | Atención externa acordada                 | 
           8 | HS-04         |          4 |            6 | 2026-10-10 00:00:00-06        | 2026-10-15 00:00:00.000001-06 | 2026-10-10 00:00:00-06 | 2026-10-15 00:00:00-06 |                   5 |                   5 |                7 |               7 |                         |                                           | t
          10 | HS-04         |          4 |            3 | 2026-10-15 00:00:00.000001-06 |                               |                        |                        |                     |                     |                7 |                 |                         | Salida real registrada tras el plazo      | 
(5 rows)

 id_ubicacion | capacidad | ocupacion | saldo_fisico 
--------------+-----------+-----------+--------------
            1 |         2 |         2 |            0
            2 |         1 |         0 |            1
            3 |           |         3 |             
            6 |         1 |         0 |            1
(4 rows)

psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:42: NOTICE:  M02-exceso rechazada P1014 [] La ubicación no tiene cupo en el intervalo real
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:44: NOTICE:  M02-condicion rechazada P1010 [] La condición declarada no coincide con la admitida por el área
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:46: NOTICE:  M03-ingreso rechazada P1005 [] El movimiento real debe estar entre el ingreso y el presente
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:48: NOTICE:  M03-retroactivo rechazada P1014 [] La ubicación no tiene cupo en el intervalo real
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:57: NOTICE:  M01–M03 después del COMMIT comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:64: NOTICE:  M04-doble rechazada P1006 [] La estancia vigente difiere de la esperada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:66: NOTICE:  M04-valoracion rechazada P1008 [] Registre la valoración sanitaria o su falta de incidencia en el traslado
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:69: NOTICE:  M05-atomica rechazada P1012 [] El oferente requiere aprobación previa y participación vigente
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:75: NOTICE:  M04–M05 después del COMMIT comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:86: NOTICE:  M07-especie rechazada P1013 [] El hogar no admite la especie del animal
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:88: NOTICE:  M07-sin-especies rechazada P1013 [] El hogar no admite la especie del animal
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:90: NOTICE:  M07-cupo rechazada P1014 [] La ubicación no tiene cupo en el intervalo real
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:92: NOTICE:  M08-antes rechazada P1011 [] La llegada real y el plan deben caber en la oferta del hogar
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:94: NOTICE:  M08-fin rechazada P1011 [] La llegada real y el plan deben caber en la oferta del hogar
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:96: NOTICE:  M08-plan-fuera rechazada P1011 [] La llegada real y el plan deben caber en la oferta del hogar
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:97: NOTICE:  M08-sin-plan rechazada P1011 [] La llegada real y el plan deben caber en la oferta del hogar
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:99: NOTICE:  M08-vigencia-siguiente-oferta rechazada P1014 [] La ubicación no tiene cupo en el intervalo real
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:113: NOTICE:  M06–M08 después del COMMIT comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:121: NOTICE:  M09-vigencia rechazada P1012 [] El oferente requiere aprobación previa y participación vigente
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:124: NOTICE:  M09-aprobacion rechazada P1012 [] El oferente requiere aprobación previa y participación vigente
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:128: NOTICE:  M10-periodo-cero rechazada P1005 [] La salida debe suceder después de la entrada en esta etapa
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:149: NOTICE:  M09–M11 después del COMMIT comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:155: NOTICE:  I01-persona-pk rechazada 23505 [persona_pkey] duplicate key value violates unique constraint "persona_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:157: NOTICE:  I01-persona-dominio rechazada 23514 [texto_no_vacio_check] value for domain texto_no_vacio violates check constraint "texto_no_vacio_check"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:159: NOTICE:  I01-persona-delete rechazada 23503 [medio_contacto_persona_id_fkey] update or delete on table "persona" violates foreign key constraint "medio_contacto_persona_id_fkey" on table "medio_contacto"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:161: NOTICE:  I02-contacto-pk rechazada 23505 [medio_contacto_pkey] duplicate key value violates unique constraint "medio_contacto_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:163: NOTICE:  I02-contacto-referencia rechazada 23503 [medio_contacto_persona_id_fkey] insert or update on table "medio_contacto" violates foreign key constraint "medio_contacto_persona_id_fkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:165: NOTICE:  I02-contacto-nulo rechazada 23502 [] null value in column "valor" of relation "medio_contacto" violates not-null constraint
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:168: NOTICE:  I03-participacion-pk rechazada 23505 [participacion_pkey] duplicate key value violates unique constraint "participacion_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:170: NOTICE:  I03-participacion-persona rechazada 23503 [participacion_persona_id_fkey] insert or update on table "participacion" violates foreign key constraint "participacion_persona_id_fkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:172: NOTICE:  I03-participacion-periodo rechazada 23514 [participacion_periodo] new row for relation "participacion" violates check constraint "participacion_periodo"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:174: NOTICE:  I03-participacion-aprobacion rechazada 23514 [participacion_aprobacion] new row for relation "participacion" violates check constraint "participacion_aprobacion"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:176: NOTICE:  I03-participacion-historia rechazada P1002 [] El cambio invalida una aprobación histórica
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:178: NOTICE:  I03-participacion-caducidad rechazada P1002 [] El cambio invalida una aprobación histórica
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:180: NOTICE:  I03-participacion-delete rechazada 23503 [estancia_aprobacion_hogar_id_fkey] update or delete on table "participacion" violates foreign key constraint "estancia_aprobacion_hogar_id_fkey" on table "estancia"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:182: NOTICE:  I04-animal-pk rechazada 23505 [animal_pkey] duplicate key value violates unique constraint "animal_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:183: NOTICE:  I04-especie-nula rechazada 23502 [] null value in column "especie" of relation "animal" violates not-null constraint
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:185: NOTICE:  I04-microchip rechazada 23505 [animal_numero_microchip_key] duplicate key value violates unique constraint "animal_numero_microchip_key"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:187: NOTICE:  I04-edad rechazada 23514 [animal_edad_estimada_check] new row for relation "animal" violates check constraint "animal_edad_estimada_check"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:189: NOTICE:  I04-especie-formato rechazada 23514 [especie_animal_check] value for domain especie_animal violates check constraint "especie_animal_check"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:191: NOTICE:  I04-especie-historica rechazada P1002 [] La identidad o especie histórica del animal es fija
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:193: NOTICE:  I04-codigo rechazada P1002 [] La identidad o especie histórica del animal es fija
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:195: NOTICE:  I05-organizacion-pk rechazada 23505 [organizacion_externa_pkey] duplicate key value violates unique constraint "organizacion_externa_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:197: NOTICE:  I05-organizacion-nombre rechazada 23502 [] null value in column "nombre_organizacion" of relation "organizacion_externa" violates not-null constraint
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:199: NOTICE:  I05-organizacion-delete rechazada 23503 [ingreso_organizacion_origen_id_fkey] update or delete on table "organizacion_externa" violates foreign key constraint "ingreso_organizacion_origen_id_fkey" on table "ingreso"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:202: NOTICE:  I06-ingreso-pk rechazada 23505 [ingreso_pkey] duplicate key value violates unique constraint "ingreso_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:204: NOTICE:  I06-propietario rechazada 23503 [ingreso_propietario_anterior_id_fkey] insert or update on table "ingreso" violates foreign key constraint "ingreso_propietario_anterior_id_fkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:206: NOTICE:  I06-traslado rechazada 23514 [ingreso_organizacion] new row for relation "ingreso" violates check constraint "ingreso_organizacion"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:208: NOTICE:  I06-otra rechazada 23514 [ingreso_detalle] new row for relation "ingreso" violates check constraint "ingreso_detalle"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:210: NOTICE:  I06-periodo rechazada 23514 [instante_check] value for domain instante violates check constraint "instante_check"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:213: NOTICE:  I06-solape rechazada 23P01 [ingreso_etapas_no_solapan] conflicting key value violates exclusion constraint "ingreso_etapas_no_solapan"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:215: NOTICE:  I06-contexto-modificacion rechazada P1002 [] El cambio de etapa contradice su historial de alojamiento
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:217: NOTICE:  I06-cierre-directo rechazada P1002 [] El cambio de etapa contradice su historial de alojamiento
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:219: NOTICE:  I06-ingreso-delete rechazada 23503 [estancia_ingreso_animal_fk] update or delete on table "ingreso" violates foreign key constraint "estancia_ingreso_animal_fk" on table "estancia"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:221: NOTICE:  I07-ubicacion-pk rechazada 23505 [ubicacion_pkey] duplicate key value violates unique constraint "ubicacion_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:223: NOTICE:  I07-capacidad rechazada 23514 [ubicacion_capacidad_check] new row for relation "ubicacion" violates check constraint "ubicacion_capacidad_check"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:225: NOTICE:  I07-condicion rechazada 23514 [ubicacion_por_tipo] new row for relation "ubicacion" violates check constraint "ubicacion_por_tipo"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:227: NOTICE:  I07-externa rechazada 23514 [ubicacion_por_tipo] new row for relation "ubicacion" violates check constraint "ubicacion_por_tipo"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:229: NOTICE:  I07-hogar-sin-oferente rechazada 23514 [ubicacion_por_tipo] new row for relation "ubicacion" violates check constraint "ubicacion_por_tipo"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:231: NOTICE:  I07-hogar-oferente-fk rechazada 23503 [ubicacion_persona_oferente_id_fkey] insert or update on table "ubicacion" violates foreign key constraint "ubicacion_persona_oferente_id_fkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:233: NOTICE:  I07-ofertas-solapadas rechazada 23P01 [ubicacion_ofertas_no_solapan] conflicting key value violates exclusion constraint "ubicacion_ofertas_no_solapan"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:235: NOTICE:  I07-oferente-historico rechazada P1002 [] Una ubicación utilizada conserva su configuración histórica
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:236: NOTICE:  I07-capacidad-historica rechazada P1002 [] Una ubicación utilizada conserva su configuración histórica
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:238: NOTICE:  I07-ubicacion-delete rechazada 23503 [estancia_ubicacion_id_fkey] update or delete on table "ubicacion" violates foreign key constraint "estancia_ubicacion_id_fkey" on table "estancia"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:240: NOTICE:  I08-especie-pk rechazada 23505 [ubicacion_especie_aceptada_pkey] duplicate key value violates unique constraint "ubicacion_especie_aceptada_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:241: NOTICE:  I08-especie-nula rechazada 23502 [] null value in column "especie" of relation "ubicacion_especie_aceptada" violates not-null constraint
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:242: NOTICE:  I08-especie-tipo rechazada P1003 [] Solo un hogar temporal declara especies admitidas
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:244: NOTICE:  I08-especie-referencia rechazada 23503 [ubicacion_especie_aceptada_ubicacion_id_fkey] insert or update on table "ubicacion_especie_aceptada" violates foreign key constraint "ubicacion_especie_aceptada_ubicacion_id_fkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:246: NOTICE:  I08-especie-historica rechazada P1002 [] La especie admitida respalda una estancia histórica
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:249: NOTICE:  I09-estancia-pk rechazada 23505 [estancia_pkey] duplicate key value violates unique constraint "estancia_pkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:252: NOTICE:  I09-contexto rechazada 23503 [estancia_ingreso_animal_fk] insert or update on table "estancia" violates foreign key constraint "estancia_ingreso_animal_fk"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:255: NOTICE:  I09-vigente rechazada 23P01 [estancia_no_solapa] conflicting key value violates exclusion constraint "estancia_no_solapa"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:257: NOTICE:  I09-cierre rechazada 23514 [estancia_cierre] new row for relation "estancia" violates check constraint "estancia_cierre"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:259: NOTICE:  I09-prevision rechazada 23514 [estancia_periodo_previsto] new row for relation "estancia" violates check constraint "estancia_periodo_previsto"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:261: NOTICE:  I09-actor rechazada 23503 [estancia_actor_entrada_id_fkey] insert or update on table "estancia" violates foreign key constraint "estancia_actor_entrada_id_fkey"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:267: NOTICE:  I10-receptor rechazada 23514 [ingreso_receptor] new row for relation "ingreso" violates check constraint "ingreso_receptor"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:269: NOTICE:  I10-motivo rechazada 23514 [ingreso_detalle] new row for relation "ingreso" violates check constraint "ingreso_detalle"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:272: NOTICE:  I10-origen rechazada 23514 [ingreso_origen_adopcion] new row for relation "ingreso" violates check constraint "ingreso_origen_adopcion"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:275: NOTICE:  I10-integracion rechazada 23514 [zz_ingreso_adopcion_pendiente] new row for relation "ingreso" violates check constraint "zz_ingreso_adopcion_pendiente"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:277: NOTICE:  I10-receptor-no-aplica rechazada 23514 [ingreso_receptor] new row for relation "ingreso" violates check constraint "ingreso_receptor"
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:280: NOTICE:  I10-FK del receptor validada en catálogo comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:290: NOTICE:  I11-cierre y contexto dentro de la transacción comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:291: NOTICE:  I11-etapa-cerrada rechazada P1004 [] Se requiere un ingreso existente y abierto
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:298: NOTICE:  I11-nueva etapa en la frontera comprobada
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:304: NOTICE:  I12-estancia-delete rechazada 42501 [] permission denied for table estancia
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:305: NOTICE:  I12-estancia-update rechazada 42501 [] permission denied for table estancia
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:308: NOTICE:  I12-estancia-insert rechazada 42501 [] permission denied for table estancia
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:309: NOTICE:  I12-catalogo rechazada 42501 [] permission denied for table ubicacion
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:310: NOTICE:  I12-participacion-delete rechazada 42501 [] permission denied for table participacion
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:311: NOTICE:  I12-cierre-privado rechazada 42501 [] permission denied for function _cerrar_etapa_alojamiento
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:312: NOTICE:  I12-truncate rechazada 42501 [] permission denied for table estancia
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:317: NOTICE:  I12-aislamiento rechazada P1001 [] Alojamiento requiere READ COMMITTED
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/01_bloque_jason.sql:337: NOTICE:  I01–I12 después de los ROLLBACK comprobada

```
