# IC-4301 — Segunda entrega, Grupo 03: Universidad Horizonte

## A. Contexto y alcance obligatorio

Universidad Horizonte administra admisiones, versiones de planes, oferta de grupos y solicitudes de matrícula. Debe explicar decisiones con la trayectoria y plan de cada admisión y conservar cambios académicos, no solo matrículas vigentes.

Esta entrega exige implementar en **PostgreSQL el 100 % del modelo relacional final**, con correcciones/ampliaciones justificadas del Proyecto 1 y Lab03. El modelo previo es punto de partida: no permite excluir un proceso por defectos o contradicciones. Se implementan **3 procesos**, exactamente los identificados abajo. Se eligen nombres, firmas y técnicas; no hay cuota de funciones/procedimientos/cursores/triggers ni se exige aplicación, frontend, backend o API.

Los tres procesos son oferta/horarios, decisión de matrícula y espera/retiro/cambio. Los datos de admisión, planes, reconocimientos y resultados previos pueden prepararse. No se asigna el flujo completo de traslado de plan, reconocimiento o corrección de notas como proceso adicional.

Los hechos de procesos no asignados pueden prepararse como datos válidos para probar dependencias e integridad. No se pueden preparar los resultados finales de los procesos asignados y presentarlos como operaciones ejecutadas. No se recalifican entregas anteriores. Se permite IA con comprensión y validación propia.

## B. Procesos asignados y aceptación

### G03-P01 — Gestionar oferta y horarios

**Necesidad:** Publicar grupos y horarios utilizables para matrícula, conservando cambios relevantes y conflictos de espacio.

**Situación operativa:** Una escuela ofrece un grupo por periodo/sede con cupo, modalidad y docentes. Se asignan bloques; posteriormente cambia cupo o se cancela oferta ya matriculada.

**Información requerida, sin firma SQL impuesta:** Periodo/ventanas, sede, curso, número de grupo, cupo, modalidad, docente responsable y adicionales, bloques con día/horas y espacio si presencial; autor/fecha/motivo de cambios.

**Reglas y comportamiento esperado:**

- Un grupo posee docente responsable y puede tener adicionales.
- La actividad presencial identifica espacio; no asignarlo simultáneamente a dos grupos.
- Conservar cambios relevantes de apertura/cierre/cancelación/cupo.
- Cancelar un grupo con matrículas no elimina esas matrículas ni su historia.

**Relaciones o conceptos relacionados:** Periodo académico, grupo, grupo–docente, docente, bloque horario, espacio, sede y curso. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Oferta consultable por periodo/sede/curso/docente, bloques y capacidad; historia de cambios y matrículas afectadas conservadas.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G03-P01-V | Crear oferta con varios bloques y docentes, modificar su cupo sin volver inconsistente la ocupación y cancelar otro grupo con solicitudes existentes. Consultar anterior/actual y motivo. |
| G03-P01-I | Intentar asignar el mismo espacio a bloques traslapados de grupos distintos; omitir docente responsable o espacio presencial. No persistir oferta inconsistente. |
| G03-P01-L | Actividad sin espacio por modalidad no presencial; bloques consecutivos según convención declarada. Una reducción de cupo por debajo de matrículas existentes no puede ocultar ni borrar estudiantes: documentar tratamiento compatible con el caso. |

**Transacción:** Grupo, bloques y docentes requeridos deben quedar coherentes. Un cambio relevante no queda sin historia; cancelar oferta y resolver efectos permitidos conserva las solicitudes previas.

**Concurrencia pertinente:** Dos sesiones asignan un mismo espacio/periodo o cambian cupo mientras se matricula. El estado final respeta ocupación y no pierde matrículas; la interpretación de cierre/reducción debe estar documentada. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G03-P01-01:** La oferta identifica contexto, modalidad, cupo, docentes y bloques.
- **AC-G03-P01-02:** No hay dos usos incompatibles confirmados del mismo espacio.
- **AC-G03-P01-03:** Los cambios relevantes conservan responsable/fecha/motivo.
- **AC-G03-P01-04:** Cancelar no borra matrículas y el cupo publicado se interpreta coherentemente con la ocupación.

**Límite del proceso:** No incluye contratación docente ni registro completo de calificaciones. Trayectoria, catálogos y admisiones válidas pueden prepararse como datos; resolver la atomicidad de ventanas del periodo sí es necesario para estos procesos.

**Fundamento del caso:** secciones Periodos y oferta académica. Los procesos se numeran consecutivamente dentro de este anexo.

### G03-P02 — Resolver matrícula

**Necesidad:** Aceptar, rechazar o dejar en espera una solicitud explicando el resultado con el plan y expediente de la admisión.

**Situación operativa:** Dentro de la ventana, un estudiante solicita un grupo para una admisión activa; puede satisfacer un curso por aprobación o reconocimiento, y un correquisito por aprobación o matrícula del mismo periodo.

**Información requerida, sin firma SQL impuesta:** Estudiante/admisión, plan asignado, grupo/periodo, estado de oferta, trayectoria y reconocimientos, requisitos/correquisitos, horarios/cupo; autorización/motivo de excepción si existe.

**Reglas y comportamiento esperado:**

- Solicitudes durante fechas autorizadas y para admisión activa.
- Validar requisitos, correquisitos, horario y cupo según versión del plan, no según año actual.
- Una excepción a requisito identifica autorización y motivo.
- No mantener dos matrículas activas del mismo curso en un periodo; repetir en periodo posterior puede ser válido.
- Conservar resultado y razones de rechazo o espera.

**Relaciones o conceptos relacionados:** Solicitud/matrícula como la represente el equipo, admisión, plan/participación/requisitos, reconocimiento/resultado previo, grupo y bloques. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Resultado persistido con motivo y cupo/horario coherentes; consultas de matriculados, rechazados, espera y excepciones.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G03-P02-V | Resolver solicitudes satisfechas por aprobado o reconocimiento y otra con correquisito matriculado en el periodo. Registrar además una excepción a requisito con autorización y motivo y comprobar su efecto acotado. Verificar plan usado, aceptación y ocupación resultante. |
| G03-P02-I | Solicitar sin requisito satisfecho ni excepción, con choque de horario o duplicación del curso en el periodo; fuera de ventana o admisión inactiva. Conservar razón del resultado y no consumir cupo indebidamente. |
| G03-P02-L | Competir por el último cupo; satisfacción de correquisito al momento de resolver; extremos de ventana según representación declarada; repetición en otro periodo. Probar duplicación del mismo curso desde admisiones distintas del mismo estudiante. No exigir requisitos lógicos alternativos complejos excluidos del caso. |

**Transacción:** Resolución, consumo de cupo y excepción/historia aplicables coherentes. Un rechazo del negocio puede quedar registrado con su motivo, pero no como matrícula activa ni consumo parcial de capacidad.

**Concurrencia pertinente:** Dos sesiones solicitan el último cupo o el mismo estudiante solicita dos grupos del mismo curso. El resultado conjunto no excede capacidad ni mantiene duplicación activa. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G03-P02-01:** Se demuestra cada vía de satisfacción utilizada y su versión de plan.
- **AC-G03-P02-02:** La decisión conserva resultado/razón y autorización cuando hay excepción.
- **AC-G03-P02-03:** No se admiten choque, duplicación activa ni exceso de cupo.
- **AC-G03-P02-04:** La concurrencia del último cupo produce decisiones coherentes y verificables.

**Límite del proceso:** No incluye implementar el flujo completo de notas o reconocimiento; sus hechos válidos pueden prepararse. Los cursos compartidos/requisitos externos a versión no se prohíben por una observación formativa: su interpretación se documenta sin contradecir el caso.

**Fundamento del caso:** secciones Solicitud y matrícula; Planes, cursos y requisitos; Estudiantes y carreras. Los procesos se numeran consecutivamente dentro de este anexo.

### G03-P03 — Gestionar lista de espera, retiros y cambios

**Necesidad:** Liberar y reasignar cupos con historia y orden de espera, sin perder la relación entre solicitudes.

**Situación operativa:** Una persona retira matrícula dentro del plazo; se evalúa al siguiente elegible. Otra solicita cambio al grupo del mismo curso y debe revalidar condiciones del destino.

**Información requerida, sin firma SQL impuesta:** Solicitud/admisión/curso/periodo, orden de espera y elegibilidad actual, plazo de modificación, grupo destino, antecedente y momento de transición.

**Reglas y comportamiento esperado:**

- Conservar orden de ingreso a espera y cuándo pasa a matrícula.
- Al liberarse cupo puede avanzar el siguiente elegible.
- Retiro solo en periodo permitido.
- Cambio de grupo del mismo curso conserva solicitud anterior y revalida horario/cupo.
- No mantener dos matrículas activas del mismo curso por un cambio parcial.

**Relaciones o conceptos relacionados:** Solicitud con sus estados e historia, grupo, periodo/ventanas y condiciones de elegibilidad de matrícula. Son referencias al negocio y al diseño previo; ustedes resuelven su representación completa y los ajustes necesarios.

**Resultados observables:** Cola ordenada, movimientos y razones verificables; matrícula anterior retirada/cambiada sin desaparición del antecedente.

| Evidencia de aceptación | Situación y comprobación esperada |
|---|---|
| G03-P03-V | Con una cola donde el primero ya no es elegible, liberar cupo por retiro y promover al siguiente elegible, conservando qué ocurrió con ambos. Realizar un cambio válido de grupo con vínculo a la solicitud anterior. |
| G03-P03-I | Intentar retiro fuera de plazo o cambio a grupo de otro curso, sin cupo o con choque. No dar por efectuado el cambio ni perder la matrícula original cuando no puede completarse. |
| G03-P03-L | Empate de ingreso a cola: documentar desempate estable. Ningún elegible disponible deja cupo libre sin inventar matrícula. Un cambio a grupo lleno no habilita doble matrícula; explicar resultado sin imponer una política no definida. |

**Transacción:** El cambio exitoso y sus estados/antecedentes forman unidad. La promoción puede ser operación separada del retiro si se documenta, pero no puede adjudicar más cupos de los liberados ni desordenar la elegibilidad.

**Concurrencia pertinente:** Dos sesiones intentan promover por el mismo cupo o retirar/cambiar la misma matrícula. No promover dos personas al único espacio ni perder una solicitud confirmada. La demostración identifica sesiones, acciones, confirmaciones/rechazos y datos finales; ustedes seleccionan el mecanismo.

**Criterios concretos:**

- **AC-G03-P03-01:** La cola y las transiciones conservan orden y momento.
- **AC-G03-P03-02:** Se reevalúa elegibilidad y se explica por qué una persona anterior no fue promovida.
- **AC-G03-P03-03:** Retiro/cambio respetan plazo y el cambio conserva origen y revalidaciones.
- **AC-G03-P03-04:** Un cambio fallido conserva matrícula previa; no hay sobrecupo ni duplicación activa bajo concurrencia.

**Límite del proceso:** No añade cobro de matrícula, proceso completo de notas ni equivalencias. El mecanismo de promoción no tiene que ser un servicio automático en segundo plano; debe poder ejecutarse y demostrarse directamente en PostgreSQL.

**Fundamento del caso:** secciones Solicitud y matrícula. Los procesos se numeran consecutivamente dentro de este anexo.

## C. Integridad del modelo completo

Todas las relaciones, incluso las que no aparecen en las operaciones de B, deben existir con claves, referencias, dominios, nulabilidad y reglas aplicables verificadas. El tamaño inicial no es una cuota que impida corregir/ampliar ni autoriza reducir el modelo. Entreguen correspondencia relación anterior–actual y regla–mecanismo–prueba.

**Inventario de partida para comprobar cobertura, sin esquema físico resuelto:** ESTUDIANTE; ADMISION; CARRERA; SEDE; VERSION_PLAN_ESTUDIOS; PERIODO_ACADEMICO; CURSO; ESCUELA; GRUPO; BLOQUE_HORARIO; ESPACIO; SOLICITUD_MATRICULA; DOCENTE; CARRERA_SEDE; PARTICIPACION_PLAN; REQUISITO_CURSO; TRASLADO_PLAN; RECONOCIMIENTO_ACADEMICO; GRUPO_DOCENTE.

| Área de atención | Verificación requerida y límite |
|---|---|
| Consolidación del modelo | Las 19 relaciones localizadas se declaran provisionales. Por decisión docente, el grupo debe corregir las discrepancias y entregar una consolidación definitiva coherente entre modelo, diccionario, trazabilidad e implementación, especialmente donde afecten los procesos asignados. Datos personales/contacto, identificadores/dominios, ventanas e históricos necesarios no pueden quedar «por definir». Registrar corrección y validación en Control_de_Cambios.md. |
| Contexto académico | Comprobar combinación carrera/sede/versión de la admisión y traslado con fecha/motivo/autorizante. Resolver y justificar redundancia de carrera respecto de versión sin perder significado. |
| Currículo | Verificar pertenencia, créditos y requisitos por versión. No prohibir cursos exigidos externos a una versión solo por una recomendación: documentar cómo se interpreta el curso compartido sin contradecir el caso. |
| Trayectoria y correcciones | Resultados/reconocimientos válidos deben permitir comprobar satisfacción de curso. Probar conservación de nota anterior, fecha/motivo/autorización de corrección donde aplique al modelo, sin desarrollar aquí todo el proceso de actas. |
| Historia y excepciones | Verificar oferta, matrículas previas/excepciones y razones de espera/rechazo. Que matrícula sea un estado de solicitud es válido si la estructura completa conserva identidad/historia y reglas. |

Para las relaciones fuera de los procesos asignados, preparen datos ficticios válidos y prueben identidad, referencia, dominio y reglas de contexto/temporalidad/estado que correspondan. Las comprobaciones incluyen intentos inválidos y lectura posterior de datos. No se exige una rutina de negocio por cada tabla ni ejecutar todos los flujos del caso: se exige demostrar sus reglas mediante pruebas reproducibles. Identifiquen cada relación cubierta y justifiquen lo no aplicable.

## D. Continuidad del Proyecto 1 y Lab03

**Aspectos que deben corregirse o completarse para el alcance actual:** Lab03 implementa seis tablas de currículo, no matrícula ni oferta. La propia normalización declara pendiente certificar atomicidad de ventanas y cerrar estructuras históricas. No puede utilizarse esa provisionalidad para omitir validación de fechas, cupo o excepciones de los procesos ahora asignados.

**Reutilización efectiva:** Conservar catálogo curricular, consultas de composición/requisitos, funciones de créditos/tipo y alta validada en plan cuando sigan siendo compatibles. Vigencia textual debe tener significado verificable cuando se utilice para resolver decisiones temporales; una suma cero no acredita existencia de una versión.

**Distinción entre defecto, observación y supuesto:** No se imponen expresiones alternativas complejas de requisitos ni una escala universal de calificación. El plazo, empate en cola, vigencia y tratamiento de reducción de cupo deben documentarse; no se autoriza borrar matrículas por cancelar oferta ni simplificar matrícula a un INSERT sin verificaciones.

Los cambios pertinentes se registran en `Control_de_Cambios.md`, con fuente, situación anterior, modificación, justificación, reglas, impacto, archivos y prueba actual. Incluyan sección de reutilización sin modificación. No se premia cambiar por cambiar ni se aplican descuentos retroactivos.

## E. Evidencia que debe poder repetirse

La aceptación de B se demuestra ejecutando operaciones sobre datos iniciales identificados y consultando después estados, valores, vínculos y antecedentes. No basta un aviso de éxito. Cada evidencia identifica su criterio AC, preparación, acción, resultado esperado previo, observado y comprobación de datos. Un rechazo muestra su causa y la ausencia de efectos indebidos; si el negocio conserva la decisión rechazada, muestre ese registro sin efectos de aceptación.

Incluyan confirmación y lectura posterior para demostrar persistencia, fallo de una operación compuesta para comprobar su atomicidad y sesiones concurrentes para los conflictos pertinentes de B. No se impone una cantidad artificial de rutinas ni un mismo algoritmo para todos. Los datos de prueba deben distinguir contextos válidos diferentes cuando se prueba integridad contextual; un error de referencia inexistente no demuestra por sí solo que se comprobó esa pertenencia.

El modelo completo se reproduce desde base nueva, con orden de scripts y versión PostgreSQL/cliente documentados. Las pruebas indican cómo manejar errores esperados y repetir sin residuos; no dejan transacciones abiertas. El paquete incluye README, modelo/diccionario/trazabilidad, SQL, pruebas, resultados observados, `Control_de_Cambios.md`, `Uso_de_IA.md` y `Defensa.md` con acceso al video.

## F. Condiciones particulares y defensa

No se imponen expresiones alternativas complejas de requisitos ni una escala universal de calificación. El plazo, empate en cola, vigencia y tratamiento de reducción de cupo deben documentarse; no se autoriza borrar matrículas por cancelar oferta ni simplificar matrícula a un INSERT sin verificaciones.

Todos los integrantes participan identificablemente en el video y explican decisiones, efectos en datos y una prueba/rechazo de su implementación. En trabajo individual se demuestra la totalidad de los dos procesos. Se permite IA, pero cada persona debe poder justificar lo incorporado y su verificación; no se valora principalmente el tiempo de escritura manual.

Los plazos o cantidades de días expresamente establecidos en los requisitos aplicables deben cumplirse y probarse. No se requieren valores numéricos adicionales si los procesos no los necesitan. Las ambigüedades restantes se documentan con fragmento, pregunta, supuesto e impacto. No se puede usar un supuesto para contradecir el caso o excluir una situación de B. No se establecen aquí fechas, duración del video ni rúbrica definitiva.

**Fuentes de lectura de este anexo:** Caso Universidad Horizonte, secciones Estudiantes y carreras, Planes, cursos y requisitos, Periodos y oferta académica y Solicitud y matrícula; normalización P0064–0088 y comentario docente12; documentación/SQL Lab03.

[Enunciado general](00_Enunciado_General.md) · [Especificación del control de cambios](Control_de_Cambios_Especificacion.md). Este anexo contiene sus obligaciones funcionales y de integridad; los documentos comunes amplían la organización y reproducción de la entrega.
