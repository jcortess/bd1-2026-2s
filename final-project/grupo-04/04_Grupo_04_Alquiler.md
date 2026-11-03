# IC-4301 — Segunda entrega, Grupo 04: Alquileres El Roble

## A. Contexto y alcance obligatorio

Alquileres El Roble compromete cantidades de tipos de equipo y posteriormente entrega unidades identificadas. Debe conservar cotización, asignación y condición de cada unidad, incluidos retornos parciales y daños en revisión.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Se desarrollan reserva por cantidades, contrato/asignación y devolución/incidencia. La inspección/entrega de salida puede prepararse como antecedente válido. No se añaden gestión completa de prórrogas, objeción de cargos, transporte o cierre contable.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G04-P01 — Reservar cantidades

**Necesidad:** Comprometer cantidades por tipo para un periodo sin necesitar números de inventario desde el inicio.

**Situación operativa:** Un cliente solicita varios tipos/cantidades; se cotiza/confirma y luego cambian fechas o cantidades. La disponibilidad debe incluir otros compromisos y mantenimiento.

**Información requerida, sin firma SQL impuesta:** Cliente/representante pertinente, periodo, lugar, tipos/cantidades, condiciones/tarifa ofrecida y versión; reservas/contratos/mantenimiento que afectan disponibilidad, suspensiones y garantía exigible documentadas.

**Reglas y comportamiento esperado:**

- Permitir reserva por tipo/cantidad sin unidad física inicial.
- Considerar reservas confirmadas, contratos y mantenimiento al comprobar disponibilidad.
- Conservar tarifa ofrecida aunque cambie el catálogo.
- Conservar cambios de fecha/cantidad, cancelación o vencimiento sin borrar versiones.
- No dar por cumplida una facultad, suspensión o garantía exigible solo por existir el cliente.

**Relaciones o conceptos relacionados:** Reservación estable/versiones, detalle por tipo, cliente/autorización, tarifa, unidades y compromisos temporales. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Reserva con versión y precio/condición histórica; disponibilidad y cantidades comprometidas consultables por tipo/periodo.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G04-P01-V | Confirmar cantidades de dos tipos sin asignar unidades; modificar cantidad/periodo con disponibilidad. Consultar la versión anterior y la cotización conservada tras cambiar tarifa de catálogo. |
| G04-P01-I | Intentar cantidad superior a capacidad compatible disponible o periodo afectado por mantenimiento; representante sin facultad vigente cuando corresponda. No comprometer cantidades inválidas. |
| G04-P01-L | Última unidad disponible del tipo y periodos adyacentes según convención. Reserva convertida en contrato no debe contarse como dos compromisos independientes de la misma necesidad. |

**Transacción:** Versión y detalle se confirman juntos. Cambio inválido mantiene compromiso anterior y no libera/reserva cantidades parcialmente.

**Concurrencia pertinente:** Dos sesiones confirman la última cantidad de un tipo para el mismo periodo. Comprobar que no se promete más de lo físicamente compatible disponible. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G04-P01-01:** Se confirma por tipo/cantidad sin asignación física prematura.
- **AC-G04-P01-02:** La disponibilidad incorpora compromisos y mantenimiento sin duplicar una reserva convertida.
- **AC-G04-P01-03:** Se conservan cotización y versiones de cambios.
- **AC-G04-P01-04:** La competencia por capacidad no produce exceso confirmado.

**Límite del proceso:** No incluye diseñar un algoritmo tarifario nuevo ni un módulo de mantenimiento. Tarifas vigentes, suspensiones, garantías y periodos fuera de servicio pueden prepararse como hechos; deben aplicarse las condiciones del caso que correspondan a la reserva.

**Fundamento del caso:** secciones Tarifas y reservaciones; Clientes y personas autorizadas. Los procesos se numeran consecutivamente dentro de este anexo.

### G04-P02 — Formalizar contrato y asignar unidades

**Necesidad:** Convertir el compromiso por tipo en un contrato con unidades concretas, conservando condiciones y sustituciones.

**Situación operativa:** Una reserva confirmada origina contrato; también hay alquiler inmediato. Se seleccionan unidades/accesorios y una avería obliga a sustituir una unidad antes de entrega.

**Información requerida, sin firma SQL impuesta:** Cliente responsable, reserva si existe, periodo/lugar, depósito/garantía exigible y condiciones aceptadas; tipos, unidades/accesorios, compromisos y estado operativo; motivo/momento de sustitución.

**Reglas y comportamiento esperado:**

- Permitir contrato desde reserva confirmada o sin reserva si hay disponibilidad.
- Identificar unidades y accesorios concretos antes de la entrega.
- No asignar unidades incompatibles, mantenidas/fuera de servicio o comprometidas de manera incompatible.
- Sustituir por compatible conserva asignación anterior y motivo; no fingir que la nueva fue siempre la original.
- Conservar responsabilidad, periodo y condiciones/garantía aplicables.

**Relaciones o conceptos relacionados:** Contrato, reserva, asignación, unidad/tipo/accesorios, garantía y restricciones del cliente. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Contrato con detalle de unidades y accesorios, origen o alquiler inmediato, condiciones y cadena de sustitución consultables.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G04-P02-V | Formalizar contrato de reserva con unidades de varios tipos; crear otro inmediato disponible. Sustituir una unidad averiada antes de entrega y consultar asignación original/nueva. |
| G04-P02-I | Intentar unidad ocupada/incompatible o accesorio ya comprometido; fallar el último componente requerido. No dejar contrato operativo con asignación incompleta ni consumir recursos ajenos. |
| G04-P02-L | Reserva que comprometía cantidad pero aún no unidad; accesorio obligatorio frente a opcional. La certificación exigida para recibir debe verificarse en la etapa que corresponda; no imponerla anticipadamente como condición universal de cotizar. |

**Transacción:** Contrato y detalle requerido se confirman de modo coherente; conversión y asignación no duplican compromiso. Sustitución mantiene historia y libera solo lo que realmente corresponde.

**Concurrencia pertinente:** Dos contratos intentan la misma unidad o accesorio en periodos incompatibles. No se confirman ambas asignaciones; mostrar quién obtuvo recurso y estado del intento rechazado. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G04-P02-01:** Hay contrato derivado e inmediato con detalle concreto y responsabilidad/condiciones.
- **AC-G04-P02-02:** Las unidades/accesorios disponibles satisfacen el tipo y cantidad comprometidos.
- **AC-G04-P02-03:** Se conserva sustitución compatible y su causa sin sobrescritura histórica.
- **AC-G04-P02-04:** Fallo y concurrencia no dejan compromisos duplicados ni contrato falsamente completo.

**Límite del proceso:** No se exige ejecutar el proceso completo de inspección/entrega, prórroga ni cierre financiero. Para probar devoluciones del proceso siguiente se pueden preparar entregas e inspecciones válidas con su trazabilidad; las reglas de esas relaciones también se verifican.

**Fundamento del caso:** secciones Contrato, entrega y prórrogas; Catálogo y unidades alquilables; Tarifas y reservaciones. Los procesos se numeran consecutivamente dentro de este anexo.

### G04-P03 — Registrar devoluciones e incidencias

**Necesidad:** Reconocer qué unidad volvió, en qué condición y qué queda pendiente sin cerrar artificialmente todo el contrato.

**Situación operativa:** Regresa una de varias unidades entregadas. Se comparan accesorios/condición con salida, se detecta daño o faltante y se registra su evaluación.

**Información requerida, sin firma SQL impuesta:** Contrato/unidad/entrega de origen, fecha/hora real, uso, combustible/carga cuando aplique, accesorios y condición de retorno; inspección previa e incidencia con situación/atribución.

**Reglas y comportamiento esperado:**

- Permitir devolución parcial y en momentos distintos por unidad.
- Vincular incidencia con la unidad y entrega correctas y comparar condición de salida.
- Distinguir revisión, desgaste normal, atribución al cliente o envío a mantenimiento.
- Devolución física no implica cierre automático con unidades, daños o saldos pendientes.

**Relaciones o conceptos relacionados:** Asignación, entrega/inspección de salida, devolución/inspección de retorno, incidencia y contrato. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Unidades devueltas/pendientes, condición antes/después e incidencias atribuibles; contrato mantiene pendientes que correspondan.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G04-P03-V | Devolver una unidad de un contrato de varias, registrar faltante o daño y dejarlo en revisión; devolver después otra con desgaste normal. Consultar ambas condiciones y pendientes. |
| G04-P03-I | Intentar devolver una unidad de otra entrega/contrato o registrar por segunda vez el mismo retorno como nuevo. No duplicar devolución ni trasladar daño a contexto ajeno. |
| G04-P03-L | Retorno anticipado autorizado y devolución sin incidencias. Falta de accesorio y daños preexistentes no deben confundirse automáticamente con daño nuevo imputable. |

**Transacción:** Retorno, inspección y estado de la unidad coherentes; un fallo no la deja disponible con devolución incompleta ni inventa cierre total.

**Concurrencia pertinente:** Dos sesiones registran retorno/evaluación de la misma entrega. Debe existir una historia coherente y no duplicarse devolución o incidencias del mismo intento por conflicto de registro. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G04-P03-01:** Se distinguen retornos parciales y unidades aún entregadas.
- **AC-G04-P03-02:** La comparación antes/después identifica origen correcto de cada incidencia.
- **AC-G04-P03-03:** Las situaciones de evaluación no se reducen a todo daño imputable al cliente.
- **AC-G04-P03-04:** El fallo/conflicto no duplica retorno ni cierra contrato con pendientes.

**Límite del proceso:** No se asigna calcular toda tarifa de atraso, objetar/resolver cargos ni cerrar contrato como proceso adicional. Si hay cargos preparados, se conservan sus vínculos y sus pendientes; representar las relaciones de cobro sigue siendo obligatorio.

**Fundamento del caso:** secciones Devoluciones, daños y cobros asociados; Contrato, entrega y prórrogas. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** PERSONA; CLIENTE; CONTACTO_CLIENTE; SUSPENSION_CLIENTE; FACULTAD; AUTORIZACION; AUTORIZACION_FACULTAD; CERTIFICACION_PERSONA; TIPO_RECURSO; CERTIFICACION_REQUERIDA; ACCESORIO_REQUERIDO; UNIDAD; TARIFA; RESERVACION; RESERVA; DETALLE_RESERVA; CONTRATO; ASIGNACION; INSPECCION_SALIDA; ENTREGA; DEVOLUCION; INSPECCION_RETORNO; GARANTIA; PRORROGA; INCIDENCIA; CARGO; MANTENIMIENTO; CARGO_ASIGNACION; CARGO_INCIDENCIA.

| Área de atención | Verificación requerida y límite |
|---|---|
| Conciliación de artefactos | Hay 26 relaciones iniciales, 29 en texto/diccionario normalizados y 27 en el diagrama llamado normalizado. Por decisión docente, el grupo debe corregir esas discrepancias y entregar modelo, diagrama, diccionario, trazabilidad e implementación concordantes, especialmente donde afecten esta entrega. Conservar cobertura completa del resultado normalizado; registrar corrección y pruebas en Control_de_Cambios.md. Describir la discrepancia sin corregirla no satisface el requisito. |
| Clientes y facultades | Comprobar tipo de cliente, otorgamientos y facultades a la fecha necesaria, suspensiones y garantía exigible. Una facultad vigente no acredita por sí sola certificación técnica para recibir equipo. |
| Unidades y accesorios | Comprobar referencias tipo/unidad, accesorios obligatorios/opcionales, asignación del accesorio reutilizable y condición operativa; mantenimiento impide disponibilidad incompatible. |
| Origen contractual | Verificar contrato de asignación, entrega, incidencia, garantía y cargo; dos referencias a objetos existentes no permiten combinar contratos distintos. |
| Historias y pendientes | Cotización/versiones y sustitución no se sobrescriben. Las prórrogas rechazadas y objeciones de cargo se representan y prueban con datos válidos/negativos del modelo, sin crear otro flujo funcional asignado. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Lab03 implementó cinco relaciones de autorización temporal, no reserva ni alquiler. El texto final separa identidad estable/versiones de reserva y describe asociaciones de origen de cargo que faltan en el diagrama. Se debe consolidar un modelo sin pérdida de esas relaciones ni de su contexto contractual.

**Reutilización efectiva:** Reutilizar altas de autorización, consulta de facultad/otorgamientos y datos consistentes. La función que cuenta otorgamientos no cuenta personas distintas; el reporte temporal exige condiciones de sesión/transacción documentadas.

**Distinción entre defecto, observación y supuesto:** El procedimiento de autorización rechazó cliente físico/lista vacía y su ruta directa de tabla no garantizaba lo mismo: fue observación formativa, no orden de crear triggers. En el modelo completo indiquen rutas de escritura admitidas y demuestren sus reglas. No se fija una tarifa, depósito, plazo de reserva o certificación no definidos por el caso.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

El procedimiento de autorización rechazó cliente físico/lista vacía y su ruta directa de tabla no garantizaba lo mismo: fue observación formativa, no orden de crear triggers. En el modelo completo indiquen rutas de escritura admitidas y demuestren sus reglas. No se fija una tarifa, depósito, plazo de reserva o certificación no definidos por el caso.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Alquileres El Roble, secciones Clientes y personas autorizadas, Catálogo y unidades alquilables, Tarifas y reservaciones, Contrato, entrega y prórrogas y Devoluciones, daños y cobros asociados; Normalizacion.pdf pp.4–5/8–10 y diccionario final.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
