# Evidencia ejecutada · Bloque de Jason

El 19 de noviembre de 2026 se ejecutó la instalación en la base nueva `huellas_g05_jason_final`, en un contenedor aislado de Docker Desktop. `SELECT version()` devolvió PostgreSQL 16.15 sobre x86_64 Linux musl (Alpine). La codificación del servidor fue UTF-8. Se usó `psql -X` 16.15 y se mostraron los instantes en Costa Rica. Terminaron correctamente el esquema, las operaciones, los datos, las vistas, el guion secuencial y la comprobación final de las dos carreras. La semilla cargó 17 animales y 17 ingresos, con cero estancias. [Reproducción](../README.md)

## G05-P01 · Operaciones y lecturas después de confirmar

El [guion secuencial](../pruebas/01_bloque_jason.sql) contiene la preparación, las llamadas, los errores esperados y las aserciones en el mismo orden de ejecución. Cada grupo de movimientos termina con `COMMIT` y vuelve a leer filas y vínculos. En las negativas, una subtransacción exige el SQLSTATE indicado y propaga cualquier error inesperado.

| Casos y regla | Preparación, acción y esperado | Observado en la ejecución |
|---|---|---|
| M01–M03 · AC-01/02, RN-05/06 | Sala 1 vacía, capacidad 2. Asignar HS-01 al iniciar el ingreso y HS-02 después. Rechazar un tercero por cupo, la condición `AISLAMIENTO` en convivencia, la llegada anterior al ingreso y un alta retroactiva que saturaría la sala cuando entra HS-02. | Quedaron las estancias 1 y 2 ligadas a los ingresos 1 y 2, con actor 1. Sala 1 quedó 2/2 tras confirmar. Rechazos por cupo `P1014`, condición `P1010`, ingreso `P1005` y cupo histórico `P1014`. No se creó estancia para el tercero. |
| M04–M05 · AC-01/03, RN-05/07/14 | HS-01 está en sala 1. Repetir asignación, omitir valoración en traslado y mover al hogar pendiente con fechas y especie válidas. Este último intento alcanza la validación de aprobación después del `UPDATE` de cierre. La estancia anterior debe seguir abierta. | `P1006`, `P1008` y `P1012`. Después de `COMMIT`, el ingreso 1 tenía solo la estancia 1, en ubicación 1, sin fecha ni actor de salida. El hogar pendiente seguía vacío. |
| M06 · AC-01/02, RN-05/07/08/14 | Trasladar HS-01 a Casa A justo al inicio de la oferta, con plan hasta el límite, aprobación vigente, acuerdo y valoración. Asignar a HS-16 el cupo liberado en la sala exactamente a la misma hora. | Sala cerrada el 05-10 a las 00:00 por el actor 7. Estancia 3 abierta en el hogar 2, con oferente 2, aprobación 2, actor 7, plan y textos de acuerdo y valoración. HS-16 ocupó el cupo en ese mismo instante. |
| M07–M08 · AC-02, RN-06/07/08 | Con Casa A ocupada, intentar alojar un gato, presentar un hogar sin catálogo de especies, exceder el cupo, llegar un microsegundo antes de la oferta y llegar al final exacto. Probar salida prevista fuera del periodo, omisión del plan y otra oferta del mismo hogar todavía físicamente ocupado. | Especie y catálogo ausente `P1013`. Exceso de cupo y otra oferta del hogar ocupado `P1014`. Llegadas fuera, plan fuera y plan ausente `P1011`. Se conservó la estancia 3 con ocupación 1/1 y no se creó ninguna estancia para los ingresos rechazados. |
| M09 · AC-02, RN-07/09 | Probar una participación que termina a las 10:00 y otra aprobación concedida a las 10:00. En el instante exacto deben fallar ambas. Aceptar un microsegundo antes del fin y un microsegundo después de la aprobación respectivamente. | Ambos intentos en el límite devolvieron `P1012`. La hora anterior registró HS-05 con aprobación 4. La hora posterior registró HS-06 con aprobación 6. |
| M10–M11 · AC-01/02, RN-05/07/08/14 | Rechazar un traslado que dejaría una estancia de duración cero. Sacar a HS-01 de Casa A justo al final de la primera oferta y ocupar el cupo de la segunda oferta con HS-04 a la misma hora. Incorporar otros animales a atención externa y conservar una salida real de hogar un microsegundo tarde. | Duración cero `P1005`. Historial de HS-01 con tres filas. Casa A conservó oferente 2 y aprobación 2 en la primera oferta y oferente 5 y aprobación 5 en la segunda. La estancia 8 quedó marcada `rebasa_oferta=true`. Ubicación externa 3 registró tres animales con capacidad y saldo nulos. |

Extracto de la lectura final del guion secuencial. `—` representa SQL `NULL`. Los instantes son de octubre de 2026.

| Estancia | Animal / ingreso | Ubicación | Inicio real | Fin real | Oferente / aprobación | Actor entrada / salida |
|---:|---|---:|---|---|---|---|
| 1 | HS-01 / 1 | 1 | 04 08:00 | 05 00:00 | — / — | 1 / 7 |
| 3 | HS-01 / 1 | 2 | 05 00:00 | 10 00:00 | 2 / 2 | 7 / 1 |
| 7 | HS-01 / 1 | 3 | 10 00:00 | — | — / — | 1 / — |
| 8 | HS-04 / 4 | 6 | 10 00:00 | 15 00:00:00.000001 | 5 / 5 | 7 / 7 |
| 10 | HS-04 / 4 | 3 | 15 00:00:00.000001 | — | — / — | 7 / — |

## Integridad y permisos

En total el guion secuencial comprobó **85 rechazos previstos**, 18 de movimientos y 67 de integridad, cierre y permisos. Las comprobaciones positivas y las lecturas después de las transacciones también pasaron. Los identificadores de prueba y las restricciones esperadas están en el [guion ejecutable](../pruebas/01_bloque_jason.sql).

| Casos y regla | Acción y verificación esperada | Observado |
|---|---|---|
| I01–I02 · RN-09/S-07 | Con persona 2 referenciada por contacto 1 y persona 8 con nombre desconocido, ensayar duplicados, texto sin contenido, persona inexistente, contacto sin valor y borrado de persona referenciada. | `23505`, `23514`, `23503` y `23502` según el caso. Se conservaron persona 8 con nombre nulo y contacto 1 de persona 2. |
| I03 · RN-07/09 | Ensayar PK duplicada, persona ausente, vigencia vacía, aprobación sin fecha, cambio de una aprobación usada, cierre que excluye la llegada histórica y borrado de la aprobación referenciada. | `23505`, `23503`, `23514` y `P1002`. El hogar histórico conservó su aprobación. La participación veterinaria 8 permaneció ligada a persona 7. |
| I04 · RN-01/03 | Ensayar animal duplicado, especie ausente o mal formada, microchip duplicado, edad negativa y cambio de código o especie histórica. | `23505`, `23502`, `23514` y `P1002`. Se conservó HS-01 como PERRO, con 18 meses y microchip textual `000451`. |
| I05–I06 · RN-04/25 | Ensayar PK, organización sin nombre, referencia a propietario inexistente, borrar la organización usada, traslado sin origen, otra causa sin detalle, fecha infinita, otra etapa solapada, edición y cierre incompatibles y borrado de ingreso referenciado. | `23505`, `23502`, `23503`, `23514`, `23P01` y `P1002`. Se mantuvo el ingreso 2 vinculado a la organización 1 y el ingreso 1 con su historial. |
| I07–I08 · RN-06/07/08 y N-01 | Ensayar PK y especie duplicadas, capacidad inválida, condición interna ausente, capacidad externa, oferente nulo o ajeno, ofertas solapadas, especie nula o en lugar incompatible, y ediciones o borrados que dañarían historia o referencias. | `23505`, `23514`, `23503`, `23502`, `23P01`, `P1002` y `P1003`. Se conservaron el oferente 2 y la especie PERRO en la oferta 2. |
| I09 · RN-05/08 | Insertar PK ya utilizada, mezclar HS-07 con el ingreso válido de HS-08, duplicar el alojamiento, quitar el actor de salida de una fila cerrada, dejar una sola fecha prevista o registrar un actor inexistente. | `23505`, `23503`, `23P01` y `23514`. La FK `estancia_ingreso_animal_fk` detectó el cruce. No se agregaron estancias para ingresos 7 y 8. |
| I10 · RN-23 | Exigir receptor, motivo y vínculo de adopción por separado. Con los datos de regreso presentes, rechazar mientras ADOPCION esté pendiente. Confirmar la FK de receptor en catálogo. | `23514` con las restricciones esperadas `ingreso_receptor`, `ingreso_detalle`, `ingreso_origen_adopcion` y `zz_ingreso_adopcion_pendiente`. El receptor fuera de contexto también fue rechazado. FK a PERSONA validada. El ingreso 7 quedó en RESCATE, con receptor y origen nulos. |
| I11 · RN-05/25, contrato P03 | En una transacción reversible cerrar la estancia 7 y el ingreso 1 en el mismo instante del 20-10. Rechazar el alojamiento en esa etapa cerrada y admitir otra etapa de cuidado a la hora exacta del fin. | Cierre y actor 7 comprobados dentro de la transacción. La etapa anterior devolvió `P1004` al intentar alojar. El nuevo ingreso y su estancia quedaron vinculados al mismo HS-01. Después de revertir, volvieron la etapa 1 abierta y la estancia 7 vigente. |
| I12 · AC-04 y rutas de escritura | Operador intenta INSERT/UPDATE/DELETE/TRUNCATE de ESTANCIA, editar otros datos y ejecutar el cierre privado. Intenta operar con un aislamiento distinto. | `42501` por las escrituras o acceso a la primitiva, `P1001` por el aislamiento. Las verificaciones de estado posteriores pasaron. |

Se comprobó por separado la protección del script de integración con ADOPCION ausente. Su intento terminó con `42P01` y código de cliente 3. En una conexión posterior seguía validado `zz_ingreso_adopcion_pendiente`. La ruta de regreso válida y su FK contextual se comprobarán con el bloque real de Giancarlo.

## C1 y C2 · Dos sesiones reales por carrera

La preparación, confirmada antes de abrir A y B, dejó a HS-13 en la estancia 15 de atención externa y los destinos 7, 8 y 9 vacíos. Los guiones abrieron conexiones `psql` distintas. Una tercera conexión consultó los bloqueos mientras A seguía en pausa. Se liberó A después de observar la espera de B. [Guiones y orden](../README.md#repetir-las-dos-carreras)

| Caso y regla | Preparación, intercalación y esperado | Observación simultánea | Resultado confirmado |
|---|---|---|---|
| C1 · AC-G05-P01-04, RN-06 | A asigna HS-11 al área 7 de un cupo y espera sin confirmar. B ve el cupo libre en su lectura y pide ese cupo para HS-12. Debe esperar y rechazar por capacidad al confirmar A. | PID A 230, `idle in transaction`. PID B 244, `active`. B esperaba `Lock/advisory`, `pg_blocking_pids(244)={230}`. | A confirmó. B releyó y obtuvo `P1014`, capturado dentro de su propia transacción. Su `COMMIT` no dejó efectos. Solo quedó la estancia 16, ingreso 11, área 7, actor 1, ocupación 1/1. |
| C2 · AC-G05-P01-04, RN-05/07/08 | A mueve a HS-13 desde la estancia 15 al hogar 8 y espera sin confirmar. B ve el mismo origen y solicita el hogar 9, elegible y vacío, con una fecha posterior. Debe esperar y detectar el origen desactualizado tras confirmar A. | PID A 258, `idle in transaction`. PID B 272, `active`. B esperaba `Lock/advisory`, `pg_blocking_pids(272)={258}`. | A confirmó. B obtuvo `P1006`, capturado, y terminó sin cambios. La estancia 15 cerró a las 09:00 del 07-10 con actor 1. Solo la estancia 17 quedó vigente, ingreso 13, hogar 8, oferente y aprobación 2, actor 1. |

[06_verificar.sql](../pruebas/concurrencia/06_verificar.sql) se ejecutó en otra conexión. Comprobó los vínculos de las tres estancias resultantes, las horas, el acuerdo y la valoración de C2, y que HS-12 y Casa Y no recibieron estancias de los intentos de B. Las ocupaciones para 7, 8 y 9 fueron 1/1, 1/2 y 0/2. Los IDs son los observados en esta ejecución. Las secuencias pueden saltar valores al revertir intentos.
