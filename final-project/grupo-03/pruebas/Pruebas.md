# Pruebas de estructura e integridad — Universidad Horizonte / Grupo 03

## 1. Objeto y fuentes de verificación

Este documento registra las pruebas de estructura e integridad del modelo físico de Universidad Horizonte, compuesto por 26 relaciones y 135 atributos. Las verificaciones se realizaron mediante dos baterías sucesivas: [`01_pruebas_base.sql`](01_pruebas_base.sql), correspondiente a las 16 relaciones base y sus 57 atributos, y [`02_pruebas_relaciones.sql`](02_pruebas_relaciones.sql), correspondiente a las diez relaciones adicionales y sus 78 atributos.

Los esquemas examinados se definen en [`01_esquema_base.sql`](../sql/01_esquema_base.sql) y [`03_esquema_relaciones.sql`](../sql/03_esquema_relaciones.sql). Los datos iniciales proceden de [`02_datos_base.sql`](../sql/02_datos_base.sql) y [`04_datos_relaciones.sql`](../sql/04_datos_relaciones.sql). La cobertura se fundamenta en el modelo relacional y el diccionario corregidos.

Las pruebas comprueban estructuras, referencias, dominios, obligatoriedad, operaciones válidas, casos de frontera, rechazos por restricciones específicas y efectos posteriores. Los resultados se limitan a las condiciones efectivamente examinadas por cada batería.

**Entorno de ejecución:** PostgreSQL 17.11 (`postgres:17.11-bookworm`), servicio `db` de Docker Compose, usuario `bd1` y base `universidad_horizonte_prueba_01`.

## 2. Pruebas de las estructuras base: preparación y criterio de aceptación

**Preparación:** la batería `01_pruebas_base.sql` se ejecutó después de instalar `01_esquema_base.sql` y cargar `02_datos_base.sql`, cuando la base contenía 16 tablas, 57 atributos y 64 registros iniciales. Esta es la precondición de las pruebas documentadas en las secciones 2 a 8. Para reproducirlas desde cero debe utilizarse una base nueva y ejecutar la batería antes de instalar `03_esquema_relaciones.sql`; su inventario estructural no corresponde al esquema completo de 26 tablas.

Desde `final-project/grupo-03/`, con el servicio `db` en ejecución:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/01_pruebas_base.sql
if ($LASTEXITCODE -ne 0) { throw "Error inesperado en las pruebas de integridad." }
```

Un caso negativo se considera aprobado **solo si** el motor rechaza la sentencia por el `SQLSTATE` y el nombre exacto de la restricción esperados. El guion ejecuta cada sentencia negativa dentro de un bloque de excepción PL/pgSQL, comprueba ambos diagnósticos y falla si la sentencia se acepta o si se rechaza por otro motivo. Los cinco casos de nulabilidad comparan `SQLSTATE = 23502` y la columna concreta. Cualquier `ERROR` no controlado detiene `psql` por `ON_ERROR_STOP=1`.

Las operaciones válidas y las comprobaciones de estado se ejecutan dentro de la transacción abierta por el guion; terminan con un `ROLLBACK` intencional. Las consultas de lectura desde una conexión nueva comprueban el estado persistido. La identidad `id_requisito` se genera automáticamente en la semilla; en las inserciones temporales de prueba se utilizan identificadores explícitos porque los avances de secuencias no se revierten con `ROLLBACK`.

## 3. Inventario de comprobaciones de las estructuras base

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

## 7. Comprobaciones de estado y repetición de las estructuras base

### Estado interno de la transacción

Tras el `ROLLBACK` de la batería base, se abrió una nueva conexión PostgreSQL y se consultaron las cardinalidades de las 16 relaciones existentes en esa etapa. La siguiente consulta reproduce dicha comprobación antes de incorporar los datos complementarios.

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

**Resultado esperado:** conservación de las 16 cardinalidades originales, con `TOTAL = 64`. **Resultado observado:** los 16 recuentos coincidieron con la semilla base; la consulta devolvió 17 filas, incluida la fila total. La comprobación posterior acreditó la conservación de las cantidades. Los valores modificados temporalmente se comprobaron dentro de la transacción; no se efectuó una lectura independiente posterior de la capacidad del espacio.

Para repetir esta batería debe reproducirse primero la instalación base en una base nueva y ejecutarse `01_pruebas_base.sql` antes de incorporar las relaciones adicionales. No debe repetirse el esquema ni la carga inicial sobre una base ya instalada. La validación complementaria y su repetición se documentan en la sección 9.

## 8. Resultado de la validación de las estructuras base

La ejecución observada finalizó con `ROLLBACK` y sin errores inesperados. El conjunto de pruebas de las estructuras base superó la comparación del catálogo, la revisión de los 64 registros iniciales, las nueve operaciones válidas, los 53 casos negativos y los cinco rechazos por nulabilidad. La consulta posterior confirmó los recuentos persistidos de los datos iniciales.

Los resultados acreditan el comportamiento **de las restricciones y los datos concretos incluidos en `01_pruebas_base.sql`**. No demuestran por sí solos todas las combinaciones posibles ni sustituyen las verificaciones de integridad contextual o de operaciones transaccionales que exijan otras relaciones del modelo.

## 9. Pruebas de las relaciones adicionales

### 9.1. Preparación y ejecución

La batería [`02_pruebas_relaciones.sql`](02_pruebas_relaciones.sql) verifica las diez relaciones adicionales y sus restricciones declarativas sobre el esquema completo.

**Precondiciones:** instalación confirmada de las 26 relaciones y 135 atributos, con ambas cargas de datos iniciales realizadas. La semilla complementaria contiene cuatro grupos, cinco bloques horarios, cinco asignaciones docentes, un traslado de plan y un reconocimiento académico. No contiene solicitudes de matrícula ni registros en los cuatro historiales o excepciones operativas restantes.

Desde `final-project/grupo-03/`, con el servicio PostgreSQL disponible:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/02_pruebas_relaciones.sql
```

El guion ejecuta los casos dentro de una transacción que finaliza con `ROLLBACK`. Las operaciones positivas y sus efectos se comprueban antes de la reversión.

### 9.2. Estructura y datos iniciales

| Comprobación | Resultado esperado | Resultado observado |
|---|---|---|
| Inventario físico | 26 tablas y 135 atributos. | Coincidencia comprobada mediante consultas al catálogo. |
| Definición de las diez relaciones adicionales | Correspondencia exacta de 78 columnas en nombre, tipo y nulabilidad. | Sin diferencias detectadas por el bloque de validación. |
| Unicidad parcial del docente responsable | Existencia del índice único parcial `uq_grupo_docente_responsable`. | Índice identificado en `pg_index`. |
| Datos iniciales | Cardinalidades de la semilla complementaria y existencia de las admisiones de referencia. | Bloque de comprobación finalizado satisfactoriamente. |

### 9.3. Casos positivos y de frontera

Los escenarios se preparan mediante registros temporales válidos. Cada acción se encuentra en el bloque de operaciones positivas de `02_pruebas_relaciones.sql`; las verificaciones posteriores consultan los datos antes del `ROLLBACK`.

| Relación y aspecto examinado | Preparación y acción | Resultado esperado y comprobación observada |
|---|---|---|
| `GRUPO` — capacidad y estado de oferta | Insertar grupos con capacidades cero y positiva; modificar capacidad y estado; eliminar un grupo sin dependencias. | Operaciones aceptadas. Se comprobaron los valores finales temporales de los grupos 20 y 13 y la ausencia del grupo eliminado. |
| `BLOQUE_HORARIO` — RN-07, restricciones locales | Insertar bloques con día y horas válidos, incluidos día 7 y actividad no presencial; modificar un intervalo horario válido. | Operaciones aceptadas. Se comprobó la referencia del bloque presencial utilizado como dato de control. |
| `GRUPO_DOCENTE` — roles | Incorporar docentes responsables a grupos temporales. | Inserciones aceptadas. La prohibición de un segundo responsable se comprobó mediante casos negativos específicos. |
| `TRASLADO_PLAN` — RN-03, datos y referencias | Insertar dos traslados con versiones diferentes, fecha, motivo y autorizador válidos. | Inserciones aceptadas; los dominios y referencias se contrastaron con los rechazos correspondientes. |
| `RECONOCIMIENTO_ACADEMICO` — RN-04, origen y participación | Insertar reconocimientos de origen institucional y externo; actualizar válidamente la representación del origen. | Operaciones aceptadas. Se comprobó el origen final del reconocimiento utilizado como control. |
| `HISTORIAL_OFERTA` — RN-19, representación de eventos | Registrar apertura, cambio de cupo, cierre y cancelación con estados, capacidades y referencias válidas. | Ocho eventos temporales comprobados; se verificaron estados y capacidades seleccionados. |
| `SOLICITUD_MATRICULA` — RN-11 y RN-12, representación declarativa | Insertar solicitudes en estados matriculada, rechazada, en espera, retirada y anulada; registrar una transición y valores académicos. | Se comprobaron seis solicitudes, estados seleccionados, orden de espera, momento de transición y valores académicos. |
| `HISTORIAL_SOLICITUD` — tipos de evento | Insertar transiciones y evaluaciones sin cambio de estado, incluidos estados iguales o ambos nulos. | Inserciones aceptadas; las formas inválidas se examinaron mediante casos negativos. |
| `EXCEPCION_REQUISITO` — RN-15, autorización y referencias | Insertar dos excepciones vinculadas a solicitudes, requisitos y autorizadores existentes. | Se comprobaron dos excepciones temporales. |
| `HISTORIAL_CORRECCION_CALIFICACION` — RN-17 y RN-20, conservación de cambios | Registrar dos correcciones sucesivas con calificaciones `80 → 85 → 90`, resultado académico, fecha, motivo y autorizador. | Se comprobaron los dos eventos y la calificación final temporal `90`, con resultado `aprobado`. |

Estas operaciones examinan la integridad declarativa y la representación de los datos. No constituyen la ejecución funcional de los procesos de oferta, resolución de matrícula o gestión de espera.

### 9.4. Casos negativos

Cada caso negativo está identificado en `02_pruebas_relaciones.sql` mediante una etiqueta única, una sentencia SQL, un `SQLSTATE` esperado y la restricción o columna responsable del rechazo.

El bloque PL/pgSQL ejecuta individualmente cada sentencia y contrasta su diagnóstico. Los rechazos esperados se gestionan mediante subtransacciones, permitiendo continuar la batería. Una aceptación inesperada o una discrepancia de diagnóstico provoca una excepción y detiene la ejecución.

| Grupo de comprobaciones | Casos | Condiciones examinadas |
|---|---:|---|
| `GRUPO` | 9 | Identidad, unicidad contextual, capacidad, modalidad, estado, referencias y obligatoriedad. |
| `BLOQUE_HORARIO` | 9 | Identidad, dominio del día, límites horarios, espacio presencial, referencias y obligatoriedad. |
| `TRASLADO_PLAN` | 7 | Identidad, versiones diferentes, motivo y referencias. |
| `RECONOCIMIENTO_ACADEMICO` | 8 | Identidad, exclusividad del origen, textos obligatorios y referencias, incluida la curricular compuesta. |
| `GRUPO_DOCENTE` | 6 | Identidad compuesta, unicidad del responsable, rol, referencias y obligatoriedad. |
| `HISTORIAL_OFERTA` | 12 | Identidad, tipos de cambio, estados, cupos, forma del evento, motivo y referencias. |
| `SOLICITUD_MATRICULA` | 14 | Identidad, estado, razones, orden de espera, autorreferencia, datos académicos y referencias. |
| `HISTORIAL_SOLICITUD` | 12 | Identidad, tipos de evento, estados, forma de transiciones y evaluaciones, motivo y referencias. |
| `EXCEPCION_REQUISITO` | 5 | Identidad, referencias y motivo. |
| `HISTORIAL_CORRECCION_CALIFICACION` | 7 | Identidad, cambio efectivo, valores académicos, motivo y referencias. |
| Modificaciones y eliminaciones | 13 | Restricciones aplicadas durante `UPDATE` y protección referencial durante `UPDATE` y `DELETE`. |
| **Total** | **102** | **Rechazos por la causa especificada.** |

La distribución por diagnóstico esperado fue de 13 violaciones de unicidad (`23505`), 32 violaciones referenciales (`23503`), 53 violaciones de restricciones `CHECK` (`23514`) y cuatro violaciones de obligatoriedad (`23502`).

**Resultado observado:** el bloque completó la comparación individual de los 102 casos y finalizó satisfactoriamente, sin errores no controlados.

### 9.5. Estado posterior y repetibilidad

Después de los casos negativos, el guion comparó los recuentos de las diez relaciones antes y después de los rechazos. También verificó valores de control en `GRUPO`, `BLOQUE_HORARIO`, `RECONOCIMIENTO_ACADEMICO`, `SOLICITUD_MATRICULA`, `HISTORIAL_OFERTA` e `HISTORIAL_CORRECCION_CALIFICACION`.

**Resultado esperado:** los rechazos no deben modificar las cantidades ni los valores examinados.

**Resultado observado:** las comprobaciones finalizaron sin excepción.

La ejecución terminó con `ROLLBACK`. Mediante una conexión independiente se consultaron posteriormente las cardinalidades de las diez relaciones.

```sql
SELECT
    (SELECT COUNT(*) FROM grupo) AS grupos,
    (SELECT COUNT(*) FROM bloque_horario) AS bloques,
    (SELECT COUNT(*) FROM grupo_docente) AS docentes,
    (SELECT COUNT(*) FROM traslado_plan) AS traslados,
    (SELECT COUNT(*) FROM reconocimiento_academico) AS reconocimientos,
    (SELECT COUNT(*) FROM solicitud_matricula) AS solicitudes,
    (SELECT COUNT(*) FROM historial_oferta) AS historial_oferta,
    (SELECT COUNT(*) FROM historial_solicitud) AS historial_solicitud,
    (SELECT COUNT(*) FROM excepcion_requisito) AS excepciones,
    (SELECT COUNT(*) FROM historial_correccion_calificacion) AS correcciones;
```

| Grupos | Bloques | Docentes | Traslados | Reconocimientos | Solicitudes | Hist. oferta | Hist. solicitud | Excepciones | Correcciones |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 5 | 5 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |

Los resultados coincidieron con la semilla complementaria. La comprobación independiente confirma las cardinalidades persistidas; los valores de los escenarios temporales fueron contrastados dentro de la transacción.

La batería puede repetirse sobre la base correctamente instalada y con la semilla conservada, ejecutando únicamente `02_pruebas_relaciones.sql`.

### 9.6. Conclusión

Las pruebas de las diez relaciones adicionales finalizaron satisfactoriamente para las restricciones declarativas, casos positivos, negativos, de frontera y modificaciones o eliminaciones examinadas.

Los resultados no acreditan por sí solos las garantías contextuales entre relaciones ni la aceptación funcional, transaccional y concurrente de G03-P01, G03-P02 y G03-P03, que requieren mecanismos y pruebas específicos.