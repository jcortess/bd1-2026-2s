# Procesos de negocio y operaciones — Grupo 08: Envíos Conecta

Este documento describe las operaciones públicas implementadas en `sql/03_rutinas.sql` y las consultas de `sql/04_consultas.sql`. Para cada operación se indica su propósito, la información que recibe, lo que devuelve o modifica, sus precondiciones, sus rechazos y el alcance de su transacción.

## 1. Convenciones

- **Procedimientos** (`sp_`, se ejecutan con `CALL`): modifican datos y no devuelven valor.
- **Funciones** (`fn_`, se ejecutan con `SELECT`): devuelven el identificador del registro creado, para usarlo en operaciones siguientes.
- **Rechazos:** todas las rutinas usan `RAISE EXCEPTION` con un código SQLSTATE (`ERRCODE`) y un nombre de restricción (`CONSTRAINT`). Así, una prueba puede verificar la causa exacta del rechazo y distinguirla de un error accidental. Los rechazos del propio esquema (CHECK, FK, UNIQUE, exclusión y triggers) conservan el nombre de su restricción.
- **Transacción:** cada llamada es atómica. Si una operación falla, se deshace todo lo que hizo; no quedan cabeceras sin detalle ni cambios parciales.
- **Unidades:** peso en kg, dimensiones en cm, volumen en m³ y precios en colones (CAM-009).

## 2. G08-P01 — Crear envíos y paquetes

### P01.1 `sp_crear_envio` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Crear una guía a partir de una solicitud, con todos sus paquetes, copiando las direcciones usadas y la cotización (RN-04, RN-06, RN-07, RN-08) |
| Entradas | Guía, solicitud, pagador (tipo y número), remitente, destinatario, tarifa, servicio, dirección de origen y de destino (provincia, cantón, distrito y otras señas), lista de paquetes en JSON y fecha de creación (por defecto, hoy). Cada paquete: `peso`, `largo`, `ancho`, `alto`, `descripcion`, `politica` y, opcionales, `respaldo` y `condiciones` (lista) |
| Modifica | ENVIO, PAQUETE y CONDICION_MANEJO_PAQUETE |
| Precondiciones | Solicitud, pagador, participantes y tarifa existentes |
| Rechazos | `ck_envio_paquetes_requeridos` (lista vacía o incompleta), `fk_envio_tarifa` (tarifa inexistente), `ck_envio_tarifa_pagador` (tarifa de contrato de otro cliente, CAM-013), `ck_envio_tarifa_vigente` (fuera de vigencia, CAM-013), `ck_envio_tarifa_servicio` (servicio distinto al de la tarifa), `ck_envio_tarifa_rango` (peso o volumen fuera de rango), `pk_envio` (guía duplicada), y las restricciones de ENVIO y PAQUETE del esquema |
| Transacción | Envío, paquetes y condiciones en una sola operación; además, un trigger diferido rechaza al confirmar un envío sin paquetes (CAM-012). La tarifa se lee con `FOR SHARE` |
| Concurrencia | Dos sesiones que crean la misma guía: la segunda espera a la primera y es rechazada por `pk_envio` |

### P01.2 `sp_registrar_revision` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Registrar la revisión inicial de un paquete: quién, cuándo, resultado y razón (RN-11) |
| Entradas | Guía, número de paquete, revisor, resultado (ACEPTADO, RETENIDO, RECHAZADO), razón y documento de respaldo (opcionales) |
| Modifica | PAQUETE (`revision_*` y `documento_respaldo`) |
| Precondiciones | El paquete existe y no tiene revisión; el revisor es OPERADOR_SEDE |
| Rechazos | `fk_paquete_envio` (paquete inexistente), `ck_paquete_revision_unica` (ya revisado: un único resultado), `ck_paquete_revisor_operador`, y del esquema `ck_paquete_prohibido_rechazado`, `ck_paquete_respaldo_exigido` y `ck_paquete_revision_razon` (CAM-006) |
| Transacción | Una actualización. Un rechazo o una retención se guarda como decisión con su razón, sin habilitar el paquete para el transporte (solo los ACEPTADO entran a un manifiesto) |
| Concurrencia | El paquete se bloquea con `FOR UPDATE`: dos revisiones simultáneas se ejecutan una tras otra y la segunda es rechazada |

### P01.3 `sp_registrar_medicion` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Agregar una medición sin reemplazar las anteriores y, opcionalmente, usarla para clasificar y cobrar (RN-10, S-07) |
| Entradas | Guía, número de paquete, sede, peso, largo, ancho y alto, y si la medición pasa a ser la aplicada (por defecto, sí) |
| Modifica | MEDICION (fila nueva) y, opcionalmente, `PAQUETE.num_medicion_aplicada` |
| Precondiciones | El paquete y la sede existen |
| Rechazos | `fk_medicion_paquete` (paquete inexistente), y del esquema `fk_medicion_sede` y `ck_medicion_valores` |
| Transacción | Medición y medición aplicada juntas. Las mediciones no se modifican ni se borran (CAM-014) |
| Concurrencia | El paquete se bloquea con `FOR UPDATE`: si dos sesiones miden el mismo paquete, la segunda espera y toma el número siguiente; ninguna sobrescribe a la otra |

## 3. G08-P02 — Preparar salidas y manifiestos

### P02.0 `sp_validar_vehiculo_disponible` (procedimiento interno)

| Aspecto | Descripción |
|---|---|
| Propósito | Verificar que un vehículo esté OPERATIVO y sin periodo fuera de servicio en un intervalo (RN-20, CAM-025). Lo usan las demás rutinas de P02 |
| Rechazos | `ck_asignacion_vehiculo_existente`, `ck_asignacion_vehiculo_operativo`, `ck_asignacion_vehiculo_fuera_servicio` |

### P02.1 `fn_crear_salida` (función)

| Aspecto | Descripción |
|---|---|
| Propósito | Crear una salida fechada de una ruta del catálogo (RN-13): la ruta es el catálogo y la salida, el viaje concreto |
| Entradas | Ruta y fecha |
| Devuelve | Id de la salida, en estado PLANIFICADA |
| Rechazos | `fk_salida_ruta_ruta` (ruta inexistente) |

### P02.2 `sp_agregar_paquete_salida` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Incluir un paquete en el manifiesto de una salida (RN-13, CAM-026) |
| Entradas | Salida, guía y número de paquete |
| Modifica | SALIDA_PAQUETE |
| Precondiciones | Salida PLANIFICADA; paquete ACEPTADO y que no esté en otra salida PLANIFICADA, CONFIRMADA o EN_RUTA |
| Rechazos | `ck_salida_existente`, `ck_salida_planificada` (manifiesto cerrado), `fk_salida_paquete_paquete`, `ck_salida_paquete_aceptado` (retenido, rechazado o sin revisar), `ck_salida_paquete_una_activa`, `pk_salida_paquete` (ya está en esa salida) |
| Concurrencia | La salida y el paquete se bloquean con `FOR UPDATE`: una confirmación o la inclusión simultánea del mismo paquete en otra salida espera |

### P02.3 `fn_asignar_salida` (función)

| Aspecto | Descripción |
|---|---|
| Propósito | Asignar una persona y un vehículo a una salida (RN-13, RN-20, RN-21, RN-22) |
| Entradas | Salida, persona, vehículo, función e intervalo `[inicio, fin)` |
| Devuelve | Id de la asignación |
| Precondiciones | Salida PLANIFICADA; vehículo disponible en el intervalo |
| Rechazos | `ck_salida_existente`, `ck_salida_planificada`, los de `sp_validar_vehiculo_disponible`, y del esquema `ex_asignacion_personal_traslape` y `ex_asignacion_vehiculo_traslape` (CAM-015) y `fk_asignacion_funcion_personal` (CAM-016) |
| Concurrencia | Dos sesiones que asignan la misma persona o el mismo vehículo en horarios superpuestos: la segunda espera y es rechazada por la restricción de exclusión |

### P02.4 `fn_sustituir_asignacion` (función)

| Aspecto | Descripción |
|---|---|
| Propósito | Cambiar la persona o el vehículo antes de ejecutar la operación, conservando la asignación original, el momento y el motivo (RN-23, CAM-027) |
| Entradas | Asignación original, nueva persona, nuevo vehículo, función y motivo |
| Devuelve | Id de la nueva asignación, con la misma operación e intervalo que la original |
| Modifica | ASIGNACION: la original pasa a `vigente = false` y se inserta la nueva con `id_asignacion_sustituida` |
| Precondiciones | Original vigente; su salida (o recolección) PLANIFICADA |
| Rechazos | `ck_asignacion_existente`, `ck_asignacion_vigente`, `ck_salida_planificada`, `ck_recoleccion_planificada`, los de `sp_validar_vehiculo_disponible` y del esquema (traslapes, función, `ck_asignacion_motivo_sustitucion`) |
| Transacción | Si la nueva asignación falla, nada cambia y la original sigue vigente: la sustitución fallida conserva el plan previo |

### P02.5 `sp_confirmar_salida` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Dar por preparada una salida (CAM-025, CAM-026, CAM-027) |
| Entradas | Salida |
| Modifica | `SALIDA_RUTA.estado = CONFIRMADA`; el manifiesto queda cerrado |
| Verifica | Al menos un paquete; al menos un CONDUCTOR vigente; un único vehículo entre las asignaciones vigentes, disponible en cada una; peso y volumen del manifiesto (medición aplicada o declarado) dentro de la capacidad; vehículo refrigerado si algún paquete tiene REFRIGERACION |
| Rechazos | `ck_salida_existente`, `ck_salida_planificada`, `ck_salida_con_paquetes`, `ck_salida_con_conductor`, `ck_salida_un_vehiculo`, `ck_salida_capacidad_peso`, `ck_salida_capacidad_volumen`, `ck_salida_refrigeracion` y los de `sp_validar_vehiculo_disponible` |
| Transacción | La salida se bloquea con `FOR UPDATE`; si falla, sigue PLANIFICADA y no se considera confirmada |

### P02.6 `sp_iniciar_salida` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Registrar la partida de una salida confirmada (S-12, CAM-026) |
| Modifica | `SALIDA_RUTA.estado = EN_RUTA` |
| Rechazos | `ck_salida_existente`, `ck_salida_confirmada` |

## 4. G08-P03 — Registrar seguimiento e incidencias

### P03.1 `fn_registrar_evento` (función)

| Aspecto | Descripción |
|---|---|
| Propósito | Registrar un movimiento o situación de un paquete (RN-12, RN-24) |
| Entradas | Guía, paquete, momento del hecho, responsable, tipo de evento, situación, condición y, opcionales, sede, descripción de la ubicación, salida y observaciones |
| Devuelve | Id del evento |
| Modifica | EVENTO_SEGUIMIENTO (fila nueva; nunca modifica las anteriores) |
| Rechazos | `fk_evento_seguimiento_paquete`, `ck_evento_seguimiento_momento` (momento futuro, CAM-024), y del esquema `ck_evento_seguimiento_ubicacion` (CAM-007), `fk_evento_seguimiento_salida_paquete` (paquete que no viaja en esa salida, CAM-018) y dominios |
| Transacción | Una inserción; la base registra el momento de registro, lo que distingue un hecho registrado después de ocurrir (CAM-003) |
| Concurrencia | Dos sesiones que registran eventos del mismo paquete: ambos se conservan y el actual se determina por el orden de CAM-003 |

### P03.2 `fn_corregir_evento` (función)

| Aspecto | Descripción |
|---|---|
| Propósito | Corregir un evento registrado por error, sin modificarlo ni borrarlo (RN-25) |
| Entradas | Evento original, autor, motivo y los datos correctos del evento |
| Devuelve | Id del evento de corrección, del mismo paquete que el original |
| Rechazos | `fk_evento_seguimiento_corregido` (original inexistente), `uq_evento_seguimiento_corregido` (ya corregido), `ck_evento_seguimiento_momento`, y las reglas de un evento normal |
| Concurrencia | El original se bloquea con `FOR UPDATE`: si dos sesiones lo corrigen, la segunda espera y es rechazada |

### P03.3 `fn_registrar_incidencia` (función)

| Aspecto | Descripción |
|---|---|
| Propósito | Registrar una incidencia que afecta uno o varios paquetes (RN-17, RN-18) |
| Entradas | Responsable de atención, tipo, descripción, lista de paquetes en JSON (`[{"guia": "...", "paquete": 1}]`) y fecha |
| Devuelve | Id de la incidencia, en estado ABIERTA |
| Modifica | INCIDENCIA e INCIDENCIA_PAQUETE (cada paquete en PENDIENTE, CAM-021) |
| Rechazos | `ck_incidencia_paquetes_requeridos`, y del esquema `fk_incidencia_paquete_paquete` y `pk_incidencia_paquete` |
| Transacción | Incidencia y paquetes afectados en una sola operación |

### P03.4 `sp_resolver_paquete_incidencia` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Determinar el resultado de una incidencia para un paquete (RN-18) |
| Entradas | Incidencia, guía, paquete y resultado (RESUELTO o SIN_SOLUCION) |
| Modifica | `INCIDENCIA_PAQUETE.resultado`; la incidencia pasa de ABIERTA a EN_ATENCION |
| Rechazos | `ck_incidencia_existente`, `ck_incidencia_no_resuelta`, `ck_incidencia_paquete_resultado`, `ck_incidencia_paquete_afectado` |
| Concurrencia | La incidencia se bloquea con `FOR UPDATE`: dos sesiones que la resuelven se ejecutan una tras otra sin perder resultados |

### P03.5 `sp_cerrar_incidencia` (procedimiento)

| Aspecto | Descripción |
|---|---|
| Propósito | Marcar una incidencia como RESUELTA con su resolución (RN-17) |
| Entradas | Incidencia y resolución |
| Rechazos | `ck_incidencia_existente`, `ck_incidencia_no_resuelta`, `ck_incidencia_sin_pendientes` (algún paquete sigue PENDIENTE), y del esquema `ck_incidencia_resolucion` |
| Concurrencia | La incidencia se bloquea con `FOR UPDATE`, así una resolución concurrente termina antes de contar los pendientes |

## 5. Rutinas reutilizadas de Lab03

| Rutina | Uso en esta entrega |
|---|---|
| `fn_solicitudes_cliente` | Solicitudes de un cliente con rango de fechas; rechaza un cliente inexistente |
| `sp_registrar_contacto` | Alta atómica de contacto con su primera facultad y medio; es la ruta admitida para registrar contactos (S-02). No registra medios de tipo OTRO |
| `fn_prioridad_solicitud`, `fn_reporte_prioridades` | Propuesta didáctica de Lab03; no es una prioridad oficial de transporte ni la usan los procesos |

## 6. Rutas de escritura admitidas

El enunciado pide explicar por qué una ruta habilitada no puede eludir una garantía. Las reglas se reparten así:

| Garantía | Dónde se garantiza |
|---|---|
| Identidad, referencias, dominios, traslapes, entrega final única, contexto de eventos y devoluciones, inmutabilidad de mediciones y eventos, mínimo de paquetes por envío, contactos solo de organizaciones, datos de la entrega | **Esquema** (restricciones y triggers): se cumplen por cualquier ruta, incluso con `INSERT`, `UPDATE` o `DELETE` directos |
| Tarifa aplicable y vigente; revisor operador; revisión única; manifiesto solo de paquetes aceptados y sin salidas activas simultáneas; capacidad, refrigeración y disponibilidad del vehículo; sustitución solo en planificación; momento no futuro; cierre de incidencias sin pendientes; al menos una facultad por contacto | **Rutinas** de `03_rutinas.sql`: son la única ruta admitida para estas operaciones. Una escritura directa en las tablas no es una ruta admitida del sistema y no se usa en los procesos ni en las pruebas |

## 7. Consultas (`sql/04_consultas.sql`)

| Consulta | Propósito | Criterio |
|---|---|---|
| C1 | Estado actual de cada paquete: último evento vigente, ubicación y responsable | AC-G08-P03-01 |
| C2 | Historial de un paquete, con las correcciones y los eventos corregidos | AC-G08-P03-03 |
| C3 | Incidencias con el resultado de cada paquete y los pendientes | AC-G08-P03-02 |
| C4, C4b | Manifiesto de una salida y su carga frente a la capacidad del vehículo | AC-G08-P02-01, 02 |
| C5 | Asignaciones de una salida, vigentes y sustituidas, con su motivo | AC-G08-P02-03 |
| C6 | Envíos con sus paquetes: contexto y cotización conservados, declarado frente a medido, resultado de la revisión | AC-G08-P01-01 a 04 |
| C7 | Solicitudes con devoluciones y la entrega rechazada que las originó | RN-19, CAM-020 |
| C8 | Paquetes con contenido prohibido por la empresa y quién los envía | RN-11, CAM-006 |
| L1 a L6 | Consultas reutilizadas de Lab03 | — |