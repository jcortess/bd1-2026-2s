# Universidad Horizonte — Proyecto Final

- **Curso:** IC-4301 Bases de Datos I
- **Grupo:** 03
- **Integrantes:** Santiago Víquez Zamora y Felipe Salazar González

## Entorno de ejecución

El proyecto utiliza PostgreSQL 17.11. Se proporciona una configuración Docker Compose para facilitar su reproducción en equipos independientes. La instalación física comprende las 26 relaciones y los 135 atributos del modelo consolidado. Las comprobaciones ejecutadas hasta esta versión abarcan las restricciones declarativas de las 16 relaciones base y las diez relaciones complementarias; las garantías contextuales, los procesos de negocio asignados y las pruebas de concurrencia requieren sus mecanismos y comprobaciones específicos.

### Requisitos

- Docker Desktop o Docker Engine con soporte para contenedores Linux.
- Docker Compose V2.

Los comandos siguientes se ejecutan desde `final-project/grupo-03/`, donde se encuentra `compose.yaml`. No se requiere instalar `psql` en el equipo anfitrión: se utiliza el cliente incluido en el contenedor.

### Iniciar PostgreSQL

```powershell
docker compose config -q
docker compose up -d --wait
docker compose ps
```

La configuración utiliza el servicio `db`, un volumen persistente exclusivo y un montaje de solo lectura del directorio del proyecto en `/workspace`.

No se publica un puerto en el equipo anfitrión. Las conexiones se realizan mediante `docker compose exec`.

### Verificar la instancia

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d postgres -c "SELECT current_database(), current_user, version();"
```

Debe identificarse PostgreSQL 17.11 y una conexión válida a la base administrativa `postgres`.

### Crear una base nueva

La base administrativa no debe utilizarse para instalar el esquema del proyecto. Para una instalación independiente, se debe elegir un nombre de base que todavía no exista; los comandos siguientes utilizan `universidad_horizonte_prueba_01` exclusivamente como ejemplo.

```powershell
docker compose exec -T db createdb -U bd1 -T template0 universidad_horizonte_prueba_01
```

Comprobar que la base existe y no contiene tablas de usuario:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT current_database(); SELECT COUNT(*) AS tablas_usuario FROM pg_tables WHERE schemaname = 'public';"
```

El recuento inicial de tablas en `public` debe ser cero. Si la base ya existe, no se debe repetir `createdb`: para reproducir una instalación integral se utiliza otra base nueva, sin eliminar bases preexistentes.

### Instalación y pruebas de integridad

Los scripts se ejecutan en el orden indicado. La batería de integridad base se ejecuta **antes** de incorporar las diez tablas restantes porque valida expresamente el inventario parcial de 16 relaciones. La batería complementaria se ejecuta después de instalar y cargar el modelo físico completo.

**Archivos y orden de ejecución:**

| Orden | Archivo | Propósito |
| --- | --- | --- |
| 1 | `sql/01_esquema_base.sql` | Crear las 16 relaciones base, sus claves, restricciones e índices. |
| 2 | `sql/02_datos_base.sql` | Cargar 64 registros ficticios, incluido el núcleo curricular adaptado de Lab03. |
| 3 | `pruebas/01_pruebas_base.sql` | Verificar las 16 relaciones base mediante casos válidos, negativos y de frontera; terminar con `ROLLBACK`. |
| 4 | `sql/03_esquema_relaciones.sql` | Crear las diez relaciones restantes, completando las 26 relaciones y 135 atributos. |
| 5 | `sql/04_datos_relaciones.sql` | Incorporar 17 registros complementarios ficticios sin precargar resultados de los procesos asignados. |
| 6 | `pruebas/02_pruebas_relaciones.sql` | Verificar las diez relaciones, operaciones válidas y de frontera, y 102 casos negativos; terminar con `ROLLBACK`. |

**Precondición:** disponer de una base de trabajo nueva, sin tablas de usuario. Los archivos de creación y carga se ejecutan una sola vez por base. Cada comando siguiente utiliza `-X` para evitar configuración externa de `psql` y `ON_ERROR_STOP=1` para detenerse ante un error no controlado. Si un comando falla, se debe investigar la causa y verificar el estado de la base antes de continuar.

#### Crear el esquema base

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/01_esquema_base.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error al instalar el esquema base."
}
```

El script instala automáticamente la extensión `btree_gist`, necesaria para la restricción de exclusión GiST utilizada en `VENTANA_PERIODO`.

**Resultado esperado:** 16 tablas creadas y `COMMIT`, sin errores.

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT COUNT(*) AS tablas FROM pg_tables WHERE schemaname = 'public'; SELECT COUNT(*) AS atributos FROM information_schema.columns WHERE table_schema = 'public';"
```

**Resultado esperado:** 16 tablas y 57 atributos.

#### Cargar los datos base

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/02_datos_base.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error al cargar los datos base."
}
```

**Resultado esperado:** inserciones confirmadas mediante `COMMIT` y 64 registros distribuidos entre las 16 relaciones. Los datos curriculares compatibles de Lab03 se reutilizan con las adaptaciones necesarias. Las fechas incorporadas para representar vigencias son ficticias y no se presentan como conversiones históricas verificadas.

#### Ejecutar las pruebas de integridad base

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/01_pruebas_base.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error durante las pruebas de integridad base."
}
```

**Resultados esperados:** 16 relaciones y 57 atributos; 16 PK, 15 FK, cuatro UNIQUE, 25 CHECK, índice único parcial y exclusión GiST; casos positivos y de frontera satisfactorios; 53 casos negativos y cinco comprobaciones adicionales de `NOT NULL` rechazados por la causa prevista; finalización con `ROLLBACK`.

Los rechazos previstos se controlan en bloques de excepción PL/pgSQL. Un error no controlado interrumpe la ejecución y no constituye una prueba satisfactoria.

#### Comprobar el estado posterior de las relaciones base

Desde una conexión independiente, comprobar que permanecen los 64 registros de partida:

```powershell
$sql = @'
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
SELECT COUNT(*) AS relaciones_contadas,
       SUM(filas) AS registros_totales
FROM conteos;
'@

docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c $sql
```

**Resultado esperado:** 16 relaciones y 64 registros totales. Esta comprobación de la semilla base corresponde al estado anterior a cargar los datos complementarios; una vez ejecutado `04_datos_relaciones.sql`, la tabla `ADMISION` incorpora un registro adicional.

#### Crear las relaciones complementarias

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/03_esquema_relaciones.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error al instalar las relaciones complementarias."
}
```

El archivo crea `GRUPO`, `BLOQUE_HORARIO`, `SOLICITUD_MATRICULA`, `TRASLADO_PLAN`, `RECONOCIMIENTO_ACADEMICO`, `GRUPO_DOCENTE`, `HISTORIAL_OFERTA`, `HISTORIAL_SOLICITUD`, `EXCEPCION_REQUISITO` e `HISTORIAL_CORRECCION_CALIFICACION`. Declara diez PK, 27 FK, 32 CHECK, dos restricciones UNIQUE y un índice adicional. Estos mecanismos verifican condiciones locales y referenciales; no sustituyen las reglas contextuales y transaccionales pendientes de implementar.

**Resultado esperado:** diez tablas creadas y `COMMIT`, sin errores.

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT COUNT(*) AS tablas FROM pg_tables WHERE schemaname = 'public'; SELECT COUNT(*) AS atributos FROM information_schema.columns WHERE table_schema = 'public';"
```

**Resultado esperado:** 26 tablas y 135 atributos.

#### Cargar los datos complementarios

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/04_datos_relaciones.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error al cargar los datos complementarios."
}
```

**Resultado esperado:** `COMMIT` y 17 registros añadidos: una admisión histórica, cuatro grupos, cinco bloques de horario, cinco asignaciones docentes, un traslado y un reconocimiento académico. Junto con la semilla base quedan 81 registros. No se precargan solicitudes ni eventos de matrícula, historial de oferta, historial de solicitudes, excepciones o correcciones: esas relaciones se ejercitan mediante datos temporales en las pruebas.

#### Ejecutar las pruebas de relaciones complementarias

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/02_pruebas_relaciones.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error durante las pruebas de relaciones complementarias."
}
```

**Resultados esperados:** avisos de conformidad estructural de 26 tablas, 135 atributos y 78 columnas adicionales; conformidad de los datos iniciales; comprobación de casos positivos, fronteras y modificaciones/eliminaciones permitidas; 102 casos negativos y comprobaciones referenciales rechazados por el SQLSTATE y la restricción o columna prevista; terminación con `ROLLBACK`.

Las modificaciones de la batería se realizan dentro de una transacción revertida; no se presentan como operaciones de negocio confirmadas ni como pruebas de concurrencia. Los errores previstos se manejan en PL/pgSQL para que continúe la batería; un error ajeno al caso esperado detiene `psql`.

#### Comprobar el estado posterior del conjunto completo

Después del `ROLLBACK`, abrir una conexión independiente y verificar los recuentos de las diez relaciones complementarias:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT (SELECT COUNT(*) FROM grupo) AS grupos, (SELECT COUNT(*) FROM bloque_horario) AS bloques, (SELECT COUNT(*) FROM grupo_docente) AS docentes, (SELECT COUNT(*) FROM traslado_plan) AS traslados, (SELECT COUNT(*) FROM reconocimiento_academico) AS reconocimientos, (SELECT COUNT(*) FROM solicitud_matricula) AS solicitudes, (SELECT COUNT(*) FROM historial_oferta) AS historial_oferta, (SELECT COUNT(*) FROM historial_solicitud) AS historial_solicitud, (SELECT COUNT(*) FROM excepcion_requisito) AS excepciones, (SELECT COUNT(*) FROM historial_correccion_calificacion) AS correcciones;"
```

**Resultado esperado y observado en la verificación de esta versión:** cuatro grupos, cinco bloques, cinco asignaciones docentes, un traslado, un reconocimiento y cero filas en las otras cinco relaciones. La conexión independiente confirmó que la batería dejó intacta la semilla de las relaciones complementarias. Los resultados detallados y las condiciones de cada prueba se documentan en `pruebas/Pruebas.md` y `evidencias/Resultados.md`.

#### Repetición y recuperación ante errores

Las baterías `01_pruebas_base.sql` y `02_pruebas_relaciones.sql` finalizan sus transacciones con `ROLLBACK`, por lo que sus cambios en tablas no persisten. Deben ejecutarse en sus estados correspondientes: la primera sobre las 16 tablas base con 64 registros, y la segunda sobre las 26 tablas con los datos complementarios cargados. Para repetir las pruebas base, utilícese una nueva instalación en una base vacía; no se debe ejecutar el guion que exige 16 tablas contra el esquema completo de 26.

Para repetir `02_pruebas_relaciones.sql` en una base ya instalada se debe comprobar previamente que las tablas y la semilla mantienen sus recuentos iniciales. En caso de error inesperado, `ON_ERROR_STOP=1` detiene el cliente y la conexión termina; las operaciones de la transacción no confirmada se revierten, pero el estado posterior debe comprobarse mediante otra conexión. No se debe repetir una creación o carga tras un fallo sin identificar antes qué se confirmó.

Para reproducir la instalación integral desde cero se utiliza otra base vacía y se ejecutan los archivos en el orden documentado. No es necesario eliminar bases existentes ni modificar el volumen persistente de Docker.

### Sesiones PostgreSQL independientes

Para abrir una sesión interactiva:

```powershell
docker compose exec db psql -X -U bd1 -d universidad_horizonte_prueba_01
```

El comando puede ejecutarse en dos terminales distintas. Dentro de cada sesión:

```sql
SELECT pg_backend_pid();
```

Los identificadores distintos permiten reconocer las conexiones independientes que se utilizarán para comprobar concurrencia. Abrir dos sesiones no constituye, por sí solo, una prueba concurrente.

Para cerrar una sesión:

```text
\q
```

### Detener el entorno

```powershell
docker compose down
```

Este comando detiene y retira los contenedores del proyecto sin eliminar su volumen persistente.

No se debe utilizar `docker compose down -v` como procedimiento ordinario de repetición, porque eliminaría el volumen de datos de esta instancia.
