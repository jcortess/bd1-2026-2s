# Continuidad del grupo 05

La distribución de responsabilidades proviene del Word del equipo. El alcance académico y la aceptación provienen del anexo y del enunciado general. Los nombres físicos de este bloque están en minúsculas, sin comillas, dentro del esquema `huellas`. Los IDs numéricos nuevos son `bigint` positivos. El código animal es texto estable. Las fechas de etapa y alojamiento son `timestamptz` finitos, mostrados en Costa Rica. Una etapa abierta tiene `ingreso.fecha_cierre IS NULL`. [Modelo y diccionario](modelo/Modelo_Jason.md)

## Cobertura del inventario original

El cuadro siguiente conserva el estado histórico de Jason en versión 0.1. No representa pendientes actuales. Al 28-11-2026 están instaladas las 27 relaciones originales y la ampliación `compatibilidad_animal_hogar` (28 tablas). Véase el [modelo consolidado](modelo/Modelo_Relacional.md) y la sección de integración vigente al final.

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
| 25 | SEGUIMIENTO_ADOPCION | Jean Carlos | Implementada. Validación contextual de reprogramaciones, cronología e historial mediante SQL 10–11; pruebas PS-01–PS-05. |
| 26 | RESTRICCION_PERSONA | Jean Carlos | Pendiente. La decisión registrada sustenta cada restricción. |
| 27 | RESULTADO_ETAPA | Jean Carlos | Pendiente. Coordinar el cierre con ADOPCION y el alojamiento. |

Las ampliaciones de Jason son atributos y claves en las tablas originales. Incluyen etapa y actores de ESTANCIA, constancia sanitaria, aprobación utilizada, identificación de la oferta física, instante de aprobación del oferente, cierre de INGRESO y receptor del regreso. Las vistas son consultas. Paula y Jean Carlos deben acordar la representación de compatibilidad animal–hogar y las claves para consumirla. [Matriz de integridad del bloque](modelo/Matriz_Jason.md)

## Paula · G05-P02 y referencia clínica

Requisitos históricos de integración, conservados como antecedente.

- Conservar la asociación de reportes a animales y el carácter opcional del reporte de un ingreso. Usar PERSONA, PARTICIPACION, ANIMAL e INGRESO de `huellas`.
- Revisar cómo enlazar EVALUACION_SALUD con la etapa mediante `(ingreso_id, animal_codigo)`. Documentar cómo se verifica la evaluación inicial por etapa, incluida la de un reingreso. Lab03 admitía una evaluación inicial sin profesional y exigía en una revisión veterinaria fecha, veterinario, motivo, observaciones, peso positivo y recomendaciones. Añadir la vigencia del registro veterinario en PARTICIPACION a la fecha real y revalidar. Para veterinario, el rol es `VETERINARIO` y el código de registro se comparte como `REGISTRADO`. Confirmar el uso de peso en kg al adaptar el recorte.
- Conservar la FK discriminada a `(id_evaluacion, tipo_evaluacion)` con el tipo fijo `REVISION_VETERINARIA` en DIAGNOSTICO_REVISION e INDICACION. Explicar que una observación diagnóstica tiene identidad por la pareja `(evaluacion_id, diagnostico_id)`, de la que depende el estado. La clave compuesta reemplaza el identificador artificial que figuraba en el inventario conceptual.
- Representar una valoración atribuible y un resultado de compatibilidad para el animal y hogar de la solicitud, con una clave que RESERVA y ADOPCION puedan verificar. Conservar SOLICITUD_ANIMAL como interés. Separar el resultado de entrevista o visita del estado global y su historial de decisiones. Definir la disponibilidad como una decisión atribuible, con fecha, actor y observación.

## Jean Carlos · G05-P03, cierre y origen del regreso

Contrato histórico de implementación. La ejecución vigente se describe al final; no ejecutar el script de FK por separado.

1. Crear `huellas.adopcion` con `id_adopcion bigint`, `animal_codigo` y `ingreso_id bigint`. Exigir `UNIQUE (ingreso_id)` y `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso (id_ingreso, animal_codigo)`. Agregar `UNIQUE (id_adopcion, animal_codigo)` como destino de la referencia inversa.
2. El contrato original proponía activar [01_adopcion_origen.sql](sql/integracion/01_adopcion_origen.sql) después. En la instalación vigente esta operación está incorporada en `11_jeank_operaciones.sql`; no ejecutar ambos. En la misma transacción instala la FK `(adopcion_origen_id, animal_codigo)` y retira el bloqueo inicial. Permanecen obligatorios el receptor, la adopción origen y el motivo para devolución o recuperación. Mantener controles sobre la adopción ya formalizada, tipo de finalización, cronología de retorno y un solo regreso por adopción. Probar una adopción ajena válida, un receptor inexistente y un regreso válido con su nuevo ingreso e historial anterior.
3. En el procedimiento de formalización, tomar primero `huellas._bloquear_alojamiento()` con `READ COMMITTED`, antes de leer el ingreso y adquirir bloqueos de la adjudicación. Verificar la vigencia de la reserva, disponibilidad, restricciones documentadas, compatibilidad y el contexto exacto de solicitud, animal e ingreso. Confirmar que ese ingreso sigue abierto y que ningún otro resultado de cierre es incompatible.
4. Como parte de esa misma transacción, llamar a `huellas._cerrar_etapa_alojamiento(ingreso_id, estancia_esperada, fecha_entrega, actor_id)`. Pasar el ID de la estancia vigente observada o `NULL` si el ingreso carece de estancia. Devuelve el ID cerrado, o `NULL` en ese segundo caso. Cierra alojamiento y etapa con el mismo instante, y exige que coincida el origen esperado. Registrar la adopción, responsables, condiciones y fin de reserva en la misma transacción. Según P1 §4.7, ADOPCION documenta el resultado de formalización y RESULTADO_ETAPA documenta los demás cierres. Debe haber exclusión mutua por ingreso en las dos rutas. Una fecha de cierre por sí sola deja pendiente fundamentar el resultado en el modelo completo.
5. Exponer la formalización mediante una rutina de privilegios controlados. Conservar privadas ambas primitivas. Las rutas de reserva y resultado que escriban el mismo estado deben acordar el orden de bloqueos y revalidar las lecturas. Probar fallo intermedio, nueva lectura después del `COMMIT` y dos familias concurrentes. La primitiva de Jason no confirma de manera independiente.

Para INDICACION_DIAGNOSTICO, conservar `evaluacion_id` y exigir las dos FK contextuales: `(indicacion_id, evaluacion_id)` a INDICACION y `(evaluacion_id, diagnostico_id)` a DIAGNOSTICO_REVISION. La asociación solo puede usar diagnósticos que constan en la revisión de origen. Prueben dos revisiones válidas con un diagnóstico registrado únicamente en la segunda y una indicación nacida en la primera. Mantener el discriminador de revisión, los campos de aplicación realizada y el bloqueo de `registrar_aplicacion`. Adaptar consultas Q01–Q04 y el reporte Q02/R05/R06 tomando los tipos y referencias del modelo completo. [Retroalimentación de Lab03](../../lab03/grupo-05/Lab03_Retroalimentacion_Grupo_05.md) · [Evidencia original de Lab03](../../lab03/grupo-05/evidencias/resultados.md)

La consolidación de modelo, matriz y Uso de IA corresponde a Paula. Jean Carlos consolida Control de Cambios y Defensa con la grabación e índice del equipo. Jason integra el arranque y los datos cuando estén listos los demás bloques.

## Contrato de Paula para Jean Carlos

Actualización 24-11-2026, Paula 1.0. Es el contrato original implementado y probado del bloque de Paula. Su consumo técnico fue validado posteriormente en P03; no se atribuye una aprobación humana formal no documentada. No se crearon tablas sustitutas de sus nueve relaciones. [Firmas y errores](Procesos_Negocio.md#g05-p02--evaluar-solicitudes-y-compatibilidad--paula) · [Modelo actual](modelo/Modelo_Relacional.md) · [Pruebas y límites](evidencias/Resultados_Paula.md).

| Interfaz disponible | Uso y condición de integración |
|---|---|
| `solicitud_animal(solicitud_id,animal_codigo)` | Sigue siendo interés. Mantener las FK de RESERVA/ADOPCION a la pareja; no tratar su existencia como una aprobación. |
| `estado_actual_solicitud` | Expone estado general, `decision_id`, actor, fecha, razón y solicitante/hogar. No tiene una columna de estado independiente para actualizar desde otro proceso. |
| `compatibilidad_vigente` | Última evaluación por solicitud/animal/ingreso; la pendiente o no favorable posterior prevalece sobre un favorable histórico. La aprobación general no genera evaluaciones ni reservas. |
| `_exigir_compatibilidad(bigint,text,bigint,timestamptz) → bigint` | Privada para el propietario/futura rutina SECURITY DEFINER. Toma bloqueo compartido, bloquea/relee solicitud y exige aprobación general válida + etapa abierta del animal + última evaluación FAVORABLE. Devuelve ID de evidencia, sin adjudicar ni modificar otros hechos. |
| `compatibilidad_animal_hogar` y UQ `(id_compatibilidad,solicitud_id,animal_codigo,ingreso_id)` | Destino de FK contextual propuesto para conservar la valoración consumida por reserva/adopción. Su contenido es inmutable y el hogar es la instantánea de la solicitud. La FK sola no comprueba que siga siendo la última ni su resultado: usar la primitiva dentro de la transacción. |
| `disponibilidad_actual(animal_codigo,ingreso_id,...)` | Comprobar decisión HABILITADO de la etapa que se entrega, fecha aplicable y atribución. Una habilitación anterior al reingreso no habilita automáticamente la nueva etapa. No se automatiza a partir de diagnósticos. |
| `evaluacion_salud(id_evaluacion,tipo_evaluacion)` | Destino conservado para INDICACION con tipo fijo REVISION_VETERINARIA. `veterinario_id` se acompaña del registro vigente real en PARTICIPACION. |
| `diagnostico_revision(evaluacion_id,diagnostico_id)` | PK de la aparición y destino clínico para INDICACION_DIAGNOSTICO. No existe `id_diagnostico_revision` artificial. Conservar también FK `(indicacion_id,evaluacion_id)` al origen de indicación. Las dos FK ya están instaladas y su contexto se comprobó en PC06/PC07. |

Orden de bloqueo: conservar primero `_bloquear_alojamiento()` y READ COMMITTED; después usar el contexto de solicitud/compatibilidad y los recursos de adjudicación de P03. La primitiva de Paula usa el mismo bloqueo de Jason, reentrante dentro de la transacción. No confirmar entre validación de compatibilidad, reserva/adopción y cierre. La disponibilidad, las restricciones de persona y la exclusividad de animal siguen siendo verificaciones necesarias de P03, no efectos de la aprobación general.

## Impacto de la inicial por etapa sobre la instalación y los cierres

Paula añade triggers a INGRESO/PARTICIPACION sin cambiar sus columnas ni las rutinas de Jason. Un ingreso nuevo debe tener una evaluación INICIAL antes de COMMIT; se permite insertar ambos en cualquier orden compatible con la FK dentro de una transacción y la revisión requiere inicial no posterior. No se exige un plazo en días. Los hechos clínicos pertenecen a `[fecha_ingreso,fecha_cierre)`; un cierre debe ser posterior a las evaluaciones/disponibilidades/compatibilidades registradas de esa etapa. No acortar el registro profesional/participación de manera que invalide un hecho histórico.

Los scripts 01–04 pueden continuar reproduciendo el bloque aislado de Jason. Para la instalación conjunta disponible usar [09_instalar_bloque_paula.sql](sql/09_instalar_bloque_paula.sql): instala 01–08 en orden; 07 prepara iniciales ficticias de los 17 ingresos existentes y 08 valida su cobertura. Esos son antecedentes para pruebas, no datos generados automáticamente por un proceso real. El guion original de Jason pasó sin modificaciones sobre una base nueva con este contrato clínico.

La restricción provisional `zz_ingreso_adopcion_pendiente` fue retirada en `11_jeank_operaciones.sql`, que instala `ingreso_adopcion_origen_fk`. PJ-09 verifica la devolución voluntaria con nuevo ingreso e inicial; PJ-08 verifica el rechazo de un resultado incompatible con una adopción.

## Integración vigente — 28 de noviembre de 2026

La instalación completa se realiza en una base nueva mediante [15_instalar_proyecto_completo.sql](sql/15_instalar_proyecto_completo.sql), que invoca 09 y 14 y comprueba las 28 tablas. La ejecución integrada se verificó en PostgreSQL 16.16 con psql 16.16. No repetir los scripts individuales sobre una base ya instalada.

| Dependencia | Implementación vigente | Evidencia / alcance |
|---|---|---|
| Jason → Paula | FK de evaluación a ingreso/animal, participación veterinaria y evaluación inicial por etapa. | Pruebas de Paula y regresión de Jason. |
| Paula → indicación | FK discriminada a revisión veterinaria y dos FK contextuales de indicacion_diagnostico. | PC06/PC07: rechazo de contexto ajeno y aceptación del correcto. |
| Paula → reserva/adopción | FK a solicitud_animal, ingreso y compatibilidad concreta; consumo de `_exigir_compatibilidad` y disponibilidad vigente. | PJ-01, PJ-04, PJ-06, PJ-07. |
| Reserva → adopción | Reserva exclusiva vigente por animal, contexto conservado, una adopción por reserva e ingreso. | PJ-02, PJ-05, PJ-10. |
| Adopción → Jason | `formalizar_adopcion` llama a `_cerrar_etapa_alojamiento` dentro de la misma transacción. | PJ-04, PJ-07, PJ-11, PJ-12. |
| Adopción → ingreso | FK `(adopcion_origen_id,animal_codigo)` y validación de finalización, cronología y circunstancia. | PJ-09: devolución voluntaria; recuperación no aislada. |
| Resultado de etapa → Jason | FK a ingreso, persona y organización externa; exclusión de adopción y comprobación diferida del cierre. | PJ-08: rechazo incompatible; PJ-17: traslado válido y cierre consistente; PJ-18: rechazo de traslado sin destino. |

### Transacciones y permisos

Las operaciones de adjudicación conservan el bloqueo asesor de alojamiento antes de las lecturas y bloqueos de contexto. La formalización exige READ COMMITTED, comprueba reserva, compatibilidad, disponibilidad y restricciones, registra adopción y responsables, finaliza reserva y cierra ingreso y estancia sin COMMIT intermedio. El trigger diferido comprueba responsables, cierre de reserva e ingreso y ausencia de resultado incompatible; la vista `v_control_adopciones_jeank` complementa la comprobación de estancia. La rutina diferida se corrigió a SECURITY DEFINER con search_path controlado y se verificó en instalación limpia.

El rol operativo utiliza las rutinas públicas autorizadas (`registrar_reserva`, `finalizar_reserva`, `formalizar_adopcion`, `registrar_aplicacion`); las primitivas internas permanecen privadas. Los antecedentes y operaciones sin interfaz pública se preparan por el propietario bajo las restricciones y triggers. PP01 verifica el rechazo de UPDATE directo de indicación, no todos los permisos posibles.

PJ-10 documenta dos sesiones independientes y un observador: A confirma, B recibe P3021 y queda una sola reserva vigente. PJ-11 documenta el rechazo P1006 por estancia esperada incorrecta, ausencia de efectos parciales y reintento correcto. PJ-09 conserva el historial anterior y no genera una restricción automática por devolución voluntaria.

### Alcance y reproducción

- [README e instalación](README.md).
- [Modelo](modelo/Modelo_Relacional.md), [diccionario](modelo/Diccionario_Datos.md), [diagrama](modelo/Diagrama_Relacional.md) y [matriz](modelo/Matriz_Integridad.md).
- [Casos de Jean Carlos](pruebas/Casos_Jeank.md) y [resultados](evidencias/Resultados_Jeank.md).
- [Ejecución secuencial](evidencias/Ejecucion_Jeank_Secuencial.md), [concurrencia](evidencias/Ejecucion_Jeank_Concurrencia.md) e [instalación](evidencias/Ejecucion_Jeank_Instalacion.md).

La existencia de las 28 tablas no implica cobertura exhaustiva de integridad. Se conservan los límites de la matriz, incluido el conteo específico de reservas antes y después de aprobación de P02, las fronteras declarativas no aisladas y la ejecución positiva de traslado. Las regresiones históricas de Jason y Paula no se presentan como nuevas ejecuciones sobre la instalación de 28 tablas.
