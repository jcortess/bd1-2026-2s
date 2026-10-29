# Rutinas, consultas y pruebas

## Ejecución

Usar una base nueva y el orden 01 → 02 → 04 → 03 → 05. No actualizar una base con las firmas antiguas: estas correcciones no son una migración. El esquema no cambia y los identificadores siguen siendo explícitos.

## Datos y consultas

Los datos son ficticios: cinco personas, cuatro clientes (uno físico y tres organizaciones), cuatro facultades, seis autorizaciones y ocho vínculos. Cubren vigencia abierta, futura, vencida, varias facultades, una persona en dos organizaciones, otorgamientos superpuestos y una organización sin autorizaciones. El cliente físico no concede autorizaciones.

Fecha de referencia: 2026-10-29 10:00:00-06. Resultados esperados, no observados en PostgreSQL:

| Consulta | Pregunta y resultado |
|---|---|
| Q-01 | Otorgamientos vigentes con cliente y persona: IDs 1, 2, 5 y 6 |
| Q-02 | Personas distintas vigentes por organización, incluyendo cero: cliente 2 → 2; 3 → 1; 4 → 0 |
| Q-03 | Otorgamientos vigentes que vencen en [noviembre, enero): IDs 1, 5 y 6 |
| Q-04 | Clasificación temporal: futura 1, vencida 1, vigente 4 |

## Funciones PL/pgSQL

- `fn_persona_tiene_facultad(cliente, persona, facultad, fecha) → boolean`: decisión para una organización concreta. Rechaza entradas nulas, referencias inexistentes y cliente físico; devuelve false si las entidades existen pero no hay concesión vigente suficiente. Inicio incluido, fin excluido y NULL como fin abierto. No comprueba garantías, certificaciones ni disponibilidad.
- `fn_contar_autorizaciones_activas(cliente, fecha) → bigint`: calcula otorgamientos vigentes, no personas distintas. En cliente existente sin otorgamientos devuelve cero. Rechaza cliente inexistente o entradas nulas. La consulta Q-02 realiza el conteo distinto de personas.

```sql
SELECT public.fn_persona_tiene_facultad(2,2,1,TIMESTAMPTZ '2026-10-29 10:00:00-06'); -- true
SELECT public.fn_contar_autorizaciones_activas(2,TIMESTAMPTZ '2026-10-29 10:00:00-06'); -- 3
```

## Procedimiento principal

`sp_registrar_autorizacion(id_autorizacion, cliente, persona, inicio, fin, facultades bigint[])` recibe la clave explícita. Valida existencia, organización, período y lista no nula, no vacía, unidimensional, sin nulos, duplicados o referencias inexistentes. Luego inserta cabecera y vínculos, sin COMMIT interno ni excepciones silenciadas. La PK controla IDs repetidos. Las restricciones declarativas permanecen en 01_esquema.sql.

```sql
BEGIN;
CALL public.sp_registrar_autorizacion(9001,2,4,TIMESTAMPTZ '2026-10-01 00:00:00-06',NULL,ARRAY[1,3]::bigint[]);
SELECT * FROM public.autorizacion_facultad WHERE id_autorizacion=9001;
ROLLBACK;
```

La atomicidad se verifica mediante el caso exitoso, rechazos y conteos posteriores. DL-05 se conserva: no se afirma protección global contra escrituras directas fuera del procedimiento.

## Técnica adicional C3

`sp_preparar_resumen(fecha)` materializa una clasificación por otorgamiento en `pg_temp.resumen_autorizaciones`. Requiere llamarse dentro de una transacción para consultar la tabla antes del COMMIT; ON COMMIT DROP la elimina al terminar. Una segunda llamada reemplaza exclusivamente la temporal de esa sesión. Q-04 muestra el uso y la alternativa CTE con el mismo resultado. Para un reporte aislado la CTE es más sencilla; la temporal es una demostración didáctica y permite reutilizar el conjunto en varios reportes de una transacción. Se retira el trigger redundante de fechas: ese control permanece como CHECK.

## Pruebas y evidencias

05_pruebas.sql contiene 23 pruebas identificadas. Incluye funciones y fronteras temporales (T-01 a T-06), alta válida (T-07), rechazos declarativos y procedimentales (T-08 a T-20), ausencia de filas parciales (T-21), repetición de la temporal (T-22) y equivalencia con CTE (T-23).

El ayudante de rechazo captura SQLSTATE y, cuando corresponde, el nombre de restricción. Un error diferente o una aceptación indebida provoca fallo; no se anuncia éxito ante cualquier excepción. Cada operación negativa se revierte en una subtransacción. Los ayudantes pg_temp son infraestructura de pruebas, no funciones de negocio presentadas para cumplir C1.

El resultado final incluye precondición, sentencia, esperado, observado y conclusión. Todo 05 termina en ROLLBACK, incluyendo el alta 9001: los datos iniciales quedan intactos. Ejecutar localmente con ON_ERROR_STOP=1. Si falla una aserción, no existe una ejecución completa aprobada; corregir y repetir. La CI trata 05 como diagnóstico no bloqueante, por lo que deben revisarse sus resultados.

Estado: revisión estática y cálculo independiente de los resultados esperados con Python; no ejecución PostgreSQL. Registrar las salidas reales de Q-01 a Q-04 y T-01 a T-23 antes de entregar. Las capturas [Consultas03](Consultas03.png) y [Pruebas05](Pruebas05.png) se conservan como antecedentes y no acreditan los scripts corregidos; deben renovarse o complementarse con evidencia actual identificada.

## Trazabilidad y uso de IA

RN-01/RN-02 y AS-02/AS-03 se conservan: solo organización, facultades administrables y vigencia. Se mantienen DL-01 a DL-06 y DF-01 a DF-04. Se concreta C1 mediante verificación booleana y conteo, en lugar del listado de facultades inicialmente propuesto; ambas consultas tienen propósito de negocio documentado. Los IDs T definitivos sustituyen la planificación anterior.

Prompt: «@GitHub Corrige los problemas señalados». Perplexity preparó la compatibilidad con IDs explícitos, filtros por organización/fecha, lista validada, agregación, tabla temporal y pruebas con aserciones. Se descartan el trigger como sustituto de C3, resultados dependientes del reloj y éxito ante cualquier excepción. Contraste: esquema publicado y alcance. Revisión independiente del equipo y ejecución técnica: pendientes de registrar con responsable, fecha y evidencia; no se atribuyen pruebas ejecutadas que no existen.
