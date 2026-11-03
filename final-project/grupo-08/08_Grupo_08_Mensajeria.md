# IC-4301 — Segunda entrega, Grupo 08: Envíos Conecta

## A. Contexto y alcance obligatorio

Envíos Conecta organiza solicitudes, guías y paquetes, salidas de ruta y eventos de seguimiento. Debe reconstruir dirección, cotización, ubicación y responsable de cada paquete aunque cambien catálogos o asignaciones.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Se desarrollan creación/revisión de envíos/paquetes, salida/manifiesto y seguimiento/incidencia. No se añaden operación completa de recolección, intentos de entrega/devolución, cobro, GPS ni optimización como procesos funcionales.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G08-P01 — Crear envíos y paquetes

**Necesidad:** Transformar solicitud en guías y paquetes con origen/destino, cotización y revisión inicial trazables.

**Situación operativa:** Un cliente distribuye a varios destinos: una solicitud origina varios envíos; cada uno tiene paquetes con condiciones. Se compara declaración con revisión/medición posterior sin borrar anteriores.

**Información requerida, sin firma SQL impuesta:** Solicitud/cliente, guía, fecha, remitente/destinatario y contacto, direcciones usadas, servicio/responsable de pago, precio cotizado y datos de cálculo, identificación interna de paquete, peso/dimensiones/contenido/condiciones, revisión con actor/momento/resultado/razón y respaldo si aplica.

**Reglas y comportamiento esperado:**

- Guía única; paquete identificado dentro de envío; varios envíos por solicitud y varios paquetes por envío.
- Remitente/destinatario no necesariamente cliente registrado; conservar cómo contactarlos.
- Direcciones usadas y cotización no cambian al actualizar catálogo/dirección habitual.
- Rechazar material prohibido y exigir respaldo para contenido que lo requiera; revisión inicial tiene resultado y razón.
- Conservar declarado y mediciones posteriores, identificando qué se usó para clasificar/cotizar.

**Relaciones o conceptos relacionados:** Solicitud, participante/medios, envío, paquete/condiciones, medición/revisión, tarifa/cotización y dirección histórica. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Guías con paquetes y contexto; declarado/medido y precio/criterios conservados; aceptado/retenido/rechazado explicable.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G08-P01-V | Desde una solicitud crear envíos a dos destinos, uno con varios paquetes y participante no cliente. Registrar revisión y verificación posterior; cambiar dirección habitual y comprobar que origen/destino y cotización anteriores permanecen. |
| G08-P01-I | Intentar guía duplicada, paquete sin envío válido o contenido prohibido presentado como aceptado; respaldo exigido ausente. El resultado no puede registrar aceptación indebida ni crear cabecera incompleta como éxito. |
| G08-P01-L | Paquete retenido frente a rechazado; diferencia entre dato declarado y medido. Preparar categorías de contenido/tarifa explícitas: no inventar lista legal ni fórmula universal. No obligar recolección ejecutada para poder crear todo envío si el caso no la exige. |

**Transacción:** La creación comprometida de guía y detalle debe quedar coherente. Revisión rechazada/retención puede persistir como decisión con causa, pero no habilitar transporte como aceptado.

**Concurrencia pertinente:** Dos sesiones intentan misma guía o registran cambios/mediciones del paquete. No duplicar identidad ni sobrescribir la medición anterior con la nueva. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G08-P01-01:** Se demuestra jerarquía solicitud–envío–paquete sin perder contexto y con guía única.
- **AC-G08-P01-02:** Se conserva participante/contacto y dirección/cotización del hecho histórico.
- **AC-G08-P01-03:** Revisión y respaldo distinguen aceptado, retenido y rechazado según datos/política declarados.
- **AC-G08-P01-04:** La medición posterior conserva declarado/previas y el criterio usado; fallo/conflicto no crea éxito parcial.

**Límite del proceso:** No añade operación completa de recolección o motor tarifario genérico. Las tarifas/condiciones de contenido y solicitud pueden prepararse; se conserva la cotización y se valida la revisión del envío. No incluye cargos adicionales ni pagos.

**Fundamento del caso:** secciones Solicitud, envío y paquetes; Clientes, contactos y direcciones; Tarifa del servicio. Los procesos se numeran consecutivamente dentro de este anexo.

### G08-P02 — Preparar salidas y manifiestos

**Necesidad:** Conocer qué paquetes viajan en una salida fechada con vehículo y responsables compatibles, y conservar sustituciones.

**Situación operativa:** Se prepara salida de ruta con varios paquetes aceptados; se comprueba carga y se cambia vehículo/persona antes de partir sin borrar asignación original.

**Información requerida, sin firma SQL impuesta:** Ruta/sede origen y destino/zona, fecha/periodo, paquetes y situación relevante, vehículo con capacidad peso/volumen/condición/mantenimiento, persona/función/periodo y motivo/momento de reemplazo.

**Reglas y comportamiento esperado:**

- Ruta catálogo no es salida concreta; antes de partir debe existir manifiesto de paquetes incluidos.
- La capacidad y condiciones del vehículo son compatibles con carga prevista.
- Evitar traslapes incompatibles de personas/vehículos y periodos fuera de servicio.
- Sustitución antes de inicio conserva original y motivo.
- Un paquete transferido conserva continuidad por seguimiento, sin desaparecer del manifiesto histórico.

**Relaciones o conceptos relacionados:** Ruta, sede, salida de ruta, salida–paquete, vehículo/fuera de servicio, personal/función y asignación/reemplazo. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Manifiesto por salida, capacidad comprometida y asignaciones vigentes/históricas consultables; conflicto de carga o recurso identificable.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G08-P02-V | Preparar salida con varios paquetes, comparar carga con capacidad y sustituir responsable/vehículo antes de comenzar con motivo. Consultar manifiesto y ambas asignaciones. |
| G08-P02-I | Intentar exceder peso o volumen, vehículo en mantenimiento o doble asignación incompatible de persona/vehículo. No dar por preparada/confirmada una salida inválida. |
| G08-P02-L | Carga exacta en una dimensión sin ignorar la otra; volumen de paquete y capacidad con unidades compatibles; paquetes rechazados/retenidos no pueden confundirse con carga aceptada sin resolución válida. |

**Transacción:** Salida, manifiesto y asignaciones requeridas coherentes. El fallo de un componente no consume capacidad o recurso como si todo hubiera sido confirmado; sustitución fallida conserva plan previo válido.

**Concurrencia pertinente:** Dos sesiones compiten por vehículo/persona o agregan paquetes al último margen de capacidad de la misma salida. La carga y compromisos finales respetan ambas capacidades e intervalos. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G08-P02-01:** Se consulta manifiesto completo antes de salida y se distingue ruta de salida fechada.
- **AC-G08-P02-02:** Se comprueban peso, volumen, condición y disponibilidad de vehículo/persona.
- **AC-G08-P02-03:** La sustitución conserva historia y causa.
- **AC-G08-P02-04:** Fallo/concurrencia no deja salida confirmada incompleta, sobrecarga o asignación incompatible.

**Límite del proceso:** No se exige optimización automática de rutas, GPS ni mantenimiento detallado. Rutas, sedes y periodos fuera de servicio se preparan como datos. No crear un proceso separado de custodia; sus movimientos se registran en G08-P03.

**Fundamento del caso:** secciones Sedes, clasificación y rutas; Vehículos y responsables. Los procesos se numeran consecutivamente dentro de este anexo.

### G08-P03 — Registrar seguimiento e incidencias

**Necesidad:** Reconstruir dónde estuvo cada paquete y quién lo tuvo, explicando incidencias y correcciones sin sobrescribir historia.

**Situación operativa:** Se registra recepción/salida/llegada o transferencia; un hecho afecta varios paquetes con resultados distintos y después se corrige un evento registrado por error.

**Información requerida, sin firma SQL impuesta:** Paquete/envío, tipo de evento aplicable, momento/ubicación/responsable/situación, movimientos/salida relacionados; incidencia con fecha, descripción, responsable de atención, estado y resultado por paquete; corrección con autor/causa/origen.

**Reglas y comportamiento esperado:**

- Eventos cronológicos permiten derivar ubicación o responsable actual sin sustituir la historia.
- No todos los eventos aplican a todos los envíos; no imponer una cadena universal.
- Incidencia puede afectar varios paquetes, con resultado determinable para cada uno.
- Corrección conserva qué se corrigió, quién y por qué.
- Ubicación debe representar el hecho real; no forzar sede/ruta ficticia cuando el hecho ocurrió fuera.

**Relaciones o conceptos relacionados:** Evento de seguimiento/corrección, paquete/envío, sede/salida/asignación como contexto e incidencia–paquete. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Cronología por paquete, situación/ubicación/responsable actual, historial de correcciones y resultados individuales de incidencia.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G08-P03-V | Registrar movimientos de paquetes por sedes y salida; crear incidencia común con resultado distinto por paquete y corregir un evento, conservando original/autor/causa. Consultar trayectoria y estado actual. |
| G08-P03-I | Intentar evento para paquete inexistente, cruce de identidad compuesta de otro envío o corrección sin origen/causa/autor. No desplazar ubicación actual mediante referencia inconsistente. |
| G08-P03-L | Eventos al mismo instante y hecho registrado después de ocurrir: declarar cómo se determina orden/actual sin borrar movimientos previos. Incidencia resuelta para un paquete y pendiente para otro; ubicación fuera de sede. |

**Transacción:** Evento y sus vínculos/corrección se registran coherentemente; incidencia y resultados por afectados no se reducen a un mensaje global que oculte pendientes.

**Concurrencia pertinente:** Dos sesiones registran/corrigen movimientos del mismo paquete o resuelven la misma incidencia. Conservar ambas acciones confirmadas y un actual determinable sin pérdida silenciosa. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G08-P03-01:** La cronología permite reconstruir ubicación/responsable y deriva el actual de forma explicada.
- **AC-G08-P03-02:** La incidencia identifica todos los paquetes afectados y su resultado individual.
- **AC-G08-P03-03:** La corrección conserva antecedente, actor y motivo.
- **AC-G08-P03-04:** Fallo/conflicto no pierde movimiento confirmado ni cruza paquete/envío; no se exige secuencia universal de eventos.

**Límite del proceso:** No incluye resolver intentos/entrega final/devolución como procesos adicionales. Sus hechos válidos pueden prepararse si se usan como eventos; no se exige custodias separadas, GPS ni optimización.

**Fundamento del caso:** secciones Seguimiento e incidencias; Recolección y recepción; Sedes, clasificación y rutas. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** CLIENTE; MEDIO_CONTACTO_CLIENTE; DIRECCION_HABITUAL; CONTACTO; FACULTAD_CONTACTO; MEDIO_CONTACTO_CONTACTO; PARTICIPANTE; MEDIO_CONTACTO_PARTICIPANTE; SOLICITUD; TARIFA; ENVIO; PAQUETE; CONDICION_MANEJO_PAQUETE; MEDICION; RECOLECCION; INTENTO_RECOLECCION; VEHICULO; PERIODO_FUERA_SERVICIO; ASIGNACION; PERSONAL; FUNCION_PERSONAL; SALIDA_PAQUETE; SALIDA_RUTA; RUTA; SEDE; ENTREGA; ENTREGA_PAQUETE; EVENTO_SEGUIMIENTO; INCIDENCIA; INCIDENCIA_PAQUETE; DEVOLUCION_PAQUETE; DEVOLUCION.

| Área de atención | Verificación requerida y límite |
|---|---|
| Identidad y dominios | Identificación compuesta y participante opcionalmente cliente; evitar datos contradictorios entre ambos. Conciliar contratos y medios de contacto P1/Lab03; WHATSAPP no representa toda categoría Otro. |
| Direcciones, tarifa y mediciones | Conservar direcciones utilizadas, cotización/datos de determinación y declarado/medido. La excepción reconocida de RECOLECCION requiere justificación de coherencia, no una afirmación global de BCNF. |
| Asignaciones | Verificar qué operación atiende cada asignación, sus intervalos y reemplazos, sin mezclar por referencias opcionales dos destinos incompatibles. |
| Ubicación y seguimiento | No forzar sedes/rutas ficticias para hechos externos. Verificar sede de medición y contexto de paquete/envío; eventos corregidos conservan antecedente y causa. |
| Entrega y devolución | Probar entrega final válida única por paquete e intentos múltiples; devolución corresponde al envío y sus paquetes. Las restricciones previas que limitaban retorno de varios envíos requieren revisión del modelo, sin asignar su flujo completo. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** El modelo de partida tiene 32 relaciones; Lab03 implementó nueve de directorio/solicitudes. No hay paquetes, flota, manifiestos o entrega implementados allí. P1 cuestiona obligar una recolección a todo envío, coherencia de devoluciones/asignaciones y localización de hechos: no recortar el proceso para conservar esas insuficiencias.

**Reutilización efectiva:** Reutilizar identidad compuesta, validación de participante, alta atómica de contacto y funciones tabulares de solicitudes/reportes cuando sean compatibles. Mantener mapeo de dominios explícito y comprobar de nuevo las dependencias al ampliar.

**Distinción entre defecto, observación y supuesto:** La prioridad del laboratorio fue propuesta didáctica y no asigna prioridades oficiales de transporte. El caso no pide cadena idéntica de eventos para todos los paquetes ni proceso separado de custodia. En cotización/condiciones de contenido no inventar fórmula o lista legal universal; preparar reglas explícitas del caso y supuestos identificados.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

La prioridad del laboratorio fue propuesta didáctica y no asigna prioridades oficiales de transporte. El caso no pide cadena idéntica de eventos para todos los paquetes ni proceso separado de custodia. En cotización/condiciones de contenido no inventar fórmula o lista legal universal; preparar reglas explícitas del caso y supuestos identificados.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Envíos Conecta, secciones Clientes, contactos y direcciones, Solicitud, envío y paquetes, Sedes, clasificación y rutas, Vehículos y responsables, Seguimiento e incidencias y Tarifa del servicio; diccionario/modelo final y observaciones P1/Lab03.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
