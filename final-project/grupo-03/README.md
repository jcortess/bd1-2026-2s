# Universidad Horizonte — Proyecto Final

- **Curso:** IC-4301 Bases de Datos I
- **Grupo:** 03
- **Integrantes:** Santiago Víquez Zamora y Felipe Salazar González

## Entorno de ejecución

El proyecto utiliza PostgreSQL 17.11. Se proporciona una configuración Docker Compose para facilitar su reproducción en equipos independientes.

### Requisitos

- Docker Desktop o Docker Engine con soporte para contenedores Linux.
- Docker Compose V2.

Los comandos siguientes se ejecutan desde `final-project/grupo-03/`, donde se encuentra `compose.yaml`.

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

La base administrativa no debe utilizarse para instalar el esquema del proyecto.

Para crear una base de trabajo vacía:

```powershell
docker compose exec -T db createdb -U bd1 -T template0 universidad_horizonte_prueba_01
```

Comprobar que la base existe y no contiene tablas de usuario:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT current_database(); SELECT COUNT(*) AS tablas_usuario FROM pg_tables WHERE schemaname = 'public';"
```

El recuento inicial de tablas en `public` debe ser cero.

Para repetir una instalación integral debe utilizarse otra base nueva, con un nombre diferente. No se deben ejecutar nuevamente los scripts de creación sobre una base que ya contenga objetos del proyecto.

### Instalación del esquema base y pruebas de integridad

El esquema base implementa 16 relaciones y 57 atributos del modelo físico de Universidad Horizonte en PostgreSQL 17.11. Los scripts se ejecutan desde `final-project/grupo-03/`, con el servicio `db` de Docker Compose iniciado.

**Archivos y orden de ejecución:**

| Orden | Archivo | Propósito |
| --- | --- | --- |
| 1 | `sql/01_esquema_base.sql` | Crear las 16 relaciones, sus claves, restricciones e índices. |
| 2 | `sql/02_datos_base.sql` | Cargar datos ficticios y el núcleo curricular adaptado de Lab03. |
| 3 | `pruebas/01_pruebas_base.sql` | Verificar estructura, integridad y comportamiento mediante casos positivos, negativos y de frontera. |

**Precondición:** disponer de una base de trabajo nueva, sin tablas de usuario, creada mediante el procedimiento anterior. El esquema y los datos iniciales deben instalarse una sola vez en esa base.

Los comandos siguientes utilizan `universidad_horizonte_prueba_01`. Para una instalación independiente debe sustituirse ese nombre por el de la base vacía correspondiente.

#### Crear el esquema

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/01_esquema_base.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error al instalar el esquema base."
}
```

El script instala automáticamente la extensión `btree_gist`, necesaria para la restricción de exclusión GiST utilizada en `VENTANA_PERIODO`.

**Resultado esperado:** creación de 16 tablas y confirmación mediante `COMMIT`, sin errores.

Para comprobar la cantidad de tablas y atributos:

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT COUNT(*) AS tablas FROM pg_tables WHERE schemaname = 'public'; SELECT COUNT(*) AS atributos FROM information_schema.columns WHERE table_schema = 'public';"
```

**Resultado esperado:** 16 tablas y 57 atributos.

#### Cargar los datos iniciales

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/sql/02_datos_base.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error al cargar los datos iniciales."
}
```

**Resultado esperado:** inserciones completadas sin errores y confirmación mediante `COMMIT`.

La semilla contiene 64 registros distribuidos entre las 16 relaciones. Los datos curriculares compatibles de Lab03 se reutilizan con las adaptaciones necesarias. Las fechas incorporadas para representar vigencias se consideran ficticias, no conversiones históricas verificadas.

#### Ejecutar las pruebas de integridad

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -f /workspace/pruebas/01_pruebas_base.sql

if ($LASTEXITCODE -ne 0) {
    throw "Error durante las pruebas de integridad."
}
```

El archivo comprueba la estructura física, la composición de las claves, las restricciones declarativas, los datos iniciales y el comportamiento ante operaciones válidas e inválidas.

**Resultados esperados:**

- 16 relaciones y 57 atributos verificados.
- 16 claves primarias, 15 claves foráneas, cuatro restricciones UNIQUE y 25 CHECK.
- Índice único parcial y restricción de exclusión GiST correctos.
- Pruebas positivas y de frontera satisfactorias.
- 53 casos negativos rechazados por la causa prevista.
- Cinco comprobaciones adicionales de obligatoriedad.
- Finalización con `ROLLBACK`, sin conservar las modificaciones temporales.

Los errores esperados se controlan mediante bloques de excepción PL/pgSQL, permitiendo continuar con las comprobaciones posteriores. Un error no controlado interrumpe la ejecución y debe investigarse; no constituye un rechazo satisfactorio.

#### Comprobar el estado posterior

Desde una conexión independiente, verificar que permanecen las relaciones y los registros iniciales:

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

**Resultado esperado:** 16 relaciones y 64 registros totales.

#### Repetición y recuperación ante errores

El script `01_pruebas_base.sql` se ejecuta dentro de una transacción que finaliza con `ROLLBACK`. Las inserciones temporales utilizan identificadores controlados cuando corresponde, evitando conflictos con la generación de identidades. Por ello, las pruebas pueden repetirse sobre una base correctamente instalada y cargada.

Si falla la creación del esquema o la carga inicial, se debe examinar el error y el estado de la base antes de continuar. No se debe repetir la instalación sobre una base parcialmente construida sin comprobar previamente qué objetos o registros quedaron confirmados.

Para reproducir la instalación completa, se utiliza otra base vacía y se ejecutan los archivos en el mismo orden. No es necesario eliminar bases existentes ni modificar el volumen persistente de Docker.

### Sesiones PostgreSQL independientes

Para abrir una sesión interactiva:

```powershell
docker compose exec db psql -X -U bd1 -d universidad_horizonte_prueba_01
```

El comando puede ejecutarse en dos terminales distintas. Dentro de cada sesión:

```sql
SELECT pg_backend_pid();
```

Los identificadores distintos permiten reconocer las conexiones independientes que posteriormente se utilizarán para comprobar concurrencia.

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
