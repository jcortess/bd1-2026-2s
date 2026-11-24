# Continuidad del grupo 05

La distribución de responsabilidades proviene del Word del equipo. El alcance académico y la aceptación provienen del anexo y del enunciado general. Los nombres físicos de este bloque están en minúsculas, sin comillas, dentro del esquema `huellas`. Los IDs numéricos nuevos son `bigint` positivos. El código animal es texto estable. Las fechas de etapa y alojamiento son `timestamptz` finitos, mostrados en Costa Rica. Una etapa abierta tiene `ingreso.fecha_cierre IS NULL`. [Modelo y diccionario](modelo/Modelo_Jason.md)

## Cobertura del inventario original

El cuadro siguiente conserva el estado histórico de Jason en versión 0.1. El estado vigente después del aporte de Paula se encuentra en [Modelo consolidado](modelo/Modelo_Relacional.md) y en el contrato añadido al final de este documento: hay 19 tablas disponibles; siguen pendientes las nueve de Jean Carlos.

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

## Contrato de Paula para Jean Carlos

Actualización 24-11-2026, Paula 1.0. Es una propuesta implementada y probada del bloque de Paula; no consta aún revisión o aprobación humana de Jean Carlos. No se crearon tablas sustitutas de sus nueve relaciones. [Firmas y errores](Procesos_Negocio.md#g05-p02--evaluar-solicitudes-y-compatibilidad--paula) · [Modelo actual](modelo/Modelo_Relacional.md) · [Pruebas y límites](evidencias/Resultados_Paula.md).

| Interfaz disponible | Uso y condición de integración |
|---|---|
| `solicitud_animal(solicitud_id,animal_codigo)` | Sigue siendo interés. Mantener las FK de RESERVA/ADOPCION a la pareja; no tratar su existencia como una aprobación. |
| `estado_actual_solicitud` | Expone estado general, `decision_id`, actor, fecha, razón y solicitante/hogar. No tiene una columna de estado independiente para actualizar desde otro proceso. |
| `compatibilidad_vigente` | Última evaluación por solicitud/animal/ingreso; la pendiente o no favorable posterior prevalece sobre un favorable histórico. La aprobación general no genera evaluaciones ni reservas. |
| `_exigir_compatibilidad(bigint,text,bigint,timestamptz) → bigint` | Privada para el propietario/futura rutina SECURITY DEFINER. Toma bloqueo compartido, bloquea/relee solicitud y exige aprobación general válida + etapa abierta del animal + última evaluación FAVORABLE. Devuelve ID de evidencia, sin adjudicar ni modificar otros hechos. |
| `compatibilidad_animal_hogar` y UQ `(id_compatibilidad,solicitud_id,animal_codigo,ingreso_id)` | Destino de FK contextual propuesto para conservar la valoración consumida por reserva/adopción. Su contenido es inmutable y el hogar es la instantánea de la solicitud. La FK sola no comprueba que siga siendo la última ni su resultado: usar la primitiva dentro de la transacción. |
| `disponibilidad_actual(animal_codigo,ingreso_id,...)` | Comprobar decisión HABILITADO de la etapa que se entrega, fecha aplicable y atribución. Una habilitación anterior al reingreso no habilita automáticamente la nueva etapa. No se automatiza a partir de diagnósticos. |
| `evaluacion_salud(id_evaluacion,tipo_evaluacion)` | Destino conservado para INDICACION con tipo fijo REVISION_VETERINARIA. `veterinario_id` se acompaña del registro vigente real en PARTICIPACION. |
| `diagnostico_revision(evaluacion_id,diagnostico_id)` | PK de la aparición y destino clínico para INDICACION_DIAGNOSTICO. No existe `id_diagnostico_revision` artificial. Conservar también FK `(indicacion_id,evaluacion_id)` al origen de indicación. Sigue pendiente instalar esas dos FK en el bloque de Jean Carlos. |

Orden de bloqueo: conservar primero `_bloquear_alojamiento()` y READ COMMITTED; después usar el contexto de solicitud/compatibilidad y los recursos de adjudicación de P03. La primitiva de Paula usa el mismo bloqueo de Jason, reentrante dentro de la transacción. No confirmar entre validación de compatibilidad, reserva/adopción y cierre. La disponibilidad, las restricciones de persona y la exclusividad de animal siguen siendo verificaciones necesarias de P03, no efectos de la aprobación general.

## Impacto de la inicial por etapa sobre la instalación y los cierres

Paula añade triggers a INGRESO/PARTICIPACION sin cambiar sus columnas ni las rutinas de Jason. Un ingreso nuevo debe tener una evaluación INICIAL antes de COMMIT; se permite insertar ambos en cualquier orden compatible con la FK dentro de una transacción y la revisión requiere inicial no posterior. No se exige un plazo en días. Los hechos clínicos pertenecen a `[fecha_ingreso,fecha_cierre)`; un cierre debe ser posterior a las evaluaciones/disponibilidades/compatibilidades registradas de esa etapa. No acortar el registro profesional/participación de manera que invalide un hecho histórico.

Los scripts 01–04 pueden continuar reproduciendo el bloque aislado de Jason. Para la instalación conjunta disponible usar [09_instalar_bloque_paula.sql](sql/09_instalar_bloque_paula.sql): instala 01–08 en orden; 07 prepara iniciales ficticias de los 17 ingresos existentes y 08 valida su cobertura. Esos son antecedentes para pruebas, no datos generados automáticamente por un proceso real. El guion original de Jason pasó sin modificaciones sobre una base nueva con este contrato clínico.

La FK contextual del regreso sigue bloqueada por `zz_ingreso_adopcion_pendiente` hasta que Jean Carlos cree ADOPCION y active el script de integración ya preparado por Jason. Su receptor está modelado; el regreso válido y el cierre exclusivo completo siguen pendientes. La documentación consolidada conserva esa diferencia.
