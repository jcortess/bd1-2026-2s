# Normalización

## Correspondencia con la normalización inicialmente entregada

**Antes:** la normalización del Proyecto 1 examinaba de forma particular cinco relaciones (`GRUPO`, `BLOQUE_HORARIO`, `SOLICITUD_MATRICULA`, `GRUPO_DOCENTE` y `PERIODO_ACADEMICO`) y denominaba provisional al conjunto de 19 relaciones. **Ahora:** se examinan las **26 relaciones** del modelo consolidado, distinguiendo dependencias funcionales reales de integridad histórica o restricciones entre filas. No se añade una relación únicamente para incrementar el conteo.

| Problema anterior | Tratamiento del análisis corregido | Registro |
| --- | --- | --- |
| Datos personales y de contacto sin atomicidad resuelta | Componentes personales y relación de contactos individualizados | CC-P1-01 |
| Dependencia transitiva potencial de carrera a través de versión | `ADMISION` elimina la copia independiente de carrera y conserva contexto por versión y sede | CC-P1-02 |
| Vigencia y ventanas temporales no descompuestas | `VERSION_PLAN_ESTUDIOS` y `VENTANA_PERIODO` identifican valores atómicos | CC-P1-03 |
| Hechos históricos sin relaciones | Historia de oferta, solicitudes, excepciones y correcciones con su propia identidad | CC-P1-08–11 |
| Cinco relaciones analizadas frente a un modelo declarado provisional | Examen explícito de 26 relaciones y su consolidación | CC-P1-12 |

La normalización no demuestra por sí sola que las reglas transaccionales, de autorización o de concurrencia se ejecuten correctamente. Su cumplimiento corresponde a las pruebas físicas del proyecto final. La comparación con las relaciones originales y el detalle de los atributos está en [Control_de_Cambios.md](../Control_de_Cambios.md), secciones 2 y 4; a continuación se mantiene el análisis corregido de cada relación.

**Criterio de análisis**

Se analizan las 26 relaciones definitivas a partir de las reglas del negocio y de las dependencias funcionales (DF) sustentadas. Para cada relación se identifican determinantes, atributos dependientes y claves candidatas mínimas; se examinan posibles anomalías y se justifica el cumplimiento de 1FN, 2FN, 3FN y BCNF. Las descomposiciones se justifican cuando existe una violación demostrable; los atributos repetibles y los hechos históricos se tratan por su granularidad, sin confundir restricciones temporales o entre relaciones con DF.

### ***GRUPO***

***Hecho representado:*** Una oferta de curso en periodo y sede con cupo, modalidad y estado.

***Relación analizada:*** GRUPO(id\_grupo PK, numero\_grupo NN, codigo\_curso FK NN, id\_periodo FK NN, id\_sede FK NN, capacidad NN, modalidad NN, estado\_oferta NN)

***Reglas relacionadas:*** El grupo relaciona un curso, periodo y sede; el número no es identificador global y el cupo no puede ignorar la ocupación.

***Dependencias funcionales principales:*** id\_grupo → numero\_grupo, codigo\_curso, id\_periodo, id\_sede, capacidad, modalidad, estado\_oferta; (id\_periodo, id\_sede, codigo\_curso, numero\_grupo) → id\_grupo, capacidad, modalidad, estado\_oferta.

***Claves candidatas:*** id\_grupo; (id\_periodo, id\_sede, codigo\_curso, numero\_grupo).

***Anomalías:*** GRUPO no presenta una dependencia interna que obligue a descomponerlo. Si almacenara nombre o créditos del curso, fechas del periodo o nombre de sede, esos datos se repetirían entre ofertas, producirían anomalías de actualización y podrían perderse al borrar la última oferta. Por ello conserva las FKs y sus atributos propios: número, capacidad, modalidad y estado. La clave alternativa (id\_periodo, id\_sede, codigo\_curso, numero\_grupo) identifica cada oferta bajo la unicidad adoptada; ninguna subcombinación se declara única. La limitación del cupo es una restricción operativa, no una DF adicional.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple bajo las DF documentadas. GRUPO: (id\_periodo,id\_sede,codigo\_curso,numero\_grupo) es otra clave candidata solo bajo la política local UQ adoptada y con todos sus campos obligatorios. Quitar periodo, sede, curso o número no preserva la identificación garantizada por la política; el número no es global. La otra clave candidata es id\_grupo.

***3FN:*** se cumple. Los atributos no primos describen la oferta identificada por id\_grupo o por (id\_periodo, id\_sede, codigo\_curso, numero\_grupo). Los datos propios de curso, periodo y sede permanecen en sus relaciones; no se identifica una DF no clave → atributo no primo.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque las DF no triviales identificadas tienen por determinantes id\_grupo y (id\_periodo, id\_sede, codigo\_curso, numero\_grupo), que son claves candidatas.

***Descomposición y justificación:*** GRUPO retiene cupo y estado actuales y HISTORIAL\_OFERTA conserva eventos; SOLICITUD\_MATRICULA retiene la decisión actual e HISTORIAL\_SOLICITUD almacena transiciones y evaluaciones; EXCEPCION\_REQUISITO representa la autorización de una regla; HISTORIAL\_CORRECCION\_CALIFICACION conserva valores anteriores/nuevos con autorización. Estas entidades son necesarias por hechos y multiplicidades del caso. No se pretende que cada tabla histórica haya surgido obligatoriamente de una DF violada en una tabla original.

### ***BLOQUE\_HORARIO***

***Hecho representado:*** Una franja de actividad de un grupo con día, horas y espacio condicional.

***Relación analizada:*** BLOQUE\_HORARIO(id\_bloque PK, id\_grupo FK NN, dia\_semana NN, hora\_inicio NN, hora\_fin NN, es\_presencial NN, id\_espacio FK ?)

***Reglas relacionadas:*** La presencialidad exige espacio de la sede del grupo; el solapamiento temporal se valida entre bloques, no por DF.

***Dependencia funcional principal:*** id\_bloque → id\_grupo, dia\_semana, hora\_inicio, hora\_fin, es\_presencial, id\_espacio.

***Claves candidatas:*** id\_bloque.

***Anomalías:*** Repetir capacidad, ubicación y sede del espacio en cada bloque obligaría a modificar varios registros al actualizar ese espacio y podría perder esos datos al eliminar su último bloque. La relación conserva solo la referencia a ESPACIO; día, horas y presencialidad corresponden al bloque, sin duplicar GRUPO.modalidad. Los conflictos de asignación se verifican por coincidencia de fechas lectivas, día e intervalos horarios, incluso entre periodos distintos; esta regla entre filas no constituye una DF que exija descomponer BLOQUE\_HORARIO.

***1FN:*** se cumple. Cada fila corresponde a un día e intervalo de horas, sin almacenar colecciones.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. Día, horas, presencialidad y espacio dependen de id\_bloque; la capacidad y la sede propias del espacio no se duplican en el bloque. Ningún atributo no primo determina otro según las reglas documentadas.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_bloque, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***SOLICITUD\_MATRICULA***

***Hecho representado:*** Una solicitud de grupo por admisión y versión evaluada con estado, historia y resultado.

***Relación analizada:*** SOLICITUD\_MATRICULA(id\_solicitud PK, id\_admision FK NN, id\_grupo FK NN, id\_solicitud\_anterior FK ?, id\_version\_plan\_evaluada FK NN, fecha\_solicitud NN, estado NN, razon\_rechazo\_espera ?, orden\_espera ?, momento\_transicion ?, calificacion ?, resultado\_academico ?)

***Reglas relacionadas:*** Estados y transiciones condicionan razones, espera y resultados; un cambio mantiene el vínculo con su solicitud de origen.

***Dependencia funcional principal:*** id\_solicitud → id\_admision, id\_grupo, id\_solicitud\_anterior, id\_version\_plan\_evaluada, fecha\_solicitud, estado, razon\_rechazo\_espera, orden\_espera, momento\_transicion, calificacion, resultado\_academico.

***Claves candidatas:*** id\_solicitud.

***Anomalías:*** Repetir atributos propios de ADMISION o GRUPO en cada solicitud provocaría inconsistencias al modificarlos, mientras acumular eventos en la misma fila impediría conservar todas las transiciones sin sobrescribir información. SOLICITUD\_MATRICULA almacena las referencias y los datos de una solicitud; HISTORIAL\_SOLICITUD representa cada evento. id\_solicitud\_anterior vincula un cambio con una solicitud matriculada de la misma admisión, curso y periodo, pero con grupo distinto, y la versión evaluada permanece histórica tras un traslado. Estado no determina una nota, motivo u orden concreto; estas condiciones no implican una DF transitiva interna.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. Estado, razón, orden de espera y resultado describen una solicitud identificada por id\_solicitud. El estado no determina por sí solo los otros valores; curso y periodo del grupo se obtienen por referencia y no se duplican.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_solicitud, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***GRUPO\_DOCENTE***

***Hecho representado:*** La participación de un docente en un grupo con rol responsable o adicional.

***Relación analizada:*** GRUPO\_DOCENTE(id\_grupo PK/FK, id\_docente PK/FK, rol NN)

***Reglas relacionadas:*** Se permite M:N y se garantiza exactamente un responsable por grupo publicado.

***Dependencia funcional principal:*** (id\_grupo, id\_docente) → rol.

***Claves candidatas:*** (id\_grupo, id\_docente).

***Anomalías:*** Guardar docentes o roles como listas en GRUPO produciría grupos repetitivos y dificultaría insertar o retirar participaciones; duplicar datos de DOCENTE en cada grupo causaría anomalías de actualización. GRUPO\_DOCENTE representa una participación por pareja (id\_grupo, id\_docente), que determina rol. Cada grupo y cada docente pueden intervenir en varias parejas, por lo que ningún componente es clave por sí solo. La exigencia de exactamente un responsable para un grupo publicado es una restricción entre filas, no una DF id\_grupo → rol aplicable a toda la relación.

***1FN:*** se cumple. Cada fila corresponde a una sola pareja grupo–docente y rol.

***2FN:*** se cumple bajo las DF documentadas. GRUPO\_DOCENTE (id\_grupo,id\_docente): sin docente, un grupo puede contar con varios participantes; sin grupo, un docente puede participar en varios grupos. Solo la pareja determina rol. «Exactamente un responsable» es condición filtrada de existencia/unicidad entre filas y no convierte id\_grupo en clave del conjunto completo de participaciones.

***3FN:*** se cumple. El único atributo no primo, rol, depende de la pareja (id\_grupo, id\_docente). La regla de un responsable por grupo publicado no constituye una DF id\_grupo → rol sobre todas las participaciones.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante (id\_grupo, id\_docente), una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***PERIODO\_ACADEMICO***

***Hecho representado:*** Un periodo con código único y fechas lectivas de inicio y finalización.

***Relación analizada:*** PERIODO\_ACADEMICO(id\_periodo PK, codigo\_periodo UQ NN, fecha\_inicio NN, fecha\_finalizacion NN)

***Reglas relacionadas:*** Las ventanas pueden repetirse y se almacenan por separado; el código del periodo constituye clave alternativa.

***Dependencias funcionales principales:*** id\_periodo → codigo\_periodo, fecha\_inicio, fecha\_finalizacion; codigo\_periodo → id\_periodo, fecha\_inicio, fecha\_finalizacion.

***Claves candidatas:*** id\_periodo; codigo\_periodo.

***Anomalías:*** Almacenar varias ventanas en columnas repetidas del periodo dificultaría añadir o retirar ventanas y permitiría inconsistencias entre intervalos. VENTANA\_PERIODO representa una ocurrencia por fila; PERIODO\_ACADEMICO conserva exclusivamente el código único y las fechas lectivas. Tanto id\_periodo como codigo\_periodo son claves candidatas no nulas que determinan esas fechas. La separación de las ventanas resuelve su multiplicidad, sin atribuirles una DF interna al periodo.

***1FN:*** se cumple. Código y fechas son escalares; cada ventana repetible tiene una relación distinta.

***2FN:*** se cumple. Las dos claves candidatas, id\_periodo y codigo\_periodo, tienen un solo atributo; por tanto, ningún atributo no primo depende parcialmente de una clave compuesta.

***3FN:*** se cumple. id\_periodo y codigo\_periodo son claves candidatas simples que determinan las fechas lectivas; las ventanas repetibles se representan en VENTANA\_PERIODO. No se mantiene una DF transitiva entre atributos no primos.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque las DF no triviales identificadas tienen por determinantes id\_periodo y codigo\_periodo, que son claves candidatas.

***Descomposición y justificación:*** El esquema original contenía «fechas\_matricula\_ordinaria» y «fechas\_modificaciones» con cardinalidad indefinida. Para admitir múltiples ventanas y registrar retiros, PERIODO\_ACADEMICO guarda código y fechas lectivas; VENTANA\_PERIODO almacena cada intervalo, tipo y FK al periodo. Una ventana es una tupla; dos ventanas son dos tuplas, nunca una lista en un atributo. No se declara que separar ventanas sea la descomposición de una DF concreta demostrada: es resolución de granularidad/multivaluación y del ciclo de vida de los intervalos.

### ***ESTUDIANTE***

***Hecho representado:*** Una persona identificada por su número institucional y datos personales atómicos.

***Relación analizada:*** ESTUDIANTE(numero\_institucional PK, nombre NN, primer\_apellido NN, segundo\_apellido ?)

***Reglas relacionadas:*** Las múltiples admisiones y contactos se separan de los datos personales.

***Dependencia funcional principal:*** numero\_institucional → nombre, primer\_apellido, segundo\_apellido.

***Claves candidatas:*** numero\_institucional.

***Anomalías:*** Incorporar contactos repetibles o admisiones dentro de ESTUDIANTE obligaría a repetir datos personales y podría provocar inconsistencias al actualizarlos, además de dificultar el alta y la baja de esas ocurrencias. ESTUDIANTE mantiene nombre y apellidos atómicos bajo numero\_institucional; CONTACTO\_ESTUDIANTE y ADMISION representan por separado los hechos múltiples, sin perder la identidad del estudiante.

***1FN:*** se cumple. Nombres y apellidos son valores simples; los contactos repetibles no se agrupan en listas.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. Los componentes personales dependen de numero\_institucional; carrera, admisiones y contactos repetibles no forman parte de esta relación, de modo que no introducen determinantes no clave.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante numero\_institucional, una clave candidata.

***Descomposición y justificación:*** El esquema del Proyecto 1 agrupaba «datos\_personales» y «datos\_contacto» sin especificar componentes ni multiplicidad; no podía declararse su 1FN solo a partir de esos nombres. Se conservan número institucional y componentes atómicos de nombre/apellidos en ESTUDIANTE, mientras CONTACTO\_ESTUDIANTE representa una ocurrencia por tipo y valor. Se evita repetir un correo principal tanto en ESTUDIANTE como en CONTACTO\_ESTUDIANTE. La transformación responde a la semántica de contactos repetibles; no se atribuye a una DF inventada.

### ***ADMISION***

***Hecho representado:*** La vinculación de un estudiante, sede y versión de plan.

***Relación analizada:*** ADMISION(id\_admision PK, numero\_institucional FK NN, id\_sede FK NN, id\_version\_plan FK NN, fecha\_ingreso NN, condicion\_academica NN, activa NN)

***Reglas relacionadas:*** La carrera deriva de la versión del plan; las diferentes admisiones no se confunden.

***Dependencia funcional principal:*** id\_admision → numero\_institucional, id\_sede, id\_version\_plan, fecha\_ingreso, condicion\_academica, activa.

***Claves candidatas:*** id\_admision.

***Anomalías:*** La versión asignada no permite inferir una única sede ni estudiante. Eliminado id\_carrera, que era derivable de id\_version\_plan por VERSION\_PLAN\_ESTUDIOS y generaba redundancia transitiva en la admisión. condicion\_academica y activa se consideran conceptos distintos, no una FD entre ellos, hasta que una norma disponga equivalencia.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple después de retirar id\_carrera, que era derivable de id\_version\_plan. Los datos propios de la admisión dependen de id\_admision y la carrera se consulta mediante VERSION\_PLAN\_ESTUDIOS.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_admision, una clave candidata.

***Descomposición y justificación:*** En la versión inicial se almacenaban tanto ADMISION.id\_version\_plan como ADMISION.id\_carrera. Las reglas de versión implican id\_version\_plan → id\_carrera y la identidad de admisión implica id\_admision → id\_version\_plan; así id\_admision → id\_version\_plan → id\_carrera. Dado que id\_version\_plan no es superclave de ADMISION y que id\_carrera no era atributo primo de ADMISION, ese almacenamiento generaba dependencia transitiva y anomalías al cambiar el plan. La relación vigente elimina ADMISION.id\_carrera. Se recupera la carrera mediante VERSION\_PLAN\_ESTUDIOS y se valida que la sede de admisión esté habilitada para esa carrera.

### ***CARRERA***

***Hecho representado:*** Un programa académico identificado independientemente.

***Relación analizada:*** CARRERA(id\_carrera PK)

***Reglas relacionadas:*** Las versiones y sedes de oferta son asociaciones externas a CARRERA.

***Dependencias funcionales:*** no existen DF no triviales entre atributos distintos; todos los atributos pertenecen a la clave primaria.

***Claves candidatas:*** id\_carrera.

***Anomalías:*** CARRERA solo contiene id\_carrera, de modo que no presenta anomalías internas de actualización por dependencias parciales o transitivas. Registrar las sedes o versiones como listas dentro de la carrera introduciría grupos repetitivos y dificultaría el mantenimiento de esas asociaciones; CARRERA\_SEDE y VERSION\_PLAN\_ESTUDIOS las representan por separado.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple trivialmente; CARRERA contiene solo id\_carrera, sin atributos no primos que puedan presentar una dependencia transitiva.

***BCNF:*** se cumple trivialmente porque no existen DF no triviales entre atributos distintos en la relación.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***SEDE***

***Hecho representado:*** Una sede con identificador y nombre propios.

***Relación analizada:*** SEDE(id\_sede PK, nombre NN)

***Reglas relacionadas:*** Su nombre no es único por suposición y sus carreras y espacios se asocian aparte.

***Dependencia funcional principal:*** id\_sede → nombre.

***Claves candidatas:*** id\_sede.

***Anomalías:*** nombre depende de id\_sede y no se declara único sin una regla de negocio que lo sustente. En SEDE no se identifica una dependencia no clave que obligue a descomponer. Repetir el nombre en cada grupo o espacio produciría anomalías de actualización; por ello las ofertas y los espacios conservan únicamente la referencia a la sede.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. nombre depende de id\_sede y no se documenta otra dependencia entre atributos no clave.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_sede, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***VERSION\_PLAN\_ESTUDIOS***

***Hecho representado:*** Una versión del plan de una carrera con vigencia temporal.

***Relación analizada:*** VERSION\_PLAN\_ESTUDIOS(id\_version\_plan PK, id\_carrera FK NN, inicio\_vigencia NN, fin\_vigencia ?)

***Reglas relacionadas:*** Inicio y fin de vigencia tienen significado temporal; no se afirma una clave alternativa no prevista.

***Dependencia funcional principal:*** id\_version\_plan → id\_carrera, inicio\_vigencia, fin\_vigencia.

***Claves candidatas:*** id\_version\_plan.

***Anomalías:*** Duplicar atributos propios de CARRERA en todas sus versiones obligaría a actualizar varias filas al modificarlos. VERSION\_PLAN\_ESTUDIOS conserva id\_carrera como FK y sus propios límites de vigencia, determinados por id\_version\_plan. Ni inicio\_vigencia por sí solo ni (id\_carrera, inicio\_vigencia) se declaran claves candidatas sin una regla que garantice su unicidad; no se identifica otra DF interna que exija descomposición.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_version\_plan determina id\_carrera y los límites de vigencia; los atributos descriptivos de CARRERA no se replican en la versión.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_version\_plan, una clave candidata.

***Descomposición y justificación:*** En Lab03, vigencia se representaba mediante TEXT. Una cadena de texto no viola necesariamente 1FN si es un valor escalar; el defecto concreto era no expresar dos límites temporales con significado y validación suficiente para los procesos del Proyecto 2\. Se adoptaron inicio\_vigencia y fin\_vigencia (opcional para vigencia abierta), con regla fin \>= inicio cuando esté presente. Se conserva id\_carrera → CARRERA mediante FK; esta conversión exige una migración controlada de los datos semilla de Lab03.

### ***CURSO***

***Hecho representado:*** Un curso con código institucional, nombre, créditos y escuela.

***Relación analizada:*** CURSO(codigo\_institucional PK, nombre NN, cantidad\_creditos NN, id\_escuela FK NN)

***Reglas relacionadas:*** La escuela administradora se referencia mediante FK y la participación curricular depende de la versión.

***Dependencia funcional principal:*** codigo\_institucional → nombre, cantidad\_creditos, id\_escuela.

***Claves candidatas:*** codigo\_institucional.

***Anomalías:*** Repetir datos descriptivos de ESCUELA en cada CURSO provocaría inconsistencias cuando cambien, mientras almacenar las participaciones en planes como columnas o listas impediría representarlas sin grupos repetitivos. CURSO conserva id\_escuela como FK y atributos determinados por codigo\_institucional; PARTICIPACION\_PLAN expresa separadamente cada participación curso–versión.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. nombre, cantidad\_creditos e id\_escuela dependen de codigo\_institucional; los datos de ESCUELA no se incorporan a CURSO y no hay dependencia transitiva interna sustentada.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante codigo\_institucional, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***ESCUELA***

***Hecho representado:*** La identidad de una escuela administradora.

***Relación analizada:*** ESCUELA(id\_escuela PK)

***Reglas relacionadas:*** Una escuela puede administrar cero o más cursos.

***Dependencias funcionales:*** no existen DF no triviales entre atributos distintos; todos los atributos pertenecen a la clave primaria.

***Claves candidatas:*** id\_escuela.

***Anomalías:*** ESCUELA solo contiene id\_escuela, sin atributos no primos que puedan causar anomalías por dependencias parciales o transitivas. Los cursos administrados se representan mediante CURSO.id\_escuela, no como una lista dentro de ESCUELA; una escuela puede administrar cero o más cursos.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple trivialmente; la relación solo contiene id\_escuela, sin atributos no primos.

***BCNF:*** se cumple trivialmente porque no existen DF no triviales entre atributos distintos en la relación.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***ESPACIO***

***Hecho representado:*** Un espacio físico con sede, capacidad y ubicación.

***Relación analizada:*** ESPACIO(id\_espacio PK, id\_sede FK NN, capacidad NN, ubicacion NN)

***Reglas relacionadas:*** Los bloques referencian espacios; las coincidencias temporales no son DF.

***Dependencia funcional principal:*** id\_espacio → id\_sede, capacidad, ubicacion.

***Claves candidatas:*** id\_espacio.

***Anomalías:*** Si capacidad, ubicación y sede se copiaran en cada BLOQUE\_HORARIO, cualquier modificación de esos datos exigiría actualizar múltiples franjas y la eliminación de la última reserva podría hacer perder la descripción del espacio. ESPACIO concentra esos atributos bajo id\_espacio; los bloques conservan la FK. Los conflictos de asignación corresponden a una restricción temporal entre filas, no a una DF interna.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_espacio determina sede, capacidad y ubicación; la información propia de la sede permanece en SEDE y no hay DF adicional entre atributos no primos documentada.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_espacio, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***DOCENTE***

***Hecho representado:*** Una persona docente identificable.

***Relación analizada:*** DOCENTE(id\_docente PK, nombre NN)

***Reglas relacionadas:*** La pertenencia a grupos y el rol son hechos de GRUPO\_DOCENTE.

***Dependencia funcional principal:*** id\_docente → nombre.

***Claves candidatas:*** id\_docente.

***Anomalías:*** Almacenar grupos y roles como una lista en DOCENTE dificultaría insertar o eliminar participaciones y no reflejaría correctamente la asociación M:N. DOCENTE conserva su identidad y nombre; GRUPO\_DOCENTE registra cada pareja grupo–docente con su rol. No hay una dependencia interna no clave que requiera otra descomposición.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. nombre depende de id\_docente; los roles se almacenan en GRUPO\_DOCENTE y no se introduce otra dependencia funcional en DOCENTE.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_docente, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***CONTACTO\_ESTUDIANTE***

***Hecho representado:*** Una ocurrencia de contacto para un estudiante.

***Relación analizada:*** CONTACTO\_ESTUDIANTE(id\_contacto PK, numero\_institucional FK NN, tipo\_contacto NN, valor NN, es\_principal NN)

***Reglas relacionadas:*** Puede haber contactos múltiples, pero no se repite la pareja estudiante–tipo–valor.

***Dependencias funcionales principales:*** id\_contacto → numero\_institucional, tipo\_contacto, valor, es\_principal; (numero\_institucional, tipo\_contacto, valor) → id\_contacto, es\_principal.

***Claves candidatas:*** id\_contacto; (numero\_institucional, tipo\_contacto, valor).

***Anomalías:*** Repetir la misma combinación (numero\_institucional, tipo\_contacto, valor) produciría contactos duplicados y posibles inconsistencias en la marca es\_principal; la clave alternativa impide esa duplicación. es\_principal depende de la ocurrencia identificada por id\_contacto o por la terna única. La restricción de un principal por estudiante y tipo no implica (numero\_institucional, tipo\_contacto) → valor en toda la relación, porque pueden existir contactos adicionales.

***1FN:*** se cumple. Cada fila representa un único tipo y valor de contacto.

***2FN:*** se cumple bajo las DF documentadas. CONTACTO\_ESTUDIANTE: la combinación (numero\_institucional,tipo\_contacto,valor) es una clave candidata alternativa porque está restringida a ocurrencias únicas y todas sus componentes son obligatorias. La PK id\_contacto también identifica la ocurrencia. No hay dependencia demostrada tipo\_contacto → valor ni (numero\_institucional,tipo\_contacto) → valor.

***3FN:*** se cumple. id\_contacto y (numero\_institucional, tipo\_contacto, valor) son claves candidatas. es\_principal corresponde a esa ocurrencia; los datos personales del estudiante no se replican.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque las DF no triviales identificadas tienen por determinantes id\_contacto y (numero\_institucional, tipo\_contacto, valor), que son claves candidatas.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***CARRERA\_SEDE***

***Hecho representado:*** Una habilitación de oferta de carrera en una sede.

***Relación analizada:*** CARRERA\_SEDE(id\_carrera PK/FK, id\_sede PK/FK)

***Reglas relacionadas:*** La asociación M:N se identifica por ambos participantes.

***Dependencias funcionales:*** no existen DF no triviales entre atributos distintos; todos los atributos pertenecen a la clave primaria.

***Claves candidatas:*** (id\_carrera, id\_sede).

***Anomalías:*** Almacenar sedes como lista en CARRERA o carreras como lista en SEDE introduciría grupos repetitivos y complicaría la inserción y eliminación de ofertas. CARRERA\_SEDE representa una combinación por fila y conserva la multiplicidad M:N. Ningún componente identifica por sí solo la asociación; como ambos forman su clave candidata, no hay atributos no primos ni una dependencia interna que exija descomposición.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple bajo las DF documentadas. CARRERA\_SEDE (id\_carrera,id\_sede): retirar id\_carrera deja una sede con múltiples carreras; retirar id\_sede deja una carrera presente en varias sedes. Ninguna componente identifica una asociación; ambos valores son primos, sin atributo no clave.

***3FN:*** se cumple trivialmente. Los dos atributos forman la clave candidata compuesta y no existen atributos no primos susceptibles de dependencia transitiva.

***BCNF:*** se cumple trivialmente porque no existen DF no triviales entre atributos distintos en la relación.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***PARTICIPACION\_PLAN***

***Hecho representado:*** La participación de un curso en una versión del plan.

***Relación analizada:*** PARTICIPACION\_PLAN(codigo\_curso PK/FK, id\_version\_plan PK/FK, tipo\_participacion NN, nivel\_o\_periodo\_recomendado ?)

***Reglas relacionadas:*** Una pareja curso–versión determina tipo de participación y nivel recomendado.

***Dependencia funcional principal:*** (codigo\_curso, id\_version\_plan) → tipo\_participacion, nivel\_o\_periodo\_recomendado.

***Claves candidatas:*** (codigo\_curso, id\_version\_plan).

***Anomalías:*** Colocar tipo\_participacion o nivel\_o\_periodo\_recomendado en CURSO o VERSION\_PLAN\_ESTUDIOS obligaría a repetir valores propios de cada pareja y produciría inconsistencias entre versiones. PARTICIPACION\_PLAN representa una participación por (codigo\_curso, id\_version\_plan), única combinación que determina esos atributos; ninguna parte de la clave lo hace por sí sola. El nivel recomendado conserva su representación textual opcional sin introducir una DF adicional.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple bajo las DF documentadas. PARTICIPACION\_PLAN (codigo\_curso,id\_version\_plan): el cierre de {codigo\_curso} no identifica una versión específica y el de {id\_version\_plan} no identifica un curso particular, porque el caso admite participación M:N. Solo la pareja determina tipo\_participacion y nivel\_o\_periodo\_recomendado. Por ello no hay dependencia parcial de atributos no primos.

***3FN:*** se cumple. tipo\_participacion y nivel\_o\_periodo\_recomendado dependen de la pareja (codigo\_curso, id\_version\_plan), sin almacenar atributos propios de CURSO o VERSION\_PLAN\_ESTUDIOS.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante (codigo\_curso, id\_version\_plan), una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***REQUISITO\_CURSO***

***Hecho representado:*** Una regla curricular para un curso objetivo en una versión.

***Relación analizada:*** REQUISITO\_CURSO(id\_version\_plan PK/FK, codigo\_curso\_objetivo PK/FK, codigo\_curso\_exigido PK/FK, tipo\_requisito PK, id\_requisito UQ NN)

***Reglas relacionadas:*** La PK de cuatro campos se conserva; id\_requisito UQ NN permite autorizar excepciones.

***Dependencias funcionales principales:*** (id\_version\_plan, codigo\_curso\_objetivo, codigo\_curso\_exigido, tipo\_requisito) → id\_requisito; id\_requisito → id\_version\_plan, codigo\_curso\_objetivo, codigo\_curso\_exigido, tipo\_requisito.

***Claves candidatas:*** (id\_version\_plan, codigo\_curso\_objetivo, codigo\_curso\_exigido, tipo\_requisito); id\_requisito.

***Anomalías:*** La PK compuesta de Lab03 sigue siendo mínima bajo el supuesto explícito de reglas distinguidas por versión, objetivo, exigido y tipo; no se presupone que un mismo par de cursos jamás pueda tener tipos distintos. El nuevo id\_requisito, único y no nulo, es clave candidata alternativa de la MISMA relación; ambas claves determinan todos los atributos. No se impone pertenencia de objetivo/exigido a PARTICIPACION\_PLAN por una restricción no establecida en el caso. La prueba P07 de Lab03 no demuestra esa condición: su objetivo UH-EST1 sí aparece como optativo en la versión 201 de la semilla. La prueba confirma una inserción válida de REQUISITO\_CURSO, no la aceptación de un curso objetivo externo al plan.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple bajo las DF documentadas. REQUISITO\_CURSO (id\_version\_plan,codigo\_curso\_objetivo,codigo\_curso\_exigido,tipo\_requisito): la identidad natural de la regla se define por los cuatro componentes. Quitar versión mezcla normas de versiones distintas; quitar objetivo mezcla exigencias para cursos diferentes; quitar exigido mezcla cursos requeridos diferentes; quitar tipo mezcla requisito previo con correquisito, permitidos como categorías distintas en el esquema. No se afirma que el negocio requiera ambos tipos simultáneos para un mismo par: es un supuesto de granularidad que preserva la PK ya utilizada en Lab03. El identificador alternativo id\_requisito (UQ NN) determina la cuaterna; la cuaterna también determina id\_requisito, por su unicidad. Toda DF no trivial aquí indicada tiene determinante clave candidata.

***3FN:*** se cumple. La cuaterna de regla y el identificador alternativo id\_requisito son claves candidatas mutuamente determinantes; no existe un atributo no primo determinado por una no superclave.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque las DF no triviales identificadas tienen por determinantes (id\_version\_plan, codigo\_curso\_objetivo, codigo\_curso\_exigido, tipo\_requisito) y id\_requisito, que son claves candidatas.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***TRASLADO\_PLAN***

***Hecho representado:*** Un cambio histórico de versión de una admisión.

***Relación analizada:*** TRASLADO\_PLAN(id\_traslado PK, id\_admision FK NN, id\_version\_origen FK NN, id\_version\_destino FK NN, fecha NN, motivo NN, id\_autorizador FK NN)

***Reglas relacionadas:*** Origen, destino, instante, motivo y autorizante son propiedades del traslado, no de la admisión actual.

***Dependencia funcional principal:*** id\_traslado → id\_admision, id\_version\_origen, id\_version\_destino, fecha, motivo, id\_autorizador.

***Claves candidatas:*** id\_traslado.

***Anomalías:*** Un mismo id\_admision puede presentar varios traslados. Origen, destino, instante, motivo y autorizante son propiedades del evento, no dependencias de la admisión actual. La regla de secuencia y misma carrera es temporal e interrelacional, no una dependencia funcional entre atributos de esta fila.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_traslado identifica cada evento; una misma admisión puede tener varios traslados, por lo que id\_admision no determina origen, destino ni motivo de un traslado individual.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_traslado, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***RECONOCIMIENTO\_ACADEMICO***

***Hecho representado:*** Una resolución que satisface un curso en una versión por reconocimiento.

***Relación analizada:*** RECONOCIMIENTO\_ACADEMICO(id\_reconocimiento PK, id\_admision FK NN, referencia\_curso\_reconocido ?, codigo\_curso\_reconocido FK ?, id\_version\_plan FK NN, codigo\_curso\_satisfecho FK NN, resolucion\_academica NN, fecha\_resolucion NN)

***Reglas relacionadas:*** El origen es institucional o externo, excluyentemente, y el contexto del curso satisfecho debe ser coherente.

***Dependencia funcional principal:*** id\_reconocimiento → id\_admision, referencia\_curso\_reconocido, codigo\_curso\_reconocido, id\_version\_plan, codigo\_curso\_satisfecho, resolucion\_academica, fecha\_resolucion.

***Claves candidatas:*** id\_reconocimiento.

***Anomalías:*** Una admisión puede contar con varios reconocimientos y un curso satisfecho puede figurar en distintas resoluciones; ninguno es una clave candidata por sí solo. La resolución distingue el curso reconocido institucional, mediante codigo\_curso\_reconocido FK, del curso externo, mediante referencia\_curso\_reconocido textual, con exclusión mutua entre ambos. La versión se fija en el instante de la resolución: no se deriva del plan actual de ADMISION después de un traslado. La FK compuesta al curso participante fija el contexto del curso satisfecho por reconocimiento sin restringir la existencia de cursos objetivo o exigidos externos a PARTICIPACION\_PLAN dentro de REQUISITO\_CURSO. Un requisito externo a la participación puede acreditarse mediante aprobación previa; el esquema no establece una prohibición general de requisitos externos por esa circunstancia. No se presupone unicidad de resolucion\_academica, pues el enunciado no establece un código único.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. Los atributos describen una resolución identificada por id\_reconocimiento; ni id\_admision ni codigo\_curso\_satisfecho determinan por sí mismos una resolución. Los datos del curso y la versión se mantienen por referencias.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_reconocimiento, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***PERSONA\_AUTORIZADORA***

***Hecho representado:*** Una identidad institucional de autorizante.

***Relación analizada:*** PERSONA\_AUTORIZADORA(id\_autorizador PK, nombre NN, identificacion\_institucional UQ NN)

***Reglas relacionadas:*** La identificación institucional es única; no se asume que todo autorizante sea DOCENTE.

***Dependencias funcionales principales:*** id\_autorizador → nombre, identificacion\_institucional; identificacion\_institucional → id\_autorizador, nombre.

***Claves candidatas:*** id\_autorizador; identificacion\_institucional.

***Anomalías:*** Ambos identificadores son obligatorios y únicos: cada uno determina el resto. No se presupone dependencia que convierta a todo autorizante en DOCENTE ni roles de una jerarquía institucional inexistente en el caso.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple. Tanto id\_autorizador como identificacion\_institucional son claves candidatas simples, de modo que no existen dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_autorizador e identificacion\_institucional son claves candidatas simples y determinan nombre; no se sustenta una dependencia desde otro atributo no clave.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque las DF no triviales identificadas tienen por determinantes id\_autorizador y identificacion\_institucional, que son claves candidatas.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***VENTANA\_PERIODO***

***Hecho representado:*** Un intervalo autorizado de un tipo en un periodo.

***Relación analizada:*** VENTANA\_PERIODO(id\_ventana PK, id\_periodo FK NN, tipo\_ventana NN, inicio NN, fin NN)

***Reglas relacionadas:*** Pueden coexistir varias ventanas del mismo tipo, con intervalos verificables.

***Dependencia funcional principal:*** id\_ventana → id\_periodo, tipo\_ventana, inicio, fin.

***Claves candidatas:*** id\_ventana.

***Anomalías:*** Guardar varios intervalos como columnas del periodo o limitar la relación a una ventana por tipo impediría representar todas las ventanas autorizadas y complicaría su inserción o modificación. VENTANA\_PERIODO registra un intervalo por fila; (id\_periodo, tipo\_ventana) no es clave porque puede repetirse. El control de superposiciones temporales se verifica entre filas y no constituye una DF que obligue a descomponer.

***1FN:*** se cumple. Cada intervalo ocupa una fila con inicio y fin atómicos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_ventana determina periodo, tipo y límites temporales; (id\_periodo, tipo\_ventana) no determina una ventana única y no existe dependencia transitiva interna documentada.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_ventana, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***HISTORIAL\_OFERTA***

***Hecho representado:*** Un evento de modificación de la oferta de un grupo.

***Relación analizada:*** HISTORIAL\_OFERTA(id\_cambio PK, id\_grupo FK NN, tipo\_cambio NN, estado\_anterior ?, estado\_nuevo ?, cupo\_anterior ?, cupo\_nuevo ?, fecha\_cambio NN, motivo NN, id\_responsable FK NN)

***Reglas relacionadas:*** Los eventos se conservan sin sobrescribir los atributos actuales de GRUPO.

***Dependencia funcional principal:*** id\_cambio → id\_grupo, tipo\_cambio, estado\_anterior, estado\_nuevo, cupo\_anterior, cupo\_nuevo, fecha\_cambio, motivo, id\_responsable.

***Claves candidatas:*** id\_cambio.

***Anomalías:*** Múltiples eventos pueden afectar un grupo. Tipo de cambio limita qué valores deben estar presentes, pero tipo\_cambio no determina valores concretos anterior/nuevo. Los eventos tienen identidad y ciclo de vida distintos del estado actual de GRUPO; su separación se debe a multiplicidad e historia, no a una FD ficticia.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. Cada evento se identifica por id\_cambio; tipo\_cambio no determina los estados ni cupos anteriores o nuevos, que corresponden a esa ocurrencia histórica.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_cambio, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***HISTORIAL\_SOLICITUD***

***Hecho representado:*** Un evento de transición o evaluación de solicitud.

***Relación analizada:*** HISTORIAL\_SOLICITUD(id\_evento PK, id\_solicitud FK NN, tipo\_evento NN, estado\_anterior ?, estado\_nuevo ?, fecha\_evento NN, motivo ?, id\_actor FK ?)

***Reglas relacionadas:*** Una solicitud puede producir varios eventos, incluso evaluaciones sin cambio de estado.

***Dependencia funcional principal:*** id\_evento → id\_solicitud, tipo\_evento, estado\_anterior, estado\_nuevo, fecha\_evento, motivo, id\_actor.

***Claves candidatas:*** id\_evento.

***Anomalías:*** Muchos eventos corresponden a una solicitud, incluidos intentos de promoción sin transición. estado\_anterior/estado\_nuevo reflejan cada evento y no son determinados únicamente por tipo\_evento. La separación conserva secuencia y justificación sin sustituir el estado actual de SOLICITUD\_MATRICULA.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_evento determina la información de cada transición o evaluación; tipo\_evento no determina por sí solo estados, motivo o actor, por lo que no introduce una dependencia transitiva.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_evento, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***EXCEPCION\_REQUISITO***

***Hecho representado:*** Una autorización de excepción a una regla curricular para una solicitud.

***Relación analizada:*** EXCEPCION\_REQUISITO(id\_excepcion PK, id\_solicitud FK NN, id\_requisito FK NN, id\_autorizador FK NN, fecha\_autorizacion NN, motivo NN)

***Reglas relacionadas:*** No se duplican datos de versión y curso objetivo determinados por la solicitud y la regla.

***Dependencia funcional principal:*** id\_excepcion → id\_solicitud, id\_requisito, id\_autorizador, fecha\_autorizacion, motivo.

***Claves candidatas:*** id\_excepcion.

***Anomalías:*** Cada autorización tiene identidad, solicitud, regla y autorizante. No se vuelven a almacenar id\_version\_plan ni codigo\_curso\_objetivo de la solicitud. La regla se referencia por id\_requisito, clave alternativa única en REQUISITO\_CURSO. Así id\_solicitud puede determinar su propio contexto sin provocar una dependencia no superclave dentro de EXCEPCION\_REQUISITO. Validar coincidencia solicitud/regla sigue siendo una restricción de integridad entre relaciones.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. La excepción solo conserva id\_solicitud e id\_requisito como referencias: el contexto curricular derivable de esas relaciones no se duplica. Todos los atributos propios de la autorización dependen de id\_excepcion.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_excepcion, una clave candidata.

***Descomposición y justificación:*** El contexto curricular de una excepción se determina desde SOLICITUD\_MATRICULA: id\_solicitud determina la versión evaluada y, por medio de GRUPO, el curso objetivo. Repetir id\_version\_plan y codigo\_curso\_objetivo dentro de cada excepción introduciría dependencias derivadas de id\_solicitud, que no es superclave cuando una solicitud posee varias excepciones, y permitiría anomalías de actualización. El esquema vigente conserva id\_solicitud e id\_requisito como FKs, junto con el autorizante, la fecha y el motivo. REQUISITO\_CURSO mantiene su PK compuesta de Lab03 y agrega id\_requisito UNIQUE NOT NULL generado por defecto como clave candidata alternativa. La regla completa se recupera mediante la unión con REQUISITO\_CURSO y se valida su correspondencia con la versión y el curso de la solicitud. Se preservan la firma de sp\_agregar\_curso\_plan y los INSERT de cuatro columnas de Lab03.

### ***HISTORIAL\_CORRECCION\_CALIFICACION***

***Hecho representado:*** Un evento de corrección autorizada de calificación o resultado.

***Relación analizada:*** HISTORIAL\_CORRECCION\_CALIFICACION(id\_correccion PK, id\_solicitud FK NN, calificacion\_anterior ?, calificacion\_nueva ?, resultado\_anterior ?, resultado\_nuevo ?, fecha\_correccion NN, motivo NN, id\_autorizador FK NN)

***Reglas relacionadas:*** La solicitud puede tener numerosas correcciones históricas, cada una con hechos anterior/nuevo.

***Dependencia funcional principal:*** id\_correccion → id\_solicitud, calificacion\_anterior, calificacion\_nueva, resultado\_anterior, resultado\_nuevo, fecha\_correccion, motivo, id\_autorizador.

***Claves candidatas:*** id\_correccion.

***Anomalías:*** Cada corrección tiene identidad y registra los valores anterior/nuevo pertinentes, instante, razón y autorizante. Una solicitud puede tener varias correcciones; id\_solicitud no determina una corrección única. Ni el estado ni la calificación anterior determinan una calificación nueva específica.

***1FN:*** se cumple. Cada atributo almacena un valor escalar del hecho correspondiente, sin grupos repetitivos.

***2FN:*** se cumple porque la clave candidata documentada es simple; no hay dependencias parciales de atributos no primos.

***3FN:*** se cumple. id\_correccion identifica cada cambio, mientras id\_solicitud puede corresponder a varios eventos y una nota anterior no determina necesariamente la nueva; no se identifican DF de no superclave a atributos no primos.

***BCNF:*** se cumple conforme a las dependencias sustentadas, porque la DF no trivial identificada tiene por determinante id\_correccion, una clave candidata.

***Descomposición:*** no requerida por dependencia funcional demostrada.

### ***Reunión sin pérdida***

La eliminación de atributos redundantes se evalúa por la posibilidad de recuperar su información mediante las referencias existentes. Las nuevas relaciones de contactos, ventanas e historiales responden a multiplicidades o hechos independientes; no se presentan como descomposiciones ocasionadas por DF inexistentes.

ADMISION almacenaba id\_carrera además de id\_version\_plan. En VERSION\_PLAN\_ESTUDIOS se cumple id\_version\_plan → id\_carrera y la referencia desde ADMISION es obligatoria. Por tanto, al retirar ADMISION.id\_carrera, la unión ADMISION ⋈ VERSION\_PLAN\_ESTUDIOS por id\_version\_plan devuelve exactamente la carrera correspondiente a cada admisión válida, sin añadir combinaciones espurias. Esta verificación recupera un dato derivable; no supone crear una segunda relación desde ADMISION.

EXCEPCION\_REQUISITO referencia la regla mediante id\_requisito, clave alternativa UNIQUE NOT NULL de REQUISITO\_CURSO. La unión por esa clave devuelve exactamente una cuaterna (versión, curso objetivo, curso exigido, tipo) para cada excepción válida, sin multiplicar filas. La correspondencia entre la regla y el curso y versión de la solicitud se exige como integridad entre relaciones; se verifica la recuperabilidad de la regla referenciada, no una descomposición histórica inexistente.

Los medios de contacto y las ventanas inicialmente indeterminados se representan por ocurrencias separadas, relacionadas con su estudiante o periodo mediante FK. Los historiales también representan eventos independientes. Como el esquema inicial no especificaba relaciones atómicas completas para esos conjuntos, no corresponde atribuirles una demostración formal de reunión sin pérdida por DF; sí se preservan su identidad, asociación y multiplicidad.

## **Relaciones resultantes de la normalización**

Las relaciones resultantes se enumeran a continuación con sus atributos, identificadores y referencias.

1. ESTUDIANTE(numero\_institucional PK, nombre NN, primer\_apellido NN, segundo\_apellido ?)  
2. ADMISION(id\_admision PK, numero\_institucional FK NN, id\_sede FK NN, id\_version\_plan FK NN, fecha\_ingreso NN, condicion\_academica NN, activa NN)  
3. CARRERA(id\_carrera PK)  
4. SEDE(id\_sede PK, nombre NN)  
5. VERSION\_PLAN\_ESTUDIOS(id\_version\_plan PK, id\_carrera FK NN, inicio\_vigencia NN, fin\_vigencia ?)  
6. PERIODO\_ACADEMICO(id\_periodo PK, codigo\_periodo UQ NN, fecha\_inicio NN, fecha\_finalizacion NN)  
7. CURSO(codigo\_institucional PK, nombre NN, cantidad\_creditos NN, id\_escuela FK NN)  
8. ESCUELA(id\_escuela PK)  
9. GRUPO(id\_grupo PK, numero\_grupo NN, codigo\_curso FK NN, id\_periodo FK NN, id\_sede FK NN, capacidad NN, modalidad NN, estado\_oferta NN)  
10. BLOQUE\_HORARIO(id\_bloque PK, id\_grupo FK NN, dia\_semana NN, hora\_inicio NN, hora\_fin NN, es\_presencial NN, id\_espacio FK ?)  
11. ESPACIO(id\_espacio PK, id\_sede FK NN, capacidad NN, ubicacion NN)  
12. SOLICITUD\_MATRICULA(id\_solicitud PK, id\_admision FK NN, id\_grupo FK NN, id\_solicitud\_anterior FK ?, id\_version\_plan\_evaluada FK NN, fecha\_solicitud NN, estado NN, razon\_rechazo\_espera ?, orden\_espera ?, momento\_transicion ?, calificacion ?, resultado\_academico ?)  
13. DOCENTE(id\_docente PK, nombre NN)  
14. CONTACTO\_ESTUDIANTE(id\_contacto PK, numero\_institucional FK NN, tipo\_contacto NN, valor NN, es\_principal NN)  
15. CARRERA\_SEDE(id\_carrera PK/FK, id\_sede PK/FK)  
16. PARTICIPACION\_PLAN(codigo\_curso PK/FK, id\_version\_plan PK/FK, tipo\_participacion NN, nivel\_o\_periodo\_recomendado ?)  
17. REQUISITO\_CURSO(id\_version\_plan PK/FK, codigo\_curso\_objetivo PK/FK, codigo\_curso\_exigido PK/FK, tipo\_requisito PK, id\_requisito UQ NN)  
18. TRASLADO\_PLAN(id\_traslado PK, id\_admision FK NN, id\_version\_origen FK NN, id\_version\_destino FK NN, fecha NN, motivo NN, id\_autorizador FK NN)  
19. RECONOCIMIENTO\_ACADEMICO(id\_reconocimiento PK, id\_admision FK NN, referencia\_curso\_reconocido ?, codigo\_curso\_reconocido FK ?, id\_version\_plan FK NN, codigo\_curso\_satisfecho FK NN, resolucion\_academica NN, fecha\_resolucion NN)  
20. PERSONA\_AUTORIZADORA(id\_autorizador PK, nombre NN, identificacion\_institucional UQ NN)  
21. VENTANA\_PERIODO(id\_ventana PK, id\_periodo FK NN, tipo\_ventana NN, inicio NN, fin NN)  
22. GRUPO\_DOCENTE(id\_grupo PK/FK, id\_docente PK/FK, rol NN)  
23. HISTORIAL\_OFERTA(id\_cambio PK, id\_grupo FK NN, tipo\_cambio NN, estado\_anterior ?, estado\_nuevo ?, cupo\_anterior ?, cupo\_nuevo ?, fecha\_cambio NN, motivo NN, id\_responsable FK NN)  
24. HISTORIAL\_SOLICITUD(id\_evento PK, id\_solicitud FK NN, tipo\_evento NN, estado\_anterior ?, estado\_nuevo ?, fecha\_evento NN, motivo ?, id\_actor FK ?)  
25. EXCEPCION\_REQUISITO(id\_excepcion PK, id\_solicitud FK NN, id\_requisito FK NN, id\_autorizador FK NN, fecha\_autorizacion NN, motivo NN)  
26. HISTORIAL\_CORRECCION\_CALIFICACION(id\_correccion PK, id\_solicitud FK NN, calificacion\_anterior ?, calificacion\_nueva ?, resultado\_anterior ?, resultado\_nuevo ?, fecha\_correccion NN, motivo NN, id\_autorizador FK NN)

Las 26 relaciones resultantes satisfacen 1FN, 2FN y 3FN y, respecto de las DF y claves candidatas sustentadas, también BCNF. Las redundancias corregidas no requieren nuevas descomposiciones; las relaciones de contactos, ventanas e historiales se justifican por la multiplicidad y el significado de sus hechos. Las restricciones de capacidad, temporalidad, autorización y concurrencia corresponden a la integridad del modelo y no alteran por sí mismas su forma normal.
