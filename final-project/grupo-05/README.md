# Huellas Seguras · Grupo 05

IC-4301 Bases de Datos I · Segunda entrega · Bloque de Jason, versión 0.1.

| Integrante | Responsabilidad de la segunda entrega |
|---|---|
| Jason Madrigal Pineda | G05-P01, personas, animales, etapas, alojamiento e instalación |
| María Paula Romero Garro | G05-P02, reportes, evaluaciones y diagnósticos, solicitudes y compatibilidad |
| Jean Carlos Segura Vargas | G05-P03, indicaciones y aplicaciones, reserva, adopción y cierre |

El bloque instalable contiene las nueve relaciones de Jason, asignación y traslado, historial, ocupación, pruebas y el contrato para integrar la adopción. El inventario general tiene 27 relaciones de partida. El registro de un regreso posterior a una adopción queda bloqueado hasta contar con la tabla y la referencia compuesta que valida su origen. El estado del resto del modelo y de los procesos se detalla en [Integración](Integracion.md).

## Instalación en una base nueva

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
- [Cobertura de las 27 relaciones e integración](Integracion.md)
- [Aporte a Control de Cambios](Control_de_Cambios.md) y [aporte a Uso de IA](Uso_de_IA.md)
- [Enunciado general](../README.md) y [anexo del Grupo 05](05_Grupo_05_Refugio.md)
