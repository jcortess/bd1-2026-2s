# G05-P01 · Controlar ubicación y capacidad

La primera asignación parte de un ingreso abierto. Un traslado parte de la estancia vigente que el operador acaba de consultar. El movimiento deja una sola ubicación vigente y conserva cada estancia anterior. La consulta de historial mantiene el ingreso, las horas, el oferente y su aprobación en hogares, los actores de entrada y salida y las condiciones registradas. [Anexo del Grupo 05](05_Grupo_05_Refugio.md)

## Operación

```text
huellas.mover_animal(
  p_ingreso_id bigint, p_estancia_esperada bigint, p_destino_id bigint,
  p_fecha_real timestamptz, p_actor_id bigint,
  p_condicion_alojamiento text = NULL,
  p_inicio_previsto timestamptz = NULL, p_fin_previsto timestamptz = NULL,
  p_condicion_especial text = NULL, p_valoracion_sanitaria text = NULL
) → bigint
```

Pase `NULL` en `p_estancia_esperada` para asignar por primera vez. Para trasladar, pase el ID observado en `huellas.ubicacion_actual`. Indique el contexto del ingreso, la ubicación de destino, el instante real y la persona que registra el movimiento. La función devuelve el ID de la nueva estancia. El cliente confirma o revierte su transacción. Si una regla de destino falla después del cierre de la estancia de origen, PostgreSQL revierte ese cierre junto con la llamada. Un alta posterior a la pérdida de conexión se verifica consultando el estado persistido antes de volver a enviarla.

| Destino | Validaciones de la operación |
|---|---|
| Área interna | La condición de alojamiento declarada coincide con la admitida en la ubicación. Queda cupo de acuerdo con la ocupación real. |
| Hogar temporal | La persona oferente estaba aprobada antes de la llegada y su participación estaba vigente. El hogar acepta la especie y tiene cupo. La llegada está dentro de la oferta y el plan completo está contenido en ella. Se conservan el plan, la aprobación utilizada y las condiciones acordadas si existen. |
| Atención externa | Se registra lugar y estancia, con capacidad y saldo nulos en la consulta. Aplican las reglas de fecha, etapa y exclusividad que comparten los tres tipos. |

En cada traslado el actor deja la valoración sanitaria utilizada o una afirmación explícita de que la salud no incidió en esa decisión. Puede identificar en el texto la valoración clínica que consultó. El dato es una constancia de esa decisión y se conserva en la estancia de destino. RN-14 no transforma diagnósticos en permisos. Las revisiones y su registro profesional corresponden al bloque clínico.

### Uso con la semilla, en una base separada de las pruebas

```sql
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT huellas.mover_animal(1, NULL, 1, '2026-10-04 08:00-06', 1, 'CONVIVENCIA');
COMMIT;

SELECT id_estancia, ingreso_id, ubicacion_id, actor_entrada_id
FROM huellas.ubicacion_actual WHERE animal_codigo = 'HS-01';
```

Para un traslado a la primera oferta de Casa A se utiliza ese ID en esta llamada de `psql`.

```sql
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT id_estancia AS origen FROM huellas.ubicacion_actual WHERE animal_codigo = 'HS-01' \gset
SELECT huellas.mover_animal(1, :origen, 2, '2026-10-05 00:00-06', 7,
    p_inicio_previsto => '2026-10-05 00:00-06',
    p_fin_previsto => '2026-10-10 00:00-06',
    p_condicion_especial => 'Reposo según el acuerdo',
    p_valoracion_sanitaria => 'Se valoró recuperación y se acordó reposo');
COMMIT;

SELECT * FROM huellas.historial_alojamiento WHERE animal_codigo = 'HS-01' ORDER BY fecha_inicio_real;
SELECT * FROM huellas.ocupacion_actual WHERE id_ubicacion IN (1, 2);
```

## Fechas y ocupación

Los periodos se interpretan como `[inicio, fin)` con precisión de microsegundos. El inicio efectivo no puede preceder al ingreso ni situarse en el futuro. En un traslado, la fecha de la operación cierra el origen y abre el destino, y es estrictamente posterior al inicio del origen. Una llegada al inicio de la oferta de un hogar es válida. Al final exacto de la oferta se permite salir o iniciar otra oferta, y ya no se admite una nueva llegada a la oferta que terminó. El fin previsto puede ser el fin de la oferta. [Tipos de rango de PostgreSQL](https://www.postgresql.org/docs/16/rangetypes.html)

La ocupación se cuenta por intervalos reales. Si se registra una admisión pasada, se comprueba el cupo en su hora y en las llegadas posteriores ya inscritas cuyo cupo podría verse afectado. La fecha prevista expresa lo acordado y la fecha real sigue registrando lo que ocurrió. Si hubo una salida tardía, queda marcada en el historial por `rebasa_oferta`. Esa condición no libera cupo automáticamente. La ocupación del mismo hogar físico se comparte entre ofertas y el saldo físico puede consultarse junto con la vigencia de la oferta. Una oferta vigente todavía requiere especie compatible y espacio para esa llegada particular.

## Escritura, concurrencia y rechazos

- A usuarios operativos se les concede el rol `huellas_g05_operador`. Puede consultar las tablas y vistas y ejecutar únicamente `mover_animal` en este bloque. El instalador administra el catálogo y los ingresos preparados, actúa como propietario de la función y debe mantenerse separado del rol operativo. Las pruebas SQL que intentan DML directo sobre ESTANCIA como propietario lo hacen en una transacción reversible para verificar sus restricciones físicas. Para operación normal, la escritura sobre ESTANCIA pasa por la función pública o por la primitiva privada dentro de la futura formalización.
- La función controla su `search_path` y ejecuta con privilegios del propietario. Las funciones internas carecen de `EXECUTE` público. Las FK impiden borrar registros referenciados y los triggers de catálogo protegen los datos utilizados en el historial. Los cambios de especie usada, de oferta usada y de aprobación que invaliden una entrada histórica son rechazados.
- Se serializan los movimientos y el DML de los catálogos relevantes en toda la base mediante un bloqueo asesor transaccional. Esta elección prioriza una sola regla de adquisición y las transacciones cortas en la escala académica del bloque. Su coste es que también se esperan movimientos de animales y lugares independientes. Bajo `READ COMMITTED`, las consultas internas que siguen al bloqueo ven lo confirmado por la primera transacción. La segunda operación revalida tanto el cupo como la estancia esperada. [Aislamiento](https://www.postgresql.org/docs/16/transaction-iso.html) · [Bloqueos asesores](https://www.postgresql.org/docs/16/explicit-locking.html) · [Visibilidad de funciones VOLATILE](https://www.postgresql.org/docs/16/xfunc-volatility.html)

| SQLSTATE | Causa |
|---|---|
| `P1001` | Nivel de aislamiento distinto de `READ COMMITTED`. |
| `P1002` | Edición del catálogo o etapa que contradice el historial. |
| `P1003` | Especie admitida declarada para una ubicación de tipo distinto de hogar. |
| `P1004` | El ingreso no existe o ya está cerrado. |
| `P1005` | Instante ausente, inválido o incompatible con el ingreso, la salida o el presente. |
| `P1006` | La estancia vigente difiere del origen esperado. Consulte la ubicación actual antes de decidir otro movimiento. |
| `P1007` | El origen y el destino son la misma ubicación u oferta. |
| `P1008` | Falta la constancia sobre valoración sanitaria del traslado. |
| `P1009` | Destino inexistente. |
| `P1010` | Condición declarada incompatible con el área interna. |
| `P1011` | Llegada o plan de estancia incompatible con el periodo del hogar. |
| `P1012` | Falta aprobación previa o participación vigente del oferente. |
| `P1013` | Especie sin admisión en el hogar. |
| `P1014` | Cupo insuficiente. |
| `P1015` | La primitiva privada de cierre requiere una persona registrada. |

PostgreSQL comunica además los errores de FK, dominio, exclusión y nulabilidad. En una transacción explícita que recibe un error fuera de un bloque de manejo, ejecute `ROLLBACK` antes de iniciar otra. Si la respuesta a un `COMMIT` se perdió, consulte el ingreso y el historial por fecha, destino y actor para saber si se confirmó.
