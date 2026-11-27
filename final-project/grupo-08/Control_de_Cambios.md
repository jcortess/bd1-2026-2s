# Control de Cambios — Grupo 08: Envíos Conecta

Este documento permite reconstruir **Proyecto 1 → Lab03 → segunda entrega**, tanto para los cambios como para los componentes reutilizados.

> **Estado del documento (25/11/2026):** registra las decisiones tomadas hasta ahora. Los cambios todavía no están implementados ni probados; por eso los campos «Archivos modificados» y «Evidencia de validación» indican lo previsto y quedan pendientes hasta ejecutar la versión actual. Los hallazgos que el grupo aún no ha decidido están en la sección 4.3, no en el registro de cambios.

---

## 1. Identificación y versiones de referencia

**Grupo:** 08.

**Integrantes:**
- Gherlan Steve Cerdas Rodríguez.
- Eddy Guiltres Rivas.
- Cristhian Josué Salas Meza.

**Caso:** Empresa de envíos «Envíos Conecta».

**Versión de la segunda entrega:** Segunda entrega, versión única presentada para evaluación (Pull Request a `main`).

**Motor utilizado:** PostgreSQL 19.0 (servidor: `PostgreSQL 19.0 on x86_64-windows, compiled by msvc-19.44.35230, 64-bit`; cliente: `psql (PostgreSQL) 19.0`), en Windows.

### 1.1 Archivos de referencia

**Proyecto 1** (única versión entregada):

| Archivo | Contenido |
|---|---|
| `Proyecto1_EnviosConecta.docx` | Documento del proyecto: reglas de negocio RN-01 a RN-25, supuestos S-01 a S-19, normalización y diccionario |
| `Modelo_conceptual_EnviosConecta.drawio` | Modelo conceptual |
| `Modelo_relacional_EnviosConecta.drawio` | Modelo relacional (32 relaciones). Se consultó también su exportación `Modelo_relacional_EnviosConecta_drawio.pdf`, sin diferencias de contenido |

**Modelo inicial frente a resultado normalizado:** la normalización del Proyecto 1 no modificó el modelo relacional, por lo que el modelo relacional inicial y el resultado final normalizado son el mismo artefacto (`Modelo_relacional_EnviosConecta.drawio`).

**Lab03** (única versión entregada):

| Archivo | Contenido |
|---|---|
| `01_esquema.sql` | DDL de 9 relaciones de directorio y solicitudes |
| `02_datos.sql` | Datos ficticios de esas 9 relaciones |
| `03_consultas.sql` | Consultas C1 a C6 |
| `04_rutinas.sql` | `fn_solicitudes_cliente`, `fn_prioridad_solicitud`, `sp_registrar_contacto`, `fn_reporte_prioridades` |
| `05_pruebas.sql` | Pruebas P01 a P09, F01 a F04, SP01 y SP02 |

Orden de ejecución declarado por Lab03: `01 → 02 → 04 → 03 → 05`. La cabecera de `01_esquema.sql` no declaraba la versión de PostgreSQL (`PostgreSQL <versión>`), por lo que los resultados de Lab03 se consideran **históricos** y deben volver a ejecutarse en la versión actual.

### 1.2 Relaciones implementadas y no implementadas en Lab03

- **Implementadas en Lab03 (9):** CLIENTE, MEDIO_CONTACTO_CLIENTE, DIRECCION_HABITUAL, CONTACTO, FACULTAD_CONTACTO, MEDIO_CONTACTO_CONTACTO, SOLICITUD, PARTICIPANTE, MEDIO_CONTACTO_PARTICIPANTE.
- **No implementadas en Lab03 (23):** TARIFA, ENVIO, PAQUETE, CONDICION_MANEJO_PAQUETE, MEDICION, RECOLECCION, INTENTO_RECOLECCION, VEHICULO, PERIODO_FUERA_SERVICIO, ASIGNACION, PERSONAL, FUNCION_PERSONAL, SALIDA_PAQUETE, SALIDA_RUTA, RUTA, SEDE, ENTREGA, ENTREGA_PAQUETE, EVENTO_SEGUIMIENTO, INCIDENCIA, INCIDENCIA_PAQUETE, DEVOLUCION_PAQUETE, DEVOLUCION.

Estas 23 relaciones existen en el modelo del Proyecto 1; solo quedaron fuera del recorte de Lab03.

### 1.3 Artefactos contradictorios o provisionales

| Hallazgo | Artefactos | Consolidación elegida |
|---|---|---|
| El comentario de la sección 4 de `02_datos.sql` dice «Cliente 4: uno \| Cliente 1: uno» contactos, pero los datos cargan dos contactos para el cliente 3, dos para el cliente 4 y ninguno para el cliente 1 (persona física, que no puede tener contactos según S-02) | `02_datos.sql` (comentario frente a datos) | Valen los datos, que cumplen S-02. El comentario es solo documentación y debe corregirse |
| Cuatro supuestos del Proyecto 1 contradicen el anexo del Grupo 08 o dejan sin representar una situación asignada: S-01, S-09, S-11 y S-16 (con S-19) | `.docx` del Proyecto 1 frente al anexo de la segunda entrega | Se corrigen en los cambios CAM-001 a CAM-004 |

**Comparación del modelo y el diccionario con Lab03:**

- El diccionario de datos del Proyecto 1 solo documenta la relación PAQUETE, que no se implementó en Lab03. Las otras 31 relaciones no tienen diccionario en el Proyecto 1.
- Las 9 relaciones de Lab03 se compararon con `Modelo_relacional_EnviosConecta.drawio`: coinciden en atributos, claves primarias, claves foráneas, claves alternativas y nulabilidad. No se identificaron contradicciones.
- Los dominios cerrados que aplica Lab03 (tipos de identificación, tipo de cliente, condición contractual, provincias, tipos de medio de contacto, facultades y niveles de servicio) no tienen fuente en el diccionario del Proyecto 1: fueron definidos en Lab03. Se registran como decisiones de Lab03 y se documentarán en el diccionario de esta entrega.
- En esta entrega se elabora el diccionario actualizado de las 32 relaciones (`modelo/`), como exige el enunciado general.

---

## 2. Registro de cambios

Los identificadores tienen la forma `CAM-NNN`. Las reglas se citan con su numeración original del Proyecto 1 (RN-xx y S-xx); no se renumeraron. Los criterios del anexo se citan con su código (por ejemplo, G08-P03-L).

### CAM-001 — Identificación del participante con tipo y número

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-001 |
| Fuente u origen | **Requisito:** anexo G08, sección C, «Identidad y dominios»: identificación compuesta y participante opcionalmente cliente, evitando datos contradictorios entre ambos. **Decisión propia** del grupo: redacción del nuevo supuesto. |
| Elemento afectado | Supuesto S-01; relación PARTICIPANTE (atributos, clave alternativa y regla de coherencia con CLIENTE). |
| Situación anterior | **P1:** S-01 define la identificación como tipo + número solo para clientes. PARTICIPANTE tiene `identificacion` (NN), `nombre` (NN) y `tipo_id`, `numero_id` (FK a CLIENTE, UK1, NULL). **Lab03:** implementó PARTICIPANTE igual, con `uq_participante_cliente (tipo_id, numero_id)` y `ck_participante_cliente_completo` (ambas NULL o ambas con valor). **Observado:** `identificacion` guarda solo un número, sin tipo de documento; dos participantes pueden repetir la misma identificación; y un participante vinculado a un cliente puede tener una identificación distinta de la del cliente. |
| Modificación realizada | **Nuevo S-01:** «La identificación de clientes y participantes se compone de un tipo (cédula física, cédula jurídica, DIMEX o pasaporte) y un número. En los clientes, esa combinación es clave candidata. Un participante también se registra con tipo y número, y esa combinación no se repite entre participantes; si el participante está vinculado a un cliente, su tipo y número coinciden con los de ese cliente.» **En PARTICIPANTE:** se agrega `tipo_identificacion` (NN, mismo dominio que `cliente.tipo_id`); se agrega una clave alternativa `(tipo_identificacion, identificacion)`; se agrega un CHECK: si `tipo_id` no es NULL, entonces `tipo_id = tipo_identificacion` y `numero_id = identificacion`. Se conservan la FK a CLIENTE, `uq_participante_cliente` y `ck_participante_cliente_completo`. |
| Justificación | Aplica a los participantes el mismo criterio que S-01 ya usaba para los clientes (un número sin tipo puede coincidir entre documentos distintos) y elimina la posibilidad de datos contradictorios que señala el anexo. No introduce una política nueva: extiende la regla existente. |
| Reglas relacionadas | S-01 (modificado), RN-01, RN-04, S-04, S-05. |
| Impacto en modelo y operaciones | PARTICIPANTE deja de ser reutilizable sin cambios. `02_datos.sql` debe agregar el tipo de identificación a los 4 participantes (los dos vinculados toman el tipo de su cliente; para los dos no clientes hay que asignar un tipo). La prueba P03 de `05_pruebas.sql` debe incluir el nuevo atributo. MEDIO_CONTACTO_PARTICIPANTE no cambia. `uq_participante_cliente` queda implicada por la nueva clave alternativa más el CHECK, pero se conserva. Como consecuencia del nuevo CHECK, cambiar la identificación de un cliente vinculado a un participante es rechazado: la cascada de la FK actualiza `tipo_id` y `numero_id`, pero no `tipo_identificacion` ni `identificacion`. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `participante`), `sql/02_datos.sql` (inserción de participantes), pruebas de integridad de `participante`. |
| Evidencia de validación | _Pendiente._ Debe mostrar: alta válida de participante no cliente; rechazo de tipo fuera del dominio; rechazo de tipo + número duplicado; rechazo de participante vinculado cuya identificación no coincide con la del cliente; y lectura posterior de los datos. |

### CAM-002 — La reprogramación de una recolección crea una nueva recolección

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-002 |
| Fuente u origen | **Decisión propia** del grupo. Antecedente: el propio S-09 del Proyecto 1 contemplaba esta alternativa en su impacto («si cada reprogramación creara una recolección nueva, habría que relacionarla con la original»). |
| Elemento afectado | Supuesto S-09; relación RECOLECCION (nueva referencia a sí misma); uso de `ENVIO.id_recoleccion`. |
| Situación anterior | **P1:** S-09 establece que la reprogramación asigna nueva fecha y franja **a la misma** recolección. RECOLECCION tiene `id_recoleccion`, `fecha`, `franja_inicio`, `franja_fin`, dirección (NULL) y `estado`. **Lab03:** RECOLECCION no implementada. **Observado:** al actualizar fecha y franja en la misma fila se pierde lo que se había planificado originalmente; los intentos guardan cuándo se intentó, pero no qué se planificó. |
| Modificación realizada | **Nuevo S-09:** «Si una recolección no se completa, se registra el intento y se crea una nueva recolección con su propia fecha, franja y asignaciones, que referencia a la recolección que reemplaza. Los envíos pendientes pasan a la nueva recolección; no se crean de nuevo.» **En RECOLECCION:** se agrega `id_recoleccion_anterior` (NULL, FK a RECOLECCION, única: una recolección se reemplaza directamente a lo sumo una vez; si la nueva falla, se encadena otra) y un CHECK que impide que una recolección se referencie a sí misma. Los envíos actualizan `id_recoleccion` hacia la nueva recolección; la historia queda en la cadena de reemplazos y en los intentos de la original. |
| Justificación | Conserva la planificación original sin sobrescribirla, en línea con el enunciado general (no eliminar historia). Cumple RN-09, porque los envíos no se crean de nuevo. Los cambios de vehículo o responsable quedan como asignaciones propias de la nueva recolección. |
| Reglas relacionadas | S-09 (modificado), RN-09, RN-23, S-08. |
| Impacto en modelo y operaciones | ASIGNACION: las asignaciones de la recolección original se conservan y la nueva tiene las suyas. INTENTO_RECOLECCION no cambia. ENVIO: la referencia apunta a la recolección vigente, por lo que la recolección anterior de un envío se obtiene recorriendo la cadena. La obligatoriedad de `ENVIO.id_recoleccion` se resolvió en CAM-005. Depende de una decisión aún abierta: la lista de estados de RECOLECCION (PEN-16). **Supuesto asociado (PEN-22, confirmado):** al reprogramar, todos los envíos pendientes de la recolección original pasan a la nueva; lo realiza la ruta de reprogramación en una sola transacción. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `recoleccion`), datos de prueba de recolecciones, pruebas de integridad de `recoleccion`. |
| Evidencia de validación | _Pendiente._ Debe mostrar: recolección con intento fallido y su reemplazo enlazado; rechazo de un segundo reemplazo directo de la misma recolección; rechazo de autorreferencia; y que la fecha y franja originales siguen consultables. |

### CAM-003 — Varios eventos de seguimiento en el mismo instante

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-003 |
| Fuente u origen | **Requisito:** anexo G08-P03-L («eventos al mismo instante y hecho registrado después de ocurrir: declarar cómo se determina orden/actual») y AC-G08-P03-01. **Decisión propia** del grupo: criterio de desempate. |
| Elemento afectado | Supuesto S-11; relación EVENTO_SEGUIMIENTO (clave alternativa UK2, nuevo atributo); consulta de ubicación y responsable actuales. |
| Situación anterior | **P1:** S-11 establece que un paquete no puede tener dos eventos con el mismo momento, y por eso EVENTO_SEGUIMIENTO tiene la clave alternativa UK2 `(numero_guia, num_paquete, momento)`. Solo existe `momento`, sin distinguir cuándo ocurrió el hecho de cuándo se registró. **Lab03:** EVENTO_SEGUIMIENTO no implementada. **Observado:** la UK2 rechaza justo la situación que el anexo pide demostrar. |
| Modificación realizada | **Nuevo S-11:** «Un paquete puede tener varios eventos en el mismo momento. La ubicación y el responsable actuales corresponden al último evento vigente del paquete, ordenado primero por el momento en que ocurrió el hecho, luego por el momento en que se registró y, si aún empatan, por el identificador del evento. Un evento que fue corregido deja de ser vigente y su lugar lo ocupa la corrección.» **En EVENTO_SEGUIMIENTO:** se elimina la UK2; se agrega `momento_registro` (NN, asignado por la base al registrar); se agrega un índice por paquete y orden para derivar el evento actual. |
| Justificación | Permite registrar hechos simultáneos sin perder ninguno, que es lo que pide el anexo. Los dos desempates nunca dejan el actual indefinido, porque `id_evento` es único. `momento_registro` permite además distinguir un hecho registrado después de ocurrir. |
| Reglas relacionadas | S-11 (modificado), RN-24, RN-25, S-10. |
| Impacto en modelo y operaciones | La ubicación y el responsable actuales siguen siendo datos derivados (no se almacenan). La consulta del evento actual debe excluir los eventos corregidos. En concurrencia (G08-P03), dos sesiones pueden registrar eventos del mismo paquete en el mismo momento y ambos se conservan. **Nota:** la UK2 aparecía cortada en la exportación PDF; S-11 confirma que su contenido era `(numero_guia, num_paquete, momento)`. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `evento_seguimiento`), consulta o vista del estado actual del paquete, pruebas de G08-P03. |
| Evidencia de validación | _Pendiente._ Debe mostrar (G08-P03-L): dos eventos del mismo paquete con igual momento aceptados; un hecho registrado después de ocurrir; consulta del evento actual con el desempate aplicado; y un evento corregido que deja de ser el actual sin borrarse. |

### CAM-004 — Una devolución por cada paquete

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-004 |
| Fuente u origen | **Requisito:** anexo G08, sección C, «Entrega y devolución»: la devolución corresponde al envío y sus paquetes, y las restricciones previas que limitaban el retorno de varios envíos requieren revisión. **Decisión propia** del grupo: la devolución se registra por paquete. |
| Elemento afectado | Supuesto S-16; relaciones DEVOLUCION y DEVOLUCION_PAQUETE (claves alternativas, referencias y cardinalidad). |
| Situación anterior | **P1:** S-16 establece que la devolución pertenece a un envío e indica cuáles de sus paquetes incluye. DEVOLUCION tiene `numero_guia` (NN), `id_entrega` (FK, UK, NULL) e `id_incidencia` (FK, UK, NULL); DEVOLUCION_PAQUETE tiene PK `(numero_guia, num_paquete)` y `id_devolucion` (FK simple). **Lab03:** ambas relaciones no implementadas. **Observado:** según S-19 una entrega puede agrupar paquetes de varios envíos, pero la UK de `id_entrega` solo permite una devolución por entrega, así que si se rechazan paquetes de dos envíos solo uno puede devolverse. Además, la FK simple de DEVOLUCION_PAQUETE no impide asociar un paquete de otro envío a la devolución. |
| Modificación realizada | **Nuevo S-16:** «Cada devolución corresponde a un único paquete y queda vinculada con su envío y con la causa que la originó. Un envío puede tener tantas devoluciones como paquetes devueltos.» **En DEVOLUCION:** se eliminan las UK de `id_entrega` e `id_incidencia`; se agrega una clave alternativa `(id_devolucion, numero_guia)` para que la referencie DEVOLUCION_PAQUETE. **En DEVOLUCION_PAQUETE:** se conserva la PK `(numero_guia, num_paquete)` (un paquete se devuelve una sola vez); se agrega UK sobre `id_devolucion` (una devolución, un paquete); la FK simple a DEVOLUCION pasa a ser compuesta `(id_devolucion, numero_guia)`, de modo que el paquete pertenece al mismo envío de la devolución. |
| Justificación | Resuelve la restricción que el anexo pide revisar y mantiene la regla de RN-19: la devolución sigue registrándose como resolución del envío (conserva `numero_guia`) y vinculada con su causa. La granularidad por paquete es coherente con RN-18, donde el resultado también se determina por paquete. **Alternativa considerada:** fusionar DEVOLUCION_PAQUETE dentro de DEVOLUCION, ya que la relación pasa a ser 1:1. Se descartó para conservar la correspondencia con las 32 relaciones del Proyecto 1. |
| Reglas relacionadas | S-16 (modificado), S-19, RN-19, RN-18, RN-15. |
| Impacto en modelo y operaciones | Una entrega o incidencia puede originar varias devoluciones, de uno o varios envíos. Que cada devolución tenga efectivamente su fila en DEVOLUCION_PAQUETE no se garantiza con FK: requiere un mecanismo adicional (PEN-07). La referencia de EVENTO_SEGUIMIENTO a la devolución queda pendiente de decisión (PEN-06). El flujo completo de devolución no es un proceso asignado; se prepara con datos y se verifica con pruebas de integridad. La referencia a la causa se modificó después en CAM-020. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tablas `devolucion` y `devolucion_paquete`), datos de prueba, pruebas de integridad. |
| Evidencia de validación | _Pendiente._ Debe mostrar: una entrega que origina devoluciones de paquetes de dos envíos distintos; rechazo de un paquete de otro envío en una devolución (cruce de contexto); rechazo de un segundo paquete en la misma devolución; rechazo de un paquete devuelto dos veces; y lectura posterior. |

### CAM-005 — La recolección deja de ser obligatoria para el envío

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-005 |
| Fuente u origen | **Requisito:** anexo G08-P01-L («no obligar recolección ejecutada para poder crear todo envío si el caso no la exige») y sección D (P1 cuestiona obligar una recolección a todo envío). |
| Elemento afectado | Relación ENVIO, atributo `id_recoleccion` (nulabilidad de la FK a RECOLECCION). |
| Situación anterior | **P1:** `ENVIO.id_recoleccion` es FK obligatoria (NN). **Lab03:** ENVIO no implementada. **Observado:** no puede crearse un envío sin una recolección previa, lo que impide demostrar G08-P01-L. |
| Modificación realizada | `ENVIO.id_recoleccion` pasa de obligatoria (NN) a opcional (NULL). La FK a RECOLECCION se conserva. |
| Justificación | RN-09 describe la recolección como algo que se planifica y puede abarcar varios envíos, pero ninguna regla exige que todo envío tenga una. Permite, por ejemplo, que el cliente entregue el paquete directamente en una sede. |
| Reglas relacionadas | RN-09, S-08. |
| Impacto en modelo y operaciones | Un envío se crea sin recolección y puede asignársele una después. Las consultas que unan ENVIO con RECOLECCION deben usar LEFT JOIN. Se relaciona con CAM-002: al reprogramar, solo se mueven los envíos que tienen recolección. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `envio`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: creación de un envío sin recolección; creación de un envío con recolección válida; rechazo de una recolección inexistente; y lectura posterior. |

### CAM-006 — Política de contenido del paquete

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-006 |
| Fuente u origen | **Requisito:** RN-11; anexo G08-P01-I (contenido prohibido presentado como aceptado, respaldo exigido ausente) y G08-P01-L (categorías de contenido explícitas, sin inventar una lista legal). **Decisión propia** del grupo: representarlo como atributo del paquete. |
| Elemento afectado | Relación PAQUETE: nuevo atributo y reglas de revisión. |
| Situación anterior | **P1:** PAQUETE tiene `descripcion` (texto libre), `documento_respaldo` (opcional) y la revisión inicial (`revision_resultado` con valores Aceptado, Retenido y Rechazado). El diccionario declara la exigencia de respaldo como «no representable completamente». **Lab03:** PAQUETE no implementada. **Observado:** no hay dato que indique si un contenido es prohibido o exige respaldo, por lo que RN-11 no puede comprobarse. |
| Modificación realizada | Se agrega `politica_contenido` (NN) con dominio cerrado: `PERMITIDO`, `PROHIBIDO`, `EXIGE_RESPALDO`. Se agregan dos CHECK: un paquete `PROHIBIDO` solo puede tener resultado de revisión Rechazado (o ninguno, si no se ha revisado); un paquete `EXIGE_RESPALDO` con resultado Aceptado debe tener `documento_respaldo`. |
| Justificación | Hace comprobable RN-11 sin inventar una lista legal: la política es una clasificación explícita del caso, no una enumeración de sustancias. La regla de respaldo, que el Proyecto 1 declaraba no representable, pasa a garantizarse con un CHECK. **Alternativa considerada:** un catálogo de categorías de contenido con su política. Se descartó para no agregar una relación nueva; a cambio, la política se registra en cada paquete y no en un catálogo de la empresa. |
| Reglas relacionadas | RN-11, RN-07. |
| Impacto en modelo y operaciones | El proceso G08-P01 debe recibir la política al registrar el paquete. La revisión inicial queda restringida por la política. Los datos de prueba incluyen paquetes de las tres políticas. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `paquete`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: paquete permitido aceptado; paquete prohibido rechazado; rechazo de un paquete prohibido marcado como aceptado; rechazo de un paquete que exige respaldo aceptado sin documento; aceptación del mismo paquete con documento; y lectura posterior. |

### CAM-007 — Ubicación de eventos fuera de una sede

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-007 |
| Fuente u origen | **Requisito:** anexo G08-P03 («no forzar sede/ruta ficticia cuando el hecho ocurrió fuera») y G08-P03-L (ubicación fuera de sede); sección C, «Ubicación y seguimiento». |
| Elemento afectado | Relación EVENTO_SEGUIMIENTO: nuevo atributo y regla de ubicación. |
| Situación anterior | **P1:** EVENTO_SEGUIMIENTO tiene `id_sede` (FK a SEDE, NULL) como único dato de ubicación. **Lab03:** EVENTO_SEGUIMIENTO no implementada. **Observado:** un evento ocurrido fuera de una sede (en ruta o en el domicilio del destinatario) queda sin ubicación, lo que contradice RN-24. |
| Modificación realizada | Se agrega `descripcion_ubicacion` (texto, NULL). `id_sede` se mantiene opcional. Se agrega un CHECK: el evento debe tener `id_sede`, `descripcion_ubicacion` o ambos; no puede faltar ninguno de los dos a la vez. |
| Justificación | Representa el hecho real sin inventar sedes ficticias. Cuando el hecho ocurre en una sede, se registra la sede y la descripción puede complementarla; cuando ocurre fuera, basta la descripción. Mantiene RN-24, porque todo evento queda ubicado. |
| Reglas relacionadas | RN-24, RN-12, S-10. |
| Impacto en modelo y operaciones | La consulta de ubicación actual muestra la sede, la descripción o ambas. El proceso G08-P03 recibe la descripción como dato opcional. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `evento_seguimiento`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: evento en sede sin descripción; evento fuera de sede solo con descripción; evento con ambas; rechazo de un evento sin sede ni descripción; y consulta de ubicación actual de un paquete cuyo último evento ocurrió fuera de sede. |

### CAM-008 — Cada asignación atiende exactamente una operación

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-008 |
| Fuente u origen | **Requisito:** anexo G08, sección C, «Asignaciones»: verificar qué operación atiende cada asignación, sin mezclar por referencias opcionales dos destinos incompatibles; sección D (P1 cuestiona la coherencia de las asignaciones). |
| Elemento afectado | Relación ASIGNACION: regla entre `id_recoleccion` e `id_salida`. |
| Situación anterior | **P1:** ASIGNACION tiene `id_recoleccion` (FK a RECOLECCION, NULL) e `id_salida` (FK a SALIDA_RUTA, NULL), sin ninguna regla entre ambas. **Lab03:** ASIGNACION no implementada. **Observado:** una asignación puede apuntar a una recolección y a una salida a la vez, o a ninguna. |
| Modificación realizada | Se conservan ambas columnas como opcionales y se agrega un CHECK: exactamente una de las dos tiene valor (`(id_recoleccion IS NULL) <> (id_salida IS NULL)`). |
| Justificación | Toda asignación queda ligada a una única operación, como exige el anexo, sin crear tablas nuevas ni perder las FK. **Alternativa considerada:** separar en dos tablas de asignación. Se descartó porque duplicaría columnas y obligaría a revisar dos tablas para detectar traslapes (RN-21). |
| Reglas relacionadas | RN-09, RN-13, RN-21, RN-23. |
| Impacto en modelo y operaciones | El proceso G08-P02 crea asignaciones solo con `id_salida`. Las asignaciones de recolecciones se preparan como datos. Queda por verificar, al diseñar la sustitución (RN-23), que una asignación sustituta atienda la misma operación que la original; no se garantiza con este CHECK. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `asignacion`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: asignación válida a una salida; asignación válida a una recolección;

### CAM-009 — Unidades de peso, dimensiones y volumen

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-009 |
| Fuente u origen | **Requisito:** enunciado general, sección 2.1 («una cantidad debe tener unidad y significado»); anexo G08-P02-L («volumen de paquete y capacidad con unidades compatibles»). **Decisión propia** del grupo: metros cúbicos para el volumen. |
| Elemento afectado | Dominios de peso, dimensiones y volumen en PAQUETE, MEDICION, VEHICULO, TARIFA y ENVIO (datos de cotización). |
| Situación anterior | **P1:** el diccionario solo existe para PAQUETE y fija kilogramos para `peso_declarado` y centímetros para las dimensiones declaradas. No hay unidad para MEDICION, `VEHICULO.capacidad_peso`, `VEHICULO.capacidad_volumen`, los rangos de TARIFA ni `ENVIO.cotiz_peso` y `cotiz_volumen`. **Lab03:** ninguna de estas relaciones se implementó. **Observado:** sin unidad de volumen no se puede comparar la carga con la capacidad. |
| Modificación realizada | Se fijan unidades para todo el modelo: **peso en kilogramos (kg)**, **dimensiones en centímetros (cm)** y **volumen en metros cúbicos (m³)**. El volumen de un paquete no se almacena: se deriva como largo × ancho × alto / 1 000 000, usando la medición aplicada o, si no la hay, los valores declarados (S-07). Las cantidades se guardan como numéricos con decimales y CHECK de valor mayor que 0. Las unidades quedan en el diccionario y en comentarios del esquema. |
| Justificación | Conserva las unidades que ya definió el Proyecto 1 y agrega la de volumen con la unidad habitual para la capacidad de un vehículo. Derivar el volumen evita guardarlo duplicado e inconsistente con las dimensiones. |
| Reglas relacionadas | RN-07, RN-08, RN-10, RN-20, S-07. |
| Impacto en modelo y operaciones | La validación de carga de G08-P02 compara la suma de pesos (kg) con `capacidad_peso` y la suma de volúmenes derivados (m³) con `capacidad_volumen`. La cotización de G08-P01 guarda `cotiz_peso` en kg y `cotiz_volumen` en m³. Los datos de prueba deben respetar estas unidades. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tablas `paquete`, `medicion`, `vehiculo`, `tarifa`, `envio`); diccionario en `modelo/`. |
| Evidencia de validación | _Pendiente._ Debe mostrar: rechazo de peso, dimensión o capacidad iguales a 0 o negativos; cálculo del volumen de un paquete conocido (por ejemplo, 30 × 20 × 10 cm = 0,006 m³); y carga exacta en una dimensión sin exceder la otra (G08-P02-L). |

### CAM-010 — Categoría «Otro» en los medios de contacto

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-010 |
| Fuente u origen | **Requisito:** anexo G08, sección C, «Identidad y dominios»: «WHATSAPP no representa toda categoría Otro»; conciliar los medios de contacto de P1 y Lab03. **Decisión propia** del grupo: agregar `OTRO` con descripción obligatoria. |
| Elemento afectado | Relaciones MEDIO_CONTACTO_CLIENTE, MEDIO_CONTACTO_CONTACTO y MEDIO_CONTACTO_PARTICIPANTE: dominio de `tipo_medio` y nuevo atributo. |
| Situación anterior | **P1:** el modelo define `tipo_medio` sin dominio explícito. **Lab03:** los tres CHECK `ck_medio_contacto_*_tipo` solo aceptan TELEFONO, CORREO y WHATSAPP. **Observado:** un medio distinto (por ejemplo, otra aplicación de mensajería o fax) no puede registrarse, o se registraría forzándolo como WHATSAPP. |
| Modificación realizada | En las tres tablas: el dominio de `tipo_medio` pasa a TELEFONO, CORREO, WHATSAPP y **OTRO**; se agrega `descripcion_medio` (texto, NULL); se agrega un CHECK: `descripcion_medio` es obligatoria cuando `tipo_medio = 'OTRO'` y nula en los demás casos. La clave primaria no cambia. |
| Justificación | Representa cualquier medio sin inventar una lista cerrada y sin confundirlo con WHATSAPP, que se conserva como categoría propia. Exigir la descripción evita un valor sin significado. Prohibirla en los demás tipos evita información redundante. |
| Reglas relacionadas | RN-01, RN-02, RN-04. |
| Impacto en modelo y operaciones | Los datos de Lab03 no cambian, porque no usan OTRO. `sp_registrar_contacto` no recibe descripción, así que no puede registrar un primer medio de tipo OTRO (el CHECK lo rechazaría); funciona igual para los demás tipos. Se decide al revisar la rutina si se amplía. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tablas `medio_contacto_cliente`, `medio_contacto_contacto`, `medio_contacto_participante`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: medio OTRO con descripción aceptado; rechazo de OTRO sin descripción; rechazo de TELEFONO con descripción; rechazo de un tipo fuera del dominio; y lectura posterior. |

### CAM-011 — Solo las organizaciones registran contactos, por cualquier ruta

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-011 |
| Fuente u origen | **Requisito:** RN-02, S-02; enunciado general, sección 4 («si una garantía depende de una operación controlada, debe quedar claro por qué una ruta habilitada no puede eludirla»). **Decisión propia** del grupo: implementarlo con triggers. |
| Elemento afectado | Relaciones CONTACTO y CLIENTE: dos triggers con sus funciones. |
| Situación anterior | **P1:** S-02 establece que solo las organizaciones registran contactos y que cada contacto tiene al menos una facultad. **Lab03:** la regla solo la valida `sp_registrar_contacto`. **Observado:** un `INSERT` directo en `contacto` con un cliente PERSONA_FISICA se acepta; también se acepta cambiar a PERSONA_FISICA un cliente que ya tiene contactos. |
| Modificación realizada | **Trigger en CONTACTO** (antes de insertar o de actualizar `tipo_id` o `numero_id`): rechaza la operación si el cliente referenciado no es PERSONA_JURIDICA. **Trigger en CLIENTE** (antes de actualizar `tipo_cliente`): rechaza el cambio a PERSONA_FISICA si el cliente tiene contactos. `sp_registrar_contacto` conserva su validación previa, que ahora es redundante pero da un mensaje más claro. |
| Justificación | La regla queda garantizada por la base en todas las rutas de escritura (procedimiento, `INSERT` o `UPDATE` directos y cambios en el cliente), y no solo por el procedimiento. **Alternativa considerada:** repetir `tipo_cliente` en CONTACTO con una FK compuesta. Se descartó por decisión del grupo. |
| Reglas relacionadas | RN-02, S-02. |
| Impacto en modelo y operaciones | La regla «al menos una facultad por contacto» sigue dependiendo de `sp_registrar_contacto`, que inserta el contacto y su primera facultad en la misma transacción. Un `INSERT` directo en CONTACTO sin facultad sigue siendo posible: se documenta como ruta no admitida para el registro de contactos. Los datos de Lab03 cumplen la regla. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (funciones y triggers sobre `contacto` y `cliente`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: contacto de una organización aceptado; rechazo de un `INSERT` directo de contacto para un cliente PERSONA_FISICA; rechazo de cambiar a PERSONA_FISICA un cliente con contactos; cambio aceptado para un cliente sin contactos; y lectura posterior. |

### CAM-012 — Mínimos de envíos, paquetes y devoluciones

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-012 |
| Fuente u origen | **Requisito:** S-06 y RN-07 (al menos un envío por solicitud y un paquete por envío); anexo G08-P01-I y sección «Transacción» de P01 (no crear cabecera incompleta como éxito); CAM-004 (un paquete por devolución). **Decisión propia** del grupo: solución mixta. |
| Elemento afectado | Relaciones ENVIO y PAQUETE (triggers diferidos); SOLICITUD y DEVOLUCION (ruta de escritura documentada). |
| Situación anterior | **P1:** S-06 fija la participación mínima en 1, pero el propio supuesto aclara que el orden de registro no se considera en el diseño lógico; ninguna FK puede exigir filas dependientes. **Lab03:** solo se implementó SOLICITUD, sin envíos. **Observado:** sin un mecanismo adicional, podría confirmarse una solicitud sin envíos, un envío sin paquetes o una devolución sin paquete. |
| Modificación realizada | **Envío → paquete (garantizado por cualquier ruta):** triggers de restricción diferidos (`DEFERRABLE INITIALLY DEFERRED`) que, al confirmar la transacción, rechazan un envío sin paquetes; se disparan al insertar un envío y al eliminar o mover un paquete a otro envío. **Solicitud → envío y devolución → paquete (ruta controlada):** las rutinas de P01 crean la solicitud con sus envíos en una sola transacción, y los datos de devolución se cargan con su paquete en la misma transacción. Se documentan como las rutas de escritura admitidas. |
| Justificación | El mínimo envío → paquete es parte del proceso evaluado (G08-P01) y se garantiza por la base, aunque se escriba directo en las tablas. Los otros dos mínimos no forman parte de un proceso con riesgo de quedar a medias en esta entrega, y garantizarlos con triggers agregaría complejidad sin beneficio para los procesos asignados. **Alternativas consideradas:** solo ruta controlada para todo (no protege el proceso P01 de escrituras directas) y triggers diferidos para todo (más código y más difícil de mantener). |
| Reglas relacionadas | S-06, RN-05, RN-07, RN-19; CAM-004. |
| Impacto en modelo y operaciones | Un envío y sus paquetes deben insertarse en la misma transacción; si se insertan con autocommit separados, el envío se rechaza. Los datos de prueba deben respetarlo. Borrar el último paquete de un envío se rechaza al confirmar, salvo que se borre también el envío. Un `INSERT` directo de solicitud sin envíos o de devolución sin paquete sigue siendo posible: se documenta como ruta no admitida. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (triggers sobre `envio` y `paquete`); `sql/03_rutinas.sql` (rutinas de P01); `sql/02_datos.sql`. |
| Evidencia de validación | _Pendiente._ Debe mostrar: envío con paquetes confirmado; rechazo al confirmar un envío sin paquetes (sin dejar cabecera); rechazo al borrar el último paquete de un envío; y que el rechazo revierte toda la transacción. |

### CAM-013 — Tarifa aplicable al pagador y vigente

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-013 |
| Fuente u origen | **Requisito:** RN-08 (los contratos empresariales pueden establecer precios con un periodo de vigencia); S-05. **Decisión propia** del grupo: validarlo en la rutina de P01. |
| Elemento afectado | Relación TARIFA (coherencia del cliente opcional); operación de creación de envíos de G08-P01. |
| Situación anterior | **P1:** TARIFA tiene `tipo_id` y `numero_id` opcionales (FK a CLIENTE) y vigencia con fin opcional; ENVIO referencia una tarifa sin ninguna regla que la relacione con el pagador ni con la fecha. **Lab03:** TARIFA y ENVIO no implementadas. **Observado:** la tarifa de contrato de un cliente podría aplicarse al envío de otro, o una tarifa vencida a un envío nuevo. |
| Modificación realizada | **En TARIFA:** CHECK para que `tipo_id` y `numero_id` sean ambos nulos (tarifa general) o ambos con valor (tarifa de contrato), igual que en PARTICIPANTE, porque una FK compuesta con una sola columna nula no se valida. **En la rutina de creación de envíos (G08-P01):** se rechaza la tarifa si es de contrato y no pertenece al pagador, o si la fecha de creación del envío está fuera de su vigencia. |
| Justificación | Cumple RN-08 en el proceso evaluado. La cotización queda congelada en el propio envío (`precio_cotizado` y `cotiz_*`), así que la validación importa en el momento de crear el envío y no después. **Alternativa considerada:** un trigger en ENVIO. Se descartó por decisión del grupo. |
| Reglas relacionadas | RN-08, S-05, RN-06. |
| Impacto en modelo y operaciones | La validación depende de la ruta controlada de P01: un `INSERT` directo en ENVIO podría usar una tarifa no aplicable. Se documenta como ruta no admitida para crear envíos. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `tarifa`); `sql/03_rutinas.sql` (rutina de creación de envíos). |
| Evidencia de validación | _Pendiente._ Debe mostrar: envío con tarifa general aceptado; envío con tarifa de contrato del propio pagador aceptado; rechazo con tarifa de contrato de otro cliente; rechazo con tarifa fuera de vigencia; rechazo de una tarifa con solo una de las dos columnas del cliente. |

### CAM-014 — Las mediciones solo se agregan

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-014 |
| Fuente u origen | **Requisito:** RN-10 («una nueva medición se agrega sin reemplazar las anteriores»); anexo G08-P01, «Concurrencia pertinente» (no sobrescribir la medición anterior con la nueva) y AC-G08-P01-04. |
| Elemento afectado | Relación MEDICION: trigger que impide modificar o eliminar filas. |
| Situación anterior | **P1:** RN-10 establece que las mediciones se conservan, pero el modelo no tiene ningún mecanismo que lo garantice. **Lab03:** MEDICION no implementada. **Observado:** un `UPDATE` o `DELETE` directo sobre una medición la reemplazaría o eliminaría sin dejar rastro. |
| Modificación realizada | Se agrega un trigger antes de `UPDATE` y `DELETE` en MEDICION que rechaza la operación. Única excepción: la eliminación en cascada de las mediciones de un paquete que se está borrando. |
| Justificación | Garantiza RN-10 por cualquier ruta de escritura y cubre la concurrencia del anexo: dos sesiones que registran mediciones del mismo paquete solo pueden agregar filas nuevas (y la clave primaria impide que ambas usen el mismo número). |
| Reglas relacionadas | RN-10, S-07. |
| Impacto en modelo y operaciones | Para corregir una medición errónea se registra una nueva y se cambia la medición aplicada del paquete (`num_medicion_aplicada`). Los datos de prueba no pueden corregirse con `UPDATE`; hay que recargar la base. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (función y trigger sobre `medicion`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: nueva medición agregada conservando las anteriores; rechazo de `UPDATE` sobre una medición; rechazo de `DELETE` de una medición; eliminación permitida al borrar el paquete completo. |

### CAM-015 — Sin traslapes de asignaciones ni de periodos fuera de servicio

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-015 |
| Fuente u origen | **Requisito:** RN-21, S-13; RN-23 (la sustitución conserva la asignación original); anexo G08-P02-I (doble asignación incompatible) y «Concurrencia pertinente» de P02 (dos sesiones compiten por el mismo vehículo o persona). **Decisión propia** del grupo: restricciones de exclusión y columna de vigencia. |
| Elemento afectado | Relaciones ASIGNACION (nuevo atributo y restricciones de exclusión) y PERIODO_FUERA_SERVICIO (restricción de exclusión); extensión `btree_gist`. |
| Situación anterior | **P1:** ASIGNACION tiene `inicio` y `fin` obligatorios; S-13 define el traslape y declara la regla «no representable completamente en el diseño lógico». PERIODO_FUERA_SERVICIO tiene `inicio` y `fin` (opcional). **Lab03:** ninguna de las dos relaciones se implementó. **Observado:** sin un mecanismo, una persona o un vehículo podría tener dos asignaciones superpuestas; y al sustituir una asignación, la original y la nueva cubrirían el mismo horario. |
| Modificación realizada | Se habilita la extensión `btree_gist`. **En ASIGNACION:** se agrega `vigente` (BOOLEAN, NN, por defecto verdadero); CHECK `fin > inicio`; dos restricciones `EXCLUDE USING gist` sobre el intervalo `[inicio, fin)`, una por `id_personal` y otra por `id_vehiculo`, que solo comparan asignaciones vigentes. Al sustituir una asignación, la original pasa a `vigente = false` y se conserva. **En PERIODO_FUERA_SERVICIO:** `EXCLUDE USING gist` sobre `[inicio, fin)` por vehículo (un `fin` nulo se interpreta como periodo abierto) y CHECK `fin > inicio` cuando hay fin. |
| Justificación | La regla que el Proyecto 1 declaraba no representable queda garantizada por la base, por cualquier ruta y también en concurrencia: si dos sesiones intentan asignar el mismo recurso en el mismo horario, una espera y luego es rechazada. El intervalo `[inicio, fin)` permite que una asignación empiece justo cuando termina otra, como dice S-13. La columna `vigente` conserva la asignación original (RN-23) sin que bloquee el recurso. **Alternativas consideradas:** triggers o validación en la rutina (no protegen la concurrencia sin bloqueos explícitos); acortar la asignación original (alteraría la historia). |
| Reglas relacionadas | RN-21, RN-23, S-13, RN-20. |
| Impacto en modelo y operaciones | La sustitución (G08-P02) se hace en una transacción: marcar la original como no vigente e insertar la nueva con `id_asignacion_sustituida`. Que una asignación no vigente esté efectivamente sustituida lo garantiza la rutina de sustitución. Que el vehículo no esté fuera de servicio durante una asignación (RN-20) se valida en la rutina de P02 (PEN-10). |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (extensión, tablas `asignacion` y `periodo_fuera_servicio`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: dos asignaciones consecutivas del mismo vehículo aceptadas (una termina cuando empieza la otra); rechazo de asignaciones superpuestas de la misma persona y del mismo vehículo; sustitución aceptada conservando la original como no vigente; rechazo de periodos fuera de servicio superpuestos; y la demostración concurrente de P02. |

### CAM-016 — La función ejercida debe ser una función de la persona

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-016 |
| Fuente u origen | **Requisito:** RN-22, S-14 (una persona solo puede asignarse en una función que desempeña). **Decisión propia** del grupo: FK compuesta. |
| Elemento afectado | Relación ASIGNACION: nueva referencia compuesta hacia FUNCION_PERSONAL. |
| Situación anterior | **P1:** ASIGNACION tiene `funcion_ejercida` como atributo independiente; S-14 indica que cada asignación registra una de las funciones de la persona, sin mecanismo que lo verifique. **Lab03:** ASIGNACION y FUNCION_PERSONAL no implementadas. **Observado:** una persona podría asignarse con una función que no desempeña. |
| Modificación realizada | Se agrega la FK compuesta `(id_personal, funcion_ejercida)` → FUNCION_PERSONAL `(id_personal, funcion)`, con `ON DELETE RESTRICT`. `funcion_ejercida` toma el mismo dominio que `funcion`. |
| Justificación | La clave primaria de FUNCION_PERSONAL ya representa «esta persona desempeña esta función», así que la regla se garantiza de forma declarativa en ambas direcciones: no se asigna una función ajena y no se elimina una función que está en uso. También funciona en concurrencia sin bloqueos explícitos. **Alternativa considerada:** un trigger, que requeriría código en ASIGNACION y en FUNCION_PERSONAL para lograr lo mismo. |
| Reglas relacionadas | RN-22, S-14. |
| Impacto en modelo y operaciones | La FK simple de ASIGNACION a PERSONAL se conserva. Las asignaciones históricas impiden quitarle a una persona una función que ejerció. Los datos de prueba deben registrar las funciones antes que las asignaciones. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `asignacion`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: asignación con una función de la persona aceptada; rechazo de una asignación con una función que la persona no tiene; rechazo de eliminar una función que está en uso en una asignación. |

### CAM-017 — Toda ruta tiene al menos un destino

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-017 |
| Fuente u origen | **Requisito:** RN-13 («una ruta se define entre una sede de salida y una zona o sede de destino»). |
| Elemento afectado | Relación RUTA: regla entre `id_sede_destino` y `zona_destino`. |
| Situación anterior | **P1:** RUTA tiene `id_sede_destino` (FK a SEDE, NULL) y `zona_destino` (NULL), sin regla entre ellas. **Lab03:** RUTA no implementada. **Observado:** una ruta podía registrarse sin ningún destino. |
| Modificación realizada | Se agrega un CHECK: `id_sede_destino` o `zona_destino` debe tener valor; pueden tenerlo ambos. |
| Justificación | Cumple RN-13 sin restringir de más: una ruta puede ir a una sede, a una zona o a una sede indicando también su zona. |
| Reglas relacionadas | RN-13. |
| Impacto en modelo y operaciones | Ninguno sobre las salidas de ruta. Los datos de prueba deben incluir al menos una ruta hacia una sede y una hacia una zona. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `ruta`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: ruta hacia una sede aceptada; ruta hacia una zona aceptada; ruta con ambas aceptada; rechazo de una ruta sin destino. |

### CAM-018 — El contexto de un evento corresponde a su paquete

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-018 |
| Fuente u origen | **Requisito:** anexo G08-P03-I («cruce de identidad compuesta de otro envío»; «no desplazar ubicación actual mediante referencia inconsistente») y AC-G08-P03-04 (no cruzar paquete/envío); enunciado general, sección 2.1 («una referencia debe conservar la identidad completa y el contexto exigido por la regla»); RN-25. **Decisión propia** del grupo: FK compuestas. |
| Elemento afectado | Relación EVENTO_SEGUIMIENTO (referencias a SALIDA_PAQUETE, DEVOLUCION_PAQUETE y a sí misma; nueva clave alternativa); relación DEVOLUCION_PAQUETE (nueva clave alternativa). |
| Situación anterior | **P1:** EVENTO_SEGUIMIENTO tiene `id_salida` (FK a SALIDA_RUTA), `id_devolucion` (FK a DEVOLUCION) e `id_evento_corregido` (FK a sí misma), todas simples. **Lab03:** ninguna de estas relaciones se implementó. **Observado:** un evento del paquete A podía referenciar una salida en la que el paquete no viaja, la devolución de otro paquete o, como corrección, un evento de otro paquete. |
| Modificación realizada | En EVENTO_SEGUIMIENTO: `(id_salida, numero_guia, num_paquete)` → SALIDA_PAQUETE (el paquete debe estar en el manifiesto de esa salida); `(id_devolucion, numero_guia, num_paquete)` → DEVOLUCION_PAQUETE (debe ser el paquete de esa devolución); `(id_evento_corregido, numero_guia, num_paquete)` → EVENTO_SEGUIMIENTO (la corrección es del mismo paquete). Se agregan las claves alternativas que sirven de destino: `(id_evento, numero_guia, num_paquete)` en EVENTO_SEGUIMIENTO y `(id_devolucion, numero_guia, num_paquete)` en DEVOLUCION_PAQUETE. Si la referencia es nula, la FK no se evalúa. |
| Justificación | Hace que la base rechace el cruce de identidad que pide demostrar el anexo, sin código adicional y por cualquier ruta. No afecta la normalización: no agrega datos (las columnas del paquete ya existen en el evento) y las nuevas claves alternativas son superclaves de claves existentes, así que no crean dependencias funcionales nuevas. **Alternativa considerada:** un trigger, que requeriría más código y cubrir también los cambios en el manifiesto. |
| Reglas relacionadas | RN-13, RN-19, RN-24, RN-25. |
| Impacto en modelo y operaciones | Un evento con salida solo se registra si el paquete ya está en el manifiesto de esa salida. Un paquete con eventos en una salida no puede quitarse de su manifiesto (RESTRICT). Los datos de prueba deben crear el manifiesto antes que los eventos de salida. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tablas `evento_seguimiento` y `devolucion_paquete`). |
| Evidencia de validación | _Pendiente._ Debe mostrar (G08-P03-I): evento con salida válida aceptado; rechazo de un evento que apunta a una salida donde el paquete no viaja; rechazo de una corrección que apunta a un evento de otro paquete; rechazo de un evento con la devolución de otro paquete; y que la ubicación actual del paquete no cambia tras los rechazos. |

### CAM-019 — Una sola entrega final válida por paquete

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-019 |
| Fuente u origen | **Requisito:** RN-16 (un paquete puede tener varios intentos de entrega, pero solo una entrega final válida); anexo G08, sección C, «Entrega y devolución» (probar entrega final válida única por paquete e intentos múltiples). |
| Elemento afectado | Relación ENTREGA_PAQUETE: índice único parcial. |
| Situación anterior | **P1:** ENTREGA_PAQUETE tiene `es_final` (NN) sin restricción; el Proyecto 1 declaró RN-16 «no garantizable únicamente con la estructura del modelo». **Lab03:** ENTREGA_PAQUETE no implementada. **Observado:** un paquete podía tener varias entregas marcadas como finales. |
| Modificación realizada | Se agrega un índice único parcial sobre `(numero_guia, num_paquete)` restringido a las filas con `es_final = true`. Las filas con `es_final = false` (intentos no finales) no se limitan. |
| Justificación | La regla que el Proyecto 1 declaraba no representable queda garantizada por la base, por cualquier ruta y también en concurrencia (dos entregas finales simultáneas del mismo paquete: una se rechaza). **Alternativas consideradas:** un trigger (más código y bloqueos explícitos) o una rutina (la entrega no es un proceso asignado, así que no habría ruta controlada que la valide). |
| Reglas relacionadas | RN-14, RN-15, RN-16. |
| Impacto en modelo y operaciones | Los datos de prueba pueden incluir varios intentos no finales por paquete y, como máximo, una entrega final. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (índice sobre `entrega_paquete`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: varios intentos no finales del mismo paquete aceptados; una entrega final aceptada; rechazo de una segunda entrega final del mismo paquete; y una entrega final de otro paquete aceptada. |

### CAM-020 — La devolución nace de una entrega rechazada del mismo paquete

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-020 |
| Fuente u origen | **Requisito:** RN-19 («un paquete rechazado por el destinatario […] inicia una devolución», vinculada con la causa que la originó); S-16 (fragmento del caso: «si el destinatario rechaza un paquete […] comienza el proceso de devolución»); anexo G08, sección C, «Entrega y devolución»; enunciado general, sección 2.1 (referencias con contexto). **Decisión propia** del grupo: eliminar la referencia a la incidencia y verificar la entrega rechazada con una FK compuesta. |
| Elemento afectado | Relaciones DEVOLUCION (se elimina `id_incidencia`; `id_entrega` se traslada), DEVOLUCION_PAQUETE (nuevos atributos y referencia compuesta) y ENTREGA_PAQUETE (nueva clave alternativa). |
| Situación anterior | **P1:** DEVOLUCION tiene `id_entrega` (FK a ENTREGA, NULL) e `id_incidencia` (FK a INCIDENCIA, NULL), ambas con UK (las UK se eliminaron en CAM-004). **Lab03:** ninguna de estas relaciones se implementó. **Observado:** ninguna regla del Proyecto 1 indica que una incidencia origine una devolución (RN-17 no la menciona); una devolución podía quedar sin causa; y como la devolución es por paquete (CAM-004), su paquete podía no haber estado en la entrega referenciada, o esa entrega podía no haber sido rechazada. |
| Modificación realizada | **En DEVOLUCION:** se elimina `id_incidencia` y se traslada `id_entrega` a DEVOLUCION_PAQUETE; quedan `id_devolucion`, `numero_guia`, `fecha` y `motivo`. **En DEVOLUCION_PAQUETE:** se agregan `id_entrega` (NN) y `resultado_entrega` (NN, CHECK = 'RECHAZADO'), y la FK compuesta `(id_entrega, numero_guia, num_paquete, resultado_entrega)` → ENTREGA_PAQUETE. **En ENTREGA_PAQUETE:** se agrega la clave alternativa `(id_entrega, numero_guia, num_paquete, resultado)` como destino de esa FK. |
| Justificación | Toda devolución queda vinculada con su causa (RN-19): el intento de entrega en el que ese mismo paquete fue rechazado. La base lo garantiza sin código y también impide cambiar después el resultado de esa entrega. La referencia a INCIDENCIA se elimina porque no tiene sustento en las reglas; la relación INCIDENCIA se conserva completa. Interpretación de RN-15: «devolución al remitente» es una próxima acción que se anota en una entrega no completada; la devolución se registra cuando un intento de entrega del paquete termina rechazado. **Alternativas consideradas:** permitir también entregas no completadas como causa (requería tres triggers sobre ENTREGA, ENTREGA_PAQUETE y DEVOLUCION_PAQUETE); verificar el rechazo con un trigger. No se normaliza peor: `resultado_entrega` es una constante que solo sirve de destino de la FK. |
| Reglas relacionadas | RN-15, RN-16, RN-17, RN-19, S-16 (modificado en CAM-004). |
| Impacto en modelo y operaciones | Modifica la estructura definida en CAM-004 (se conservan la devolución por paquete, la UK de `id_devolucion` y la FK `(id_devolucion, numero_guia)`). Una entrega puede originar devoluciones de varios paquetes y envíos. Una entrega cuyo paquete ya fue devuelto no puede cambiar el resultado de ese paquete. Resuelve PEN-17: la causa es obligatoria. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tablas `devolucion`, `devolucion_paquete`, `entrega_paquete`); `modelo/Modelo_Relacional.md`. |
| Evidencia de validación | _Pendiente._ Debe mostrar: devolución de un paquete rechazado en una entrega aceptada; rechazo de una devolución que apunta a una entrega donde el paquete no estaba; rechazo de una devolución sobre una entrega exitosa; rechazo de cambiar el resultado de una entrega ya devuelta; y lectura posterior. |

### CAM-021 — El resultado de una incidencia por paquete es explícito

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-021 |
| Fuente u origen | **Requisito:** RN-18 (el resultado se determina para cada paquete afectado); anexo G08-P03, «Transacción» (la incidencia no se reduce a un mensaje global que oculte pendientes) y G08-P03-L (incidencia resuelta para un paquete y pendiente para otro). **Decisión propia** del grupo: resultado obligatorio con valor por defecto. |
| Elemento afectado | Relación INCIDENCIA_PAQUETE: nulabilidad y dominio de `resultado`. |
| Situación anterior | **P1:** `INCIDENCIA_PAQUETE.resultado` es opcional (NULL), sin dominio definido. **Lab03:** INCIDENCIA_PAQUETE no implementada. **Observado:** un resultado nulo no indica explícitamente si el paquete está pendiente o si falta el dato. |
| Modificación realizada | `resultado` pasa a ser obligatorio (NN), con dominio PENDIENTE, RESUELTO, SIN_SOLUCION y valor por defecto PENDIENTE. |
| Justificación | Cada paquete afectado tiene siempre un resultado explícito, de modo que una consulta puede listar los pendientes sin interpretar nulos. |
| Reglas relacionadas | RN-17, RN-18. |
| Impacto en modelo y operaciones | Al registrar una incidencia, cada paquete afectado nace como PENDIENTE. Que una incidencia no se marque RESUELTA mientras tenga paquetes PENDIENTE se valida en la rutina de P03. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `incidencia_paquete`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: paquete afectado registrado como PENDIENTE por defecto; resultados distintos para dos paquetes de la misma incidencia; rechazo de un resultado nulo o fuera del dominio. |

### CAM-022 — La persona de una entrega es mensajera

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-022 |
| Fuente u origen | **Requisito:** RN-14 (la entrega registra la persona mensajera); RN-22. **Decisión propia** del grupo: FK compuesta con columna fija. |
| Elemento afectado | Relación ENTREGA: nuevo atributo y referencia compuesta hacia FUNCION_PERSONAL. |
| Situación anterior | **P1:** ENTREGA tiene `id_personal` (FK a PERSONAL) sin relación con las funciones de la persona. **Lab03:** ENTREGA no implementada. **Observado:** una entrega podía registrarse con una persona que no desempeña la función de mensajero. |
| Modificación realizada | Se agrega `funcion_mensajero` (NN, por defecto y con CHECK = 'MENSAJERO') y la FK compuesta `(id_personal, funcion_mensajero)` → FUNCION_PERSONAL `(id_personal, funcion)`. Se conserva la FK simple a PERSONAL. |
| Justificación | Garantiza RN-14 de forma declarativa y en ambas direcciones: no se registra una entrega con alguien que no es mensajero, ni se le quita la función a quien tiene entregas. Es la misma técnica de CAM-016 y CAM-020. **Alternativa considerada:** un trigger, que no cubriría el retiro posterior de la función. |
| Reglas relacionadas | RN-14, RN-22, S-14. |
| Impacto en modelo y operaciones | Los datos de prueba deben asignar la función MENSAJERO a las personas que realizan entregas antes de registrarlas. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (tabla `entrega`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: entrega con un mensajero aceptada; rechazo de una entrega con una persona sin la función MENSAJERO; rechazo de quitar la función MENSAJERO a una persona con entregas. |

### CAM-023 — Datos de la entrega según el resultado de sus paquetes

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-023 |
| Fuente u origen | **Requisito:** RN-15 (una entrega exitosa identifica a quien recibió y la constancia, con el documento mostrado cuando el paquete exige prueba de identidad; una entrega no completada conserva el motivo y la próxima acción); RN-19 (un paquete rechazado no se considera entregado). **Decisión propia** del grupo: trigger diferido. |
| Elemento afectado | Relaciones ENTREGA y ENTREGA_PAQUETE: función y dos triggers diferidos. |
| Situación anterior | **P1:** los datos del receptor, la constancia, el documento, el motivo y la próxima acción son opcionales en ENTREGA, y el resultado está en ENTREGA_PAQUETE; ningún mecanismo relaciona ambos. **Lab03:** ninguna de las dos relaciones se implementó. **Observado:** una entrega con paquetes entregados podía quedar sin receptor ni constancia, y una no completada sin motivo ni próxima acción. |
| Modificación realizada | Se agrega la función `fn_entrega_datos_resultado` y dos triggers de restricción diferidos (al insertar o modificar ENTREGA_PAQUETE y al modificar ENTREGA). Al confirmar la transacción verifican: si algún paquete está ENTREGADO, la entrega tiene receptor y constancia; si alguno ENTREGADO exige PRUEBA_IDENTIDAD, tiene documento mostrado; si alguno está NO_COMPLETADO o RECHAZADO, tiene motivo y próxima acción. |
| Justificación | RN-15 relaciona datos de dos tablas, que un CHECK no puede comparar. El trigger diferido la garantiza por cualquier ruta y permite registrar la entrega y sus paquetes en cualquier orden dentro de la transacción. **Alternativas consideradas:** verificarlo solo con una consulta de las pruebas (dejaba la regla sin protección) y trasladar el receptor a cada paquete (contradice RN-14, que agrupa paquetes del mismo receptor). |
| Reglas relacionadas | RN-14, RN-15, RN-19, RN-07 (condición PRUEBA_IDENTIDAD). |
| Impacto en modelo y operaciones | La entrega y sus paquetes deben registrarse en una sola transacción con los datos correspondientes. Agregar la condición PRUEBA_IDENTIDAD a un paquete después de su entrega no se revisa retroactivamente. |
| Archivos modificados | _Previsto:_ `sql/01_esquema.sql` (función y triggers sobre `entrega` y `entrega_paquete`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: entrega exitosa con receptor y constancia aceptada; rechazo al confirmar una entrega exitosa sin constancia; rechazo de una entrega de un paquete con PRUEBA_IDENTIDAD sin documento; rechazo de una entrega no completada sin motivo; y rechazo de quitar después la constancia de una entrega exitosa. |

### CAM-024 — Un evento de seguimiento no puede tener momento futuro

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-024 |
| Fuente u origen | **Decisión propia** del grupo, sobre RN-24 (el evento registra el momento del hecho) y el anexo G08-P03-L (hecho registrado después de ocurrir). |
| Elemento afectado | Operaciones `fn_registrar_evento` y `fn_corregir_evento` (G08-P03). |
| Situación anterior | **P1:** `momento` no tiene ninguna restricción. **Lab03:** no implementado. **Observado:** podía registrarse un hecho que aún no había ocurrido, y ese evento pasaría a ser el actual del paquete. |
| Modificación realizada | Ambas rutinas rechazan un `momento` posterior al momento de registro, con la restricción lógica `ck_evento_seguimiento_momento`. Un hecho registrado después de ocurrir sigue permitido. |
| Justificación | Un evento describe un hecho ocurrido; uno futuro desplazaría la ubicación actual con información que aún no es real. Se valida en las rutinas y no con un CHECK, porque un CHECK con `now()` no es determinista. |
| Reglas relacionadas | RN-24, RN-25; CAM-003. |
| Impacto en modelo y operaciones | La estructura no cambia. Un `INSERT` directo en EVENTO_SEGUIMIENTO no valida esta regla: la ruta admitida son las rutinas de P03. |
| Archivos modificados | `sql/03_rutinas.sql` (`fn_registrar_evento`, `fn_corregir_evento`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: evento con momento pasado aceptado; rechazo de un evento con momento futuro. |

### CAM-025 — Compatibilidad del vehículo con la carga (PEN-10)

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-025 |
| Fuente u origen | **Requisito:** RN-20 (vehículo operativo y compatible en peso, volumen y condiciones); anexo G08-P02-I y P02-L (exceder peso o volumen, vehículo en mantenimiento, carga exacta en una dimensión sin ignorar la otra) y AC-G08-P02-02. **Decisión propia** del grupo: cuándo y cómo se verifica. |
| Elemento afectado | Operaciones `fn_asignar_salida` y `sp_confirmar_salida` (G08-P02). |
| Situación anterior | **P1:** el Proyecto 1 declaró RN-20 no garantizable solo con la estructura. **Lab03:** no implementado. **Observado:** sin una operación que lo verifique, una salida podía confirmarse con un vehículo en mantenimiento, sobrecargado o sin refrigeración. |
| Modificación realizada | **Al asignar** un vehículo a una salida: debe estar OPERATIVO y sin periodo fuera de servicio que se cruce con el intervalo de la asignación. **Al confirmar** la salida: se repite esa revisión; la suma de pesos (kg) y de volúmenes (m³) de los paquetes del manifiesto no puede superar la capacidad del vehículo (se usa la medición aplicada o, si no hay, lo declarado, S-07); y si algún paquete tiene la condición REFRIGERACION, el vehículo debe ser refrigerado. |
| Justificación | Verificar la capacidad una sola vez, al confirmar, evita revisarla en cada cambio del manifiesto, que solo puede modificarse antes de confirmar (CAM-026). La revisión de disponibilidad se repite al confirmar porque el vehículo pudo entrar en mantenimiento después de asignarse. **Alternativa considerada:** revisar la capacidad al agregar cada paquete; se descartó por decisión del grupo. |
| Reglas relacionadas | RN-20, S-07; CAM-009, CAM-015. |
| Impacto en modelo y operaciones | La estructura no cambia. La demostración concurrente de P02 se hace con dos sesiones que compiten por el mismo vehículo o la misma persona (rechazo por las restricciones de exclusión de CAM-015); la salida se bloquea al confirmar para que nadie modifique su manifiesto durante la revisión. |
| Archivos modificados | `sql/03_rutinas.sql` (`fn_asignar_salida`, `sp_confirmar_salida`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: confirmación aceptada con carga exacta en peso y por debajo en volumen; rechazo por exceso de peso; rechazo por exceso de volumen; rechazo de asignar un vehículo en mantenimiento; rechazo de confirmar un paquete refrigerado en un vehículo no refrigerado. |

### CAM-026 — Reglas del manifiesto (PEN-12)

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-026 |
| Fuente u origen | **Requisito:** RN-13 y S-12 (los paquetes quedan registrados antes de partir); anexo G08-P02-L (paquetes retenidos o rechazados no se confunden con carga aceptada). **Decisión propia** del grupo: el manifiesto se cierra al confirmar y un paquete no viaja en dos salidas activas. |
| Elemento afectado | Operación `sp_agregar_paquete_salida` (G08-P02). |
| Situación anterior | **P1:** S-12 marcaba la partida con un evento de salida y la declaraba no representable en el diseño lógico. **Lab03:** no implementado. **Observado:** sin una operación que lo controle, podían agregarse paquetes después de confirmada o iniciada la salida, paquetes no aceptados, o un mismo paquete en dos salidas a la vez. |
| Modificación realizada | Un paquete solo se agrega si la salida está PLANIFICADA, si su revisión es ACEPTADO y si no está en otra salida PLANIFICADA, CONFIRMADA o EN_RUTA. Al confirmar, el manifiesto queda cerrado. La partida se registra con el paso de la salida a EN_RUTA (`sp_iniciar_salida`). |
| Justificación | Cerrar el manifiesto al confirmar garantiza que la capacidad revisada en CAM-025 no cambie después y que el manifiesto exista antes de partir (RN-13). Un paquete no puede estar en dos vehículos a la vez; cuando una salida termina, el paquete puede ir en otra, y la anterior se conserva en el manifiesto histórico. |
| Reglas relacionadas | RN-13, S-12, RN-11; CAM-025. |
| Impacto en modelo y operaciones | Interpreta S-12: la partida se marca con el estado de la salida y no con un evento. Un `INSERT` directo en SALIDA_PAQUETE no valida estas reglas: la ruta admitida es la rutina. |
| Archivos modificados | `sql/03_rutinas.sql` (`sp_agregar_paquete_salida`, `sp_iniciar_salida`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: paquete aceptado agregado; rechazo de un paquete retenido o rechazado; rechazo de agregar a una salida confirmada; rechazo de un paquete que está en otra salida activa. |

### CAM-027 — Requisitos para confirmar una salida y sustituir asignaciones

| Campo | Información verificable |
|---|---|
| Identificador del cambio | CAM-027 |
| Fuente u origen | **Requisito:** RN-13 (salida con un vehículo y una persona responsable); RN-23 (cambio antes de ejecutar conserva el original y el motivo); anexo G08-P02 («sustitución fallida conserva plan previo válido») y AC-G08-P02-03 y 04. **Decisión propia** del grupo: condiciones de confirmación y momento de la sustitución. |
| Elemento afectado | Operaciones `sp_confirmar_salida` y `fn_sustituir_asignacion` (G08-P02). |
| Situación anterior | **P1:** RN-13 y RN-23 no fijan qué se exige para confirmar una salida ni hasta cuándo se sustituye. **Lab03:** no implementado. **Observado:** una salida podía confirmarse sin paquetes, sin conductor o con vehículos distintos entre sus asignaciones. |
| Modificación realizada | **Para confirmar:** al menos un paquete en el manifiesto, al menos una asignación vigente con función CONDUCTOR, y un único vehículo entre todas las asignaciones vigentes. **Sustitución:** solo mientras la salida está PLANIFICADA; marca la asignación original como no vigente y crea la nueva con motivo, en una transacción. |
| Justificación | Un único vehículo por salida permite comparar la carga sin ambigüedad (CAM-025). Restringir la sustitución a salidas PLANIFICADAS evita cambiar el vehículo después de revisar la capacidad; si hace falta un cambio, la salida se planifica de nuevo. **Alternativa considerada:** permitir la sustitución en salidas confirmadas, revisando de nuevo la carga; se descartó por decisión del grupo. |
| Reglas relacionadas | RN-13, RN-21, RN-23; CAM-008, CAM-015, CAM-016. |
| Impacto en modelo y operaciones | La estructura no cambia. Si la sustitución falla (por ejemplo, por traslape del nuevo recurso), la transacción se deshace y la asignación original sigue vigente. |
| Archivos modificados | `sql/03_rutinas.sql` (`sp_confirmar_salida`, `fn_sustituir_asignacion`). |
| Evidencia de validación | _Pendiente._ Debe mostrar: confirmación aceptada con conductor y un solo vehículo; rechazo sin paquetes; rechazo sin conductor; rechazo con dos vehículos vigentes; sustitución aceptada conservando la original y su motivo; rechazo de sustituir en una salida confirmada; sustitución fallida que conserva la original vigente. |

---

## 3. Reutilización sin modificación

### 3.1 Componentes que se conservan (decisión del grupo)

| Campo | Información verificable |
|---|---|
| Componente | `fn_prioridad_solicitud(p_id_solicitud)` |
| Archivo / versión de origen | Lab03, `04_rutinas.sql` (F2) |
| Propósito | Clasificar una solicitud como CRITICA, ALTA, NORMAL o BAJA según su nivel de servicio y la condición contractual del cliente |
| Reglas que cubre | Ninguna regla del negocio. Su clasificación es una **propuesta didáctica** del laboratorio: el propio código la marca como propuesta, y el anexo (secciones D y F) aclara que no asigna prioridades oficiales de transporte. No se usa en los procesos G08-P01, G08-P02 ni G08-P03 |
| Razón para conservarlo | Funciona sobre relaciones que se mantienen y sirve como consulta complementaria del directorio de solicitudes |
| Dependencias compatibles | CLIENTE (`condicion_contractual`) y SOLICITUD (`nivel_servicio`), sin cambios decididos a la fecha |
| Pruebas actuales que confirman que sigue funcionando | Ejecutada el 25/11/2026 en PostgreSQL 19.0, sobre una base nueva cargada con los scripts de Lab03 (01, 02, 04, 03). `SELECT fn_prioridad_solicitud(6);` Esperado: `CRITICA` (solicitud MISMO_DIA). Observado: `CRITICA`. Coincide con el resultado histórico de Lab03 |

| Campo | Información verificable |
|---|---|
| Componente | `fn_reporte_prioridades()` |
| Archivo / versión de origen | Lab03, `04_rutinas.sql` (C3, cursor explícito) |
| Propósito | Recorrer las solicitudes y devolver la prioridad de cada una |
| Reglas que cubre | Ninguna regla del negocio (depende de `fn_prioridad_solicitud`, que es una propuesta didáctica). El propio código documenta que un `SELECT` equivalente da el mismo resultado; el cursor se conserva con fines didácticos |
| Razón para conservarlo | Funciona y documenta su alternativa basada en conjuntos |
| Dependencias compatibles | `fn_prioridad_solicitud`, SOLICITUD y CLIENTE |
| Pruebas actuales que confirman que sigue funcionando | Ejecutada el 25/11/2026 en PostgreSQL 19.0, sobre la misma base. `SELECT * FROM fn_reporte_prioridades();` Esperado: 7 filas (1 NORMAL, 2 ALTA, 3 BAJA, 4 BAJA, 5 CRITICA, 6 CRITICA, 7 NORMAL). Observado: las mismas 7 filas y prioridades. Coincide con el resultado histórico de Lab03 |

| Campo | Información verificable |
|---|---|
| Componente | `fn_solicitudes_cliente(p_tipo_id, p_numero_id, p_desde, p_hasta)` |
| Archivo / versión de origen | Lab03, `04_rutinas.sql` (F1); ahora en `sql/03_rutinas.sql`, parte 1 |
| Propósito | Consultar las solicitudes de un cliente, con rango de fechas opcional, rechazando un cliente inexistente |
| Reglas que cubre | RN-05 (solicitudes de un único contratante). Es la «función tabular de solicitudes» que el anexo pide reutilizar (sección D) |
| Razón para conservarlo | SOLICITUD y CLIENTE no cambiaron de estructura; la función sigue siendo correcta |
| Dependencias compatibles | CLIENTE y SOLICITUD |
| Pruebas actuales que confirman que sigue funcionando | Ejecutada el 26/11/2026 en PostgreSQL 19.0 sobre una base nueva con `01_esquema.sql`, `02_datos.sql` y `03_rutinas.sql`. `SELECT * FROM fn_solicitudes_cliente('CEDULA_JURIDICA','3-101-111111');` Esperado: solicitudes 4, 5 y 6. Observado: las mismas tres filas. Coincide con el resultado histórico de Lab03 |

| Campo | Información verificable |
|---|---|
| Componente | `sp_registrar_contacto(...)` |
| Archivo / versión de origen | Lab03, `04_rutinas.sql` (P1); ahora en `sql/03_rutinas.sql`, parte 1 |
| Propósito | Registrar un contacto de una organización con su primera facultad y su primer medio, en una sola operación |
| Reglas que cubre | RN-02, S-02. Es la ruta de escritura admitida para contactos: garantiza al menos una facultad (CAM-011, CAM-012). Es el «alta atómica de contacto» que el anexo pide reutilizar (sección D) |
| Razón para conservarlo | Sigue siendo compatible; su validación de organización ahora también la garantizan los triggers de CAM-011 |
| Dependencias compatibles | CLIENTE, CONTACTO, FACULTAD_CONTACTO y MEDIO_CONTACTO_CONTACTO. Limitación: no recibe descripción, por lo que no registra medios de tipo OTRO (CAM-010) |
| Pruebas actuales que confirman que sigue funcionando | _Pendiente:_ se prueba en `pruebas/05_pruebas.sql` (alta exitosa y rechazo para una persona física) |

### 3.2 Candidatos a reutilización (pendiente de confirmar por el grupo)

No se registran como reutilizados hasta que el grupo los confirme y se vuelvan a ejecutar en la versión actual.

| Componente | Origen | Observación |
|---|---|---|
| Tablas `cliente`, `direccion_habitual`, `contacto`, `facultad_contacto`, `solicitud` | `01_esquema.sql` | Sin cambios decididos. Las tablas `medio_contacto_*` dependen de PEN-02 (categoría «Otro») |
| Índices `idx_solicitud_cliente`, `idx_contacto_cliente` y convención `pk_ / fk_ / uq_ / ck_` | `01_esquema.sql` | Sin cambios decididos |
| `fn_solicitudes_cliente` | `04_rutinas.sql` (F1) | Corresponde a la «función tabular de solicitudes» que el anexo pide reutilizar |
| `sp_registrar_contacto` | `04_rutinas.sql` (P1) | Corresponde al «alta atómica de contacto» del anexo. Depende de PEN-03 (la regla RN-02 puede eludirse con un `INSERT` directo) y de PEN-02 |
| Datos de clientes, contactos, direcciones y solicitudes | `02_datos.sql` | La inserción de participantes cambia por CAM-001 |
| Consultas C1 a C6 | `03_consultas.sql` | Sus resultados esperados dependen de que los identificadores empiecen en 1 (base limpia) |
| Patrón de prueba con captura de excepción y verificación del nombre de la restricción | `05_pruebas.sql` | Permite distinguir el rechazo correcto de un error accidental. P03 cambia por CAM-001 |

---

## 4. Cobertura y pendientes

### 4.1 Correspondencia de relaciones (Proyecto 1 → entrega actual)

Estados posibles: **conservada**, **corregida**, **ampliada**, **implementada por primera vez** o **renominada**. Ninguna relación desaparece.

| # | Relación de partida | Lab03 | Estado actual | Cambios | Matriz de integridad |
|---|---|---|---|---|---|
| 1 | CLIENTE | Implementada | Sin cambios decididos | — | _Pendiente_ |
| 2 | MEDIO_CONTACTO_CLIENTE | Implementada | **Corregida** | CAM-010 | _Pendiente_ |
| 3 | DIRECCION_HABITUAL | Implementada | Sin cambios decididos | — | _Pendiente_ |
| 4 | CONTACTO | Implementada | Sin cambios decididos (ver PEN-03) | — | _Pendiente_ |
| 5 | FACULTAD_CONTACTO | Implementada | Sin cambios decididos | — | _Pendiente_ |
| 6 | MEDIO_CONTACTO_CONTACTO | Implementada | **Corregida** | CAM-010 | _Pendiente_ |
| 7 | PARTICIPANTE | Implementada | **Corregida** | CAM-001 | _Pendiente_ |
| 8 | MEDIO_CONTACTO_PARTICIPANTE | Implementada | **Corregida** | CAM-010 | _Pendiente_ |
| 9 | SOLICITUD | Implementada | Sin cambios en estructura; ruta de escritura documentada | CAM-012 | _Pendiente_ |
| 10 | TARIFA | No implementada | Por implementar por primera vez, **corregida** | CAM-009, CAM-013 | _Pendiente_ |
| 11 | ENVIO | No implementada | Por implementar por primera vez, **corregida** | CAM-002, CAM-005, CAM-009, CAM-012, CAM-013 | _Pendiente_ |
| 12 | PAQUETE | No implementada | Por implementar por primera vez, **ampliada** | CAM-006, CAM-009, CAM-012 | _Pendiente_ |
| 13 | CONDICION_MANEJO_PAQUETE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 14 | MEDICION | No implementada | Por implementar por primera vez, **ampliada** | CAM-009, CAM-014 | _Pendiente_ |
| 15 | RECOLECCION | No implementada | Por implementar por primera vez, **ampliada** | CAM-002 | _Pendiente_ |
| 16 | INTENTO_RECOLECCION | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 17 | VEHICULO | No implementada | Por implementar por primera vez | CAM-009 | _Pendiente_ |
| 18 | PERIODO_FUERA_SERVICIO | No implementada | Por implementar por primera vez, **corregida** | CAM-015 | _Pendiente_ |
| 19 | ASIGNACION | No implementada | Por implementar por primera vez, **corregida** | CAM-008, CAM-015, CAM-016, CAM-027 | _Pendiente_ |
| 20 | PERSONAL | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 21 | FUNCION_PERSONAL | No implementada | Por implementar por primera vez | CAM-016, CAM-022 | _Pendiente_ |
| 22 | SALIDA_PAQUETE | No implementada | Por implementar por primera vez | CAM-018, CAM-026 | _Pendiente_ |
| 23 | SALIDA_RUTA | No implementada | Por implementar por primera vez | CAM-025, CAM-026, CAM-027 | _Pendiente_ |
| 24 | RUTA | No implementada | Por implementar por primera vez, **corregida** | CAM-017 | _Pendiente_ |
| 25 | SEDE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 26 | ENTREGA | No implementada | Por implementar por primera vez, **corregida** | CAM-022, CAM-023 | _Pendiente_ |
| 27 | ENTREGA_PAQUETE | No implementada | Por implementar por primera vez, **corregida** | CAM-019, CAM-020, CAM-023 | _Pendiente_ |
| 28 | EVENTO_SEGUIMIENTO | No implementada | Por implementar por primera vez, **corregida** | CAM-003, CAM-007, CAM-018 | _Pendiente_ |
| 29 | INCIDENCIA | No implementada | Por implementar por primera vez; sin cambios en estructura, deja de ser referenciada por DEVOLUCION | CAM-020 | _Pendiente_ |
| 30 | INCIDENCIA_PAQUETE | No implementada | Por implementar por primera vez, **corregida** | CAM-021 | _Pendiente_ |
| 31 | DEVOLUCION_PAQUETE | No implementada | Por implementar por primera vez, **corregida** | CAM-004, CAM-012, CAM-018, CAM-020 | _Pendiente_ |
| 32 | DEVOLUCION | No implementada | Por implementar por primera vez, **corregida** | CAM-004, CAM-012, CAM-020 | _Pendiente_ |

### 4.2 Reglas declaradas «no representables completamente en el lógico»

El Proyecto 1 declaró estas reglas como no garantizables solo con la estructura. En esta entrega deben indicar cómo se verifican y con qué prueba.

| Regla | Fuente | Cómo se verifica | Prueba |
|---|---|---|---|
| RN-16: una sola entrega final válida por paquete | P1, nota final de las reglas | Índice único parcial sobre `(numero_guia, num_paquete)` donde `es_final` es verdadero (CAM-019) | _Pendiente_ |
| RN-20: vehículo operativo y compatible con la carga | P1, nota final de las reglas | Rutinas de P02: disponibilidad al asignar y al confirmar; capacidad de peso y volumen y refrigeración al confirmar (CAM-025) | _Pendiente_ |
| RN-21 / S-13: sin traslapes incompatibles de personas o vehículos | P1, nota final de las reglas y S-13 | `EXCLUDE USING gist` sobre `[inicio, fin)` por persona y por vehículo, solo entre asignaciones vigentes (CAM-015) | _Pendiente_ |
| S-12: no se agregan paquetes a una salida después de su partida | P1, S-12 | Rutina de P02: los paquetes solo se agregan a salidas PLANIFICADAS; la partida es el paso a EN_RUTA (CAM-026) | _Pendiente_ |

### 4.3 Supuestos, ambigüedades y hallazgos pendientes de decisión

Hallazgos identificados al revisar el Proyecto 1, Lab03 y el anexo. **Ninguno está decidido ni implementado**; cuando el grupo decida, cada uno pasa a la sección 2 como cambio o se descarta con su razón.

| ID | Fuente | Fragmento o situación | Pregunta | Impacto |
|---|---|---|---|---|
| PEN-01 **(Resuelto en CAM-005)**| Anexo G08-P01-L y sección D; RN-09 | En P1, `ENVIO.id_recoleccion` es NN | ¿Se permite crear un envío sin recolección? El anexo pide no obligarla | Si se mantiene NN, no puede demostrarse G08-P01-L |
| PEN-02 **(Resuelto en CAM-010)** | Anexo G08, sección C, «Identidad y dominios» | Los medios de contacto de Lab03 solo admiten TELEFONO, CORREO y WHATSAPP | ¿Cómo se representa la categoría «Otro»? | Afecta las tres tablas `medio_contacto_*`, sus datos y `sp_registrar_contacto` |
| PEN-03 **(Resuelto en CAM-011)** | RN-02, S-02; enunciado general, sección 4 (rutas de escritura) | La regla «solo organizaciones con contactos, con al menos una facultad» solo la valida `sp_registrar_contacto` | ¿Cómo se impide que un `INSERT` directo en `contacto` la eluda? | Hay que documentar la ruta de escritura permitida o agregar un mecanismo |
| PEN-04 **(Resuelto en CAM-006)** | RN-11; anexo G08-P01-I y P01-L | No hay dónde registrar qué contenido es prohibido o exige respaldo | ¿Cómo se representan las categorías de contenido sin inventar una lista legal? | Sin esto no puede demostrarse el rechazo de material prohibido ni la exigencia de respaldo |
| PEN-05 **(Resuelto en CAM-007)** | Anexo G08-P03 y sección C, «Ubicación y seguimiento»; RN-24 | EVENTO_SEGUIMIENTO solo tiene `id_sede` (NULL) como ubicación | ¿Cómo se registra un hecho ocurrido fuera de una sede sin forzar una sede ficticia? | Afecta G08-P03-L |
| PEN-06 **(Resuelto en CAM-018)** | Anexo G08-P03-I y AC-G08-P03-04 | Las referencias del evento a salida y devolución son simples | ¿Cómo se garantiza que el paquete del evento viaja en esa salida o pertenece a esa devolución? | Sin esto puede cruzarse paquete y envío |
| PEN-07 **(Resuelto en CAM-012)** | S-06, RN-07; CAM-004 | Mínimos: al menos un envío por solicitud, un paquete por envío y un paquete por devolución | ¿Con qué mecanismo se garantizan los mínimos? | No se pueden expresar con FK |
| PEN-08 **(Resuelto en CAM-019)** | RN-16; anexo sección C | `ENTREGA_PAQUETE.es_final` no tiene restricción | ¿Cómo se garantiza una sola entrega final por paquete? | Ver 4.2 |
| PEN-09 **(Resuelto en CAM-008)** | Anexo G08, sección C, «Asignaciones» | ASIGNACION tiene `id_recoleccion` e `id_salida` opcionales | ¿Cómo se evita que una asignación apunte a ambas o a ninguna? | Afecta G08-P02 |
| PEN-10 **(Resuelto en CAM-025)** | RN-20; anexo G08-P02-I y P02-L | Capacidad de peso y volumen, condición operativa y periodos fuera de servicio | ¿Cómo y cuándo se compara la carga con la capacidad? | Afecta G08-P02 y su concurrencia |
| PEN-11 **(Resuelto en CAM-015)** | RN-21, S-13 | Traslape de asignaciones; se permite empezar cuando termina la anterior | ¿Qué mecanismo se usa? | Ver 4.2 |
| PEN-12 **(Resuelto en CAM-026)** | S-12, RN-13 | La partida se marca con un evento de salida | ¿Cómo se impide agregar paquetes después de la partida? | Ver 4.2 |
| PEN-13 **(Resuelto en CAM-016)** | RN-22, S-14 | `ASIGNACION.funcion_ejercida` es independiente de FUNCION_PERSONAL | ¿Se exige que la función pertenezca a la persona? | Afecta G08-P02 |
| PEN-14 **(Resuelto en CAM-009)** | Enunciado general, sección 2.1; anexo G08-P02-L | El diccionario del Proyecto 1 fija kilogramos para el peso y centímetros para las dimensiones declaradas del paquete, pero no hay unidad para volumen (capacidad del vehículo, rangos de tarifa) ni para las mediciones | ¿Qué unidad de volumen se usa y cómo se compara con las dimensiones en centímetros? | Afecta diccionario, P01 y P02 |
| PEN-15 **(Descartado: resuelto con diccionario del Proyecto 1)** | S-07, RN-10 | `PAQUETE.num_medicion_aplicada` | ¿Cómo se asegura que la medición aplicada sea del mismo paquete? | La FK compuesta (numero_guia, num_paquete, num_medicion_aplicada) → MEDICION ya lo garantiza |
| PEN-16 **(Resuelto: valores definidos documentados en `modelo/Modelo_Relacional.md`, secciones 3 y 5, y aplicados con CHECK en `sql/01_esquema.sql`)** | S-15 | Situación, estado y resultado son listas cerradas | ¿Cuáles son los valores concretos de cada lista? | Afecta diccionario y dominios de varias relaciones |
| PEN-17 **(Resuelto en CAM-020)** | RN-19; CAM-004 | La devolución debe vincularse con su causa, pero `id_entrega` e `id_incidencia` son ambos NULL | ¿Se exige al menos una causa? | Afecta DEVOLUCION |
| PEN-18 **(Resuelto en CAM-017)** | RN-13 | RUTA tiene sede destino y zona destino opcionales | ¿Se exige al menos uno? | Afecta RUTA |
| PEN-19 **(Resuelto en CAM-013)** | RN-08, S-05 | TARIFA puede pertenecer a un cliente | ¿La tarifa de un cliente solo puede aplicarse a envíos de ese pagador y dentro de su vigencia? | Afecta G08-P01 |
| PEN-20 **(Resuelto: supuesto documentado, sin cambio en la estructura)** | RN-05 | `SOLICITUD.destino` es un único texto, pero una solicitud origina varios envíos a destinos distintos | ¿Qué representa ese atributo? | Se conserva como destino general de la solicitud (ver supuesto en `modelo/Modelo_Relacional.md`) |
| PEN-21 **(Resuelto: justificación documentada en `modelo/Modelo_Relacional.md`, sin cambio en la estructura)** | Anexo G08, sección C, «Direcciones, tarifa y mediciones» | La excepción reconocida de RECOLECCION frente a BCNF | ¿Cómo se justifica su coherencia? | Requiere justificación documentada |
| PEN-22 **(Resuelto en CAM-002: supuesto confirmado)** | CAM-002 | Al reprogramar una recolección | ¿Todos los envíos pendientes pasan a la nueva recolección? | Sí: la ruta de reprogramación los mueve todos en una sola transacción |
| PEN-23 **(Resuelto en CAM-022)** | RN-14 | La entrega registra a la persona mensajera, pero `entrega.id_personal` acepta a cualquier persona | ¿Se exige que tenga la función MENSAJERO? | Afecta ENTREGA |
| PEN-24 **(Resuelto en CAM-023)** | RN-15 | Una entrega exitosa identifica a quien recibió y la constancia, pero el resultado está por paquete (ENTREGA_PAQUETE) y el receptor por entrega (ENTREGA) | ¿Cómo se garantiza que una entrega con paquetes ENTREGADO tenga receptor y constancia? | Afecta ENTREGA y ENTREGA_PAQUETE |

### 4.4 Recomendaciones opcionales no adoptadas

| Recomendación | Origen | Razón para no adoptarla |
|---|---|---|
| Historial de revisiones del paquete en una relación nueva | Propuesta surgida en el análisis con IA | RN-11 establece un único resultado para la revisión inicial; no hay fuente que exija conservar varias revisiones |

---

## 5. Comprobación al entregar

Una persona revisora debe poder:

- Partir de un cambio (`CAM-NNN`) y encontrar su origen, los archivos actuales y la prueba que lo valida.
- Partir de una relación o regla y reconocer si se conservó, se implementó por primera vez o se corrigió.

Lista de verificación antes del Pull Request:

- [ ] Cada `CAM-NNN` tiene sus archivos modificados reales y su evidencia de validación ejecutada en la versión actual.
- [ ] Cada `PEN-NN` de la sección 4.3 se resolvió como cambio (sección 2), se descartó con su razón o quedó documentado como supuesto pendiente.
- [ ] Las 32 relaciones de la sección 4.1 tienen estado final y referencia a la matriz de integridad.
- [ ] Las reglas de la sección 4.2 indican cómo se verifican y con qué prueba.
- [ ] Los componentes de la sección 3 tienen pruebas re-ejecutadas en PostgreSQL 19.0, distinguiendo el resultado histórico de Lab03.
- [ ] La versión exacta de PostgreSQL y del cliente está anotada en la sección 1.
- [ ] No se presenta como resuelto ningún defecto que siga siendo reproducible.