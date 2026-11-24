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
