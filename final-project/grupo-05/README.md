# Huellas Seguras · Grupo 05

IC-4301 Bases de Datos I · Segunda entrega · Consolidación integrada 2.0.

| Integrante | Responsabilidad de la segunda entrega |
|---|---|
| Jason Madrigal Pineda | G05-P01, personas, animales, etapas, alojamiento e instalación |
| María Paula Romero Garro | G05-P02, reportes, evaluaciones y diagnósticos, solicitudes y compatibilidad |
| Jean Carlos Segura Vargas | G05-P03, indicaciones y aplicaciones, reserva, adopción y cierre |

**Estado integrado 2.0 (28 de noviembre de 2026):** 28 tablas físicas: nueve de Jason, diez de Paula (incluida la ampliación de compatibilidad) y nueve de Jean Carlos. Se conservan las 27 relaciones originales de P1. Los tres procesos están implementados; la FK contextual de adopción de origen sustituye el bloqueo provisional de reingreso. La cobertura de pruebas y sus límites se detallan en la [matriz de integridad](modelo/Matriz_Integridad.md) y en [Integración](Integracion.md).

## Instalación completa recomendada

Validada con PostgreSQL y psql 16.16 en Windows, base UTF-8, extensión `btree_gist` y zona `America/Costa_Rica`. Desde `final-project/grupo-05`, en PowerShell, elegir un nombre de base nuevo y libre. No eliminar bases existentes. El instalador requiere permisos de creación de base, rol y extensión.

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
$base = 'huellas_g05_completo_demo'
& "$pg\createdb.exe" -U postgres -T template0 -E UTF8 $base
& "$pg\psql.exe" -X -U postgres -d $base -c 'SELECT version();'
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f sql/15_instalar_proyecto_completo.sql
```

El instalador 15 invoca 09 (Jason y Paula) y 14 (Jean Carlos), y comprueba las 28 tablas. No ejecutar nuevamente los instaladores parciales ni `sql/integracion/01_adopcion_origen.sql` sobre esta base. Los antecedentes son ficticios. Las instrucciones históricas siguientes permiten reproducir los bloques aislados; utilizar bases independientes para evitar interferencias entre sus datos de prueba.

## Instalación histórica del bloque de Jason en una base nueva

Se probó PostgreSQL **16.15** con `psql` **16.15**, base UTF-8 y extensión `btree_gist`. Las fechas de las demostraciones se muestran en `America/Costa_Rica`. Se necesita un usuario instalador con permisos para crear la base, instalar la extensión y crear el rol `huellas_g05_operador` si aún no existe. Los comandos usan el administrador de la instancia de prueba.

| Orden | Archivo | Efecto |
|---|---|---|
| 1 | [01_esquema.sql](sql/01_esquema.sql) | Crea el esquema `huellas`, el rol, las nueve tablas y sus restricciones. |
| 2 | [02_operaciones.sql](sql/02_operaciones.sql) | Instala la operación de movimiento, protecciones y permisos. |
| 3 | [03_datos.sql](sql/03_datos.sql) | Registra antecedentes ficticios y deja las estancias vacías. |
| 4 | [04_consultas.sql](sql/04_consultas.sql) | Instala tres vistas y muestra el estado inicial. Puede volverse a ejecutar como propietario. |
| 5 | [01_bloque_jason.sql](pruebas/01_bloque_jason.sql) | Ejecuta movimientos, confirma y consulta efectos. Revierte las pruebas de integridad que modifican antecedentes. |
| 6 | [pruebas/concurrencia](pruebas/concurrencia) | Ejecuta la preparación, las dos carreras y la comprobación final indicadas abajo. |

### PostgreSQL local

Desde `final-project/grupo-05`, con la conexión configurada para una instancia de pruebas. Para repetir, elija otro nombre libre y úselo en todos los comandos y sesiones. Cada archivo está preparado para detenerse con el primer error inesperado.

```sh
createdb -U postgres -E UTF8 -T template0 huellas_g05_jason_demo
psql -X -U postgres -d huellas_g05_jason_demo -c 'SELECT version();'
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_jason_demo -f sql/01_esquema.sql -f sql/02_operaciones.sql -f sql/03_datos.sql -f sql/04_consultas.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_jason_demo -f pruebas/01_bloque_jason.sql
```

### Docker Desktop y PowerShell

Desde la raíz del repositorio. Este ejemplo crea un contenedor aislado sin publicar puertos, con autenticación local de demostración. En cada repetición elija un nombre de base nuevo. Si el contenedor ya existe, conserve su volumen y ejecute desde `pg_isready` con otro nombre de base.

```powershell
$grupo = (Resolve-Path '.\final-project\grupo-05').Path
$cont = 'huellas-g05-demo'
$base = 'huellas_g05_jason_demo'
docker run -d --name $cont -e POSTGRES_HOST_AUTH_METHOD=trust postgres@sha256:0cefaabd882e42bcb2a2f3dc56d3ce4770560ba62fd7f197f1a2e008fd5731ab
docker exec $cont pg_isready -U postgres
```

Espere `accepting connections`. El manifiesto identifica la imagen usada en la ejecución. Confirme la versión con `SELECT version()`.

```powershell
docker exec $cont mkdir -p /entrega-g05
docker cp "${grupo}/." "${cont}:/entrega-g05"
docker exec $cont createdb -U postgres -E UTF8 -T template0 $base
docker exec $cont psql -X -U postgres -d $base -c 'SELECT version();'
docker exec $cont psql -X -v ON_ERROR_STOP=1 -U postgres -d $base -f /entrega-g05/sql/01_esquema.sql -f /entrega-g05/sql/02_operaciones.sql -f /entrega-g05/sql/03_datos.sql -f /entrega-g05/sql/04_consultas.sql
docker exec $cont psql -X -v ON_ERROR_STOP=1 -U postgres -d $base -f /entrega-g05/pruebas/01_bloque_jason.sql
```

Al terminar la carga inicial, `ubicacion_actual` e `historial_alojamiento` devuelven cero filas. Tras las pruebas, consulte el ingreso, la hora, la ubicación y el actor de cada movimiento. Las pruebas confirman estados de demostración, por lo que para repetirlas se instala otra base vacía. Cada negativa comprueba su SQLSTATE y, cuando aplica, el nombre de la restricción. Los bloques capturan los rechazos previstos y revierten sus efectos. Un error inesperado hace que `psql` termine con error.

## Repetir las dos carreras

Use tres terminales en la misma base. En Docker, defina `$cont` y `$base` con los mismos valores en cada terminal. Use el instalador para la lectura de `pg_stat_activity`. Cada guion de escritura cambia al rol operativo en su transacción.

1. Corra [00_preparacion.sql](pruebas/concurrencia/00_preparacion.sql) una vez. Debe verse HS-13 en atención externa y ocupación cero en las ubicaciones 7, 8 y 9.
2. En la terminal A ejecute [01_cupo_a.sql](pruebas/concurrencia/01_cupo_a.sql). Espere al mensaje de pausa, que indica que A tomó el cupo y sigue sin confirmar.
3. En la terminal B ejecute [02_cupo_b.sql](pruebas/concurrencia/02_cupo_b.sql). Desde la tercera terminal use [05_espera.sql](pruebas/concurrencia/05_espera.sql) con `-v caso=cupo`. Espere `wait_event=advisory` y `a_bloquea_b=t`. Pulse Intro en A. B debe terminar con el rechazo controlado `P1014`.
4. Repita la intercalación con [03_animal_a.sql](pruebas/concurrencia/03_animal_a.sql) y [04_animal_b.sql](pruebas/concurrencia/04_animal_b.sql), ahora con `-v caso=animal`. Después de confirmar A, B debe terminar con `P1006`.
5. En una conexión nueva ejecute [06_verificar.sql](pruebas/concurrencia/06_verificar.sql). Comprueba los vínculos, las ocupaciones y que B no dejó estancias. Los PID cambian entre ejecuciones.

Ejemplos de invocación en Docker para la primera carrera. Con instalación local use `psql` directamente y sustituya `/entrega-g05/` por el directorio de trabajo.

```powershell
# Preparación
docker exec $cont psql -X -U postgres -d $base -f /entrega-g05/pruebas/concurrencia/00_preparacion.sql
# Terminal A
docker exec -it $cont psql -X -U postgres -d $base -f /entrega-g05/pruebas/concurrencia/01_cupo_a.sql
# Terminal B
docker exec $cont psql -X -U postgres -d $base -f /entrega-g05/pruebas/concurrencia/02_cupo_b.sql
# Tercera terminal
docker exec $cont psql -X -U postgres -d $base -v caso=cupo -f /entrega-g05/pruebas/concurrencia/05_espera.sql
# Verificación después de ambas carreras
docker exec $cont psql -X -U postgres -d $base -f /entrega-g05/pruebas/concurrencia/06_verificar.sql
```

Los resultados con fechas, IDs y observación de bloqueos están en [Evidencia de ejecución](evidencias/Resultados_Jason.md). La firma y los ejemplos para usar la base están en [G05-P01](Procesos_Negocio.md).

## Documentación del bloque

- [Modelo, diccionario y decisiones](modelo/Modelo_Jason.md)
- [Matriz de integridad](modelo/Matriz_Jason.md)
- [Cobertura de las 28 tablas e integración](Integracion.md)
- [Aporte a Control de Cambios](Control_de_Cambios.md) y [aporte a Uso de IA](Uso_de_IA.md)
- [Enunciado general](../README.md) y [anexo del Grupo 05](05_Grupo_05_Refugio.md)

## Bloque de Paula G05-P02

Reportes, evaluaciones y diagnósticos, disponibilidad atribuible, solicitudes, actividades, decisiones y compatibilidad individual animal–hogar. No se agregan procesos médicos ni una implementación sustituta de P03. Se probó la instalación conjunta con PostgreSQL **18.6** y `psql` **18.6** (Ubuntu/WSL, UTF-8, `btree_gist`); los resultados anteriores de Jason con 16.15 se conservan como tales. No se presume que se probó esta ampliación en 16.15. Se necesita instalador con permisos de crear base/rol/extensión. El operador operativo usa `huellas_g05_operador` sin DML directo.

Desde `final-project/grupo-05`, en una instancia destinada a pruebas, elegir un nombre nuevo para cada ejecución y no borrar bases preexistentes:

```sh
createdb -U postgres -T template0 -E UTF8 huellas_g05_paula_demo
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f sql/09_instalar_bloque_paula.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f pruebas/02_bloque_paula.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f pruebas/03_catalogo_paula.sql -f pruebas/04_consultas_paula.sql
```

`09` es un guion psql (`\ir`) que resuelve rutas respecto de sí mismo y ejecuta los ocho archivos de instalación. No ejecutar además los mismos scripts sobre la base ya cargada. Los cinco archivos SQL de Jason se conservan intactos; los de Paula se agregan en el siguiente orden:

| Orden de instalación | Archivo | Propósito |
|---|---|---|
| 1–4 | `sql/01_esquema.sql` a `sql/04_consultas.sql` | Bloque existente de Jason: esquema, operaciones, antecedentes y vistas. |
| 5 | [05_paula_esquema.sql](sql/05_paula_esquema.sql) | Nueve relaciones y ampliación de compatibilidad, claves, dominios y contexto. |
| 6 | [06_paula_operaciones.sql](sql/06_paula_operaciones.sql) | Operaciones públicas, historia, controles de contexto/atribución y permisos. |
| 7 | [07_paula_datos.sql](sql/07_paula_datos.sql) | Antecedentes ficticios de reportes/salud/disponibilidad. Cero solicitudes/compatibilidades precargadas. |
| 8 | [08_paula_consultas.sql](sql/08_paula_consultas.sql) | Vistas, validación de iniciales y consumo privado para P03. |

La semilla de Paula requiere las personas/animales/ingresos de `03_datos.sql`; no duplica sus tablas. Los INSERT de antecedentes no resuelven solicitudes. El guion de pruebas sí ejecuta las operaciones que producen sus resultados. Las pruebas negativas capturan SQLSTATE y, cuando aplica, la restricción exacta. Las transacciones reversibles consultan antes de ROLLBACK y P15 comprueba después los datos confirmados. Ante un error inesperado, psql termina con error y la conexión revierte su transacción abierta; para repetir el conjunto completo usar otra base nueva.

### Reproducción en este entorno Windows/WSL

La ejecución real utilizó Ubuntu en WSL, con PostgreSQL 18.6 ya disponible al ejecutar los guiones. Docker Desktop estaba detenido, por lo que las evidencias nuevas no se atribuyen a Docker. Este ejemplo usa una base nueva; no elimina la de ninguna ejecución anterior. En PowerShell:

```powershell
$rutaGrupo = (Get-Location).Path.Replace('\','/').Replace('C:','/mnt/c')
$basePaula = 'huellas_g05_paula_demo'
wsl -d Ubuntu -u root -- runuser -u postgres -- createdb -T template0 -E UTF8 $basePaula
wsl -d Ubuntu -u root -- runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -d $basePaula -f "$rutaGrupo/sql/09_instalar_bloque_paula.sql"
wsl -d Ubuntu -u root -- runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -d $basePaula -f "$rutaGrupo/pruebas/02_bloque_paula.sql"
wsl -d Ubuntu -u root -- runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -d $basePaula -f "$rutaGrupo/pruebas/03_catalogo_paula.sql" -f "$rutaGrupo/pruebas/04_consultas_paula.sql"
```

Si PostgreSQL no está iniciado en esa instancia WSL: `wsl -d Ubuntu -u root -- pg_ctlcluster 18 main start`. No iniciar/reconfigurar un clúster ajeno para reproducir estas pruebas. Como alternativa, en una instancia Docker de pruebas en ejecución usar los comandos del apartado original, cambiando a `sql/09_instalar_bloque_paula.sql` y los guiones de Paula; esa alternativa no constituye una ejecución nueva documentada aquí.

### Dos sesiones concurrentes de Paula

En la misma base instalada, desde tres terminales psql distintas. Los guiones usan BEGIN/COMMIT o ROLLBACK y cambian al rol operativo. No lanzar B después de confirmar A: debe estar esperando mientras A mantiene su transacción. Con WSL usar el prefijo del ejemplo anterior; con psql local ejecutar:

```sh
# Preparación, una sola vez
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f pruebas/concurrencia_paula/00_preparacion.sql
# Terminal A: esperar PAULA_A_LISTA; no pulsar Intro aún
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f pruebas/concurrencia_paula/01_commit_a.sql
# Terminal B: se bloqueará hasta que se libere A
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f pruebas/concurrencia_paula/02_commit_b.sql
# Tercera terminal: observar Lock/advisory, bloqueadores y a_bloquea_b=t; después pulsar Intro en A
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_paula_demo -f pruebas/concurrencia_paula/05_espera.sql
```

Después repetir con `03_rollback_a.sql` en A y `04_rollback_b.sql` en B, usando el mismo observador. Al liberar A, esta vez A revierte y B confirma. Por último ejecutar `06_verificar.sql` en una conexión nueva; comprueba ausencia de efectos perdidos/duplicados, reenvío ciego y nueva decisión informada. Este último guion registra una decisión nueva de comprobación y se ejecuta una sola vez. Los UUID de preparación son fijos, por lo que para repetir las carreras se elige otra base, no se borran sus historias.

Los scripts no incorporan pausas cronometradas que pretendan demostrar el bloqueo; A permanece en `\prompt` hasta que el observador lo compruebe. [Transcripción de las dos carreras](evidencias/Ejecucion_Paula_Concurrencia.md).

### Documentación y límites actuales

- [Resultados, errores corregidos y estado de la entrega de Paula](evidencias/Resultados_Paula.md).
- [Modelo consolidado e inventario de las 28 tablas](modelo/Modelo_Relacional.md), [diccionario](modelo/Diccionario_Datos.md), [diagrama Mermaid](modelo/Diagrama_Relacional.md) y [matriz de integridad](modelo/Matriz_Integridad.md).
- [Conciliación y fuentes](modelo/Conciliacion_Paula.md), [casos individuales](pruebas/Casos_Paula.md), [operaciones y concurrencia](Procesos_Negocio.md) y [contrato de integración](Integracion.md#contrato-de-paula-para-jean-carlos).
- [Aporte a defensa](Defensa.md), [control de cambios](Control_de_Cambios.md) y [uso transparente de IA](Uso_de_IA.md).

La integración posterior de P03 incorpora las nueve tablas, la corrección A2 y el reingreso contextual. La evidencia histórica de P02 se conserva; el conteo específico de RESERVA antes y después de aprobar una solicitud todavía requiere prueba directa en la instalación integrada.

## Bloque de Jean Carlos G05-P03

| Archivo | Propósito |
|---|---|
| [10_jeank_esquema.sql](sql/10_jeank_esquema.sql) | Nueve tablas, claves, restricciones e índices. |
| [11_jeank_operaciones.sql](sql/11_jeank_operaciones.sql) | Validaciones, operaciones públicas, permisos, FK de reingreso y cierre atómico. |
| [12_jeank_datos.sql](sql/12_jeank_datos.sql) | Antecedentes clínicos y restricción ficticia. |
| [13_jeank_consultas.sql](sql/13_jeank_consultas.sql) | Vistas de consulta y control de adopciones. |
| [14_instalar_bloque_jeank.sql](sql/14_instalar_bloque_jeank.sql) | Instalación del bloque sobre Jason y Paula. |
| [15_instalar_proyecto_completo.sql](sql/15_instalar_proyecto_completo.sql) | Instalación integrada desde base vacía. |

### Pruebas secuenciales y atomicidad

En una base recién instalada mediante 15, ejecutar en el siguiente orden. No combinar con las pruebas históricas de otros bloques en esa misma base. Detenerse ante cualquier error inesperado.

```powershell
foreach ($n in @('05_preparacion_jeank','09_bloque_jeank','06_preparacion_concurrencia_jeank','10_pruebas_complementarias_jeank','07_devolucion_jeank','11_integridad_final_jeank','08_preparacion_dos_sesiones_jeank','12_atomicidad_jeank')) {
    & "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -P pager=off -U postgres -d $base -f "pruebas/$n.sql"
    if ($LASTEXITCODE -ne 0) { throw "Error inesperado en $n" }
}
```

El orden conserva las dependencias de capacidad, adopción y devolución. Los casos comprueban reservas, formalización, rechazo de contexto ajeno, restricción vigente, devolución sin prohibición automática, aplicaciones clínicas, seguimiento, permisos y ausencia de efectos parciales ante una estancia incorrecta. Los resultados se verifican después de confirmar o revertir las transacciones.

### Concurrencia de reservas (PJ-10)

Crear otra base nueva mediante las instrucciones de instalación completa, usando por ejemplo `huellas_g05_concurrencia_demo` como `$base`. Ejecutar únicamente `pruebas/05_preparacion_jeank.sql` antes de la carrera. En tres terminales PowerShell, desde el directorio del grupo, definir el mismo `$pg` y `$base`.

```powershell
# Terminal A: esperar la pausa sin confirmar
& "$pg\psql.exe" -X -U postgres -d $base -f pruebas/concurrencia_jeank/01_reserva_a.sql
# Terminal B: ejecutar mientras A sigue abierta
& "$pg\psql.exe" -X -U postgres -d $base -f pruebas/concurrencia_jeank/02_reserva_b.sql
# Observador: comprobar bloqueo asesor y a_bloquea_b=t
& "$pg\psql.exe" -X -U postgres -d $base -f pruebas/concurrencia_jeank/03_espera.sql
```

Después de observar el bloqueo, pulsar Intro en A para confirmar. B debe rechazar la segunda reserva con P3021 y revertir. Solo después de que ambas sesiones terminen, ejecutar:

```powershell
& "$pg\psql.exe" -X -U postgres -d $base -f pruebas/concurrencia_jeank/04_verificar.sql
```

Debe quedar una reserva vigente para HS-01 y conservarse las dos compatibilidades favorables.

### Evidencias y alcance

- [Casos de prueba](pruebas/Casos_Jeank.md) y [resultados](evidencias/Resultados_Jeank.md).
- [Ejecución secuencial](evidencias/Ejecucion_Jeank_Secuencial.md), [concurrencia](evidencias/Ejecucion_Jeank_Concurrencia.md) e [instalación](evidencias/Ejecucion_Jeank_Instalacion.md).
- [Modelo](modelo/Modelo_Relacional.md), [diccionario](modelo/Diccionario_Datos.md), [diagrama](modelo/Diagrama_Relacional.md) y [matriz](modelo/Matriz_Integridad.md).

 Los 33 casos identificados del bloque incluyen instalación, concurrencia y cobertura adicional. Todos fueron ejecutados satisfactoriamente. No constituyen cobertura exhaustiva de todas las restricciones; consultar los límites explícitos de la matriz de integridad. El índice y enlace del video se documentan en [Defensa](Defensa.md) cuando estén disponibles.

### Pruebas adicionales de cobertura

En una base de datos independiente, ejecutar los siguientes archivos en orden:

1. `sql/15_instalar_proyecto_completo.sql`
2. `pruebas/05_preparacion_jeank.sql`
3. `pruebas/09_bloque_jeank.sql`
4. `pruebas/06_preparacion_concurrencia_jeank.sql`
5. `pruebas/07_devolucion_jeank.sql`
6. `pruebas/13_cobertura_adicional_jeank.sql`

Los resultados se documentan en [Ejecución de cobertura adicional](evidencias/Ejecucion_Jeank_Cobertura.md).
