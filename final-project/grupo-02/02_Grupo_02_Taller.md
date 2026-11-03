# IC-4301 — Segunda entrega, Grupo 02: Taller Ruta 27

## A. Contexto y alcance obligatorio

Taller Ruta 27 recibe vehículos, diagnostica hallazgos, presenta trabajos al cliente y registra su autorización y ejecución. Cada visita es una orden; cambios de propietario o de promesas de entrega no deben reescribir visitas previas.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Se desarrollan presupuesto/autorización, ejecución técnica/pruebas y estados/promesa de entrega. La ejecución incluye registrar consumos si una labor usa repuestos; no añade compras/proveedores, entrega comercial ni garantía como flujos funcionales independientes.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G02-P01 — Versionar propuestas y autorizar labores

**Necesidad:** Distinguir trabajo ofrecido, aceptado, rechazado y pendiente sin reemplazar presupuestos anteriores.

**Situación operativa:** Tras los hallazgos de una orden se presenta una propuesta; aparecen necesidades adicionales y se emite otra versión. La persona facultada responde por cada labor.

**Información requerida, sin firma SQL impuesta:** Orden/hallazgos, versión y componentes, labores/repuestos estimados con cantidades/precios informados, decisión por labor, fecha, medio y persona facultada; justificación si se usa la excepción de emergencia.

**Reglas y comportamiento esperado:**

- Conservar propuestas anteriores y sus precios/alcance.
- Permitir aceptación parcial y decisiones pendientes; identificar fecha, medio y persona que responde.
- Una labor rechazada no se ejecuta bajo esa autorización.
- Identificar a quien responde no demuestra por sí solo su facultad durante la visita.

**Relaciones o conceptos relacionados:** Orden, hallazgo, propuesta, labor, repuestos propuestos, autorización por labor y representación del cliente. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Comparación de versiones y situación de cada labor; autorización atribuible al contexto correcto de orden/cliente.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G02-P01-V | Crear una propuesta con varias labores, aceptar una, rechazar otra y dejar otra pendiente. Emitir ampliación y consultar que la versión anterior y sus decisiones/precios permanecen. |
| G02-P01-I | Intentar atribuir decisión a persona sin facultad o a labor de otra orden/versión. No generar una autorización válida para ese trabajo ni modificar silenciosamente la propuesta anterior. |
| G02-P01-L | Nueva versión que cambia solo un precio o añade una labor; propuesta con decisiones incompletas. Precisar cómo se reconoce la decisión aplicable sin que una ampliación autorice por arrastre lo rechazado. |

**Transacción:** Publicar versión con sus componentes y registrar cada decisión de manera coherente; un fallo de detalle no deja propuesta presentada incompleta ni autorización huérfana.

**Concurrencia pertinente:** Dos sesiones emiten una versión o decisiones incompatibles para la misma labor. No perder el antecedente ni hacer ejecutable un trabajo por una combinación ambigua de versiones/decisiones. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G02-P01-01:** Se comparan versiones sin pérdida de la propuesta previa.
- **AC-G02-P01-02:** Cada labor tiene situación y, cuando se decidió, actor/medio/fecha verificables.
- **AC-G02-P01-03:** No se autorizan labores de contexto ajeno ni por persona no facultada.
- **AC-G02-P01-04:** La autorización que permite ejecución es identificable y no se deduce solo del último cliente registrado.

**Límite del proceso:** No incluye comprar repuestos, administrar proveedores o tramitar garantías. Los hallazgos y catálogos pueden prepararse; aquí se exige presupuesto y autorización, no rehacer recepción de Lab03.

**Fundamento del caso:** secciones Diagnóstico y presupuesto; Clientes y vehículos. Los procesos se numeran consecutivamente dentro de este anexo.

### G02-P02 — Ejecutar reparaciones y pruebas

**Necesidad:** Demostrar qué se ejecutó realmente, quién intervino y si la verificación confirmó o no el resultado.

**Situación operativa:** Se inicia una labor autorizada con varios técnicos; puede depender de otra. Una prueba detecta que la falla continúa y se registra nueva intervención vinculada.

**Información requerida, sin firma SQL impuesta:** Labor y autorización aplicable o emergencia justificada, estado, dependencias, técnicos/participaciones y periodos/tiempo, repuestos realmente instalados si los hay, prueba con autor, momento y medición o descripción.

**Reglas y comportamiento esperado:**

- No ejecutar labor rechazada; emergencia solo permite labor mínima para evitar riesgo y exige justificación.
- Conservar participación de uno o varios técnicos y tiempo dedicado.
- Respetar dependencia de finalización antes de avanzar una labor que la requiera.
- Pruebas heterogéneas; una revisión/retrabajo debe enlazar la intervención previa sin eliminarla.
- Distinguir repuesto estimado de cantidad/precio efectivamente usados cuando la labor los incorpora.

**Relaciones o conceptos relacionados:** Labor, autorización, participación técnica, especialidad histórica, prueba, consumo de repuesto y relación con labor revisada. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Historia de estados y participaciones de la labor, resultados de pruebas y relación de retrabajo; comparación propuesto/ejecutado.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G02-P02-V | Ejecutar una labor autorizada con dos participaciones, registrar una prueba con resultado desfavorable y una intervención posterior ligada a la original. Mostrar tiempos/resultados e insumos usados donde corresponda. |
| G02-P02-I | Intentar iniciar labor rechazada o dependiente de otra aún no finalizada. Probar referencia a técnico/labor ajena inexistente. No avanzar el trabajo como si estuviese habilitado. |
| G02-P02-L | Labor sin repuestos ni medición numérica; prueba descriptiva válida. Emergencia mínima documentada no debe autorizar toda la propuesta. Conservar participación sin confundir duración de intervalo con tiempo efectivo si son distintos. |

**Transacción:** Los cambios que el equipo defina como ejecución/registro de participación/consumo deben mantener sus vínculos. Un fallo no deja labor completada con registro obligatorio ausente ni consumo sin origen.

**Concurrencia pertinente:** Dos sesiones completan o modifican la misma labor mientras se registra una prueba/intervención. No perder participaciones ni producir estados contradictorios con dependencias; documentar el orden confirmado. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G02-P02-01:** Lo ejecutado se distingue de lo propuesto y conserva técnicos, tiempos y resultados.
- **AC-G02-P02-02:** La autorización o excepción que habilitó ejecución es verificable.
- **AC-G02-P02-03:** Dependencias y estados se respetan sin eliminar intervenciones previas.
- **AC-G02-P02-04:** El retrabajo conserva vínculo con labor revisada y el fallo técnico no deja una ejecución parcial presentada como completa.

**Límite del proceso:** No se asigna el flujo independiente de compras, reserva/liberación integral de inventario ni entrega del vehículo. Si la ejecución usa repuestos, debe registrar consumo y respetar existencias/reglas del modelo con movimientos pertinentes; no requiere construir toda la operación comercial de proveedores.

**Fundamento del caso:** secciones Reparaciones y participación técnica; Diagnóstico y presupuesto; Repuestos. Los procesos se numeran consecutivamente dentro de este anexo.

### G02-P03 — Gestionar estados y fecha prometida

**Necesidad:** Explicar el estado de una orden y los compromisos de entrega comunicados, incluidos cambios y retrocesos permitidos.

**Situación operativa:** La orden avanza a reparación o regresa a diagnóstico; se comunica una nueva fecha prometida por un atraso.

**Información requerida, sin firma SQL impuesta:** Orden existente, transición solicitada, actor/momento, motivo aplicable; fecha prometida anterior/nueva y momento de comunicación de la modificación.

**Reglas y comportamiento esperado:**

- Los estados no forman obligatoriamente una secuencia lineal: puede volver a diagnóstico.
- Conservar quién registró cada estado y cuándo.
- La fecha prometida puede cambiar, pero cada modificación conserva cuándo se comunicó y su motivo.
- No confundir historial de estados con historial de promesas ni borrar antecedentes al cancelar.

**Relaciones o conceptos relacionados:** Orden de trabajo, historial de orden, historial de fecha prometida y personal identificado. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Estado actual determinable y cronología de estados/promesas con valores y atribución; pendientes consultables.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G02-P03-V | Registrar avance, retorno a diagnóstico y dos cambios de promesa para una orden. Verificar orden cronológico, fecha original y actual, motivo y actor. |
| G02-P03-I | Intentar cambio sobre orden inexistente o sin la información que exige su historia. Fallar una parte del registro y verificar que no cambia el actual sin su antecedente correspondiente. |
| G02-P03-L | Cambios con mismo instante registrado: documentar orden inequívoco sin inventar una transición perdida. Una orden cancelada sigue consultable. No se impone prohibición universal de retroceso. |

**Transacción:** El valor actual y su registro histórico se confirman juntos; no aceptar sobrescritura de fecha que vuelva imposible reconstruir la promesa anterior.

**Concurrencia pertinente:** Dos sesiones cambian estado/promesa de la misma orden. Debe poder reconstruirse el orden efectivamente confirmado sin pérdida silenciosa del primer cambio. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G02-P03-01:** Se reconstruyen estado actual y todas las promesas anteriores.
- **AC-G02-P03-02:** Cada transición conserva responsable/momento y cada promesa su comunicación/motivo.
- **AC-G02-P03-03:** Se demuestra un retroceso legítimo a diagnóstico.
- **AC-G02-P03-04:** Un fallo o conflicto no deja historia y actual en desacuerdo.

**Límite del proceso:** No añade seguimiento de garantía ni entrega completa. La historia de promesa es exigencia expresa de esta entrega; esto no decide retroactivamente si su exclusión fue válida en Lab03.

**Fundamento del caso:** secciones Ingreso y orden de trabajo; Necesidades de información. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** CLIENTE; CONTACTO_CLIENTE; VEHICULO; PERSONAL; ORDEN_TRABAJO; OBJETO_DANO; HISTORIAL_ORDEN; HISTORIAL_FECHA_PROMETIDA; HALLAZGO; PROPUESTA; LABOR; AUTORIZACION_LABOR; PARTICIPACION_TECNICA; ESPECIALIDAD_TECNICO; PRUEBA; REPUESTO; PROVEEDOR_REPUESTO; REPUESTO_PROPUESTO; CONSUMO_REPUESTO; MOVIMIENTO_INVENTARIO; PIEZA_RETIRADA; ENTREGA; GARANTIA_RECLAMO.

| Área de atención | Verificación requerida y límite |
|---|---|
| Identidad y roles | VIN estable y papeles por visita; verificar contactos y facultad real para aprobar/retirar donde corresponda, no solo existencia del cliente. |
| Autoría y participación | Hallazgo, participación y prueba deben conservar atribución exigida por el caso; las especialidades/periodos del técnico no se sustituyen por texto sin significado temporal. |
| Repuestos y movimientos | Distinguir presupuesto, reserva, consumo y pieza retirada. Verificar cantidad/precio/contexto y origen de movimientos; datos preparados no habilitan existencias negativas o pérdida inexplicada. |
| Entrega y garantía | Probar referencias y condiciones de entrega y garantía otorgada antes de eventual reclamo; evitar que solo pueda existir garantía cuando hay reclamación. Una prueba de integridad no obliga a implementar el flujo completo de entrega/garantía. |
| Historia | Estados y promesas son hechos diferentes; probar actor, momento, motivo y coherencia del actual, sin suponer una trayectoria lineal obligatoria. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Lab03 implementó seis tablas de recepción/diagnóstico y alta con historial inicial. No implementó propuestas, reparaciones ni historia de fecha prometida. La sobrescritura de la promesa sin historia fue demostrada; en G02-P03 debe conservarse el antecedente. Revisión P1 señaló autor de hallazgo, facultades y garantía/reclamo insuficientemente diferenciados.

**Reutilización efectiva:** Reutilizar identidades, alta de orden con estado inicial y consultas de pendientes/hallazgos; corregir rótulos de Q02/Q04 para que describan visitas por vehículo y conteo por estado. No reescribir el alta válida solo por quedar como preparación de estos procesos.

**Distinción entre defecto, observación y supuesto:** La discusión anterior sobre si reprogramación quedaba fuera de Lab03 no modifica su nota. En esta segunda entrega la fecha prometida está expresamente asignada. No se impone un catálogo de transiciones lineales ni se convierte urgencia didáctica en autorización automática de reparación.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

La discusión anterior sobre si reprogramación quedaba fuera de Lab03 no modifica su nota. En esta segunda entrega la fecha prometida está expresamente asignada. No se impone un catálogo de transiciones lineales ni se convierte urgencia didáctica en autorización automática de reparación.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Taller Ruta 27, secciones Clientes y vehículos, Ingreso y orden de trabajo, Diagnóstico y presupuesto, Reparaciones y participación técnica y Repuestos; modelo final §7.1 y observaciones P1/Lab03.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
