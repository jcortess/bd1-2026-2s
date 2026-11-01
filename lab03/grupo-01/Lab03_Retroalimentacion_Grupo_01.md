# IC-4301 · Laboratorio 03 · Grupo 01

## Clínica Los Robles

**Calificación: 98/100.** Trabajo del grupo: **78/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Seis relaciones clínicas; fechas, versionado y sustitución trazados al P1. |
| A2 — Esquema físico y restricciones | 13 | 11 | 2 | Falta correspondencia diagnóstico–consulta del tratamiento; las restantes claves y dominios operan. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 6 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Consultas, notas versionadas y tratamientos de distintos estados; 7 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 4 consultas correctas: diagnósticos, conteos, sustituciones y notas vigentes. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | P01–P03 válidas y P04–P08 rechazadas: ocho conclusiones CUMPLE. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_calcular_dias_tratamiento: duración/fin nulo; fn_determinar_prioridad_consulta: ramas ALTA/MEDIA/BAJA. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_sustituir_tratamiento conserva consulta/diagnósticos, rechaza estados inválidos y revierte el cambio si falla el alta. |
| C3 — Técnica adicional | 7 | 7 | 0 | fn_auditar_evolucion_consulta_cursor: tres textos completos con notas, versiones y orden correctos. |
| D1 — Documentación | 6 | 6 | 0 | README y matriz explican fechas/sustitución; precisiones de referencias externas y cursor son formativas. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=23/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- El proceso clínico conserva consultas, notas versionadas y asociaciones N:M.
- Las cuatro consultas y siete llamadas de cálculo producen los resultados esperados.
- La sustitución conserva consulta y diagnósticos, rechaza estados inválidos y revierte cambios si el alta nueva falla; es una corrección razonada del P1.
- El cursor produjo el texto completo esperado; ocho pruebas originales terminaron con CUMPLE.

## Incumplimientos que afectan la nota

### El diagnóstico asociado al tratamiento no tiene que estar registrado en su consulta

#### Problema identificado

La tabla `tratamiento_diagnostico_nm` comprueba por separado que existan el tratamiento y el código de diagnóstico, pero no exige que ese diagnóstico se haya registrado en la consulta del tratamiento. Por ello admite una asociación válida por sus claves individuales y, a la vez, incorrecta por su contexto clínico.

#### Requisito esperado

El caso clínico establece que los tratamientos atienden diagnósticos registrados durante la consulta. Las restricciones del esquema deben conservar esa correspondencia entre `tratamiento`, `consulta_diagnostico_nm` y `tratamiento_diagnostico_nm`; no basta que el código exista en el catálogo `diagnostico`.

#### Prueba realizada

Se utilizó la semilla original después de cargar `sql/01_esquema.sql`, `sql/02_datos.sql` y `sql/04_rutinas.sql`. El tratamiento 7004 pertenece a la consulta 5003. En esa consulta solo está registrado J00; R50.9 existe en el catálogo y está registrado en la consulta 5001. No se crearon pacientes, consultas ni diagnósticos nuevos para esta prueba: la única fila añadida fue el vínculo que se intentaba validar.

```sql
BEGIN;
INSERT INTO tratamiento_diagnostico_nm VALUES (7004,'R50.9');
ROLLBACK;
```
El fragmento corresponde a la sentencia probada sobre esa semilla. ROLLBACK deshace el vínculo al terminar.

#### Resultado esperado

Rechazar el vínculo, porque R50.9 no está registrado en la consulta 5003 a la que pertenece el tratamiento 7004.

#### Resultado observado

La inserción se aceptó sin error. El tratamiento quedó asociado a un diagnóstico de otra consulta dentro de la transacción de prueba.

#### Consecuencia

Una prescripción puede justificarse con un diagnóstico que no forma parte de la atención en que se indicó. La asociación inconsistente sí se pudo registrar; no se afirma que se haya producido un daño clínico real.

#### Recomendación

Conservar el identificador de consulta en la asociación y usar referencias compuestas que comprueben tanto tratamiento–consulta como consulta–diagnóstico. Otra alternativa es una operación de asociación que valide explícitamente ese contexto. No se requiere un trigger como única solución.

#### Impacto en la nota

**A2 — Esquema físico y restricciones: máximo 13; otorgado 11; descuento 2 puntos.** Se reconoce el esquema operativo y las claves, dominios y rechazos correctos. La reducción corresponde únicamente a esta omisión contextual, no al esquema completo; no se repite en datos, pruebas ni procedimiento.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Referencias externas.** Paciente, médico y cita quedan como identificadores sin FK física. Precisar esa diferencia en la matriz evita atribuir al esquema garantías de otro sistema; pueden rotularse como referencias externas del recorte.

**Versiones históricas.** Una modificación SQL directa permitió editar una versión histórica por SQL directo. Explicar cómo se crean nuevas versiones y quién puede editarlas facilitará conservar la trazabilidad; un refuerzo de la tabla puede estudiarse después, sin exigir trigger.

**Comparación del cursor.** El cursor es correcto, pero STRING_AGG se muestra abreviado. Completar filtros, formato y orden facilitará comparar soluciones; retirar o sustentar la afirmación sobre ahorro de memoria.

**Prioridad clínica.** ALTA/MEDIA/BAJA calcula lo declarado, pero no deriva de una RN clínica acreditada. Identificarla como supuesto didáctico evita presentar una demostración de programación como política clínica oficial.

Las correcciones propuestas orientan el aprendizaje y la continuidad del proyecto; no se exige modificar una entrega fuera de plazo para recuperar puntos.
