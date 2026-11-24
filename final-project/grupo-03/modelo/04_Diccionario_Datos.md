# Diccionario de datos — Proyecto 1 corregido

## Correspondencia con el diccionario del Proyecto 1

La versión original contenía **19 relaciones y 77 registros de atributos**; la corrección documenta **26 relaciones y 135 atributos**. El aumento no representa una simple renumeración: refleja los conceptos históricos, de autorización y temporales incorporados y el desglose de atributos originalmente no atómicos.

| Grupo de cambios | Qué se modificó respecto del diccionario original | Referencia |
| --- | --- | --- |
| Datos personales y contactos | `datos_personales` y `datos_contacto` se sustituyen por componentes de estudiante y medios de contacto individuales | CC-P1-01 |
| Contexto académico | Admisión sin carrera redundante, con estado activo; versiones con vigencia desglosada; reconocimiento contextualizado | CC-P1-02, 03 y 06 |
| Oferta y temporalidad | Fechas de ventanas separadas, presencialidad por bloque, sede de espacio, estado e historia de oferta | CC-P1-03, 04 y 08 |
| Reglas y autorizaciones | Identificador alternativo de requisito, autorizante institucional y excepción asociada a solicitud | CC-P1-05, 07 y 10 |
| Movimientos y correcciones | Historia de solicitud, fecha y plan evaluado y correcciones de calificación con valores anteriores y nuevos | CC-P1-09 y 11 |

La [correspondencia individual de atributos](../Control_de_Cambios.md) está en el **Anexo A** de `Control_de_Cambios.md`, donde se identifican altas, sustituciones y modificaciones, además de las 19 relaciones de origen. No se altera ni sintetiza ninguna de las **135 filas** que siguen. Estos son dominios y restricciones de diseño lógico; su verificación física se documentará con los scripts y pruebas de la segunda entrega.

Este documento conserva los **135 atributos** y las **26 relaciones** del diccionario corregido, en el orden de la hoja original.

> La información corresponde al modelo lógico corregido. Los tipos físicos y las pruebas de restricciones PostgreSQL se documentarán durante la segunda entrega.

## ESTUDIANTE

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ESTUDIANTE | numero_institucional | Identificador institucional asignado a cada estudiante; no cambia entre sus admisiones. | Código institucional no vacío (texto) | Obligatorio | Sí — PK individual | PK | Código institucional no vacío | Clave primaria obligatoria y única. RN-01; RN-02. Datos personales atómicos e identidad institucional; los contactos se registran aparte. | 1001 |
| ESTUDIANTE | nombre | Nombre propio del estudiante, separado de apellidos para evitar atributo compuesto indefinido. | Nombre personal no vacío | Obligatorio | No | Ninguna | Nombre personal no vacío | Dato obligatorio. RN-01; RN-02 | Ana |
| ESTUDIANTE | primer_apellido | Primer apellido del estudiante, registrado como dato personal propio. | Apellido no vacío | Obligatorio | No | Ninguna | Apellido no vacío | Dato obligatorio. RN-01; RN-02 | Solís |
| ESTUDIANTE | segundo_apellido | Segundo apellido, cuando conste en la identificación del estudiante. | Apellido o NULL | Opcional | No | Ninguna | Apellido o NULL | Valor opcional. RN-01; RN-02 | Vargas |


## ADMISION

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADMISION | id_admision | Identificador de una admisión particular del estudiante a carrera/sede/plan. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-02; RN-03; RN-09. La carrera procede de la versión del plan; sede habilitada y condición académica distinta de admisión activa. | 501 |
| ADMISION | numero_institucional | Estudiante titular de la admisión, que puede tener otras admisiones. | Código institucional del estudiante | Obligatorio | No | FK | Valor existente en ESTUDIANTE(numero_institucional) | Referencia obligatoria a relación existente. RN-02; RN-03; RN-09 | 1001 |
| ADMISION | id_sede | Sede asociada a la admisión; la carrera se deriva de la versión de plan. | Identificador entero de SEDE | Obligatorio | No | FK | Valor existente en SEDE(id_sede) | Integridad (carrera de versión,sede) contra CARRERA_SEDE también en UPDATE/DELETE. Integridad referencial. RN-02; RN-03; RN-09 | 1 |
| ADMISION | id_version_plan | Versión del plan actualmente asignada a esta admisión. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | No | FK | Valor existente en VERSION_PLAN_ESTUDIOS(id_version_plan) | Referencia obligatoria a relación existente. RN-02; RN-03; RN-09 | 102 |
| ADMISION | fecha_ingreso | Fecha en que comienza la trayectoria de esta admisión. | Fecha de calendario | Obligatorio | No | Ninguna | Fecha válida (AAAA-MM-DD) | Dato obligatorio. RN-02; RN-03; RN-09 | 2024-02-05 |
| ADMISION | condicion_academica | Condición académica informativa de la admisión; no se equipara automáticamente con actividad. | Texto de condición institucional no vacío | Obligatorio | No | Ninguna | Texto de condición institucional no vacío | Dato obligatorio. Condición académica institucional; no se fija un catálogo cerrado. RN-02; RN-03; RN-09 | regular |
| ADMISION | activa | Indicador independiente de habilitación de la admisión para presentar solicitudes. | Booleano verdadero/falso | Obligatorio | No | Ninguna | Verdadero; falso | Debe ser VERDADERO al resolver solicitud (G03-P02). NOT NULL. RN-02; RN-03; RN-09 | VERDADERO |


## CARRERA

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CARRERA | id_carrera | Identificador de carrera; catálogo curricular incluido en el catálogo curricular institucional. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-02; RN-03; RN-05. Identificador estable del catálogo curricular. | 10 |


## SEDE

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SEDE | id_sede | Identificador de la sede universitaria donde se ofrecen carreras y grupos. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-02; RN-07. La sede se referencia desde admisiones, ofertas y espacios. | 1 |
| SEDE | nombre | Denominación legible de la sede universitaria. | Texto no vacío | Obligatorio | No | Ninguna | Texto no vacío | Dato obligatorio. RN-02; RN-07 | Sede Central |


## VERSION_PLAN_ESTUDIOS

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VERSION_PLAN_ESTUDIOS | id_version_plan | Identificador estable de una versión concreta de plan de estudios. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-03; RN-05. Carrera estable y vigencia mediante fechas verificables, con fin opcional. | 101 |
| VERSION_PLAN_ESTUDIOS | id_carrera | Carrera a la que pertenece la versión del plan; su identidad histórica es estable. | Identificador entero de CARRERA | Obligatorio | No | FK | Valor existente en CARRERA(id_carrera) | Referencia obligatoria a relación existente. RN-03; RN-05 | 10 |
| VERSION_PLAN_ESTUDIOS | inicio_vigencia | Fecha desde la cual la versión es aplicable conforme a la cronología institucional. | Fecha de calendario | Obligatorio | No | Ninguna | Fecha válida (AAAA-MM-DD) | Dato obligatorio. RN-03; RN-05 | 2024-01-01 |
| VERSION_PLAN_ESTUDIOS | fin_vigencia | Fecha de fin de vigencia; NULL identifica un intervalo abierto hacia el futuro. | Fecha de calendario o NULL | Opcional | No | Ninguna | Fecha válida (AAAA-MM-DD) o NULL | Fecha final opcional; si existe debe ser ≥ inicio_vigencia. NULL permitido. RN-03; RN-05 | 2025-12-31 |


## PERIODO_ACADEMICO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PERIODO_ACADEMICO | id_periodo | Identificador interno de un periodo de oferta académica. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-09; RN-13. Código alternativo único y fechas lectivas; ventanas de matrícula, modificación y retiro separadas. | 20261 |
| PERIODO_ACADEMICO | codigo_periodo | Código de referencia única del periodo académico. | Código de periodo no vacío y único | Obligatorio | Sí — UNIQUE individual | Clave candidata (UQ) | Código de periodo único y no vacío | Dato obligatorio. Código académico alternativo único y obligatorio. RN-09; RN-13 | 2026-I |
| PERIODO_ACADEMICO | fecha_inicio | Primer día del periodo académico para actividad lectiva. | Fecha de calendario | Obligatorio | No | Ninguna | Fecha válida (AAAA-MM-DD) | Dato obligatorio. RN-09; RN-13 | 2026-02-02 |
| PERIODO_ACADEMICO | fecha_finalizacion | Último día del periodo académico lectivo. | Fecha de calendario | Obligatorio | No | Ninguna | Fecha válida (AAAA-MM-DD) | Debe ser ≥ fecha_inicio. NOT NULL. RN-09; RN-13 | 2026-06-12 |


## CURSO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CURSO | codigo_institucional | Código institucional estable que identifica la asignatura. | Código de curso no vacío (texto) | Obligatorio | Sí — PK individual | PK | Código de curso no vacío | Clave primaria obligatoria y única. RN-05; RN-06. Catálogo institucional con créditos no negativos y escuela administradora. | UH-PROG1 |
| CURSO | nombre | Denominación académica de la asignatura. | Texto no vacío | Obligatorio | No | Ninguna | Texto no vacío | Dato obligatorio. RN-05; RN-06 | Introducción a la Programación |
| CURSO | cantidad_creditos | Cantidad de créditos académicos asignados al curso. | Entero ≥ 0, unidad: créditos | Obligatorio | No | Ninguna | Enteros ≥ 0, unidad: créditos | Dato obligatorio. RN-05; RN-06 | 4 |
| CURSO | id_escuela | Escuela que administra académicamente el curso. | Identificador entero de ESCUELA | Obligatorio | No | FK | Valor existente en ESCUELA(id_escuela) | Referencia obligatoria a relación existente. RN-05; RN-06 | 1 |


## ESCUELA

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ESCUELA | id_escuela | Identificador de la escuela responsable del catálogo institucional de cursos. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-05. Catálogo de escuelas referenciado por CURSO. | 1 |


## GRUPO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GRUPO | id_grupo | Identificador global de un grupo ofertado. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-07; RN-08; RN-10; RN-16; RN-19. Oferta con cupo, docentes, sede, modalidad y estado; ocupación y modificación de cupos transaccionales. | 801 |
| GRUPO | numero_grupo | Número local de la oferta de un curso en periodo y sede. | Identificador numérico local | Obligatorio | Solo UQ conjunta (id_periodo, id_sede, codigo_curso, numero_grupo) | Ninguna | Identificador entero válido | UQ(periodo,sede,curso,número) es supuesto local. NOT NULL. Unicidad local adoptada para (id_periodo, id_sede, codigo_curso, numero_grupo). RN-07; RN-08; RN-10; RN-16; RN-19 | 1 |
| GRUPO | codigo_curso | Curso institucional que se imparte en este grupo. | Código institucional de CURSO | Obligatorio | Solo UQ conjunta (id_periodo, id_sede, codigo_curso, numero_grupo) | FK | Valor existente en CURSO(codigo_institucional) | Referencia obligatoria a relación existente. RN-07; RN-08; RN-10; RN-16; RN-19 | UH-PROG2 |
| GRUPO | id_periodo | Periodo académico en el que se ofrece el grupo. | Identificador entero de PERIODO_ACADEMICO | Obligatorio | Solo UQ conjunta (id_periodo, id_sede, codigo_curso, numero_grupo) | FK | Valor existente en PERIODO_ACADEMICO(id_periodo) | Referencia obligatoria a relación existente. RN-07; RN-08; RN-10; RN-16; RN-19 | 20261 |
| GRUPO | id_sede | Sede donde se ofrece el grupo. | Identificador entero de SEDE | Obligatorio | Solo UQ conjunta (id_periodo, id_sede, codigo_curso, numero_grupo) | FK | Valor existente en SEDE(id_sede) | Referencia obligatoria a relación existente. RN-07; RN-08; RN-10; RN-16; RN-19 | 1 |
| GRUPO | capacidad | Cantidad de cupos disponibles como capacidad nominal de oferta, no ocupación actual. | Entero ≥ 0, unidad: cupos | Obligatorio | No | Ninguna | Enteros ≥ 0, unidad: cupos | CHECK(capacidad >= 0); no disminuir bajo ocupación matriculada. NOT NULL. RN-07; RN-08; RN-10; RN-16; RN-19 | 28 |
| GRUPO | modalidad | Modalidad general de impartición; los bloques individuales conservan su presencialidad. | Enumeración {presencial, virtual, mixta} | Obligatorio | No | Ninguna | presencial; virtual; mixta | Dato obligatorio. Modalidades admitidas: presencial, virtual y mixta. RN-07; RN-08; RN-10; RN-16; RN-19 | mixta |
| GRUPO | estado_oferta | Estado actual de disponibilidad administrativa de la oferta. | Enumeración {abierta, cerrada, cancelada} | Obligatorio | No | Ninguna | abierta; cerrada; cancelada | Cambios relevantes deben registrar HISTORIAL_OFERTA. NOT NULL. Publicación requiere exactamente un docente responsable y al menos un bloque horario. RN-07; RN-08; RN-10; RN-16; RN-19 | abierta |


## BLOQUE_HORARIO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BLOQUE_HORARIO | id_bloque | Identificador de una franja individual programada para un grupo. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-07; RN-10. Intervalo horario válido y espacio obligatorio para actividad presencial; sin uso simultáneo del espacio. | 4001 |
| BLOQUE_HORARIO | id_grupo | Grupo al que pertenece este bloque de horario. | Identificador entero de GRUPO | Obligatorio | No | FK | Valor existente en GRUPO(id_grupo) | Referencia obligatoria a relación existente. RN-07; RN-10 | 801 |
| BLOQUE_HORARIO | dia_semana | Día semanal recurrente en el que ocurre la actividad. | Entero 1–7 (lunes=1; convención) | Obligatorio | No | Ninguna | 1 a 7 (lunes = 1; domingo = 7) | Dato obligatorio. Convención de días: lunes = 1 y domingo = 7. RN-07; RN-10 | 1 |
| BLOQUE_HORARIO | hora_inicio | Hora del día en que empieza la actividad del bloque. | Hora local (HH:MM:SS) | Obligatorio | No | Ninguna | Hora válida (HH:MM:SS) | Dato obligatorio. RN-07; RN-10 | 09:00:00 |
| BLOQUE_HORARIO | hora_fin | Hora del día en que finaliza la actividad. | Hora local (HH:MM:SS) | Obligatorio | No | Ninguna | Hora válida (HH:MM:SS) | CHECK(hora_inicio < hora_fin), franjas [inicio,fin). NOT NULL. RN-07; RN-10 | 10:30:00 |
| BLOQUE_HORARIO | es_presencial | Especifica si este bloque, independientemente de la modalidad general, requiere espacio físico. | Booleano verdadero/falso | Obligatorio | No | Ninguna | Verdadero; falso | Si VERDADERO requiere id_espacio y sede del grupo. NOT NULL. RN-07; RN-10 | VERDADERO |
| BLOQUE_HORARIO | id_espacio | Espacio asignado cuando se realiza una sesión presencial. | Identificador entero de ESPACIO o NULL | Opcional | No | FK | Valor existente en ESPACIO(id_espacio) o NULL, según la condición aplicable | Obligatorio si es_presencial; sin ocupación simultánea del espacio, incluso entre periodos coincidentes. Integridad referencial. RN-07; RN-10 | 101 |


## ESPACIO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ESPACIO | id_espacio | Identificador de un espacio físico que puede asignarse a bloques. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-07; G03-P01. Capacidad positiva; espacio localizado en sede y sin asignaciones temporales incompatibles. | 101 |
| ESPACIO | id_sede | Sede física donde se ubica el espacio. | Identificador entero de SEDE | Obligatorio | No | FK | Valor existente en SEDE(id_sede) | Referencia obligatoria a relación existente. RN-07; G03-P01 | 1 |
| ESPACIO | capacidad | Número máximo de personas admitidas físicamente en el espacio. | Entero > 0, unidad: personas | Obligatorio | No | Ninguna | Enteros > 0, unidad: personas | CHECK(capacidad > 0); unidad personas. NOT NULL. RN-07; G03-P01 | 35 |
| ESPACIO | ubicacion | Referencia interna para localizar el espacio en la sede. | Texto no vacío | Obligatorio | No | Ninguna | Texto no vacío | Dato obligatorio. RN-07; G03-P01 | Edificio A, aula 203 |


## SOLICITUD_MATRICULA

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SOLICITUD_MATRICULA | id_solicitud | Identificador persistente de una solicitud específica de matrícula o cambio. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-09 a RN-14; RN-16; RN-18; RN-20. Estado e historial diferenciados, versión evaluada conservada y cupos; no se admiten matrículas activas duplicadas. | 6001 |
| SOLICITUD_MATRICULA | id_admision | Admisión desde la que la persona solicita el grupo. | Identificador entero de ADMISION | Obligatorio | No | FK | Valor existente en ADMISION(id_admision) | Referencia obligatoria a relación existente. RN-09 a RN-14; RN-16; RN-18; RN-20 | 501 |
| SOLICITUD_MATRICULA | id_grupo | Grupo solicitado para una admisión determinada. | Identificador entero de GRUPO | Obligatorio | No | FK | Valor existente en GRUPO(id_grupo) | Referencia obligatoria a relación existente. RN-09 a RN-14; RN-16; RN-18; RN-20 | 801 |
| SOLICITUD_MATRICULA | id_solicitud_anterior | Solicitud anterior a la que queda vinculado un cambio de grupo. | Identificador entero de SOLICITUD_MATRICULA o NULL | Opcional | No | FK | Valor existente en SOLICITUD_MATRICULA(id_solicitud) o NULL, según la condición aplicable | Referencia obligatoria a relación existente. RN-09 a RN-14; RN-16; RN-18; RN-20 | NULL |
| SOLICITUD_MATRICULA | id_version_plan_evaluada | Versión curricular utilizada al decidir la solicitud; no cambia tras futuros traslados. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | No | FK | Valor existente en VERSION_PLAN_ESTUDIOS(id_version_plan) | Plan fijado al decidir; no recomputar desde ADMISION tras traslado. Integridad referencial. RN-09 a RN-14; RN-16; RN-18; RN-20 | 101 |
| SOLICITUD_MATRICULA | fecha_solicitud | Instante en que se presenta la solicitud al sistema. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Dato obligatorio. RN-09 a RN-14; RN-16; RN-18; RN-20 | 2026-01-18 09:15:00-06 |
| SOLICITUD_MATRICULA | estado | Resultado operativo actual de la solicitud dentro del ciclo de matrícula. | Enumeración {matriculada, rechazada, en_espera, retirada, anulada} | Obligatorio | No | Ninguna | matriculada; rechazada; en_espera; retirada; anulada | Cinco estados cerrados RN-11; solo matriculada consume cupo. NOT NULL. Solo el estado matriculada consume cupo; las transiciones se documentan en HISTORIAL_SOLICITUD. RN-09 a RN-14; RN-16; RN-18; RN-20 | matriculada |
| SOLICITUD_MATRICULA | razon_rechazo_espera | Motivo del rechazo o de ingreso en lista de espera, conservable después de una promoción. | Texto no vacío o NULL condicionado | Opcional | No | Ninguna | Texto no vacío o NULL según estado | Obligatorio si rechazada o en_espera; no ocultar motivos. NULL permitido. RN-09 a RN-14; RN-16; RN-18; RN-20 | Sin cupo disponible |
| SOLICITUD_MATRICULA | orden_espera | Número de orden persistido para solicitudes ingresadas a la espera del grupo. | Entero positivo o NULL | Opcional | No | Ninguna | Entero positivo o NULL | Asignar al ingresar a espera y conservar para reconstrucción histórica. NULL permitido. RN-09 a RN-14; RN-16; RN-18; RN-20 | 1 |
| SOLICITUD_MATRICULA | momento_transicion | Instante en que la solicitud pasa de espera a matrícula, cuando ocurra. | Marca temporal con zona o NULL | Opcional | No | Ninguna | Fecha y hora válidas con zona horaria o NULL | Conservar instante de promoción espera → matrícula. NULL permitido. RN-09 a RN-14; RN-16; RN-18; RN-20 | 2026-01-18 11:30:00-06 |
| SOLICITUD_MATRICULA | calificacion | Valor de evaluación final aplicable a la matrícula; escala depende del curso o modalidad. | Texto de escala aplicable o NULL | Opcional | No | Ninguna | Calificación según escala aplicable o NULL | Solo en solicitud que alcanzó matrícula; escala contextual. NULL permitido. RN-09 a RN-14; RN-16; RN-18; RN-20 | 85 |
| SOLICITUD_MATRICULA | resultado_academico | Resultado de la matrícula evaluada al cierre del periodo. | Enumeración {aprobado, reprobado, incompleto, retiro_justificado} o NULL | Opcional | No | Ninguna | aprobado; reprobado; incompleto; retiro_justificado; NULL | Valor opcional. RN-09 a RN-14; RN-16; RN-18; RN-20 | aprobado |


## DOCENTE

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DOCENTE | id_docente | Identificador de una persona docente participante en la oferta. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-07; G03-P01. Un docente puede participar en varios grupos; la responsabilidad se valida al publicar. | 301 |
| DOCENTE | nombre | Nombre del docente que imparte o coordina grupos. | Nombre no vacío | Obligatorio | No | Ninguna | Nombre no vacío | Dato obligatorio. RN-07; G03-P01 | Carlos Pérez |


## CARRERA_SEDE

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CARRERA_SEDE | id_carrera | Carrera ofrecida en la combinación registrada de carrera y sede. | Identificador entero de CARRERA | Obligatorio | Solo PK conjunta (id_carrera, id_sede) | PK/FK compuesta | Valor existente en CARRERA(id_carrera) | Clave primaria obligatoria y única. RN-02; RN-03. Asociación de habilitación de carrera y sede identificada por PK compuesta. | 10 |
| CARRERA_SEDE | id_sede | Sede habilitada para ofrecer la carrera de esta asociación. | Identificador entero de SEDE | Obligatorio | Solo PK conjunta (id_carrera, id_sede) | PK/FK compuesta | Valor existente en SEDE(id_sede) | Clave primaria obligatoria y única. RN-02; RN-03 | 1 |


## PARTICIPACION_PLAN

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PARTICIPACION_PLAN | codigo_curso | Curso que figura en una versión de plan de estudios. | Código institucional de CURSO | Obligatorio | Solo PK conjunta (codigo_curso, id_version_plan) | PK/FK compuesta | Valor existente en CURSO(codigo_institucional) | Clave primaria obligatoria y única. RN-05. Asociación curso–versión con tipo obligatorio u optativo y nivel recomendado textual opcional. | UH-PROG1 |
| PARTICIPACION_PLAN | id_version_plan | Versión en la que figura este curso y se define su participación. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | Solo PK conjunta (codigo_curso, id_version_plan) | PK/FK compuesta | Valor existente en VERSION_PLAN_ESTUDIOS(id_version_plan) | Clave primaria obligatoria y única. RN-05 | 101 |
| PARTICIPACION_PLAN | tipo_participacion | Determina si el curso es obligatorio u optativo dentro de la versión. | Enumeración {Obligatorio, Optativo} | Obligatorio | No | Ninguna | Obligatorio; Optativo | Dato obligatorio. RN-05 | Obligatorio |
| PARTICIPACION_PLAN | nivel_o_periodo_recomendado | Nivel o periodo recomendado para cursar esta asignatura en la versión; se registra como texto opcional. | Texto opcional, nivel o periodo recomendado | Opcional | No | Ninguna | Texto descriptivo o NULL | Texto opcional; no restringir a entero. NULL permitido. RN-05 | 1 |


## REQUISITO_CURSO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQUISITO_CURSO | id_version_plan | Versión del plan para la que se declara la regla curricular. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | Solo PK conjunta (id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito) | PK/FK compuesta | Valor existente en VERSION_PLAN_ESTUDIOS(id_version_plan) | Clave primaria obligatoria y única. RN-05; RN-06; RN-15. Regla diferenciada por versión, curso objetivo, curso exigido y tipo; las referencias a CURSO no exigen participación en el plan. | 101 |
| REQUISITO_CURSO | codigo_curso_objetivo | Curso cuya matrícula está sujeta a esta regla curricular. | Código institucional de CURSO | Obligatorio | Solo PK conjunta (id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito) | PK/FK compuesta | Valor existente en CURSO(codigo_institucional) | FK a CURSO; No exigir que el curso objetivo participe en el plan. PK no nula. El curso objetivo referencia CURSO; no se exige que participe en la versión. RN-05; RN-06; RN-15 | UH-PROG2 |
| REQUISITO_CURSO | codigo_curso_exigido | Curso que debe haberse aprobado o que cumple función de correquisito. | Código institucional de CURSO | Obligatorio | Solo PK conjunta (id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito) | PK/FK compuesta | Valor existente en CURSO(codigo_institucional) | FK a CURSO; exigido puede no participar en versión. PK no nula. El curso exigido referencia CURSO; puede no participar en la versión. RN-05; RN-06; RN-15 | UH-PROG1 |
| REQUISITO_CURSO | tipo_requisito | Distingue requisito previo de correquisito para el curso objetivo. | Enumeración {Requisito previo, Correquisito} | Obligatorio | Solo PK conjunta (id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito) | PK | Requisito previo; Correquisito | Clave primaria obligatoria y única. RN-05; RN-06; RN-15 | Requisito previo |
| REQUISITO_CURSO | id_requisito | Clave alternativa generada para identificar la regla completa sin repetir su clave compuesta en excepciones. | Identificador interno entero, UNIQUE, NN | Obligatorio | Sí — UNIQUE individual | Clave candidata (UQ) | Identificador entero válido | UNIQUE NOT NULL, valor generado automáticamente; generación automática sin exigir un quinto valor al registrar la regla. NOT NULL. Identificador alternativo único, no nulo y generado automáticamente; conserva la PK compuesta. RN-05; RN-06; RN-15 | 9001 |


## TRASLADO_PLAN

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TRASLADO_PLAN | id_traslado | Identificador de un evento de traslado de versión del plan de una admisión. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-03. Versiones distintas de la misma carrera; origen vigente, destino y autorización registrados históricamente. | 601 |
| TRASLADO_PLAN | id_admision | Admisión cuya versión de plan se modifica en este evento. | Identificador entero de ADMISION | Obligatorio | No | FK | Valor existente en ADMISION(id_admision) | Referencia obligatoria a relación existente. RN-03 | 501 |
| TRASLADO_PLAN | id_version_origen | Versión previamente asignada antes del traslado. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | No | FK | Valor existente en VERSION_PLAN_ESTUDIOS(id_version_plan) | Debe coincidir con versión vigente anterior de admisión. Integridad referencial. RN-03 | 101 |
| TRASLADO_PLAN | id_version_destino | Versión asignada a partir del traslado. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | No | FK | Valor existente en VERSION_PLAN_ESTUDIOS(id_version_plan) | Distinto de origen; misma carrera de admisión. Integridad referencial. RN-03 | 102 |
| TRASLADO_PLAN | fecha | Instante en que se registra y hace efectivo el traslado, conservando fecha calendario. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Dato obligatorio. RN-03 | 2026-07-15 10:00:00-06 |
| TRASLADO_PLAN | motivo | Razón institucional documentada para autorizar el traslado. | Texto no vacío | Obligatorio | No | Ninguna | Texto no vacío | Dato obligatorio. RN-03 | Actualización curricular autorizada |
| TRASLADO_PLAN | id_autorizador | Persona institucional que aprobó el traslado. | Identificador entero de PERSONA_AUTORIZADORA | Obligatorio | No | FK | Valor existente en PERSONA_AUTORIZADORA(id_autorizador) | Referencia obligatoria a relación existente. RN-03 | 41 |


## RECONOCIMIENTO_ACADEMICO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RECONOCIMIENTO_ACADEMICO | id_reconocimiento | Identificador de una resolución individual de reconocimiento académico. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-04; RN-18. Resolución temporal vinculada a admisión y versión; curso satisfecho propio del plan y origen identificado de forma excluyente. | 701 |
| RECONOCIMIENTO_ACADEMICO | id_admision | Admisión beneficiaria del reconocimiento; evita mezclar planes de un mismo estudiante. | Identificador entero de ADMISION | Obligatorio | No | FK | Valor existente en ADMISION(id_admision) | Referencia obligatoria a relación existente. RN-04; RN-18 | 501 |
| RECONOCIMIENTO_ACADEMICO | referencia_curso_reconocido | Referencia del curso reconocido cuando procede de otra institución y no figura en el catálogo institucional. | Texto de referencia externa no vacío, o NULL | Opcional | No | Ninguna | Referencia externa no vacía o NULL | Debe existir exactamente una identificación del curso reconocido: referencia externa o codigo_curso_reconocido FK a CURSO (XOR). RN-04; RN-18. Referencia externa cuando no existe código de curso institucional; excluyente respecto de codigo_curso_reconocido | EXT-MAT101 |
| RECONOCIMIENTO_ACADEMICO | codigo_curso_reconocido | Código institucional del curso reconocido, cuando el curso de origen pertenece a Universidad Horizonte. | Código institucional de CURSO o NULL | Opcional | No | FK | Valor existente en CURSO(codigo_institucional) o NULL, según la condición aplicable | Si el curso reconocido es institucional se exige FK válida a CURSO y referencia externa NULL; en origen externo se exige el caso contrario (XOR). RN-04; RN-18. | NULL |
| RECONOCIMIENTO_ACADEMICO | id_version_plan | Versión del plan en cuyo contexto se otorga el reconocimiento. | Identificador entero de VERSION_PLAN_ESTUDIOS | Obligatorio | No | FK | Combinación existente en PARTICIPACION_PLAN(codigo_curso,id_version_plan) | Versión histórica de la admisión en la resolución; FK compuesta. NOT NULL. RN-04; RN-18 | 101 |
| RECONOCIMIENTO_ACADEMICO | codigo_curso_satisfecho | Curso de la versión cuya exigencia se considera satisfecha por reconocimiento. | Código institucional de CURSO | Obligatorio | No | FK | Combinación existente en PARTICIPACION_PLAN(codigo_curso,id_version_plan) | FK compuesta versión/curso a PARTICIPACION_PLAN. NOT NULL. RN-04; RN-18 | UH-MAT1 |
| RECONOCIMIENTO_ACADEMICO | resolucion_academica | Referencia a la resolución oficial que respalda la decisión de reconocimiento. | Referencia documental no vacía | Obligatorio | No | Ninguna | Referencia documental no vacía | Dato obligatorio. RN-04; RN-18 | RES-2024-015 |
| RECONOCIMIENTO_ACADEMICO | fecha_resolucion | Instante de emisión de la resolución académica, con fecha y hora, necesario para determinar el plan aplicable ante traslados del mismo día. | Marca temporal con zona horaria | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Conservar orden temporal verificable de resolución y traslados de la misma admisión. RN-03; RN-04; RN-18. | 2024-06-12 10:00:00-06 |


## GRUPO_DOCENTE

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GRUPO_DOCENTE | id_grupo | Grupo donde participa el docente con el rol registrado. | Identificador entero de GRUPO | Obligatorio | Solo PK conjunta (id_grupo, id_docente) | PK/FK compuesta | Valor existente en GRUPO(id_grupo) | Clave primaria obligatoria y única. G03-P01. Como máximo un responsable por grupo; exactamente uno al publicar. | 801 |
| GRUPO_DOCENTE | id_docente | Docente que tiene el rol indicado en ese grupo. | Identificador entero de DOCENTE | Obligatorio | Solo PK conjunta (id_grupo, id_docente) | PK/FK compuesta | Valor existente en DOCENTE(id_docente) | Clave primaria obligatoria y única. G03-P01 | 301 |
| GRUPO_DOCENTE | rol | Clasifica a la persona docente como responsable o adicional. | Enumeración {responsable, adicional} | Obligatorio | No | Ninguna | responsable; adicional | Máximo un responsable/grupo y exactamente uno al publicar. NOT NULL. G03-P01 | responsable |


## CONTACTO_ESTUDIANTE

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CONTACTO_ESTUDIANTE | id_contacto | Identificador interno de una ocurrencia de contacto; permite varios por estudiante. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-01. Contactos repetibles con terna (estudiante, tipo, valor) única y como máximo uno principal por tipo. | 31 |
| CONTACTO_ESTUDIANTE | numero_institucional | Estudiante titular del medio de contacto. | Código institucional del estudiante | Obligatorio | Solo UQ conjunta (numero_institucional, tipo_contacto, valor) | FK | Valor existente en ESTUDIANTE(numero_institucional) | Referencia obligatoria a relación existente. RN-01 | 1001 |
| CONTACTO_ESTUDIANTE | tipo_contacto | Clase del medio de contacto utilizado para comunicarse con el estudiante. | Texto de tipo de contacto; p. ej. correo/teléfono | Obligatorio | Solo UQ conjunta (numero_institucional, tipo_contacto, valor) | Ninguna | Tipo de contacto no vacío (p. ej., correo o teléfono) | Dato obligatorio. Tipos de contacto admitidos conforme a la convención institucional. RN-01 | correo |
| CONTACTO_ESTUDIANTE | valor | Dirección o número concreto del medio de contacto declarado. | Texto no vacío acorde al tipo de contacto | Obligatorio | Solo UQ conjunta (numero_institucional, tipo_contacto, valor) | Ninguna | Texto no vacío acorde al tipo de contacto | Dato obligatorio. RN-01 | ana.solis@example.org |
| CONTACTO_ESTUDIANTE | es_principal | Indica si este es el contacto prioritario dentro de su tipo para el estudiante. | Booleano verdadero/falso | Obligatorio | No | Ninguna | Verdadero; falso | ÚNICO parcial por estudiante/tipo cuando VERDADERO; NOT NULL. RN-01 | VERDADERO |


## PERSONA_AUTORIZADORA

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PERSONA_AUTORIZADORA | id_autorizador | Identificador interno de una persona institucional responsable de autorizaciones. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-03; RN-15; RN-17; RN-19. Autorización institucional con identidad alternativa única. | 41 |
| PERSONA_AUTORIZADORA | nombre | Nombre de la persona que figura como autorizante o responsable en eventos. | Nombre no vacío | Obligatorio | No | Ninguna | Nombre no vacío | Dato obligatorio. RN-03; RN-15; RN-17; RN-19 | María Calderón |
| PERSONA_AUTORIZADORA | identificacion_institucional | Credencial institucional única de la persona autorizadora. | Código institucional no vacío y único | Obligatorio | Sí — UNIQUE individual | Clave candidata (UQ) | Código institucional único y no vacío | Dato obligatorio. Identificación institucional única y obligatoria. RN-03; RN-15; RN-17; RN-19 | AUT-041 |


## VENTANA_PERIODO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VENTANA_PERIODO | id_ventana | Identificador de una ventana concreta de operación académica. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-09; RN-13; RN-14. Intervalos [inicio, fin) válidos y sin solapamientos ambiguos. | 901 |
| VENTANA_PERIODO | id_periodo | Periodo al que pertenece la ventana operativa. | Identificador entero de PERIODO_ACADEMICO | Obligatorio | No | FK | Valor existente en PERIODO_ACADEMICO(id_periodo) | Referencia obligatoria a relación existente. RN-09; RN-13; RN-14 | 20261 |
| VENTANA_PERIODO | tipo_ventana | Operación autorizada durante el intervalo: matrícula, modificación o retiro. | Enumeración {matricula, modificacion, retiro} | Obligatorio | No | Ninguna | matricula; modificacion; retiro | Dato obligatorio. RN-09; RN-13; RN-14 | matricula |
| VENTANA_PERIODO | inicio | Instante inicial incluido del intervalo de operación. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Dato obligatorio. RN-09; RN-13; RN-14 | 2026-01-15 08:00:00-06 |
| VENTANA_PERIODO | fin | Instante final excluido del intervalo de operación. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Debe ser > inicio; fin excluido; evitar ventana ambiguamente solapada. NOT NULL. RN-09; RN-13; RN-14 | 2026-01-20 17:00:00-06 |


## HISTORIAL_OFERTA

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| HISTORIAL_OFERTA | id_cambio | Identificador de un cambio persistido en la oferta de un grupo. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-08; RN-19. Conserva eventos reales y valores anteriores o nuevos pertinentes, con motivo, instante y responsable. | 5101 |
| HISTORIAL_OFERTA | id_grupo | Grupo cuyo estado o cupo fue modificado. | Identificador entero de GRUPO | Obligatorio | No | FK | Valor existente en GRUPO(id_grupo) | Referencia obligatoria a relación existente. RN-08; RN-19 | 801 |
| HISTORIAL_OFERTA | tipo_cambio | Clase de modificación: apertura, cierre, cancelación o cambio de cupo. | Enumeración {apertura, cierre, cancelacion, cambio_cupo} | Obligatorio | No | Ninguna | apertura; cierre; cancelacion; cambio_cupo | Dato obligatorio. RN-08; RN-19 | cambio_cupo |
| HISTORIAL_OFERTA | estado_anterior | Estado de oferta antes del cambio, cuando el evento modifica estado. | Estado oferta o NULL | Opcional | No | Ninguna | abierta; cerrada; cancelada; NULL | Requerido si cambio de estado; NULL si no aplica. NULL permitido. RN-08; RN-19 | NULL |
| HISTORIAL_OFERTA | estado_nuevo | Estado de oferta resultante del evento, cuando cambia estado. | Estado oferta o NULL | Opcional | No | Ninguna | abierta; cerrada; cancelada; NULL | Requerido si cambio de estado; distinto de anterior. NULL permitido. RN-08; RN-19 | NULL |
| HISTORIAL_OFERTA | cupo_anterior | Capacidad del grupo antes del evento de modificación de cupo. | Entero ≥ 0 (cupos) o NULL | Opcional | No | Ninguna | Enteros ≥ 0 (cupos) o NULL | Requerido si cambio_cupo; NULL si no aplica. NULL permitido. RN-08; RN-19 | 30 |
| HISTORIAL_OFERTA | cupo_nuevo | Capacidad del grupo después del evento de modificación de cupo. | Entero ≥ 0 (cupos) o NULL | Opcional | No | Ninguna | Enteros ≥ 0 (cupos) o NULL | Requerido si cambio_cupo; distinto de anterior. NULL permitido. RN-08; RN-19 | 28 |
| HISTORIAL_OFERTA | fecha_cambio | Instante verificable de ejecución del cambio de oferta. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Dato obligatorio. RN-08; RN-19 | 2026-02-01 11:00:00-06 |
| HISTORIAL_OFERTA | motivo | Explicación obligatoria del cambio administrativo registrado. | Texto no vacío | Obligatorio | No | Ninguna | Texto no vacío | Dato obligatorio. RN-08; RN-19 | Ajuste de capacidad por disponibilidad |
| HISTORIAL_OFERTA | id_responsable | Persona institucional responsable del cambio. | Identificador entero de PERSONA_AUTORIZADORA | Obligatorio | No | FK | Valor existente en PERSONA_AUTORIZADORA(id_autorizador) | Referencia obligatoria a relación existente. RN-08; RN-19 | 41 |


## HISTORIAL_SOLICITUD

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| HISTORIAL_SOLICITUD | id_evento | Identificador de un evento histórico asociado a una solicitud. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-11; RN-12; RN-13; RN-14. Conserva transiciones y evaluaciones de espera, sin eventos vacíos. | 7001 |
| HISTORIAL_SOLICITUD | id_solicitud | Solicitud cuyo estado o elegibilidad fue examinado. | Identificador entero de SOLICITUD_MATRICULA | Obligatorio | No | FK | Valor existente en SOLICITUD_MATRICULA(id_solicitud) | Referencia obligatoria a relación existente. RN-11; RN-12; RN-13; RN-14 | 6001 |
| HISTORIAL_SOLICITUD | tipo_evento | Diferencia una transición efectiva de la evaluación de alguien en espera. | Enumeración {transicion, evaluacion_espera} | Obligatorio | No | Ninguna | transicion; evaluacion_espera | Transición cambia estado; evaluación_espera requiere motivo si omite. NOT NULL. RN-11; RN-12; RN-13; RN-14 | transicion |
| HISTORIAL_SOLICITUD | estado_anterior | Estado que tenía la solicitud antes de una transición, si aplica. | Estado de solicitud o NULL | Opcional | No | Ninguna | matriculada; rechazada; en_espera; retirada; anulada; NULL | Valor opcional. RN-11; RN-12; RN-13; RN-14 | en_espera |
| HISTORIAL_SOLICITUD | estado_nuevo | Estado después de una transición; puede quedar NULL en mera evaluación. | Estado de solicitud o NULL | Opcional | No | Ninguna | matriculada; rechazada; en_espera; retirada; anulada; NULL | Opcional en evaluación sin transición; exigido al cambiar estado. NULL permitido. RN-11; RN-12; RN-13; RN-14 | matriculada |
| HISTORIAL_SOLICITUD | fecha_evento | Instante en que ocurrió la transición o evaluación de elegibilidad. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Dato obligatorio. RN-11; RN-12; RN-13; RN-14 | 2026-01-18 11:30:00-06 |
| HISTORIAL_SOLICITUD | motivo | Explicación del evento, obligatoria cuando se omite un candidato no elegible. | Texto justificativo o NULL | Opcional | No | Ninguna | Texto justificativo o NULL | Valor opcional. RN-11; RN-12; RN-13; RN-14 | Cupo liberado y elegibilidad verificada |
| HISTORIAL_SOLICITUD | id_actor | Autor institucional identificado cuando la acción es administrativa; NULL en otras acciones. | Identificador entero de PERSONA_AUTORIZADORA o NULL | Opcional | No | FK | Valor existente en PERSONA_AUTORIZADORA(id_autorizador) o NULL, según la condición aplicable | Referencia obligatoria a relación existente. RN-11; RN-12; RN-13; RN-14 | 41 |


## EXCEPCION_REQUISITO

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EXCEPCION_REQUISITO | id_excepcion | Identificador del acto individual que autoriza apartarse de un requisito. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-15; G03-P02. Cada excepción identifica una regla completa y una solicitud compatibles, con motivo y autorizante. | 8001 |
| EXCEPCION_REQUISITO | id_solicitud | Solicitud académica para la que se concede esta excepción. | Identificador entero de SOLICITUD_MATRICULA | Obligatorio | No | FK | Valor existente en SOLICITUD_MATRICULA(id_solicitud) | Referencia obligatoria a relación existente. RN-15; G03-P02 | 6001 |
| EXCEPCION_REQUISITO | id_requisito | Regla curricular exacta cuya aplicación se exceptúa; clave alternativa de REQUISITO_CURSO. | Identificador entero de REQUISITO_CURSO | Obligatorio | No | FK | Valor existente en REQUISITO_CURSO(id_requisito) | FK a REQUISITO_CURSO.id_requisito; confirmar curso objetivo y versión de solicitud. Integridad referencial. RN-15; G03-P02 | 9001 |
| EXCEPCION_REQUISITO | id_autorizador | Persona responsable de aprobar la excepción a la regla. | Identificador entero de PERSONA_AUTORIZADORA | Obligatorio | No | FK | Valor existente en PERSONA_AUTORIZADORA(id_autorizador) | Referencia obligatoria a relación existente. RN-15; G03-P02 | 41 |
| EXCEPCION_REQUISITO | fecha_autorizacion | Instante de autorización de la excepción antes de resolver matrícula. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Dato obligatorio. RN-15; G03-P02 | 2026-01-18 09:30:00-06 |
| EXCEPCION_REQUISITO | motivo | Fundamento académico de la excepción otorgada. | Texto justificativo no vacío | Obligatorio | No | Ninguna | Texto justificativo no vacío | Dato obligatorio. RN-15; G03-P02 | Excepción autorizada por resolución |


## HISTORIAL_CORRECCION_CALIFICACION

| Relación o entidad | Nombre | Descripción | Dominio o tipo conceptual | Obligatoriedad | Unicidad | Clave | Valores permitidos | Regla o restricción | Ejemplo |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| HISTORIAL_CORRECCION_CALIFICACION | id_correccion | Identificador de un evento de modificación de calificación o resultado. | Identificador entero interno | Obligatorio | Sí — PK individual | PK | Identificador entero válido | Clave primaria obligatoria y única. RN-17; RN-20. Rectificación real con valores anterior y nuevo, instante, motivo y autorizante. | 9101 |
| HISTORIAL_CORRECCION_CALIFICACION | id_solicitud | Solicitud que llegó a matrícula y cuyo resultado fue rectificado. | Identificador entero de SOLICITUD_MATRICULA | Obligatorio | No | FK | Valor existente en SOLICITUD_MATRICULA(id_solicitud) | Referencia obligatoria a relación existente. RN-17; RN-20 | 6001 |
| HISTORIAL_CORRECCION_CALIFICACION | calificacion_anterior | Valor de evaluación antes de la rectificación, si esa magnitud cambió. | Texto de escala aplicable o NULL | Opcional | No | Ninguna | Calificación según escala aplicable o NULL | Valor opcional. RN-17; RN-20 | 70 |
| HISTORIAL_CORRECCION_CALIFICACION | calificacion_nueva | Valor de evaluación corregido según la escala propia del curso. | Texto de escala aplicable o NULL | Opcional | No | Ninguna | Calificación según escala aplicable o NULL | Debe existir valor anterior y nuevo cuando cambie nota. NULL permitido. RN-17; RN-20 | 85 |
| HISTORIAL_CORRECCION_CALIFICACION | resultado_anterior | Resultado académico registrado antes de la rectificación. | Resultado académico o NULL | Opcional | No | Ninguna | aprobado; reprobado; incompleto; retiro_justificado; NULL | Valor opcional. RN-17; RN-20 | reprobado |
| HISTORIAL_CORRECCION_CALIFICACION | resultado_nuevo | Resultado académico después de aplicar la corrección autorizada. | Resultado académico o NULL | Opcional | No | Ninguna | aprobado; reprobado; incompleto; retiro_justificado; NULL | Debe existir resultado anterior/nuevo si cambia resultado. NULL permitido. RN-17; RN-20 | aprobado |
| HISTORIAL_CORRECCION_CALIFICACION | fecha_correccion | Instante efectivo de registro de la rectificación académica. | Marca temporal con zona | Obligatorio | No | Ninguna | Fecha y hora válidas con zona horaria | Corrección y estado persistidos en la misma transacción. NOT NULL. RN-17; RN-20 | 2026-06-25 10:00:00-06 |
| HISTORIAL_CORRECCION_CALIFICACION | motivo | Explicación documentada que justifica el cambio de calificación o resultado. | Texto justificativo no vacío | Obligatorio | No | Ninguna | Texto justificativo no vacío | Dato obligatorio. RN-17; RN-20 | Rectificación por error de registro |
| HISTORIAL_CORRECCION_CALIFICACION | id_autorizador | Persona institucional que autorizó la modificación del resultado. | Identificador entero de PERSONA_AUTORIZADORA | Obligatorio | No | FK | Valor existente en PERSONA_AUTORIZADORA(id_autorizador) | Referencia obligatoria a relación existente. RN-17; RN-20 | 41 |
