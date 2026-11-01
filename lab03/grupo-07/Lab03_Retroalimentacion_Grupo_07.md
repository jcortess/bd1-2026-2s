# IC-4301 · Laboratorio 03 · Grupo 07

## Eventos Nexo

**Calificación: 98/100.** Trabajo del grupo: **78/80**. Defensa individual: **20/20** por integrante activo.

**Versión evaluada:** `c55142cfdfab8caaaa56871d526d21e30e8d0584`.

## Desglose de la calificación

| Criterio | Máximo | Obtenido | Descuento | Justificación |
|---|---:|---:|---:|---|
| A1 — Trazabilidad | 7 | 7 | 0 | Doce relaciones justificadas por dependencias de evento, cargo y pago. |
| A2 — Esquema físico y restricciones | 13 | 11 | 2 | FK compuestas operativas; falta unicidad efectiva de evento por solicitud. |
| A3 — Reproducibilidad del DDL | 5 | 5 | 0 | 01_esquema.sql creó 12 tablas en public sobre base vacía, sin objetos manuales. |
| B1 — Datos e integridad | 7 | 7 | 0 | Cuatro eventos con saldos/estados distintos, cargos y aplicaciones; 17 FK sin huérfanos. |
| B2 — Consultas | 6 | 6 | 0 | 4 consultas correctas: saldos de eventos, deuda por cliente, recaudación y reparto. |
| B3 — Pruebas de integridad | 7 | 7 | 0 | T01–T04 válidas y T05–T11 rechazadas: once conclusiones PASA. |
| C1 — Funciones PL/pgSQL | 8 | 8 | 0 | fn_saldo_evento y fn_estado_pago_evento: saldos y estados de los cuatro eventos. |
| C2 — Procedimiento almacenado | 10 | 10 | 0 | sp_registrar_pago/sp_aplicar_pago reparten 400000 en 260000+140000; rechazan sobrepago y reaplicar no duplica. |
| C3 — Técnica adicional | 7 | 7 | 0 | Cursor explícito de reparto contrastado con simulación Q04 y alternativa por conjuntos. |
| D1 — Documentación | 6 | 6 | 0 | README y matriz declaran exclusiones; aclarar tipos de cargo que ck_cargo_origen hace irrealizables. |
| D2 — Evidencias | 4 | 4 | 0 | Resultados de consultas, pruebas y rutinas identificados y contrastables con sus registros de ejecución. |
| D3 — Defensa individual | 20 | 20 | 0 | Defensa individual: 20/20 por integrante activo. |

**Subtotales:** A=23/25; B=20/20; C=25/25; D=30/30. D incluye 10 puntos de documentación/evidencias del grupo y 20 de defensa individual.

## Fortalezas

- FK compuestas conservan coherencia de evento en servicios, cargos y aplicaciones de pago.
- Cuatro consultas y ocho llamadas calculan correctamente saldos y estados en la semilla.
- El pago de 400000 se distribuye 260000 y 140000, con saldo final 210000; se rechaza sobrepago y reaplicar es idempotente.
- Once pruebas originales superadas y alternativa por conjuntos contrastada; el mayor número de tablas no otorga puntos extra.

## Incumplimientos que afectan la nota

### Las claves únicas de propuesta y alternativa no impiden dos eventos de una solicitud

#### Problema identificado

En `evento`, las restricciones `UNIQUE(id_propuesta)` y `UNIQUE(id_alternativa)` no impiden que dos propuestas distintas y dos alternativas distintas de una misma solicitud generen dos eventos. Cada clave individual puede seguir siendo única mientras se duplica el evento de la solicitud.

#### Requisito esperado

La RN-08 del Proyecto 1 establece que la confirmación crea un único evento por solicitud. El esquema debe asegurar la unicidad efectiva de esa solicitud, conservando su correspondencia con propuesta y alternativa.

#### Prueba realizada

Sobre el esquema y la semilla cargados se añadieron datos ficticios con identificadores 9001/9002, libres al iniciar. Se crearon persona, cliente, espacio, solicitudes y las dependencias necesarias. Ambas propuestas y ambas alternativas usadas por los dos eventos pertenecen a la solicitud 9001. El evento 9001 es el control válido; la sentencia siguiente intenta crear un segundo evento para esa misma solicitud. Todos estos datos fueron añadidos para la prueba, no son registros de la semilla. El bloque conserva la preparación y las sentencias utilizadas y termina deshaciendo los cambios.

```sql
BEGIN;
INSERT INTO persona(id_persona,identificacion,nombre_completo) VALUES(9001,'AUD-9001','Persona auditoría');
INSERT INTO cliente(id_cliente,tipo_cliente,id_persona) VALUES(9001,'Persona',9001);
INSERT INTO espacio(id_espacio,nombre,tipo_propiedad,ubicacion,capacidad,divisible) VALUES(9001,'Auditoría','Propio','Prueba',100,false);
INSERT INTO solicitud(id_solicitud,id_cliente,fecha_solicitud,tipo_evento,fecha_desde,fecha_hasta,horario_aproximado,asistentes_esperados,estado_solicitud)
 VALUES(9001,9001,'2026-10-01','Prueba','2026-12-01','2026-12-02','10:00',10,'Aprobada'),
 (9002,9001,'2026-10-01','Prueba','2026-12-01','2026-12-02','10:00',10,'Aprobada');
INSERT INTO propuesta(id_propuesta,id_solicitud,numero_version,fecha_version,vigencia_hasta,condiciones,estado_propuesta)
 VALUES(9001,9001,1,'2026-10-01','2026-11-30','Prueba','Vigente'),(9002,9001,2,'2026-10-02','2026-11-30','Prueba','Vigente');
INSERT INTO alternativa_solicitud(id_alternativa,id_solicitud,fecha_desde,fecha_hasta,id_espacio,estado_alternativa)
 VALUES(9001,9001,'2026-12-01','2026-12-01',9001,'En evaluación'),(9002,9001,'2026-12-02','2026-12-02',9001,'En evaluación');
INSERT INTO evento(id_evento,id_propuesta,id_alternativa,id_persona_autorizada,fecha_aceptacion,monto_adelanto_requerido,tipo_evento,fecha_inicio,fecha_fin,estado_evento) VALUES(9001,9001,9001,9001,'2026-10-03',0,'Prueba','2026-12-01','2026-12-01','Confirmado');

INSERT INTO evento(id_evento,id_propuesta,id_alternativa,id_persona_autorizada,fecha_aceptacion,monto_adelanto_requerido,tipo_evento,fecha_inicio,fecha_fin,estado_evento) VALUES(9002,9002,9002,9001,'2026-10-03',0,'Prueba','2026-12-01','2026-12-01','Confirmado');

SELECT p.id_solicitud,count(*) AS eventos FROM evento e JOIN propuesta p USING(id_propuesta) WHERE p.id_solicitud=9001 GROUP BY p.id_solicitud;
ROLLBACK;
```

#### Resultado esperado

Rechazar el segundo evento porque la solicitud 9001 ya tiene el evento 9001.

#### Resultado observado

Se aceptó el segundo evento. La consulta de comprobación devolvió `id_solicitud=9001` con `eventos=2`.

#### Consecuencia

La base permite confirmar más de un evento para una solicitud. Esto podría fragmentar posteriormente seguimiento, cargos y pagos entre eventos; la duplicación fue demostrada, pero no se afirma que se haya ejecutado un perjuicio financiero posterior.

#### Recomendación

Representar y comprobar la solicitud del evento y establecer una unicidad efectiva sobre ella. Asegurar también que propuesta y alternativa correspondan a esa misma solicitud. Las referencias compuestas pueden ayudar a conservar el contexto; dos UNIQUE independientes no sustituyen la unicidad por solicitud.

#### Impacto en la nota

**A2 — Esquema físico y restricciones: máximo 13; otorgado 11; descuento 2 puntos.** Se reconocen las referencias compuestas y restricciones correctas de eventos, cargos y pagos. El defecto se imputa una sola vez; el cruce propuesta–alternativa no añade otro descuento y el procedimiento de cobro conserva su puntaje.

## Observaciones formativas — sin descuento

Todas las observaciones de esta sección tienen **descuento cero**. Las mejoras opcionales y posibles ampliaciones no son requisitos nuevos de esta entrega.

**Tipos de cargo.** ck_cargo_tipo anuncia Ajuste/Adicional, pero ck_cargo_origen no tiene ramas que los admitan. Como esos procesos están excluidos, reducir el dominio del recorte o explicar su extensión futura evitará valores aparentemente utilizables.

**Edición de aplicaciones.** La tabla permite exceder montos mediante UPDATE directo. El flujo por procedimiento sí funciona; explicar ruta y permisos previstos ayuda a conservar sus controles. El refuerzo adicional de tablas es opcional aquí.

**Coherencia de solicitud.** El esquema permite combinar propuesta y alternativa de solicitudes distintas. Al corregir el vínculo con la solicitud, incluir ambas referencias en el mismo contexto; es un síntoma de esa causa y no añade descuento.

Las correcciones propuestas orientan el aprendizaje y la continuidad del proyecto; no se exige modificar una entrega fuera de plazo para recuperar puntos.
