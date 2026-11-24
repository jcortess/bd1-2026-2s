# Modelo relacional consolidado · Grupo 05

Versión de consolidación Paula 1.0, 24 de noviembre de 2026. Jason Madrigal Pineda, María Paula Romero Garro y Jean Carlos Segura Vargas. Se parte del resultado **normalizado** de P1 §5.8–5.9, no del diagrama inicial §4.8 ni del recorte de ocho tablas de Lab03. [Fuentes y conciliación](Conciliacion_Paula.md) · [Diccionario físico por atributo](Diccionario_Datos.md) · [Diagrama físico](Diagrama_Relacional.md) · [Matriz](Matriz_Integridad.md).

Hay **19 tablas físicas disponibles**: las nueve de Jason, las nueve de Paula y `compatibilidad_animal_hogar`. Se conservan en el inventario las nueve originales de Jean Carlos, todavía sin SQL en esta rama. Por tanto, el paquete de equipo aún no alcanza el 100 % físico ni G05-P03. No se sustituyen esas relaciones por referencias externas ni por tablas ficticias.

## Correspondencia completa de las 27 relaciones y ampliación

Todas las relaciones originales mantienen su nombre en minúsculas dentro de `huellas`. Las claves completas, tipos, atributos, dominios, índices y restricciones de las disponibles están en el diccionario; las reglas operativas de Jason permanecen en [Modelo_Jason.md](Modelo_Jason.md).

| N.º | Relación de P1 §5.8 / anexo C | Lab03 | Físico actual y transformación | Responsable / evidencia |
|---:|---|---|---|---|
| 1 | PERSONA | Versión reducida | `persona`; identidad bigint y nombre opcional. RN-09, no RN-01. | Jason; I01 y regresión actual. |
| 2 | MEDIO_CONTACTO | Fuera del recorte | `medio_contacto`; medios conocidos múltiples. | Jason; I02. |
| 3 | PARTICIPACION | Fuera del recorte | `participacion`; roles/periodos/aprobación. Paula agrega protección del registro usado en hechos propios sin redefinir columnas. | Jason; I03. Paula R03/P09. |
| 4 | REPORTE | Fuera del recorte | `reporte`; reportante y datos descriptivos desconocidos admiten NULL. | Paula; R01/R02. |
| 5 | ANIMAL | Versión reducida | `animal`; identidad estable, microchip opcional único, edad en meses. | Jason; I04. |
| 6 | REPORTE_ANIMAL | Fuera del recorte | `reporte_animal`; PK `(reporte_id,animal_codigo)`, M:N. | Paula; R02. |
| 7 | ORGANIZACION_EXTERNA | Fuera del recorte | `organizacion_externa`; identificación mínima de organización. | Jason; I05. |
| 8 | INGRESO | Fuera del recorte | `ingreso`; etapa/animal, cierre y receptor. Paula agrega inicial diferida y protección del contexto clínico usado. Sigue bloqueo de origen de adopción hasta P03. | Jason I06/I10/I11; Paula P12/P13/R03. |
| 9 | UBICACION | Fuera del recorte | `ubicacion`; ofertas históricas identifican hogar físico. Oferente histórico preservado. | Jason; I07. |
| 10 | UBICACION_ESPECIE_ACEPTADA | Fuera del recorte | `ubicacion_especie_aceptada`; PK `(ubicacion_id,especie)`. | Jason; I08. |
| 11 | ESTANCIA | Fuera del recorte | `estancia`; conserva N-01: no se reincorpora `responsable_id`. Se deriva oferente; entrada/salida son otros actores. FK contextual a ingreso. | Jason; I09/I11, M01–M11. |
| 12 | EVALUACION_SALUD | Implementada | `evaluacion_salud`; añade ingreso, registro veterinario vigente y precisión temporal; conserva revisión completa y discriminador. | Paula; R03, P12/P13. |
| 13 | DIAGNOSTICO | Implementada | `diagnostico`; PK propia y nombre único/no vacío, sin estado clínico en catálogo. | Paula; R04/R05. |
| 14 | DIAGNOSTICO_REVISION | Implementada | `diagnostico_revision`; PK `(evaluacion_id,diagnostico_id)` y FK discriminada a revisión. Se preserva el hecho clínico, sin borrado en cascada. | Paula; R05/H01. |
| 15 | INDICACION | Implementada en recorte | **Pendiente en final**; no se ha trasladado SQL de Jean Carlos. Debe conservar revisión y sustitución clínica coherente. | Jean Carlos. |
| 16 | INDICACION_DIAGNOSTICO | Implementada con defecto A2 | **Pendiente**; añadir contexto de evaluación y ambas FK compuestas al integrar. El destino `(evaluacion_id,diagnostico_id)` ya está disponible. | Jean Carlos; ver contrato de integración. |
| 17 | APLICACION_INDICACION | Implementada | **Pendiente**; revalidar obligatoriedad de ejecución, `registrar_aplicacion`, consultas Q02/Q04 y reporte. | Jean Carlos. |
| 18 | CAMBIO_DISPONIBILIDAD | Fuera del recorte | `cambio_disponibilidad`; etapa, actor/participación y valoración obligatorios. Historial inmutable; ninguna enfermedad decide. | Paula; R06/H01. |
| 19 | SOLICITUD_ADOPCION | Fuera del recorte | `solicitud_adopcion`; datos del hogar, fecha y UUID de operación. Hogar conservado por solicitud. | Paula; P01/P05/P08/R07. |
| 20 | SOLICITUD_ANIMAL | Fuera del recorte | `solicitud_animal`; interés M:N con fecha, sin resultado favorable implícito. | Paula; P02/P08. |
| 21 | EVENTO_SOLICITUD | Fuera del recorte | `evento_solicitud`; reemplaza `resultado_estado` por resultado de actividad o estado de decisión, con antecedente/razón e historial. | Paula; P02/P06/P09/R08/H02, C-P01–03. |
| 22 | RESERVA | Fuera del recorte | **Pendiente**; debe consumir la compatibilidad de la solicitud/animal/ingreso y conservar atribución y exclusividad. | Jean Carlos. |
| 23 | ADOPCION | Fuera del recorte | **Pendiente**; animal debe coincidir con ingreso, cierre sin resultado incompatible y responsabilidades no vacías. | Jean Carlos con Jason. |
| 24 | ADOPCION_RESPONSABLE | Fuera del recorte | **Pendiente**; asociación M:N del trámite, distinta del solicitante/adoptante. | Jean Carlos. |
| 25 | SEGUIMIENTO_ADOPCION | Fuera del recorte | **Pendiente**; reprogramación conserva origen/adopción y evita ciclos. | Jean Carlos. |
| 26 | RESTRICCION_PERSONA | Fuera del recorte | **Pendiente**; decisión expresa, sin prohibición automática por devolución. | Jean Carlos. |
| 27 | RESULTADO_ETAPA | Fuera del recorte | **Pendiente**; resultado no adoptivo, contexto y exclusión con adopción. | Jean Carlos con Jason. |
| 28 | Ampliación RN-19 / calificación F10–F14 | No existía | `compatibilidad_animal_hogar`; valoraciones sucesivas individualizadas, no renominación de interés ni reserva. | Paula; P03/P04/P10/P11/R09/H02. |

## Claves y cardinalidades del bloque de Paula

- REPORTE puede existir sin reportante y sin animales todavía identificados; al identificarlos, REPORTE_ANIMAL conserva M:N con PK completa. Un ingreso no exige reporte ni se convierte el enlace de animal en enlace de etapa no previsto en P1.
- INGRESO tiene exactamente una inicial al confirmar una nueva etapa y cero o muchas revisiones. La inicial puede tener datos clínicos desconocidos y no exige veterinario (S-02). Cada revisión exige profesional, registro vigente, fecha, motivo, observaciones, peso positivo finito en kg y recomendaciones. La evaluación pertenece al mismo animal de su ingreso. Sus instantes están en `[fecha_ingreso,fecha_cierre)`.
- Una revisión tiene cero o muchos diagnósticos; cada aparición corresponde a un diagnóstico del catálogo. Un diagnóstico puede aparecer en muchas revisiones. La pareja es mínima: ninguno de sus componentes determina el estado por sí solo. No se inventa un diagnóstico para obligar a que toda revisión tenga uno.
- ANIMAL/INGRESO tienen cero o muchas decisiones de disponibilidad, con responsable, participación, observación y valoración. La última dentro de la etapa es la decisión vigente. Un reingreso no hereda una habilitación de la etapa anterior.
- Una PERSONA presenta cero o muchas solicitudes, incluso después de un rechazo. La solicitud conserva una instantánea de su hogar y requiere recepción atribuible. Tiene cero o muchos animales de interés; puede seguir siendo general. Cada pareja tiene una sola fecha de inclusión. El interés no es evaluación.
- La solicitud tiene una recepción, cero o muchas actividades y cero o muchas decisiones posteriores. Cada decisión tiene un antecedente de la misma solicitud, que debe ser la última decisión confirmada. Una actividad no altera estado global.
- Cada interés tiene cero o muchas valoraciones por etapa. Cada valoración identifica solicitud/hogar, animal, ingreso, responsable, resultado, contexto y razones. Una actividad de apoyo es opcional; cuando se indica, debe ser de esa solicitud, previa y de tipo actividad. La evaluación concreta completa también puede constituir su propio fundamento. No se exige visita a todos los hogares.

## Decisiones y límites de interpretación

| ID | Fragmento / pregunta | Decisión propuesta por Codex e impacto |
|---|---|---|
| D-P01 | RN-19, calificación F10/F11/F14: falta valorar animal–hogar. ¿Tabla adicional? | Mantener interés y añadir historial `compatibilidad_animal_hogar`. La referencia compuesta de contexto puede ser consumida por P03. Propuesta implementada; la validación humana del contrato por Jean Carlos sigue pendiente. |
| D-P02 | P1 §3.4 menciona ID artificial y §5.8 usa pareja de diagnóstico. | Conservar la pareja de P1 normalizado y Lab03. No existen dos identidades contradictorias. La FK discriminada admite solo revisiones. El estado es del diagnóstico en esa revisión. |
| D-P03 | S-16/RN-16: los datos del hogar son descriptivos. ¿Qué hogar se evaluó? | La solicitud es una instantánea inmutable de sus cuatro descripciones. La valoración refiere esa solicitud; así no se aplica a un hogar reinterpretado por una edición. Información adicional se conserva como actividad INFORMACION. Un cambio material del hogar se tramita como nueva solicitud; no se deduce un plazo ni una prohibición de reaplicar. |
| D-P04 | RN-18 enumera estados sin grafo de transiciones ni duración. | No imponer grafo terminal, mínimo de entrevistas, visita universal ni vencimiento por días. Se admite pasar entre los siete estados (o ratificar el mismo) con razón, responsable, fecha no anterior y antecedente vigente. RECIBIDA inicial procede de recepción. Una rectificación es una nueva decisión, no un UPDATE. |
| D-P05 | RN-10 exige inicial y revisiones posteriores; no fija demora en horas/días. | Una inicial por etapa mediante índice parcial; requisito de existencia diferido hasta COMMIT del ingreso, para permitir cabecera e inicial en una transacción. Revisión requiere inicial no posterior. No exigir que una inicial sea veterinaria ni crear datos médicos automáticamente. |
| D-P06 | RN-09/10 y anexo C: profesional registrado y actor atribuible. | Profesional con participación VETERINARIO/REGISTRADO vigente en `[inicio,fin)` y registro no posterior. Actividades/decisiones con personal permanente o voluntario vigente; se conserva la participación elegida. La política concreta de estos dos roles es decisión técnica, sin sistema de autenticación de aplicación. |
| D-P07 | README §6: competencia por decisiones. ¿Cómo evitar pérdida? | Reutilizar el bloqueo transaccional de Jason, primero en todas las rutas; después bloquear solicitud y comprobar antecedente. READ COMMITTED obligatorio. Coste: también se serializan solicitudes independientes. Pruebas reales C-P01/C-P02; un reintento informado agrega decisión y preserva ambas. |
| D-P08 | README §6: respuesta perdida/reenvío. | UUID único por operación persistida; una repetición se rechaza por unicidad o antecedente viejo sin efectos. Quien ejecuta consulta por clave antes de reenviar. La asociación usa la PK pareja como identidad de efecto. No se afirma que un nuevo UUID sea el mismo intento lógico. |
| D-P09 | RN-14/15: salud influye, no determina. | Observación y valoración humanas obligatorias, incluso al suspender/restablecer. No hay umbral médico, catálogo de enfermedades prohibidas ni diagnóstico que cree disponibilidad/reserva. |
| D-P10 | Historia clínica/administrativa y rutas de modificación. | Evaluaciones, apariciones diagnósticas, disponibilidad, solicitud, interés, eventos y compatibilidad son hechos append-only. Cambios de estado se documentan en nuevas revisiones/decisiones; el catálogo diagnóstico y reportes desconocidos sí permiten completar/corregir datos como instalador. No se ofrece borrado clínico operativo. |

## Dependencias funcionales y transformaciones

Se conserva N-01 de P1 en el bloque de Jason. `id_solicitud → solicitante,fecha,datos_hogar,clave_operacion`; por cada solicitud, su hogar no cambia. `id_evento_solicitud → solicitud,fecha,tipo,responsable,resultado/estado,razón,antecedente` y `clave_operacion` es otra clave candidata no nula de esa tabla. `id_compatibilidad → solicitud,animal,ingreso,fecha,valoración,resultado,razones,actividad`; UUID es clave alternativa. La pareja solicitud–animal **no** determina un único resultado histórico: las reevaluaciones necesitan identidad propia.

Las FK compuestas redundantes en claves de referencia no se presentan como nuevas DF del negocio: sirven para igualdad de contexto. Los discriminadores de revisión son constantes físicas. No se declara BCNF de todo el modelo ampliado sin considerar las redundancias controladas de contexto (`ingreso → animal`, `participacion → persona`), conservadas para comprobar pertenencia mediante FK/trigger. La misma distinción ya se aplicaba en P1 a los hechos históricos y exclusividad temporal.

La aprobación general no exige que todos los animales resulten compatibles ni adjudica ninguno. `_exigir_compatibilidad` solo devuelve la última valoración favorable de esa combinación cuando existe aprobación general vigente y etapa correcta abierta. Jean Carlos debe añadir disponibilidad, restricciones, exclusividad y formalización. Los nueve objetos pendientes se mantienen identificados hasta contar con su implementación y pruebas reales.
