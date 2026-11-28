# Universidad Horizonte — Proyecto Final

- **Curso:** IC-4301 Bases de Datos I
- **Grupo:** 03
- **Integrantes:** Santiago Víquez Zamora y Felipe Salazar González

## Entorno de ejecución

El proyecto implementa en PostgreSQL el modelo de Universidad Horizonte para admisiones, planes de estudio, oferta académica y solicitudes de matrícula. El esquema contiene 26 relaciones y 135 atributos. La instalación incorpora restricciones declarativas y controles de integridad contextual, temporal e histórica.

Se utilizó PostgreSQL 17.11 con el cliente `psql` incluido en el contenedor. Las tres baterías secuenciales se ejecutaron sobre estados sucesivos de una misma instalación. Las pruebas concurrentes de último cupo, asignación de espacio, reducción de capacidad y duplicidad de matrícula se realizaron en una segunda base de datos.

### Requisitos

- Docker Desktop o Docker Engine con soporte para contenedores Linux.
- Docker Compose V2.
- PowerShell para ejecutar los comandos de este documento.

Los comandos se ejecutan desde `final-project/grupo-03/`, donde se encuentra `compose.yaml`. El servicio `db` utiliza la imagen `postgres:17.11-bookworm`, un volumen persistente y un montaje de solo lectura del directorio del grupo en `/workspace`. Las conexiones se realizan mediante `docker compose exec`; no se requiere instalar `psql` en el equipo anfitrión ni publicar un puerto.

### Iniciar PostgreSQL

```powershell
docker compose config -q
if ($LASTEXITCODE -ne 0) { throw "Configuración de Docker Compose inválida." }

docker compose up -d --wait
if ($LASTEXITCODE -ne 0) { throw "El servicio PostgreSQL no está disponible." }

docker compose ps
```

El servicio `db` debe aparecer en estado `healthy`.

### Verificar la instancia

```powershell
docker compose exec -T db psql --version
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d postgres -c "SELECT current_database(), current_user, version();"
```

Debe identificarse la instancia PostgreSQL 17.11 y una conexión a la base administrativa `postgres` con el usuario `bd1`.

### Crear una base nueva

Los siguientes comandos utilizan el nombre de la base secuencial de la ejecución documentada. Para repetir la instalación en una instancia donde ese nombre ya existe, se asigna a `$base` un nombre nuevo y se conserva la misma variable durante todo el procedimiento.

```powershell
$base = 'universidad_horizonte_prueba_01'

docker compose exec -T db createdb -U bd1 -T template0 $base
if ($LASTEXITCODE -ne 0) { throw "No se creó la base nueva. Verificar el nombre antes de continuar." }

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -c "SELECT current_database() AS base_actual; SELECT COUNT(*) AS tablas_usuario FROM pg_tables WHERE schemaname = 'public';"
if ($LASTEXITCODE -ne 0) { throw "No se pudo verificar la base de trabajo." }
```

Antes de instalar el esquema, `base_actual` debe coincidir con `$base` y `tablas_usuario` debe ser `0`.

### Instalación y pruebas de integridad

| Orden | Archivo | Propósito |
|---:|---|---|
| 1 | [`sql/01_esquema_base.sql`](sql/01_esquema_base.sql) | Crear las 16 relaciones base, sus claves, restricciones e índices. |
| 2 | [`sql/02_datos_base.sql`](sql/02_datos_base.sql) | Cargar 64 registros ficticios, incluido el núcleo curricular adaptado de Lab03. |
| 3 | [`pruebas/01_pruebas_base.sql`](pruebas/01_pruebas_base.sql) | Validar el inventario de 16 relaciones y 57 atributos, sus datos y restricciones. |
| 4 | [`sql/03_esquema_relaciones.sql`](sql/03_esquema_relaciones.sql) | Crear las diez relaciones restantes y completar las 26 relaciones y 135 atributos. |
| 5 | [`sql/04_datos_relaciones.sql`](sql/04_datos_relaciones.sql) | Incorporar los 17 registros complementarios. |
| 6 | [`pruebas/02_pruebas_relaciones.sql`](pruebas/02_pruebas_relaciones.sql) | Validar las relaciones adicionales y sus restricciones declarativas sobre el esquema completo. |
| 7 | [`sql/05_integridad_avanzada.sql`](sql/05_integridad_avanzada.sql) | Instalar las funciones y los triggers de integridad avanzada y validar la semilla existente. |
| 8 | [`pruebas/03_pruebas_integridad_avanzada.sql`](pruebas/03_pruebas_integridad_avanzada.sql) | Verificar la integridad contextual, temporal e histórica y el tratamiento de los niveles de aislamiento examinados. |

El orden forma parte de las precondiciones de prueba. La primera batería exige que existan exactamente 16 tablas. La segunda comprueba las operaciones permitidas por las restricciones declarativas antes de instalar los triggers avanzados. La tercera exige que esos triggers ya estén instalados y que la semilla contenga 81 registros.

Los archivos de esquema y carga se ejecutan una vez por base. La opción `-X` evita que la configuración personal de `psql` altere la ejecución. `ON_ERROR_STOP=1` detiene el cliente ante un error SQL no controlado.

#### Crear el esquema base

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/sql/01_esquema_base.sql
if ($LASTEXITCODE -ne 0) { throw "Error al instalar el esquema base." }
```

El archivo instala la extensión `btree_gist`, utilizada por la restricción de exclusión de `VENTANA_PERIODO`. Se espera que la creación de las 16 tablas finalice con `COMMIT`.

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -c "SELECT COUNT(*) AS tablas FROM pg_tables WHERE schemaname = 'public'; SELECT COUNT(*) AS atributos FROM information_schema.columns WHERE table_schema = 'public';"
```

**Resultado esperado:** 16 tablas y 57 atributos.

#### Cargar los datos base

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/sql/02_datos_base.sql
if ($LASTEXITCODE -ne 0) { throw "Error al cargar los datos base." }
```

**Resultado esperado:** carga de 64 registros en las 16 relaciones y confirmación con `COMMIT`. Los datos curriculares compatibles de Lab03 se reutilizan con las adaptaciones del modelo. Las fechas empleadas para representar vigencias son ficticias.

#### Ejecutar las pruebas de integridad base

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/pruebas/01_pruebas_base.sql
if ($LASTEXITCODE -ne 0) { throw "Error durante las pruebas de integridad base." }
```

**Resultado esperado:** comprobación de 16 relaciones, 57 atributos, 16 PK, 15 FK, cuatro restricciones `UNIQUE`, 25 restricciones `CHECK`, el índice único parcial y la exclusión GiST. Las operaciones positivas deben aceptarse. Los 53 casos negativos y las cinco comprobaciones adicionales de `NOT NULL` deben producir el diagnóstico previsto. El archivo debe finalizar con `ROLLBACK`.

#### Comprobar el estado posterior de las relaciones base

Desde una conexión independiente, verificar los recuentos antes de incorporar las relaciones complementarias:

```powershell
$sqlBase = @'
WITH conteos AS (
    SELECT COUNT(*) AS filas FROM estudiante
    UNION ALL SELECT COUNT(*) FROM admision
    UNION ALL SELECT COUNT(*) FROM carrera
    UNION ALL SELECT COUNT(*) FROM sede
    UNION ALL SELECT COUNT(*) FROM version_plan_estudios
    UNION ALL SELECT COUNT(*) FROM periodo_academico
    UNION ALL SELECT COUNT(*) FROM curso
    UNION ALL SELECT COUNT(*) FROM escuela
    UNION ALL SELECT COUNT(*) FROM espacio
    UNION ALL SELECT COUNT(*) FROM docente
    UNION ALL SELECT COUNT(*) FROM carrera_sede
    UNION ALL SELECT COUNT(*) FROM participacion_plan
    UNION ALL SELECT COUNT(*) FROM requisito_curso
    UNION ALL SELECT COUNT(*) FROM contacto_estudiante
    UNION ALL SELECT COUNT(*) FROM persona_autorizadora
    UNION ALL SELECT COUNT(*) FROM ventana_periodo
)
SELECT COUNT(*) AS relaciones_contadas, SUM(filas) AS registros_totales
FROM conteos;
'@

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -c $sqlBase
```

**Resultado esperado:** 16 relaciones contadas y 64 registros. Este total corresponde a la semilla base. La carga complementaria añade, entre otros datos, una fila a `ADMISION`.

#### Crear las relaciones complementarias

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/sql/03_esquema_relaciones.sql
if ($LASTEXITCODE -ne 0) { throw "Error al instalar las relaciones complementarias." }
```

El archivo crea `GRUPO`, `BLOQUE_HORARIO`, `SOLICITUD_MATRICULA`, `TRASLADO_PLAN`, `RECONOCIMIENTO_ACADEMICO`, `GRUPO_DOCENTE`, `HISTORIAL_OFERTA`, `HISTORIAL_SOLICITUD`, `EXCEPCION_REQUISITO` e `HISTORIAL_CORRECCION_CALIFICACION`. Declara diez PK, 27 FK, 32 restricciones `CHECK`, una restricción `UNIQUE` y un índice único parcial.

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -c "SELECT COUNT(*) AS tablas FROM pg_tables WHERE schemaname = 'public'; SELECT COUNT(*) AS atributos FROM information_schema.columns WHERE table_schema = 'public';"
```

**Resultado esperado:** creación confirmada con `COMMIT` y un inventario de 26 tablas y 135 atributos.

#### Cargar los datos complementarios

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/sql/04_datos_relaciones.sql
if ($LASTEXITCODE -ne 0) { throw "Error al cargar los datos complementarios." }
```

**Resultado esperado:** `COMMIT` y 17 registros añadidos: una admisión histórica, cuatro grupos, cinco bloques de horario, cinco asignaciones docentes, un traslado y un reconocimiento académico. El total de la semilla asciende a 81 registros. Las tablas de solicitudes, historial de oferta, historial de solicitudes, excepciones y correcciones quedan vacías.

#### Ejecutar las pruebas de relaciones complementarias

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/pruebas/02_pruebas_relaciones.sql
if ($LASTEXITCODE -ne 0) { throw "Error durante las pruebas de relaciones complementarias." }
```

**Resultado esperado:** comprobación de las 26 tablas, los 135 atributos y las 78 columnas adicionales. El guion contrasta la semilla, los casos positivos y de frontera, las modificaciones y eliminaciones examinadas y 102 rechazos por el `SQLSTATE` y la restricción o columna previstos. Finaliza con `ROLLBACK`.

#### Comprobar el estado posterior del conjunto completo

La siguiente consulta se utiliza en una conexión independiente después de la segunda batería y, nuevamente, después de la tercera. Conservar `$sqlEstado` durante la ejecución de los pasos siguientes.

```powershell
$sqlEstado = @'
SELECT
    (SELECT COUNT(*) FROM pg_tables
     WHERE schemaname = 'public') AS tablas,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = 'public') AS atributos,
    (SELECT COUNT(*) FROM grupo) AS grupos,
    (SELECT COUNT(*) FROM bloque_horario) AS bloques,
    (SELECT COUNT(*) FROM grupo_docente) AS asignaciones_docentes,
    (SELECT COUNT(*) FROM traslado_plan) AS traslados,
    (SELECT COUNT(*) FROM reconocimiento_academico) AS reconocimientos,
    (SELECT COUNT(*) FROM solicitud_matricula) AS solicitudes,
    (SELECT COUNT(*) FROM historial_oferta) AS historial_oferta,
    (SELECT COUNT(*) FROM historial_solicitud) AS historial_solicitud,
    (SELECT COUNT(*) FROM excepcion_requisito) AS excepciones,
    (SELECT COUNT(*) FROM historial_correccion_calificacion) AS correcciones;
'@

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -At -c $sqlEstado
```

**Resultado esperado:** `26|135|4|5|5|1|1|0|0|0|0|0`. El campo de asignaciones docentes cuenta las filas de `grupo_docente`.

#### Instalar la integridad avanzada

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/sql/05_integridad_avanzada.sql
if ($LASTEXITCODE -ne 0) { throw "Error al instalar la integridad avanzada." }
```

El archivo instala los controles de escritura sobre el esquema existente y ejecuta `public.uh_validar_integridad()` sobre la semilla antes de confirmar la instalación. Desde una conexión nueva se comprueba el catálogo:

```powershell
$sqlCatalogo = @'
SELECT
    (SELECT COUNT(*)
     FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND p.prokind = 'f'
       AND left(p.proname::text, 3) = 'uh_') AS funciones,
    (SELECT COUNT(*)
     FROM pg_trigger t
     JOIN pg_class c ON c.oid = t.tgrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND NOT t.tgisinternal
       AND left(t.tgname::text, 3) = 'uh_') AS triggers,
    to_regprocedure('public.uh_validar_integridad()') IS NOT NULL AS validador;
'@

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -At -c $sqlCatalogo
```

**Resultado esperado:** `21|94|t`, correspondiente a 21 funciones, 94 triggers de usuario y presencia del validador.

#### Ejecutar las pruebas de integridad avanzada

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -f /workspace/pruebas/03_pruebas_integridad_avanzada.sql
if ($LASTEXITCODE -ne 0) { throw "Error durante las pruebas de integridad avanzada." }

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $base -At -c $sqlEstado
```

La batería exige 26 tablas, 135 atributos, 81 filas de semilla y 94 triggers. Comprueba los estados de los escenarios antes de revertirlos. Para los rechazos de integridad exige `23514` y el nombre de restricción previsto. Tras revertir la transacción principal, comprueba en dos transacciones separadas el rechazo `25001` bajo `REPEATABLE READ` y `SERIALIZABLE`. Ambas terminan con `ROLLBACK`.

**Resultado esperado:** finalización sin errores no controlados y lectura posterior `26|135|4|5|5|1|1|0|0|0|0|0`. La variante temporal del caso de corrección académica depende del reloj del servidor. La condición y la rama observada el 27 de noviembre de 2026 se identifican en [Pruebas, sección 10.2](pruebas/Pruebas.md#102-casos-secuenciales-y-criterios-de-aceptación).

#### Repetición y recuperación ante errores

| Batería | Estado de instalación necesario para repetirla |
|---|---|
| `01_pruebas_base.sql` | Solo el esquema y la carga base: 16 tablas y 64 registros. |
| `02_pruebas_relaciones.sql` | Archivos de instalación `01` a `04` ejecutados: 26 tablas y 81 registros, antes de instalar los triggers avanzados. |
| `03_pruebas_integridad_avanzada.sql` | Archivos de instalación `01` a `05` ejecutados, semilla de 81 registros conservada y controles avanzados presentes. |

Para repetir una batería en su estado de instalación se ejecuta únicamente su archivo de pruebas. Si la instalación ya avanzó más allá de ese estado, se prepara otra base nueva hasta el paso correspondiente. Las tres baterías revierten sus operaciones temporales sobre las tablas.

Los guiones manejan internamente los rechazos esperados. Ante un error no controlado, se interrumpe la secuencia, se identifica la sentencia y se comprueba desde otra conexión qué esquema o carga quedó confirmado. Los archivos anteriores que ya finalizaron con `COMMIT` conservan sus efectos. Los datos de prueba se verifican mediante los recuentos y las consultas de estado correspondientes a la batería.

### Sesiones PostgreSQL independientes

Los cuatro escenarios concurrentes utilizan una **segunda base nueva**. La preparación y la escritura aceptada en cada escenario se confirman. Para reproducir de nuevo A–D se utiliza otra base con la misma semilla inicial.

Desde `final-project/grupo-03/`, elegir un nombre disponible y ejecutar los cinco archivos de instalación:

```powershell
$baseConcurrente = 'universidad_horizonte_concurrencia_01'

docker compose exec -T db createdb -U bd1 -T template0 $baseConcurrente
if ($LASTEXITCODE -ne 0) { throw "No se creó la base nueva de concurrencia." }

$archivos = @(
    '01_esquema_base.sql'
    '02_datos_base.sql'
    '03_esquema_relaciones.sql'
    '04_datos_relaciones.sql'
    '05_integridad_avanzada.sql'
)

foreach ($archivo in $archivos) {
    docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $baseConcurrente -f "/workspace/sql/$archivo"
    if ($LASTEXITCODE -ne 0) { throw "Falló la instalación de $archivo." }
}

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $baseConcurrente -At -c $sqlEstado
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d $baseConcurrente -At -c $sqlCatalogo
```

Antes de preparar los escenarios, las consultas deben devolver `26|135|4|5|5|1|1|0|0|0|0|0` y `21|94|t`. Ambas variables de consulta se definen en los apartados anteriores.

Abrir tres terminales en el directorio del grupo. En cada una, conectarse a la misma base de concurrencia. Si se eligió otro nombre al crearla, utilizar ese nombre en las tres conexiones.

```powershell
docker compose exec db psql -X -U bd1 -d universidad_horizonte_concurrencia_01
```

Ejecutar una sola vez la preparación de seis grupos y seguir, en orden, los casos A–D. Dos conexiones realizan las escrituras y la tercera observa el bloqueo y consulta el estado confirmado. Las sentencias de preparación, los nombres de sesión para la reproducción, la intercalación de `BEGIN` y `COMMIT`, los diagnósticos previstos y las consultas finales se encuentran en [Pruebas, secciones 10.4 y 10.5](pruebas/Pruebas.md#104-preparación-de-los-escenarios-concurrentes). Los resultados de la ejecución se encuentran en [Resultados, sección 9.4](evidencias/Resultados.md#94-conflictos-concurrentes).

Después de completar el cierre de las transacciones, salir de cada cliente con `\q`.

### Detener el entorno

```powershell
docker compose down
```

El comando detiene y retira los contenedores del proyecto conservando el volumen de PostgreSQL. La repetición de las pruebas se realiza con las condiciones de base y semilla indicadas para cada conjunto.