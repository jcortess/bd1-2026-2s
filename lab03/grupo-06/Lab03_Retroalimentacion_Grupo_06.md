# IC-4301 · Laboratorio 03 · Grupo 06

## Hotel Mirador del Valle

**Calificación: 100/100.** Trabajo del grupo: **80/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Ocho relaciones de reserva por categoría; responsables alternativos y precio pactado conservados. |
| A2 — Esquema físico y restricciones | 13 | 13 | 0 | PK/FK, obligatoriedad y dominios de categoria_habitacion, plan_tarifario comprobados. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 8 tablas en hotel sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Ocho reservas, mezcla de categorías y adelantos pagados/pendientes; 7 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 5 consultas correctas: confirmadas, ingresos por categoría, adelantos, modificaciones y penalizaciones. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | P01–P03 exitosas y P04–P09 rechazadas: nueve conclusiones PASA. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_total_reservacion: noches e importes pactados; fn_decision_adelanto: devolución/penalización/sin adelanto. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_cancelar_reservacion cambia estado y registra decisión/historia; rechazos conservan los datos originales. |
| C3 — Técnica adicional | 7 | 7 | 0 | sp_marcar_reservaciones_vencidas y alternativa por conjuntos producen los mismos ocho estados finales. |
| D1 — Documentación | 6 | 6 | 0 | README y matriz explican precio pactado y cancelación; unificar versión 14/16. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=25/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- Esquema hotel y responsables alternativos conservan las relaciones del proceso de reservación.
- Cinco consultas y 24 llamadas validan totales pactados y decisiones sobre adelantos.
- Cancelar reserva produce estado e historial correctos y rechaza casos inválidos.
- Cursor y alternativa por conjuntos producen los mismos ocho estados; nueve pruebas originales favorables.

## Incumplimientos que afectan la nota

No se aplicaron descuentos por incumplimientos técnicos. Las recomendaciones de la sección siguiente son formativas y no reducen la calificación.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Versión del motor.** README indica PostgreSQL 14 y las rutinas 16; el funcionamiento se comprobó en 16.15. Unificar la versión realmente utilizada y comandos facilitará reproducir el entorno; no se presume un fallo en otra versión.

**Detalle de reserva.** El esquema admite reserva directa sin detalle. Explicar dónde comprueba la aplicación ese mínimo evita presentar una garantía global; una operación de alta completa puede estudiarse después, sin exigir trigger ni cambiar C3.

**Tarifa y cancelación.** El precio pactado se conserva, pero su derivación por tarifa y el contacto de persona dependen de procesos excluidos. Distinguirlos y rotular el umbral de dos días como supuesto aclara qué valida la solución y qué podría ampliarse.
