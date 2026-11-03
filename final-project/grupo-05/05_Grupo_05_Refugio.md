# IC-4301 — Segunda entrega, Grupo 05: Refugio Huellas Seguras

## A. Contexto y alcance obligatorio

Huellas Seguras registra cada animal a través de ingresos, alojamientos, salud y decisiones de adopción. Un animal y una persona mantienen identidad aunque cambien de etapa o participación; compatibilidad y disponibilidad son decisiones atribuibles.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Los tres procesos son alojamiento/capacidad, evaluación de solicitud/compatibilidad y reserva/formalización individual de adopción. No se agregan atención veterinaria, seguimientos, rescate ni devolución como procesos operativos adicionales.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G05-P01 — Controlar ubicación y capacidad

**Necesidad:** Saber dónde está cada animal y evitar ocupación incompatible o superior a la capacidad admitida.

**Situación operativa:** Después de un ingreso se asigna ubicación interna, hogar temporal aprobado o atención externa; se traslada al animal conservando fechas y responsables.

**Información requerida, sin firma SQL impuesta:** Animal/etapa, ubicación/tipo, capacidad y condición admitida, especie, hogar/oferente aprobado, disponibilidad y estancias previstas/reales; responsable y condiciones acordadas.

**Reglas y comportamiento esperado:**

- Una sola ubicación vigente por animal.
- Respetar capacidad y condición de área interna, o cantidad/especie/periodo declarados por hogar temporal.
- Hogar temporal ofrecido por persona previamente aprobada.
- Conservar ubicaciones anteriores, fechas previstas/reales y responsabilidad; no sobrescribir oferente histórico para reinterpretar estancia.

**Relaciones o conceptos relacionados:** Animal, ubicación, especies admitidas, estancia, persona/participación e ingreso como contexto. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Ubicación actual, ocupación/capacidad e historial por animal; traslados explicables con responsables/periodos.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G05-P01-V | Asignar un animal a ubicación compatible y trasladarlo a hogar aprobado con cupo/especie/periodo válidos. Consultar ambas estancias y responsable de cada una. |
| G05-P01-I | Intentar segundo alojamiento vigente del mismo animal, cupo excedido, especie no admitida o hogar no aprobado/disponible. No dejar estancia incompatible ni perder la anterior. |
| G05-P01-L | Último cupo y cambio en frontera de periodos según convención; ubicación externa no debe recibir una capacidad ficticia de jaula si el caso no la define. No se requiere matriz detallada de compatibilidad entre animales. |

**Transacción:** Cerrar estancia anterior y abrir nueva de forma coherente; si falla destino, no dejar animal sin ubicación por un traslado presentado como exitoso.

**Concurrencia pertinente:** Dos sesiones compiten por último cupo o trasladan al mismo animal a hogares diferentes. El conjunto final conserva exclusividad y capacidad. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G05-P01-01:** Se consulta una ubicación vigente y todas las anteriores de cada animal.
- **AC-G05-P01-02:** Se respetan capacidad, especie, aprobación y periodo donde aplican.
- **AC-G05-P01-03:** El traslado fallido conserva el estado anterior.
- **AC-G05-P01-04:** La competencia por cupo/animal no produce doble ubicación ni exceso.

**Límite del proceso:** No incluye gestionar todo rescate/ingreso ni un calendario de atención externa. Ingresos, participantes y aprobación de hogares pueden prepararse; la operación debe comprobarlos donde correspondan.

**Fundamento del caso:** secciones Ubicación y alojamiento. Los procesos se numeran consecutivamente dentro de este anexo.

### G05-P02 — Evaluar solicitudes y compatibilidad

**Necesidad:** Diferenciar aprobación de la solicitud, resultado de actividades y compatibilidad de un animal concreto con el hogar.

**Situación operativa:** Se recibe solicitud general o con varios animales; se registran entrevistas/visita cuando corresponda, decisiones y una evaluación de correspondencia animal–hogar.

**Información requerida, sin firma SQL impuesta:** Solicitante, vivienda/hogar/experiencia/condiciones, animales de interés si los hay, actividades con fecha/responsable/resultado/observaciones, estados y razones; valoración de compatibilidad concreta.

**Reglas y comportamiento esperado:**

- Admitir interés por varios animales o solicitud general.
- Conservar historial de decisiones y razones, incluido pendiente de información, rechazo o nueva solicitud posterior.
- Aprobación de persona no reserva automáticamente todos los animales.
- Compatibilidad debe registrarse para animal y hogar concretos, separada del mero interés.
- Disponibilidad sanitaria/administrativa es decisión atribuible de personal, no resultado automático de un diagnóstico.

**Relaciones o conceptos relacionados:** Solicitud, solicitud–animal, evento/actividad de solicitud, persona/hogar, valoración de compatibilidad y disponibilidad del animal. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Historia de actividades/decisiones y resultados por combinación animal–hogar; pendientes consultables sin confundir resultado de entrevista con estado global.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G05-P02-V | Evaluar solicitud general, agregar interés por dos animales y registrar resultados de compatibilidad distintos. Dejar actividad con resultado y decisión atribuible; comprobar que no se reservaron ambos animales automáticamente. |
| G05-P02-I | Intentar presentar interés como compatibilidad aprobada sin evaluación concreta o decisión sin responsable/razón exigible. No formalizar una aprobación ficticia ni perder la actividad previa. |
| G05-P02-L | Persona con solicitud rechazada presenta otra: ambas historias permanecen separadas. La visita solo se exige cuando corresponde; no imponerla a todos los casos por uniformidad. |

**Transacción:** Cada actividad/decisión y su contexto deben quedar coherentes. Un fallo no cambia estado global sin su fundamento ni crea resultado asociado a animal/hogar ajenos.

**Concurrencia pertinente:** Dos sesiones evalúan la misma solicitud. Las decisiones confirmadas no se pierden ni sobrescriben sin antecedente; aprobar compatibilidad no equivale a adjudicar el animal frente a otra familia. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G05-P02-01:** Se distingue solicitud general, interés y compatibilidad animal–hogar.
- **AC-G05-P02-02:** Las actividades conservan fecha, responsable, resultado y observaciones y las decisiones sus razones.
- **AC-G05-P02-03:** La nueva solicitud no elimina la rechazada.
- **AC-G05-P02-04:** No existe reserva automática por aprobación ni regla médica inventada para habilitar adopción.

**Límite del proceso:** La disponibilidad previa puede prepararse como decisión válida; no se añade un proceso completo de atención médica o de habilitación clínica. Las actividades y decisión de esta solicitud sí deben ejecutarse, no cargarse como resultado final de la demostración.

**Fundamento del caso:** secciones Solicitudes de adopción; Preparación para adopción; Evaluación y atención de salud. Los procesos se numeran consecutivamente dentro de este anexo.

### G05-P03 — Formalizar adopciones

**Necesidad:** Reservar y entregar un animal a una familia con resultado individual trazable y sin adjudicación simultánea.

**Situación operativa:** Después de evaluar correspondencia se decide reservar animal para solicitud y formalizar adopción con fecha de entrega, condiciones y responsables.

**Información requerida, sin firma SQL impuesta:** Animal/ingreso actual, solicitud/familia, compatibilidad y decisiones aplicables, disponibilidad/reservas y restricciones vigentes de persona; actor y fecha de reserva, entrega y condiciones aceptadas.

**Reglas y comportamiento esperado:**

- Un animal puede ser considerado en varias solicitudes antes de adjudicación.
- Durante reserva no se asigna simultáneamente a otra familia.
- Formalizar por animal aunque solicitud incluya varios; conservar responsables y condiciones aceptadas.
- El resultado corresponde al animal/ingreso correctos y no cierra el mismo ingreso simultáneamente por adopción y otro resultado incompatible.
- Una devolución previa no crea automáticamente prohibición de adoptar; la restricción necesita decisión registrada.

**Relaciones o conceptos relacionados:** Reserva, solicitud/compatibilidad, adopción/responsables, animal, ingreso y resultado de etapa; estancia vigente al entregar. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Reserva atribuible y adopción individual vinculada a la etapa, entrega/condiciones y responsables; situación actual coherente sin doble adjudicación.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G05-P03-V | Reservar un animal tras compatibilidad favorable y formalizar su adopción. En solicitud con varios animales mostrar resultado individual sin dar por adoptados todos. |
| G05-P03-I | Intentar reservar/adoptar el mismo animal para otra familia con reserva incompatible vigente o usar ingreso de otro animal. No duplicar adjudicación ni cerrar contexto equivocado. |
| G05-P03-L | Persona que devolvió antes pero no tiene restricción vigente; no rechazar automáticamente. Animal considerado por varias solicitudes aún no reservado no pertenece a ninguna familia por ese solo interés. |

**Transacción:** Adopción, resultado del ingreso, situación de reserva y salida de alojamiento cuando corresponda deben concordar. Un fallo no deja animal entregado sin adopción ni etapa doblemente cerrada.

**Concurrencia pertinente:** Dos familias intentan reservar/formalizar el mismo animal. Solo puede quedar una adjudicación compatible y el rechazo debe ser comprobable sin eliminar evaluaciones de la otra familia. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G05-P03-01:** Se conserva reserva y formalización con solicitud, animal, ingreso y responsables correctos.
- **AC-G05-P03-02:** La exclusividad se mantiene incluso bajo competencia de dos familias.
- **AC-G05-P03-03:** Se distingue resultado por animal y no se cierra la etapa por resultados incompatibles.
- **AC-G05-P03-04:** No se aplica una restricción automática por devolución previa y no quedan efectos parciales de formalización.

**Límite del proceso:** No incluye ejecutar seguimientos, devoluciones ni restricciones como nuevos procesos. Sus antecedentes pueden prepararse y sus relaciones/reglas se prueban en el modelo completo. Registrar la salida necesaria al entregar es efecto de formalización, no un proceso adicional de alojamiento.

**Fundamento del caso:** secciones Solicitudes de adopción; Formalización y seguimiento de la adopción; Traslados y otros resultados. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** PERSONA; MEDIO_CONTACTO; PARTICIPACION; REPORTE; ANIMAL; REPORTE_ANIMAL; ORGANIZACION_EXTERNA; INGRESO; UBICACION; UBICACION_ESPECIE_ACEPTADA; ESTANCIA; EVALUACION_SALUD; DIAGNOSTICO; DIAGNOSTICO_REVISION; INDICACION; INDICACION_DIAGNOSTICO; APLICACION_INDICACION; CAMBIO_DISPONIBILIDAD; SOLICITUD_ADOPCION; SOLICITUD_ANIMAL; EVENTO_SOLICITUD; RESERVA; ADOPCION; ADOPCION_RESPONSABLE; SEGUIMIENTO_ADOPCION; RESTRICCION_PERSONA; RESULTADO_ETAPA.

| Área de atención | Verificación requerida y límite |
|---|---|
| Identidad y etapas | Microchip opcional no puede asociarse simultáneamente a otro animal; reportes pueden vincular varios animales. Reingreso conserva código y antecedentes; registrar receptor cuando hay devolución según el caso. |
| Alojamiento y responsabilidad | Conservar responsabilidad histórica; N-01 deriva oferente de ubicación y exige no sobrescribirlo al cambiar. Probar especies/capacidades/periodos sin reducirlo a una FK. |
| Salud | Mantener restricción de revisión veterinaria y exigir contexto de diagnóstico de la indicación. Probar ejecución real con fecha/responsable/observación. Profesión vigente e ingreso ya forman parte del modelo completo, no se omiten como externos al recorte. |
| Solicitud y compatibilidad | Separar interés, actividad, resultado y estado; debe quedar evaluada correspondencia animal–hogar. Conservar decisiones y nuevas solicitudes posteriores. |
| Adopción y otros resultados | Animal de adopción coincide con ingreso; no cerrar la misma etapa simultáneamente por adopción y resultado incompatible. Seguimiento reprogramado conserva adopción origen; una restricción de persona exige decisión y no nace automáticamente de devolución. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Punto de partida: 27 relaciones finales. Lab03 implementó ocho clínicas y mejoró origen de hijos mediante tipo de evaluación. Está demostrado diagnóstico ajeno a evaluación en vínculo de indicación; debe mantenerse ahora el contexto. P1 señaló resultado de compatibilidad ausente y receptor de devolución no conservado: no simplifiquen evaluación/adopción para ajustarlas a ese defecto.

**Reutilización efectiva:** Reutilizar revisión/diagnósticos, aplicaciones y procedimiento de ejecución con validación/rollback, además de consultas/reporte clínico útil. Sus pruebas pueden integrarse a cobertura del modelo sin convertir salud en cuarto proceso.

**Distinción entre defecto, observación y supuesto:** No existe una enfermedad que habilite/inhabilite automáticamente toda adopción. No se exige visita en todos los casos ni matriz detallada de compatibilidad entre animales. Una devolución no implica inhabilitación futura sin decisión registrada.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

No existe una enfermedad que habilite/inhabilite automáticamente toda adopción. No se exige visita en todos los casos ni matriz detallada de compatibilidad entre animales. Una devolución no implica inhabilitación futura sin decisión registrada.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Huellas Seguras, secciones Ubicación y alojamiento, Preparación para adopción, Solicitudes de adopción y Formalización y seguimiento; PDF del Proyecto1 §5.8–5.9 y observaciones P1/Lab03.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
