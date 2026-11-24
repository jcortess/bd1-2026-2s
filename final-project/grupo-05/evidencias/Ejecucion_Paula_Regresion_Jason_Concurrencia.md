# Regresión concurrente del bloque de Jason

Guiones originales intactos; base nueva de regresión con esquema ampliado. Dos conexiones por carrera y observador.


## 00_preparacion.sql

Salida 0.

```text
SET
SET
BEGIN
SET
DO
 estancia_origen 
-----------------
              15
(1 row)

COMMIT
 id_estancia | animal_codigo | ingreso_id | ubicacion_id | actor_entrada_id 
-------------+---------------+------------+--------------+------------------
          15 | HS-13         |         13 |            3 |                1
(1 row)

 id_ubicacion | capacidad | ocupacion | saldo_fisico 
--------------+-----------+-----------+--------------
            7 |         1 |         0 |            1
            8 |         2 |         0 |            2
            9 |         2 |         0 |            2
(3 rows)


```


## cupo

A/B terminaron con 0/0. Se observó la espera antes de liberar A.

```text
 pid_a |      estado_a       | pid_b | estado_b | wait_event_type | wait_event | bloqueadores | a_bloquea_b 
-------+---------------------+-------+----------+-----------------+------------+--------------+-------------
   487 | idle in transaction |   491 | active   | Lock            | advisory   | {487}        | t
(1 row)


SESION A
SET
SET
SET
BEGIN
SET
 sesion_a | estancia_reservada_en_a 
----------+-------------------------
      487 |                      16
(1 row)

Abra la sesion B y compruebe la espera. Luego pulse Intro para confirmar A: COMMIT
 id_estancia | animal_codigo | ingreso_id | ubicacion_id | actor_entrada_id 
-------------+---------------+------------+--------------+------------------
          16 | HS-11         |         11 |            7 |                1
(1 row)


SESION B
SET
SET
SET
BEGIN
SET
 sesion_b | capacidad | ocupacion 
----------+-----------+-----------
      491 |         1 |         0
(1 row)

psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/concurrencia/02_cupo_b.sql:15: NOTICE:  C1: P1014 La ubicación no tiene cupo en el intervalo real
DO
COMMIT
 animal_codigo | ingreso_id | ubicacion_id | actor_entrada_id 
---------------+------------+--------------+------------------
 HS-11         |         11 |            7 |                1
(1 row)


```


## animal

A/B terminaron con 0/0. Se observó la espera antes de liberar A.

```text
 pid_a |      estado_a       | pid_b | estado_b | wait_event_type | wait_event | bloqueadores | a_bloquea_b 
-------+---------------------+-------+----------+-----------------+------------+--------------+-------------
   506 | idle in transaction |   513 | active   | Lock            | advisory   | {506}        | t
(1 row)


SESION A
SET
SET
SET
BEGIN
SET
 sesion_a | origen | traslado_a 
----------+--------+------------
      506 |     15 |         17
(1 row)

Abra la sesion B y compruebe la espera. Luego pulse Intro para confirmar A: COMMIT
 id_estancia | ingreso_id | ubicacion_id | persona_oferente_id | aprobacion_hogar_id | actor_entrada_id 
-------------+------------+--------------+---------------------+---------------------+------------------
          17 |         13 |            8 |                   2 |                   2 |                1
(1 row)


SESION B
SET
SET
SET
BEGIN
SET
 sesion_b | id_estancia | animal_codigo | ubicacion_id 
----------+-------------+---------------+--------------
      513 |          15 | HS-13         |            3
(1 row)

DO
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/concurrencia/04_animal_b.sql:21: NOTICE:  C2: P1006 La estancia vigente difiere de la esperada
COMMIT
 id_estancia | ingreso_id | ubicacion_id | persona_oferente_id | aprobacion_hogar_id | actor_entrada_id 
-------------+------------+--------------+---------------------+---------------------+------------------
          17 |         13 |            8 |                   2 |                   2 |                1
(1 row)


```


## 06_verificar.sql

Salida 0.

```text
SET
SET
DO
 id_estancia | animal_codigo | ingreso_id | ubicacion_id |   fecha_inicio_real    |     fecha_fin_real     | persona_oferente_id | aprobacion_hogar_id | actor_entrada_id | actor_salida_id 
-------------+---------------+------------+--------------+------------------------+------------------------+---------------------+---------------------+------------------+-----------------
          16 | HS-11         |         11 |            7 | 2026-10-06 09:00:00-06 |                        |                     |                     |                1 |                
          15 | HS-13         |         13 |            3 | 2026-10-06 08:00:00-06 | 2026-10-07 09:00:00-06 |                     |                     |                1 |               1
          17 | HS-13         |         13 |            8 | 2026-10-07 09:00:00-06 |                        |                   2 |                   2 |                1 |                
(3 rows)

 id_ubicacion | ocupacion | capacidad | saldo_fisico 
--------------+-----------+-----------+--------------
            7 |         1 |         1 |            0
            8 |         1 |         2 |            1
            9 |         0 |         2 |            2
(3 rows)


```
