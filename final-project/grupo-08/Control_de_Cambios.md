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
| Impacto en modelo y operaciones | PARTICIPANTE deja de ser reutilizable sin cambios. `02_datos.sql` debe agregar el tipo de identificación a los 4 participantes (los dos vinculados toman el tipo de su cliente; para los dos no clientes hay que asignar un tipo). La prueba P03 de `05_pruebas.sql` debe incluir el nuevo atributo. MEDIO_CONTACTO_PARTICIPANTE no cambia. `uq_participante_cliente` queda implicada por la nueva clave alternativa más el CHECK, pero se conserva. |
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
| Impacto en modelo y operaciones | ASIGNACION: las asignaciones de la recolección original se conservan y la nueva tiene las suyas. INTENTO_RECOLECCION no cambia. ENVIO: la referencia apunta a la recolección vigente, por lo que la recolección anterior de un envío se obtiene recorriendo la cadena. La obligatoriedad de `ENVIO.id_recoleccion` se resolvió en CAM-005. Depende de una decisión aún abierta: la lista de estados de RECOLECCION (PEN-16).. **Supuesto asociado, pendiente de confirmar (PEN-23):** al reprogramar, todos los envíos pendientes de la recolección original pasan a la nueva. |
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
| Impacto en modelo y operaciones | Una entrega o incidencia puede originar varias devoluciones, de uno o varios envíos. Que cada devolución tenga efectivamente su fila en DEVOLUCION_PAQUETE no se garantiza con FK: requiere un mecanismo adicional (PEN-07). La referencia de EVENTO_SEGUIMIENTO a la devolución queda pendiente de decisión (PEN-06). El flujo completo de devolución no es un proceso asignado; se prepara con datos y se verifica con pruebas de integridad. |
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
| 2 | MEDIO_CONTACTO_CLIENTE | Implementada | Sin cambios decididos (ver PEN-02) | — | _Pendiente_ |
| 3 | DIRECCION_HABITUAL | Implementada | Sin cambios decididos | — | _Pendiente_ |
| 4 | CONTACTO | Implementada | Sin cambios decididos (ver PEN-03) | — | _Pendiente_ |
| 5 | FACULTAD_CONTACTO | Implementada | Sin cambios decididos | — | _Pendiente_ |
| 6 | MEDIO_CONTACTO_CONTACTO | Implementada | Sin cambios decididos (ver PEN-02) | — | _Pendiente_ |
| 7 | PARTICIPANTE | Implementada | **Corregida** | CAM-001 | _Pendiente_ |
| 8 | MEDIO_CONTACTO_PARTICIPANTE | Implementada | Sin cambios decididos (ver PEN-02) | — | _Pendiente_ |
| 9 | SOLICITUD | Implementada | Sin cambios decididos | — | _Pendiente_ |
| 10 | TARIFA | No implementada | Por implementar por primera vez | CAM-009 | _Pendiente_ |
| 11 | ENVIO | No implementada | Por implementar por primera vez, **corregida** | CAM-002, CAM-005, CAM-009 | _Pendiente_ |
| 12 | PAQUETE | No implementada | Por implementar por primera vez, **ampliada** | CAM-006, CAM-009 | _Pendiente_ |
| 13 | CONDICION_MANEJO_PAQUETE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 14 | MEDICION | No implementada | Por implementar por primera vez | CAM-009 | _Pendiente_ |
| 15 | RECOLECCION | No implementada | Por implementar por primera vez, **ampliada** | CAM-002 | _Pendiente_ |
| 16 | INTENTO_RECOLECCION | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 17 | VEHICULO | No implementada | Por implementar por primera vez | CAM-009 | _Pendiente_ |
| 18 | PERIODO_FUERA_SERVICIO | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 19 | ASIGNACION | No implementada | Por implementar por primera vez, **corregida** | CAM-008 | _Pendiente_ |
| 20 | PERSONAL | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 21 | FUNCION_PERSONAL | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 22 | SALIDA_PAQUETE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 23 | SALIDA_RUTA | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 24 | RUTA | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 25 | SEDE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 26 | ENTREGA | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 27 | ENTREGA_PAQUETE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 28 | EVENTO_SEGUIMIENTO | No implementada | Por implementar por primera vez, **corregida** | CAM-003, CAM-007 | _Pendiente_ |
| 29 | INCIDENCIA | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 30 | INCIDENCIA_PAQUETE | No implementada | Por implementar por primera vez | — | _Pendiente_ |
| 31 | DEVOLUCION_PAQUETE | No implementada | Por implementar por primera vez, **corregida** | CAM-004 | _Pendiente_ |
| 32 | DEVOLUCION | No implementada | Por implementar por primera vez, **corregida** | CAM-004 | _Pendiente_ |

### 4.2 Reglas declaradas «no representables completamente en el lógico»

El Proyecto 1 declaró estas reglas como no garantizables solo con la estructura. En esta entrega deben indicar cómo se verifican y con qué prueba.

| Regla | Fuente | Cómo se verifica | Prueba |
|---|---|---|---|
| RN-16: una sola entrega final válida por paquete | P1, nota final de las reglas | _Pendiente de diseño_ (PEN-08) | _Pendiente_ |
| RN-20: vehículo operativo y compatible con la carga | P1, nota final de las reglas | _Pendiente de diseño_ (PEN-10) | _Pendiente_ |
| RN-21 / S-13: sin traslapes incompatibles de personas o vehículos | P1, nota final de las reglas y S-13 | _Pendiente de diseño_ (PEN-11) | _Pendiente_ |
| S-12: no se agregan paquetes a una salida después de su partida | P1, S-12 | _Pendiente de diseño_ (PEN-12) | _Pendiente_ |

### 4.3 Supuestos, ambigüedades y hallazgos pendientes de decisión

Hallazgos identificados al revisar el Proyecto 1, Lab03 y el anexo. **Ninguno está decidido ni implementado**; cuando el grupo decida, cada uno pasa a la sección 2 como cambio o se descarta con su razón.

| ID | Fuente | Fragmento o situación | Pregunta | Impacto |
|---|---|---|---|---|
| PEN-01 **(Resuelto en CAM-005)**| Anexo G08-P01-L y sección D; RN-09 | En P1, `ENVIO.id_recoleccion` es NN | ¿Se permite crear un envío sin recolección? El anexo pide no obligarla | Si se mantiene NN, no puede demostrarse G08-P01-L |
| PEN-02 | Anexo G08, sección C, «Identidad y dominios» | Los medios de contacto de Lab03 solo admiten TELEFONO, CORREO y WHATSAPP | ¿Cómo se representa la categoría «Otro»? | Afecta las tres tablas `medio_contacto_*`, sus datos y `sp_registrar_contacto` |
| PEN-03 | RN-02, S-02; enunciado general, sección 4 (rutas de escritura) | La regla «solo organizaciones con contactos, con al menos una facultad» solo la valida `sp_registrar_contacto` | ¿Cómo se impide que un `INSERT` directo en `contacto` la eluda? | Hay que documentar la ruta de escritura permitida o agregar un mecanismo |
| PEN-04 **(Resuelto en CAM-006)** | RN-11; anexo G08-P01-I y P01-L | No hay dónde registrar qué contenido es prohibido o exige respaldo | ¿Cómo se representan las categorías de contenido sin inventar una lista legal? | Sin esto no puede demostrarse el rechazo de material prohibido ni la exigencia de respaldo |
| PEN-05 **(Resuelto en CAM-007)** | Anexo G08-P03 y sección C, «Ubicación y seguimiento»; RN-24 | EVENTO_SEGUIMIENTO solo tiene `id_sede` (NULL) como ubicación | ¿Cómo se registra un hecho ocurrido fuera de una sede sin forzar una sede ficticia? | Afecta G08-P03-L |
| PEN-06 | Anexo G08-P03-I y AC-G08-P03-04 | Las referencias del evento a salida y devolución son simples | ¿Cómo se garantiza que el paquete del evento viaja en esa salida o pertenece a esa devolución? | Sin esto puede cruzarse paquete y envío |
| PEN-07 | S-06, RN-07; CAM-004 | Mínimos: al menos un envío por solicitud, un paquete por envío y un paquete por devolución | ¿Con qué mecanismo se garantizan los mínimos? | No se pueden expresar con FK |
| PEN-08 | RN-16; anexo sección C | `ENTREGA_PAQUETE.es_final` no tiene restricción | ¿Cómo se garantiza una sola entrega final por paquete? | Ver 4.2 |
| PEN-09 **(Resuelto en CAM-008)** | Anexo G08, sección C, «Asignaciones» | ASIGNACION tiene `id_recoleccion` e `id_salida` opcionales | ¿Cómo se evita que una asignación apunte a ambas o a ninguna? | Afecta G08-P02 |
| PEN-10 | RN-20; anexo G08-P02-I y P02-L | Capacidad de peso y volumen, condición operativa y periodos fuera de servicio | ¿Cómo y cuándo se compara la carga con la capacidad? | Afecta G08-P02 y su concurrencia |
| PEN-11 | RN-21, S-13 | Traslape de asignaciones; se permite empezar cuando termina la anterior | ¿Qué mecanismo se usa? | Ver 4.2 |
| PEN-12 | S-12, RN-13 | La partida se marca con un evento de salida | ¿Cómo se impide agregar paquetes después de la partida? | Ver 4.2 |
| PEN-13 | RN-22, S-14 | `ASIGNACION.funcion_ejercida` es independiente de FUNCION_PERSONAL | ¿Se exige que la función pertenezca a la persona? | Afecta G08-P02 |
| PEN-14 **(Resuelto en CAM-009)** | Enunciado general, sección 2.1; anexo G08-P02-L | El diccionario del Proyecto 1 fija kilogramos para el peso y centímetros para las dimensiones declaradas del paquete, pero no hay unidad para volumen (capacidad del vehículo, rangos de tarifa) ni para las mediciones | ¿Qué unidad de volumen se usa y cómo se compara con las dimensiones en centímetros? | Afecta diccionario, P01 y P02 |
| PEN-16 | S-15 | Situación, estado y resultado son listas cerradas | ¿Cuáles son los valores concretos de cada lista? | Afecta diccionario y dominios de varias relaciones |
| PEN-17 | RN-19; CAM-004 | La devolución debe vincularse con su causa, pero `id_entrega` e `id_incidencia` son ambos NULL | ¿Se exige al menos una causa? | Afecta DEVOLUCION |
| PEN-18 | RN-13 | RUTA tiene sede destino y zona destino opcionales | ¿Se exige al menos uno? | Afecta RUTA |
| PEN-19 | RN-08, S-05 | TARIFA puede pertenecer a un cliente | ¿La tarifa de un cliente solo puede aplicarse a envíos de ese pagador y dentro de su vigencia? | Afecta G08-P01 |
| PEN-20 | RN-05 | `SOLICITUD.destino` es un único texto, pero una solicitud origina varios envíos a destinos distintos | ¿Qué representa ese atributo? | Afecta la interpretación de SOLICITUD |
| PEN-21 | Anexo G08, sección C, «Direcciones, tarifa y mediciones» | La excepción reconocida de RECOLECCION frente a BCNF | ¿Cómo se justifica su coherencia? | Requiere justificación documentada |
| PEN-22 | CAM-002 | Al reprogramar una recolección | ¿Todos los envíos pendientes pasan a la nueva recolección? | Supuesto asociado a CAM-002 |

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