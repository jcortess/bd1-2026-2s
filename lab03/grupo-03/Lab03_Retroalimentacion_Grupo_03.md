# IC-4301 · Laboratorio 03 · Grupo 03

## Universidad Horizonte

**Calificación: 100/100.** Trabajo del grupo: **80/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Seis relaciones de cursos, versiones, participaciones y requisitos trazadas al P1. |
| A2 — Esquema físico y restricciones | 13 | 13 | 0 | PK/FK, obligatoriedad y dominios de escuela, curso comprobados. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 6 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Tres versiones y participaciones obligatorias/optativas; 7 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 3 consultas correctas: cursos de versión 102, requisitos y conteos por versión/tipo. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | P01/P02/P03/P07/P08 válidas y P04/P05/P06/P09 rechazadas: nueve avisos EXITOSA. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_creditos_obligatorios_plan: sumas; fn_tipo_requisitos_curso: combinaciones y ausencia de requisitos. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_agregar_curso_plan valida curso, versión, tipo y duplicado; alta y rechazos comprobados. |
| C3 — Técnica adicional | 7 | 7 | 0 | fn_detalle_requisitos_cursor: dieciséis textos completos correctos y alternativa STRING_AGG documentada. |
| D1 — Documentación | 6 | 6 | 0 | README, matriz y límites del recorte presentes; vigencia textual tratada como mejora formativa. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=25/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- Trazabilidad de cursos, versiones y participación; siete FK verificadas sin huérfanos.
- Las tres consultas y veinte llamadas coinciden con cálculo independiente.
- El alta en plan rechaza duplicados, curso/versión inexistentes y tipo inválido.
- El cursor y sus dieciséis textos se validaron; nueve pruebas originales exitosas. La tercera función no genera bonificación.

## Incumplimientos que afectan la nota

No se aplicaron descuentos por incumplimientos técnicos. Las recomendaciones de la sección siguiente son formativas y no reducen la calificación.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Vigencia del plan.** La vigencia sigue en texto libre y no permite comprobar un intervalo. Para una evolución del proyecto conviene precisar su significado y, si corresponde, separar inicio/fin; no se impone ahora un formato que el negocio no definió.

**Requisitos compartidos.** El esquema admite un curso exigido externo a la versión del plan. Explicitar si el negocio permite cursos compartidos hará más clara su interpretación; una restricción futura de pertenencia debería definirse y modelarse expresamente, sin añadirla como obligación a esta entrega.
