# IC-4301 · Laboratorio 03 · Grupo 11

## Cooperativa Valle Verde

**Calificación: 73/100.** Trabajo del grupo: **53/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Nueve relaciones de productor, finca e historial contrastadas con P1; completar la matriz es formativo. |
| A2 — Esquema físico y restricciones | 13 | 11 | 2 | Claves y referencias operativas; el patrón textual admite fecha imposible. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 9 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Productores con varias fincas y responsables/historiales referenciados; 9 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 3 consultas correctas: responsables durante período, fincas por productor y conteo de fincas. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | p01/p03/p06 válidas y p02/p04/p05 rechazadas con continuación y SAVEPOINT; Conjunto de seis pruebas completado en modo de continuación. |
| C1 — Funciones PL/pgSQL | 8 | 0 | 8 | Solo total_fincas_de_responsable, LANGUAGE sql, con tres resultados válidos; faltan las dos funciones PL/pgSQL. |
| C2 — Procedimiento almacenado | 10 | 0 | 10 | No hay CREATE PROCEDURE ni objeto prokind=p en el catálogo. |
| C3 — Técnica adicional | 7 | 0 | 7 | No hay cursor explícito, tabla temporal ni demostración de SQL dinámico. |
| D1 — Documentación | 6 | 6 | 0 | README, matriz y enlaces presentes; mejorar trazabilidad y protocolo sin descuento. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de c01–c03 y p01–p06 identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=23/25; B=20/20; C=0/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- Nueve tablas y nueve FK sin huérfanos; se preserva identidad compuesta de finca y referencias del historial.
- Las tres consultas con datos válidos son correctas. c01 usa TO_DATE y ordena cronológicamente; no se penaliza por orden textual.
- La función LANGUAGE sql total_fincas_de_responsable es útil y sus tres llamadas coinciden con el cálculo de fincas distintas; se reconoce sin sustituir C1.
- Las tres altas y tres negativas originales funcionan con continuación y SAVEPOINT. El DDL carga en base vacía.

## Incumplimientos que afectan la nota

### El formato de texto permite almacenar una fecha inexistente

#### Problema identificado

Las fechas de ingreso y salida de `registro_en_historial` están almacenadas como texto. El patrón de dos dígitos/dos dígitos/cuatro dígitos verifica la forma de la cadena, pero no el calendario; por ello admite 31 de febrero.

#### Requisito esperado

El historial debe conservar fechas reales de cambio de responsable. A2 exige tipos adecuados y restricciones acordes con el dato representado. Una cadena con el formato aparente de fecha no garantiza un día válido.

#### Prueba realizada

Se partió del esquema y la semilla originales y se añadieron para esta prueba productor-9001, responsables ficticios, finca-9001 e historialR-9001 con referencias válidas. No había un episodio previo de responsable-9001 en ese historial. Esos registros son preparación adicional, no datos de la semilla. Luego se intentó registrar el ingreso 31/02/2026. El bloque reproduce las sentencias empleadas y deshace la preparación al finalizar; requiere esos identificadores libres.

```sql
BEGIN;
INSERT INTO productores(productor_id,nombre,fecha_de_afiliacion,condicion) VALUES('productor-9001','Productor ficticio','01/01/2020','activo');
INSERT INTO personas_responsables(responsable_id,nombre) VALUES('responsable-9001','Persona A'),('responsable-9002','Persona B');
INSERT INTO fincas(productor_id,finca_id,responsable_id,provincia,canton,distrito,indicacion_especifica,area_aproximada)
 VALUES('productor-9001','finca-9001','responsable-9001','Alajuela','San Carlos','Quesada','Dirección ficticia','500 m²');
INSERT INTO historiales_responsable(historial_responsables_id,productor_id,finca_id) VALUES('historialR-9001','productor-9001','finca-9001');

INSERT INTO registro_en_historial VALUES('historialR-9001','productor-9001','finca-9001','responsable-9001','31/02/2026',NULL);

SELECT fecha_de_ingreso_como_responsable FROM registro_en_historial WHERE historial_responsables_id='historialR-9001';
ROLLBACK;
```

#### Resultado esperado

Rechazar la fecha 31/02/2026 porque ese día no existe en el calendario.

#### Resultado observado

La inserción se aceptó y el SELECT devolvió `31/02/2026` como fecha de ingreso.

#### Consecuencia

Se puede almacenar un cambio de responsable con fecha imposible. Además, c01 convierte el texto a fecha mediante TO_DATE: un valor imposible persistido puede provocar un error al convertirlo. La aceptación se demostró; no se atribuye a c01 un orden incorrecto con datos válidos, pues sus resultados con la semilla fueron correctos.

#### Recomendación

Usar columnas DATE para ingreso y salida, manteniendo la salida opcional, y aplicar DD/MM/YYYY solo al presentar. Revisar los textos existentes antes de migrarlos. No se exige añadir reglas nuevas de solapamiento o reingreso que el caso no haya definido.

#### Impacto en la nota

**A2 — Esquema físico y restricciones: máximo 13; otorgado 11; descuento 2 puntos.** Se reconocen las claves, nueve referencias y restricciones que sí funcionan. Formato, fecha imposible y riesgo de conversión se consideran una sola causa; B2 conserva 6/6 por las consultas correctas con la semilla.

### No están las dos funciones PL/pgSQL exigidas

#### Problema identificado

`sql/04_rutinas.sql` contiene una única función, `total_fincas_de_responsable`, declarada `LANGUAGE sql`. No contiene las dos funciones PL/pgSQL solicitadas ni una segunda función con decisión de negocio.

#### Requisito esperado

C1 solicita dos funciones en PL/pgSQL: una parametrizada que calcule o consulte un valor útil y otra que incluya una decisión de negocio mediante IF, CASE u otra estructura justificada. Deben documentarse parámetros, retorno, reglas y ejemplos.

#### Prueba realizada

Se inspeccionaron el archivo completo `sql/04_rutinas.sql` y las rutinas registradas en el esquema de PostgreSQL tras cargar la entrega. El código encontrado fue:

```sql
CREATE OR REPLACE FUNCTION total_fincas_de_responsable(p_responsable_id VARCHAR) RETURNS INTEGER LANGUAGE sql AS $$
SELECT COUNT(DISTINCT (productor_id, finca_id))::INTEGER
FROM registro_en_historial
WHERE responsable_id = p_responsable_id;
$$;
```
Esta es una inspección de lo entregado, no una llamada simulada a funciones ausentes. El cálculo de esta función SQL sí se comprobó y produjo los resultados correctos.

#### Resultado esperado

Encontrar al menos dos funciones PL/pgSQL con los dos propósitos exigidos.

#### Resultado observado

Solo se encontró `total_fincas_de_responsable`, de lenguaje SQL; cero funciones PL/pgSQL. El cálculo de fincas distintas es válido, pero no cumple la cantidad y lenguaje de C1.

#### Consecuencia

No se entregó la capacidad procedimental que evalúa C1. Una función SQL útil puede resolver una consulta, pero no demuestra las dos funciones PL/pgSQL ni la decisión de negocio solicitadas.

#### Recomendación

Aprovechar el cálculo existente en una función PL/pgSQL útil e implementar otra con una decisión respaldada por el proceso de fincas/historial. Documentar parámetros, retorno, regla y ejemplos; evitar funciones artificiales creadas solo para aumentar el conteo.

#### Impacto en la nota

**C1 — Funciones PL/pgSQL: máximo 8; otorgado 0; descuento 8 puntos.** No hay ningún objeto del lenguaje exigido ni la segunda función. Se reconoce expresamente la función SQL correcta en las fortalezas y consultas; no se equipara a las dos funciones requeridas ni se repite este descuento en documentación.

### No existe el procedimiento almacenado con validaciones

#### Problema identificado

No se entregó un procedimiento almacenado: `sql/04_rutinas.sql` no contiene CREATE PROCEDURE y el catálogo del esquema no contiene procedimientos.

#### Requisito esperado

C2 exige un procedimiento que inserte o actualice información de una operación real, valide al menos una condición antes de modificar y comunique claramente el rechazo de una operación inválida. Deben probarse el éxito y el rechazo, manteniendo las restricciones del esquema.

#### Prueba realizada

Se inspeccionó el archivo completo de rutinas y el tipo de los objetos registrados tras cargar los scripts. El único objeto encontrado fue la función SQL `total_fincas_de_responsable`. No se ejecutó ni se inventó una llamada a un procedimiento inexistente. Los INSERT de las pruebas de integridad se reconocen como pruebas de tablas, pero no son una rutina almacenada.

#### Resultado esperado

Un procedimiento de negocio que valide y modifique datos, con evidencia de caso válido y rechazado.

#### Resultado observado

No existe CREATE PROCEDURE ni un objeto de tipo procedimiento en el esquema cargado.

#### Consecuencia

La entrega no ofrece la operación almacenada con validaciones y rechazo que evalúa este criterio; las tablas y los INSERT aislados no sustituyen ese componente.

#### Recomendación

Encapsular una operación de finca/historial en CREATE PROCEDURE, con una condición de negocio explícita antes de modificar, mensaje de rechazo claro y pruebas de éxito/rechazo. Conservar las FK y CHECK ya implementadas.

#### Impacto en la nota

**C2 — Procedimiento almacenado: máximo 10; otorgado 0; descuento 10 puntos.** El componente está ausente. No se vuelve a descontar por no documentar o probar ese mismo procedimiento ausente.

### No se incorporó ninguna de las técnicas adicionales admitidas

#### Problema identificado

No hay cursor explícito, tabla temporal ni SQL dinámico como rutina o demostración acotada en los cinco scripts. Los SAVEPOINT usados para recuperar pruebas negativas no son una de las técnicas elegibles de C3.

#### Requisito esperado

C3 requiere una de estas técnicas: cursor explícito, tabla temporal o SQL dinámico apropiado. Debe justificarse su elección y, si la demostración es didáctica y existe una solución más sencilla basada en conjuntos, mostrar y discutir esa alternativa.

#### Prueba realizada

Se inspeccionaron los cinco scripts de la entrega, incluido `sql/04_rutinas.sql`, y las rutinas creadas. La única rutina es la función SQL de conteo de fincas; no hay una demostración de las técnicas solicitadas. Se trata de ausencia de componente, no de una ejecución fallida de una técnica implementada.

#### Resultado esperado

Una rutina o demostración con al menos una técnica elegible y su justificación.

#### Resultado observado

No se encontró ninguna de las técnicas requeridas ni una demostración correspondiente.

#### Consecuencia

No se acredita la capacidad adicional de programación evaluada en C3. Las transacciones de las pruebas y una agregación SQL correcta cumplen otros propósitos y no sustituyen esta demostración.

#### Recomendación

Incorporar una técnica pertinente al proceso, por ejemplo un reporte con temporal o cursor explícito. Explicar su elección y comparar con SQL por conjuntos si su finalidad es didáctica. Evitar SQL dinámico para consultas de estructura fija.

#### Impacto en la nota

**C3 — Técnica adicional: máximo 7; otorgado 0; descuento 7 puntos.** No existe una técnica elegible que pueda recibir crédito parcial. C1, C2 y C3 evalúan tres componentes distintos; cada ausencia se imputa solo en su criterio.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Rotulado de p02.** La prueba dice cantón, pero Rojolandia se inserta en provincia y falla fincas_provincia_check. Corregir el rótulo permitirá relacionar el resultado con la restricción correcta; el rechazo funciona y no descuenta.

**Matriz de trazabilidad.** Faltan filas de PRODUCTOR y PERSONA_RESPONSABLE y algunas referencias compuestas aparecen separadas. Completar esas correspondencias y justificar formatos ayudará a entender el esquema; es una mejora sin descuento.

**Geografía.** El esquema acepta una pareja provincia/cantón incompatible. Un catálogo relacionado puede mejorar calidad de datos; no se identificó una RN que obligue a comprobar esa pareja, por lo que es opcional.

**Episodios del responsable.** La PK impide reingreso de una persona al mismo historial. Si el negocio incorpora ese caso, una identidad de episodio permitirá conservar ambos períodos; no se exige esa ampliación para esta nota.

**Versión del motor.** Las cabeceras mencionan PostgreSQL 18 y el funcionamiento se comprobó en 16.15. Precisar el entorno del estudiante y comandos facilitará reproducirlo; la diferencia de versión no constituye por sí sola un fallo.

**Ejecución de las pruebas.** `05_pruebas.sql` completa p01–p06 cuando el cliente continúa tras los rechazos esperados y permite alcanzar ROLLBACK TO SAVEPOINT. Con parada ante el primer error se interrumpe en p02; además, BEGIN queda sin COMMIT/ROLLBACK final. Documentar el modo de ejecución y cerrar explícitamente la transacción hará más clara la repetición y el estado final. También puede considerarse capturar los rechazos previstos en bloques PL/pgSQL. Estos aspectos no descuentan: **B3=7/7**.

Las correcciones propuestas orientan el aprendizaje y la continuidad del proyecto; no se exige modificar una entrega fuera de plazo para recuperar puntos.
