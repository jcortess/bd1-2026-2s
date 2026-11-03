# IC-4301 — Segunda entrega, Grupo 07: Eventos Nexo

## A. Contexto y alcance obligatorio

Eventos Nexo convierte solicitudes y propuestas en compromisos de espacios, servicios, recursos y personal. Debe conservar alternativas, versiones y decisiones y evitar dobles reservas incompatibles.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Se desarrollan propuesta/aceptación, reserva de espacios/recursos y cronograma/personal. No se añade cobro —aunque Lab03 lo implementó— ni contratación comercial completa, incidencias o cierre del evento como otros procesos.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G07-P01 — Versionar y aceptar propuestas

**Necesidad:** Conservar lo ofrecido y lo aceptado para un evento sin cambiar retrospectivamente versiones o autorizaciones.

**Situación operativa:** El cliente evalúa alternativas y varias versiones de servicios. Acepta componentes mediante persona facultada y confirma propuesta para organizar evento.

**Información requerida, sin firma SQL impuesta:** Solicitud/alternativas, versión, componentes con cantidades/precios/condiciones/vigencia, aceptación/rechazo/pendiente, persona facultada y adelanto requerido; correspondencia de propuesta/alternativa/evento.

**Reglas y comportamiento esperado:**

- Conservar versiones anteriores y componentes, sin sobrescritura silenciosa.
- Permitir aceptación parcial/rechazo/modificación y conservar la persona que autorizó.
- La confirmación identifica propuesta y alternativa de la misma solicitud.
- Mantener el compromiso del modelo RN-08 de un único evento por solicitud; UNIQUE en eslabones distintos no basta para demostrarlo.

**Relaciones o conceptos relacionados:** Solicitud, alternativa, propuesta/componentes, evento, autorización específica y servicios aceptados. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Versiones comparables, resultado por componente y evento confirmado con origen/autorizante inequívocos.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G07-P01-V | Crear dos versiones, aceptar algunos componentes y confirmar una alternativa de la misma solicitud. Consultar precios/versiones anteriores y resultado de componentes. |
| G07-P01-I | Intentar confirmar con alternativa de otra solicitud o crear un segundo evento por otra propuesta/alternativa de la misma solicitud. No generar compromiso duplicado ni cruce de origen. |
| G07-P01-L | Cambio solo de cantidad/precio y componente pendiente. La aceptación parcial no implica contratar de manera automática todo lo ofrecido por un proveedor. |

**Transacción:** Confirmación, origen, componentes comprometidos y autorización requeridos coherentes. Fallo en un componente no deja evento confirmado sin detalle aceptado correspondiente.

**Concurrencia pertinente:** Dos sesiones confirman versiones/alternativas de la misma solicitud. Solo puede quedar un evento conforme al compromiso RN-08, sin pérdida de las versiones no aceptadas. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G07-P01-01:** Se distinguen versiones, componentes y decisiones sin borrar lo previo.
- **AC-G07-P01-02:** El evento identifica solicitud/propuesta/alternativa/autorizante coherentes.
- **AC-G07-P01-03:** No se admiten segundo evento por solicitud ni cruce entre solicitudes.
- **AC-G07-P01-04:** La confirmación incompleta o concurrente no deja compromiso inválido.

**Límite del proceso:** No incluye registrar/aplicar pagos, gestionar contratación completa o ejecutar ajustes posteriores como nuevos procesos. El adelanto requerido se conserva como condición; el cobro Lab03 puede reutilizarse sin convertirlo en proceso adicional.

**Fundamento del caso:** secciones Solicitud y propuesta; Clientes y contactos. Los procesos se numeran consecutivamente dentro de este anexo.

### G07-P02 — Reservar espacios y recursos

**Necesidad:** Evitar compromisos incompatibles de espacios/áreas y recursos reutilizables incluyendo preparación y traslado.

**Situación operativa:** Se reserva espacio propio/tercero y recursos para evento; hay reserva provisional con vencimiento y luego confirmación. Un cambio de espacio debe conservar antecedente y motivo.

**Información requerida, sin firma SQL impuesta:** Evento, espacio/área/configuración, capacidad y asistentes pertinentes, recurso/tipo/condición, intervalos de montaje/evento/desmontaje y preparación/traslado, estado, vencimiento y confirmación externa si aplica.

**Reglas y comportamiento esperado:**

- Solo reservar áreas independientemente cuando configuración del espacio lo permita.
- No confirmar actividades incompatibles que se traslapen en espacio/área.
- Incluir montaje/desmontaje y preparación/traslado de recursos, no solo horario visible.
- Reserva provisional tiene vencimiento y condición de confirmación; cambio conserva motivo y opción anterior.
- Evento puede usar varios espacios y recursos.

**Relaciones o conceptos relacionados:** Espacio/área/características, reserva de espacio, recurso/reserva de recurso, evento y actividades como contexto. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Ocupación/compromisos por periodo y estado; conflictos explicables, vencimientos y cambios conservados.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G07-P02-V | Reservar dos espacios para un evento y un recurso con preparación. Confirmar provisional tras cumplir su condición y cambiar otro espacio conservando opción/motivo. |
| G07-P02-I | Intentar solapamiento incompatible solo durante montaje/desmontaje o traslado, o reservar área como independiente sin configuración habilitada. No confirmar compromiso conflictivo. |
| G07-P02-L | Reservas contiguas según convención y provisional vencida. Documentar cómo se trata su capacidad antes/después del vencimiento sin inventar plazo universal ni algoritmo automático obligatorio. |

**Transacción:** Cada reserva/cambio requerido y su historia se mantienen coherentes; un cambio inválido no pierde reserva anterior ni crea la nueva incompatible.

**Concurrencia pertinente:** Dos sesiones confirman el mismo espacio/área/recurso para periodos incompatibles. Mostrar el conjunto final, considerando reservas provisionales según política declarada. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G07-P02-01:** Los periodos incluyen tiempos auxiliares y se consultan por recurso/espacio.
- **AC-G07-P02-02:** Se respeta configuración de áreas e incompatibilidad.
- **AC-G07-P02-03:** Vencimiento/confirmación y cambios quedan trazables.
- **AC-G07-P02-04:** La concurrencia y fallo no producen doble compromiso incompatible ni pérdida de antecedente.

**Límite del proceso:** No incluye inventario de consumibles ni compra/alquiler comercial completo de recursos. La política de qué actividades son compatibles debe explicarse con el caso/configuración; no prohibir por defecto todos los usos simultáneos de áreas realmente independientes.

**Fundamento del caso:** secciones Espacios y reservaciones; Servicios, proveedores y recursos. Los procesos se numeran consecutivamente dentro de este anexo.

### G07-P03 — Planificar actividades y personal

**Necesidad:** Mantener cronograma vigente y cambios significativos sin asignar personas o recursos a actividades incompatibles.

**Situación operativa:** Se planifica montaje/actividad/desmontaje con responsables y dependencias; el cliente cambia un horario que afecta actividades y compromisos.

**Información requerida, sin firma SQL impuesta:** Evento, actividades con periodo/espacio/responsable, dependencias, servicios/recursos requeridos, personal/función/periodo y versiones; solicitante y efectos del cambio.

**Reglas y comportamiento esperado:**

- Una actividad tiene periodo, espacio y responsable; puede depender de finalizar otra.
- Conservar versión vigente y cambios significativos, solicitante y actividades/reservas/contrataciones afectadas.
- No asignar persona simultáneamente a actividades incompatibles.
- No aceptar cambio que genere conflicto de espacio, proveedor o recurso; una dependencia no se resuelve solo por existir la actividad referenciada.

**Relaciones o conceptos relacionados:** Actividad/versiones, asignación de personal, reservas de espacio/recurso, evento y contratación/servicio como condiciones previas. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Cronograma vigente e historial, funciones/responsables y efectos del cambio sobre compromisos consultables.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G07-P03-V | Crear actividades con dependencia y personal, cambiar horario y conservar versión/solicitante/efectos. Verificar horario vigente y que la actividad anterior sigue reconstruible. |
| G07-P03-I | Intentar sucesora antes de finalizar precedente según plan, doble asignación incompatible de persona o cambio que choque con recurso/espacio/contratación existente. No publicar versión inválida. |
| G07-P03-L | Actividad sin precedente y periodos consecutivos. El supuesto anterior de un único predecesor debe justificarse y no usarse para perder dependencias necesarias; no exigir por cantidad un modelo de grafo más amplio que el caso. |

**Transacción:** La nueva versión y los ajustes necesarios de asignaciones/reservas forman un estado coherente; si el cambio se rechaza, permanece cronograma previo y sus compromisos.

**Concurrencia pertinente:** Dos sesiones cambian cronograma o asignan la misma persona a actividades incompatibles. Evitar pérdida silenciosa de versión confirmada y doble asignación. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G07-P03-01:** Se consulta versión vigente y se reconstruyen cambios significativos con solicitante.
- **AC-G07-P03-02:** Dependencias, responsables/funciones y periodos son verificables.
- **AC-G07-P03-03:** Un cambio considera sus recursos, espacios y condiciones contractuales preparadas.
- **AC-G07-P03-04:** Fallo/concurrencia no publica cronograma incompatible ni borra el previo.

**Límite del proceso:** No incluye operar incidencias durante evento ni sustituir proveedores mediante un cuarto flujo. Contratos/servicios previos pueden prepararse; el cambio de cronograma sí debe comprobar su compatibilidad y registrar efectos pertinentes.

**Fundamento del caso:** secciones Cronograma y responsables; Servicios, proveedores y recursos. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** ESPACIO; ESPACIO_CARACTERISTICA; AREA; SERVICIO; PROVEEDOR; PROVEEDOR_SERVICIO; RECURSO; PERSONA; CLIENTE; MEDIO_CONTACTO; CONTACTO_CLIENTE; SOLICITUD; ALTERNATIVA_SOLICITUD; PROPUESTA; PROPUESTA_SERVICIO; EVENTO; EVENTO_AUTORIZADO; AJUSTE_EVENTO; RESERVA_ESPACIO; SERVICIO_EVENTO; CONTRATACION; ACTIVIDAD; ACTIVIDAD_VERSION; RESERVA_RECURSO; ASIGNACION_PERSONAL; INCIDENCIA; CARGO; PAGO; APLICACION_PAGO.

| Área de atención | Verificación requerida y límite |
|---|---|
| Origen del evento | La RN-08 del modelo compromete un evento por solicitud. Comprobar coherencia propuesta/alternativa/solicitud, no solo unicidad de dos referencias independientes. |
| Componentes e historia | Precios/cantidades ofrecidos, aceptación parcial, cambios y autorizante se conservan. No confundir candidato opcional con identificador válido de todas las filas. |
| Proveedores/servicios | Probar servicio repetido por evento en momentos/espacios diferentes, proveedor elegido y condiciones históricas/sustitución; la observación sobre oferta histórica no obliga a operar contratación como cuarto proceso. |
| Tiempo y dependencias | Montaje/desmontaje/preparación/traslado, divisibilidad de áreas, dependencias y asignación incompatible deben verificarse con su significado, no con un único CHECK de estado. |
| Finanzas y contexto | Conservar mejoras de FK de evento en cargos/aplicaciones; verificar montos, origen y estado. Si el dominio anuncia tipos no utilizables, resolver coherencia del modelo completo sin inventar otro flujo de cobro asignado. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Punto de partida de 29 relaciones. Lab03 implementó 12 principalmente para cobro. Se demostró segundo evento por solicitud y cruce entre propuesta/alternativa de solicitudes distintas, ya observados desde P1; en aceptación deben quedar corregidos. Las buenas referencias de contexto financiero se conservan.

**Reutilización efectiva:** Reutilizar catálogo mínimo, funciones de saldo/estado, aplicación transaccional de pago y sus pruebas como evidencia del esquema completo. No se exige reescribir el cursor válido ni volver a evaluar cobro como un cuarto proceso.

**Distinción entre defecto, observación y supuesto:** El supuesto de un solo predecesor no es regla literal del caso; justificar su suficiencia sin borrar dependencias necesarias. No imponer incompatibilidad de toda área simultánea si configuración permite independencia. Las rutas de escritura financiera y sus permisos deben quedar documentadas; el resultado secuencial no prueba concurrencia general.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

El supuesto de un solo predecesor no es regla literal del caso; justificar su suficiencia sin borrar dependencias necesarias. No imponer incompatibilidad de toda área simultánea si configuración permite independencia. Las rutas de escritura financiera y sus permisos deben quedar documentadas; el resultado secuencial no prueba concurrencia general.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Eventos Nexo, secciones Clientes y contactos, Solicitud y propuesta, Espacios y reservaciones, Servicios, proveedores y recursos y Cronograma y responsables; P1 §3.2/RN-08 y retroalimentaciones.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
