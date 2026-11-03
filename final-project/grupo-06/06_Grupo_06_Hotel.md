# IC-4301 — Segunda entrega, Grupo 06: Hotel Mirador del Valle

## A. Contexto y alcance obligatorio

Hotel Mirador del Valle recibe personas y empresas, confirma categorías antes de seleccionar habitación y conserva dónde se alojó cada huésped. Adelantos, cargos por noches reales, responsabilidad de pago y cierre deben distinguirse.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Se desarrollan confirmación/adelantos, ingreso/ocupación y aplicación de pagos/cierre. No se agrega como cuarto proceso el registro de todos los servicios o el manejo completo de cancelación/penalización; sus antecedentes pueden prepararse con trazabilidad.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G06-P01 — Confirmar reservas y adelantos

**Necesidad:** Confirmar cantidades por categoría y condiciones ofrecidas con responsable y adelanto identificables.

**Situación operativa:** Una persona reserva para sí/terceros o una empresa solicita categorías distintas. Se confirma sin asignar necesariamente habitación concreta y se registra adelanto cuando aplica.

**Información requerida, sin firma SQL impuesta:** Responsable/contacto, fechas, huéspedes y cantidades por categoría, plan/precio/condiciones pactados, disponibilidad futura y política/adelanto requerido; pagos recibidos e identificación de su contexto.

**Reglas y comportamiento esperado:**

- Reserva puede agrupar varias categorías sin números de habitación iniciales.
- Al confirmar conservar precio/condiciones aunque cambie tarifario.
- Disponibilidad futura considera reservas, estancias y bloqueos, no solo estado actual.
- Identificar responsable/contacto y distinguir adelanto requerido de recibido.
- No universalizar un umbral de Lab03 como política de todos los planes.

**Relaciones o conceptos relacionados:** Reservación/detalle, categoría/habitación, bloqueos/ocupación, plan/tarifa, persona/empresa y pago de adelanto. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Reserva confirmada completa, categorías/cantidades y pacto; adelanto recibido/pendiente consultable sin afirmar que pago parcial cubre toda obligación.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G06-P01-V | Confirmar reserva de varias categorías y registrar adelanto según condición pactada; confirmar otra cuyo plan no lo requiera. Cambiar tarifario y comprobar que pacto previo no cambia. |
| G06-P01-I | Intentar confirmar sin detalle requerido, con fechas/cantidades inválidas o sin disponibilidad compatible. Un pago referido a otra reserva no puede cubrir el adelanto de esta. |
| G06-P01-L | Adelanto parcial y último cupo de categoría. Distinguir huésped aún desconocido al reservar de identidad exigida al ocupar; no obligar a dar nombres de todos los acompañantes antes de confirmación. |

**Transacción:** Confirmación y detalle/pacto requeridos coherentes. Pago de adelanto puede registrarse por operación separada documentada, pero cada importe tiene contexto y no confirma por sí solo una reserva incompleta.

**Concurrencia pertinente:** Dos sesiones confirman últimas habitaciones de una categoría para el mismo periodo. No sobrecomprometer inventario físico compatible al combinar reservas y ocupaciones. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G06-P01-01:** Se conserva reserva confirmada con detalle, responsable/contacto y pacto completo.
- **AC-G06-P01-02:** Los pagos de adelanto se distinguen de lo requerido y de pagos ajenos.
- **AC-G06-P01-03:** Cambiar tarifa no altera condiciones históricas.
- **AC-G06-P01-04:** No hay confirmación sin detalle ni exceso de disponibilidad en concurrencia.

**Límite del proceso:** No incluye el flujo completo de cancelaciones, penalizaciones o vencimiento automático. Se reutilizan cálculos/historia Lab03 cuando correspondan; su política de dos/siete días no se impone aquí como regla universal.

**Fundamento del caso:** secciones Tarifas y reservaciones; Huéspedes, contactos y empresas; Habitaciones y características. Los procesos se numeran consecutivamente dentro de este anexo.

### G06-P02 — Registrar ingreso y ocupación

**Necesidad:** Saber quién estuvo en cada habitación y periodo, conservando la categoría contratada y los cambios reales.

**Situación operativa:** Llegan huéspedes de una reserva en momentos distintos o sin reserva; se asignan habitaciones. Una persona cambia de habitación o amplía estancia si hay disponibilidad.

**Información requerida, sin firma SQL impuesta:** Identidad de huéspedes, adulto responsable, reserva/pacto si existe, estancia, habitación/categoría real, ocupantes, periodos previstos/reales, bloqueos y motivos de cambio/excepción autorizada.

**Reglas y comportamiento esperado:**

- Registrar huéspedes antes de ocupar y adulto responsable por habitación.
- Una reserva puede originar varias estancias y puede haber estancia sin reserva con disponibilidad.
- No exceder capacidad salvo excepción autorizada y documentada.
- Mantener ocupaciones y cambios de habitación con momento/motivo; distinguir categoría contratada y proporcionada.
- Ampliación requiere disponibilidad; registrar salida real de habitación sin confundirla con cierre financiero de toda estancia.

**Relaciones o conceptos relacionados:** Estancia, ocupación, huéspedes–ocupación, persona, habitación/categoría, reserva y bloqueo. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Ocupación por habitación/noche y huésped, llegadas parciales, cambios y salidas reales; categoría contratada/proporcionada consultables.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G06-P02-V | Registrar dos llegadas de una reserva que originan estancias distintas y una llegada sin reserva disponible. Trasladar huésped de habitación y consultar dónde estuvo en cada periodo. |
| G06-P02-I | Asignar habitación bloqueada/ocupada de manera incompatible o exceder capacidad sin excepción, o ingresar sin adulto responsable. No crear ocupación válida ni perder origen por fallo de traslado. |
| G06-P02-L | Capacidad exacta, excepción autorizada frente a exceso sin autorización y cambio de categoría. Edad que define adulto y convención de noches deben declararse sin presentarlas como un umbral dado por el caso. |

**Transacción:** Estancia/ocupantes/asignación requerida forman una unidad coherente; el traslado fallido conserva alojamiento previo. Salida real y liberación de habitación deben concordar.

**Concurrencia pertinente:** Dos sesiones asignan la misma habitación o una amplía ocupación mientras otra la adjudica. No quedan periodos incompatibles ni capacidad excedida sin autorización. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G06-P02-01:** Se demuestra llegada desde reserva, llegada sin reserva y multiplicidad de estancias por reserva.
- **AC-G06-P02-02:** Se conservan huéspedes, adulto responsable, periodos y categoría real/contratada.
- **AC-G06-P02-03:** Capacidad/bloqueos/excepciones se comprueban y los movimientos no borran noches anteriores.
- **AC-G06-P02-04:** Fallo/concurrencia no produce doble ocupación incompatible ni pérdida del alojamiento anterior.

**Límite del proceso:** No incluye nómina/limpieza ni operación interna del restaurante. Las tarifas y autorizaciones pueden prepararse. Registrar ocupación/salida es necesario para este proceso; el cierre completo se demuestra en G06-P03.

**Fundamento del caso:** secciones Llegada, estancia y salida; Huéspedes, contactos y empresas; Habitaciones y características. Los procesos se numeran consecutivamente dentro de este anexo.

### G06-P03 — Aplicar pagos y cerrar estancia

**Necesidad:** Aplicar dinero a obligaciones identificables y distinguir salida de habitaciones del cierre de una estancia.

**Situación operativa:** Una estancia tiene cargos/adelantos y pagos de huésped o empresa por conceptos autorizados. Se distribuye un pago entre cargos y se cierra únicamente con saldo cero, sin habitaciones ocupadas ni consumos pendientes de revisión.

**Información requerida, sin firma SQL impuesta:** Estancia, ocupaciones/salidas reales, cargos de noches efectivas y condiciones pactadas, consumos y revisión, descuentos autorizados si existen, responsable por concepto, pagos/aplicaciones, medio/referencia y saldo.

**Reglas y comportamiento esperado:**

- Distinguir adelantos, cargos, descuentos autorizados y pagos sin contar dos veces un adelanto.
- Pago puede cubrir varios cargos y cargo recibir varios pagos.
- Conservar responsabilidad de empresa/huésped según autorización y concepto.
- Cargos de alojamiento se corresponden con noches efectivas y pacto; no usar automáticamente total previsto como monto real.
- Para esta segunda entrega, por aclaración docente, cerrar exige saldo cero, sin habitaciones ocupadas ni consumos pendientes de revisión. El saldo se obtiene de cargos, descuentos autorizados y aplicaciones válidas; no basta cambiar el estado a cerrado.

**Relaciones o conceptos relacionados:** Pago, aplicación pago–cargo, cargo, consumo/revisión, autorización por concepto, estancia/ocupación y condiciones pactadas. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Distribución y saldos consultables por cargo/responsable/estancia; cierre persistido solo con saldo cero y las demás condiciones satisfechas. Una estancia con deuda puede registrar salida física, pero permanece pendiente de cierre.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G06-P03-V | Aplicar un pago a varios cargos y completar uno de ellos con otro pago, mostrando adelanto y responsabilidad empresarial/huésped sin doble contabilización. Saldar las obligaciones mediante pagos o ajustes autorizados válidos, registrar salidas y revisión necesarias y confirmar el cierre con saldo cero verificable. |
| G06-P03-I | Intentar aplicación de pago/cargo de contexto ajeno o cantidad superior al disponible/pendiente. Intentar cerrar con saldo pendiente, incluso si todas las habitaciones se entregaron y todos los consumos se revisaron; rechazar y conservar el estado previo. También rechazar cierre con saldo cero si hay habitación ocupada o consumo sin revisar. |
| G06-P03-L | Comparar liquidación exacta con un residuo positivo mínimo según la precisión monetaria declarada: solo la primera satisface saldo cero. Probar pago ya distribuido para evitar duplicación por reintento. Una salida física con saldo pendiente no equivale a cierre. |

**Transacción:** Aplicaciones y saldos derivados deben concordar; el cierre verifica conjuntamente saldo cero, habitaciones desocupadas y consumos revisados. Un fallo de distribución no deja importe aplicado parcialmente sin resultado válido ni estado cerrado con deuda.

**Concurrencia pertinente:** Dos sesiones aplican al mismo pendiente o una intenta cerrar mientras otra modifica una obligación de la estancia. La decisión final no excede pagos/cargos ni deja cerrado con saldo distinto de cero, habitación ocupada o consumo pendiente de revisión. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G06-P03-01:** Las aplicaciones N:M explican cada importe y el saldo sin duplicar adelanto.
- **AC-G06-P03-02:** Las responsabilidades/conceptos y cargos de noches efectivas son verificables.
- **AC-G06-P03-03:** Se rechaza exceso/cruce de contexto y cierre con saldo pendiente, ocupación o revisión pendiente.
- **AC-G06-P03-04:** El cierre confirmado acredita saldo cero y demás condiciones; el rechazo por saldo residual conserva el estado previo y los fallos/conflictos no dejan cierre con deuda.

**Límite del proceso:** No se añade como cuarto proceso el registro operativo de todos los servicios, sus anulaciones o tarifas. Cargos/consumos pueden prepararse de forma trazable con datos de prueba y comprobar su revisión; se exige aplicación y cierre efectivos. No incluye devolución bancaria, contabilidad ni facturación.

**Fundamento del caso:** secciones Servicios y cargos; Llegada, estancia y salida. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** Persona; MedioContactoPersona; Empresa; Reservación; ModificaciónReservación; DetalleReservación; CategoríaHabitación; Habitación; CaracteristicaHabitacion; Bloqueo; PlanTarifario; Tarifa; Estancia; OcupaciónHabitación; HuéspedOcupación; ConceptoAutorizado; Servicio; PlanServicio; Consumo; Cargo; Pago; PagoCargo.

| Área de atención | Verificación requerida y límite |
|---|---|
| Modelo completo y pactos | Implementar las 22 relaciones finales y ajustes justificados. Condición/precio pactados son históricos, no una referencia que cambia con el plan actual. Revisar coherencia de la redundancia declarada de Cargo. |
| Responsabilidad y autorizaciones | Tipo/documento, contacto y responsabilidad de reserva; autorización de empresa por conceptos y división con huésped cuando aplica. |
| Inventario temporal | Disponibilidad incluye habitación física, reservas, estancias y bloqueos. Categoría solicitada no es habitación concreta ni categoría finalmente proporcionada. |
| Consumo/cargo | Probar cantidad/precio/origen, responsable y corrección/anulación con motivo/autor. Cargos de alojamiento se explican por noches efectivamente ocupadas y condiciones pactadas, no solo por estimación. |
| Aplicación/cierre | Comprobar pago–cargo en contexto, adelanto sin doble cómputo y cierre únicamente con saldo cero, sin habitaciones ocupadas ni consumos pendientes de revisión. El saldo cero es aclaración docente de esta segunda entrega; no queda a elección del equipo. Probar cierre válido y rechazo por saldo residual. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Lab03 implementó ocho relaciones de reservación y pagos asociados, sin habitación, estancia, consumo, cargo ni aplicación N:M completa. Se aceptaba reserva directa sin detalle; ahora la confirmación completa debe demostrarlo. Los requisitos actuales se fundamentan en el caso y la retroalimentación identificada; las dudas de localización de evaluaciones no generan una tarea adicional para el grupo.

**Reutilización efectiva:** Reutilizar cálculos de precio pactado, datos y restricciones válidas e historial de cancelación/modificación. No confundir total previsto con cargo por noches reales ni contador de adelanto con distribución de pagos a cargos.

**Distinción entre defecto, observación y supuesto:** Los umbrales dos días/siete días de Lab03 son supuestos, no políticas universales. El cursor de vencimiento seleccionaba reservas sin ningún adelanto, no todas las que lo tenían incompleto. No se exige reescribirlo ni convertirlo en proceso evaluable aquí. La edad de adulto y convención de noches deben declararse; no se fijan por inferencia.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

Los umbrales dos días/siete días de Lab03 son supuestos, no políticas universales. El cursor de vencimiento seleccionaba reservas sin ningún adelanto, no todas las que lo tenían incompleto. No se exige reescribirlo ni convertirlo en proceso evaluable aquí. La edad de adulto y convención de noches deben declararse; no se fijan por inferencia.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Hotel Mirador del Valle, secciones Huéspedes, contactos y empresas, Habitaciones y características, Tarifas y reservaciones, Llegada, estancia y salida y Servicios y cargos; PDF P1 pp.12–21/42–45; Lab03 del grupo.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
