# Modelo relacional consolidado — Proyecto 1 corregido

## Correspondencia y fundamento de las transformaciones del Proyecto 1

**Punto de partida:** 19 relaciones en el modelo original y en la matriz de partida del anexo G03. **Consolidación del equipo:** 26 relaciones. Las 19 originales permanecen identificables; siete aparecen por primera vez. Las definiciones completas de claves, nulabilidad y referencias siguen a esta sección.

| Modificación | Situación original | Consolidación y razón | Registro |
| --- | --- | --- | --- |
| Desglose de estudiante | Datos personales y de contacto genéricos | `ESTUDIANTE` con nombre/apellidos y nueva `CONTACTO_ESTUDIANTE` para valores repetibles | CC-P1-01 |
| Contexto de admisión | `ADMISION.id_carrera` coexistía con `id_version_plan` y no garantizaba compatibilidad | Carrera derivada de `VERSION_PLAN_ESTUDIOS`; sede y habilitación mediante `CARRERA_SEDE`, con campo `activa` | CC-P1-02 |
| Vigencias y ventanas | Vigencia genérica y fechas de operaciones no atómicas | Fechas de vigencia y `VENTANA_PERIODO` para intervalos individualizados | CC-P1-03 |
| Oferta y espacio | Sin estado de oferta; presencialidad y sede de espacio insuficientemente delimitadas | Se identifican estado, bloque presencial, sede y roles docentes; historial independiente de cambios | CC-P1-04 y 08 |
| Autorizaciones | Traslados y otros eventos sin identificador común de autorizante | `PERSONA_AUTORIZADORA` y referencias verificables a eventos | CC-P1-05 |
| Reconocimientos | Contexto vinculado al estudiante sin asegurar correspondencia con plan | `RECONOCIMIENTO_ACADEMICO` refiere admisión y par curso satisfecho/versión de `PARTICIPACION_PLAN` | CC-P1-06 |
| Requisito individual | PK compuesta sin identificador alternativo | `id_requisito` único para identificar la regla exceptuada, conservando PK y cursos externos permitidos | CC-P1-07 |
| Historia de oferta y solicitudes | No había relaciones autónomas que conservaran todos los eventos | `HISTORIAL_OFERTA` y `HISTORIAL_SOLICITUD` | CC-P1-08 y 09 |
| Excepciones y correcciones | Reglas reconocidas sin relaciones históricas correspondientes | `EXCEPCION_REQUISITO` y `HISTORIAL_CORRECCION_CALIFICACION` | CC-P1-10 y 11 |

**Las siete relaciones incorporadas son:** `CONTACTO_ESTUDIANTE`, `PERSONA_AUTORIZADORA`, `VENTANA_PERIODO`, `HISTORIAL_OFERTA`, `HISTORIAL_SOLICITUD`, `EXCEPCION_REQUISITO` y `HISTORIAL_CORRECCION_CALIFICACION`. `PARTICIPACION_PLAN`, `REQUISITO_CURSO`, `TRASLADO_PLAN` y `RECONOCIMIENTO_ACADEMICO` **ya existían** en el modelo relacional de partida; se ajustan sus atributos y asociaciones, pero no se presentan como cuatro relaciones nuevas.

El detalle de atributos sustituidos, identidades, restricciones y referencias se conserva en las 26 definiciones siguientes, en el [diccionario](04_Diccionario_Datos.md) y en [Control_de_Cambios.md](../Control_de_Cambios.md). El diseño es lógico: ninguna restricción pendiente de PostgreSQL se declara aquí como ejecutada.

**Criterio de transformación**

Cada entidad con identidad propia se transforma en una relación cuyos atributos son atómicos. Las asociaciones 1:N se reflejan, cuando corresponde, mediante claves foráneas en el extremo N; las M:N y los hechos con atributos o identidad histórica se representan mediante relaciones independientes. El diseño se fundamenta en las entidades, asociaciones, cardinalidades y reglas de negocio del análisis del caso.

La descomposición considera admisiones académicas diferenciadas, planes con vigencia histórica, oferta por periodo y sede, solicitudes de matrícula con transiciones, excepciones autorizadas y correcciones de resultados. En total se obtienen 26 relaciones.

**Relaciones resultantes de las entidades**

Cada definición muestra sus atributos y claves; a continuación se indica el hecho conceptual representado y la transformación lógica.

**1\.	ESTUDIANTE(numero\_institucional PK, nombre NN, primer\_apellido NN, segundo\_apellido ?)**

Origen conceptual: Estudiante.

Transformación: Número institucional como clave primaria. Los datos personales se descomponen en nombre, primer apellido y segundo apellido opcional. Los medios de contacto se representan en CONTACTO\_ESTUDIANTE para evitar atributos multivaluados.

**2\.	ADMISION(id\_admision PK, numero\_institucional FK NN, id\_sede FK NN, id\_version\_plan FK NN, fecha\_ingreso NN, condicion\_academica NN, activa NN)**

Origen conceptual: Admisión.

Transformación: La admisión pertenece a un estudiante, una sede y una versión de plan. La carrera se obtiene mediante VERSION\_PLAN\_ESTUDIOS, sin duplicar id\_carrera. La combinación de carrera derivada y sede debe existir en CARRERA\_SEDE. activa expresa la elegibilidad para solicitudes independientemente de condicion\_academica; un estudiante puede tener múltiples admisiones.

**3\.	CARRERA(id\_carrera PK)**

Origen conceptual: Carrera.

Transformación: Cada carrera se identifica mediante id\_carrera. No se atribuyen a esta relación datos de carácter obligatorio que el caso no define.

**4\.	SEDE(id\_sede PK, nombre NN)**

Origen conceptual: Sede.

Transformación: Cada sede tiene identificador propio y una denominación. La denominación es un atributo descriptivo adoptado para distinguir las sedes.

**5\.	VERSION\_PLAN\_ESTUDIOS(id\_version\_plan PK, id\_carrera FK NN, inicio\_vigencia NN, fin\_vigencia ?)**

Origen conceptual: Versión del plan de estudios.

Transformación: Cada versión pertenece a una carrera mediante id\_carrera. La vigencia se expresa con fecha inicial obligatoria y fecha final opcional; cuando existe, fin\_vigencia es igual o posterior a inicio\_vigencia. La carrera vinculada a una versión con referencias históricas permanece estable.

**6\.	PERIODO\_ACADEMICO(id\_periodo PK, codigo\_periodo UQ NN, fecha\_inicio NN, fecha\_finalizacion NN)**

Origen conceptual: Periodo académico.

Transformación: El periodo tiene identificador interno, código de periodo único, inicio y finalización obligatorios, con fecha\_inicio menor o igual que fecha\_finalizacion. Las ventanas operativas se representan en VENTANA\_PERIODO, no como una lista de fechas en la relación del periodo.

**7\.	CURSO(codigo\_institucional PK, nombre NN, cantidad\_creditos NN, id\_escuela FK NN)**

Origen conceptual: Curso.

Transformación: El código institucional identifica cada curso; nombre y cantidad de créditos son obligatorios. id\_escuela es una clave foránea obligatoria a ESCUELA y cantidad\_creditos es no negativa.

**8\.	ESCUELA(id\_escuela PK)**

Origen conceptual: Escuela.

Transformación: Cada escuela tiene identificador propio y puede administrar cero o más cursos. No se presupone otro atributo obligatorio que no haya sido definido en el caso.

**9\.	GRUPO(id\_grupo PK, numero\_grupo NN, codigo\_curso FK NN, id\_periodo FK NN, id\_sede FK NN, capacidad NN, modalidad NN, estado\_oferta NN)**

Origen conceptual: Grupo.

Transformación: Cada grupo referencia curso, periodo y sede y conserva número, capacidad, modalidad y estado de oferta. Se adopta UQ(id\_periodo, id\_sede, codigo\_curso, numero\_grupo); el número no es único globalmente. La capacidad es no negativa, la modalidad se representa como presencial, virtual o mixta y el estado como abierta, cerrada o cancelada. La capacidad no puede quedar por debajo de las matrículas confirmadas.

**10\.	BLOQUE\_HORARIO(id\_bloque PK, id\_grupo FK NN, dia\_semana NN, hora\_inicio NN, hora\_fin NN, es\_presencial NN, id\_espacio FK ?)**

Origen conceptual: Bloque de horario.

Transformación: Cada bloque pertenece a un grupo y conserva día, hora inicial, hora final y condición presencial. hora\_inicio es anterior a hora\_fin. Si es\_presencial es verdadero, id\_espacio es obligatorio; la modalidad mixta permite distinguir bloques presenciales y no presenciales. Un mismo espacio no puede tener asignaciones simultáneas, incluso en periodos cuyas fechas lectivas se superponen.

**11\.	ESPACIO(id\_espacio PK, id\_sede FK NN, capacidad NN, ubicacion NN)**

Origen conceptual: Espacio.

Transformación: El espacio pertenece a una sede e incluye capacidad física positiva y ubicación. Su sede debe coincidir con la del grupo al que se asigna un bloque presencial.

**12\.	SOLICITUD\_MATRICULA(id\_solicitud PK, id\_admision FK NN, id\_grupo FK NN, id\_solicitud\_anterior FK ?, id\_version\_plan\_evaluada FK NN, fecha\_solicitud NN, estado NN, razon\_rechazo\_espera ?, orden\_espera ?, momento\_transicion ?, calificacion ?, resultado\_academico ?)**

Origen conceptual: Solicitud de matrícula.

Transformación: Cada solicitud pertenece a una admisión y un grupo; conserva la versión de plan utilizada en su evaluación. Una solicitud de cambio puede referir una solicitud previa de la misma admisión, curso y periodo, con grupo distinto, sin ciclos ni origen no matriculado. El estado admite {matriculada, rechazada, en\_espera, retirada, anulada}; el resultado académico admite {aprobado, reprobado, incompleto, retiro\_justificado} cuando corresponde. Rechazo y espera registran motivo; el orden de espera y el instante de transición permanecen disponibles. La escala de calificación depende del contexto académico.

**13\.	DOCENTE(id\_docente PK, nombre NN)**

Origen conceptual: Docente.

Transformación: Cada docente posee identidad propia. Su participación en grupos y el rol responsable o adicional se materializan mediante GRUPO\_DOCENTE.

**14\.	CONTACTO\_ESTUDIANTE(id\_contacto PK, numero\_institucional FK NN, tipo\_contacto NN, valor NN, es\_principal NN)**

Origen conceptual: Contacto de estudiante.

Transformación: Cada medio de contacto tiene identidad propia y referencia obligatoria a ESTUDIANTE. UQ(numero\_institucional, tipo\_contacto, valor) evita duplicados; es\_principal distingue el medio preferido. Como criterio de diseño, existe al menos un contacto cuando el registro del estudiante está completo y, por estudiante y tipo, como máximo uno es principal.

**15\.	CARRERA\_SEDE(id\_carrera PK/FK, id\_sede PK/FK)**

Origen conceptual: Carrera en sede.

Transformación: La clave primaria compuesta (id\_carrera, id\_sede) representa la oferta de una carrera en una sede. Ambas columnas son claves foráneas obligatorias a CARRERA y SEDE, respectivamente.

**16\.	PARTICIPACION\_PLAN(codigo\_curso PK/FK, id\_version\_plan PK/FK, tipo\_participacion NN, nivel\_o\_periodo\_recomendado ?)**

Origen conceptual: Participa en plan.

Transformación: PK(codigo\_curso, id\_version\_plan), con claves foráneas a CURSO y VERSION\_PLAN\_ESTUDIOS. tipo\_participacion distingue {Obligatorio, Optativo}. nivel\_o\_periodo\_recomendado es un dato textual opcional, porque no se dispone de un dominio numérico universal ni de una obligatoriedad definida.

**17\.	REQUISITO\_CURSO(id\_version\_plan PK/FK, codigo\_curso\_objetivo PK/FK, codigo\_curso\_exigido PK/FK, tipo\_requisito PK, id\_requisito UQ NN)**

Origen conceptual: Requisito de curso.

Transformación: PK(id\_version\_plan, codigo\_curso\_objetivo, codigo\_curso\_exigido, tipo\_requisito). La versión referencia VERSION\_PLAN\_ESTUDIOS y los dos códigos de curso referencian CURSO con roles diferentes. tipo\_requisito admite {Requisito previo, Correquisito}; un curso no puede exigirse a sí mismo. id\_requisito es una clave alternativa única y obligatoria que identifica la regla completa desde EXCEPCION\_REQUISITO. Los cursos objetivo y exigido no están sujetos a una clave foránea adicional a PARTICIPACION\_PLAN; la aplicabilidad de la regla a una solicitud se valida mediante su versión y curso objetivo.

**18\.	TRASLADO\_PLAN(id\_traslado PK, id\_admision FK NN, id\_version\_origen FK NN, id\_version\_destino FK NN, fecha NN, motivo NN, id\_autorizador FK NN)**

Origen conceptual: Traslado de plan.

Transformación: Cada traslado pertenece a ADMISION, identifica versiones de origen y destino y conserva fecha, motivo y persona autorizadora. Las dos versiones deben ser diferentes y pertenecer a la misma carrera; el origen coincide con el plan asignado antes del evento. El cambio del plan y el registro del traslado constituyen una operación indivisible.

**19\.	RECONOCIMIENTO\_ACADEMICO(id\_reconocimiento PK, id\_admision FK NN, referencia\_curso\_reconocido ?, codigo\_curso\_reconocido FK ?, id\_version\_plan FK NN, codigo\_curso\_satisfecho FK NN, resolucion\_academica NN, fecha\_resolucion NN)**

Origen conceptual: Reconocimiento académico.

Transformación: El reconocimiento identifica la admisión, la resolución, su instante efectivo y el curso satisfecho en una versión concreta mediante FK(codigo\_curso\_satisfecho, id\_version\_plan) a PARTICIPACION\_PLAN. El curso reconocido se registra de forma excluyente: código con FK a CURSO si es institucional o referencia textual si proviene de otra institución. La versión debe ser aplicable a la admisión en el instante de la resolución; el reconocimiento no se extiende automáticamente a otras admisiones o versiones.

**20\.	PERSONA\_AUTORIZADORA(id\_autorizador PK, nombre NN, identificacion\_institucional UQ NN)**

Origen conceptual: Persona autorizadora.

Transformación: Identidad institucional reutilizable para autorizaciones de traslados, excepciones, cambios de oferta y correcciones de calificación. identificacion\_institucional es única y obligatoria; la participación concreta queda vinculada al evento correspondiente. No se equipara automáticamente a DOCENTE ni presupone jerarquías o permisos.

**21\.	VENTANA\_PERIODO(id\_ventana PK, id\_periodo FK NN, tipo\_ventana NN, inicio NN, fin NN)**

Origen conceptual: Ventana de periodo.

Transformación: Cada ventana pertenece a un PERIODO\_ACADEMICO y tiene un tipo entre {matricula, modificacion, retiro}. Se adopta un intervalo semiabierto \[inicio, fin), donde inicio es anterior a fin. Pueden existir varias ventanas de un mismo tipo sin solapamientos ambiguos; la ventana de matrícula no necesita estar contenida en las fechas lectivas.

**22\.	GRUPO\_DOCENTE(id\_grupo PK/FK, id\_docente PK/FK, rol NN)**

Origen conceptual: Docentes de grupo y rol.

Transformación: La clave compuesta (id\_grupo, id\_docente) identifica la participación de un docente en un grupo. rol admite {responsable, adicional}. Cada grupo publicado tiene exactamente un responsable; la unicidad condicionada garantiza como máximo uno y la obligatoriedad se comprueba al confirmar la oferta.

**23\.	HISTORIAL\_OFERTA(id\_cambio PK, id\_grupo FK NN, tipo\_cambio NN, estado\_anterior ?, estado\_nuevo ?, cupo\_anterior ?, cupo\_nuevo ?, fecha\_cambio NN, motivo NN, id\_responsable FK NN)**

Origen conceptual: Historial de oferta.

Transformación: Cada evento pertenece a un grupo y tiene responsable institucional. tipo\_cambio admite {apertura, cierre, cancelacion, cambio\_cupo}; el evento conserva fecha, motivo y valores anteriores y nuevos pertinentes, con una modificación efectiva. La cancelación del grupo no elimina las matrículas ni los registros históricos.

**24\.	HISTORIAL\_SOLICITUD(id\_evento PK, id\_solicitud FK NN, tipo\_evento NN, estado\_anterior ?, estado\_nuevo ?, fecha\_evento NN, motivo ?, id\_actor FK ?)**

Origen conceptual: Historial de solicitud.

Transformación: Cada evento referencia una solicitud y opcionalmente una persona autorizadora cuando interviene un actor administrativo. tipo\_evento admite {transicion, evaluacion\_espera}. Las transiciones registran estados anterior y nuevo; las evaluaciones sin cambio de estado documentan su motivo. El evento histórico y la actualización de la solicitud son consistentes.

**25\.	EXCEPCION\_REQUISITO(id\_excepcion PK, id\_solicitud FK NN, id\_requisito FK NN, id\_autorizador FK NN, fecha\_autorizacion NN, motivo NN)**

Origen conceptual: Excepción de requisito.

Transformación: Cada excepción referencia una solicitud, una regla específica mediante la clave alternativa REQUISITO\_CURSO(id\_requisito) y una persona autorizadora. Conserva fecha y motivo. La versión y el curso objetivo de la regla referenciada deben coincidir con el plan evaluado y el curso del grupo de la solicitud; el contexto se obtiene por las relaciones existentes, sin duplicarlo en la excepción.

**26\.	HISTORIAL\_CORRECCION\_CALIFICACION(id\_correccion PK, id\_solicitud FK NN, calificacion\_anterior ?, calificacion\_nueva ?, resultado\_anterior ?, resultado\_nuevo ?, fecha\_correccion NN, motivo NN, id\_autorizador FK NN)**

Origen conceptual: Historial de corrección de calificación.

Transformación: Cada corrección referencia una solicitud y una persona autorizadora; conserva instante, motivo, valores anteriores y nuevos de calificación o resultado. Al menos uno de esos valores debe cambiar efectivamente. La escala académica no se fija universalmente.

### **Transformación de asociaciones**

**Criterio de transformación**

La transformación conserva las cardinalidades y los atributos propios establecidos en el modelo conceptual corregido. Las asociaciones 1:N se reflejan mediante claves foráneas en la relación dependiente; las M:N y los hechos repetibles o históricos se materializan mediante relaciones específicas. Las referencias opcionales mantienen las condiciones que determinan cuándo debe existir el vínculo.

**1\.	Posee admisiones**

ADMISION.numero\_institucional es FK obligatoria a ESTUDIANTE. Cada admisión pertenece a un estudiante y cada estudiante puede mantener múltiples admisiones, simultáneas o históricas; no se crea una relación intermedia.

**2\.	Contextualiza admisión**

ADMISION conserva id\_sede e id\_version\_plan como FKs obligatorias. La carrera se obtiene de VERSION\_PLAN\_ESTUDIOS.id\_carrera y su oferta en la sede consta en CARRERA\_SEDE; no se duplica id\_carrera. La asignación y los traslados identifican la versión aplicable en cada instante. Al resolver matrícula no se presupone que la sede de la admisión deba coincidir con la sede del grupo: ambas se conservan y se comprueban, sin introducir una prohibición de matrícula intersede ausente del caso.

**3\.	Se ofrece en**

CARRERA\_SEDE(id\_carrera, id\_sede) materializa la asociación M:N Carrera–Sede; la PK compuesta identifica cada combinación habilitada y ambas columnas son FKs obligatorias.

**4\.	Posee versiones**

VERSION\_PLAN\_ESTUDIOS.id\_carrera es FK obligatoria a CARRERA. Cada versión pertenece a una carrera, que puede poseer múltiples versiones; no requiere relación intermedia.

**5\.	Pertenece administrativamente**

CURSO.id\_escuela es FK obligatoria a ESCUELA. Cada curso pertenece a una escuela, que puede administrar múltiples cursos.

**6\.	Participa en plan**

PARTICIPACION\_PLAN(codigo\_curso, id\_version\_plan, tipo\_participacion, nivel\_o\_periodo\_recomendado) conserva la asociación M:N Curso–Versión y sus atributos propios. La PK compuesta identifica una ocurrencia por pareja y permite tipos y niveles distintos entre versiones.

**7\.	Define requisitos**

REQUISITO\_CURSO distingue versión, curso objetivo, curso exigido y tipo mediante una PK de cuatro componentes. id\_requisito, UNIQUE NOT NULL y generado automáticamente, identifica adicionalmente la regla completa para EXCEPCION\_REQUISITO. No se imponen FKs adicionales de los dos cursos a PARTICIPACION\_PLAN: una regla puede exigir cursos externos a la versión. Para matrícula, un requisito previo se satisface mediante aprobación anterior o reconocimiento válido; un correquisito mediante aprobación anterior o matrícula del mismo periodo. Toda excepción se limita a la regla autorizada para la solicitud.

**8\.	Registra traslado**

TRASLADO\_PLAN identifica cada cambio histórico de versión de una admisión y conserva versiones de origen y destino, instante efectivo, motivo y persona autorizadora. Ambas versiones pertenecen a la misma carrera, son diferentes y el origen corresponde al plan vigente antes del evento. Cambio e historial son consistentes. Los cambios de plan y las resoluciones que determinan el contexto histórico se registran como instantes con fecha, hora y zona horaria, sin ambigüedad entre eventos del mismo día.

**9\.	Registra reconocimiento**

RECONOCIMIENTO\_ACADEMICO referencia la admisión, versión aplicable y curso satisfecho por una FK compuesta a PARTICIPACION\_PLAN. El curso reconocido se identifica por código institucional o referencia externa, excluyentemente, y se conserva resolución e instante efectivo, sin transferir automáticamente el reconocimiento a otra admisión o versión.

**10\.	Oferta grupo**

GRUPO referencia a CURSO, PERIODO\_ACADEMICO y SEDE por FKs obligatorias. Cada grupo es oferta de un curso en un periodo y una sede; esos conceptos pueden aparecer en múltiples grupos.

**11\.	Participación docente**

GRUPO\_DOCENTE(id\_grupo, id\_docente, rol) expresa la asociación M:N y conserva los roles responsable y adicional. La PK identifica cada participación; un grupo publicado tiene exactamente un responsable y puede incluir docentes adicionales. La publicación debe comprobar conjuntamente la existencia de ese responsable y al menos un bloque de horario, sin confirmar una oferta incompleta.

**12\.	Programa horario**

BLOQUE\_HORARIO referencia obligatoriamente a GRUPO y opcionalmente a ESPACIO; el espacio es obligatorio para un bloque presencial y pertenece a la sede del grupo. Cada grupo publicado tiene al menos un bloque. Un espacio es reutilizable en horarios compatibles, pero no simultáneamente entre grupos con días, horas y fechas lectivas coincidentes. La compatibilidad del espacio incluye su capacidad cuando corresponda a la actividad ofertada.

**13\.	Gestiona solicitud**

SOLICITUD\_MATRICULA referencia a ADMISION, GRUPO y VERSION\_PLAN\_ESTUDIOS evaluada. id\_solicitud\_anterior es opcional y enlaza cambios de grupo de igual admisión, curso y periodo, con origen matriculado y sin ciclos. El estado matriculada representa la matrícula efectiva; no se duplica en una tabla MATRÍCULA separada. Calificación y resultado académico permanecen asociados a la solicitud. El cambio de grupo se confirma de forma indivisible: un rechazo por cupo, horario o elegibilidad conserva matriculada la solicitud de origen.

**14\.	Registra contactos**

CONTACTO\_ESTUDIANTE guarda cada medio de contacto con su identidad, tipo, valor, marca de principal y FK a ESTUDIANTE. Admite contactos múltiples, evita duplicar (estudiante, tipo, valor) y permite a lo sumo un principal por tipo y estudiante.

**15\.	Habilita ventanas**

VENTANA\_PERIODO representa cada intervalo de matrícula, modificación o retiro mediante su FK a PERIODO\_ACADEMICO. Admite varias ventanas del mismo tipo sin superposiciones ambiguas y utiliza límites semiabiertos \[inicio, fin).

**16\.	Identifica autorizaciones**

PERSONA\_AUTORIZADORA conserva la identidad institucional de quienes autorizan traslados, excepciones y correcciones o responden por cambios de oferta. HISTORIAL\_SOLICITUD puede identificar opcionalmente un actor administrativo. No se presupone que la persona sea DOCENTE ni se inventan jerarquías.

**17\.	Documenta cambios de oferta**

HISTORIAL\_OFERTA vincula al grupo y responsable cada apertura, cierre, cancelación o cambio de cupo, con fecha, motivo y valores anteriores y nuevos pertinentes. Las matrículas y solicitudes anteriores se conservan aunque el grupo se cancele. No se admiten eventos históricos vacíos ni se sobrescriben los hechos anteriores.

**18\.	Documenta eventos de solicitud**

HISTORIAL\_SOLICITUD conserva transiciones y evaluaciones de espera de cada solicitud. Registra instante, estados anterior y nuevo cuando aplica, razón de una omisión de promoción y actor administrativo opcional. Estado actual e historial son consistentes. Cuando no queda ninguna persona elegible, la lista no genera una matrícula ficticia y se conservan los motivos de omisión.

**19\.	Concede excepción**

EXCEPCION\_REQUISITO vincula una solicitud con una regla concreta mediante REQUISITO\_CURSO.id\_requisito y con su autorizante. Conserva fecha y motivo, y exige que versión y curso objetivo de la regla coincidan con el plan evaluado y el grupo solicitado, sin repetir esos atributos contextuales.

**20\.	Documenta corrección**

HISTORIAL\_CORRECCION\_CALIFICACION registra cambios autorizados de calificación o resultado de una solicitud, con valores anteriores y nuevos, instante, motivo y persona autorizadora. Cada evento modifica efectivamente al menos un valor sin destruir los anteriores.

### **Identificadores y claves**

**Criterio de diseño**

ESTUDIANTE.numero\_institucional y CURSO.codigo\_institucional conservan los identificadores institucionales expresos del caso. Las otras entidades con identidad propia utilizan identificadores internos estables; las asociaciones identificables por los participantes emplean claves compuestas. Toda clave primaria es única y no nula. Las claves de los eventos históricos permiten registrar sucesivas ocurrencias sin confundirlas con la identidad de su participante.

**Claves primarias de las relaciones base**

* ESTUDIANTE: PK \= numero\_institucional. Identificador institucional único.  
* ADMISION: PK \= id\_admision. Distingue admisiones múltiples de una persona.  
* CARRERA: PK \= id\_carrera. Identifica una carrera.  
* SEDE: PK \= id\_sede. Identifica una sede.  
* VERSION\_PLAN\_ESTUDIOS: PK \= id\_version\_plan. Identifica una versión histórica.  
* PERIODO\_ACADEMICO: PK \= id\_periodo. Identifica cada periodo.  
* CURSO: PK \= codigo\_institucional. Identificador institucional del curso.  
* ESCUELA: PK \= id\_escuela. Identifica la escuela.  
* GRUPO: PK \= id\_grupo. Distingue grupos sin exigir un numero\_grupo global.  
* BLOQUE\_HORARIO: PK \= id\_bloque. Identifica cada bloque programado.  
* ESPACIO: PK \= id\_espacio. Identifica cada espacio.  
* SOLICITUD\_MATRICULA: PK \= id\_solicitud. Distingue solicitudes y cambios.  
* DOCENTE: PK \= id\_docente. Identifica a cada docente.

**Claves primarias de las relaciones derivadas**

* CONTACTO\_ESTUDIANTE: PK \= id\_contacto. Permite varios contactos por estudiante.  
* CARRERA\_SEDE: PK \= (id\_carrera, id\_sede). Identifica una habilitación de carrera y sede.  
* PARTICIPACION\_PLAN: PK \= (codigo\_curso, id\_version\_plan). Identifica cada pareja curso–versión.  
* REQUISITO\_CURSO: PK \= (id\_version\_plan, codigo\_curso\_objetivo, codigo\_curso\_exigido, tipo\_requisito). Identifica una regla curricular completa.  
* TRASLADO\_PLAN: PK \= id\_traslado. Distingue eventos de traslado.  
* RECONOCIMIENTO\_ACADEMICO: PK \= id\_reconocimiento. Identifica la resolución individual.  
* PERSONA\_AUTORIZADORA: PK \= id\_autorizador. Identifica a la persona institucional.  
* VENTANA\_PERIODO: PK \= id\_ventana. Distingue intervalos de un periodo.  
* GRUPO\_DOCENTE: PK \= (id\_grupo, id\_docente). Identifica la participación docente.  
* HISTORIAL\_OFERTA: PK \= id\_cambio. Identifica eventos de oferta.  
* HISTORIAL\_SOLICITUD: PK \= id\_evento. Identifica transiciones y evaluaciones.  
* EXCEPCION\_REQUISITO: PK \= id\_excepcion. Identifica autorizaciones individuales de excepción.  
* HISTORIAL\_CORRECCION\_CALIFICACION: PK \= id\_correccion. Identifica cambios académicos históricos.

**Claves foráneas**

* CONTACTO\_ESTUDIANTE.numero\_institucional → ESTUDIANTE.numero\_institucional.  
* CARRERA\_SEDE.id\_carrera → CARRERA.id\_carrera; id\_sede → SEDE.id\_sede.  
* VERSION\_PLAN\_ESTUDIOS.id\_carrera → CARRERA.id\_carrera.  
* ADMISION.numero\_institucional → ESTUDIANTE.numero\_institucional; id\_sede → SEDE.id\_sede; id\_version\_plan → VERSION\_PLAN\_ESTUDIOS.id\_version\_plan. La carrera se deriva de la versión y su oferta en la sede debe constar en CARRERA\_SEDE.  
* CURSO.id\_escuela → ESCUELA.id\_escuela.  
* PARTICIPACION\_PLAN.codigo\_curso → CURSO.codigo\_institucional; id\_version\_plan → VERSION\_PLAN\_ESTUDIOS.id\_version\_plan.  
* REQUISITO\_CURSO.id\_version\_plan → VERSION\_PLAN\_ESTUDIOS.id\_version\_plan; codigo\_curso\_objetivo y codigo\_curso\_exigido → CURSO.codigo\_institucional con roles distintos. No se exige pertenencia de esos cursos a PARTICIPACION\_PLAN, porque se admiten requisitos de cursos no participantes en la versión.  
* TRASLADO\_PLAN.id\_admision → ADMISION.id\_admision; id\_version\_origen e id\_version\_destino → VERSION\_PLAN\_ESTUDIOS.id\_version\_plan; id\_autorizador → PERSONA\_AUTORIZADORA.id\_autorizador. Las versiones son distintas y pertenecen a la misma carrera; el origen coincide con la versión aplicable antes del traslado.  
* RECONOCIMIENTO\_ACADEMICO.id\_admision → ADMISION.id\_admision; codigo\_curso\_reconocido → CURSO.codigo\_institucional cuando el origen es interno; (codigo\_curso\_satisfecho, id\_version\_plan) → PARTICIPACION\_PLAN(codigo\_curso, id\_version\_plan). El origen externo es alternativo al interno y la resolución corresponde al contexto temporal de la admisión.  
* VENTANA\_PERIODO.id\_periodo → PERIODO\_ACADEMICO.id\_periodo.  
* ESPACIO.id\_sede → SEDE.id\_sede.  
* GRUPO.codigo\_curso → CURSO.codigo\_institucional; id\_periodo → PERIODO\_ACADEMICO.id\_periodo; id\_sede → SEDE.id\_sede.  
* GRUPO\_DOCENTE.id\_grupo → GRUPO.id\_grupo; id\_docente → DOCENTE.id\_docente.  
* BLOQUE\_HORARIO.id\_grupo → GRUPO.id\_grupo; id\_espacio → ESPACIO.id\_espacio cuando existe. Para actividad presencial se requiere un espacio de la sede del grupo.  
* HISTORIAL\_OFERTA.id\_grupo → GRUPO.id\_grupo; id\_responsable → PERSONA\_AUTORIZADORA.id\_autorizador.  
* SOLICITUD\_MATRICULA.id\_admision → ADMISION.id\_admision; id\_grupo → GRUPO.id\_grupo; id\_solicitud\_anterior → SOLICITUD\_MATRICULA.id\_solicitud cuando corresponde; id\_version\_plan\_evaluada → VERSION\_PLAN\_ESTUDIOS.id\_version\_plan. El cambio conserva igual admisión, curso y periodo.  
* HISTORIAL\_SOLICITUD.id\_solicitud → SOLICITUD\_MATRICULA.id\_solicitud; id\_actor → PERSONA\_AUTORIZADORA.id\_autorizador cuando interviene actor administrativo.  
* EXCEPCION\_REQUISITO.id\_solicitud → SOLICITUD\_MATRICULA.id\_solicitud; id\_requisito → REQUISITO\_CURSO.id\_requisito; id\_autorizador → PERSONA\_AUTORIZADORA.id\_autorizador. La regla exceptuada corresponde al curso y plan evaluados en la solicitud.  
* HISTORIAL\_CORRECCION\_CALIFICACION.id\_solicitud → SOLICITUD\_MATRICULA.id\_solicitud; id\_autorizador → PERSONA\_AUTORIZADORA.id\_autorizador.

**Claves candidatas relevantes**

ESTUDIANTE.numero\_institucional y CURSO.codigo\_institucional son claves de negocio y candidatas elegidas como PK. Las parejas de CARRERA\_SEDE y PARTICIPACION\_PLAN y la cuaterna de REQUISITO\_CURSO son candidatas compuestas, porque ningún componente individual identifica toda la ocurrencia.

REQUISITO\_CURSO.id\_requisito es una clave candidata alternativa UNIQUE NOT NULL, generada por defecto en PostgreSQL, sin reemplazar la PK compuesta ni modificar los INSERT de cuatro columnas de Lab03. También son claves alternativas CONTACTO\_ESTUDIANTE(numero\_institucional, tipo\_contacto, valor), PERIODO\_ACADEMICO.codigo\_periodo, PERSONA\_AUTORIZADORA.identificacion\_institucional y, bajo la unicidad local documentada, GRUPO(id\_periodo, id\_sede, codigo\_curso, numero\_grupo).

GRUPO\_DOCENTE(id\_grupo, id\_docente) identifica la participación, no un responsable globalmente único; rol permanece fuera de la PK. No se impone unicidad global de numero\_grupo ni se consideran claves candidatas la resolución académica o la combinación estudiante–carrera–sede de una admisión.

**Tratamiento de entidades débiles**

El modelo conceptual corregido identifica sus entidades mediante atributos propios, incluidos Contacto de estudiante, Ventana de periodo y los eventos históricos. La dependencia de existencia respecto de Estudiante, Periodo, Solicitud o Grupo se refleja en FKs obligatorias, pero no exige clasificarlas como entidades débiles identificadas por una clave parcial. Las claves compuestas de asociaciones M:N tampoco implican crear entidades débiles conceptuales.

### **Nulabilidad y unicidad**

**Criterio de diseño**

Toda PK es no nula; los atributos NN son obligatorios y los marcados como opcionales admiten ausencia de valor únicamente cuando el hecho representado lo permite. La participación obligatoria determina las FKs no nulas, mientras las condiciones entre varias filas o tablas exigen restricciones de integridad adicionales, sin confundir nulabilidad con existencia condicional.

**Referencias obligatorias y opcionales**

CONTACTO\_ESTUDIANTE.numero\_institucional: no nulo, porque todo contacto corresponde a un estudiante.

CARRERA\_SEDE.id\_carrera e id\_sede: no nulos, porque ambos identifican la asociación.

VERSION\_PLAN\_ESTUDIOS.id\_carrera: no nulo, porque cada versión pertenece a una carrera.

ADMISION.numero\_institucional, id\_sede e id\_version\_plan: no nulos; cada admisión pertenece a un estudiante, sede y versión, y la carrera procede de la versión sin columna duplicada.

CURSO.id\_escuela: no nulo, porque cada curso pertenece a una escuela.

PARTICIPACION\_PLAN.codigo\_curso e id\_version\_plan: no nulos, porque constituyen su clave compuesta.

REQUISITO\_CURSO.id\_version\_plan, codigo\_curso\_objetivo y codigo\_curso\_exigido: no nulos, al igual que tipo\_requisito, para identificar cada regla.

TRASLADO\_PLAN.id\_admision, id\_version\_origen, id\_version\_destino e id\_autorizador: no nulos, porque todo traslado identifica sus participantes y autorizante.

RECONOCIMIENTO\_ACADEMICO.id\_admision, id\_version\_plan y codigo\_curso\_satisfecho: no nulos. codigo\_curso\_reconocido es opcional únicamente cuando se identifica un origen externo mediante referencia\_curso\_reconocido; ambas alternativas son excluyentes.

VENTANA\_PERIODO.id\_periodo: no nulo, porque pertenece a un periodo académico.

ESPACIO.id\_sede: no nulo, porque todo espacio tiene una sede.

GRUPO.codigo\_curso, id\_periodo e id\_sede: no nulos; contextualizan la oferta.

GRUPO\_DOCENTE.id\_grupo e id\_docente: no nulos; cada participación relaciona ambos participantes.

BLOQUE\_HORARIO.id\_grupo: no nulo. id\_espacio admite nulo para actividad no presencial y es obligatorio si es\_presencial es verdadero; la sede del espacio coincide con la del grupo.

HISTORIAL\_OFERTA.id\_grupo e id\_responsable: no nulos, porque cada cambio tiene grupo y responsable.

SOLICITUD\_MATRICULA.id\_admision, id\_grupo e id\_version\_plan\_evaluada: no nulos. id\_solicitud\_anterior es opcional y se usa para cambios de grupo válidos.

HISTORIAL\_SOLICITUD.id\_solicitud: no nulo. id\_actor es opcional si no interviene una persona autorizadora administrativa.

EXCEPCION\_REQUISITO.id\_solicitud, id\_requisito e id\_autorizador: no nulos para vincular la solicitud, regla y autorizante.

HISTORIAL\_CORRECCION\_CALIFICACION.id\_solicitud e id\_autorizador: no nulos, porque cada corrección tiene solicitud y autorización.

**Nulabilidad de atributos propios**

ESTUDIANTE.nombre y primer\_apellido: no nulos; segundo\_apellido: opcional. Los contactos se representan en una relación independiente.

CONTACTO\_ESTUDIANTE.tipo\_contacto, valor y es\_principal: no nulos; cada contacto conserva tipo, contenido y preferencia.

SEDE.nombre: no nulo para identificar su denominación legible.

VERSION\_PLAN\_ESTUDIOS.inicio\_vigencia: no nulo; fin\_vigencia: opcional, pero no anterior al inicio.

ADMISION.fecha\_ingreso, condicion\_academica y activa: no nulos. La condición académica no sustituye a la marca de admisión activa.

CURSO.nombre y cantidad\_creditos: no nulos; los créditos son no negativos.

PARTICIPACION\_PLAN.tipo\_participacion: no nulo, obligatorio u optativo; nivel\_o\_periodo\_recomendado: texto opcional como en Lab03.

REQUISITO\_CURSO.tipo\_requisito e id\_requisito: no nulos; el tipo distingue requisito previo o correquisito y no admite autorrequisito.

TRASLADO\_PLAN.fecha y motivo: no nulos; fecha identifica el instante efectivo y permite ordenar sucesivos traslados.

RECONOCIMIENTO\_ACADEMICO.resolucion\_academica y fecha\_resolucion: no nulos; referencia\_curso\_reconocido admite nulo solo cuando se identifica el origen institucional por codigo\_curso\_reconocido, y viceversa.

PERSONA\_AUTORIZADORA.nombre e identificacion\_institucional: no nulos; la identificación institucional es individual y única.

PERIODO\_ACADEMICO.codigo\_periodo, fecha\_inicio y fecha\_finalizacion: no nulos; el inicio lectivo no es posterior al final.

VENTANA\_PERIODO.tipo\_ventana, inicio y fin: no nulos; el tipo es matrícula, modificación o retiro y el intervalo cumple inicio anterior a fin, con límites semiabiertos \[inicio, fin).

DOCENTE.nombre: no nulo, como dato descriptivo del docente.

ESPACIO.capacidad y ubicacion: no nulos; la capacidad física es positiva.

GRUPO.numero\_grupo, capacidad, modalidad y estado\_oferta: no nulos. La capacidad es no negativa y no puede quedar por debajo de la matrícula confirmada. modalidad pertenece a {presencial, virtual, mixta} y estado\_oferta a {abierta, cerrada, cancelada}.

GRUPO\_DOCENTE.rol: no nulo; responsable o adicional. Un grupo publicado requiere exactamente un responsable.

BLOQUE\_HORARIO.dia\_semana, hora\_inicio, hora\_fin y es\_presencial: no nulos; hora\_inicio precede a hora\_fin. La presencialidad se determina por bloque.

HISTORIAL\_OFERTA.tipo\_cambio, fecha\_cambio y motivo: no nulos; estado\_anterior, estado\_nuevo, cupo\_anterior y cupo\_nuevo son opcionales según el evento y reflejan un cambio efectivo.

SOLICITUD\_MATRICULA.fecha\_solicitud y estado: no nulos. razon\_rechazo\_espera registra rechazo o espera, orden\_espera identifica la posición de espera y momento\_transicion guarda el cambio. calificacion y resultado\_academico son opcionales según la situación; el resultado admite {aprobado, reprobado, incompleto, retiro\_justificado}.

HISTORIAL\_SOLICITUD.tipo\_evento y fecha\_evento: no nulos. estado\_anterior y estado\_nuevo son condicionales a una transición; motivo explica, entre otras cosas, las omisiones de promoción.

EXCEPCION\_REQUISITO.fecha\_autorizacion y motivo: no nulos; conservan cuándo y por qué se exceptuó una regla.

HISTORIAL\_CORRECCION\_CALIFICACION.fecha\_correccion y motivo: no nulos. calificacion\_anterior, calificacion\_nueva, resultado\_anterior y resultado\_nuevo son opcionales por componente, pero al menos un valor debe cambiar y preservarse.

**Restricciones de unicidad**

Todas las PK son únicas. CARRERA\_SEDE(id\_carrera, id\_sede), PARTICIPACION\_PLAN(codigo\_curso, id\_version\_plan), GRUPO\_DOCENTE(id\_grupo, id\_docente) y la cuaterna de REQUISITO\_CURSO identifican una asociación o regla; sus componentes no son individualmente únicos.

CONTACTO\_ESTUDIANTE tiene UQ(numero\_institucional, tipo\_contacto, valor) y admite como máximo un principal por estudiante y tipo. REQUISITO\_CURSO.id\_requisito, PERIODO\_ACADEMICO.codigo\_periodo y PERSONA\_AUTORIZADORA.identificacion\_institucional son UNIQUE NOT NULL.

GRUPO.numero\_grupo no es único globalmente; sí lo es (id\_periodo, id\_sede, codigo\_curso, numero\_grupo), conforme al supuesto local documentado. No son únicas por sí mismas resolucion\_academica ni la combinación estudiante–carrera–sede de ADMISION.

GRUPO\_DOCENTE permite como máximo un responsable por grupo y exige exactamente uno para un grupo publicado; la publicación también requiere al menos un BLOQUE\_HORARIO. Estas condiciones de existencia no se obtienen de la PK compuesta.

RN-16 impide dos matrículas activas del mismo estudiante, curso y periodo, aun entre admisiones diferentes, y permite repetir un curso en periodos posteriores. La regla depende del estado de SOLICITUD\_MATRICULA y de ADMISION y GRUPO, por lo que no se reduce a un UNIQUE simple sobre la solicitud. La ocupación se calcula exclusivamente con solicitudes en estado matriculada, y la reducción de capacidad por debajo de esa ocupación se rechaza íntegramente.

Las listas de espera preservan un orden estable, con orden\_espera e id\_solicitud como desempate. Una promoción vuelve a comprobar elegibilidad, documenta omisiones y conserva la matrícula de origen si el cambio de grupo falla. La integridad de cupos, duplicación y estados también se mantiene en concurrencia.

**Tratamiento de atributos compuestos o multivaluados**

ESTUDIANTE descompone sus datos personales en nombre, primer\_apellido y segundo\_apellido opcional. CONTACTO\_ESTUDIANTE almacena medios repetibles mediante tipo\_contacto, valor y es\_principal, sin listas de teléfonos o correos ni duplicación de contactos en ESTUDIANTE.

VERSION\_PLAN\_ESTUDIOS expresa su vigencia mediante inicio\_vigencia y fin\_vigencia opcional, sustituyendo la vigencia textual previa de Lab03. PERIODO\_ACADEMICO conserva fechas lectivas y VENTANA\_PERIODO representa cada intervalo autorizado de matrícula, modificación o retiro. Las fechas efectivas de traslados y reconocimientos permiten orden temporal dentro de un mismo día.

La participación de varios cursos en una versión, varios docentes en un grupo, varias sedes por carrera y múltiples requisitos se representa mediante PARTICIPACION\_PLAN, GRUPO\_DOCENTE, CARRERA\_SEDE y REQUISITO\_CURSO. Los cambios de oferta, solicitudes y calificaciones se preservan como eventos independientes en sus historiales, no como atributos multivaluados.

### **Validación M:N o equivalente**

**Caso seleccionado:** Participa en plan

CURSO y VERSION\_PLAN\_ESTUDIOS participan en una asociación M:N: un curso puede aparecer en múltiples versiones y una versión puede incluir múltiples cursos. La participación guarda tipo obligatorio u optativo y nivel o periodo recomendado opcional.

**Transformación aplicada**

Una única FK en CURSO o en VERSION\_PLAN\_ESTUDIOS limitaría incorrectamente la multiplicidad y no conservaría los atributos de la asociación. La transformación produce PARTICIPACION\_PLAN(codigo\_curso, id\_version\_plan, tipo\_participacion, nivel\_o\_periodo\_recomendado).

**Validación de claves y referencias**

La PK compuesta (codigo\_curso, id\_version\_plan) identifica una sola participación por pareja, con FKs obligatorias a CURSO y VERSION\_PLAN\_ESTUDIOS. tipo\_participacion es obligatorio y nivel\_o\_periodo\_recomendado conserva el carácter textual opcional de Lab03; la clave evita duplicados sin volver único al curso globalmente.

**Comprobación de preservación semántica**

El mismo curso puede figurar en versiones distintas con diferente tipo de participación o nivel recomendado; cada versión puede contener numerosos cursos. Se mantiene EV-02 del análisis corregido sin duplicar atributos propios. CARRERA\_SEDE y GRUPO\_DOCENTE conservan igualmente sus asociaciones M:N y REQUISITO\_CURSO diferencia roles de curso objetivo y exigido, tipo y versión.

### **Regla no completamente representable**

**Regla seleccionada: RN-07**

RN-07 establece que todo bloque presencial debe tener un espacio físico asignado y que un mismo espacio no puede utilizarse simultáneamente por dos grupos.

**Parte representable en el diseño lógico**

BLOQUE\_HORARIO referencia obligatoriamente a GRUPO y registra id\_espacio como FK a ESPACIO, obligatoria cuando es\_presencial es verdadero. Conserva día y horas, y el espacio pertenece a la misma sede del grupo.

**No representable completamente en el diseño lógico**

PK, FK, NN y UQ individuales no impiden que dos bloques ocupen simultáneamente el mismo espacio con horarios parcialmente solapados. Un UNIQUE de id\_espacio impediría su reutilización legítima y una combinación de horas exactas tampoco detectaría solapamientos. La comprobación incluye la coincidencia de fechas lectivas entre periodos, días e intervalos; bloques contiguos sin intersección son válidos.

**Comprobación posterior requerida**

La integridad temporal exige comparar bloques del mismo espacio cuyas fechas lectivas, días e intervalos horarios se intersecten, incluso entre periodos distintos. La ocupación máxima, matrícula activa única, ventanas autorizadas y transiciones históricas también deben mantenerse bajo INSERT, UPDATE y DELETE permitidos y concurrencia. El modelo lógico expresa estas reglas, mientras su garantía física corresponde a restricciones y operaciones transaccionales de PostgreSQL.
