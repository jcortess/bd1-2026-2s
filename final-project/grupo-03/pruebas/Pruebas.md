# Pruebas de estructura e integridad — Universidad Horizonte / Grupo 03

## 1. Objeto y fuentes de verificación

Este documento registra las pruebas del modelo físico de Universidad Horizonte, compuesto por 26 relaciones y 135 atributos. Se ejecutaron tres baterías sobre estados sucesivos de instalación:

1. [`01_pruebas_base.sql`](01_pruebas_base.sql), sobre las 16 relaciones base, sus 57 atributos y 64 registros iniciales.
2. [`02_pruebas_relaciones.sql`](02_pruebas_relaciones.sql), sobre el esquema de 26 relaciones, después de incorporar las diez relaciones adicionales y sus 78 atributos.
3. [`03_pruebas_integridad_avanzada.sql`](03_pruebas_integridad_avanzada.sql), sobre el esquema completo con 81 registros iniciales y los controles de integridad contextual, temporal e histórica instalados.

Los esquemas examinados se definen en [`01_esquema_base.sql`](../sql/01_esquema_base.sql) y [`03_esquema_relaciones.sql`](../sql/03_esquema_relaciones.sql). Los datos iniciales proceden de [`02_datos_base.sql`](../sql/02_datos_base.sql) y [`04_datos_relaciones.sql`](../sql/04_datos_relaciones.sql). Los controles avanzados se instalan mediante [`05_integridad_avanzada.sql`](../sql/05_integridad_avanzada.sql). Las referencias RN corresponden a la [matriz de trazabilidad del modelo](../modelo/06_Matriz_Trazabilidad.md).

**Entorno de ejecución:** PostgreSQL 17.11 (`postgres:17.11-bookworm`), cliente `psql`, servicio `db` de Docker Compose y usuario `bd1`. Las tres baterías se ejecutaron en `universidad_horizonte_prueba_01`. Los cuatro conflictos concurrentes de la sección 10 se comprobaron mediante sesiones independientes en `universidad_horizonte_concurrencia_01`.

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
| RN-01 — identidad institucional del estudiante | E-01, E-02, N-36 | Clave de estudiante en el catálogo y rechazo del número institucional en blanco. El caso de PK duplicada N-01 corresponde a `ESCUELA` |
| RN-02 — multiplicidad de admisiones | V-08, D-02, N-19, N-52 y N-53 | Una persona puede tener dos admisiones; referencias de admisión a estudiante, sede y versión válidas. La comprobación de combinaciones en D-02 se limita a la semilla |
| RN-05 — requisitos definidos por versión del plan | E-02, D-01, V-09, N-14 a N-18, N-50 y N-51 | PK de cuatro componentes, identificador alternativo, dominio y referencias a versión y cursos |
| RN-09 y RN-13 — intervalos de ventanas académicas | D-02, N-26 a N-29 y N-32 a N-33 | Existencia, tipos, límites y exclusión de superposiciones del mismo tipo/periodo; no se evalúa aquí una solicitud o un retiro concreto |
| Diccionario físico — claves, nulabilidad, catálogos y dominios de las restantes relaciones base | E-01 a E-03, V-01 a V-07, N-01 a N-53 y NN-01 a NN-05, según relación y restricción | Comprobación estructural y declarativa |

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

Antes del `ROLLBACK`, el guion comprobó el periodo 1, sus cuatro ventanas, los once requisitos curriculares, los tres contactos de `UH-ALU1` y la existencia de la escuela 1. Los recuentos de requisitos y contactos incluían las inserciones válidas de la sección 4. Los rechazos de las secciones 5 y 6 conservaron esos valores de control.

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

## 9. Pruebas de las relaciones adicionales

### 9.1. Preparación y ejecución

La batería [`02_pruebas_relaciones.sql`](02_pruebas_relaciones.sql) verifica las diez relaciones adicionales y sus restricciones declarativas sobre el esquema completo.

**Precondiciones:** instalación confirmada de las 26 relaciones y 135 atributos, con ambas cargas de datos iniciales realizadas y antes de instalar `05_integridad_avanzada.sql`. La carga complementaria añade una admisión, cuatro grupos, cinco bloques horarios, cinco asignaciones docentes, un traslado de plan y un reconocimiento académico. Las tablas de solicitudes, historial de oferta, historial de solicitudes, excepciones y correcciones están vacías.

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

Para repetir la batería se utiliza el estado de la sección 9.1, con los archivos de instalación `01` a `04` y la semilla conservada. En ese estado se ejecuta únicamente `02_pruebas_relaciones.sql`.

### 9.6. Conclusión

Las pruebas de las diez relaciones adicionales finalizaron satisfactoriamente para las restricciones declarativas, casos positivos, negativos, de frontera y modificaciones o eliminaciones examinadas.

## 10. Pruebas de integridad avanzada

### 10.1. Preparación y ejecución

**Fecha de ejecución:** 27 de noviembre de 2026. La base secuencial contenía 26 tablas, 135 atributos y cero solicitudes de matrícula. Sobre el esquema y las dos cargas de datos de las secciones anteriores se instaló `05_integridad_avanzada.sql`. Después de la instalación se comprobaron 21 funciones `uh_%`, 94 triggers `uh_%` y la presencia de `public.uh_validar_integridad()`.

Desde `final-project/grupo-03/`, sobre la base secuencial en el estado indicado:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/05_integridad_avanzada.sql
if ($LASTEXITCODE -ne 0) { throw "Error al instalar la integridad avanzada." }

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/03_pruebas_integridad_avanzada.sql
if ($LASTEXITCODE -ne 0) { throw "Error inesperado en las pruebas de integridad avanzada." }
```

El primer bloque de la batería cuenta las tablas base de `public`, sus columnas, las filas de las 26 relaciones y los triggers no internos de los ocho nombres previstos. Exige, respectivamente, `26`, `135`, `81` y `94`. Después ejecuta `public.uh_validar_integridad()` sobre la semilla. Para repetir la batería sobre esa instalación se conserva la semilla y se ejecuta únicamente el segundo comando.

### 10.2. Casos secuenciales y criterios de aceptación

La preparación, las sentencias y las consultas de control de cada caso se encuentran en [`03_pruebas_integridad_avanzada.sql`](03_pruebas_integridad_avanzada.sql), en orden de ejecución. Para los rechazos de integridad, cada llamada a `pg_temp.esperar_rechazo` identifica el caso, la operación y la restricción esperada. La función ejecuta la operación y fuerza las restricciones diferidas mediante `SET CONSTRAINTS ALL IMMEDIATE`. Solo acepta `SQLSTATE 23514` con el `CONSTRAINT_NAME` previsto. Una aceptación indebida, otro código o una restricción distinta interrumpe la batería. La subtransacción revierte los efectos de la operación rechazada.

| Condición examinada | Preparación y acción | Resultado esperado | Comprobación observada dentro de la transacción |
|---|---|---|---|
| Contacto, contexto de admisión y vigencia | Eliminar el último contacto de un estudiante admitido, utilizar una sede existente no habilitada para la carrera o asignar una versión fuera de vigencia. Intentar modificar una admisión con trayectoria. | Rechazo por la condición específica infringida. | Coincidieron, según el caso, `uh_estudiante_contacto`, `uh_admision_carrera_sede`, `uh_admision_vigencia_inicial` y `uh_admision_historia`. |
| Traslados, reconocimientos y currículo por versión — RN-03, RN-04 y RN-05 | Preparar dos traslados de la admisión 8. Consultar su plan antes del primero y en el instante exacto de ambos cambios. Intentar alterar el origen histórico, utilizar una versión incompatible o modificar reglas ya utilizadas. | La versión destino rige desde el traslado. El reconocimiento y las decisiones anteriores conservan su contexto. | `uh_plan_aplicable` devolvió `101`, `102` y `103` en los tres instantes. Los rechazos distinguieron contexto, secuencia e inmutabilidad. Se aceptó y leyó el cierre de vigencia de la versión 190 sin decisiones de matrícula. |
| Uso de espacio — RN-07 | Asignar un espacio de otra sede, introducir franjas superpuestas y ampliar un calendario hasta generar conflicto. Probar franjas contiguas y periodos que coinciden en fechas, pero sin el día semanal del bloque en su intersección. | Admitir los usos compatibles y rechazar la incompatibilidad de sede o la ocupación simultánea efectiva. | Se aceptaron los casos compatibles. Para la sede se obtuvo `uh_bloque_espacio_contexto`. Para el solapamiento, incluso entre periodos distintos con un día lectivo común, se obtuvo `uh_espacio_solapamiento`. |
| Oferta, cancelación e historia — RN-08 y RN-19 | Abrir los grupos 11 y 12, consultar la oferta antes y después de la apertura, cancelar el grupo 12 con solicitudes e intentar alterar el historial. Cancelar también un grupo cerrado que nunca se abrió. | Registrar los cambios reales, conservar las solicitudes al cancelar y distinguir una cancelación de una apertura. | Se comprobaron dos aperturas. La cancelación del grupo 12 conservó seis solicitudes y un evento con estado `cancelada` y responsable 1. En el grupo 13 se comprobó la cancelación desde `cerrada` y la ausencia de apertura. |
| Ventana, admisión y estado — RN-09 y RN-11 | Intentar matricular desde una admisión inactiva. Registrar la decisión rechazada 9304 con motivo. Ejecutar el caso 3002 en el extremo final y después en el inicial de la ventana. Insertar dos decisiones rechazadas en una sentencia. | La matrícula requiere admisión activa y ventana `[inicio, fin)`. La decisión rechazada conserva su razón. Cada fila del lote genera su transición. | Se rechazó la matrícula desde la admisión inactiva y se leyó el motivo de 9304 en `historial_solicitud`. El final del intervalo fue rechazado y el inicio aceptado. Se contaron dos transiciones para 9390 y 9391. |
| Ocupación, horario y duplicidad — RN-10 y RN-16 | Ocupar las dos plazas del grupo 12, intentar una tercera matrícula y reducir el cupo por debajo de lo ocupado. Intentar matricular al mismo estudiante desde otra admisión y adjudicarle un grupo con choque horario. Repetir los conflictos sobre instantes anteriores a un retiro. | Mantener capacidad, compatibilidad horaria y una sola matrícula activa por estudiante, curso y periodo, incluidos los instantes históricos examinados. | Se contaron dos matrículas en el grupo 12. Coincidieron los diagnósticos de cupo, duplicidad y horario. Las verificaciones históricas detectaron conflictos que el estado posterior al retiro habría ocultado. |
| Requisito, correquisito y excepción individual — RN-05, RN-06, RN-15 y RN-18 | Evaluar reconocimiento, aprobación previa y correquisito matriculado en el periodo. Variar el instante de adjudicación o anulación del correquisito. Añadir una excepción para el requisito concreto y probar una autorización tardía y otra de distinto curso. | Admitir cada vía válida en el instante de la decisión. Rechazar el requisito insatisfecho y la excepción incompatible o posterior. | Se contaron cuatro matrículas entre 5017, 5018, 6018 y 6020. La operación compuesta con adjudicación simultánea conservó ambas matrículas 6122 y 6120 antes de revertirse. Coincidieron `uh_matricula_requisitos`, `uh_excepcion_contexto` y `uh_excepcion_temporal` en sus casos respectivos. |
| Orden y promoción de espera — RN-12 | Preparar 2001 y 2002 con igual instante de entrada. Intentar repetir o reescribir posición, omitir al primer elegible y utilizar una evaluación anterior. Liberar cupo y ensayar ambas ramas de promoción mediante un punto de retorno. | Conservar el orden de entrada y el desempate por `id_solicitud`. Una omisión requiere reevaluación pertinente al instante de promoción. | En la primera rama se comprobó 2001 `matriculada`. Al volver al punto de retorno, inactivar su admisión y registrar la evaluación motivada en el instante de promoción, se comprobó 2001 `en_espera` y 2002 `matriculada`. |
| Promoción posterior a traslado — RN-03, RN-12 y RN-15 | Poner 9900 en espera con plan 102, trasladar la admisión al plan 105 y ampliar el cupo. Intentar la promoción antes y después de autorizar la excepción del nuevo plan. | Conservar la versión inicial y evaluar el requisito del plan aplicable en la transición. | La primera promoción se rechazó por `uh_matricula_requisitos`. Después se comprobaron estado `matriculada`, orden 1, versión inicial 102 y plan aplicable 105. Se revirtió el escenario al punto de retorno. |
| Retiro y cambio de grupo — RN-13 y RN-14 | Intentar retiro fuera de plazo, cambio a otro curso y cambio con un minuto de diferencia entre retiro y adjudicación. Ejecutar el cambio de 1001 a 4002 con antecedente y el mismo instante efectivo. Retirar posteriormente el destino. | Rechazar el retiro fuera de plazo y el cambio incompatible. Admitir la operación conjunta válida y conservar el vínculo histórico. | El retiro fuera de plazo produjo `uh_historial_evento_temporal`. Los cambios incompatibles produjeron `uh_solicitud_antecedente`. Se validó el cambio con origen 1001 y destino 4002 y se leyeron ambos estados `retirada` después del retiro posterior del destino. |
| Resultado académico y correcciones — RN-17 y RN-20 | Asignar una primera nota, intentar calificar antes del cierre lectivo, corregir sin motivo y luego con autorización. Pasar por `NULL` y volver a asignar valores. | Distinguir primera asignación de corrección, conservar los valores anterior y nuevo y respetar el cierre lectivo. | Para 5052 se comprobó ausencia de corrección inicial. Para 5051 se encontró el cambio `A/aprobado → B/reprobado` con autorizador 1. La rama que pasó por `NULL` contó tres correcciones antes de revertirse. Se rechazaron las notas anticipadas y la corrección sin motivo. |
| Protección de antecedentes y aislamiento | Intentar insertar transiciones ficticias, modificar o eliminar eventos y truncar tablas protegidas directamente o con `CASCADE`. Después de la transacción principal, intentar un `UPDATE ... WHERE FALSE` sobre `grupo` bajo `REPEATABLE READ` y `SERIALIZABLE`. | Rechazar la vía de escritura específica. Para los dos aislamientos con instantánea fija, rechazar la sentencia aun cuando no seleccione filas. | Se comprobaron los diagnósticos individuales de protección. Las dos transacciones de aislamiento capturaron `25001` y terminaron con `ROLLBACK`. |

El 27 de noviembre se comprobaron **97 rechazos de integridad** mediante `pg_temp.esperar_rechazo`. Los dos rechazos por aislamiento se comprobaron aparte. En el caso de revocación de una aprobación utilizada como antecedente, el script compara el reloj del servidor con `2026-12-22 11:00:00-06`. En la ejecución documentada se recorrió la rama anterior a ese instante y se obtuvo `uh_matricula_requisitos`. Una ejecución posterior al umbral recorre la comprobación de conservación del resultado histórico prevista en el mismo archivo.

### 10.3. Estado posterior de la batería secuencial

Los valores de los escenarios anteriores se consultan antes de su reversión. Una vez finalizado `psql`, una conexión independiente a `universidad_horizonte_prueba_01` comprobó el inventario estructural y las diez cardinalidades de la sección 9.5. La siguiente consulta reproduce la lectura de esos campos en el orden del resultado:

```sql
SELECT
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') AS tablas,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'public') AS atributos,
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

**Esperado y observado:** `26|135|4|5|5|1|1|0|0|0|0|0`. Las cantidades persistidas examinadas coincidieron con la preparación. El total de 81 filas corresponde al control de entrada sobre las 26 relaciones.

### 10.4. Preparación de los escenarios concurrentes

Los casos A a D se ejecutaron en ese orden sobre `universidad_horizonte_concurrencia_01`, una base nueva independiente de la secuencial. Se instalaron, en orden, `01_esquema_base.sql`, `02_datos_base.sql`, `03_esquema_relaciones.sql`, `04_datos_relaciones.sql` y `05_integridad_avanzada.sql`. El inventario coincidió con el de la sección 10.3, más 21 funciones y 94 triggers. Antes de preparar los casos se comprobaron cero grupos con ID entre 990 y 995, cero solicitudes y 94 triggers de usuario con nombre `uh_%`.

Para repetir los cuatro conflictos se utiliza otra base nueva con esa misma instalación. La preparación y las escrituras de la sesión A se confirman. Por tanto, los cuatro casos se recorren una sola vez sobre cada preparación. Desde `final-project/grupo-03/`, el siguiente comando abre una conexión interactiva a la base utilizada en el ensayo:

```powershell
docker compose exec db psql -X -U bd1 -d universidad_horizonte_concurrencia_01
```

En una conexión se prepara y confirma el siguiente conjunto. El motivo de preparación es un texto descriptivo para la auditoría de apertura.

```sql
BEGIN;
SET LOCAL universidad.autorizador = '1';
SET LOCAL universidad.motivo = 'Preparacion de escenarios concurrentes';

INSERT INTO estudiante VALUES
    ('UH-ALU3','Estudiante','Tres',NULL),
    ('UH-ALU7','Estudiante','Siete',NULL);

INSERT INTO contacto_estudiante VALUES
    (603,'UH-ALU3','correo','alu3@example.test',TRUE),
    (607,'UH-ALU7','correo','alu7@example.test',TRUE);

INSERT INTO admision VALUES
    (4,'UH-ALU3',1,102,DATE '2026-02-01','regular',TRUE),
    (8,'UH-ALU7',1,102,DATE '2026-02-01','regular',TRUE),
    (9,'UH-ALU7',1,102,DATE '2026-02-01','regular',TRUE);

INSERT INTO grupo VALUES
    (990,90,'UH-PROG1',1,1,1,'virtual','cerrada'),
    (991,91,'UH-PROG1',1,1,1,'virtual','cerrada'),
    (992,92,'UH-PROG1',1,1,1,'presencial','cerrada'),
    (993,93,'UH-PROG1',1,1,1,'presencial','cerrada'),
    (994,94,'UH-PROG1',1,1,2,'virtual','cerrada'),
    (995,95,'UH-PROG1',1,1,2,'virtual','cerrada');

INSERT INTO bloque_horario VALUES
    (990,990,5,TIME '08:00',TIME '09:00',FALSE,NULL),
    (991,991,5,TIME '10:00',TIME '11:00',FALSE,NULL),
    (994,994,5,TIME '08:00',TIME '09:00',FALSE,NULL),
    (995,995,5,TIME '09:00',TIME '10:00',FALSE,NULL);

INSERT INTO grupo_docente VALUES
    (990,1,'responsable'), (991,1,'responsable'),
    (994,1,'responsable'), (995,2,'responsable');

SET LOCAL universidad.instante_efectivo = '2026-06-30 12:00-06';
UPDATE grupo SET estado_oferta = 'abierta'
WHERE id_grupo IN (990,991,994,995);
SET LOCAL universidad.instante_efectivo = '';
COMMIT;

SELECT COUNT(*) FROM grupo WHERE id_grupo BETWEEN 990 AND 995;
```

**Esperado y observado:** seis grupos auxiliares. Los grupos 990 y 991 tienen una plaza cada uno. Los grupos presenciales 992 y 993 permiten probar la asignación del mismo espacio. Los grupos 994 y 995 tienen dos plazas y franjas consecutivas. Las admisiones 8 y 9 pertenecen a `UH-ALU7`, por lo que el último conflicto aísla la duplicidad de curso del mismo estudiante.

### 10.5. Intercalación, diagnósticos y comprobaciones concurrentes

Se utilizaron dos sesiones `psql` independientes dirigidas desde PowerShell y una conexión observadora. En cada caso, A abrió la transacción y ejecutó su escritura. El controlador mantuvo A abierta con `SELECT pg_sleep(20)` e inició B cuando encontró a A activa en esa sentencia. B abrió otra transacción e intentó su escritura. Antes del `COMMIT` de A, el observador comprobó que el PID de A figuraba entre los bloqueadores de B y que B esperaba por un bloqueo.

Para reproducir la intercalación manualmente, se abren tres conexiones a la misma base. Los siguientes nombres de sesión son los usados en las instrucciones de reproducción. En A se ejecuta `SET application_name = 'uh_prueba_a';` y en B, `SET application_name = 'uh_prueba_b';`. En ambos clientes se activa `\set VERBOSITY verbose` para identificar el código y la restricción del error.

1. En A, ejecutar `BEGIN ISOLATION LEVEL READ COMMITTED;` y la escritura A del caso. Mantener abierta la transacción.
2. En B, ejecutar `BEGIN ISOLATION LEVEL READ COMMITTED;` y la escritura B. Mientras B espera, efectuar la consulta de bloqueo desde el observador.
3. Tras obtener `t`, ejecutar `COMMIT;` en A. En B, cuando termine la escritura, ejecutar `COMMIT;` si la transacción sigue abierta y válida. La validación diferida puede emitir el rechazo al intentar confirmar. Si el error ya se produjo durante la escritura y la sesión interactiva quedó en transacción abortada, ejecutar `ROLLBACK;`.
4. Desde el observador, fuera de las transacciones A y B, ejecutar la consulta final del caso. Continuar con el siguiente caso una vez comprobados el diagnóstico y el estado persistido.

Estas son las consultas de sincronización y bloqueo utilizadas, con los nombres de aplicación parametrizados para la reproducción. La primera corresponde a la pausa de la ejecución automatizada. En la ejecución manual, A permanece abierta en el paso 1 hasta que el observador confirme el bloqueo.

```sql
\set appA uh_prueba_a
\set appB uh_prueba_b

SELECT COUNT(*) FROM pg_stat_activity
WHERE application_name = :'appA'
  AND state = 'active'
  AND query LIKE '%pg_sleep(20)%';

SELECT EXISTS (
    SELECT 1 FROM pg_stat_activity a
    JOIN pg_stat_activity b ON a.pid = ANY(pg_blocking_pids(b.pid))
    WHERE a.application_name = :'appA'
      AND b.application_name = :'appB'
      AND b.wait_event_type = 'Lock'
);
```

**A. Último cupo — RN-10.** Dos admisiones distintas compiten por la única plaza del grupo 990. Se espera que A confirme la solicitud 9901 y B reciba `23514`, `uh_grupo_cupo`, al intentar confirmar la segunda matrícula.

```sql
-- Sesión A
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
VALUES (9901,3,990,102,'2026-07-04 08:00-06','matriculada');

-- Sesión B
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
VALUES (9902,4,990,102,'2026-07-04 08:01-06','matriculada');

-- Observador, después del cierre de ambas sesiones y antes del caso B
SELECT
    (SELECT COUNT(*) FROM grupo WHERE id_grupo BETWEEN 990 AND 995),
    (SELECT COUNT(*) FROM solicitud_matricula
     WHERE id_solicitud=9901 AND estado='matriculada'),
    (SELECT COUNT(*) FROM solicitud_matricula WHERE id_solicitud=9902),
    (SELECT capacidad FROM grupo WHERE id_grupo=990),
    (SELECT COUNT(*) FROM bloque_horario WHERE id_bloque IN (992,993)),
    (SELECT COUNT(*) FROM solicitud_matricula
     WHERE id_solicitud IN (9911,9941,9951));
```

**Observado:** bloqueo de B por A, `COMMIT` de A, rechazo de B por la restricción esperada y estado `6|1|0|1|0|0`. Persistió 9901, quedó ausente 9902 y la capacidad permaneció en 1. Los dos últimos ceros corresponden al estado anterior a los casos siguientes.

**B. Solapamiento de espacio — RN-07.** Los grupos 992 y 993 intentan utilizar el espacio 1 el mismo día en franjas que se superponen entre las 15:30 y las 16:00. Se espera que solo persista el bloque de A y que B reciba `23514`, `uh_espacio_solapamiento`.

```sql
-- Sesión A
INSERT INTO bloque_horario VALUES
    (992,992,5,TIME '15:00',TIME '16:00',TRUE,1);

-- Sesión B
INSERT INTO bloque_horario VALUES
    (993,993,5,TIME '15:30',TIME '16:30',TRUE,1);

-- Observador
SELECT COUNT(*)::text || '|' || COUNT(*) FILTER (WHERE id_grupo=992)::text
FROM bloque_horario WHERE id_bloque IN (992,993);
```

**Observado:** bloqueo, confirmación de A y rechazo de B por la restricción esperada. El resultado `1|1` indica un bloque entre los dos examinados, perteneciente al grupo 992.

**C. Reducción de capacidad durante una matrícula — RN-10.** A ocupa la única plaza del grupo 991. B intenta reducir a cero su capacidad con autorizador y motivo. Se espera conservar la matrícula y rechazar la reducción mediante `23514`, `uh_grupo_cupo`.

```sql
-- Sesión A
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
VALUES (9911,4,991,102,'2026-07-04 11:00-06','matriculada');

-- Sesión B
SET LOCAL universidad.autorizador='1';
SET LOCAL universidad.motivo='Reduccion concurrente de cupo';
UPDATE grupo SET capacidad=0 WHERE id_grupo=991;

-- Observador
SELECT capacidad::text || '|' ||
       (SELECT COUNT(*) FROM solicitud_matricula
        WHERE id_grupo=991 AND estado='matriculada')::text
FROM grupo WHERE id_grupo=991;
```

**Observado:** bloqueo, confirmación de A y rechazo de B por la restricción esperada. El resultado `1|1` indica capacidad 1 y una solicitud matriculada en el grupo 991.

**D. Duplicidad entre admisiones — RN-16.** Las admisiones 8 y 9 del mismo estudiante solicitan dos grupos de `UH-PROG1` en el periodo 1. Ambos grupos disponen de cupo y sus horarios son contiguos. Se espera que solo persista la primera matrícula y que B reciba `23514`, `uh_matricula_duplicada`.

```sql
-- Sesión A
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
VALUES (9941,8,994,102,'2026-07-04 08:00-06','matriculada');

-- Sesión B
INSERT INTO solicitud_matricula
    (id_solicitud,id_admision,id_grupo,id_version_plan_evaluada,fecha_solicitud,estado)
VALUES (9951,9,995,102,'2026-07-04 08:01-06','matriculada');

-- Observador
SELECT COUNT(*)::text || '|' || COALESCE(MIN(id_solicitud)::text,'')
FROM solicitud_matricula WHERE id_solicitud IN (9941,9951);
```

**Observado:** bloqueo, confirmación de A y rechazo de B por la restricción esperada. El resultado `1|9941` identifica una única solicitud persistida entre las dos examinadas.

### 10.6. Conclusión

La batería secuencial verificó los estados temporales y los diagnósticos específicos de los casos de integridad avanzada. La lectura independiente posterior confirmó los recuentos examinados después del `ROLLBACK`. En las cuatro intercalaciones concurrentes se observó la espera de B por A y se comprobó el estado confirmado después del rechazo de B: una matrícula para el último cupo, un único uso del espacio en conflicto, una capacidad compatible con la ocupación y una sola matrícula del estudiante en el mismo curso y periodo.