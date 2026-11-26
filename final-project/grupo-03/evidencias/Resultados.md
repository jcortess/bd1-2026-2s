# Resultados de ejecución y validación — Universidad Horizonte

## 1. Identificación

| Elemento | Valor |
|---|---|
| Curso | IC-4301 Bases de Datos I |
| Proyecto | Universidad Horizonte |
| Grupo | 03 |
| Fecha de ejecución | 25 de noviembre de 2026 |
| Motor | PostgreSQL 17.11 |
| Imagen | `postgres:17.11-bookworm` |
| Entorno | Docker Compose |
| Servicio | `db` |
| Base de trabajo | `universidad_horizonte_prueba_01` |
| Usuario PostgreSQL | `bd1` |
| Alcance verificado | 16 relaciones base, 57 atributos, carga inicial y restricciones declarativas |

Se ejecutaron los siguientes archivos, en el orden indicado:

1. [`sql/01_esquema_base.sql`](../sql/01_esquema_base.sql): creación de relaciones y restricciones.
2. [`sql/02_datos_base.sql`](../sql/02_datos_base.sql): carga de datos ficticios.
3. [`pruebas/01_pruebas_base.sql`](../pruebas/01_pruebas_base.sql): comprobaciones de estructura, integridad y comportamiento.

Se utilizó `psql` con `-X` y `ON_ERROR_STOP=1`. Los resultados consignados corresponden a la ejecución efectuada en PostgreSQL, no exclusivamente a resultados previstos por los scripts.

**Correspondencia de la evidencia:** después de esta ejecución se reformularon seis mensajes `RAISE NOTICE` y se ajustaron comentarios del guion de pruebas, sin alterar sus sentencias SQL ni sus condiciones de aceptación. Los fragmentos de avisos consignados en la sección 5 proceden de la salida original observada el 25 de noviembre de 2026; no se presentan como salida de los mensajes reformulados. Para acreditar una ejecución de la copia actual del guion debe repetirse la prueba y registrar sus resultados.

## 2. Preparación y estado inicial

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

## 3. Instalación del esquema

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

## 4. Carga de datos ficticios

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

## 5. Ejecución de pruebas de integridad

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

**Evidencia de la ejecución original — fragmento literal del aviso observado:**

```text
Catalogo: 16 PK, 15 FK, 4 UNIQUE, 25 CHECK, indice parcial y exclusion GiST correctos
```

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

**Evidencia de la ejecución original — fragmento literal del aviso observado:**

```text
positivos: inserciones, actualizacion, fechas frontera y nulabilidad: OK
```

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

**Evidencia de la ejecución original — fragmento literal del aviso observado:**

```text
negativos: 53 rechazos por causa exacta confirmados
```

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

**Evidencia de la ejecución original — fragmento literal del aviso observado:**

```text
5 comprobaciones NOT NULL por columna
```

**Conclusión:** se confirmó el rechazo de los cinco valores nulos prohibidos, con identificación de la columna correspondiente.

### 5.5. Comprobación posterior a los rechazos

Dentro de la transacción se verificó la conservación de registros de referencia después de los casos negativos.

Las comprobaciones incluyeron:

- Existencia del periodo académico original.
- Conservación de cuatro ventanas asociadas al periodo.
- Recuento de once requisitos curriculares, incluidos los diez iniciales y el caso positivo temporal.
- Conservación de los tres contactos correspondientes al estudiante utilizado en las pruebas, incluido el contacto temporal.
- Existencia de la escuela de referencia.

**Evidencia de la ejecución original — fragmento literal del aviso observado:**

```text
posterior: rechazos sin efectos indebidos
```

**Conclusión:** no se detectaron modificaciones indebidas en los registros examinados después de los rechazos.

### 5.6. Cierre de las pruebas

La ejecución finalizó con el mensaje:

```text
ROLLBACK
```

La reversión retiró las inserciones y la actualización temporales realizadas por el archivo de pruebas. Las transacciones de creación del esquema y carga de datos habían finalizado previamente mediante `COMMIT`.

**Conclusión:** el guion de pruebas cerró su transacción y no confirmó los cambios temporales.

## 6. Comprobación independiente del estado persistido

Después de ejecutar el archivo de pruebas, se abrió una nueva conexión PostgreSQL y se consultaron las cardinalidades persistidas.

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

## 7. Conclusión general

Se completó satisfactoriamente la instalación y validación de las 16 relaciones base del modelo físico de Universidad Horizonte en PostgreSQL 17.11.

Se verificaron las 57 columnas previstas, la composición de las claves y referencias, las restricciones declarativas examinadas, la carga de 64 registros ficticios y el comportamiento de los casos positivos, negativos y de frontera incluidos en el guion.

Los 53 casos negativos y las cinco comprobaciones adicionales de obligatoriedad produjeron los rechazos esperados. Las verificaciones posteriores no detectaron efectos indebidos en los registros examinados. El archivo de pruebas finalizó mediante `ROLLBACK` y la consulta independiente confirmó las cardinalidades iniciales.

**Resultado de la validación: satisfactorio para las estructuras, operaciones y restricciones efectivamente comprobadas.**

La evidencia es reproducible mediante los archivos SQL referenciados, ejecutados sobre una base PostgreSQL vacía en el orden documentado. Los resultados aquí consignados proceden de la ejecución observada y de las comprobaciones efectuadas, sin atribuir resultados a pruebas no realizadas.