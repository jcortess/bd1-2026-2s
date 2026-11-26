# Control de cambios — Universidad Horizonte / Grupo 03

## 1. Identificación y versiones de referencia

- **Curso y caso:** IC-4301 Bases de Datos I — Universidad Horizonte, grupo 03.
- **Integrantes:** Santiago Víquez Zamora y Felipe Salazar González.
- **Alcance de esta versión:** trazabilidad de las correcciones del modelo lógico (26 relaciones y 135 atributos), de su continuidad con Lab03 y de las adaptaciones incorporadas en el esquema físico actual de 16 relaciones y 57 atributos. La implementación completa se documentará conforme se integren sus componentes.
- **Modelo inicial:** análisis, modelo relacional, diccionario, normalización y trazabilidad presentados en Proyecto 1; consolidación inicial de 19 relaciones.
- **Lab03:** recorte curricular de 6 tablas; versión evaluada `c55142cfdfab8caaaa56871d526d21e30e8d0584`, calificación 100/100.
- **Modelo corregido:** 26 relaciones en el diccionario y normalización, 135 atributos y 20 reglas RN-01 a RN-20, a partir de los documentos corregidos del equipo.
- **Estado de pruebas SQL actuales:** esquema de 16 relaciones instalado y semilla cargada en PostgreSQL 17.11; verificaciones declarativas, casos positivos, negativos y de frontera ejecutados satisfactoriamente. Las tres consultas, cuatro rutinas y nueve pruebas originales de Lab03 todavía no se han reejecutado sobre la implementación actual.

### Fuentes identificadas (sin enlaces privados)

El contraste documental toma como referencia las versiones entregadas del Proyecto 1: `01 - Análisis del caso`, `02 - Modelo conceptual`, `03 - Modelo relacional`, `04 - Diccionario de datos`, `05 - Normalización` y `06 - Matriz de trazabilidad`, así como la retroalimentación del profesor de esos artefactos. Sus versiones corregidas se identifican mediante los mismos títulos con el sufijo «corregido». Los seis documentos corregidos están incorporados en `modelo/` y el diagrama está en `diagramas/Modelo_Conceptual.svg`.

Las fuentes evaluadas de Lab03 se encuentran en el repositorio docente, versión inmutable `c55142cfdfab8caaaa56871d526d21e30e8d0584`, ruta `lab03/grupo-03/`: `sql/01_esquema.sql`, `sql/02_datos.sql`, `sql/03_consultas.sql`, `sql/04_rutinas.sql`, `sql/05_pruebas.sql`, `README.md` y `evidencias/resultados.md`. La calificación y observaciones corresponden a `Lab03_Retroalimentacion_Grupo_03.md` del mismo repositorio.

Consignas aplicables: `final-project/README.md`, `final-project/Control_de_Cambios_Especificacion.md` y `final-project/grupo-03/03_Grupo_03_Matricula.md` del repositorio docente. No se anexan documentos originales en formatos no admitidos para la entrega.

### Diferencias estructurales comprobadas entre versiones

| Fuente inicial | Corrección consolidada | Cómo queda identificada |
| --- | --- | --- |
| Proyecto 1: 19 relaciones. | 26 relaciones, con siete nuevas para contactos, autorizantes, ventanas y eventos históricos. | `modelo/03_Modelo_Relacional.md`, `modelo/04_Diccionario_Datos.md` y correspondencia de la sección 4. |
| Proyecto 1: 77 atributos en el diccionario. | 135 atributos. | `modelo/04_Diccionario_Datos.md`. |
| Proyecto 1: normalización selectiva de cinco relaciones y consolidación provisional. | Análisis de 26 relaciones y modelo lógico consolidado. | `modelo/05_Normalizacion.md`. |
| Lab03: seis relaciones curriculares implementadas; las otras 13 del modelo inicial no pertenecían al recorte. | Se conserva la cobertura de las seis y se incorporan al diseño las 13 restantes y las siete nuevas. | Sección 3, análisis estático de los cinco SQL de Lab03; sección 4, correspondencia completa. |
| Lab03: `vigencia TEXT`; `REQUISITO_CURSO` sin identificador alternativo. | Vigencia con inicio y fin; clave alternativa `id_requisito` auto-generada conservando la clave compuesta. | CC-P1-03, CC-P1-07 y revisión de compatibilidad en sección 3. |

### Retroalimentación docente identificable utilizada

Las referencias abreviadas en cada cambio remiten a los comentarios numerados de estos archivos calificados:

- `01 - Análisis del caso_calificado.docx`: comentarios 1, 33, 37 y 41.
- `03 - Modelo relacional_calificado.docx`: comentarios 0, 3, 4, 5, 7, 8, 9, 12 y 13.
- `05 - Normalización_calificado.docx`: comentarios 1, 2, 6, 9 y 12.

En los registros se distingue entre **requisito del caso**, **observación de la retroalimentación calificada del Proyecto 1**, **observación formativa sin descuento de Lab03** y **decisión de diseño del equipo**. Las observaciones de Proyecto 1 forman parte de la evaluación de 71/100; no deben confundirse con las recomendaciones formativas de Lab03 (100/100). Una decisión propia no se presenta como instrucción textual del profesor.

La documentación del modelo incluye ahora, además del registro central de cambios, una sección «Correspondencia» en cada Markdown. En particular, `modelo/02_Modelo_Conceptual.md` identifica las siete entidades conceptuales incorporadas, las cuatro asociaciones anteriormente representadas como vínculos que ahora son nodos identificables y las modificaciones de cardinalidades/atributos del diagrama. Esto no constituye un cambio nuevo al modelo aprobado, sino una explicación de las correcciones ya realizadas.

## 2. Registro de cambios documentales y de modelo

Las modificaciones del modelo fueron efectuadas por el equipo antes de preparar estos archivos Markdown. Los registros `CC-P1-01` a `CC-P1-14` describen sus antecedentes y su correspondencia con Proyecto 1 y Lab03. Las referencias a implementación y pruebas pendientes dentro de esos registros expresan el estado de la consolidación documental original; la ejecución física posterior del conjunto base se identifica en la sección 3, sin alterar retrospectivamente esos antecedentes.

### CC-P1-01 — Descomposición de datos de estudiante y contactos

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-01 |
| Fuente u origen | Requisito explícito: RD-01; RN-01 y RN-02. Observación docente de Proyecto 1: `01 - Análisis del caso_calificado.docx`, comentario 33; `03 - Modelo relacional_calificado.docx`, comentario 13; `05 - Normalización_calificado.docx`, comentarios 1 y 2. Decisión del equipo: descomponer los datos personales y representar cada contacto como ocurrencia independiente. |
| Elemento afectado | ESTUDIANTE; CONTACTO_ESTUDIANTE. |
| Situación anterior | P1: ESTUDIANTE(datos_personales, datos_contacto) sin atomicidad cerrada; CONTACTO_ESTUDIANTE no estaba entre las 19 relaciones. Lab03: no implementado. |
| Modificación realizada | ESTUDIANTE ahora identifica nombre y apellidos; CONTACTO_ESTUDIANTE se incorpora con id_contacto, tipo_contacto, valor y es_principal. |
| Justificación | Permite representar atributos atómicos y contactos múltiples sin eliminar la identidad del estudiante. |
| Reglas relacionadas | RD-01; RN-01; RN-02. |
| Impacto en modelo y operaciones | Nueva FK de contacto a estudiante; DDL y pruebas de multiplicidad/dominio pendientes. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: comparar ESTUDIANTE y CONTACTO_ESTUDIANTE entre diccionario original y corregido. PostgreSQL: pendiente. |

### CC-P1-02 — Admisión y contexto de versión de plan

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-02 |
| Fuente u origen | Requisito explícito: RN-02 y RN-03. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentarios 7, 8 y 9. Decisión del equipo: derivar la carrera desde VERSION_PLAN_ESTUDIOS y retirar la referencia redundante ADMISION.id_carrera, conservando la sede y validando su compatibilidad. |
| Elemento afectado | ADMISION; VERSION_PLAN_ESTUDIOS; CARRERA_SEDE. |
| Situación anterior | P1: ADMISION conservaba id_carrera además de id_version_plan, sin garantía de compatibilidad; no existía activa explícita. Lab03 implementaba VERSION_PLAN_ESTUDIOS, pero no ADMISION. |
| Modificación realizada | ADMISION prescinde de id_carrera redundante y añade activa; se determina la carrera mediante la versión del plan, conservando id_sede y el vínculo CARRERA_SEDE. |
| Justificación | Resuelve la redundancia señalada y permite evaluar la condición de admisión activa. |
| Reglas relacionadas | RN-02; RN-03; RN-09; G03-P02. |
| Impacto en modelo y operaciones | Cambian referencias y consultas sobre admisión; verificar compatibilidad carrera–sede–versión y efectos históricos en PostgreSQL. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: atributos ADMISION antes/después. Pruebas de integridad contextual en DDL: pendientes. |

### CC-P1-03 — Vigencias, periodos académicos y ventanas

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-03 |
| Fuente u origen | Requisito explícito: RD-04, RD-11, RN-09 y RN-13. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 13; `05 - Normalización_calificado.docx`, comentarios 9 y 12. Antecedente técnico: Lab03 representaba vigencia como TEXT. Decisión del equipo: usar límites temporales explícitos y una relación independiente para ventanas múltiples. |
| Elemento afectado | VERSION_PLAN_ESTUDIOS; PERIODO_ACADEMICO; VENTANA_PERIODO. |
| Situación anterior | P1: vigencia genérica y fechas_matricula_ordinaria/fechas_modificaciones en PERIODO_ACADEMICO. Lab03: vigencia TEXT provisional. |
| Modificación realizada | VERSION_PLAN_ESTUDIOS incorpora inicio_vigencia y fin_vigencia; PERIODO_ACADEMICO conserva sus fechas y añade codigo_periodo; VENTANA_PERIODO identifica tipo, inicio y fin. |
| Justificación | Permite expresar intervalos atómicos y múltiples ventanas autorizadas. |
| Reglas relacionadas | RN-03; RN-09; RN-13. |
| Impacto en modelo y operaciones | El SQL del Lab03 que usa vigencia TEXT deberá adaptarse; se requieren pruebas de fronteras y restricciones temporales. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: cambios de atributos y nueva relación. Validación temporal PostgreSQL: pendiente. |

### CC-P1-04 — Oferta, docentes, espacios y representación de bloques

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-04 |
| Fuente u origen | Requisito explícito: RD-12, RD-13, RN-07, RN-08 y RN-19. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentarios 0 y 12. Proceso asignado: G03-P01. Decisión del equipo: precisar los atributos de bloque, espacio y oferta y conservar el rol docente en la asociación. |
| Elemento afectado | GRUPO; BLOQUE_HORARIO; ESPACIO; DOCENTE; GRUPO_DOCENTE. |
| Situación anterior | P1: GRUPO no registraba estado_oferta; BLOQUE_HORARIO no diferenciaba es_presencial; ESPACIO sin sede; GRUPO_DOCENTE no garantizaba por sí solo un responsable. Lab03: no implementó GRUPO, BLOQUE_HORARIO, ESPACIO, DOCENTE ni GRUPO_DOCENTE; sí conservó el catálogo CURSO como dependencia curricular. |
| Modificación realizada | GRUPO añade estado_oferta y usa codigo_curso; BLOQUE_HORARIO incorpora es_presencial, dia_semana, hora_inicio y hora_fin; ESPACIO añade id_sede; DOCENTE incluye nombre. GRUPO_DOCENTE conserva rol. |
| Justificación | Distingue estado de oferta, presencialidad y contexto espacial y prepara los mecanismos de integridad exigidos. |
| Reglas relacionadas | RN-07; RN-08; RN-10; RN-19; G03-P01. |
| Impacto en modelo y operaciones | En PostgreSQL deberá garantizarse exactamente un responsable, evitar choques de espacios y respetar capacidad y sede; pendiente. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: comparación de atributos. Pruebas de oferta y concurrencia: pendientes. |

### CC-P1-05 — Identificación de personas autorizadoras

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-05 |
| Fuente u origen | Requisito explícito: RN-03, RN-15, RN-17 y RN-19. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 3; `01 - Análisis del caso_calificado.docx`, comentario 33. Decisión del equipo: identificar de forma reutilizable a las personas autorizadoras sin presumir que son docentes. |
| Elemento afectado | PERSONA_AUTORIZADORA; TRASLADO_PLAN y hechos con autorización. |
| Situación anterior | P1: el traslado guardaba fecha y motivo, pero no una FK que identificara a su autorizante. Lab03: fuera del recorte. |
| Modificación realizada | Se incorpora PERSONA_AUTORIZADORA con identificador propio e identificacion_institucional; TRASLADO_PLAN incluye id_autorizador y otros hechos autorizados refieren ese actor. |
| Justificación | Permite conservar identidad verificable sin suponer que toda persona autorizadora es un docente. |
| Reglas relacionadas | RN-03; RN-15; RN-17; RN-19. |
| Impacto en modelo y operaciones | Nuevas FKs, obligatoriedad de autorizaciones y verificaciones de referencias en los datos de prueba. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/05_Normalizacion.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: presencia de PERSONA_AUTORIZADORA y id_autorizador. PostgreSQL: pendiente. |

### CC-P1-06 — Contexto de reconocimientos académicos

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-06 |
| Fuente u origen | Requisito explícito: RD-10, RN-04 y RN-18. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 4. Decisión del equipo: vincular curso satisfecho y versión mediante referencia compuesta a PARTICIPACION_PLAN. |
| Elemento afectado | RECONOCIMIENTO_ACADEMICO; PARTICIPACION_PLAN; ADMISION. |
| Situación anterior | P1: RECONOCIMIENTO_ACADEMICO refería numero_institucional y versión/curso satisfecho sin vincularse directamente a una admisión. Lab03 no implementó reconocimientos. |
| Modificación realizada | RECONOCIMIENTO_ACADEMICO incluye id_admision, fecha_resolucion y referencia_curso_reconocido opcional; mantiene contexto de versión/curso satisfecho. |
| Justificación | Permite documentar el reconocimiento en el contexto de la trayectoria académica aplicable. |
| Reglas relacionadas | RN-04; RN-18; G03-P02. |
| Impacto en modelo y operaciones | El diseño físico deberá verificar correspondencia reconocimiento–admisión–versión–curso satisfecho; pendiente de pruebas. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: atributos antes/después. Comprobación de FK compuesta/contextual: pendiente. |

### CC-P1-07 — Identificador individual de requisito

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-07 |
| Fuente u origen | Requisito explícito: RD-17; RN-05, RN-06 y RN-15. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 5, sobre la ausencia de excepciones. Proceso asignado: G03-P02. Decisión del equipo: añadir id_requisito como clave candidata alternativa para identificar la regla concreta sin sustituir la PK compuesta. |
| Elemento afectado | REQUISITO_CURSO; EXCEPCION_REQUISITO. |
| Situación anterior | P1/Lab03: REQUISITO_CURSO tenía clave primaria compuesta por versión, curso objetivo, curso exigido y tipo; no tenía id_requisito. |
| Modificación realizada | Se conserva la identidad compuesta y se agrega id_requisito único, referenciado por EXCEPCION_REQUISITO. |
| Justificación | Permite identificar qué exigencia específica queda exceptuada, sin ampliar indiscriminadamente el alcance de la dispensa. |
| Reglas relacionadas | RN-05; RN-06; RN-15; G03-P02. |
| Impacto en modelo y operaciones | La tabla del Lab03 requiere una columna adicional y una restricción de unicidad; las rutinas heredadas deben volver a probarse. |
| Archivos modificados | modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: cambio en diccionario. Integración de rutinas y pruebas del Lab03: pendiente. |

### CC-P1-08 — Historial de cambios de oferta

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-08 |
| Fuente u origen | Requisito explícito: RD-14; RN-08 y RN-19. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 5; `01 - Análisis del caso_calificado.docx`, comentario 41. Proceso asignado: G03-P01. Decisión del equipo: separar los eventos históricos del estado actual de GRUPO. |
| Elemento afectado | GRUPO; HISTORIAL_OFERTA; PERSONA_AUTORIZADORA. |
| Situación anterior | P1: se exigía historia de apertura/cierre/cancelación/cupo, pero no existía una relación histórica independiente. Lab03: fuera del recorte. |
| Modificación realizada | HISTORIAL_OFERTA registra grupo, tipo de cambio, estados/cupos anteriores y nuevos, fecha, motivo y responsable. |
| Justificación | Conserva cambios relevantes sin sobrescribir exclusivamente el estado vigente. |
| Reglas relacionadas | RN-08; RN-19; G03-P01. |
| Impacto en modelo y operaciones | Se necesitarán operaciones atómicas para cambiar oferta e insertar historia y pruebas de no desaparición de matrículas. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: nueva relación. Ejecución de cancelación/modificación y consulta histórica: pendientes. |

### CC-P1-09 — Historial de transiciones de solicitudes

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-09 |
| Fuente u origen | Requisito explícito: RD-15 y RD-16; RN-11, RN-12 y RN-14. Procesos asignados: G03-P02 y G03-P03. Decisión del equipo: conservar los eventos de solicitud en una relación histórica separada, incluidos los eventos de evaluación de espera. No se atribuye este diseño a un comentario docente específico. |
| Elemento afectado | SOLICITUD_MATRICULA; HISTORIAL_SOLICITUD. |
| Situación anterior | P1: solicitud almacenaba estado, orden de espera y momento de transición, pero carecía de un historial independiente de todos los movimientos. Lab03: SOLICITUD_MATRICULA e HISTORIAL_SOLICITUD quedaron fuera de su recorte curricular; las consultas y rutinas del laboratorio no resolvían estados de matrícula ni listas de espera. |
| Modificación realizada | SOLICITUD_MATRICULA incorpora fecha_solicitud e id_version_plan_evaluada; HISTORIAL_SOLICITUD registra evento, estado anterior/nuevo, fecha, motivo y actor opcional. |
| Justificación | Permite rastrear resultado, plan evaluado, orden y transiciones sin perder antecedentes. |
| Reglas relacionadas | RN-09–RN-14; RN-16; G03-P02; G03-P03. |
| Impacto en modelo y operaciones | Se requerirán garantías transaccionales para aceptar, rechazar, retirar, cambiar y promover; pruebas aún pendientes. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: nueva relación y dos atributos de solicitud. Pruebas operativas/concurrentes: pendientes. |

### CC-P1-10 — Excepciones identificadas por solicitud y requisito

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-10 |
| Fuente u origen | Requisito explícito: RD-17 y RN-15. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 5; `01 - Análisis del caso_calificado.docx`, comentario 41. Proceso asignado: G03-P02. Decisión del equipo: asociar cada excepción con una solicitud, una regla identificable y una persona autorizadora. |
| Elemento afectado | EXCEPCION_REQUISITO; SOLICITUD_MATRICULA; REQUISITO_CURSO; PERSONA_AUTORIZADORA. |
| Situación anterior | P1: no existía una relación propia para excepciones; la matriz indicaba ausencia de representación. Lab03: sí implementó REQUISITO_CURSO, pero no implementó SOLICITUD_MATRICULA, EXCEPCION_REQUISITO ni gestión de autorizaciones. |
| Modificación realizada | EXCEPCION_REQUISITO incorpora solicitud, requisito específico, autorizante, fecha de autorización y motivo. |
| Justificación | Evita que una excepción se aplique automáticamente a solicitudes o requisitos no autorizados. |
| Reglas relacionadas | RN-15; G03-P02. |
| Impacto en modelo y operaciones | Se deben verificar la vigencia y el alcance efectivo de una excepción en decisiones de matrícula, con pruebas negativas. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: nueva relación. Validación funcional y persistencia: pendientes. |

### CC-P1-11 — Historial de correcciones de calificación

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-11 |
| Fuente u origen | Requisito explícito: RD-18; RN-17 y RN-20. Observación docente de Proyecto 1: `03 - Modelo relacional_calificado.docx`, comentario 5; `01 - Análisis del caso_calificado.docx`, comentario 41. Fuente de alcance: apartado C del anexo G03. Decisión del equipo: conservar cada corrección como evento con valores anteriores/nuevos y autorización. |
| Elemento afectado | SOLICITUD_MATRICULA; HISTORIAL_CORRECCION_CALIFICACION. |
| Situación anterior | P1: SOLICITUD_MATRICULA contenía calificacion y resultado_academico vigentes, sin historial de corrección. Lab03: no implementó resultados académicos, solicitudes matriculadas ni correcciones de calificación; solo el subsistema curricular de seis relaciones. |
| Modificación realizada | HISTORIAL_CORRECCION_CALIFICACION guarda solicitud, calificación/resultado anterior y nuevo, fecha, motivo y autorizante. |
| Justificación | Preserva antecedentes obligatorios sin incorporar el proceso completo de actas como un cuarto proceso asignado. |
| Reglas relacionadas | RN-17; RN-20. |
| Impacto en modelo y operaciones | Pruebas de integridad e historia de correcciones; el flujo operativo de notas no está asignado. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Documental: nueva relación. Pruebas PostgreSQL: pendientes. |

### CC-P1-12 — Consolidación de normalización, diccionario y trazabilidad

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-12 |
| Fuente u origen | Requisito de consolidación: Aclaraciones complementarias P1, apartado 4; anexo G03, apartados C y D. Observación docente de Proyecto 1: `05 - Normalización_calificado.docx`, comentarios 1, 2, 6, 9 y 12. Decisión del equipo: utilizar como modelo lógico final la versión coherente de 26 relaciones, 135 atributos y 20 reglas. |
| Elemento afectado | Modelo relacional completo, diccionario y matriz. |
| Situación anterior | P1: normalización selectiva de cinco relaciones y consolidación expresamente provisional de 19. Lab03: implementó y probó únicamente seis relaciones curriculares derivadas del modelo previo, no el modelo completo de 19 ni los nuevos hechos históricos. |
| Modificación realizada | Normalización corregida analiza las 26 relaciones; diccionario contiene 135 atributos y matriz documenta RN-01 a RN-20. |
| Justificación | Cierra la representación lógica declarada por el equipo antes de implementar las restricciones físicas. |
| Reglas relacionadas | RN-01–RN-20. |
| Impacto en modelo y operaciones | La matriz de esta segunda entrega deberá añadir mecanismo físico y prueba por regla; DDL del conjunto todavía pendiente. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/03_Modelo_Relacional.md; modelo/04_Diccionario_Datos.md; modelo/05_Normalizacion.md; modelo/06_Matriz_Trazabilidad.md. |
| Evidencia de validación | Comprobación documental de exportación: 26 relaciones en diccionario, 135 atributos, 20 reglas. Integración con DDL y pruebas: pendiente. |

### CC-P1-13 — Revisión de representación conceptual

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-13 |
| Fuente u origen | Requisito de representación: notación Crow’s Foot establecida para el DER del P1. Observación docente de Proyecto 1: `01 - Análisis del caso_calificado.docx`, comentarios 1 y 37, sobre completar la representación conceptual y justificar el modelo por corrección técnica, no por cuotas. Decisión del equipo: actualizar el diagrama conceptual para reflejar las entidades, asociaciones y atributos del modelo corregido. |
| Elemento afectado | Modelo conceptual (diagrama de entidades y asociaciones). |
| Situación anterior | P1: diagrama anterior con inconsistencias de cardinalidades y ausencia de hechos históricos. Lab03: documentó un fragmento lógico curricular, no un DER conceptual integral ni las asociaciones de oferta y matrícula. |
| Modificación realizada | El equipo dispone de un DER corregido en el archivo editable de referencia. Esta preparación incluye su imagen SVG vectorial equivalente para la entrega; no se modifica el diseño. |
| Justificación | La consigna permite diagramas SVG referenciados en Markdown; evita introducir un PDF como sustituto del diagrama. |
| Reglas relacionadas | RN-01–RN-20 (en lo aplicable). |
| Impacto en modelo y operaciones | El diagrama debe mantenerse sincronizado con los cambios posteriores del esquema físico. |
| Archivos modificados | modelo/01_Analisis_del_Caso.md; modelo/02_Modelo_Conceptual.md; diagramas/Modelo_Conceptual.svg. |
| Evidencia de validación | Documental: el SVG representa visualmente el diagrama corregido; se cotejaron las 24 cajas de conceptos/hechos y sus 42 conexiones con el archivo editable. Se comprobó que las multiplicidades en los enlaces corresponden a los extremos indicados en el análisis. No constituye prueba de integridad PostgreSQL. |

### CC-P1-14 — Aclaración de la evidencia P07 de Lab03 (solo documental)

| Campo | Registro |
| --- | --- |
| Identificador del cambio | CC-P1-14 |
| Fuente u origen | `lab03/grupo-03/sql/02_datos.sql` y `sql/05_pruebas.sql` de la versión evaluada. No se trata de una regla nueva ni de una observación del profesor. |
| Elemento afectado | Explicación de `REQUISITO_CURSO` en `modelo/05_Normalizacion.md`. |
| Situación anterior | El documento corregido afirmaba que P07 había demostrado un requisito cuyo curso objetivo no figuraba en la versión 201. Lab03: el guion original P07 insertaba un requisito con objetivo UH-EST1 en la versión 201; su propia semilla ya incluía ese curso en esa versión. |
| Modificación realizada | Se rectifica únicamente esa atribución de evidencia: `UH-EST1` sí participa como optativo en la versión 201 según la semilla, por lo que P07 no constituye una prueba de objetivo externo al plan. |
| Justificación | Evitar atribuir a una prueba histórica una condición que sus datos no representan; conservar la regla que permite requisitos de cursos compartidos sin introducir prohibiciones nuevas. |
| Reglas relacionadas | RN-05 y RN-06; aclaración formativa de Lab03 sobre requisitos compartidos. |
| Impacto en modelo y operaciones | Sin modificación estructural. Una prueba de requisito externo, si es aplicable a la segunda entrega, debe construirse con datos que realmente satisfagan esa precondición. |
| Archivos modificados | `modelo/05_Normalizacion.md` y `Control_de_Cambios.md`. |
| Evidencia de validación | Comparación estática directa: en `02_datos.sql`, versión 201 incluye `('UH-EST1',201,'Optativo','3')`; P07 inserta `(201,'UH-EST1','UH-MAT1','Requisito previo')`. |

## 3. Lab03 — continuidad, adaptaciones y comprobaciones

**Alcance de la comprobación:** se examinaron los cinco archivos SQL de la versión evaluada de Lab03, junto con su `README.md` y sus evidencias, y se contrastaron sus estructuras, datos, consultas, rutinas y pruebas con el modelo corregido. La implementación posterior de las seis relaciones curriculares adaptadas se realizó en `sql/01_esquema_base.sql`, con datos en `sql/02_datos_base.sql` y pruebas actuales en `pruebas/01_pruebas_base.sql`. Se distinguen la compatibilidad estática de los componentes heredados, los resultados ejecutados en PostgreSQL 17.11 y los antecedentes históricos del laboratorio, cuya evaluación 100/100 no constituye evidencia de ejecución actual.

### 3.1 Las seis relaciones de `01_esquema.sql`

| Relación | Continuidad con Lab03 | Implementación actual respecto de Lab03 |
| --- | --- | --- |
| `escuela` | Clave `id_escuela` y granularidad conservadas. | Definición conservada sin modificación. |
| `carrera` | Clave `id_carrera` conservada. | Definición conservada sin modificación. |
| `curso` | Se mantienen `codigo_institucional`, `nombre`, `cantidad_creditos` e `id_escuela`. | Se conservó la FK a ESCUELA y se añadieron comprobaciones de créditos no negativos y textos obligatorios no vacíos. |
| `version_plan_estudios` | Se conservan `id_version_plan` e `id_carrera`. | Se sustituyó `vigencia TEXT NOT NULL` por `inicio_vigencia DATE NOT NULL` y `fin_vigencia DATE` opcional, con comprobación del intervalo. |
| `participacion_plan` | Se conservan la PK `(codigo_curso, id_version_plan)`, las FK y los atributos `tipo_participacion` y `nivel_o_periodo_recomendado`. | Se mantuvo el dominio de participación y se añadió la comprobación de texto no vacío cuando se informa el nivel o periodo recomendado. |
| `requisito_curso` | Se conservan la PK `(id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito)` y las FK a versiones y cursos. | Se añadió `id_requisito` como identidad generada `UNIQUE NOT NULL`, sin sustituir la PK, y la prohibición de autorrequisitos. No se agregaron FK de ambos cursos a `participacion_plan`, en conformidad con el modelo corregido. |

### 3.2 `02_datos.sql` y las tres consultas de `03_consultas.sql`

La semilla histórica de Lab03 contiene **41 registros**: dos escuelas, dos carreras, ocho cursos, tres versiones del plan, 16 participaciones y diez reglas de requisito. Se reutilizaron en `sql/02_datos_base.sql`, adaptando los tres valores textuales de vigencia a fechas explícitas ficticias; dichas fechas no se presentan como datos históricos comprobados. Se añadieron 23 registros ficticios para las demás relaciones del conjunto instalado, con **64 registros en total**, cuya carga y conservación posterior fueron comprobadas en PostgreSQL 17.11. Las tres consultas Q01–Q03 se examinaron estáticamente, pero no se atribuyen resultados nuevos de ejecución a sus archivos originales.

| Consulta | Dependencias de origen | Conclusión de compatibilidad estática |
| --- | --- | --- |
| Q01 — cursos de versión 102 | `participacion_plan`, `curso`; columnas sin cambios. | Compatible con el esquema lógico corregido. Resultado histórico: siete cursos, seis obligatorios y uno optativo; confirmar nuevamente si se reutiliza la misma semilla. |
| Q02 — requisitos de `UH-BDAT1`, versión 102 | `requisito_curso`, `curso`; nombres de columnas sin cambios. | Compatible con la adición de `id_requisito`, al no requerir esa columna. Resultado histórico: un requisito previo y dos correquisitos. |
| Q03 — conteos por versión y tipo | `participacion_plan`; claves y dominio conservados. | Compatible. Históricamente: 101 (5/1), 102 (6/1), 201 (2/1), obligatorios/optativos. |

### 3.3 Las cuatro rutinas de `04_rutinas.sql`

| Rutina | Firma/contrato heredados | Conclusión y límite real |
| --- | --- | --- |
| `fn_creditos_obligatorios_plan(INTEGER) RETURNS INTEGER` | Suma créditos obligatorios vía `participacion_plan` + `curso`; devuelve 0 si no hay filas. | Referencias estáticamente compatibles. El resultado 0 también ocurre para una versión inexistente, de modo que **no** debe utilizarse este retorno como validación de existencia de versión. |
| `fn_tipo_requisitos_curso(TEXT, INTEGER) RETURNS TEXT` | Clasifica requisitos del curso siempre que pertenezca a la versión; utiliza `participacion_plan` y `requisito_curso`. | Compatible dentro de su contrato de consulta curricular. La salida «El curso no pertenece al plan» no es una comprobación universal de la validez de reglas exigidas externas al plan; no debe reutilizarse como tal en G03-P02. |
| `sp_agregar_curso_plan(TEXT, INTEGER, TEXT, TEXT)` | Inserta una participación validando curso, versión, tipo y duplicación; usa las cuatro columnas conservadas de `participacion_plan`. | Firma y dependencias compatibles. Se debe mantener la PK para protección ante duplicados. No se requiere modificar la rutina únicamente porque el esquema global incluya más relaciones. |
| `fn_detalle_requisitos_cursor(TEXT, INTEGER) RETURNS TEXT` | Cursor explícito que recorre requisitos y construye una descripción; exige pertenencia del objetivo al plan. | Compatible con los nombres corregidos, dentro de su contrato. Es un componente histórico reutilizable, no una rutina necesaria para alcanzar una cuota de cursores. |

### 3.4 Las nueve pruebas de `05_pruebas.sql`

| ID | Acción y cobertura verificada históricamente | Compatibilidad y reserva comprobada |
| --- | --- | --- |
| P01 | Suma de 22 créditos obligatorios en versión 102. | Válida como prueba de agregación con la misma semilla; no prueba existencia de versión desconocida. |
| P02 | Clasificación «Requisitos previos y correquisitos» para `UH-BDAT1`/102. | Válida para curso participante; no evalúa requisitos externos. |
| P03 | Alta temporal válida de `UH-RED1` en versión 101, con `SAVEPOINT` y reversión. | Conserva columnas y firma de `sp_agregar_curso_plan`; requiere la semilla compatible. |
| P04 | Rechazo de participación duplicada por `pk_participacion_plan`. | Compatible si se preserva esa PK y su nombre, pues la prueba inspecciona `CONSTRAINT_NAME`. |
| P05 | Rechazo de FK de curso inexistente por `fk_participacion_curso`. | Compatible si se preserva la FK y su nombre; la prueba inspecciona `CONSTRAINT_NAME`. |
| P06 | Rechazo de tipo inválido por `ck_tipo_participacion`. | Compatible si se preserva el `CHECK` y su nombre. |
| P07 | Alta temporal de requisito para `UH-EST1`/201, con reversión. | La semilla **sí incluye** `UH-EST1` en la versión 201; **no demuestra** la admisión de un curso objetivo externo al plan. El INSERT de cuatro columnas exige `id_requisito` autogenerado en el esquema corregido. |
| P08 | Cambio temporal de participación de `UH-RED1`/102 de optativo a obligatorio, luego reversión. | Compatible con las columnas y dominio conservados; no demuestra los flujos de modificación de matrícula. |
| P09 | Rechazo de participación duplicada mediante `sp_agregar_curso_plan`, comprobando texto del error. | Compatible si no se altera el mensaje del procedimiento; el texto es parte de la condición que la prueba compara. |

Las nueve pruebas originales fueron reportadas exitosas en `lab03/grupo-03/evidencias/resultados.md` y corresponden a la versión evaluada de Lab03. No se han reejecutado como batería original sobre el esquema actual. La comprobación física de las relaciones curriculares adaptadas forma parte de `pruebas/01_pruebas_base.sql`, cuyos resultados deben mantenerse diferenciados de aquella evidencia histórica.

### 3.5 Resultado de reutilización y medidas de compatibilidad

#### Componentes reutilizados sin modificación

Las definiciones de `ESCUELA` y `CARRERA` se conservaron sin cambios respecto de `lab03/grupo-03/sql/01_esquema.sql`, versión evaluada `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

| Componente | Propósito y reglas relacionadas | Razón para conservarlo y dependencias compatibles | Prueba en la implementación actual |
| --- | --- | --- | --- |
| `ESCUELA` | Identificar escuelas mediante `id_escuela`, clave primaria; referencia institucional de `CURSO.id_escuela`. No tiene una RN autónoma en la matriz lógica. | Su identidad y granularidad son compatibles con el modelo corregido y con la FK de CURSO; modificarla no es necesario. | `pruebas/01_pruebas_base.sql`: estructura y PK de ESCUELA y FK `fk_curso_escuela`; `sql/02_datos_base.sql`: dos registros de ESCUELA cargados. |
| `CARRERA` | Identificar carreras mediante `id_carrera`, clave primaria; referencia de `VERSION_PLAN_ESTUDIOS.id_carrera`, relacionada con RN-02 y RN-03. | Su identidad es compatible con las versiones de plan y las referencias del modelo corregido; no requiere modificación. | `pruebas/01_pruebas_base.sql`: estructura y PK de CARRERA y FK `fk_version_carrera`; `sql/02_datos_base.sql`: dos registros de CARRERA cargados. |

#### Componentes curriculares adaptados

| Componente de Lab03 | Adaptación efectuada en el modelo físico | Comprobación actual |
| --- | --- | --- |
| `CURSO` | Atributos y FK a ESCUELA conservados; comprobaciones de créditos no negativos y textos obligatorios no vacíos añadidas. | Estructura, FK, dominios y rechazos comprobados. |
| `VERSION_PLAN_ESTUDIOS` | Identidad y FK a CARRERA conservadas; `vigencia TEXT` sustituida por fechas de inicio y fin (CC-P1-03). | Estructura y fronteras de vigencia comprobadas. |
| `PARTICIPACION_PLAN` | PK compuesta, FK y dominio de participación conservados; comprobación del nivel informado añadida. | Identidad compuesta, referencias y dominios comprobados. |
| `REQUISITO_CURSO` | PK de cuatro componentes y FK conservadas; incorporado `id_requisito` generado, único y obligatorio (CC-P1-07), más prohibición de autorrequisitos. | Identidad compuesta y alternativa, referencias y rechazos comprobados. |
| Datos de `02_datos.sql` | Conservación de 41 registros curriculares; tres vigencias textuales expresadas mediante fechas ficticias. | Carga mediante `COMMIT` y recuentos posteriores comprobados. |

Los componentes físicos se encuentran en `sql/01_esquema_base.sql` y la semilla adaptada en `sql/02_datos_base.sql`. `pruebas/01_pruebas_base.sql` verificó el conjunto de 16 relaciones y 57 atributos: 16 PK, 15 FK, cuatro UNIQUE, 25 CHECK, índice único parcial y exclusión GiST; además de casos positivos, 53 rechazos negativos por la causa esperada y cinco comprobaciones adicionales de `NOT NULL`. La transacción de prueba terminó con `ROLLBACK`; una conexión independiente confirmó que permanecían los 64 registros de la semilla.

Las tres consultas de `03_consultas.sql`, las cuatro rutinas de `04_rutinas.sql` y las nueve pruebas de `05_pruebas.sql` se conservan como referencia sin reescritura. Su compatibilidad estructural se examinó en las secciones anteriores, pero sus resultados históricos no se presentan como ejecuciones actuales; todavía no existe una comprobación funcional nueva de estos archivos. En particular, P07 no demuestra un requisito cuyo curso objetivo esté fuera del plan porque la semilla de Lab03 incluye dicho curso en la versión utilizada.

## 4. Correspondencia de relaciones de partida y correcciones

| Relación de P1 | Situación en Lab03 | Situación en el modelo corregido |
| --- | --- | --- |
| `ESTUDIANTE` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `ADMISION` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `CARRERA` | Implementada en el recorte del Lab03 | Conservada en el inventario; validar restricciones físicas |
| `SEDE` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `VERSION_PLAN_ESTUDIOS` | Implementada en el recorte del Lab03 | Conservada con cambios |
| `PERIODO_ACADEMICO` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `CURSO` | Implementada en el recorte del Lab03 | Conservada en el inventario; validar restricciones físicas |
| `ESCUELA` | Implementada en el recorte del Lab03 | Conservada en el inventario; validar restricciones físicas |
| `GRUPO` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `BLOQUE_HORARIO` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `ESPACIO` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `SOLICITUD_MATRICULA` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `DOCENTE` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `CARRERA_SEDE` | No implementada en el recorte del Lab03 | Conservada en el inventario; validar restricciones físicas |
| `PARTICIPACION_PLAN` | Implementada en el recorte del Lab03 | Conservada en el inventario; validar restricciones físicas |
| `REQUISITO_CURSO` | Implementada en el recorte del Lab03 | Conservada con cambios |
| `TRASLADO_PLAN` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `RECONOCIMIENTO_ACADEMICO` | No implementada en el recorte del Lab03 | Conservada con cambios |
| `GRUPO_DOCENTE` | No implementada en el recorte del Lab03 | Conservada en el inventario; validar restricciones físicas |

**Relaciones incorporadas al modelo corregido que no estaban entre las 19 de P1:** `CONTACTO_ESTUDIANTE`, `PERSONA_AUTORIZADORA`, `VENTANA_PERIODO`, `HISTORIAL_OFERTA`, `HISTORIAL_SOLICITUD`, `EXCEPCION_REQUISITO`, `HISTORIAL_CORRECCION_CALIFICACION`.

Las 19 relaciones de partida están representadas nominalmente en el diccionario corregido. Una modificación de nombre de atributo no equivale a eliminar su hecho de negocio. Esta correspondencia se actualizará si la transformación física cambia la organización sin perder semántica.



### Anexo A — Cotejo exhaustivo del diccionario original y corregido

**Propósito:** identificar todas las incorporaciones, eliminaciones/sustituciones y modificaciones de atributos, sin duplicar las definiciones completas del diccionario. La comparación utiliza **clave (relación, atributo)** y contrasta las ocho propiedades documentales de cada atributo; el detalle íntegro de cada valor anterior y nuevo se obtiene en las respectivas versiones del diccionario.

- Original de Proyecto 1: **19 relaciones y 77 atributos**.
- Modelo corregido: **26 relaciones y 135 atributos**.
- Atributos con igual nombre de relación y atributo en ambas versiones: **66**, todos con alguna propiedad documental actualizada.
- Atributos ausentes de la versión corregida con su identificador anterior: **11** (eliminados, renombrados o descompuestos; se precisa su correspondencia).
- Atributos nuevos con su identificador actual: **69**.
- Comprobación de cobertura: 66 + 11 = 77 atributos originales; 66 + 69 = 135 atributos actuales.

**Claves de interpretación:** «Conservados: campo (propiedades modificadas)» significa que permanecen el identificador de relación y atributo, pero cambian exclusivamente las columnas nombradas. Los atributos nuevos se reconocen por identificador; sus propiedades completas están en `modelo/04_Diccionario_Datos.md`.

| Relación | Atributos originales que desaparecen con ese nombre | Atributos nuevos en la versión corregida | Conservados con campos documentales cambiados |
| --- | --- | --- | --- |
| `ADMISION` | `id_carrera` | `activa` | `condicion_academica` (descripción, dominio, valores permitidos, restricción, ejemplo); `fecha_ingreso` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_admision` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_sede` (descripción, dominio, valores permitidos, restricción); `id_version_plan` (descripción, dominio, valores permitidos, restricción, ejemplo); `numero_institucional` (descripción, dominio, valores permitidos, restricción) |
| `BLOQUE_HORARIO` | `dia`, `hora_final`, `hora_inicial` | `dia_semana`, `es_presencial`, `hora_fin`, `hora_inicio` | `id_bloque` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_espacio` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_grupo` (descripción, dominio, valores permitidos, restricción, ejemplo) |
| `CARRERA` | — | — | `id_carrera` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo) |
| `CARRERA_SEDE` | — | — | `id_carrera` (descripción, dominio, unicidad, valores permitidos, restricción, ejemplo); `id_sede` (descripción, dominio, unicidad, valores permitidos, restricción) |
| `CONTACTO_ESTUDIANTE` | — | `es_principal`, `id_contacto`, `numero_institucional`, `tipo_contacto`, `valor` | — |
| `CURSO` | — | — | `cantidad_creditos` (descripción, dominio, valores permitidos, restricción); `codigo_institucional` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_escuela` (descripción, dominio, valores permitidos, restricción); `nombre` (descripción, dominio, valores permitidos, restricción, ejemplo) |
| `DOCENTE` | — | `nombre` | `id_docente` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo) |
| `ESCUELA` | — | — | `id_escuela` (descripción, dominio, unicidad, clave, valores permitidos, restricción) |
| `ESPACIO` | — | `id_sede` | `capacidad` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_espacio` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `ubicacion` (descripción, dominio, valores permitidos, restricción, ejemplo) |
| `ESTUDIANTE` | `datos_contacto`, `datos_personales` | `nombre`, `primer_apellido`, `segundo_apellido` | `numero_institucional` (descripción, dominio, unicidad, clave, valores permitidos, restricción) |
| `EXCEPCION_REQUISITO` | — | `fecha_autorizacion`, `id_autorizador`, `id_excepcion`, `id_requisito`, `id_solicitud`, `motivo` | — |
| `GRUPO` | `id_curso` | `codigo_curso`, `estado_oferta` | `capacidad` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_grupo` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_periodo` (dominio, unicidad, valores permitidos, restricción, ejemplo); `id_sede` (descripción, dominio, unicidad, valores permitidos, restricción); `modalidad` (descripción, dominio, valores permitidos, restricción, ejemplo); `numero_grupo` (descripción, dominio, unicidad, valores permitidos, restricción) |
| `GRUPO_DOCENTE` | — | — | `id_docente` (descripción, dominio, unicidad, valores permitidos, restricción, ejemplo); `id_grupo` (descripción, dominio, unicidad, valores permitidos, restricción, ejemplo); `rol` (descripción, dominio, valores permitidos, restricción, ejemplo) |
| `HISTORIAL_CORRECCION_CALIFICACION` | — | `calificacion_anterior`, `calificacion_nueva`, `fecha_correccion`, `id_autorizador`, `id_correccion`, `id_solicitud`, `motivo`, `resultado_anterior`, `resultado_nuevo` | — |
| `HISTORIAL_OFERTA` | — | `cupo_anterior`, `cupo_nuevo`, `estado_anterior`, `estado_nuevo`, `fecha_cambio`, `id_cambio`, `id_grupo`, `id_responsable`, `motivo`, `tipo_cambio` | — |
| `HISTORIAL_SOLICITUD` | — | `estado_anterior`, `estado_nuevo`, `fecha_evento`, `id_actor`, `id_evento`, `id_solicitud`, `motivo`, `tipo_evento` | — |
| `PARTICIPACION_PLAN` | — | — | `codigo_curso` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_version_plan` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `nivel_o_periodo_recomendado` (descripción, dominio, obligatoriedad, valores permitidos, restricción, ejemplo); `tipo_participacion` (descripción, dominio, restricción) |
| `PERIODO_ACADEMICO` | `fechas_matricula_ordinaria`, `fechas_modificaciones` | `codigo_periodo` | `fecha_finalizacion` (descripción, dominio, valores permitidos, restricción, ejemplo); `fecha_inicio` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_periodo` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo) |
| `PERSONA_AUTORIZADORA` | — | `id_autorizador`, `identificacion_institucional`, `nombre` | — |
| `RECONOCIMIENTO_ACADEMICO` | `numero_institucional` | `fecha_resolucion`, `id_admision`, `referencia_curso_reconocido` | `codigo_curso_reconocido` (descripción, dominio, obligatoriedad, valores permitidos, restricción, ejemplo); `codigo_curso_satisfecho` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_reconocimiento` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_version_plan` (descripción, dominio, valores permitidos, restricción, ejemplo); `resolucion_academica` (descripción, dominio, valores permitidos, restricción, ejemplo) |
| `REQUISITO_CURSO` | — | `id_requisito` | `codigo_curso_exigido` (descripción, dominio, unicidad, valores permitidos, restricción, ejemplo); `codigo_curso_objetivo` (descripción, dominio, unicidad, valores permitidos, restricción, ejemplo); `id_version_plan` (descripción, dominio, unicidad, valores permitidos, restricción, ejemplo); `tipo_requisito` (descripción, dominio, unicidad, clave, restricción) |
| `SEDE` | — | `nombre` | `id_sede` (descripción, dominio, unicidad, clave, valores permitidos, restricción) |
| `SOLICITUD_MATRICULA` | — | `fecha_solicitud`, `id_version_plan_evaluada` | `calificacion` (descripción, dominio, valores permitidos, restricción, ejemplo); `estado` (descripción, dominio, valores permitidos, restricción); `id_admision` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_grupo` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_solicitud` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_solicitud_anterior` (descripción, dominio, clave, valores permitidos, restricción, ejemplo); `momento_transicion` (descripción, dominio, valores permitidos, restricción, ejemplo); `orden_espera` (descripción, dominio, valores permitidos, restricción, ejemplo); `razon_rechazo_espera` (descripción, dominio, valores permitidos, restricción); `resultado_academico` (descripción, dominio, valores permitidos, restricción) |
| `TRASLADO_PLAN` | — | `id_autorizador` | `fecha` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_admision` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_traslado` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo); `id_version_destino` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_version_origen` (descripción, dominio, valores permitidos, restricción, ejemplo); `motivo` (descripción, dominio, valores permitidos, restricción, ejemplo) |
| `VENTANA_PERIODO` | — | `fin`, `id_periodo`, `id_ventana`, `inicio`, `tipo_ventana` | — |
| `VERSION_PLAN_ESTUDIOS` | `vigencia` | `fin_vigencia`, `inicio_vigencia` | `id_carrera` (descripción, dominio, valores permitidos, restricción, ejemplo); `id_version_plan` (descripción, dominio, unicidad, clave, valores permitidos, restricción, ejemplo) |

#### Correspondencia de los 11 identificadores anteriores sustituidos

| Atributo anterior | Correspondencia en el corregido | Naturaleza |
| --- | --- | --- |
| `ESTUDIANTE.datos_personales` | `ESTUDIANTE.nombre`, `primer_apellido`, `segundo_apellido` | Descomposición en atributos atómicos. |
| `ESTUDIANTE.datos_contacto` | `CONTACTO_ESTUDIANTE` y sus cinco atributos | Separación de un hecho repetible en relación propia. |
| `ADMISION.id_carrera` | `ADMISION.id_version_plan` → `VERSION_PLAN_ESTUDIOS.id_carrera` | Eliminación de redundancia; carrera derivada de la versión. |
| `VERSION_PLAN_ESTUDIOS.vigencia` | `inicio_vigencia`, `fin_vigencia` | Descomposición temporal; intervalo explícito. |
| `PERIODO_ACADEMICO.fechas_matricula_ordinaria` | `VENTANA_PERIODO`, `tipo_ventana = matricula` | Ventana independiente y repetible. |
| `PERIODO_ACADEMICO.fechas_modificaciones` | `VENTANA_PERIODO`, `tipo_ventana = modificacion` | Ventana independiente y repetible. |
| `BLOQUE_HORARIO.dia` | `BLOQUE_HORARIO.dia_semana` | Renominación y precisión de dominio. |
| `BLOQUE_HORARIO.hora_inicial` | `BLOQUE_HORARIO.hora_inicio` | Renominación del extremo inicial. |
| `BLOQUE_HORARIO.hora_final` | `BLOQUE_HORARIO.hora_fin` | Renominación del extremo final. |
| `GRUPO.id_curso` | `GRUPO.codigo_curso` → `CURSO.codigo_institucional` | Renominación y referencia por clave del curso. |
| `RECONOCIMIENTO_ACADEMICO.numero_institucional` | `RECONOCIMIENTO_ACADEMICO.id_admision` → `ADMISION.numero_institucional` | Asociación al contexto de la admisión, sin perder identidad del estudiante. |

Los cambios de cardinalidades y hechos históricos se encuentran identificados en CC-P1-01 a CC-P1-13 y en las secciones 1 y 4. La implementación física de las 16 relaciones base y sus comprobaciones actuales se describen en la sección 3; las demás correspondencias físicas se completarán al integrar el modelo completo.

### Anexo B — Cotejo de las 20 reglas de trazabilidad

Las descripciones de RN-01 a RN-20 se conservan sin renumeración. La siguiente tabla identifica, para cada regla, los campos de la matriz que cambiaron. La matriz corregida conserva el texto íntegro; aquí se documenta solo la diferencia respecto de la original.

| Regla | Columnas modificadas respecto de Proyecto 1 |
| --- | --- |
| RN-01 | Elemento relacional, Restricción |
| RN-02 | Elemento conceptual, Elemento relacional, Restricción |
| RN-03 | Elemento conceptual, Elemento relacional, Restricción |
| RN-04 | Elemento conceptual, Elemento relacional, Restricción |
| RN-05 | Elemento conceptual, Elemento relacional, Restricción |
| RN-06 | Elemento conceptual, Elemento relacional, Restricción |
| RN-07 | Elemento conceptual, Elemento relacional, Restricción |
| RN-08 | Elemento conceptual, Elemento relacional, Restricción |
| RN-09 | Elemento conceptual, Elemento relacional, Restricción |
| RN-10 | Elemento conceptual, Elemento relacional, Restricción |
| RN-11 | Elemento conceptual, Elemento relacional, Restricción |
| RN-12 | Elemento conceptual, Elemento relacional, Restricción |
| RN-13 | Elemento conceptual, Elemento relacional, Restricción |
| RN-14 | Elemento conceptual, Elemento relacional, Restricción |
| RN-15 | Elemento conceptual, Elemento relacional, Restricción |
| RN-16 | Elemento conceptual, Elemento relacional, Restricción |
| RN-17 | Elemento conceptual, Elemento relacional, Restricción |
| RN-18 | Elemento conceptual, Elemento relacional, Restricción |
| RN-19 | Elemento conceptual, Elemento relacional, Restricción |
| RN-20 | Elemento conceptual, Elemento relacional, Restricción |
### Anexo C — Cotejo del análisis y la normalización

| Apartado | Proyecto 1 inicial | Versión corregida | Correspondencia y efecto |
| --- | --- | --- | --- |
| Requerimientos de datos | 18 RD | 18 RD | Cambian los textos de RD-01, RD-04, RD-09; el resto conserva su identificador y redacción. |
| Requerimientos funcionales | 20 RF | 20 RF | Cambia el texto de RF-17; el resto conserva su identificador y redacción. |
| Requerimiento no funcional | 1 RNF | 1 RNF | RNF-01 permanece sin cambio textual. |
| Reglas de negocio | 20 RN | 20 RN | RN-01 a RN-20 conservan texto e identificadores; cambia su representación en la matriz. |
| Escenarios de validación | 5 válidos y 3 inválidos | 5 válidos y 3 inválidos | Se conserva el inventario de escenarios. |
| Glosario | 45 términos | 45 términos | Se conserva el inventario documentado. |
| Ambigüedades y supuestos | 20 filas | 20 filas | Se modificó la redacción de 15 filas y se conservaron cinco; véase el Anexo D. |
| Registro de decisiones | Sección «Registro de decisiones y correcciones de modelado», orientada a la simplificación por cuotas | Sección «Criterios de modelado» | Sustituye el criterio de recortar entidades/asociaciones por la fidelidad al caso y la necesidad de históricos; no se borra el antecedente del control de cambios. |
| Entidades conceptuales | 13 | 20 | Se incorporan siete conceptos con identidad necesaria para contactos, ventanas, actores e historia. |
| Atributos del diccionario conceptual | 33 filas | 48 filas | Mayor explicitud de identidad, temporalidad, estados, autorizaciones y antecedentes. |
| Asociaciones del diccionario conceptual | 13 | 20 | Nuevas asociaciones para hechos históricos y vínculos antes ausentes. |
| Modelo relacional | 19 relaciones | 26 relaciones | Correspondencia nominal de las 19 + siete nuevas en la sección 4. |
| Normalización | Cinco relaciones examinadas | 26 relaciones examinadas | El modelo deja de declararse provisional. |
| DER conceptual | Representación previa | Diagrama corregido | El SVG referenciado por `modelo/02_Modelo_Conceptual.md` conserva la representación gráfica corregida. |

El cotejo identifica las variaciones documentales sin tratar todo cambio de redacción o ejemplo como una entidad o requisito nuevo. Los criterios de evaluación siguen siendo los de la consigna: procedencia, corrección justificada y evidencia técnica reproducible cuando exista implementación.

### Anexo D — Diferencias concretas del análisis conceptual

**Antecedente del análisis:** el documento corregido actualiza además la descripción del problema, el alcance y las exclusiones, para retirar formulaciones provisionales y mantener el sistema limitado al caso universitario. El objetivo, la lista de actores, las necesidades de información, la lista de procesos relevantes, el glosario, RNF-01 y los ocho escenarios de validación se conservan en lo sustancial y no se presentan como nuevos componentes.

**Nuevos conceptos conceptuales (7):** `Contacto de estudiante`, `Persona autorizadora`, `Ventana de periodo`, `Cambio de oferta`, `Evento de solicitud`, `Excepción de requisito`, `Corrección de calificación`.

**Nuevas asociaciones conceptuales (7):** `Registra contactos`, `Habilita ventanas`, `Identifica autorizaciones`, `Documenta cambios de oferta`, `Documenta eventos de solicitud`, `Concede excepción`, `Documenta corrección`.

**Atributos del diccionario conceptual:** el original contiene 33 filas y el corregido 48. Las sustituciones de las cinco etiquetas anteriores que ya no aparecen son `Estudiante.Datos personales`, `Estudiante.Datos de contacto`, `Versión del plan de estudios.Vigencia`, `Periodo académico.Fechas de matrícula ordinaria` y `Periodo académico.Fechas de modificaciones`. La versión corregida incorpora 20 nuevas etiquetas atómicas o históricas, documentadas en la tabla de atributos del análisis. La representación relacional concreta de estas modificaciones se encuentra en el Anexo A, con 11 identificadores originales sustituidos y 69 atributos nuevos.

**Ambigüedades y supuestos:** las mismas 20 situaciones permanecen numeradas aquí por su *posición en la tabla*, exclusivamente para el cotejo (no son nuevos códigos RN ni requerimientos). Quince filas se reformularon y cinco conservaron exactamente los valores documentados. Los campos modificados de cada una de las quince son:

| Fila original/corregida | Identificación del tema original | Campos cuya redacción cambió |
| --- | --- | --- |
| 01 | Admisiones de una misma persona en una o varias carreras y alcance de unicidad de la admisión | Supuesto |
| 02 | Identidad independiente de plan de estudios frente a versión del plan | Supuesto |
| 04 | Identificación de la persona que autoriza un traslado de plan | Supuesto, Impacto |
| 06 | Distinción entre nivel académico y periodo recomendado de un curso | Supuesto |
| 08 | Alcance de un reconocimiento académico respecto del estudiante o su admisión | Supuesto, Impacto |
| 09 | Desglose y multiplicidad de datos personales y medios de contacto | Supuesto, Impacto |
| 10 | Relación entre condición académica y habilitación de una admisión activa | Supuesto |
| 11 | Representación de la vigencia de versiones de planes de estudio | Supuesto, Impacto |
| 13 | Almacenamiento independiente frente a derivación de los cursos aprobados | Supuesto, Impacto |
| 14 | Identificación de cursos reconocidos de origen institucional o externo | Supuesto, Impacto |
| 15 | Alcance de unicidad del número de grupo en la oferta académica | Supuesto, Impacto |
| 17 | Modalidad de grupo frente a presencialidad de cada bloque de horario | Supuesto |
| 18 | Condiciones para considerar elegible una solicitud en lista de espera | Supuesto |
| 19 | Escala de calificación dependiente del curso o modalidad de evaluación | Supuesto |
| 20 | Identidad común y roles de personas autorizadoras y responsables de eventos | Supuesto |

Este inventario complementa los cambios de identidad, atributos, dominios, restricciones e históricos de CC-P1-01 a CC-P1-13. No inventa nuevos hechos, actores ni reglas: cada variación se localiza mediante las secciones con el mismo título en las versiones original y corregida del análisis.

## 5. Cobertura de reglas, evidencia y pendientes

- La matriz lógica corregida está en `modelo/06_Matriz_Trazabilidad.md` y documenta RN-01 a RN-20 para las 26 relaciones y 135 atributos del modelo consolidado.
- La implementación física actual comprende 16 relaciones y 57 atributos. Sus mecanismos declarativos se encuentran en `sql/01_esquema_base.sql`, su semilla en `sql/02_datos_base.sql` y sus comprobaciones reproducibles en `pruebas/01_pruebas_base.sql`.
- La **matriz física relación/regla–mecanismo–prueba** exigida para el conjunto completo todavía debe consolidar las relaciones, operaciones y garantías restantes. La cobertura parcial comprobada no se presenta como validación integral del modelo.
- Quedan por verificar las condiciones que dependen de relaciones adicionales o de mecanismos entre relaciones. En particular, las FK individuales de ADMISION no garantizan por sí solas la correspondencia conjunta entre carrera, versión del plan y sede.
- Los resultados de las consultas, rutinas y pruebas históricas de Lab03 se distinguen de los comprobados en la versión actual. Las comprobaciones reproducibles del conjunto implementado y sus resultados observados se documentan en `pruebas/Pruebas.md` y `evidencias/Resultados.md`, respectivamente.
- Los supuestos no fijados por la fuente deben documentar fragmento, pregunta, interpretación adoptada e impacto. Las observaciones formativas de Lab03 no generan sanciones retroactivas ni obligan a introducir reglas arbitrarias.

## 6. Procedimiento de comprobación al entregar

1. Partir de un `CC-P1-*` y localizar su origen, la sección del modelo actual y la evidencia que se completará al ejecutar SQL.
2. Verificar que cada tabla física y relación de origen esté cubierta por su clave, referencia, dominio y prueba, o justificar documentalmente «no aplica».
3. Ejecutar pruebas en una base PostgreSQL nueva y registrar esperado/observado y lectura posterior de estado confirmado.
4. Reejecutar las consultas y rutinas heredadas de Lab03 en la estructura completa; distinguir sus resultados nuevos de la calificación histórica.
5. Localizar cada adaptación y reutilización en los archivos SQL de la versión actual y en sus pruebas; documentar en los archivos Markdown de pruebas y evidencias los resultados esperados, observados y el estado posterior. Diferenciar los componentes ya verificados de los pendientes.
