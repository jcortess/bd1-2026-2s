# Defensa · Grupo 05 · Huellas Seguras

Participantes del equipo: Jason Madrigal Pineda (G05-P01), María Paula Romero Garro (G05-P02) y Jean Carlos Segura Vargas (G05-P03). Este documento consolida el plan de demostración de los tres integrantes. **Video sin grabar y enlace/minutajes pendientes**: no se inventan participaciones ni grabaciones. El requisito oficial es una grabación sin cortes/edición, con cámara encendida e iluminación adecuada de cada participante.

## Índice preparado para la participación de Paula

| Segmento propuesto, sin minutaje ficticio | Contenido sustantivo y evidencia reproducible |
|---|---|
| Identificación y entorno | Paula identifica nombre, G05-P02, rama grupo-05 y versión usada; ejecutar `pruebas/04_consultas_paula.sql` para version/base/usuario y lecturas. La ejecución actual utilizó PostgreSQL/psql 18.6, UTF-8 y Costa Rica. |
| Decisión relevante del modelo | Mostrar `modelo/Diagrama_Relacional.md`: SOLICITUD_ANIMAL solo expresa interés; COMPATIBILIDAD_ANIMAL_HOGAR valora un animal, hogar concreto de solicitud y etapa, con resultado propio. Explicar por qué APROBADA no equivale a todos compatibles/reservados y cómo una evaluación posterior conserva la anterior. |
| Caso válido y persistencia | Base nueva instalada con `sql/09_instalar_bloque_paula.sql`. Ejecutar `pruebas/02_bloque_paula.sql`, que crea general, agrega dos animales, entrevista, aprobación y dos resultados distintos; comprobar P01–P04 y filas persistidas. Las firmas y acciones están en SQL, no solo en diapositivas. |
| Rechazo y atomicidad | Mostrar P03-interes-no-compatible (P2026), P09-sin-razon (23514/evento_contenido) y P07-atomicidad: segundo animal inexistente después de crear cabecera/recepción/primer detalle; consultar que la clave ...0099 no dejó cabecera ni recepción y los conteos permanecen. Interpretar el error verdadero. |
| Historia y frontera | P05: rechazo y nueva solicitud de la misma persona. R03: registro profesional justo antes de fin es válido, en fin exacto no; peso 0.001 kg aceptado, cero/NaN rechazados. Explicar inicial sin veterinario frente a revisión efectuada completa y sin exigir diagnóstico mínimo. |
| Concurrencia demostrada | Ejecutar preparación y A/B de `pruebas/concurrencia_paula/` siguiendo README. Mostrar observador mientras B espera; liberar A para COMMIT y explicar P2021 sin pérdida de decisión. Repetir ROLLBACK de A y confirmación de B; verificar historia y reintento informado con 06. Son conexiones distintas, no dos llamadas secuenciales. |
| Límites y conexión con el equipo | Mostrar `_exigir_compatibilidad` y la clave contextual propuesta para Jean Carlos; explicar cómo P03 consume la compatibilidad y verifica disponibilidad, restricciones y exclusividad. Las nueve relaciones de Jean Carlos se incorporaron posteriormente. |

## Comandos para ensayo desde una base nueva

Desde la carpeta del grupo, con PostgreSQL de pruebas y otro nombre de base si ya existe:

```sh
createdb -U postgres -T template0 -E UTF8 huellas_g05_defensa_paula
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_defensa_paula -f sql/09_instalar_bloque_paula.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_defensa_paula -f pruebas/02_bloque_paula.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_defensa_paula -f pruebas/03_catalogo_paula.sql -f pruebas/04_consultas_paula.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d huellas_g05_defensa_paula -f pruebas/concurrencia_paula/00_preparacion.sql
```

Abrir A y B con 01/02, observar con 05 y liberar A; después 03/04, observar y liberar A; finalmente 06. Los comandos exactos de las tres terminales y la alternativa Windows/WSL están en [README](README.md#dos-sesiones-concurrentes-de-paula). Para conservar salida de la sesión durante un ensayo puede usarse el cliente psql; no sustituir las consultas persistidas por avisos preparados. No se pide editar ni recortar la grabación oficial.

Después de grabar, el equipo debe completar el índice real y enlazar el video accesible. Paula debe revisar y poder explicar el SQL asistido por IA antes de la defensa; esta intervención no certifica esa revisión humana.


## Apertura y orden propuesto del equipo

Presentar los tres integrantes, la rama `grupo-05`, el alcance de G05-P01 a G05-P03 y el inventario de 28 tablas (27 originales y compatibilidad animal–hogar). Mostrar el diagrama, la matriz y la instalación completa. Identificar el entorno real de grabación con `SELECT version(), current_database(), current_user;` y `SHOW TimeZone;`. No atribuir a la grabación los resultados de ensayos anteriores.

## Participación de Jason · G05-P01

| Segmento | Demostración |
|---|---|
| Modelo | Mostrar INGRESO, ESTANCIA, UBICACION y las claves de contexto; explicar actores y oferta histórica. |
| Caso válido | Ejecutar `pruebas/01_bloque_jason.sql` en una base preparada para Jason; consultar `ubicacion_actual`, `historial_alojamiento` y `ocupacion_actual`. |
| Rechazo y atomicidad | Explicar el rechazo por cupo o estancia esperada incorrecta y comprobar que el origen no se pierde. |
| Concurrencia | Preparar `pruebas/concurrencia/00_preparacion.sql`; ejecutar A/B de cupo (01/02), observar con 05 y `-v caso=cupo`, confirmar A y comprobar P1014. Repetir con 03/04 y `-v caso=animal`, comprobar P1006. Ejecutar 06 al terminar ambas carreras. |
| Integración | Explicar `_bloquear_alojamiento()` y `_cerrar_etapa_alojamiento()` como primitivas privadas reutilizadas por P03. |

Usar los comandos del [README](README.md) para instalar el bloque aislado de Jason y reproducir sus carreras. No mezclar datos de las suites de distintos integrantes en una misma base sin una preparación comprobada.

## Participación de Jean Carlos · G05-P03

| Segmento | Demostración y resultado esperado |
|---|---|
| Instalación | Ejecutar `sql/15_instalar_proyecto_completo.sql` en una base nueva; comprobar las 28 tablas. |
| Modelo | Mostrar RESERVA, ADOPCION, ADOPCION_RESPONSABLE, INGRESO y ESTANCIA; explicar FK contextuales, índice único parcial y compatibilidad consumida. |
| Reserva y adopción | Ejecutar preparación 05 y pruebas 09. Explicar PJ-01, PJ-02, PJ-04, PJ-05, PJ-06, PJ-07 y PJ-08; consultar `huellas.v_control_adopciones_jeank` después de confirmar. |
| Restricción y devolución | Ejecutar 06, 10 y 07 en ese orden. Explicar PJ-03 y PJ-09: restricción documentada rechaza reserva; devolución voluntaria permite nuevo ingreso sin sanción automática. |
| Clínica y seguimiento | Ejecutar 11; explicar PC-06 (FK contextual, 23503), PC-07 (vínculo válido), seguimientos PS-01 a PS-05 y PP-01 (42501). Las aplicaciones PC-01 a PC-05 se demuestran en 09. |
| Atomicidad | Ejecutar 08 y 12; mostrar PJ-11, rechazo P1006 por estancia incorrecta, estado posterior sin efectos parciales y reintento válido. |
| Concurrencia | En otra base nueva, preparar 05 y ejecutar las sesiones independientes descritas abajo. Mostrar espera real, rechazo P3021 y una sola reserva vigente. |
| Límites | Distinguir 25 casos identificados de cobertura exhaustiva; explicar los escenarios sin evidencia aislada señalados en la matriz. |

### Comandos de ensayo de Jean Carlos (PowerShell)

Desde `final-project/grupo-05`, con PostgreSQL 16 disponible. Elegir nombres nuevos si existen estas bases. No borrar bases anteriores.

```powershell
$pg = 'C:\Program Files\PostgreSQL\16\bin'
$base = 'huellas_g05_defensa_jeank'
& "$pg\createdb.exe" -U postgres -T template0 -E UTF8 $base
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f sql/15_instalar_proyecto_completo.sql
foreach ($archivo in @('05_preparacion_jeank','09_bloque_jeank','06_preparacion_concurrencia_jeank','10_pruebas_complementarias_jeank','07_devolucion_jeank','11_integridad_final_jeank','08_preparacion_dos_sesiones_jeank','12_atomicidad_jeank')) {
    & "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -P pager=off -U postgres -d $base -f "pruebas/$archivo.sql"
    if ($LASTEXITCODE -ne 0) { throw "Fallo inesperado: $archivo" }
}
& "$pg\psql.exe" -X -U postgres -d $base -c 'SELECT * FROM huellas.v_control_adopciones_jeank;'
```

### Concurrencia de reservas

Preparar una base distinta:

```powershell
$base = 'huellas_g05_defensa_concurrencia'
& "$pg\createdb.exe" -U postgres -T template0 -E UTF8 $base
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f sql/15_instalar_proyecto_completo.sql
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f pruebas/05_preparacion_jeank.sql
```

En cada terminal definir la misma ruta `$pg` y base `$base`, y ubicarse en la carpeta del grupo.

```powershell
# Terminal A: esperar la pausa sin pulsar Intro
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f pruebas/concurrencia_jeank/01_reserva_a.sql
# Terminal B: ejecutar mientras A sigue abierta
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f pruebas/concurrencia_jeank/02_reserva_b.sql
# Terminal observadora
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f pruebas/concurrencia_jeank/03_espera.sql
```

Mostrar `Lock/advisory` y `a_bloquea_b=t`. Pulsar Intro en A para confirmar. Esperar el rechazo esperado P3021 y ROLLBACK de B. Solo entonces ejecutar en una conexión nueva:

```powershell
& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -U postgres -d $base -f pruebas/concurrencia_jeank/04_verificar.sql
```

Explicar por qué ambas compatibilidades favorables permanecen, pero solo una familia conserva la reserva. Referencias: [Resultados](evidencias/Resultados_Jeank.md), [Concurrencia](evidencias/Ejecucion_Jeank_Concurrencia.md), [Ejecución secuencial](evidencias/Ejecucion_Jeank_Secuencial.md), [Instalación](evidencias/Ejecucion_Jeank_Instalacion.md).

## Índice definitivo del video

Completar después de grabar; el orden siguiente es una propuesta, no un registro de participación efectiva.

| Segmento | Participante | Inicio real |
|---|---|---|
| Identificación, entorno y modelo | Equipo | Pendiente |
| G05-P01 | Jason | Pendiente |
| G05-P02 | Paula | Pendiente |
| G05-P03 e integración | Jean Carlos | Pendiente |
| Conclusiones y límites | Equipo | Pendiente |
