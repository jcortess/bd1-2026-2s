# IC-4301 · Laboratorio 03 · Grupo 02

## Taller Ruta 27

**Calificación: 100/100.** Trabajo del grupo: **80/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Seis relaciones del taller; VIN, roles de cliente/receptor e historial conservados. |
| A2 — Esquema físico y restricciones | 13 | 13 | 0 | PK/FK, obligatoriedad y dominios de vehiculo, orden_trabajo comprobados. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 6 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Cinco órdenes, visitas repetidas y urgencias distintas; 8 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 4 consultas correctas: órdenes pendientes, visitas por vehículo, hallazgos y estados. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | P01–P03 válidas y P04–P07 rechazadas: siete avisos APROBADA. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_total_ordenes_cliente: conteos por cliente; fn_prioridad_orden: urgencias y ausencia de hallazgos. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_registrar_orden crea orden y estado Recibida; rechaza duplicado, kilometraje y referencias inválidas sin residuos. |
| C3 — Técnica adicional | 7 | 7 | 0 | tmp_resumen_prioridades verificada por orden, placa y prioridad en su sesión; alternativa SELECT discutida. |
| D1 — Documentación | 6 | 6 | 0 | README y modelo presentes; corregir los rótulos Q02/Q04, sin descuento. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=25/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- Esquema y cinco scripts originales ejecutados sin errores no esperados; ocho FK sin huérfanos.
- Las cuatro consultas reales son útiles y correctas, aunque Q02/Q04 estén mal rotuladas en el README.
- Dos funciones PL/pgSQL verificadas, alta de orden con roles separados e historial inicial; diez llamadas y pruebas de atomicidad favorables.
- La demostración de tabla temporal funciona en la misma sesión; siete pruebas originales aprobadas.

## Incumplimientos que afectan la nota

No se aplicaron descuentos por incumplimientos técnicos. Las recomendaciones de la sección siguiente son formativas y no reducen la calificación.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Rótulos de Q02/Q04.** El README describe consultas distintas del SQL: Q02 cuenta visitas por vehículo y Q04 órdenes por estado. Actualizar las preguntas y resultados esperados hará más clara su reproducción; las consultas correctas conservan su puntaje.

**Límite de recepción.** Identificar al cliente no acredita por sí solo autorización ni contacto habilitado. Precisar las comprobaciones externas permitirá interpretar el recorte de recepción/diagnóstico, sin exigir incorporar procesos excluidos.

**Fecha prometida.** Un UPDATE directo reemplaza fecha_prometida_actual sin historial. Documentar que la reprogramación está fuera del flujo evita prometer trazabilidad no implementada; si se amplía ese proceso, conservar fecha anterior, motivo y responsable. Descuento actual: cero.
