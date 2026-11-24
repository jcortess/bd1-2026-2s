# Matriz consolidada relación/regla–mecanismo–prueba

Consolidación Paula 1.0. Los números RN-01…RN-25 conservan P1 §2; AC refiere el [anexo vigente](../05_Grupo_05_Refugio.md). Las claves de caso se localizan individualmente en [Casos_Paula.md](../pruebas/Casos_Paula.md). **Verificada** solo cubre el mecanismo y escenario descritos, no una aprobación global de procesos pendientes. [Modelo](Modelo_Relacional.md) · [Diccionario](Diccionario_Datos.md) · [Resultados actuales](../evidencias/Resultados_Paula.md).

## Bloque de Paula y ampliación

Para todas estas filas, el SQL de estructura es [05](../sql/05_paula_esquema.sql), los triggers/rutinas están en [06](../sql/06_paula_operaciones.sql), los datos ficticios en [07](../sql/07_paula_datos.sql) y las vistas/consumo en [08](../sql/08_paula_consultas.sql). La evidencia secuencial completa está en [transcripción](../evidencias/Ejecucion_Paula_Secuencial.md).

| Relación | Regla y fuente | Representación física / mecanismo | Categoría | Pruebas | Evidencia / estado |
|---|---|---|---|---|---|
| REPORTE | RN-02, P1 pp.5/50; S-07 | PK propia, FK opcional reportante, `instante`/textos opcionales con dominio; completar desconocidos permitido. | Identidad, referencia, dominio, nulabilidad, modificación | R01-reporte-pk/persona/texto/fecha; R02-rectificacion-valida y P15 | Transcripción; verificada. |
| REPORTE_ANIMAL | RN-02, P1 pp.29/51 | PK pareja y dos FK NO ACTION; vínculo M:N, sin inventar enlace obligatorio al ingreso. | Identidad compuesta, referencia, nulos, modificación/eliminación | R02-pareja-duplicada/reporte-ausente/animal-ausente/clave-incompleta/padre-delete/padre-update/rectificacion-valida | Transcripción y P15; verificada. |
| EVALUACION_SALUD | RN-10 y F11/F12 | PK propia; FK `(ingreso_id,animal_codigo)`; revisión exige motivo, observación, peso finito >0, recomendación y profesional/registro. | Identidad, contexto, dominio, obligatoriedad | R03-evaluacion-pk/contexto-ajeno/ingreso-ausente/sin-veterinario/sin-motivo/sin-observaciones/sin-peso/sin-recomendaciones/peso-cero/peso-nan | Transcripción; verificada. |
| EVALUACION_SALUD / INGRESO | RN-10, anexo C, S-02 | Inicial única por etapa; trigger diferido exige existencia al confirmar, revisión exige inicial previa, `[ingreso,cierre)`; protege datos de etapa usados. | Entre filas, contexto temporal, cierre/modificación | R03-inicial-duplicada/antes-ingreso/etapa-modificada; P12-ingreso-sin-inicial; P13-revision-sin-inicial-etapa/evaluacion-fin-etapa/iniciales-por-etapa | Transcripción y lectura posterior a COMMIT; verificada. |
| EVALUACION_SALUD / PARTICIPACION | RN-09/10, anexo C; observación formativa Lab03 ahora aplicable | FK al registro y trigger de VETERINARIO/REGISTRADO, persona y vigencia; protección de participación histórica. | Referencia contextual, vigencia, modificación/eliminación | R03-registro-ajeno/fin-registro/frontera-valida/registro-historico/registro-delete | Transcripción; verificada. |
| EVALUACION_SALUD | RN-10, README §4, decisión D-P10 | Historia append-only, sin CASCADE nuevo. | Modificación, eliminación, historia | H01-evaluacion-update/delete, P15 | Transcripción; verificada. |
| DIAGNOSTICO | RN-11, P1 p.56 | PK, nombre NN/UQ/texto no vacío sin espacios exteriores; FK de apariciones impide perder catálogo usado. | Identidad, clave alternativa, dominio, nulos, modificación/eliminación | R04-catalogo-pk/nombre/nulo/vacio; R05-catalogo-delete/update | Transcripción; verificada. |
| DIAGNOSTICO_REVISION | RN-11, F10; Lab03 FK discriminada | PK `(evaluacion_id,diagnostico_id)`; FK `(evaluacion_id,tipo_evaluacion)` solo revisión y FK catálogo; estados PROVISIONAL/CONFIRMADO/DESCARTADO. | Identidad completa, referencias, dominio, obligatoriedad, contexto | R05-pareja-pk/no-inicial/diagnostico-ausente/estado/estado-nulo/reutilizacion-clinica | Transcripción; verificada. |
| DIAGNOSTICO_REVISION | RN-11/12, decisión de historia | Aparición inmutable; una revisión posterior expresa cambio de valoración. Destino de FK clínica disponible para Jean Carlos. | Historia, modificación/eliminación; integración clínica | H01-diagnostico-update/delete; R05 | Historia verificada. FK desde INDICACION_DIAGNOSTICO **pendiente de Jean Carlos**. |
| CAMBIO_DISPONIBILIDAD | RN-14/15, P1 pp.58–59; anexo AC-04 | PK/FK etapa-animal; actor/participación, fecha, observación y valoración NN; estado categórico; vista última decisión. | Identidad, referencia/contexto, dominio/nulos, entre filas | R06-disponibilidad-pk/contexto/observacion/valoracion/dominio/actor/historia-sin-automatismo | Transcripción; verificada. |
| CAMBIO_DISPONIBILIDAD | RN-14/15, README §4 | Historia inmutable; no trigger desde diagnóstico que habilite o reserve. | Modificación/eliminación, historia, independencia de decisión | H01-disponibilidad-update/delete; R06-historia-sin-automatismo; P15 | Verificada; consumo desde P03 pendiente. |
| SOLICITUD_ADOPCION | RN-09/16/18, S-16 | PK/UUID UQ, solicitante FK; cuatro datos del hogar NN/no vacíos; fecha; recepción diferida obligatoria. | Identidad, referencia, dominio/obligatoriedad, entre relaciones | P01-general, P08-solicitante-fk/vivienda-nula/texto-vacio/reintento-clave; R07-solicitud-pk; P12-solicitud-sin-recepcion | Transcripción; verificada. |
| SOLICITUD_ADOPCION | RN-18/19, D-P03 | Hogar inmutable por solicitud; nuevas solicitudes conservan historia anterior, sin UQ por persona. | Modificación/eliminación, historia/contexto | P05-nueva-tras-rechazo; H02-hogar-inmutable/solicitud-delete; R09-hogares-separados | Transcripción; verificada. |
| SOLICITUD_ANIMAL | RN-16/19, S-10 | PK completa, FK solicitud/animal; fecha >= recepción. Array puede estar vacío. | Identidad, referencia, dominio/contexto temporal | P01/P02/P05; P08-interes-duplicado/solicitud-ausente/interes-animal-ausente/duplicado-en-alta/fecha-anterior/fecha-futura | Transcripción; verificada. |
| SOLICITUD_ANIMAL | RN-19, README §4 | Solo interés, append-only; no resultado médico ni de compatibilidad en la asociación. | Historia, modificación/eliminación, separación de hechos | P03-interes-no-compatible; H02-interes-update/delete; P15 | Transcripción; verificada. |
| EVENTO_SOLICITUD | RN-17, F12 | Actividad con tipo, fecha, actor/participación, resultado y observación; `evento_contenido` exige estado/razón nulos en actividad. | Identidad, referencia, dominio, obligatoriedad, contexto | P02-interes-actividad; P06-estados; P09-responsable-ausente/desconocido/actor-sin-rol/actividad-sin-observacion/actividad-sin-resultado/tipo-no-actividad/reintento-actividad; R08-evento-pk | Transcripción; verificada. |
| EVENTO_SOLICITUD | RN-18, F12/F14; README §6 | Decisión con estado/razón y antecedente vigente; recepción única; vista deriva estado; todas las decisiones se preservan. | Identidad, contexto, dominio/nulos, entre filas, historia | P03/P05/P06; P09-sin-razon/sin-estado/estado-invalido/antecedente-viejo; H02-evento-update/delete; P15 | Transcripción; verificada. |
| COMPATIBILIDAD_ANIMAL_HOGAR (ampliación) | RN-19, F9/F10/F11/F14 | PK/UUID UQ, FK interés, FK etapa-animal, actividad contextual opcional, resultado/valoración/razones NN y hogar derivado de solicitud inmutable. | Identidad, referencia, dominio/obligatoriedad, contexto | P03/P04; P10-interes-no-evaluado/ingreso-animal-ajeno/actividad-otra-solicitud/decision-no-actividad/evaluacion-sin-contexto/dominio/evaluacion-antigua; R09-compatibilidad-pk/hogares-separados | Transcripción; verificada. |
| COMPATIBILIDAD_ANIMAL_HOGAR | RN-19, README §6 | Historial, vista vigente y `_exigir_compatibilidad` exige aprobación + última favorable de etapa correcta. | Entre filas, historia, modificación/eliminación, precondición | P03-sin-aprobacion/interes-no-compatible; P04-no-favorable/etapa-ajena; P11-vigente-pendiente/historia-individual; H02-compatibilidad-update/delete | Transcripción; verificada. Consumo en reserva real pendiente. |
| SOLICITUD_ADOPCION / ANIMAL / EVENTO_SOLICITUD | README §6/7, atomicidad | Una llamada crea cabecera, recepción y detalles; error en segundo detalle revierte todos. | Transacción/ausencia de efectos parciales | P07-atomicidad/sin-parciales, P15 | Valores persistidos después de error y COMMIT posteriores; verificada. |
| EVENTO_SOLICITUD / SOLICITUD_ADOPCION | README §6; anexo P02 | Bloqueo asesor compatible con Jason, fila de solicitud y versión por antecedente en READ COMMITTED. | Concurrencia, reintento e historia | C-P01 (A COMMIT/B rechazo), C-P02 (A ROLLBACK/B confirma), C-P03 (reenvío y nueva decisión informada) | [Dos sesiones reales y observador](../evidencias/Ejecucion_Paula_Concurrencia.md); verificada. |
| Las diez relaciones del bloque | README §4, rutas permitidas | Rol operativo SELECT + operaciones públicas; sin DML/TRUNCATE/privadas; triggers y FK para preparación por propietario. | Permisos y control de escritura | P14; [03_catalogo_paula.sql](../pruebas/03_catalogo_paula.sql) | Evidencia de catálogo y permisos; verificada. |

## Criterios de aceptación G05-P02

| Criterio | Demostración | Estado / límite |
|---|---|---|
| AC-G05-P02-01 | General, interés posterior, varios animales y valoraciones distintas; P01–P04/P10/R09. | Verificado en bloque Paula. |
| AC-G05-P02-02 | Fecha/actor/resultado/observaciones de actividad y razones/antecedentes de decisión; P02/P05/P06/P09. | Verificado; visita solo cuando corresponde. |
| AC-G05-P02-03 | Rechazo registrado y nueva solicitud separada de la misma persona; P05. | Verificado, sin perder historia. |
| AC-G05-P02-04 | Diagnóstico confirmado coexiste con habilitación decidida; ninguna regla médica ni escritura de reserva en P02; P03/P04/R06/P15. | Verificada independencia clínica y ausencia de creación de reserva en el paquete actual. Comprobar conteo de RESERVA real antes/después **pendiente de Jean Carlos** al integrarla. |
| G05-P02-V/I/L y transacción/concurrencia | P01–P11, P15, C-P01–03. Rechazo técnico deja intactos fundamentos; RECHAZADA conserva su resultado de negocio. | Verificado dentro del bloque; no se afirma ejecución de P03. |

## Consolidación del bloque existente de Jason

Se mantiene su [matriz original](Matriz_Jason.md) y [evidencia histórica](../evidencias/Resultados_Jason.md). La [regresión actual](../evidencias/Ejecucion_Paula_Regresion_Jason.md) ejecutó el guion original sin cambios sobre una base nueva con ambos bloques: sus 85 rechazos previstos y aserciones pasaron. También se repitieron sus dos carreras con observador y guiones originales: [regresión concurrente actual](../evidencias/Ejecucion_Paula_Regresion_Jason_Concurrencia.md). Ambas se distinguen de la historia previa C1/C2.

| Relación | Regla / representación / mecanismo existente | Categoría y prueba identificable | Estado |
|---|---|---|---|
| PERSONA | RN-09/S-06/S-07; PK/identidad y nombre opcional; FK entrantes. | Identidad, dominio, referencias: I01/I02. | Verificada por Jason y regresión actual. |
| MEDIO_CONTACTO | RN-09/S-07; PK, FK persona, tipo/valor NN. | Identidad, referencia, obligatoriedad: I02. | Verificada. |
| PARTICIPACION | RN-07/09; PK, FK, periodos y aprobación; protección de evidencia histórica. | Identidad, referencia, dominio, modificación/eliminación: I03/M05/M09; Paula añade R03/P09. | Verificada para usos disponibles. |
| ANIMAL | RN-01/03; PK estable, microchip UQ opcional, edad no negativa, especie común. | Identidad, dominio, contexto/historia: I04/I11/M07. | Verificada. |
| ORGANIZACION_EXTERNA | RN-04/25/S-09; PK/nombre NN y referencia desde INGRESO. | Identidad, obligatoriedad, eliminación: I05/I06. | Verificada para ingreso; destino de RESULTADO_ETAPA pendiente. |
| INGRESO | RN-01/02/04/23/25; FK etapa/animal, exclusión GiST, datos condicionales/receptor, bloqueo de origen de adopción. | Identidad, referencia, dominio, contexto/historia: I06/I10/I11. | Verificado sin regreso completo; referencia a ADOPCION pendiente. |
| UBICACION | RN-06/07/08; datos por tipo, FK oferente, oferta/exclusión, inmutabilidad de configuración usada. | Identidad, dominio, contexto/periodos y cambio/eliminación: I07/M02/M06–M11. | Verificada. |
| UBICACION_ESPECIE_ACEPTADA | RN-07; PK pareja, FK y restricción de hogar; protege especie usada. | Identidad, referencia, tipo/nulo/historia: I08/M07. | Verificada. |
| ESTANCIA | RN-05/06/07/08/14; FK contextual, exclusión, condición/capacidad, actores/plan y ruta controlada. | Identidad, referencia, dominio/contexto, atomicidad/permisos: I09/I11/I12/M01–M11 y C1/C2. | Verificada secuencial y concurrentemente en la integración actual; formalización desde P03 pendiente. |

## Relaciones/reglas pendientes de Jean Carlos

| Relación | Regla / requisito que debe conservar | Mecanismo disponible o requerido | Prueba pendiente / responsable |
|---|---|---|---|
| INDICACION | RN-12; solo revisión, sustitución sin ciclos del mismo animal/contexto. | Destino `(id_evaluacion,tipo_evaluacion)` disponible; tabla/rutina aún no entregadas. | Referencia discriminada y sustitución; Jean Carlos. |
| INDICACION_DIAGNOSTICO | RN-12; defecto A2 de Lab03. | Dos FK contextuales con evaluación: a indicación y a pareja de diagnóstico de revisión. | Dos revisiones válidas, diagnóstico solo en segunda e indicación de primera; Jean Carlos. |
| APLICACION_INDICACION | RN-13; plan distinto de ejecución completa. | Reutilizar CHECK y procedimiento con bloqueo de Lab03; referencias reales. | Válido, incompleto, doble ejecución, rollback y consultas; Jean Carlos. |
| RESERVA | RN-19/20; compatibilidad favorable concreta y exclusividad. | Consumir primitiva/vistas de Paula y FK de contexto; tabla ausente. | Conteo antes/después de aprobación, dos familias concurrentes; Jean Carlos. |
| ADOPCION | RN-21/23; animal-ingreso correctos, un resultado y responsables. | FK contextual y cierre privado de Jason; compatibilidad de Paula disponible. | Contexto ajeno, doble cierre, fallo intermedio, formalización real; Jean Carlos con Jason. |
| ADOPCION_RESPONSABLE | RN-21; al menos un responsable por trámite. | PK pareja y obligación de existencia al formalizar, aún ausente. | Identidad/referencia/cierre sin responsable; Jean Carlos. |
| SEGUIMIENTO_ADOPCION | RN-22/S-15; fecha/resultado de realizado y misma adopción al reprogramar. | Autorreferencia contextual y control de ciclos, aún ausente. | Reprogramación válida/ajena/cíclica y nulos condicionales; Jean Carlos. |
| RESTRICCION_PERSONA | RN-24; decisión propia y vigencia; no nace por devolución. | FK a persona/actor y motivo/periodo, aún ausente. | Devolución sin prohibición automática; Jean Carlos. |
| RESULTADO_ETAPA | RN-25/S-08/S-09; resultado/actor/circunstancias y destino en traslado. | Contexto de ingreso y exclusión con ADOPCION; aún ausente. | Identidad, referencias, dominio, doble cierre y retorno; Jean Carlos con Jason. |

Estas filas están **pendientes**, no «no aplica». Ninguna relación original desaparece. RN-19 tiene cobertura de interés/compatibilidad/decisión completa en Paula y adjudicación pendiente en Jean Carlos. RN-23 receptor es representable y ya tiene FK de Jason; solo su regreso íntegro depende de integrar adopción.

## Categorías no aplicables y alcance de evidencia

- REPORTE admite datos desconocidos; no hay categoría de compatibilidad/etapa que cruzar en esa tabla. REPORTE_ANIMAL tiene dos identidades, pero el caso no exige que pertenezca a una etapa de ingreso concreta. Sus comprobaciones de contexto son las FK de la pareja.
- DIAGNOSTICO es un catálogo raíz: no tiene FK saliente, responsable profesional, periodo ni cantidad acumulada. La vigencia y el estado clínico pertenecen a EVALUACION_SALUD/DIAGNOSTICO_REVISION.
- No hay capacidad ni exclusividad de adjudicación en solicitudes o compatibilidades: varias familias pueden considerar/evaluar el mismo animal. Esas categorías corresponden a P01/P03; imponer unicidad por animal en compatibilidad reduciría el caso.
- No se exige una cardinalidad mínima de diagnósticos ni visita para cada solicitud. Se prueban los datos exigidos cuando esos hechos existen. No se reemplazan pendientes del modelo completo por un «no aplica».
- Los datos clínicos preparados y su integridad no prueban ejecución de indicaciones, devolución, seguimiento ni reserva. Se mantienen separados de los tres procesos asignados.
