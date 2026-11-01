# IC-4301 · Laboratorio 03 · Grupo 04

## Alquileres El Roble

**Calificación: 100/100.** Trabajo del grupo: **80/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Cinco relaciones de cliente/persona, autorizaciones y facultades, con otorgamientos múltiples. |
| A2 — Esquema físico y restricciones | 13 | 13 | 0 | PK/FK, obligatoriedad y dominios de persona, cliente comprobados. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 5 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Autorizaciones vigentes, futuras, vencidas y abiertas; 5 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 5 consultas correctas: vigencia, personas distintas, próximos vencimientos y clasificación temporal. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | T01–T23 producen valores o rechazos previstos; incluyen fronteras temporales y atomicidad. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_persona_tiene_facultad: combinaciones y frontera temporal; fn_contar_autorizaciones_activas: otorgamientos. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_registrar_autorizacion crea cabecera/facultades; rechaza físico, listas y fechas inválidas sin residuos. |
| C3 — Técnica adicional | 7 | 7 | 0 | sp_preparar_resumen: clasificación completa de autorizaciones y alternativa CTE coincidentes. |
| D1 — Documentación | 6 | 6 | 0 | README y documentación ampliada presentes; actualizar estados y nombres de fuentes obsoletos. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=25/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- Se preservan otorgamientos múltiples por persona sin confundirlos con personas distintas.
- Cinco consultas y 64 llamadas verifican conteos y facultades por organización/persona/fecha.
- El procedimiento valida organización, lista de facultades y fechas, y no deja residuos al fallar.
- La temporal y la alternativa CTE coinciden; 23 comprobaciones originales favorables.

## Incumplimientos que afectan la nota

No se aplicaron descuentos por incumplimientos técnicos. Las recomendaciones de la sección siguiente son formativas y no reducen la calificación.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Ruta de alta.** La tabla acepta por INSERT directo un cliente físico y cero facultades; sp_registrar_autorizacion rechaza ambos casos inválidos. Documentar la ruta de operación y permisos ayudará a entender su garantía, sin exigir triggers para otras rutas.

**Documentación vigente.** Algunos documentos conservan estados como sin DDL y nombres distintos de las fuentes usadas. Actualizarlos permitirá relacionar el diseño con la implementación ya funcional y evitar dudas de reproducción.
