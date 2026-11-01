# IC-4301 · Laboratorio 03 · Grupo 05

## Refugio Huellas Seguras

**Calificación: 98/100.** Trabajo del grupo: **78/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Ocho relaciones de salud; adaptación discriminada de revisión documentada. |
| A2 — Esquema físico y restricciones | 13 | 11 | 2 | Origen en revisión protegido; falta correspondencia diagnóstico–evaluación de indicación. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 8 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Cinco animales, revisiones y aplicaciones planificadas/realizadas; 10 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 4 consultas correctas: historia de salud, pendientes, revisiones y diagnósticos de indicaciones. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | P01–P03 válidas y P04–P12 rechazadas: doce conclusiones Cumple. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | contar_revisiones_animal: conteos; estado_aplicacion: REALIZADA/VENCIDA/PROGRAMADA. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | registrar_aplicacion valida completitud y estado previo; realiza la aplicación y revierte si el responsable no existe. |
| C3 — Técnica adicional | 7 | 7 | 0 | generar_reporte_pendientes: temporal completa por animal, indicación, fecha y estado; alternativa discutida. |
| D1 — Documentación | 6 | 6 | 0 | README y matriz documentan revisión/indicación/aplicación y límites de roles/ingreso. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=23/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- La FK discriminada conserva el origen de diagnóstico/indicación en revisión veterinaria.
- Cuatro consultas y once llamadas a funciones producen los resultados esperados.
- Registrar una aplicación exige fecha, responsable y observaciones; rechazos y atomicidad comprobados.
- Doce pruebas originales y el reporte temporal completo se verificaron; la falta contextual se imputa solo en A2.

## Incumplimientos que afectan la nota

### Una indicación acepta un diagnóstico ajeno a su evaluación de origen

#### Problema identificado

`indicacion_diagnostico` referencia una indicación y el catálogo de diagnósticos, pero no comprueba que el diagnóstico pertenezca a la evaluación de la que nació esa indicación. La relación `diagnostico_revision` contiene la información necesaria para verificarlo.

#### Requisito esperado

El Proyecto 1 exige comprobar que el diagnóstico asociado a una indicación corresponda a su evaluación de origen usando `DIAGNOSTICO_REVISION`. Esta correspondencia es interna al proceso de salud seleccionado y forma parte de las restricciones de A2.

#### Prueba realizada

Con el esquema y la semilla originales cargados, se añadieron exclusivamente para la prueba una persona veterinaria 9001, el animal AUD-HS-1, dos revisiones de ese animal (9001 y 9002), el diagnóstico 9001 y la indicación 9001. El diagnóstico se registró solo en la revisión 9002; la indicación nace de la revisión 9001. Esos identificadores de prueba no se tomaron de la semilla. El bloque siguiente conserva las sentencias de preparación, inserción y comprobación utilizadas; debe partir de una copia limpia, con esos identificadores libres.

```sql
BEGIN;
INSERT INTO persona(id_persona,nombre_identificacion) VALUES(9001,'Veterinario ficticio auditoría');
INSERT INTO animal(codigo_interno,especie) VALUES('AUD-HS-1','Perro');
INSERT INTO evaluacion_salud(id_evaluacion,animal_codigo,tipo_evaluacion,fecha_evaluacion,veterinario_id,motivo,observaciones,peso,recomendaciones)
 VALUES(9001,'AUD-HS-1','REVISION_VETERINARIA','2026-10-01',9001,'Motivo A','Observación A',10,'Control A'),
 (9002,'AUD-HS-1','REVISION_VETERINARIA','2026-10-02',9001,'Motivo B','Observación B',10,'Control B');
INSERT INTO diagnostico(id_diagnostico,nombre_estandarizado) VALUES(9001,'Diagnóstico auditoría ajeno');
INSERT INTO diagnostico_revision(evaluacion_id,diagnostico_id,estado_diagnostico) VALUES(9002,9001,'CONFIRMADO');
INSERT INTO indicacion(id_indicacion,evaluacion_id,tipo_indicacion,descripcion) VALUES(9001,9001,'TRATAMIENTO','Indicación de revisión A');
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM diagnostico_revision WHERE evaluacion_id=9001 AND diagnostico_id=9001)
 OR NOT EXISTS(SELECT 1 FROM diagnostico_revision WHERE evaluacion_id=9002 AND diagnostico_id=9001)
 THEN RAISE EXCEPTION 'Preparación inválida'; END IF; END $$;

INSERT INTO indicacion_diagnostico(indicacion_id,diagnostico_id) VALUES(9001,9001);

SELECT i.id_indicacion,i.evaluacion_id,d.diagnostico_id,EXISTS(SELECT 1 FROM diagnostico_revision dr WHERE dr.evaluacion_id=i.evaluacion_id AND dr.diagnostico_id=d.diagnostico_id) AS diagnostico_en_origen
 FROM indicacion i JOIN indicacion_diagnostico d ON d.indicacion_id=i.id_indicacion WHERE i.id_indicacion=9001;
ROLLBACK;
```

#### Resultado esperado

Rechazar la asociación `(indicacion_id=9001,diagnostico_id=9001)`, pues no existe el diagnóstico 9001 en la revisión 9001 de origen.

#### Resultado observado

La inserción se aceptó. La comprobación devolvió `diagnostico_en_origen=false`: el vínculo existía, aunque ese diagnóstico no correspondía a la evaluación de la indicación.

#### Consecuencia

Un tratamiento o recomendación puede quedar asociado con un diagnóstico ajeno a su revisión de origen. Las dos referencias a registros existentes no garantizan que correspondan a la misma evaluación.

#### Recomendación

Representar la evaluación en la asociación y asegurar, mediante referencias compuestas coherentes, que coincida con la evaluación de la indicación y con la pareja evaluación–diagnóstico registrada. Conservar el discriminador que ya restringe el origen a revisión veterinaria.

#### Impacto en la nota

**A2 — Esquema físico y restricciones: máximo 13; otorgado 11; descuento 2 puntos.** Se reconocen las ocho tablas y sus restricciones correctas, incluido el origen discriminado en revisión. Solo se reduce por la correspondencia omitida; el procedimiento de registrar aplicaciones conserva su puntaje.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Roles e ingreso.** PERSONA mínima no acredita profesión vigente ni evaluación inicial inmediata. Explicar que dependen de procesos excluidos permite interpretar las FK existentes sin ampliar obligatoriamente el recorte.

**Alcance de la historia.** Historia clínica completa puede sugerir procesos no implementados. Enumerar consultas, revisiones e indicaciones cubiertas y sus exclusiones hará más precisa la documentación; conservar la adaptación discriminada correcta de revisión veterinaria.

Las correcciones propuestas orientan el aprendizaje y la continuidad del proyecto; no se exige modificar una entrega fuera de plazo para recuperar puntos.
