# IC-4301 — Segunda entrega, Grupo 11: Cooperativa Valle Verde

## A. Contexto y alcance obligatorio

Cooperativa Valle Verde reúne productores y conserva procedencia de cantidades agrícolas desde finca/cosecha hasta recepción y clasificación. Cada cosecha es un lote de origen y los resultados no deben mezclar productores ni magnitudes.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **2 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Trabajo individual: dos procesos, finca/responsables y recepción/clasificación. Se exige el mismo principio de modelo físico completo; no se agregan ciclos operativos, despacho, venta o liquidación como un tercer proceso.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G11-P01 — Registrar fincas y responsables

**Necesidad:** Identificar finca de un productor y conservar desde cuándo cambió su responsable para explicar procedencia de cosechas.

**Situación operativa:** Un asociado registra varias fincas con ubicación/área; posteriormente cambia la persona responsable y se consulta un periodo pasado.

**Información requerida, sin firma SQL impuesta:** Productor, identificación/nombre de finca, ubicación/área, responsable y fecha efectiva de cambio; referencia al antecedente e intervalo de responsabilidad cuando corresponda.

**Reglas y comportamiento esperado:**

- Productor puede registrar varias fincas y debe conservarse identidad completa de cada una.
- Cambio de responsable conserva fecha y no reescribe atribución histórica.
- Fechas deben ser de calendario válido; salida puede ser opcional para periodo abierto.
- No confundir contar fincas de las que fue responsable con ser responsable actual de ellas.

**Relaciones o conceptos relacionados:** Productor, finca, persona responsable y sus medios, historial/registro de responsabilidad; cosecha de origen como hecho relacionado preparado. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Fincas por productor, responsable actual/histórico y consulta por periodo con origen coherente.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G11-P01-V | Registrar dos fincas del mismo productor, asignar y cambiar responsable de una. Consultar antes/después y por periodo; una cosecha previa preparada conserva su procedencia histórica. |
| G11-P01-I | Intentar referenciar finca solo por componente que pertenece a otro productor, responsable inexistente o fecha como 31/02. No crear historia ajena ni fecha imposible. |
| G11-P01-L | Dos productores con igual código local de finca y periodo abierto. No se exige admitir reingreso al mismo historial por una recomendación opcional: si el diseño lo admite, explicar identidad de episodio y probarlo. |

**Transacción:** Cambio de responsable y registro histórico deben concordar; un fallo no modifica actual sin antecedente o historia de otra finca.

**Concurrencia pertinente:** Dos sesiones cambian responsable de la misma finca. Conservar orden efectivo y un actual explicable sin perder un cambio confirmado. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G11-P01-01:** La identidad de finca incluye su productor y permite códigos locales iguales en productores distintos.
- **AC-G11-P01-02:** Consulta histórica conserva los responsables de cada periodo sin reescribir hechos anteriores.
- **AC-G11-P01-03:** Se rechazan fecha imposible y referencia contextual incorrecta.
- **AC-G11-P01-04:** Fallo/cambio concurrente no deja responsable actual e historia contradictorios.

**Límite del proceso:** No añade mantenimiento de todo ciclo/cosecha como proceso evaluable. Esos hechos pueden prepararse para comprobar origen; no se exige geografía exhaustiva ni regla nueva de reingreso ausente del caso.

**Fundamento del caso:** secciones Productores y fincas; Necesidades de información. Los procesos se numeran consecutivamente dentro de este anexo.

### G11-P02 — Recibir y clasificar entregas

**Necesidad:** Aceptar cantidades de varios lotes sin perder cosecha/productor y sin clasificar más producto del recibido.

**Situación operativa:** Un productor entrega partes de varias cosechas. Personal recibe e inspecciona; una cantidad se acepta en categorías distintas, otra se rechaza y otra queda pendiente.

**Información requerida, sin firma SQL impuesta:** Productor, cosecha/lote de origen, unidad, cantidad ofrecida/recibida por origen, fecha/receptor; resultados de calidad/madurez/condición con cantidad, unidad, responsable y observaciones.

**Reglas y comportamiento esperado:**

- Cada cosecha constituye lote de origen; una entrega puede incluir varias cosechas del mismo productor.
- Distinguir cosechado, ofrecido y efectivamente recibido; pueden existir entregas parciales.
- Los resultados por origen pueden ser aceptación en distintas calidades, rechazo parcial o revisión pendiente.
- La cantidad clasificada no supera lo recibido; conservar responsable y observaciones.
- Pérdidas posteriores se documentan; no se usan para justificar desaparición silenciosa de recibido.

**Relaciones o conceptos relacionados:** Ciclo/cosecha/lote como antecedentes, entrega con cantidades por lote, receptor, resultados/observaciones y responsable de clasificación. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Detalle recibido por origen y resultados parciales; cantidades aceptadas/rechazadas/pendientes por producto/variedad/calidad/unidad reconstruibles.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G11-P02-V | Recibir parcialmente dos lotes del mismo productor y clasificar uno en varias categorías con rechazo o revisión pendiente. Realizar recepción posterior del mismo lote y comprobar acumulados sin duplicar original ni origen. |
| G11-P02-I | Intentar clasificar cantidad que excede la recibida o atribuir resultado a lote/productor ajeno. No crear aceptación adicional ni alterar saldo de otro lote. Probar cantidad/unidad inválida. |
| G11-P02-L | Cantidad clasificada exacta a recibida y clasificación parcial que deja pendiente; lote con parte no ofrecida a cooperativa. Con unidades distintas, declarar conversiones sustentadas o rechazar combinación, sin sumar magnitudes incompatibles. |

**Transacción:** Recepción y detalle de origen coherentes; cada clasificación mantiene cantidades/resultado en su contexto. Fallo en parte de la operación no deja cabecera presentada completa sin detalle ni acumulado inflado.

**Concurrencia pertinente:** Dos sesiones clasifican el último saldo no clasificado de la misma recepción/lote. No puede aceptarse en conjunto más de lo recibido; mostrar ambos resultados y pendientes finales. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G11-P02-01:** Se demuestra recepción parcial y repetida del mismo lote y entrega con varios orígenes del mismo productor.
- **AC-G11-P02-02:** Cada resultado identifica lote/cantidad/unidad/responsable, con categorías y rechazo/pendiente distinguibles.
- **AC-G11-P02-03:** Los acumulados distinguen cosechado/ofrecido/recibido/clasificado sin exceder lo recibido.
- **AC-G11-P02-04:** Fallo/concurrencia no cruza productor/lote ni sobreclasifica cantidad.

**Límite del proceso:** No incluye pedidos, despacho, reparto de ventas o pagos como procesos adicionales. Cosechas/lotes válidos deben poder existir antes de recepción y se pueden preparar como antecedentes; corregir su representación es necesario para este proceso, no reducirlo a la tabla defectuosa previa.

**Fundamento del caso:** secciones Cosechas y lotes de origen; Recepción y clasificación. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** Productor_Asociado; TELEFONO_PRODUCTOR; CORREO_PRODUCTOR; FINCA; Responsable_finca; TELEFONO_RESPONSABLE_FINCA; CORREO_RESPONSABLE_FINCA; HISTORIAL_RESPONSABLES; REGISTRO_EN_HISTORIAL_DE_RESPONSABLES; CICLO; COSECHA; LOTE; HISTORIAL_DE_CICLOS; REGISTRO_HISTORIAL_CICLOS; RECEPCIONISTA; TELEFONO_RECEPCIONISTA; CORREO_RECEPCIONISTA; ENTREGA; RESULTADO; OBSERVACION; EMPLEADO; TELEFONO_EMPLEADO; CORREO_EMPLEADO; COMPRADOR; TELEFONO_COMPRADOR; CORREO_COMPRADOR; DIRECCION_ENTREGA; SOLICITUD_DE_COMPRA; PEDIDO; DESPACHO; RECHAZO_DE_DESPACHO; PERDIDA.

| Área de atención | Verificación requerida y límite |
|---|---|
| Identidad y tipos | El punto de partida lista 32 relaciones. Completar identidad de finca/ciclo/resultados/despachos al referenciarlos; no usar componentes aislados de una identidad compuesta. Fecha válida no equivale a patrón de texto y número/unidad no deben impedir validar magnitud. |
| Cosecha/lote/recepción | Cada cosecha es lote de origen, existe antes de entrega y permite recepción parcial. Corregir cardinalidad, vínculo obligatorio de lote a entrega única y clasificación sin lote; son necesarios para G11-P02. |
| Cultivos y superficie | Probar catálogo de producto/variedad y cantidad de área de ciclos simultáneos coherente o justificada. Esto es integridad de relaciones no asignadas, no un proceso nuevo de planificación. |
| Pedido, despacho y rechazo | Probar origen y cantidades por lote/productor, cabecera/detalle y referencias completas; estado de pedido no completo con pendiente salvo aceptación parcial. Datos de integridad pueden prepararse sin construir su flujo funcional entero. |
| Trazabilidad y pérdidas | Distinguir cosechado/ofrecido/recibido/clasificado/disponible. Probar que merma tiene causa/autor/cantidad y no desaparece producto; cubrir RN del análisis que faltaban en matriz. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Lab03 implementó nueve tablas de productor/finca/responsables y corrigió referencias compuestas del historial; conservar esa mejora. Se demostró persistencia de 31/02/2026 por fechas textuales. Las limitaciones P1 de lote/recepción/clasificación deben corregirse: no reducir G11-P02 a registrar una cabecera sin origen de cantidades.

**Reutilización efectiva:** Reutilizar identidades compuestas corregidas, datos coherentes, consultas de finca/responsable por periodo y función SQL de fincas distintas. No se impone ahora la cuota anterior de PL/pgSQL/procedimiento/técnica ausentes: la selección de componentes responde a estos dos procesos.

**Distinción entre defecto, observación y supuesto:** El protocolo de pruebas negativas Lab03 tuvo decisión docente ya cerrada y no se reabre. Geografía exhaustiva y reingreso del mismo responsable no se convierten por sí solos en nuevas reglas. El guion actual sí debe documentar errores esperados y cerrar transacciones para poder reproducirse.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

El protocolo de pruebas negativas Lab03 tuvo decisión docente ya cerrada y no se reabre. Geografía exhaustiva y reingreso del mismo responsable no se convierten por sí solos en nuevas reglas. El guion actual sí debe documentar errores esperados y cerrar transacciones para poder reproducirse.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Cooperativa Valle Verde, secciones Productores y fincas, Cosechas y lotes de origen y Recepción y clasificación; lista final P0612–0671, hoja de observaciones P1 y retroalimentación Lab03.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
