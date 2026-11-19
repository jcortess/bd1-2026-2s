# Continuidad del grupo 05

La distribución de responsabilidades proviene del Word del equipo. El alcance académico y la aceptación provienen del anexo y del enunciado general. Los nombres físicos de este bloque están en minúsculas, sin comillas, dentro del esquema `huellas`. Los IDs numéricos nuevos son `bigint` positivos. El código animal es texto estable. Las fechas de etapa y alojamiento son `timestamptz` finitos, mostrados en Costa Rica. Una etapa abierta tiene `ingreso.fecha_cierre IS NULL`. [Modelo y diccionario](modelo/Modelo_Jason.md)

## Cobertura del inventario original

| N.º | Relación | Responsable | Estado en versión 0.1 |
|---:|---|---|---|
| 1 | PERSONA | Jason | Implementada y probada. |
| 2 | MEDIO_CONTACTO | Jason | Implementada y probada. |
| 3 | PARTICIPACION | Jason | Implementada. La vigencia del oferente está probada y el consumo del registro veterinario se integra con Paula. |
| 4 | REPORTE | Paula | Pendiente. |
| 5 | ANIMAL | Jason | Implementada y probada. |
| 6 | REPORTE_ANIMAL | Paula | Pendiente. |
| 7 | ORGANIZACION_EXTERNA | Jason | Implementada y probada. Falta consumo desde resultado de etapa. |
| 8 | INGRESO | Jason | Implementada y probada para ingresos sin adopción origen. FK contextual, regreso completo y cierre de negocio pendientes de integración. |
| 9 | UBICACION | Jason | Implementada y probada. |
| 10 | UBICACION_ESPECIE_ACEPTADA | Jason | Implementada y probada. |
| 11 | ESTANCIA | Jason | Implementada y probada. Primitiva privada de cierre probada en aislamiento. Pendiente ejercerla desde G05-P03. |
| 12 | EVALUACION_SALUD | Paula | Pendiente de adaptar y revalidar desde Lab03 con el nuevo contexto de ingreso y participación. |
| 13 | DIAGNOSTICO | Paula | Pendiente de integrar desde Lab03. |
| 14 | DIAGNOSTICO_REVISION | Paula | Pendiente de integrar desde Lab03 y verificar su uso en el vínculo contextual. |
| 15 | INDICACION | Jean Carlos | Pendiente de adaptar y revalidar desde Lab03. |
| 16 | INDICACION_DIAGNOSTICO | Jean Carlos y Paula para la referencia | Pendiente de corregir e integrar. |
| 17 | APLICACION_INDICACION | Jean Carlos | Pendiente de adaptar y revalidar desde Lab03. |
| 18 | CAMBIO_DISPONIBILIDAD | Paula | Pendiente. Disponibilidad atribuible, incluida la valoración sanitaria. |
| 19 | SOLICITUD_ADOPCION | Paula | Pendiente. |
| 20 | SOLICITUD_ANIMAL | Paula | Pendiente. Conserva interés por un animal. |
| 21 | EVENTO_SOLICITUD | Paula | Pendiente. Diferenciar resultado de actividad, decisión y estado de solicitud. |
| 22 | RESERVA | Jean Carlos | Pendiente. Depende de compatibilidad y disponibilidad demostrables. |
| 23 | ADOPCION | Jean Carlos | Pendiente. Requiere claves contextuales y cierre en una transacción. |
| 24 | ADOPCION_RESPONSABLE | Jean Carlos | Pendiente. |
| 25 | SEGUIMIENTO_ADOPCION | Jean Carlos | Pendiente. Validar adopción de origen en la reprogramación y evitar ciclos. |
| 26 | RESTRICCION_PERSONA | Jean Carlos | Pendiente. La decisión registrada sustenta cada restricción. |
| 27 | RESULTADO_ETAPA | Jean Carlos | Pendiente. Coordinar el cierre con ADOPCION y el alojamiento. |

Las ampliaciones de Jason son atributos y claves en las tablas originales. Incluyen etapa y actores de ESTANCIA, constancia sanitaria, aprobación utilizada, identificación de la oferta física, instante de aprobación del oferente, cierre de INGRESO y receptor del regreso. Las vistas son consultas. Paula y Jean Carlos deben acordar la representación de compatibilidad animal–hogar y las claves para consumirla. [Matriz de integridad del bloque](modelo/Matriz_Jason.md)

## Paula · G05-P02 y referencia clínica

- Conservar la asociación de reportes a animales y el carácter opcional del reporte de un ingreso. Usar PERSONA, PARTICIPACION, ANIMAL e INGRESO de `huellas`.
- Revisar cómo enlazar EVALUACION_SALUD con la etapa mediante `(ingreso_id, animal_codigo)`. Documentar cómo se verifica la evaluación inicial por etapa, incluida la de un reingreso. Lab03 admitía una evaluación inicial sin profesional y exigía en una revisión veterinaria fecha, veterinario, motivo, observaciones, peso positivo y recomendaciones. Añadir la vigencia del registro veterinario en PARTICIPACION a la fecha real y revalidar. Para veterinario, el rol es `VETERINARIO` y el código de registro se comparte como `REGISTRADO`. Confirmar el uso de peso en kg al adaptar el recorte.
- Conservar la FK discriminada a `(id_evaluacion, tipo_evaluacion)` con el tipo fijo `REVISION_VETERINARIA` en DIAGNOSTICO_REVISION e INDICACION. Explicar que una observación diagnóstica tiene identidad por la pareja `(evaluacion_id, diagnostico_id)`, de la que depende el estado. La clave compuesta reemplaza el identificador artificial que figuraba en el inventario conceptual.
- Representar una valoración atribuible y un resultado de compatibilidad para el animal y hogar de la solicitud, con una clave que RESERVA y ADOPCION puedan verificar. Conservar SOLICITUD_ANIMAL como interés. Separar el resultado de entrevista o visita del estado global y su historial de decisiones. Definir la disponibilidad como una decisión atribuible, con fecha, actor y observación.

## Jean Carlos · G05-P03, cierre y origen del regreso

1. Crear `huellas.adopcion` con `id_adopcion bigint`, `animal_codigo` y `ingreso_id bigint`. Exigir `UNIQUE (ingreso_id)` y `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso (id_ingreso, animal_codigo)`. Agregar `UNIQUE (id_adopcion, animal_codigo)` como destino de la referencia inversa.
2. Activar [01_adopcion_origen.sql](sql/integracion/01_adopcion_origen.sql) después. En la misma transacción instala la FK `(adopcion_origen_id, animal_codigo)` y retira el bloqueo inicial. Permanecen obligatorios el receptor, la adopción origen y el motivo para devolución o recuperación. Mantener controles sobre la adopción ya formalizada, tipo de finalización, cronología de retorno y un solo regreso por adopción. Probar una adopción ajena válida, un receptor inexistente y un regreso válido con su nuevo ingreso e historial anterior.
3. En el procedimiento de formalización, tomar primero `huellas._bloquear_alojamiento()` con `READ COMMITTED`, antes de leer el ingreso y adquirir bloqueos de la adjudicación. Verificar la vigencia de la reserva, disponibilidad, restricciones documentadas, compatibilidad y el contexto exacto de solicitud, animal e ingreso. Confirmar que ese ingreso sigue abierto y que ningún otro resultado de cierre es incompatible.
4. Como parte de esa misma transacción, llamar a `huellas._cerrar_etapa_alojamiento(ingreso_id, estancia_esperada, fecha_entrega, actor_id)`. Pasar el ID de la estancia vigente observada o `NULL` si el ingreso carece de estancia. Devuelve el ID cerrado, o `NULL` en ese segundo caso. Cierra alojamiento y etapa con el mismo instante, y exige que coincida el origen esperado. Registrar la adopción, responsables, condiciones y fin de reserva en la misma transacción. Según P1 §4.7, ADOPCION documenta el resultado de formalización y RESULTADO_ETAPA documenta los demás cierres. Debe haber exclusión mutua por ingreso en las dos rutas. Una fecha de cierre por sí sola deja pendiente fundamentar el resultado en el modelo completo.
5. Exponer la formalización mediante una rutina de privilegios controlados. Conservar privadas ambas primitivas. Las rutas de reserva y resultado que escriban el mismo estado deben acordar el orden de bloqueos y revalidar las lecturas. Probar fallo intermedio, nueva lectura después del `COMMIT` y dos familias concurrentes. La primitiva de Jason no confirma de manera independiente.

Para INDICACION_DIAGNOSTICO, conservar `evaluacion_id` y exigir las dos FK contextuales: `(indicacion_id, evaluacion_id)` a INDICACION y `(evaluacion_id, diagnostico_id)` a DIAGNOSTICO_REVISION. La asociación solo puede usar diagnósticos que constan en la revisión de origen. Prueben dos revisiones válidas con un diagnóstico registrado únicamente en la segunda y una indicación nacida en la primera. Mantener el discriminador de revisión, los campos de aplicación realizada y el bloqueo de `registrar_aplicacion`. Adaptar consultas Q01–Q04 y el reporte Q02/R05/R06 tomando los tipos y referencias del modelo completo. [Retroalimentación de Lab03](../../lab03/grupo-05/Lab03_Retroalimentacion_Grupo_05.md) · [Evidencia original de Lab03](../../lab03/grupo-05/evidencias/resultados.md)

La consolidación de modelo, matriz y Uso de IA corresponde a Paula. Jean Carlos consolida Control de Cambios y Defensa con la grabación e índice del equipo. Jason integra el arranque y los datos cuando estén listos los demás bloques.
