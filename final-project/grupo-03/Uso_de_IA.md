# Interacciones con inteligencia artificial — Universidad Horizonte

## Modelo: GPT-6

## Interacción 01 — Configuración reproducible del entorno PostgreSQL

### Prompt

Para el Proyecto Final del curso IC-4301 Bases de Datos I, Grupo 03 — Universidad Horizonte, define una configuración correcta y reproducible del entorno PostgreSQL.

Utiliza como fuentes la consigna general del Proyecto Final, el anexo del Grupo 03, los materiales del curso y la estructura existente en la rama `grupo-03-proyecto-final` del repositorio `jcortess/bd1-2026-2s`.

El entorno debe cumplir las siguientes condiciones:

1. Utilizar PostgreSQL 17, manteniendo compatibilidad con el motor empleado en Lab03.
2. Permitir que cada integrante reproduzca su propia instancia mediante Docker Compose, sin depender de rutas absolutas, credenciales personales ni configuraciones específicas del equipo de desarrollo.
3. Mantener los datos PostgreSQL en almacenamiento persistente y permitir acceder a los scripts del repositorio sin modificar los archivos anfitriones.
4. Permitir crear una base de trabajo nueva e independiente de la base administrativa.
5. Admitir conexiones simultáneas para las posteriores pruebas de transacciones y concurrencia.
6. Documentar en `README.md` los requisitos y comandos necesarios para iniciar el entorno, crear una base limpia, conectarse y detener los servicios.

Entrega la configuración propuesta para `compose.yaml`, su justificación técnica y el contenido correspondiente del README.

No implementes todavía tablas, rutinas ni procesos del negocio. No introduzcas servicios adicionales, aplicaciones auxiliares ni automatizaciones que no sean necesarias para reproducir el proyecto. No modifiques directamente el repositorio; la incorporación y validación se realizarán por separado.

### Respuesta

# Configuración del entorno — Universidad Horizonte

**Motor:** PostgreSQL 17.11
**Imagen:** `postgres:17.11-bookworm`
**Orquestación:** Docker Compose
**Alcance:** infraestructura de desarrollo y ejecución local reproducible.

### 1. Decisiones de configuración

Se propone un único servicio PostgreSQL administrado mediante Docker Compose.

La imagen `postgres:17.11-bookworm` fija una versión concreta del motor, evitando que distintas ejecuciones dependan de actualizaciones implícitas de la etiqueta de la imagen.

El servicio utiliza:

- Un volumen Docker con nombre para conservar los archivos de datos de PostgreSQL.
- Un montaje relativo de `./` hacia `/workspace`, en modo de solo lectura, para acceder posteriormente a los scripts SQL.
- Una comprobación de disponibilidad mediante `pg_isready`.
- Una base administrativa inicial `postgres`, separada de las bases destinadas a ejecutar el proyecto.
- Conexiones mediante `docker compose exec`, sin publicar puertos del contenedor en el equipo anfitrión.

Se evita ejecutar automáticamente los scripts de instalación desde el mecanismo de inicialización de la imagen PostgreSQL. Dicho mecanismo depende de la inicialización del directorio de datos y no garantiza que los scripts vuelvan a ejecutarse al reutilizar un volumen existente. La creación y carga de cada base del proyecto se realizará explícitamente y en el orden documentado.

### 2. Archivo `compose.yaml`

Ubicación: `final-project/grupo-03/compose.yaml`.

```yaml
name: bd1-g03-final

services:
  db:
    image: postgres:17.11-bookworm

    environment:
      POSTGRES_USER: bd1
      POSTGRES_PASSWORD: bd1_local
      POSTGRES_DB: postgres

    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./:/workspace:ro

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 3s
      timeout: 3s
      retries: 20

volumes:
  postgres_data:
```

La contraseña `bd1_local` corresponde exclusivamente al entorno local de desarrollo. La configuración no está destinada a exponerse como servicio PostgreSQL público ni a utilizarse en producción.

### 3. Documentación para `README.md`

Se incorpora al README el procedimiento de reproducción del entorno.

**Requisitos:** Docker Engine o Docker Desktop con soporte para contenedores Linux y Docker Compose V2.

Los comandos se ejecutan desde `final-project/grupo-03/`.

**Iniciar y comprobar el servicio:**

```powershell
docker compose config -q
docker compose up -d --wait
docker compose ps
```

**Comprobar PostgreSQL:**

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d postgres -c "SELECT current_database(), current_user, version();"
```

**Crear una base de trabajo limpia:**

```powershell
docker compose exec -T db createdb -U bd1 -T template0 universidad_horizonte_prueba_01
```

La base se crea a partir de `template0` para disponer de una base nueva, independiente de la base administrativa. La instalación completa del proyecto deberá realizarse posteriormente mediante los scripts SQL entregables.

**Comprobar que la base está vacía:**

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT current_database(); SELECT COUNT(*) AS tablas_usuario FROM pg_tables WHERE schemaname = 'public';"
```

**Abrir sesiones PostgreSQL independientes:**

```powershell
docker compose exec db psql -X -U bd1 -d universidad_horizonte_prueba_01
```

Cada terminal establece una conexión independiente. Sus identificadores pueden comprobarse mediante:

```sql
SELECT pg_backend_pid();
```

Para salir de `psql` se utiliza `\q`.

**Detener el servicio:**

```powershell
docker compose down
```

El comando conserva el volumen persistente. No debe utilizarse `docker compose down -v` como operación ordinaria de detención, porque elimina los volúmenes asociados al proyecto.

Las instrucciones de ejecución de los scripts SQL se incorporarán cuando estos hayan sido implementados y validados.

### Verificación posterior

La configuración propuesta se incorporó manualmente a `compose.yaml` y las instrucciones de reproducción a `README.md`, tras la revisión de las decisiones técnicas.

Las comprobaciones locales realizadas produjeron los siguientes resultados:

| Comprobación                                  | Resultado observado            |
| --------------------------------------------- | ------------------------------ |
| `docker compose config -q`                    | Código de salida `0`           |
| Imagen configurada                            | `postgres:17.11-bookworm`      |
| Inicio con `docker compose up -d --wait`      | Contenedor en estado `healthy` |
| Versión del servidor                          | PostgreSQL `17.11`             |
| Montaje `/workspace`                          | `RW = false`                   |
| Montaje `/var/lib/postgresql/data`            | `RW = true`                    |
| Creación de `universidad_horizonte_prueba_01` | Código de salida `0`           |
| Tablas de usuario iniciales en `public`       | `0`                            |
| Sesiones PostgreSQL simultáneas               | PID `1421` y PID `1592`        |
| `git diff --check`                            | Sin advertencias               |

Las pruebas confirman el funcionamiento de la configuración en el entorno local utilizado. La reproducción independiente en otro equipo y la ejecución del modelo físico completo quedan fuera de estas comprobaciones.

**Resultado incorporado:** `compose.yaml` y la sección de entorno de `README.md`, con decisiones de configuración revisadas y verificaciones locales satisfactorias.
