# IC-4301 — Segunda entrega, Grupo 01: Clínica Los Robles

## A. Contexto y alcance obligatorio

Clínica Los Robles presta atención ambulatoria general y especializada. Recepción programa citas y los médicos registran atenciones; la historia debe seguir al paciente aunque cambien contactos, responsables o habilitaciones de los médicos.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Los tres procesos abarcan programación, cambios de la misma cita y registro de atención. Llegada/cancelación/ausencia son operaciones relacionadas con esos procesos; no se añaden prescripción, laboratorio, hospitalización, cobros ni nómina.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G01-P01 — Programar citas

**Necesidad:** Recepción necesita comprometer una atención para un paciente y especialidad sin duplicar ocupación de paciente o médico.

**Situación operativa:** Una persona solicita atención. Recepción propone fecha, hora y duración; puede confirmar el espacio de la especialidad antes de conocer al médico y asignarlo posteriormente.

**Información requerida, sin firma SQL impuesta:** Paciente existente, solicitante y su vínculo cuando aplique, especialidad, motivo general, inicio y duración previstos, estado de la solicitud y médico si ya se conoce; habilitación y disponibilidad pertinentes.

**Reglas y comportamiento esperado:**

- La cita corresponde a un paciente y una especialidad; el médico inicial puede estar pendiente.
- Si se asigna médico, debe estar autorizado para esa especialidad en la fecha correspondiente.
- No admitir citas que traslapen para el mismo paciente, aunque cambie el médico, ni compromisos incompatibles del mismo médico.
- Conservar la solicitud original, su solicitante y duración prevista; no exigir una duración fija del catálogo de especialidad.

**Relaciones o conceptos relacionados:** Paciente/persona, responsable, médico, especialidad, habilitación histórica, disponibilidad y cita. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Cita identificable con sus datos y estado; agenda consultable por fecha/especialidad/médico y citas aún sin médico; rechazo explicable si no puede programarse.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G01-P01-V | Con un paciente y especialidad válidos y sin ocupaciones incompatibles, registrar una cita inicialmente sin médico y asignarle después un médico habilitado. Verificar que sigue siendo la misma cita y aparece correctamente en ambas consultas de agenda. |
| G01-P01-I | Intentar otra cita que traslape al paciente con médico distinto y otra que traslape al médico con paciente distinto. Probar también especialidad no habilitada a la fecha. No debe quedar la cita incompatible ni una asignación parcial. |
| G01-P01-L | Comprobar comienzo/fin de una autorización, citas consecutivas y duración inválida. Declarar la convención de extremos de intervalos y mostrar esperado/observado; no crear ausencias arbitrarias ni una regla clínica de prioridad. |

**Transacción:** El alta/asignación y sus comprobaciones constituyen una decisión coherente. Un rechazo no deja consumido el espacio ni modifica la cita original de otra persona.

**Concurrencia pertinente:** Dos sesiones intentan comprometer un mismo paciente o médico en intervalos incompatibles. Solo pueden confirmarse resultados compatibles; mostrar agenda final y qué ocurrió a cada sesión. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G01-P01-01:** Se registra una cita con médico pendiente y se distingue de una cita inexistente.
- **AC-G01-P01-02:** La asignación comprueba especialidad y vigencia en la fecha de atención propuesta.
- **AC-G01-P01-03:** La agenda final no contiene los dos tipos de traslape prohibido; el rechazo conserva los demás compromisos.
- **AC-G01-P01-04:** Se consultan motivo, solicitante, duración y estado de la misma solicitud sin duplicarla.

**Límite del proceso:** No incluye crear pacientes/médicos ni administrar todo el calendario de ausencias como un proceso adicional. Sus registros válidos pueden prepararse; las excepciones de disponibilidad utilizadas deben estar justificadas por el caso y documentadas.

**Fundamento del caso:** secciones Solicitud y programación de citas; Médicos y especialidades; Registro de pacientes. Los procesos se numeran consecutivamente dentro de este anexo.

### G01-P02 — Reprogramar y mantener historial

**Necesidad:** Cambiar una cita sin perder su fecha original ni atribuir al médico nuevo toda la historia anterior.

**Situación operativa:** Recepción recibe una solicitud de cambio de fecha, hora o médico; también necesita registrar cancelación o ausencia de la misma solicitud y explicar quién gestionó el cambio.

**Información requerida, sin firma SQL impuesta:** Identidad de cita, cambio solicitado, actor administrativo, momento y motivo cuando corresponda, valores anteriores/nuevos, disponibilidad y habilitación para la nueva propuesta.

**Reglas y comportamiento esperado:**

- La reprogramación conserva identidad de la solicitud.
- La historia conserva cambios de fecha/hora y médico, actor, momento y motivo aplicable; cancelar no borra cita ni historia.
- La nueva programación vuelve a respetar los conflictos de paciente/médico y la habilitación por especialidad.
- El estado actual debe poder explicarse a partir de la historia; no se impone una secuencia de estados no definida por el caso.

**Relaciones o conceptos relacionados:** Cita, historial de cambios, personal administrativo identificado, médico/especialidad y agenda. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Cita vigente actualizada y cronología con estado previo/nuevo; cancelaciones y ausencias reconocibles sin desaparición del antecedente.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G01-P02-V | Reprogramar una cita dos veces, incluyendo un cambio solo de médico, y cancelar otra. Consultar fecha original, cambios y responsables; comprobar que permanecen las identidades y las citas canceladas. |
| G01-P02-I | Solicitar traslado a una franja incompatible o a médico no autorizado. Comprobar que se mantiene la programación anterior y no aparece una transición exitosa ficticia. |
| G01-P02-L | Cambiar únicamente el médico sin cambiar hora; cancelar una cita ya vinculada a consulta atendida debe tratarse según coherencia documentada, sin borrar la atención. Distinguir ausencia de cancelación. |

**Transacción:** Actualización e historia correspondiente deben quedar completas o conservarse el estado previo. Un fallo posterior a una parte del cambio no puede dejar una historia que anuncie una reprogramación no realizada.

**Concurrencia pertinente:** Dos sesiones cambian la misma cita o disputan la franja de destino. No perder una modificación confirmada ni aceptar dos compromisos incompatibles; identificar el rechazo o reintento. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G01-P02-01:** Una consulta permite reconstruir la primera programación y todas las modificaciones realizadas.
- **AC-G01-P02-02:** Un cambio solo de médico conserva ambos médicos y su orden histórico.
- **AC-G01-P02-03:** Una cancelación mantiene cita, actor e historia y no crea consulta clínica.
- **AC-G01-P02-04:** Un cambio inválido no altera el estado previo ni deja efectos parciales; el actual coincide con la historia confirmada.

**Límite del proceso:** Incluye los cambios de estado necesarios de la cita; no añade un sistema general de auditoría de usuarios ni la gestión del expediente clínico versionado como cuarto proceso.

**Fundamento del caso:** secciones Solicitud y programación de citas. Los procesos se numeran consecutivamente dentro de este anexo.

### G01-P03 — Registrar consultas

**Necesidad:** Conservar una atención real bajo médico responsable, tanto desde cita como por urgencia sin programación.

**Situación operativa:** Se confirma la llegada y el médico registra el inicio, motivo clínico y resumen. Si hay cita debe poder reconocerse qué atención la resolvió.

**Información requerida, sin firma SQL impuesta:** Paciente, médico responsable, inicio real, motivo clínico y resumen; cita opcional con paciente/estado y correspondencia pertinente.

**Reglas y comportamiento esperado:**

- Cada consulta tiene un único paciente y médico responsable.
- La atención urgente puede existir sin cita y debe permanecer en el mismo expediente del paciente.
- Una cita cancelada o marcada como ausencia no puede producir consulta; una atendida permite identificar su consulta.
- No confundir hora propuesta con inicio real ni generar consultas duplicadas para una misma cita según la correspondencia del modelo final.

**Relaciones o conceptos relacionados:** Consulta, cita, paciente/persona y médico; las relaciones clínicas restantes permanecen parte del modelo completo. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Consulta persistida y consultable por paciente/médico, con o sin cita; cita atendida coherente con su atención e identidad del paciente.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G01-P03-V | Registrar atención desde una cita válida y otra urgente sin cita para el mismo paciente. Confirmar y consultar ambas por expediente, distinguiendo origen e inicio real. |
| G01-P03-I | Intentar consulta para cita cancelada/ausente, con referencia inexistente o con paciente distinto del de la cita. Comprobar ausencia de consulta inválida y de transición indebida. |
| G01-P03-L | Repetir el registro para una cita ya atendida y registrar una urgencia sin antecedente en agenda. Explicar cómo se reconoce la atención ya existente sin duplicar sus efectos. |

**Transacción:** La consulta y el cambio de cita a atendida, cuando exista, deben ser una unidad. Si falla la consulta, la cita no queda atendida sin atención correspondiente.

**Concurrencia pertinente:** Dos sesiones registran atención de una misma cita, o una intenta cancelarla mientras otra registra atención. El estado final no puede ser cita cancelada con consulta nueva ni dos atenciones para la misma cita. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G01-P03-01:** Se conserva atención con cita y urgencia sin cita bajo el mismo paciente.
- **AC-G01-P03-02:** Las referencias internas del modelo completo acreditan existencia e identidad coherentes.
- **AC-G01-P03-03:** El rechazo de cita cancelada/ausente deja datos consistentes.
- **AC-G01-P03-04:** Después de confirmar, la cita atendida identifica su consulta; no hay duplicación por ejecución concurrente.

**Límite del proceso:** Registrar consulta no exige agregar diagnósticos o tratamientos a toda atención. No se asignan como nuevos procesos la prescripción, sustitución ni corrección de notas; sus relaciones y reglas sí se implementan y prueban en el modelo completo, reutilizando Lab03.

**Fundamento del caso:** secciones Atención y consulta médica; Historial y necesidades de información. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** PERSONA; MEDIO_CONTACTO; PACIENTE; MEDICO; RESPONSABLE_PACIENTE_NM; ESPECIALIDAD; MEDICO_ESPECIALIDAD_NM; DISPONIBILIDAD_MEDICO; RECOMENDACION_SEGUIMIENTO; CITA; HISTORIAL_CAMBIO_CITA; CONSULTA; OBSERVACION_CLINICA; DIAGNOSTICO; CONSULTA_DIAGNOSTICO_NM; TRATAMIENTO; TRATAMIENTO_DIAGNOSTICO_NM.

| Área de atención | Verificación requerida y límite |
|---|---|
| Identidad y responsabilidad | Probar tipo/documento único y cambios de contactos sin expediente duplicado; responsable de menor puede ser persona no paciente. No imponer como dato del caso un umbral de edad no especificado: documentar la interpretación. |
| Habilitación y temporalidad | Comprobar código profesional único y autorización de especialidad histórica. Una autorización terminada hoy no invalida atención anterior legítima. |
| Notas clínicas | Verificar identidades/versiones y que una corrección no altere silenciosamente la historia; distinguir contenido vigente e histórico sin exigir un mecanismo concreto. |
| Diagnósticos y tratamientos | Probar que un diagnóstico asociado a tratamiento corresponde a su consulta; existencia aislada del código no basta. Verificar instrucciones/fechas y relación de sustitución cuando aplique. |
| Seguimiento | Probar vínculo de recomendación con consulta origen y cita posterior sin confundir fecha sugerida/programada. Preparar hechos de prueba, sin implementar un cuarto flujo de agendamiento especializado. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** El recorte de Lab03 contenía seis relaciones clínicas. En el modelo completo paciente, médico y cita dejan de ser enteros sin comprobación referencial interna. Está demostrado que se admitía diagnóstico de otra consulta en tratamiento: esa correspondencia debe mantenerse ahora. El historial de cita previo necesita representar cambios solo de médico además de fechas.

**Reutilización efectiva:** Conservar el núcleo clínico, consultas útiles y sustitución con herencia/rollback que funcionaron, adaptándolos a las nuevas referencias. No es necesario ejecutar la sustitución como proceso funcional adicional, pero su integridad y continuidad se verifican con las pruebas del esquema.

**Distinción entre defecto, observación y supuesto:** La duración por cita fue aceptada en la versión calificada: no se obliga a copiar duración fija de especialidad. La edición directa de nota histórica fue observación formativa; para esta entrega se demuestra la conservación histórica exigida por el caso, sin prescribir trigger. La prioridad ALTA/MEDIA/BAJA de Lab03 no es una política clínica oficial ni un requisito de los procesos asignados.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

La duración por cita fue aceptada en la versión calificada: no se obliga a copiar duración fija de especialidad. La edición directa de nota histórica fue observación formativa; para esta entrega se demuestra la conservación histórica exigida por el caso, sin prescribir trigger. La prioridad ALTA/MEDIA/BAJA de Lab03 no es una política clínica oficial ni un requisito de los procesos asignados.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Clínica Los Robles, secciones Registro de pacientes, Médicos y especialidades, Solicitud y programación de citas y Atención y consulta médica; resultado normalizado del Proyecto 1 y retroalimentación Lab03 del grupo.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
