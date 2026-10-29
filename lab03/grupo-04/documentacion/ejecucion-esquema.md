# Ejecución del esquema

## Requisitos

PostgreSQL 17 y cliente psql, o Docker. Comandos siguientes para Bash desde la raíz del repositorio. La preparación administrativa se realiza fuera de los scripts SQL.

## Entorno con Docker

Crear un contenedor local sin publicar puertos. La contraseña mostrada es solo de desarrollo y no debe reutilizarse. Usar un nombre de contenedor libre.

```bash
docker run -d --name bd1-lab03-g04 -e POSTGRES_PASSWORD=solo_desarrollo_no_reutilizar postgres:17
docker exec bd1-lab03-g04 pg_isready -U postgres
```

Esperar a que pg_isready indique disponibilidad; repetir la comprobación si todavía inicia. Crear una vez el rol ordinario y la base vacía:

```bash
docker exec bd1-lab03-g04 createuser -U postgres --no-superuser --no-createdb --no-createrole lab04
docker exec bd1-lab03-g04 createdb -U postgres -O lab04 lab03_g04
docker exec bd1-lab03-g04 psql -X -U lab04 -d lab03_g04 -v ON_ERROR_STOP=1 -c "SELECT version(), current_user;"
docker exec bd1-lab03-g04 psql -X -U lab04 -d lab03_g04 -v ON_ERROR_STOP=1 -c "SELECT rolname, rolsuper, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname = current_user;"
```

La conexión usa el socket local del contenedor; no constituye configuración de autenticación para producción. lab04 debe aparecer sin superusuario, creación de bases ni creación de roles.

## Crear las tablas

```bash
docker exec -i bd1-lab03-g04 psql -X -U lab04 -d lab03_g04 -v ON_ERROR_STOP=1 -f - < lab03/grupo-04/sql/01_esquema.sql
```

El archivo agrupa el DDL en BEGIN/COMMIT y no elimina objetos. Ejecutarlo sin otra transacción abierta y sobre una base vacía. No usa IF NOT EXISTS para ocultar diferencias con objetos existentes. Si falla, detenerse y revisar el error.

Para repetir desde cero sin borrar información, crear una base con otro nombre:

```bash
docker exec bd1-lab03-g04 createdb -U postgres -O lab04 lab03_g04_repeticion
docker exec -i bd1-lab03-g04 psql -X -U lab04 -d lab03_g04_repeticion -v ON_ERROR_STOP=1 -f - < lab03/grupo-04/sql/01_esquema.sql
```

Si ese nombre ya existe, utilizar uno nuevo. En una instalación PostgreSQL existente puede ejecutarse el archivo con psql y un rol propietario de una base vacía, usando ON_ERROR_STOP=1; no requiere superusuario para crear las tablas.

## Comprobar estructura

```bash
docker exec bd1-lab03-g04 psql -X -U lab04 -d lab03_g04 -v ON_ERROR_STOP=1 -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;"
docker exec bd1-lab03-g04 psql -X -U lab04 -d lab03_g04 -v ON_ERROR_STOP=1 -c "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = 'public' ORDER BY table_name, ordinal_position;"
docker exec bd1-lab03-g04 psql -X -U lab04 -d lab03_g04 -v ON_ERROR_STOP=1 -c "SELECT table_name, constraint_name, constraint_type FROM information_schema.table_constraints WHERE table_schema = 'public' ORDER BY table_name, constraint_name;"
```

Esperado: cinco tablas, 19 columnas, cinco PK, cinco FK y cuatro UNIQUE adicionales. Revisar también CHECK y nulabilidad contra el diccionario. Registrar versión, rol, sentencias, salida y conclusión como E-01.

## Límites y verificación

Se realizó revisión manual del SQL contra el diseño; la ejecución real y E-01 siguen pendientes. No hay resultados observados ni pruebas funcionales aprobadas en esta etapa. Las instrucciones anteriores son el procedimiento propuesto de comprobación. Las referencias a DDL futuro en documentos de pasos anteriores corresponden a esas etapas.

La FK garantiza existencia, no tipo organización ni mínimo de una facultad. Esas validaciones y su atomicidad se implementarán en el procedimiento, con los límites de escritura directa descritos en DL-05. Los rechazos declarativos se comprobarán en 05_pruebas.sql. Este paso incorpora solo 01_esquema.sql; los otros cuatro scripts pertenecen a etapas posteriores.

## Registro del paso

Prompt: «@GitHub Ok, haz el paso 4». Ajuste solicitado: README breve y publicación conjunta con el esquema. Herramienta: Perplexity. Propuesta incorporada: DDL conforme a DF-01 a DF-04 e instrucciones separadas del README. Validación independiente del equipo y ejecución: pendientes de registrar con fecha, responsable y evidencia.
