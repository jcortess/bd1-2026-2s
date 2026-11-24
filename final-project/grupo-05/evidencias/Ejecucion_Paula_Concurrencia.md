# Concurrencia real G05-P02

Base `huellas_g05_paula_20261124_c`. Dos conexiones psql por carrera y una tercera observadora.


## 00_preparacion.sql

Salida `0`.

```text
SET
SET
BEGIN
SET
 crear_solicitud 
-----------------
              13
(1 row)

 crear_solicitud 
-----------------
              14
(1 row)

COMMIT
 id_solicitud |           clave_operacion            | decision_id |  estado  
--------------+--------------------------------------+-------------+----------
           13 | 050c0000-0000-0000-0000-000000000001 |          29 | RECIBIDA
           14 | 050c0000-0000-0000-0000-000000000002 |          30 | RECIBIDA
(2 rows)


```


## Carrera commit

Se observó `Lock/advisory` antes de liberar A. Códigos A/B: `0/0`.

Observador:

```text
 pid_a |          sesion_a          |      estado_a       | pid_b |          sesion_b          | estado_b | wait_event_type | wait_event | bloqueadores | a_bloquea_b 
-------+----------------------------+---------------------+-------+----------------------------+----------+-----------------+------------+--------------+-------------
   478 | huellas_g05_paula_commit_a | idle in transaction |   482 | huellas_g05_paula_commit_b | active   | Lock            | advisory   | {478}        | t
(1 row)


```

A:

```text
SET
SET
SET
BEGIN
SET
 pid_a | decision_a 
-------+------------
   478 |         31
(1 row)

PAULA_A_LISTA
Compruebe B esperando desde otra sesión; pulse Intro para COMMIT de A: COMMIT

```

B:

```text
SET
SET
SET
BEGIN
SET
 pid_b | id_solicitud | decision_id |  estado  
-------+--------------+-------------+----------
   482 |           13 |          29 | RECIBIDA
(1 row)

DO
psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/concurrencia_paula/02_commit_b.sql:17: NOTICE:  C-P01 rechazo real: P2021 Antecedente desactualizado; relea la decisión y no reintente a ciegas
COMMIT
 id_solicitud | decision_id |  estado  
--------------+-------------+----------
           13 |          31 | APROBADA
(1 row)


```


## Carrera rollback

Se observó `Lock/advisory` antes de liberar A. Códigos A/B: `0/0`.

Observador:

```text
 pid_a |           sesion_a           |      estado_a       | pid_b |           sesion_b           | estado_b | wait_event_type | wait_event | bloqueadores | a_bloquea_b 
-------+------------------------------+---------------------+-------+------------------------------+----------+-----------------+------------+--------------+-------------
   496 | huellas_g05_paula_rollback_a | idle in transaction |   501 | huellas_g05_paula_rollback_b | active   | Lock            | advisory   | {496}        | t
(1 row)


```

A:

```text
SET
SET
SET
BEGIN
SET
 pid_a | decision_a 
-------+------------
   496 |         33
(1 row)

PAULA_A_LISTA
Compruebe B esperando desde otra sesión; pulse Intro para ROLLBACK de A: ROLLBACK

```

B:

```text
SET
SET
SET
BEGIN
SET
 decidir_solicitud 
-------------------
                34
(1 row)

COMMIT
 id_solicitud | decision_id |  estado   
--------------+-------------+-----------
           14 |          34 | RECHAZADA
(1 row)


```


## 06_verificar.sql

Salida `0`.

```text
SET
SET
DO
 solicitud_id | id_evento_solicitud | antecedente_decision_id |         fecha          |   estado_resultante   | responsable_id |                      razon                      
--------------+---------------------+-------------------------+------------------------+-----------------------+----------------+-------------------------------------------------
           13 |                  29 |                         | 2026-10-12 08:00:00-06 | RECIBIDA              |              1 | Recepción de solicitud
           13 |                  31 |                      29 | 2026-10-12 09:00:00-06 | APROBADA              |              1 | Decisión concurrente A
           13 |                  36 |                      31 | 2026-10-12 11:00:00-06 | PENDIENTE_INFORMACION |              7 | Revisión informada posterior al conflicto
           14 |                  30 |                         | 2026-10-12 08:00:00-06 | RECIBIDA              |              1 | Recepción de solicitud
           14 |                  34 |                      30 | 2026-10-12 10:00:00-06 | RECHAZADA             |              7 | Decisión B confirmada después del ROLLBACK de A
(5 rows)

 id_solicitud |        estado         | decision_id 
--------------+-----------------------+-------------
           13 | PENDIENTE_INFORMACION |          36
           14 | RECHAZADA             |          34
(2 rows)

psql:/mnt/c/Users/rmari/Desktop/TEC/IVSemestre/Bases/Proyecto2/bd1-2026-2s/final-project/grupo-05/pruebas/concurrencia_paula/06_verificar.sql:35: NOTICE:  C-P03 reintento sin efectos: P2021 Antecedente desactualizado; relea la decisión y no reintente a ciegas

```
