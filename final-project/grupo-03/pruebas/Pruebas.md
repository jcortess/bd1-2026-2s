# Pruebas de estructura e integridad — Universidad Horizonte / Grupo 03

## 1. Objeto y fuentes de verificación

Este documento identifica las comprobaciones reproducibles ejecutadas sobre las **16 relaciones base y sus 57 atributos** del modelo físico consolidado. La cobertura procede del modelo relacional y el diccionario corregidos, y de las restricciones físicas definidas en [`01_esquema_base.sql`](../sql/01_esquema_base.sql). La batería ejecutable es [`01_pruebas_base.sql`](01_pruebas_base.sql); los datos de preparación proceden de [`02_datos_base.sql`](../sql/02_datos_base.sql).

El script de pruebas examina la estructura, los datos iniciales, operaciones aceptadas, condiciones de frontera, rechazos por restricciones concretas y el estado posterior. Los resultados observados se consignan a partir de las salidas registradas durante la ejecución en PostgreSQL. Las verificaciones de este documento corresponden a las estructuras efectivamente instaladas; una validación de datos de ejemplo no se interpreta como garantía general de reglas contextuales entre relaciones.

**Entorno observado:** PostgreSQL 17.11 (`postgres:17.11-bookworm`), cliente `psql` ejecutado mediante el servicio `db` de Docker Compose, base `universidad_horizonte_prueba_01`. Se ejecutó la batería después de instalar el esquema y cargar la semilla; los resultados observados corresponden a esa ejecución.

## 2. Precondiciones, ejecución y criterio de aceptación

**Preparación:** utilizar una base destinada a pruebas del proyecto, con `sql/01_esquema_base.sql` ejecutado y confirmado una sola vez, seguido de `sql/02_datos_base.sql`, también confirmado. Antes de ejecutar la batería, la base debe contener exactamente las 16 tablas y los 64 registros de la semilla, sin registros temporales de ejecuciones anteriores. La instalación inicial y el orden de los archivos se documentan en [`README.md`](../README.md).

Desde `final-project/grupo-03/`, con el servicio `db` en ejecución:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/01_pruebas_base.sql
if ($LASTEXITCODE -ne 0) { throw "Error inesperado en las pruebas de integridad." }
```

Un caso negativo se considera aprobado **solo si** el motor rechaza la sentencia por el `SQLSTATE` y el nombre exacto de la restricción esperados. El guion ejecuta cada sentencia negativa dentro de un bloque de excepción PL/pgSQL, comprueba ambos diagnósticos y falla si la sentencia se acepta o si se rechaza por otro motivo. Los cinco casos de nulabilidad comparan `SQLSTATE = 23502` y la columna concreta. Cualquier `ERROR` no controlado detiene `psql` por `ON_ERROR_STOP=1`.

Las operaciones válidas y las comprobaciones de estado se ejecutan dentro de la transacción abierta por el guion; terminan con un `ROLLBACK` intencional. Las consultas de lectura desde una conexión nueva comprueban el estado persistido. La identidad `id_requisito` se genera automáticamente en la semilla; en las inserciones temporales de prueba se utilizan identificadores explícitos porque los avances de secuencias no se revierten con `ROLLBACK`.

## 3. Inventario de comprobaciones ejecutadas

| ID documental | Elemento o condición comprobada | Preparación y acción | Resultado esperado | Resultado observado |
| --- | --- | --- | --- | --- |
| E-01 | Cobertura estructural del modelo físico base | Consultar `pg_tables` y contrastar columnas, tipos, nulabilidad e identidad mediante `information_schema` | 16 tablas; 57 columnas exactas; `id_requisito` con identidad `BY DEFAULT`; extensión e índices presentes | Bloque `DO` finalizado; aviso de estructura correcta |
| E-02 | PK, FK, UNIQUE y acciones referenciales de las 16 relaciones | Comparar composición y destino de las restricciones con `pg_constraint`; examinar acciones de FK | 16 PK, 15 FK, cuatro UNIQUE; acciones `NO ACTION` para actualización y eliminación de padres | Bloque `DO` finalizado; inventario de catálogo conforme |
| E-03 | Dominios e integridad especializada | Contrastar nombres de `CHECK`; definición y unicidad del índice parcial; método de acceso de la exclusión | 25 CHECK, índice único parcial de contactos principales y exclusión GiST de ventanas | Bloque de catálogo finalizado sin excepción |
| D-01 | Datos curriculares conservados de Lab03 | Consultas de agregación y recuento de `participacion_plan` y `requisito_curso` | 22 créditos obligatorios de la versión 102; tres requisitos para `UH-BDAT1`/102; diez requisitos con identificador alternativo | Bloque de datos finalizado sin excepción |
| D-02 | Intervalos y contextos de los datos iniciales | Contar ventanas de matrícula, comprobar el solapamiento entre tipos distintos y contrastar las combinaciones de admisión, carrera y sede de la semilla | Dos ventanas de matrícula, solapamiento entre tipos distintos y ninguna admisión sembrada con carrera/sede no habilitada | Bloque de datos finalizado sin excepción. La semilla contiene ventanas consecutivas, pero el bloque solo comprueba su cantidad, no la igualdad entre extremos adyacentes; la compatibilidad carrera/sede se comprueba solo para los datos sembrados |
| D-03 | Cardinalidad basal de la semilla | Comparar el número de filas de cada una de las 16 relaciones con la distribución esperada | Recuentos exactos de la tabla siguiente; 64 filas en total | Bloque de datos finalizado; consulta independiente posterior confirmó 64 registros |
| V-01 a V-09 | Inserciones y modificación válidas | Ejecutar las ocho inserciones y una actualización descritas en la sección 4 | Todas aceptadas y visibles dentro de la transacción | Ocho mensajes `INSERT 0 1`, uno `UPDATE 1` y bloque de comprobación positiva finalizado sin excepción |
| N-01 a N-53 | Infracciones de claves, referencias, unicidades, dominios y exclusión temporal | Ejecutar los 53 casos de la sección 5 y comparar diagnósticos | Rechazo por `SQLSTATE` y restricción indicados en cada fila | El bloque informó 53 rechazos por la causa exacta prevista y terminó sin excepción |
| NN-01 a NN-05 | Nulabilidad obligatoria | Ejecutar los cinco casos de la sección 6, inspeccionando `COLUMN_NAME` | Rechazo `23502` por la columna indicada | El bloque informó cinco verificaciones `NOT NULL` satisfactorias |
| P-01 | Ausencia de efectos de los rechazos dentro de la transacción | Comprobar periodo 1, cuatro ventanas, 11 requisitos (10 iniciales + 1 válido), tres contactos del estudiante `UH-ALU1` (dos iniciales + uno válido) y existencia de la escuela 1 | Todos los hechos de control conservados | El bloque de comprobación posterior terminó sin excepción |
| P-02 | Reversión y estado persistido | Ejecutar `ROLLBACK` y consultar mediante otra conexión | Solo permanece la semilla previamente confirmada: 16 tablas y 64 registros | Salida `ROLLBACK` y consulta de 16 relaciones/64 registros confirmadas |

### Correspondencia con reglas del modelo

| Regla o fuente | Casos que aportan evidencia | Alcance demostrado |
| --- | --- | --- |
| RN-01 — identidad institucional del estudiante | E-01, E-02, N-36; prueba de obligatoriedad NN-01 | Clave de estudiante y campos obligatorios comprobados; el rechazo de PK duplicada de la batería se realiza específicamente en ESCUELA, no en ESTUDIANTE |
| RN-02 — multiplicidad de admisiones | V-08, D-02, N-19, N-52 y N-53 | Una persona puede tener dos admisiones; referencias de admisión a estudiante, sede y versión válidas. La comprobación de combinaciones en D-02 se limita a la semilla |
| RN-05 — requisitos definidos por versión del plan | E-02, D-01, V-09, N-14 a N-18, N-50 y N-51 | PK de cuatro componentes, identificador alternativo, dominio y referencias a versión y cursos |
| RN-09 y RN-13 — intervalos de ventanas académicas | D-02, N-26 a N-29 y N-32 a N-33 | Existencia, tipos, límites y exclusión de superposiciones del mismo tipo/periodo; no se evalúa aquí una solicitud o un retiro concreto |
| Diccionario físico — claves, nulabilidad, catálogos y dominios de las restantes relaciones base | E-01 a E-03, V-01 a V-07, N-01 a N-53 y NN-01 a NN-05, según relación y restricción | Comprobación estructural y declarativa; no se atribuyen reglas RN adicionales a pruebas que solo validan campos o referencias |

Las referencias RN identifican **aspectos concretos** respaldados por estas pruebas, no la implementación íntegra de cada regla de negocio cuando exige consultas y decisiones entre relaciones.

### Distribución inicial de registros

| Relación | Registros esperados y contrastados |
| --- | ---: |
| `escuela` | 2 |
| `carrera` | 2 |
| `sede` | 2 |
| `estudiante` | 2 |
| `docente` | 2 |
| `persona_autorizadora` | 2 |
| `periodo_academico` | 1 |
| `curso` | 8 |
| `version_plan_estudios` | 3 |
| `carrera_sede` | 3 |
| `espacio` | 2 |
| `contacto_estudiante` | 3 |
| `ventana_periodo` | 4 |
| `participacion_plan` | 16 |
| `requisito_curso` | 10 |
| `admision` | 2 |
| **Total** | **64** |

## 4. Casos válidos y de frontera

**Estado inicial común:** semilla de 64 registros instalada; cada acción se realiza dentro de la misma transacción de pruebas. Las sentencias y las consultas `IF NOT EXISTS` que confirman cada efecto están en `01_pruebas_base.sql`, antes del bloque de casos negativos.

| ID | Relación / condición | Acción | Resultado esperado | Resultado observado y conclusión |
| --- | --- | --- | --- | --- |
| V-01 | ESTUDIANTE; segundo apellido opcional | Insertar `UH-TEST-VALIDO` con `segundo_apellido = NULL` | Inserción aceptada y columna nula | `INSERT 0 1`; consulta interna confirmó la fila. Conforme |
| V-02 | CURSO; límite inferior de créditos | Insertar `UH-TEST-CERO` con `cantidad_creditos = 0` | Inserción aceptada y crédito cero | `INSERT 0 1`; consulta interna confirmó el crédito. Conforme |
| V-03 | CONTACTO_ESTUDIANTE; principalidad por tipo | Insertar contacto no principal `id_contacto = 905`, de tipo correo, para `UH-ALU1` | Inserción aceptada junto al correo principal existente | `INSERT 0 1`; consulta interna confirmó el contacto no principal. Conforme |
| V-04 | PARTICIPACION_PLAN; atributo opcional | Insertar `UH-PROG1` en versión 201, con nivel recomendado `NULL` | Inserción aceptada con valor nulo | `INSERT 0 1`; consulta interna confirmó el valor nulo. Conforme |
| V-05 | ESPACIO; actualización dentro del dominio | Modificar la capacidad del espacio 1 a 31 | Actualización aceptada y capacidad 31 | `UPDATE 1`; consulta interna confirmó el nuevo valor. Conforme |
| V-06 | VERSION_PLAN_ESTUDIOS; vigencia abierta | Insertar versión 903 de carrera 10, con `fin_vigencia = NULL` | Inserción aceptada con fecha final nula | `INSERT 0 1`; consulta interna confirmó la vigencia abierta. Conforme |
| V-07 | PERIODO_ACADEMICO; fechas coincidentes | Insertar periodo 903 con inicio y finalización iguales | Inserción aceptada en la frontera permitida | `INSERT 0 1`; consulta interna confirmó ambas fechas iguales. Conforme |
| V-08 | ADMISION; multiplicidad e inactividad | Insertar admisión 904 para `UH-ALU1`, sede 2 y versión 102, inactiva | Inserción aceptada; dos admisiones para el estudiante | `INSERT 0 1`; consulta interna confirmó los datos y las dos admisiones. Conforme |
| V-09 | REQUISITO_CURSO; cursos no participantes en la versión | Insertar requisito entre `UH-PROG2` y `UH-PROG1` para versión 201, con `id_requisito = 910000` | Inserción aceptada por referencia a CURSO, sin exigir participación en el plan | `INSERT 0 1`; consulta interna confirmó requisito e identificador. Conforme |

El script comprueba estos nueve efectos mediante consultas de lectura **antes del `ROLLBACK`**. Las filas y el cambio de capacidad son temporales: no se presentan como datos persistidos.

## 5. Casos negativos: causa exacta

**Estado inicial común:** la semilla sigue disponible y ya se ejecutaron los casos válidos de la sección anterior. Cada sentencia de esta tabla se encuentra en el conjunto `VALUES` del bloque `DO $negativos$` de `01_pruebas_base.sql`, en el mismo orden. La acción exacta es el SQL asociado a la etiqueta correspondiente. La verificación de `SQLSTATE` y `CONSTRAINT_NAME` es individual para cada caso; los cambios rechazados se revierten en la subtransacción PL/pgSQL sin impedir la ejecución del siguiente.

Los códigos utilizados son `23505` (unicidad/clave), `23503` (referencia), `23514` (CHECK) y `23P01` (exclusión). **En la columna “Observado”, “Conforme” significa que el código y el nombre de restricción coincidieron en la ejecución real**, no únicamente que se produjo algún error.

| ID | Acción o infracción sometida a prueba | SQLSTATE esperado | Restricción esperada | Observado |
| --- | --- | --- | --- | --- |
| N-01 | PK duplicada | `23505` | `pk_escuela` | Conforme |
| N-02 | Estudiante nombre vacio | `23514` | `ck_estudiante_nombre_no_vacio` | Conforme |
| N-03 | Apellido opcional blanco | `23514` | `ck_estudiante_segundo_apellido_no_vacio` | Conforme |
| N-04 | Contacto FK estudiante | `23503` | `fk_contacto_estudiante` | Conforme |
| N-05 | Contacto principal duplicado | `23505` | `uq_contacto_principal_tipo` | Conforme |
| N-06 | Contacto terna duplicada | `23505` | `uq_contacto_tipo_valor` | Conforme |
| N-07 | Contacto tipo blanco | `23514` | `ck_contacto_tipo_no_vacio` | Conforme |
| N-08 | Curso escuela inexistente | `23503` | `fk_curso_escuela` | Conforme |
| N-09 | Curso creditos negativos | `23514` | `ck_curso_creditos` | Conforme |
| N-10 | Version fechas invertidas | `23514` | `ck_version_vigencia` | Conforme |
| N-11 | Participacion PK duplicada | `23505` | `pk_participacion_plan` | Conforme |
| N-12 | Participacion dominio incorrecto | `23514` | `ck_tipo_participacion` | Conforme |
| N-13 | Nivel opcional blanco | `23514` | `ck_participacion_nivel_no_vacio` | Conforme |
| N-14 | Requisito PK duplicada | `23505` | `pk_requisito_curso` | Conforme |
| N-15 | Requisito tipo invalido | `23514` | `ck_tipo_requisito` | Conforme |
| N-16 | Autorrequisito | `23514` | `ck_requisito_no_autorrequisito` | Conforme |
| N-17 | Requisito exigido inexistente | `23503` | `fk_requisito_exigido` | Conforme |
| N-18 | Requisito alternativo duplicado | `23505` | `uq_requisito_id` | Conforme |
| N-19 | Admision estudiante inexistente | `23503` | `fk_admision_estudiante` | Conforme |
| N-20 | Admision condicion vacia | `23514` | `ck_admision_condicion_no_vacia` | Conforme |
| N-21 | Carrera sede PK duplicada | `23505` | `pk_carrera_sede` | Conforme |
| N-22 | Espacio capacidad cero | `23514` | `ck_espacio_capacidad` | Conforme |
| N-23 | Espacio sede invalida | `23503` | `fk_espacio_sede` | Conforme |
| N-24 | Periodo fechas invertidas | `23514` | `ck_periodo_fechas` | Conforme |
| N-25 | Periodo codigo duplicado | `23505` | `uq_periodo_codigo` | Conforme |
| N-26 | Ventana tipo invalido | `23514` | `ck_ventana_tipo` | Conforme |
| N-27 | Ventana longitud cero | `23514` | `ck_ventana_intervalo` | Conforme |
| N-28 | Ventana solapada | `23P01` | `ex_ventana_tipo_periodo_no_solapado` | Conforme |
| N-29 | Ventana periodo inexistente | `23503` | `fk_ventana_periodo` | Conforme |
| N-30 | Autorizador UQ duplicada | `23505` | `uq_persona_autorizadora_identificacion` | Conforme |
| N-31 | Autor nombre blanco | `23514` | `ck_persona_autorizadora_nombre_no_vacio` | Conforme |
| N-32 | Delete padre referenciado | `23503` | `fk_ventana_periodo` | Conforme |
| N-33 | Update PK padre referenciado | `23503` | `fk_ventana_periodo` | Conforme |
| N-34 | UPDATE capacidad invalida | `23514` | `ck_espacio_capacidad` | Conforme |
| N-35 | Sede nombre blanco | `23514` | `ck_sede_nombre_no_vacio` | Conforme |
| N-36 | Estudiante codigo blanco | `23514` | `ck_estudiante_numero_no_vacio` | Conforme |
| N-37 | Estudiante primer apellido blanco | `23514` | `ck_estudiante_primer_apellido_no_vacio` | Conforme |
| N-38 | Docente nombre blanco | `23514` | `ck_docente_nombre_no_vacio` | Conforme |
| N-39 | Autorizador codigo blanco | `23514` | `ck_persona_autorizadora_identificacion_no_vacia` | Conforme |
| N-40 | Periodo codigo blanco | `23514` | `ck_periodo_codigo_no_vacio` | Conforme |
| N-41 | Curso codigo blanco | `23514` | `ck_curso_codigo_no_vacio` | Conforme |
| N-42 | Curso nombre blanco | `23514` | `ck_curso_nombre_no_vacio` | Conforme |
| N-43 | Espacio ubicacion blanco | `23514` | `ck_espacio_ubicacion_no_vacia` | Conforme |
| N-44 | Contacto valor blanco | `23514` | `ck_contacto_valor_no_vacio` | Conforme |
| N-45 | Version carrera inexistente | `23503` | `fk_version_carrera` | Conforme |
| N-46 | Carrera sede carrera inexistente | `23503` | `fk_carrera_sede_carrera` | Conforme |
| N-47 | Carrera sede sede inexistente | `23503` | `fk_carrera_sede_sede` | Conforme |
| N-48 | Participacion curso inexistente | `23503` | `fk_participacion_curso` | Conforme |
| N-49 | Participacion version inexistente | `23503` | `fk_participacion_version` | Conforme |
| N-50 | Requisito version inexistente | `23503` | `fk_requisito_version` | Conforme |
| N-51 | Requisito objetivo inexistente | `23503` | `fk_requisito_objetivo` | Conforme |
| N-52 | Admision sede inexistente | `23503` | `fk_admision_sede` | Conforme |
| N-53 | Admision version inexistente | `23503` | `fk_admision_version` | Conforme |

El control de la ejecución comprobó **53 de 53** rechazos con el diagnóstico esperado. Una aceptación inesperada o una causa distinta produce `RAISE EXCEPTION` y detiene el script. No se considera evidencia suficiente un aviso de error sin diagnóstico coincidente.

## 6. Pruebas de nulabilidad obligatoria

**Estado inicial común:** el mismo conjunto de datos y la misma transacción. Las sentencias se encuentran en `DO $nulos$` de `01_pruebas_base.sql`. El procedimiento captura la excepción `not_null_violation` y compara la columna reportada por PostgreSQL.

| ID | Acción inválida | Columna esperada | SQLSTATE esperado | Observado |
| --- | --- | --- | --- | --- |
| NN-01 | Nombre de estudiante a `NULL` | `nombre` | `23502` | Conforme |
| NN-02 | Activa de admision a `NULL` | `activa` | `23502` | Conforme |
| NN-03 | Fin de ventana a `NULL` | `fin` | `23502` | Conforme |
| NN-04 | Tipo de requisito a `NULL` | `tipo_requisito` | `23502` | Conforme |
| NN-05 | Vigencia inicial a `NULL` | `inicio_vigencia` | `23502` | Conforme |

Los cinco casos terminaron con el rechazo por la columna prevista; ninguna de estas filas inválidas quedó incorporada.

## 7. Comprobaciones de estado y repetición

### Estado interno de la transacción

El bloque `DO $posterior$` comprueba que siguen existiendo el periodo `id_periodo = 1` con código `2026-2` y la escuela `id_escuela = 1`, que existen cuatro ventanas vinculadas al periodo 1, que `requisito_curso` contiene 11 registros (incluida la inserción válida temporal) y que `UH-ALU1` mantiene tres contactos (incluido el contacto válido temporal). Todas las comprobaciones finalizaron sin excepción.

### Estado persistido después de la reversión

Tras el `ROLLBACK`, se abrió una nueva conexión `psql` y se consultaron los recuentos de las 16 tablas. La consulta de comprobación reproducible es:

```sql
WITH conteos AS (
    SELECT 'estudiante' AS relacion, COUNT(*) AS filas FROM estudiante
    UNION ALL SELECT 'admision', COUNT(*) FROM admision
    UNION ALL SELECT 'carrera', COUNT(*) FROM carrera
    UNION ALL SELECT 'sede', COUNT(*) FROM sede
    UNION ALL SELECT 'version_plan_estudios', COUNT(*) FROM version_plan_estudios
    UNION ALL SELECT 'periodo_academico', COUNT(*) FROM periodo_academico
    UNION ALL SELECT 'curso', COUNT(*) FROM curso
    UNION ALL SELECT 'escuela', COUNT(*) FROM escuela
    UNION ALL SELECT 'espacio', COUNT(*) FROM espacio
    UNION ALL SELECT 'docente', COUNT(*) FROM docente
    UNION ALL SELECT 'carrera_sede', COUNT(*) FROM carrera_sede
    UNION ALL SELECT 'participacion_plan', COUNT(*) FROM participacion_plan
    UNION ALL SELECT 'requisito_curso', COUNT(*) FROM requisito_curso
    UNION ALL SELECT 'contacto_estudiante', COUNT(*) FROM contacto_estudiante
    UNION ALL SELECT 'persona_autorizadora', COUNT(*) FROM persona_autorizadora
    UNION ALL SELECT 'ventana_periodo', COUNT(*) FROM ventana_periodo
)
SELECT relacion, filas FROM conteos
UNION ALL
SELECT 'TOTAL', SUM(filas) FROM conteos
ORDER BY relacion;
```

**Esperado:** los 16 recuentos iniciales de la sección 3 y `TOTAL = 64`. **Observado:** 16 relaciones con esos recuentos y `TOTAL = 64`, en 17 filas de resultado. La consulta posterior confirma la restitución de los recuentos iniciales. El `ROLLBACK` revierte por definición las inserciones y la actualización temporal; no se realizó una lectura independiente posterior del valor de capacidad del espacio. Los bloques internos ya habían comprobado los valores y referencias antes de revertir la transacción.

Para repetir la batería se requiere mantener intactas las 16 tablas y la semilla original, y volver a ejecutar el archivo de pruebas; no deben repetirse los archivos de esquema o datos sobre una base ya instalada. Si un caso falla inesperadamente, debe examinarse el error antes de reintentar y verificarse el estado de la conexión y de la base. El cierre de `psql` ante error detiene la sesión y revierte su transacción no confirmada, pero no reemplaza la comprobación del estado posterior.

## 8. Resultado y alcance de la evidencia

La ejecución observada finalizó con `ROLLBACK` y sin errores inesperados. El conjunto de pruebas de las estructuras base superó la comparación del catálogo, la revisión de los 64 registros iniciales, las nueve operaciones válidas, los 53 casos negativos y los cinco rechazos por nulabilidad. La consulta posterior confirmó los recuentos persistidos de los datos iniciales.

Los resultados acreditan el comportamiento **de las restricciones y los datos concretos incluidos en `01_pruebas_base.sql`**. No demuestran por sí solos todas las combinaciones posibles ni sustituyen las verificaciones de integridad contextual o de operaciones transaccionales que exijan otras relaciones del modelo.
