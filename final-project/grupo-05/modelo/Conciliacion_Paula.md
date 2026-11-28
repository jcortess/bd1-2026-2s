# Conciliación Proyecto 1 → Lab03 → entrega final · Paula

Fuentes examinadas completas: `Huellas_Seguras.pdf` (74 páginas, incluidas tablas y diagramas pp.12,33,47), `Hoja_Calificacion_Proyecto_ROMERO GARRO MARIA PAULA.xlsx` (ambas hojas, observaciones F9–F15), `Distribucion Proyecto Final.docx` (párrafos y cinco tablas), los archivos SQL/Markdown e imágenes de Lab03 y todos los archivos disponibles de la carpeta final. Los nombres reales de Word/PDF carecen del sufijo `(1)` indicado en la solicitud; se usaron los archivos explícitamente adjuntos disponibles. No faltó ninguno de esos tres documentos.

La solicitud de desarrollo está archivada en [Prompt_Desarrollo_Paula.md](../evidencias/Prompt_Desarrollo_Paula.md). El Word asigna trabajo; las reglas académicas vienen del [README oficial](../../README.md), el [anexo](../05_Grupo_05_Refugio.md) y la [especificación de cambios](../../Control_de_Cambios_Especificacion.md). Se comprobó `origin/main` mediante fetch: estos tres documentos no diferían de los locales al iniciar. No se trata el contenido de documentos históricos como instrucciones para modificar otras ramas o implementar procesos ajenos.

## Versiones y trabajo previo

La intervención comenzó con HEAD `18359c4` (`version_1.1`, Jason), rama `grupo-05`, árbol limpio, remoto `https://github.com/jcortess/bd1-2026-2s.git`; local y remoto tenían cero commits de diferencia después de fetch. El commit anterior del bloque es `9016e06`. No se ejecutó push, merge, PR ni commit. Lab03 tiene evaluación docente de versión `c55142cfdfab8caaaa56871d526d21e30e8d0584`; la retroalimentación se incorporó posteriormente en `461a85d726a6a13b41eca22c68e48c00cd9d592e`. El [README de Lab03](../../../lab03/grupo-05/README.md) y sus capturas documentan el recorte clínico de ocho tablas, no el modelo completo.

Los archivos SQL de Lab03 disponibles coinciden con la versión evaluada `c55142c` al comparar su contenido mediante Git; no se editaron. El anexo oficial conserva dos enlaces relativos anteriores que no resuelven (`00_Enunciado_General.md` y `Control_de_Cambios_Especificacion.md` desde su misma carpeta). Se mantuvo ese documento oficial intacto; las referencias correctas que usa esta consolidación son `final-project/README.md` y `final-project/Control_de_Cambios_Especificacion.md`. Los enlaces de los documentos nuevos/modificados se comprobaron por separado.

P1 conserva 27 relaciones y 150 atributos en su versión normalizada declarada. §4 conserva un modelo inicial; §5.8–5.9 prevalece para N-01. P1 §7 contiene referencias a una sección 9 y a C01–C09 sin un desarrollo autónomo recuperable en el PDF. Las menciones dispersas no permiten inventar nueve hallazgos originales. La consolidación sustituye esas referencias por fuentes identificables (RN, página y celda docente) y por cambios P-01…P-07; no pretende reconstruir contenido ausente.

## Correcciones y clasificación

| Fuente | Clasificación | Hallazgo / tratamiento actual | Estado y comprobación |
|---|---|---|---|
| Calificación F9/F10/F11/F14, P1 RN-19 pp.6/70 | Requisito omitido | El interés no representaba valoración animal–hogar. Historial adicional, resultado individual y contexto inmutable. | Implementado por Paula; P03/P04/P10/P11/R09. P03 del equipo debe consumirlo. |
| F10, P1 §3.4 y §5.8.3 | Inconsistencia documental | ID conceptual artificial frente a PK pareja. Se conserva la pareja ya implementada en Lab03 y su discriminador. | R05/H01 y diccionario/diagrama actual. |
| F11/F12, RN-10 | Requisito explícito | Revisión efectuada sin atributos exigidos no es información opcional desconocida. Se conserva CHECK de Lab03 y se añade profesional vigente e ingreso. | R03, P12/P13; inicial sin veterinario permitida. |
| Lab03 A2, retroalimentación | Defecto probado | INDICACION_DIAGNOSTICO aceptaba diagnóstico de otra evaluación. Pareja destino correcta disponible; falta instalar las dos FK contextuales en la asociación de Jean Carlos. | **Pendiente de Jean Carlos**, sin afirmar que se corrigió la relación ausente. |
| Lab03, observaciones de roles/ingreso sin descuento | Observación formativa que ahora coincide con alcance final explícito | El recorte podía omitir participación e ingreso; el final no. Se integran como relaciones internas reales. | R03/P12/P13. No modifica la calificación histórica. |
| F12/F14, RN-17/18 | Requisito y precisión semántica | Separar resultado de entrevista de estado general; razón de decisiones y observaciones de actividades obligatorias. | P02/P05/P06/P09, H02, C-P01–03. |
| F12/F14/F15 | Error documental | Retirar C01–C09/sección 9 sin desarrollo; definir dominios reales, condiciones de NULL y referencias verificables. | Diccionario extraído de catálogo, casos ejecutados y matriz. |
| F12, PERSONA.id_persona | Asociación documental incorrecta | PERSONA se vincula a RN-09/S-06; RN-01 identifica ANIMAL. | Conserva corrección previa de Jason y la aplica al diccionario consolidado. |
| F14, RN-23 | Requisito representable | Receptor sí se representa con FK. Jason ya lo incorporó; el regreso completo sigue bloqueado por adopción pendiente. | Regresión I10; FK y CHECK presentes, sin declarar regreso válido probado. |
| F11, ADOPCION.animal/ingreso | Requisito contextual | La adopción debe referir animal e ingreso coherentes. Jason preparó clave destino e integración; falta ADOPCION. | Pendiente de Jean Carlos con Jason. |
| F15, afirmación de coherencia general | Límite de evidencia | Se declara solo lo ejecutado; catálogo, guiones, observados y pendientes identificados. No se atribuyen revisiones humanas a quien no las ha realizado. | Evidencias actuales separadas de las históricas. |

## Supuestos S-01 a S-16 y reglas condicionadas

| Supuesto P1 pp.8–10 | RN / decisión | Correspondencia actual y estado |
|---|---|---|
| S-01, nombre actual | RN-01 | ANIMAL de Jason mantiene nombre actual; no se inventa historial nominal. |
| S-02, inicial distinta de revisión | RN-10 | INICIAL permite datos desconocidos y profesional ausente; REVISION exige completitud y acreditación. |
| S-03, periodos de hogar | RN-07 | UBICACION de Jason versiona ofertas, no sobrescribe oferente usado. |
| S-04, adoptante principal | RN-21 | Derivable de solicitante al integrar; ADOPCION pendiente. |
| S-05, devolución/recuperación distintas | RN-23 | INGRESO distingue ambas; receptor obligatorio en ambas, referencia a adopción pendiente. |
| S-06, identidad única con roles | RN-09 | PERSONA/PARTICIPACION compartidas; el rol no crea otra persona. |
| S-07, reportante/contacto conocidos | RN-02/09 | REPORTE admite NULL; medios disponibles de PERSONA no son un requisito de ingreso. |
| S-08, cuidado prolongado cierra etapa | RN-25 | Contexto de INGRESO disponible; resultado no adoptivo aún de Jean Carlos. P13 prueba dos etapas como datos ficticios, sin simular resultado final. |
| S-09, organización mínima | RN-04/25 | Organización identificable con nombre, sin inventar catálogo de contactos. |
| S-10, consideración posterior | RN-16/19 | SOLICITUD_ANIMAL con fecha de interés y operación pública de asociación. |
| S-11, atención externa | RN-05/06 | Lugar externo sin capacidad ficticia; implementación de Jason conservada. |
| S-12, rescatista/receptor ordinario opcional | RN-04/23 | No se aplica a devoluciones: RN-23 exige receptor y prevalece en ese contexto. |
| S-13, oferente responsable | RN-07/08, N-01 | Responsabilidad derivada en estancias de hogar; intacta. |
| S-14, microchip vigente | RN-03 | Opcional único; no se inventa historial de microchips. |
| S-15, seguimiento reprogramado | RN-22 | Pendiente de Jean Carlos; conservar origen y adopción, no sobrescribir ni formar ciclos. |
| S-16, hogar descriptivo por solicitud | RN-16/19, D-P03 | Cuatro textos, conservados como contexto de valoración individual. No se modelan familiares como PERSONA por inferencia. |

## Reutilización efectiva y revalidación

| Componente y origen Lab03 | Conservación / adaptación | Verificación actual |
|---|---|---|
| `sql/01_esquema.sql`, `chk_revision_campos` | Misma condición de completitud; tipos/instante/esquema compartidos, registro e ingreso añadidos. | R03 sin veterinario, motivo, observación, peso o recomendación; R03 frontera profesional. |
| Mismo archivo, PK DIAGNOSTICO_REVISION y `uq_evaluacion_id_tipo` / FK discriminada | Misma identidad y mecanismo; bigint y esquema huellas. Se sustituye CASCADE por conservación de historia. | R05 duplicado, diagnóstico solo en revisión, estados y referencia; H01. |
| Catálogo único y estado de aparición | Mismo significado; texto no vacío estandarizado. | R04/R05. |
| `sql/04_rutinas.sql`, `contar_revisiones_animal` | Misma consulta de conteo; firma text, search_path seguro y STABLE. No se reescribe como proceso médico. | R05-reutilizacion-clinica: 2 revisiones HS-01. |
| `sql/03_consultas.sql`, Q01 y Q03 | Se convierten en vistas con etapa; se mantienen LEFT JOIN para inicial sin diagnóstico y conteo de apariciones confirmadas. | HS-01: tres evaluaciones y dos apariciones confirmadas; R05. |
| `sql/05_pruebas.sql`, P02/P07/P09/P10 | Reutilización de escenarios y método de capturar rechazo esperado, con referencias actuales y aserciones de estado. | R03/R05 ejecutadas de nuevo, no se copian resultados de octubre. |
| Q02/Q04, `estado_aplicacion`, `registrar_aplicacion`, reporte temporal | Fuera del bloque asignado a Paula. Se preservan los archivos históricos y se registra el trabajo necesario. | Pendientes de Jean Carlos; no se atribuye su revalidación a esta intervención. |

No hay componente SQL de Paula copiado byte por byte sin adaptación: todos los clínicos precisan esquema, tipos o contexto nuevos. Las reglas de contenido conservadas se distinguen de los archivos efectivamente adaptados. Las restricciones de microchip/edad ya reutilizadas por Jason se mantienen y su guion original se ejecutó de nuevo en una base con ambos bloques. El Word solicita acuerdo de las nuevas relaciones: la propuesta se implementa en el bloque propio y se deja para revisión de consumo por Jean Carlos, sin atribuirle aprobación ni modificar sus tablas ausentes.

## Identificación de adjuntos por contenido

| Archivo examinado | SHA-256 |
|---|---|
| Distribucion Proyecto Final.docx | `2fceccd02ce35c5ebc9ef90aa5825ebd5e876aea3ca5ca2a5c78e7cbe5ed2efe` |
| Hoja_Calificacion_Proyecto_ROMERO GARRO MARIA PAULA.xlsx | `994b6e71b0afe1bfd9816eee5ed0fd4626e41909b41681c6d2619abbd98c3b27` |
| Huellas_Seguras.pdf | `72acc86232d4f006d6c4b9c8e88a8902e578c09aed3a6ce4cac9f4e2dec5cbf2` |
