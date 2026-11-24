# Pruebas, evidencia y reproducción

Todas las salidas enlazadas son ejecuciones reales de esta sesión. No se editaron las pruebas públicas. Ejecutar los comandos de esta guía **desde `operacion-platano/`**. El cliente `psql` se usa dentro de Docker porque no está instalado en Windows. Python 3.12 está disponible y los ejecutores usan solo su biblioteca estándar.

## Entorno y creación desde cero

Docker ejecuta PostgreSQL en un contenedor; el volumen guarda las tablas. La imagen `postgres:16` utilizada ejecutó PostgreSQL 16.15. El Compose monta el esquema y el seed en `/docker-entrypoint-initdb.d` como archivos de solo lectura, ordenados por sus prefijos 01 y 02. Los ejecuta cuando el directorio de datos está vacío. `03_queries.sql` se ejecuta aparte: no crea vistas permanentes ni se inicializa automáticamente.

La base inicial se creó con `docker compose up -d --wait --wait-timeout 90`. Después de las correcciones se creó otra con:

```powershell
docker compose -p platano_mariapaula -f docker-compose.yml -f entregables/compose.validacion.yml up -d --wait --wait-timeout 90
```

`-p` separa red y volumen por nombre de proyecto. Los dos `-f` combinan configuración. El complemento cambia contenedor y puerto a `platano_validacion_db` / 5433. `!override` requiere Compose 2.24.4 o posterior; se verificó Compose v5.3.1. La [documentación de combinación de Compose](https://docs.docker.com/reference/compose-file/merge/) explica esa etiqueta.

En esta sesión **el volumen de validación no existía**, y la evidencia 10 registra su creación. La evidencia 11 registra ejecución de ambos scripts con los conteos corregidos. Después se detectó un defecto adicional de precisión: `numeric(5,1)` redondeaba 69.99 a 70 y 100.01 a 100 (evidencia 22). La versión definitiva usa `numeric` sin escala fija.

Para comprobar los **scripts definitivos** desde cero se creó una base adicional vacía con `docker exec platano_validacion_db createdb -U platano platano_final` (23) y se enviaron esquema y seed actuales a esa base con el ejecutor (24–25). Esta base no existía previamente; el DROP SCHEMA del archivo solo encontró su esquema público vacío. Las 104 aserciones pasaron en esa base (27). La base de trabajo `platano` recibió la ampliación de tipo sin pérdida mediante `entregables/ajuste_precision.sql` (26) y también pasó las 104 (28). No se pretende que el volumen se hubiera reinicializado automáticamente al editar SQL.

Repetir `up` sobre el mismo volumen no lo vacía ni recarga el seed. Para otra instalación nueva, usar un nombre de proyecto, contenedor y puerto nuevos en un complemento propio, comprobando antes que no existan. Para otra base vacía en el contenedor, usar un nombre nuevo y **confirmar éxito de createdb antes de ejecutar el esquema**; nunca reutilizar la existente si createdb falló. No ejecutar `down -v` sin revisar y autorizar la pérdida del volumen. Tampoco ejecutar el esquema contra una base con información importante: contiene `DROP SCHEMA ... CASCADE`.

El puerto del equipo distingue ambas bases:

| Uso | Contenedor | Conexión desde el equipo |
|---|---|---|
| Datos originales para comparación | `platano_db` | localhost:5432 |
| Solución creada desde cero | `platano_validacion_db` | localhost:5433 |

En el contenedor corregido, `platano` es la base de trabajo y `platano_final` es la comprobación adicional de instalación vacía con la última versión del esquema. Ambas tienen las mismas entidades y resultados del seed. Para seleccionar esta última con psql se usa `-d platano_final`; con el ejecutor adicional, `--base platano_final`.

Usuario, contraseña y base de desarrollo: `platano`. Dentro del contenedor PostgreSQL escucha en 5432 en ambos casos; `docker exec` no usa el puerto publicado del equipo.

## Cómo guardar y leer una evidencia

Ejemplo ejecutable, con un nombre nuevo para conservar las salidas anteriores:

```powershell
python entregables/ejecutar_evidencia.py revision_publicas_01.txt --sql tests/pruebas_publicas.sql -- docker exec -i platano_validacion_db psql -X -v ON_ERROR_STOP=1 -U platano -d platano -f -
```

El ejecutor lee el archivo en bytes, lo envía a `psql`, combina las salidas estándar y de errores y guarda el texto UTF-8, el comando, el archivo fuente y `EXIT_CODE`. No calcula ni fabrica resultados. Rechaza sobrescribir evidencia existente. El separador `--` distingue sus opciones del comando que ejecutará.

`docker exec -i` permite entrada estándar. `psql -X` evita configuración personal; `-v ON_ERROR_STOP=1` detiene en error SQL; `-U` selecciona usuario; `-d`, base; `-f -`, el SQL enviado. `\echo` imprime etiquetas y `\pset pager off` evita paginación: son órdenes de psql, no sentencias del servidor.

Interpretación:

- `(0 rows)` es éxito cuando se buscan datos prohibidos, pero podría ser un error en un catálogo que debe contener cursos.
- `INSERT 0 3` significa tres filas insertadas; `CREATE TABLE` confirma una tabla creada.
- `NOTICE: OK: ...` es una aserción adicional que cumplió la expectativa.
- Un error de aserción produce `FALLO`, termina `psql` y devuelve código distinto de cero.
- `EXIT_CODE=0` en las públicas **solo significa que el SQL ejecutó**: sus SELECT no lanzan excepciones cuando encuentran defectos. Hay que comparar cada resultado con la etiqueta.
- `ROLLBACK` final descarta los datos de prueba; la evidencia 19 comprueba cero filas sintéticas.

La imagen inicial emite un aviso de autenticación local `trust`, y detiene su servidor temporal antes de arrancar el definitivo. Esos mensajes no indican fallo de carga; los logs muestran `PostgreSQL init process complete` y el servidor disponible. No se atribuyeron errores SQL a esos mensajes normales del arranque.

## Resultados de las pruebas públicas

| Pública | Original | Corregida |
|---|---|---|
| 1. Carnet repetido | `2021010`, dos registros: incumple | Vacía |
| 2. Cédula repetida | `1-1111-1111`, dos registros: incumple | Vacía |
| 3. Par matrícula repetido | Estudiante 9 / grupo 1: incumple | Vacía |
| 4. Créditos menores de uno | Seminario, cero: incumple | Vacía |
| 5. Nota fuera de rango | Vacía; no prueba prevención futura | Vacía; rango además probado por rechazo |
| 6. Autorrequisito | Curso 4 sobre sí mismo: incumple | Vacía |
| 7. Estudiante sin carrera | Karla: incumple | Vacía |
| 8. Cantidad de tablas | 8 | 8 |
| 9. Consulta de referencia con 70 | Incluye Ana; no valida Q7 original | Incluye Ana; Q7 también comprobada |
| 10. Curso sin grupos | Estadística; informativa | Estadística; informativa, conservada |

Antes: [04_publicas_original.txt](evidencias/04_publicas_original.txt). Después definitivo: [29_publicas_definitivas.txt](evidencias/29_publicas_definitivas.txt). Las evidencias 12 y 18 conservan las ejecuciones de etapas anteriores.

## Pruebas adicionales: 104 aserciones aprobadas

Ejecutar con un nombre nuevo de evidencia:

```powershell
python entregables/verificar_reportes.py --contenedor platano_validacion_db --evidencia revision_adicionales_01.txt
```

El ejecutor extrae los doce SELECT de `database/03_queries.sql`, verifica su cantidad, crea doce vistas temporales sobre el SQL real y añade `tests/pruebas_adicionales.sql`. No compara una copia corregida con otra copia. El extractor está diseñado para estos doce SELECT sin punto y coma dentro de literales ni comentarios de bloque; si se cambia ese formato debe revisarse el extractor, no asumir que es un analizador SQL general.

Se ejecuta todo dentro de `BEGIN`/`ROLLBACK`, con `SAVEPOINT` para aislar escenarios. Los datos sintéticos usan ids negativos explícitos y no consumen los `SERIAL` de las tablas del modelo. Un contador **temporal** suma las aserciones aunque se revierta un escenario; se destruye al terminar la conexión. Los intentos inválidos usan un subbloque de excepción y comprueban el SQLSTATE esperado. Un dato inválido aceptado o un error de causa distinta hace fallar el ejecutor.

| Bloque | Cantidad | Qué comprueba y qué espera |
|---|---:|---|
| A y Q01–Q12 | 31 | Conservación de entidades y auditoría; resultados concretos de los doce reportes: 8 cursos, 0 en grupo vacío, Ana aprobada, solo Carlos elegible, créditos 8/10/0, cuatro requisitos |
| B01–B30 | 30 | Rechazo de carnet/cédula/par repetidos, carrera ausente, créditos inválidos, notas fuera del rango/NaN/infinitos (incluye −0.01 y 100.01), autorrequisito, requisito duplicado, estado inválido y nueve FK; también UPDATE |
| C01–C10 | 10 | Homónimos de estudiantes, carreras, cursos y profesores; activo/inactivo; profesor opcional, profesor sin grupos, cursos/grupos vacíos y créditos cero |
| D01–D06 | 6 | 0 y 100 aceptados; 69.9 reprueba; 70 aprueba; `NULL` pendiente; correcta clasificación y créditos |
| E01–E06 | 6 | Retirados con 100 o `NULL` no afectan rendimiento, aprobación, elegibilidad, créditos ni cupo; siguen siendo registros históricos |
| F01–F04 | 4 | Repetir un curso en grupos distintos no repite créditos; otro curso de igual creditaje sí suma; dos requisitos no multiplican créditos |
| G01–G06 | 6 | Uno de dos no basta, pendiente/retirado no basta, ambos con 70 sí, aprobación repetida no duplica elegibilidad; cero requisitos habilita a todos; curso ausente no habilita |
| H01–H06 | 6 | Histórico separado de 2026-1; ambos conteos históricos preservados; ciclo sin matrículas o grupos retorna cero |
| I01–I03 | 3 | Cero matrículas incluidas o solo pendientes: tasa `NULL`, conteos cero/pendientes explícitos, sin división por cero |
| J01–J02 | 2 | Conservación exacta de 69.99 y clasificación como reprobada, sin redondeo a 70 |
| **Total** | **104** | Todas ejecutadas y aprobadas en las dos bases corregidas |

La evidencia [15_pruebas_adicionales.txt](evidencias/15_pruebas_adicionales.txt) contiene 96 aserciones de la primera versión. Después se protegió Q4 frente a ausencia de grupos y matrículas y se añadieron H05/H06; [16_pruebas_adicionales_final.txt](evidencias/16_pruebas_adicionales_final.txt) registra las 98 de esa etapa, antes de encontrar el problema de precisión. Tras corregirlo se añadieron B27–B30 y J01–J02: [27_adicionales_limpio_final.txt](evidencias/27_adicionales_limpio_final.txt) y [28_adicionales_trabajo_final.txt](evidencias/28_adicionales_trabajo_final.txt) registran las **104 definitivas**, con `EXIT_CODE=0`. Se conservan las versiones intermedias para reflejar el desarrollo real.

## Reproducir los defectos originales

Mientras exista la base original, los SELECT originales guardados permiten repetir el diagnóstico sin modificar el SQL corregido:

```powershell
python entregables/verificar_reportes.py --contenedor platano_db --consultas entregables/evidencias/original/03_queries.sql --pruebas tests/casos_limite_original.sql --evidencia revision_original_01.txt
```

Este diagnóstico imprime resultados incorrectos deliberadamente y termina con rollback; no es una batería que deba aprobar con cero hallazgos. Comprueba notas −1/101 aceptadas, retirados aprobados/habilitados/con créditos, cero omitido, histórico mezclado, profesores fusionados y falta de total de créditos. La ejecución inicial real está en evidencia 07. La reproducción con selección explícita del archivo original queda en evidencia 20.

`tests/auditoria_inicial.sql` puede ejecutarse en ambas bases con el ejecutor genérico; muestra restricciones, duplicados, catálogo completo, requisitos y auditoría. Su bloque de multiplicación reproduce **el JOIN heredado**, incluso en la base corregida: no afirma que Q10 corregida todavía lo contenga.

## Inventario de evidencias

| Archivos | Qué demuestran |
|---|---|
| `original/01_schema.sql`, `02_seed.sql`, `03_queries.sql` | Copias originales completas para comparación, con sus datos e instrucciones contradictorias |
| `00_docker_inicial.txt`, `01_docker_arranque.txt` | Motor inicialmente no disponible y luego disponible |
| `02_compose_original.txt`, `03_logs_original.txt` | Volumen original nuevo, carga original de esquema y datos |
| `04_publicas_original.txt`, `05_auditoria_original.txt`, `06_reportes_original.txt` | Incumplimientos y resultados iniciales reales |
| `07_casos_limite_original.txt` | Defectos originales que no evidenciaba el seed |
| `08_base64_decodificado.txt` | Texto decodificado, tratado como dato no normativo |
| `09_config_validacion.txt`, `10_compose_limpio.txt`, `11_logs_limpio.txt` | Configuración aislada, volumen nuevo y scripts corregidos cargados |
| `12_publicas_corregido.txt`, `13_reportes_corregido.txt`, `14_auditoria_corregido.txt` | Primera comprobación corregida |
| `15_pruebas_adicionales.txt`, `16_pruebas_adicionales_final.txt` | 96 y 98 de etapas anteriores a la corrección de precisión |
| `17_reportes_final.txt`, `18_publicas_final.txt` | Doce SELECT y públicas de la etapa de 98 aserciones |
| `19_estado_final.txt` | Primera auditoría completa: conteos intactos, cero residuos, nueve FK y cuatro expedientes históricos sin respaldo |
| `20_reproduccion_original.txt` | Diagnóstico original repetido seleccionando explícitamente el SQL original |
| `21_revision_git.txt` | Primera revisión de Git; algunas tildes mal decodificadas en la captura Python inicial |
| `22_precision_antes.txt` | Redondeo real de −0.01, 100.01 y 69.99 con el tipo heredado, luego rollback |
| `23_crear_base_final.txt`, `24_schema_final_desde_cero.txt`, `25_seed_final_desde_cero.txt` | Base vacía y carga completa de los scripts definitivos, con numeric sin escala fija |
| `26_precision_base_trabajo.txt` | Ampliación sin pérdida de la columna de la base de trabajo a numeric sin escala |
| `27_adicionales_limpio_final.txt`, `28_adicionales_trabajo_final.txt` | 104 aserciones definitivas aprobadas en ambas bases |
| `29_publicas_definitivas.txt`, `30_reportes_definitivos.txt` | Públicas y doce reportes definitivos en la instalación vacía |
| `31_estado_limpio_definitivo.txt`, `32_estado_trabajo_definitivo.txt` | Estado final de ambas bases: sin residuos, tipo numeric y datos preservados |
| `33_revision_git_final.txt` | Revisión definitiva, con captura UTF-8 correcta |
| `MANIFIESTO_SHA256.txt` | Huellas de archivos para vincular código, pruebas y evidencias entregadas |

Las evidencias se leen junto con [CAMBIOS.md](CAMBIOS.md): las cuatro incidencias heredadas son límites declarados, no admisiones históricas supuestamente saneadas. Las pruebas ocultas no están disponibles ni se afirma que se hayan ejecutado.
