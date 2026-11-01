# IC-4301 · Laboratorio 03 · Grupo 08

## Envíos Conecta

**Calificación: 100/100.** Trabajo del grupo: **80/80**. Defensa individual: **20/20** por integrante activo.
**Cristhian no publicó el video de la presentación**

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Nueve relaciones de clientes, contactos, participantes y solicitudes trazadas al P1. |
| A2 — Esquema físico y restricciones | 13 | 13 | 0 | PK/FK, obligatoriedad y dominios de cliente, medio_contacto_cliente comprobados. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 9 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Clientes sin solicitudes y solicitudes de distintos niveles; 8 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 6 consultas correctas: solicitudes, conteos, urgentes, direcciones, contactos y período previsto. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | P01–P03 válidas y P04–P09 rechazadas; funciones y alta/rechazo del procedimiento comprobados. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_solicitudes_cliente: rangos y cliente sin solicitudes; fn_prioridad_solicitud: niveles y contrato. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_registrar_contacto crea contacto, facultad y medio; rechaza físico y revierte ante facultad inválida. |
| C3 — Técnica adicional | 7 | 7 | 0 | fn_reporte_prioridades: reporte completo comparado fila por fila; alternativa por conjuntos discutida. |
| D1 — Documentación | 6 | 6 | 0 | README y matriz identifican políticas propuestas; añadir equivalencias de dominios del P1. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=25/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- Identidad compuesta y CHECK de participante evitan identificaciones parcialmente nulas sin obligar a todo participante a ser cliente.
- Seis consultas y veinte llamadas, incluidos rangos y clientes sin solicitudes, coinciden con el esperado.
- El procedimiento crea contacto, facultad y medio para organización, rechaza físico y revierte una operación inválida.
- Cursor de prioridades validado fila por fila; políticas nuevas se señalan como propuesta.

## Incumplimientos que afectan la nota

No se aplicaron descuentos por incumplimientos técnicos. Las recomendaciones de la sección siguiente son formativas y no reducen la calificación.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Contacto por procedimiento.** SQL directo admite persona física y contacto sin facultades, mientras sp_registrar_contacto valida el tipo y crea los hijos. Documentar ruta y permisos explica esa diferencia; no se exige trigger para otras rutas.

**Equivalencia de dominios.** Contrato y medios no tienen un mapeo completo desde el diccionario P1. Añadir una correspondencia evitará suponer que WHATSAPP representa toda la categoría Otro; esa mejora futura no afecta esta nota.

**Prioridad propuesta.** fn_prioridad_solicitud está marcada PROPUESTA y calcula lo declarado. Conservar esa advertencia y documentar la política acordada evitará confundir resultados funcionales con aprobación de una nueva regla.
