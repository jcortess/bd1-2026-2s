# Resultados de ejecución y validación — Universidad Horizonte

## 1. Identificación

| Elemento | Valor |
|---|---|
| Curso | IC-4301 Bases de Datos I |
| Proyecto | Universidad Horizonte |
| Grupo | 03 |
| Fechas de ejecución | 25, 26 y 27 de noviembre de 2026 |
| Motor | PostgreSQL 17.11 |
| Imagen | `postgres:17.11-bookworm` |
| Entorno | Docker Compose |
| Servicio | `db` |
| Base de trabajo secuencial | `universidad_horizonte_prueba_01` |
| Base de pruebas concurrentes | `universidad_horizonte_concurrencia_01` |
| Usuario PostgreSQL | `bd1` |
| Alcance verificado | Estructura y semilla del modelo de 26 relaciones y 135 atributos, restricciones declarativas, integridad contextual, temporal e histórica, y cuatro conflictos concurrentes de capacidad, espacio y duplicidad |

En la base secuencial se ejecutaron los siguientes archivos, en el orden indicado:

1. [`sql/01_esquema_base.sql`](../sql/01_esquema_base.sql): creación de relaciones y restricciones.
2. [`sql/02_datos_base.sql`](../sql/02_datos_base.sql): carga de datos ficticios.
3. [`pruebas/01_pruebas_base.sql`](../pruebas/01_pruebas_base.sql): comprobaciones de estructura, integridad y comportamiento.
4. [`sql/03_esquema_relaciones.sql`](../sql/03_esquema_relaciones.sql): creación de las diez relaciones adicionales y sus restricciones.
5. [`sql/04_datos_relaciones.sql`](../sql/04_datos_relaciones.sql): carga complementaria de datos ficticios.
6. [`pruebas/02_pruebas_relaciones.sql`](../pruebas/02_pruebas_relaciones.sql): comprobaciones de estructura e integridad declarativa de las relaciones adicionales.
7. [`sql/05_integridad_avanzada.sql`](../sql/05_integridad_avanzada.sql): instalación y validación de los controles avanzados sobre la semilla.
8. [`pruebas/03_pruebas_integridad_avanzada.sql`](../pruebas/03_pruebas_integridad_avanzada.sql): comprobaciones secuenciales de integridad avanzada y aislamiento.

Se utilizó `psql` con `-X` y `ON_ERROR_STOP=1`. En la base independiente de concurrencia se ejecutaron los cinco archivos de `sql/` en orden numérico. Los cuatro conflictos se ejecutaron después mediante conexiones `psql` separadas.

## 2. Preparación inicial de las estructuras base

Se verificó la configuración de Docker Compose y el estado del servicio PostgreSQL.

| Comprobación | Resultado esperado | Resultado observado |
|---|---|---|
| `docker compose config -q` | Configuración válida | Sin errores |
| `docker compose up -d --wait` | Servicio disponible | Contenedor iniciado |
| `docker compose ps` | Servicio `db` saludable | `healthy` |
| Conexión PostgreSQL | Base `postgres`, usuario `bd1` | Correcta |
| Versión del servidor | PostgreSQL 17.11 | `17.11 (Debian 17.11-1.pgdg12+2)` |

Para verificar la versión se ejecutó:

```sql
SELECT
    current_database(),
    current_user,
    current_setting('server_version');
```

La instalación se realizó sobre la base de trabajo existente `universidad_horizonte_prueba_01`, después de confirmar que estaba vacía.

```sql
SELECT current_database() AS base_actual;

SELECT COUNT(*) AS tablas_usuario
FROM pg_tables
WHERE schemaname = 'public';
```

**Resultado observado:**

| Campo | Valor |
|---|---|
| `base_actual` | `universidad_horizonte_prueba_01` |
| `tablas_usuario` | 0 |

**Conclusión:** se verificó que la base destinada a la instalación no contenía tablas de usuario. No fue necesario eliminar objetos ni crear una base adicional.

## 3. Instalación del esquema base

Se ejecutó:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/01_esquema_base.sql
```

**Resultado esperado:** creación de las 16 tablas, sus restricciones y los objetos auxiliares necesarios, sin errores y con confirmación de la transacción.

**Resultado observado:**

| Mensaje PostgreSQL | Cantidad |
|---|---:|
| `CREATE EXTENSION` | 1 |
| `CREATE TABLE` | 16 |
| `CREATE INDEX` | 1 |
| `COMMIT` | 1 |

La ejecución inició con `BEGIN`, aplicó la configuración de sesión mediante `SET` y finalizó con `COMMIT`. No se observaron mensajes de error.

Posteriormente se ejecutó:

```sql
SELECT COUNT(*) AS tablas_creadas
FROM pg_tables
WHERE schemaname = 'public';
```

| Comprobación | Esperado | Observado |
|---|---:|---:|
| Tablas de usuario en `public` | 16 | 16 |

**Conclusión:** se instalaron las 16 tablas previstas. La correspondencia de columnas, tipos, claves y restricciones se examinó mediante las comprobaciones posteriores.

## 4. Carga inicial de datos ficticios

Se ejecutó:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/02_datos_base.sql
```

**Resultado esperado:** carga correcta de la semilla inicial, sin infracciones de integridad y con confirmación de la transacción.

**Resultado observado:** se registraron 16 operaciones `INSERT`, correspondientes a 64 filas insertadas. La ejecución finalizó con `COMMIT`, sin errores.

Se comprobaron directamente las cardinalidades de seis relaciones curriculares:

| Relación | Esperado | Observado |
|---|---:|---:|
| `CARRERA` | 2 | 2 |
| `CURSO` | 8 | 8 |
| `ESCUELA` | 2 | 2 |
| `PARTICIPACION_PLAN` | 16 | 16 |
| `REQUISITO_CURSO` | 10 | 10 |
| `VERSION_PLAN_ESTUDIOS` | 3 | 3 |

El script de pruebas verificó posteriormente las cardinalidades de las 16 relaciones y las siguientes condiciones del conjunto inicial:

- La versión de plan `102` contiene 22 créditos obligatorios.
- El curso `UH-BDAT1` tiene tres requisitos declarados en la versión `102`.
- Los diez registros iniciales de `REQUISITO_CURSO` poseen identificador alternativo.
- Existen dos ventanas del tipo `matricula` y ventanas de tipos diferentes cuyos intervalos se superponen.
- Las admisiones iniciales corresponden a combinaciones carrera–sede habilitadas.

La semilla contiene dos ventanas consecutivas de matrícula, con el fin de la primera igual al inicio de la segunda. Su inserción fue aceptada por PostgreSQL; el bloque de comprobación de datos no realizó una comparación independiente de esa igualdad.

**Conclusión:** la semilla fue cargada y sus cardinalidades y condiciones examinadas coincidieron con las expectativas. Las fechas empleadas para adaptar las vigencias de Lab03 son datos ficticios, no fechas institucionales históricas verificadas.

## 5. Pruebas de integridad de las estructuras base

Se ejecutó:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/01_pruebas_base.sql
```

**Precondición:** esquema y semilla inicial instalados una única vez, sin datos residuales de pruebas anteriores.

**Resultado esperado:** comprobación satisfactoria de la estructura, aceptación de operaciones válidas, rechazo por causa específica de operaciones inválidas y reversión de las modificaciones temporales.

**Resultado observado:** todos los bloques `DO` finalizaron correctamente; las inserciones y la actualización positivas devolvieron los recuentos esperados; la ejecución terminó mediante `ROLLBACK`, sin errores inesperados.

### 5.1. Comprobación estructural

Se comparó el catálogo PostgreSQL con las definiciones esperadas de tablas, columnas, tipos, nulabilidad, claves y restricciones.

| Elemento | Esperado | Observado |
|---|---:|---|
| Relaciones | 16 | 16 |
| Atributos | 57 | 57 |
| Claves primarias | 16 | 16 |
| Claves foráneas | 15 | 15 |
| Restricciones `UNIQUE` | 4 | 4 |
| Restricciones `CHECK` | 25 | 25 |
| Índice único parcial | 1 | Confirmado |
| Exclusión GiST | 1 | Confirmada |
| Extensión `btree_gist` | Instalada | Confirmada |
| Identidad de `REQUISITO_CURSO.id_requisito` | `GENERATED BY DEFAULT` | Confirmada |

La comprobación no se limitó a contar claves: se compararon los nombres, columnas y destinos de las restricciones PK, FK y UNIQUE. También se verificó que las claves foráneas utilizaran acciones referenciales `NO ACTION`.

El bloque finalizó sin generar excepciones.

**Conclusión:** las definiciones examinadas coincidieron con las especificadas en las pruebas del catálogo.

### 5.2. Casos positivos y de frontera

Se ejecutaron ocho operaciones `INSERT` y una operación `UPDATE`.

| Operación | Condición comprobada | Resultado observado |
|---|---|---|
| Insertar estudiante | Apellido secundario opcional | `INSERT 0 1` |
| Insertar curso | Cantidad de créditos igual a cero | `INSERT 0 1` |
| Insertar contacto | Contacto adicional no principal del mismo tipo | `INSERT 0 1` |
| Insertar participación | Periodo recomendado nulo | `INSERT 0 1` |
| Actualizar espacio | Capacidad válida de 31 | `UPDATE 1` |
| Insertar versión del plan | Vigencia sin fecha final | `INSERT 0 1` |
| Insertar periodo académico | Fecha inicial igual a fecha final | `INSERT 0 1` |
| Insertar admisión | Segunda admisión inactiva para un estudiante existente | `INSERT 0 1` |
| Insertar requisito | Regla curricular con cursos referenciados válidamente | `INSERT 0 1` |

Después de las operaciones se ejecutó un bloque PL/pgSQL que consultó las filas insertadas y el valor actualizado.

**Conclusión:** se aceptaron las operaciones válidas y se confirmaron sus valores dentro de la transacción de pruebas.

### 5.3. Casos negativos

Se ejecutaron 53 casos negativos destinados a verificar el rechazo de operaciones inválidas mediante restricciones de identidad, referencia, unicidad, dominio, temporalidad y acciones de modificación o eliminación.

Cada caso definió previamente la sentencia que debía rechazarse, el `SQLSTATE` esperado y el nombre de la restricción responsable. El bloque PL/pgSQL capturó el error producido y comparó ambos valores con los esperados.

Algunos casos representativos fueron:

| Condición | SQLSTATE esperado | Restricción esperada |
|---|---|---|
| Duplicación de clave primaria de `ESCUELA` | `23505` | `pk_escuela` |
| Referencia a una escuela inexistente desde `CURSO` | `23503` | `fk_curso_escuela` |
| Créditos negativos | `23514` | `ck_curso_creditos` |
| Duplicación de contacto principal por estudiante y tipo | `23505` | `uq_contacto_principal_tipo` |
| Autorrequisito curricular | `23514` | `ck_requisito_no_autorrequisito` |
| Superposición prohibida de ventanas | `23P01` | `ex_ventana_tipo_periodo_no_solapado` |
| Eliminación de un periodo referenciado | `23503` | `fk_ventana_periodo` |
| Actualización inválida de capacidad | `23514` | `ck_espacio_capacidad` |

Estos casos se encuentran definidos y son reproducibles en `pruebas/01_pruebas_base.sql`.

| Comprobación | Esperado | Observado |
|---|---:|---:|
| Rechazos por la causa definida | 53 | 53 |
| Excepciones inesperadas notificadas | 0 | 0 |

Los errores previstos se manejaron mediante bloques `EXCEPTION`, con reversión de cada operación inválida y continuación de la ejecución. El guion habría interrumpido las pruebas ante una aceptación indebida o una discrepancia de código o restricción.

**Conclusión:** los 53 casos fueron rechazados por las causas especificadas en el guion. La consola mostró el resultado agregado de esas comparaciones, no un listado individual de los 53 errores.

### 5.4. Comprobaciones adicionales de obligatoriedad

Se ejecutaron cinco operaciones con valores `NULL` prohibidos.

| Relación | Columna | Resultado esperado |
|---|---|---|
| `ESTUDIANTE` | `nombre` | Rechazo `23502` |
| `ADMISION` | `activa` | Rechazo `23502` |
| `VENTANA_PERIODO` | `fin` | Rechazo `23502` |
| `REQUISITO_CURSO` | `tipo_requisito` | Rechazo `23502` |
| `VERSION_PLAN_ESTUDIOS` | `inicio_vigencia` | Rechazo `23502` |

Se comprobó el código `23502` y el nombre de la columna responsable en cada caso.

**Conclusión:** se confirmó el rechazo de los cinco valores nulos prohibidos, con identificación de la columna correspondiente.

### 5.5. Comprobación posterior a los rechazos

Dentro de la transacción se verificó la conservación de registros de referencia después de los casos negativos.

Las comprobaciones incluyeron:

- Existencia del periodo académico original.
- Conservación de cuatro ventanas asociadas al periodo.
- Recuento de once requisitos curriculares, incluidos los diez iniciales y el caso positivo temporal.
- Conservación de los tres contactos correspondientes al estudiante utilizado en las pruebas, incluido el contacto temporal.
- Existencia de la escuela de referencia.

**Conclusión:** no se detectaron modificaciones indebidas en los registros examinados después de los rechazos.

### 5.6. Cierre de las pruebas

La ejecución finalizó con el mensaje:

```text
ROLLBACK
```

La reversión retiró las inserciones y la actualización temporales realizadas por el archivo de pruebas. Las transacciones de creación del esquema y carga de datos habían finalizado previamente mediante `COMMIT`.

**Conclusión:** el guion de pruebas cerró su transacción y no confirmó los cambios temporales.

## 6. Comprobación posterior de las estructuras base

Después de ejecutar `01_pruebas_base.sql`, y antes de incorporar las diez relaciones adicionales, se abrió una nueva conexión PostgreSQL y se consultaron las cardinalidades persistidas de las 16 relaciones base.

Se ejecutó la siguiente consulta:

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
SELECT relacion, filas
FROM conteos
UNION ALL
SELECT 'TOTAL', SUM(filas)
FROM conteos
ORDER BY relacion;
```

**Resultado esperado:** conservación de las 16 cardinalidades iniciales, con un total de 64 registros.

**Resultado observado:**

| Relación | Registros persistidos |
|---|---:|
| `ADMISION` | 2 |
| `CARRERA` | 2 |
| `CARRERA_SEDE` | 3 |
| `CONTACTO_ESTUDIANTE` | 3 |
| `CURSO` | 8 |
| `DOCENTE` | 2 |
| `ESCUELA` | 2 |
| `ESPACIO` | 2 |
| `ESTUDIANTE` | 2 |
| `PARTICIPACION_PLAN` | 16 |
| `PERIODO_ACADEMICO` | 1 |
| `PERSONA_AUTORIZADORA` | 2 |
| `REQUISITO_CURSO` | 10 |
| `SEDE` | 2 |
| `VENTANA_PERIODO` | 4 |
| `VERSION_PLAN_ESTUDIOS` | 3 |
| **Total** | **64** |

La consulta devolvió 17 filas —16 relaciones y una fila total— y finalizó sin errores.

**Conclusión:** las cardinalidades persistidas coincidieron con las de la semilla anterior a las pruebas. Esta comprobación acredita la conservación de los recuentos desde una conexión independiente; las comprobaciones de contenido y ausencia de modificaciones indebidas se realizaron dentro de la transacción mediante los bloques del archivo de pruebas.

## 7. Resultado de la validación de las estructuras base

Se completó satisfactoriamente la instalación y validación de las 16 relaciones base del modelo físico de Universidad Horizonte en PostgreSQL 17.11.

Se verificaron las 57 columnas previstas, la composición de las claves y referencias, las restricciones declarativas examinadas, la carga de 64 registros ficticios y el comportamiento de los casos positivos, negativos y de frontera incluidos en el guion.

Los 53 casos negativos y las cinco comprobaciones adicionales de obligatoriedad produjeron los rechazos esperados. Las verificaciones posteriores no detectaron efectos indebidos en los registros examinados. El archivo de pruebas finalizó mediante `ROLLBACK` y la consulta independiente confirmó las cardinalidades iniciales.

**Resultado de la validación: satisfactorio para las estructuras, operaciones y restricciones efectivamente comprobadas.**

## 8. Instalación y validación de las relaciones adicionales

**Fecha de ejecución:** 26 de noviembre de 2026.

**Entorno:** PostgreSQL 17.11, Docker Compose, servicio `db`, usuario `bd1` y base `universidad_horizonte_prueba_01`.

**Archivos ejecutados:**

1. [`sql/03_esquema_relaciones.sql`](../sql/03_esquema_relaciones.sql)
2. [`sql/04_datos_relaciones.sql`](../sql/04_datos_relaciones.sql)
3. [`pruebas/02_pruebas_relaciones.sql`](../pruebas/02_pruebas_relaciones.sql)

### 8.1. Instalación y carga

| Comprobación | Resultado esperado | Resultado observado |
|---|---|---|
| Estado previo | 16 relaciones y 57 atributos. | 16 relaciones y 57 atributos. |
| Esquema complementario | Crear diez relaciones y un índice único parcial, sin errores. | Diez mensajes `CREATE TABLE`, un `CREATE INDEX` y `COMMIT`. |
| Estructura completa | 26 relaciones y 135 atributos. | 26 relaciones y 135 atributos, confirmados mediante consulta independiente. |
| Datos complementarios | Insertar 17 registros ficticios y confirmar la transacción. | Seis operaciones `INSERT`, con cardinalidades 1, 4, 5, 5, 1 y 1; finalización con `COMMIT`. |

Los 17 registros corresponden a una admisión, cuatro grupos, cinco bloques horarios, cinco asignaciones docentes, un traslado de plan y un reconocimiento académico.

Una consulta posterior confirmó cuatro grupos, cinco bloques, cinco asignaciones docentes y ninguna solicitud de matrícula persistida.

### 8.2. Pruebas de integridad

Se ejecutó [`pruebas/02_pruebas_relaciones.sql`](../pruebas/02_pruebas_relaciones.sql) sobre el esquema completo. Los escenarios, precondiciones y criterios de aceptación se documentan en [`Pruebas.md`](../pruebas/Pruebas.md), sección 9.

| Comprobación | Resultado esperado | Resultado observado |
|---|---|---|
| Estructura | 26 tablas, 135 atributos y correspondencia de las 78 columnas adicionales. | Comprobación satisfactoria. |
| Datos iniciales | Cardinalidades y referencias de preparación válidas. | Comprobación satisfactoria. |
| Casos positivos y de frontera | Aceptación de operaciones válidas y conservación de los valores de control examinados. | Operaciones aceptadas y bloque de comprobación finalizado sin excepción. |
| Casos negativos | 102 rechazos con diagnóstico específico coincidente. | 102 casos conformes, verificados individualmente dentro del script. |
| Estado posterior a los rechazos | Sin modificaciones indebidas en las cantidades y valores examinados. | Comprobaciones satisfactorias. |
| Cierre transaccional | Reversión de las operaciones temporales. | `ROLLBACK`. |

Los 102 casos negativos incluyeron 13 infracciones de unicidad, 32 de referencia, 53 de restricciones `CHECK` y cuatro de obligatoriedad. La comprobación individual de los diagnósticos se realizó en PL/pgSQL; la consola presentó el resultado agregado.

### 8.3. Estado persistido

Después del `ROLLBACK`, una conexión PostgreSQL independiente confirmó los siguientes recuentos:

| Relación | Registros observados |
|---|---:|
| `grupo` | 4 |
| `bloque_horario` | 5 |
| `grupo_docente` | 5 |
| `traslado_plan` | 1 |
| `reconocimiento_academico` | 1 |
| `solicitud_matricula` | 0 |
| `historial_oferta` | 0 |
| `historial_solicitud` | 0 |
| `excepcion_requisito` | 0 |
| `historial_correccion_calificacion` | 0 |

Las cardinalidades coincidieron con la semilla complementaria. Los escenarios temporales no dejaron registros persistidos en las relaciones examinadas.

### 8.4. Conclusión

Se completó satisfactoriamente la instalación de las diez relaciones adicionales y su validación mediante pruebas de integridad declarativa.

**Resultado:** el esquema físico contiene 26 relaciones y 135 atributos. Los casos positivos, negativos y de frontera ejecutados cumplieron los criterios comprobados, y la consulta independiente confirmó la conservación de los recuentos iniciales después del `ROLLBACK`.

## 9. Instalación y validación de integridad avanzada

**Fecha de ejecución:** 27 de noviembre de 2026. Se utilizó PostgreSQL 17.11 con el servicio `db` de Docker Compose y el usuario `bd1`.

### 9.1. Instalación y versión de los archivos ejecutados

En `universidad_horizonte_prueba_01` se comprobaron 26 tablas, 135 atributos y cero solicitudes de matrícula antes de instalar los controles avanzados. Después de la instalación, el catálogo devolvió `21|94|t`: 21 funciones `uh_%`, 94 triggers no internos `uh_%` y presencia de `public.uh_validar_integridad()`.

| Archivo ejecutado | SHA-256 obtenido con `Get-FileHash` |
|---|---|
| `sql/05_integridad_avanzada.sql` | `AEA62EC289F03D3DC983C3A65047774967D6AE3F232E193DE14A6F75145FA648` |
| `pruebas/03_pruebas_integridad_avanzada.sql` | `7768BE981B62F4651CFA3CE3C4FE4B185386FBC10A0B4300CC31EF391DA5902E` |

### 9.2. Batería secuencial

La batería avanzada finalizó con código de salida `0`. El primer bloque comprobó las 26 tablas, sus 135 atributos, la suma de **81 filas** en las 26 relaciones y los 94 triggers previstos. La llamada a `public.uh_validar_integridad()` sobre los datos iniciales finalizó sin excepción.

| Comprobación | Resultado esperado | Resultado observado |
|---|---|---|
| Rechazos de integridad | `23514` y nombre de restricción específico para cada operación negativa. | Se completaron 97 comprobaciones individuales. Cada una comparó `CONSTRAINT_NAME` después de ejecutar la operación y, cuando correspondía, forzar la validación diferida. |
| Trayectoria y vigencia | Recuperar el plan aplicable antes de un traslado y desde el instante efectivo de cada cambio. | Para la admisión 8 se obtuvieron, en orden, los planes 101, 102 y 103. |
| Oferta y cancelación | Distinguir apertura y cancelación y conservar las solicitudes existentes. | Se comprobaron dos aperturas. Tras cancelar el grupo 12 permanecieron seis solicitudes y se encontró el evento de cancelación con responsable 1. |
| Adjudicación y antecedentes académicos | Conservar las matrículas válidas por las vías de satisfacción preparadas y rechazar el antecedente inválido en el instante de adjudicación. | Se contaron cuatro solicitudes matriculadas entre 5017, 5018, 6018 y 6020. Se verificaron ambas matrículas del caso compuesto 6122/6120. La revocación anterior a la adjudicación fue rechazada por `uh_matricula_requisitos`. |
| Espera y cambio de grupo | Respetar la prioridad, documentar la omisión de una persona no elegible y conservar el antecedente de un cambio válido. | Se comprobó la promoción de 2001 en la primera rama. En la segunda, 2001 seguía en espera y 2002 estaba matriculada. En el cambio 1001/4002 se validó el vínculo y se leyeron los dos estados después del retiro posterior del destino. |
| Corrección académica | Distinguir la primera carga de la corrección y conservar valores anterior y nuevo. | 5052 carecía de corrección después de su primera asignación. En 5051 se encontró `A/aprobado → B/reprobado`, con autorizador 1. La comprobación que pasó por `NULL` contó tres correcciones antes de revertirse. |
| Aislamiento de escritura | Rechazar la sentencia de escritura bajo `REPEATABLE READ` y `SERIALIZABLE`. | Se capturó `25001` en ambas pruebas. Cada transacción finalizó con `ROLLBACK`. |

Los estados de esta tabla se verificaron dentro de las transacciones o subtransacciones correspondientes. La transacción principal terminó con `ROLLBACK` antes de las dos comprobaciones de aislamiento. Las operaciones, criterios y consultas de control se identifican en la [sección 10 de Pruebas.md](../pruebas/Pruebas.md#10-pruebas-de-integridad-avanzada).

### 9.3. Estado persistido después de la batería

Una conexión independiente a `universidad_horizonte_prueba_01` devolvió:

```text
26|135|4|5|5|1|1|0|0|0|0|0
```

Las columnas corresponden, en orden, a tablas, atributos, grupos, bloques, asignaciones docentes, traslados, reconocimientos, solicitudes, historial de oferta, historial de solicitudes, excepciones y correcciones. Los doce valores coincidieron con los esperados. Permanecieron los cuatro grupos, cinco bloques, cinco asignaciones docentes, un traslado y un reconocimiento de la preparación. Las cinco relaciones operativas examinadas al final de la fila quedaron vacías.

### 9.4. Conflictos concurrentes

En `universidad_horizonte_concurrencia_01`, el inventario posterior a la instalación sobre base nueva fue `26|135|4|5|5|1|1|0|0|0|0|0|21|94`. Los doce primeros campos tienen el orden indicado en la sección 9.3. Los dos últimos corresponden a las funciones y los triggers de integridad avanzada. Se confirmó la preparación de seis grupos auxiliares.

En cada conflicto, la conexión observadora identificó por `application_name` a las dos sesiones. Mientras B esperaba con `wait_event_type = 'Lock'`, `pg_blocking_pids()` incluyó el PID de A entre sus bloqueadores. A confirmó su transacción. La transacción de B fue rechazada y sus cambios se revirtieron. Las consultas posteriores se ejecutaron desde una conexión independiente.

| Conflicto | Resultado esperado | Diagnóstico observado en B | Estado persistido observado |
|---|---|---|---|
| A. Último cupo del grupo 990 — RN-10 | Conservar la primera matrícula y mantener la capacidad en 1. | `23514`, `uh_grupo_cupo`. | `6\|1\|0\|1\|0\|0`: seis grupos auxiliares, 9901 matriculada, 9902 ausente y capacidad 1. Los bloques y solicitudes de control de los casos posteriores aún estaban ausentes. |
| B. Uso del espacio 1 en franjas superpuestas — RN-07 | Conservar un solo bloque entre 992 y 993. | `23514`, `uh_espacio_solapamiento`. | `1\|1`: un bloque entre los examinados, correspondiente al grupo 992. |
| C. Reducción de cupo del grupo 991 durante una matrícula — RN-10 | Conservar la capacidad y la matrícula confirmada. | `23514`, `uh_grupo_cupo`. | `1\|1`: capacidad 1 y una solicitud matriculada en el grupo 991. |
| D. Mismo curso y periodo desde dos admisiones del mismo estudiante — RN-16 | Conservar una sola matrícula entre 9941 y 9951. | `23514`, `uh_matricula_duplicada`. | `1\|9941`: una solicitud persistida entre las dos examinadas, identificada como 9941. |

### 9.5. Conclusión

La instalación avanzada validó la semilla del esquema completo. La batería secuencial obtuvo los diagnósticos previstos y comprobó los estados temporales antes de su reversión. La lectura posterior confirmó las cardinalidades persistidas examinadas. En las cuatro pruebas concurrentes, el diagnóstico de B y los datos confirmados coincidieron con la condición específica en conflicto: último cupo, uso de espacio, reducción de capacidad o duplicidad de matrícula.