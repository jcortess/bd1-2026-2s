# Defensa · Grupo 05 · aporte técnico de Paula

Participantes del equipo: Jason Madrigal Pineda (G05-P01), María Paula Romero Garro (G05-P02) y Jean Carlos Segura Vargas (G05-P03). Este documento deja listo el aporte de Paula para la consolidación de Jean Carlos. **Video sin grabar y enlace/minutajes pendientes**: no se inventan participaciones ni grabaciones. El requisito oficial es una grabación sin cortes/edición, con cámara encendida e iluminación adecuada de cada participante.

## Índice preparado para la participación de Paula

| Segmento propuesto, sin minutaje ficticio | Contenido sustantivo y evidencia reproducible |
|---|---|
| Identificación y entorno | Paula identifica nombre, G05-P02, rama grupo-05 y versión usada; ejecutar `pruebas/04_consultas_paula.sql` para version/base/usuario y lecturas. La ejecución actual utilizó PostgreSQL/psql 18.6, UTF-8 y Costa Rica. |
| Decisión relevante del modelo | Mostrar `modelo/Diagrama_Relacional.md`: SOLICITUD_ANIMAL solo expresa interés; COMPATIBILIDAD_ANIMAL_HOGAR valora un animal, hogar concreto de solicitud y etapa, con resultado propio. Explicar por qué APROBADA no equivale a todos compatibles/reservados y cómo una evaluación posterior conserva la anterior. |
| Caso válido y persistencia | Base nueva instalada con `sql/09_instalar_bloque_paula.sql`. Ejecutar `pruebas/02_bloque_paula.sql`, que crea general, agrega dos animales, entrevista, aprobación y dos resultados distintos; comprobar P01–P04 y filas persistidas. Las firmas y acciones están en SQL, no solo en diapositivas. |
| Rechazo y atomicidad | Mostrar P03-interes-no-compatible (P2026), P09-sin-razon (23514/evento_contenido) y P07-atomicidad: segundo animal inexistente después de crear cabecera/recepción/primer detalle; consultar que la clave ...0099 no dejó cabecera ni recepción y los conteos permanecen. Interpretar el error verdadero. |
| Historia y frontera | P05: rechazo y nueva solicitud de la misma persona. R03: registro profesional justo antes de fin es válido, en fin exacto no; peso 0.001 kg aceptado, cero/NaN rechazados. Explicar inicial sin veterinario frente a revisión efectuada completa y sin exigir diagnóstico mínimo. |
| Concurrencia demostrada | Ejecutar preparación y A/B de `pruebas/concurrencia_paula/` siguiendo README. Mostrar observador mientras B espera; liberar A para COMMIT y explicar P2021 sin pérdida de decisión. Repetir ROLLBACK de A y confirmación de B; verificar historia y reintento informado con 06. Son conexiones distintas, no dos llamadas secuenciales. |
| Límites y conexión con el equipo | Mostrar `_exigir_compatibilidad` y la clave contextual propuesta para Jean Carlos; explicar disponibilidad/restricciones/exclusividad todavía responsabilidad de P03. Las nueve relaciones pendientes no están implementadas por Paula. |

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

Jean Carlos debe incorporar su segmento y el de Jason, ordenar el índice real con minutajes después de grabar y enlazar el video accesible desde este archivo o README. Paula debe revisar y poder explicar el SQL asistido por IA antes de la defensa; esta intervención no certifica esa revisión humana.
