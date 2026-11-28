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

- A usuarios operativos se les concede el rol `huellas_g05_operador`. Puede consultar las tablas y vistas y ejecutar únicamente `mover_animal` en este bloque. El instalador administra el catálogo y los ingresos preparados, actúa como propietario de la función y debe mantenerse separado del rol operativo. Las pruebas SQL que intentan DML directo sobre ESTANCIA como propietario lo hacen en una transacción reversible para verificar sus restricciones físicas. Para operación normal, la escritura sobre ESTANCIA pasa por la función pública o por la primitiva privada dentro de la formalización integrada de G05-P03.
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

# G05-P02 · Evaluar solicitudes y compatibilidad · Paula

Implementado en [06_paula_operaciones.sql](sql/06_paula_operaciones.sql), con [vistas e interfaz de consumo](sql/08_paula_consultas.sql). [Casos reproducibles](pruebas/Casos_Paula.md) · [Resultados actuales](evidencias/Resultados_Paula.md) · [Decisiones del modelo](modelo/Modelo_Relacional.md).

## Operaciones públicas

Todas las firmas siguientes pertenecen al esquema `huellas`. Las fechas son `timestamptz` finitas, reales y no futuras; en los ejemplos se usa Costa Rica. Los IDs son bigint; UUID debe ser nuevo para cada intento lógico. Las firmas SQL exactas y valores de demostración están en los scripts, no dependen de copiar bloques Markdown.

| Operación y retorno | Parámetros, propósito y precondiciones | Efectos y resultados | Rechazos y prueba |
|---|---|---|---|
| `crear_solicitud(uuid,bigint,timestamptz,text,text,text,text,bigint,text[] DEFAULT '{}') → bigint` | `p_clave`, `p_solicitante`, `p_fecha`, `p_vivienda`, `p_integrantes`, `p_experiencia`, `p_cuidado`, `p_responsable`, `p_animales`. Solicitante existente, cuatro textos no vacíos, personal/voluntario vigente. Array vacío o NULL significa solicitud general. | Crea solicitud/hogar, recepción RECIBIDA atribuible y cero o muchos intereses con fecha; devuelve ID. Una falla en un animal revierte todos esos cambios. | Clave repetida, referencia inexistente, texto ausente/vacío, animal repetido, fecha o actor inválido. P01/P05/P07/P08. |
| `asociar_animal(bigint,text,timestamptz) → void` | `p_solicitud`, `p_animal`, `p_fecha`. Solicitud y animal existentes; momento no anterior a recepción. | Agrega únicamente interés; no decide compatibilidad ni modifica estado. La pareja identifica el efecto de un reintento. | Pareja duplicada, referencia ausente, fecha inválida. P02/P08. |
| `registrar_actividad(uuid,bigint,timestamptz,bigint,text,text,text) → bigint` | `p_clave`, `p_solicitud`, `p_fecha`, `p_responsable`, `p_tipo`, `p_resultado`, `p_observaciones`. Tipo ENTREVISTA, VISITA_HOGAR, INFORMACION u OTRA_ACTIVIDAD; resultado y observaciones no vacíos; actor vigente. | Agrega un evento de actividad, devuelve ID. No cambia estado global, incluso si el texto de resultado expresa una opinión favorable. | Falta de contexto, tipo distinto, actor/fecha inválidos, resultado u observación ausentes, clave repetida. P02/P06/P09. |
| `decidir_solicitud(uuid,bigint,bigint,timestamptz,bigint,text,text,text DEFAULT NULL) → bigint` | `p_clave`, `p_solicitud`, `p_antecedente`, `p_fecha`, `p_responsable`, `p_estado`, `p_razon`, `p_observaciones`. Antecedente obtenido de `estado_actual_solicitud.decision_id`; siete estados RN-18, responsable y razón obligatorios. Fecha no anterior al antecedente. | Agrega decisión y referencia a su antecedente. La vista deriva estado vigente del último evento de estado. Un RECHAZADA se confirma como resultado de negocio con su razón; no es excepción técnica. | Antecedente viejo, estado ajeno, falta de razón/responsable o contexto. P03/P05/P06/P09; C-P01–03. |
| `evaluar_compatibilidad(uuid,bigint,text,bigint,timestamptz,bigint,text,text,text,text,bigint DEFAULT NULL) → bigint` | `p_clave`, `p_solicitud`, `p_animal`, `p_ingreso`, `p_fecha`, `p_responsable`, `p_resultado`, `p_valoracion`, `p_razon`, `p_observaciones`, `p_actividad`. Interés existente; ingreso del mismo animal; hogar inmutable de esa solicitud; valoración individual completa. Actividad opcional previa y de la misma solicitud. | Agrega valoración histórica; devuelve ID. Resultados FAVORABLE, NO_FAVORABLE o PENDIENTE_INFORMACION. Una reevaluación conserva la anterior. No exige que la solicitud esté ya aprobada para poder evaluarla. | Referencias cruzadas, fecha anterior al interés/última valoración, estado inválido, evaluación sin valoración concreta, actividad ajena o que es una decisión. P04/P10/P11/R09. |
| `contar_revisiones_animal(text) → integer` | `p_codigo_animal`. Consulta reutilizada de Lab03. | Cuenta revisiones veterinarias, sin incluir iniciales ni modificar datos. Cero si el código no tiene revisiones. | R05-reutilizacion-clinica. |

Cada llamada compuesta es una sentencia atómica de PostgreSQL. No contiene COMMIT interno; quien ejecuta puede agrupar varias en BEGIN/COMMIT y un fallo no controlado deja su transacción abortada hasta ROLLBACK. P07 provoca una falla después de cabecera, recepción y primer detalle y comprueba directamente la ausencia de efectos. Una falla al insertar una decisión no actualiza una columna de estado por separado: el estado solo existe como proyección de decisiones válidas, por lo que no puede quedar desincronizado.

No se establecen duraciones de vencimiento ni un grafo de transiciones no presente en las fuentes. Pasar entre los estados o ratificar uno requiere nuevo antecedente, fecha, responsable y razón. La visita se registra cuando sea pertinente; no se exige a todas las solicitudes. Se conserva información complementaria como actividad; si cambia materialmente el hogar, otra solicitud identifica el nuevo contexto sin reinterpretar compatibilidades históricas.

## Consultas y consumo desde G05-P03

El archivo [08_paula_consultas.sql](sql/08_paula_consultas.sql) puede ejecutarse nuevamente como **consultas** solo seleccionando sus SELECT; sus CREATE VIEW forman parte de la instalación de una base nueva. Para repetir todas las lecturas sin recrear vistas está [04_consultas_paula.sql](pruebas/04_consultas_paula.sql).

| Consulta | Comprobación |
|---|---|
| `estado_actual_solicitud` | Estado vigente, decisión/actor/razón, hogar concreto y si sigue general. Filtrar por `es_general` o estado PENDIENTE_INFORMACION. |
| `solicitud_animal` | Intereses y fechas; no contiene resultados de compatibilidad. |
| `historial_solicitud` | Actividades con resultado/observación y decisiones con estado/razón. Ordenar por solicitud, fecha e ID para desempates. |
| `compatibilidad_animal_hogar` y `contexto_compatibilidad` | Todas las valoraciones de cada animal/hogar/etapa, con actividad de apoyo y datos exactos de vivienda, integrantes, experiencia y cuidado. |
| `compatibilidad_vigente` | Última valoración por solicitud, animal e ingreso; una pendiente posterior invalida el uso del favorable antiguo. |
| Solicitudes rechazadas y posteriores | JOIN por solicitante con fecha posterior a la decisión rechazada; ambas PK e historias permanecen separadas. |
| `historial_evaluaciones`, `resumen_revisiones`, `contar_revisiones_animal` | Antecedentes clínicos por animal/etapa; iniciales sin diagnóstico y apariciones confirmadas, sin inferir disponibilidad. |
| `disponibilidad_actual` | Última decisión sanitaria/administrativa por animal e ingreso, con actor y valoración. |

La primitiva **privada** `_exigir_compatibilidad(p_solicitud bigint,p_animal text,p_ingreso bigint,p_fecha timestamptz) → bigint` puede ser invocada por las rutinas SECURITY DEFINER integradas de Jean Carlos bajo el mismo propietario. Requiere decisión general APROBADA no posterior a la operación, etapa abierta del animal y última valoración individual FAVORABLE no posterior. Devuelve el ID de la evidencia, conservable mediante la clave `(id_compatibilidad,solicitud_id,animal_codigo,ingreso_id)`. No modifica disponibilidad, reserva, adopción, estancia ni etapa. El consumidor debe comprobar por separado disponibilidad atribuible, restricciones y adjudicación exclusiva. Si otra familia evalúa al animal favorablemente, esa evaluación tampoco adjudica el animal.

Los diagnósticos pueden existir sin nuevas indicaciones y sin nuevos cambios de disponibilidad. Esos hechos se preparan y verifican como integridad; no se incorpora un cuarto proceso operativo de atención médica.

## Escritura, historia y permisos

Se conserva el rol compartido `huellas_g05_operador`. Tiene SELECT de las diez tablas nuevas y sus vistas, y EXECUTE de las cinco operaciones públicas más el conteo. No recibe INSERT/UPDATE/DELETE/TRUNCATE ni privilegios de secuencias de este bloque, tampoco EXECUTE de auxiliares privados. El propietario instalador prepara catálogos, reportes, antecedentes clínicos y disponibilidad con INSERT controlado por restricciones/triggers. No se presenta al propietario/superusuario como un usuario operativo.

Evaluaciones, apariciones diagnósticas, decisiones de disponibilidad, solicitudes/hogar, intereses, actividades, decisiones y compatibilidades son inmutables una vez insertados; los triggers rechazan UPDATE/DELETE aun al preparar datos como propietario. Cambios clínicos se expresan en una revisión posterior, y decisiones/reevaluaciones en filas nuevas. Reportes con información desconocida y nombres del catálogo sí admiten rectificación como instalador, con FK que impiden invalidar referencias. No hay cascadas nuevas que borren historia. La participación usada se conserva y no puede acortarse de manera que excluya el hecho histórico. La etapa no puede desplazarse/cerrarse de forma que deje una evaluación fuera del contexto.

El alta de un ingreso requiere una inicial antes de COMMIT, mediante restricción diferida; el alta de solicitud requiere recepción atribuible antes de COMMIT. El instalador debe agrupar esos hechos. En la instalación, 07 carga los antecedentes existentes y 08 comprueba que ninguna etapa de la semilla quedó sin inicial. No se generan evaluaciones ficticias automáticamente en una operación real.

## Concurrencia y reintentos

Todas las rutas P02 adquieren primero `_bloquear_alojamiento()` (bloqueo asesor `(50301,1)`), compartido con el catálogo/alojamiento de Jason, y después bloquean/releen la solicitud. Los triggers de INSERT como propietario siguen el mismo orden; los mecanismos de historia y FK también aplican a esa preparación. Se exige READ COMMITTED para que las consultas VOLATILE posteriores al bloqueo vean los cambios confirmados por la sesión precedente. Coste: el bloqueo serializa también solicitudes independientes; es una elección documentada para el tamaño académico y un orden único de integración. [PostgreSQL: bloqueos](https://www.postgresql.org/docs/18/explicit-locking.html) · [Volatilidad y snapshots](https://www.postgresql.org/docs/18/xfunc-volatility.html).

C-P01 observa B esperando antes de que A confirme: al continuar, B detecta el antecedente desactualizado y obtiene P2021, conservando la decisión de A y sin registrar una decisión de B. C-P02 observa la misma espera pero A revierte: B relee el antecedente todavía vigente y confirma su rechazo con razón. C-P03 consulta la clave de A y prueba que el reenvío ciego no duplica; una decisión posterior informada enlaza a la de A y conserva ambas. No hay reintento automático que cambie el antecedente sin volver a decidir.

Ante pérdida de respuesta de COMMIT, consultar `clave_operacion` en solicitud, evento o compatibilidad; revisar el contenido antes de volver a enviar. Las asociaciones se consultan por su pareja. Reutilizar UUID produce unicidad o conflicto de antecedente y ningún efecto adicional. Un UUID diferente representa una decisión nueva: el motor no adivina que dos órdenes diferentes eran el mismo intento.

## Errores identificables

| SQLSTATE | Causa del bloque |
|---|---|
| P2001 | Intento de editar/borrar un hecho histórico. |
| P2002 | Fecha ausente/futura/infinita o anterior a su solicitud/interés/antecedente/valoración vigente. |
| P2003 | Responsable inexistente o ausente. |
| P2004 | Actor sin participación vigente de personal/voluntario o participación indicada incorrecta. |
| P2005 | Solicitud inexistente. |
| P2010 | Evaluación/disponibilidad/compatibilidad fuera de su etapa. |
| P2011 | Revisión sin inicial previa en esa etapa. |
| P2012 | Registro veterinario ausente, ajeno o no vigente. |
| P2013 | Ingreso sin inicial al comprobar la restricción diferida / instalación incompleta. |
| P2014 | Edición del ingreso que invalida su contexto clínico/evaluado. |
| P2015 | Edición de participación que invalida atribución histórica. |
| P2020 | Solicitud sin recepción o decisión sin recepción previa. |
| P2021 | Antecedente desactualizado; releer antes de decidir de nuevo. |
| P2022 | Referencia de apoyo que no es actividad previa de la solicitud. |
| P2023 | Tipo inválido para registrar actividad. |
| P2024 | Consumo P03 sin aprobación general válida. |
| P2025 | Consumo P03 con etapa ajena/cerrada o fecha incompatible. |
| P2026 | Consumo P03 sin valoración individual favorable vigente. |
| P1001 | Aislamiento diferente de READ COMMITTED (primitiva compartida). |
| 23502/23503/23505/23514 | Obligatoriedad, FK/contexto, identidad/reenvío o dominio/CHECK; las pruebas exigen el nombre de restricción cuando discrimina la causa. |
| 42501 | Escritura o auxiliar privado fuera de permisos del rol operativo. |

## Reproducción y defensa

[README, bloque Paula](README.md#bloque-de-paula-g05-p02) identifica instalación y sesiones. [Defensa.md](Defensa.md) contiene la secuencia de demostración para Paula; P03 se documenta a continuación; la grabación del equipo sigue pendiente.

# G05-P03 · Reservar y formalizar adopciones · Jean Carlos

Implementado en [10_jeank_esquema.sql](sql/10_jeank_esquema.sql) y [11_jeank_operaciones.sql](sql/11_jeank_operaciones.sql). Consume las interfaces de P01 y P02 sin sustituirlas. [Casos](pruebas/Casos_Jeank.md) · [Resultados](evidencias/Resultados_Jeank.md) · [Matriz](modelo/Matriz_Integridad.md).

## Operaciones públicas

Las firmas pertenecen al esquema `huellas`. El cliente controla BEGIN, COMMIT y ROLLBACK.

| Operación y retorno | Parámetros en orden | Validaciones y efectos |
|---|---|---|
| `registrar_reserva(uuid,bigint,text,bigint,timestamptz,bigint) → bigint` | `p_clave_operacion`, `p_solicitud_id`, `p_animal_codigo`, `p_ingreso_id`, `p_fecha_reserva`, `p_responsable_id` | Exige aprobación, interés, compatibilidad favorable vigente, etapa abierta, disponibilidad habilitada, actor válido y solicitante sin restricción vigente. Impide otra reserva activa y resultados incompatibles. Devuelve el ID de reserva. |
| `finalizar_reserva(bigint,timestamptz,bigint) → bigint` | `p_reserva_id`, `p_fecha_fin`, `p_responsable_id` | Valida actor, reserva vigente y cronología; registra fin sin borrar historia. El actor de finalización se valida pero no se almacena en una columna independiente. |
| `formalizar_adopcion(uuid,bigint,bigint,timestamptz,text,bigint,bigint[]) → bigint` | `p_clave_operacion`, `p_reserva_id`, `p_estancia_esperada`, `p_fecha_entrega`, `p_condiciones_aceptadas`, `p_responsable_entrega`, `p_responsables` | Revalida reserva, contexto, compatibilidad, disponibilidad y restricciones. Exige responsables, incluido el solicitante. Inserta adopción y responsables, finaliza reserva y cierra alojamiento e ingreso en la misma transacción. Devuelve ID de adopción. |

La aprobación de una solicitud no crea una reserva. La reserva identifica una adjudicación concreta por animal y etapa. Una solicitud puede producir adopciones individuales de distintos animales; cada ingreso admite una sola adopción. Las claves UUID son únicas por tabla; ante pérdida de respuesta, consultar la clave y el estado persistido antes de reenviar.

## Ejemplo reproducible

En una base nueva instalada mediante `sql/15_instalar_proyecto_completo.sql`, ejecutar `pruebas/05_preparacion_jeank.sql` antes del ejemplo. No combinar este ejemplo con el guion secuencial en la misma base, pues ambos consumen los mismos antecedentes. Ejecutar en psql:

```sql
BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT huellas.registrar_reserva(
  '19000000-0000-0000-0000-000000000001',
  1, 'HS-01', 1, '2026-10-07 13:00:00-06', 1
) AS reserva_creada \gset
COMMIT;

BEGIN;
SET LOCAL ROLE huellas_g05_operador;
SELECT huellas.formalizar_adopcion(
  '19000000-0000-0000-0000-000000000003',
  :reserva_creada, 1, '2026-10-07 14:00:00-06',
  'Condiciones aceptadas para la demostración', 1, ARRAY[101]::bigint[]
);
COMMIT;
SELECT * FROM huellas.v_control_adopciones_jeank;
```

El resultado esperado es una adopción CONSISTENTE. Los identificadores del ejemplo corresponden a la preparación indicada; para otros datos consultar los IDs reales. Los guiones de pruebas constituyen la reproducción de referencia.

## Atomicidad, concurrencia y cierre

Las operaciones adquieren el bloqueo asesor compartido de alojamiento y catálogo, bajo READ COMMITTED, antes de validar y modificar el contexto. La reserva se protege también con el índice único parcial `reserva_animal_vigente_uq`. La formalización usa `_cerrar_etapa_alojamiento` con la estancia esperada; no confirma internamente. El trigger diferido `adopcion_integridad_final` comprueba responsables, cierre del ingreso y reserva al instante de entrega y ausencia de resultado incompatible. La vista de control incluye la comprobación de estancia abierta.

PJ-10 demuestra dos sesiones reales: A mantiene la reserva sin confirmar, B espera el bloqueo asesor, A confirma y B recibe P3021 y revierte. La lectura posterior confirma una sola reserva vigente y conserva ambas compatibilidades. PJ-11 provoca P1006 con una estancia esperada incorrecta, comprueba que no hay adopción ni cierre parcial y confirma un reintento correcto. [Concurrencia](evidencias/Ejecucion_Jeank_Concurrencia.md) · [Secuencial](evidencias/Ejecucion_Jeank_Secuencial.md).

## Devolución, seguimiento y otros resultados

- La finalización de una adopción conserva su historia y exige tipo y fecha coherentes. El reingreso por devolución o recuperación referencia la adopción del mismo animal, finalizada con el tipo correspondiente; exige receptor, motivo y evaluación inicial propia antes de COMMIT. La FK `ingreso_adopcion_origen_fk` se instala en 11; no ejecutar el parche histórico por separado.
- Una devolución voluntaria no crea una restricción. `restriccion_persona` registra una decisión independiente con motivo, actor y periodo; la vigencia se comprueba al reservar y formalizar. PJ-03 y PJ-09 aportan evidencia de ambos escenarios.
- El seguimiento conserva fecha prevista, medio, responsable, estado y resultado. Una realización exige fecha efectiva y resultado; una reprogramación crea otra fila vinculada a la misma adopción, con fecha posterior y origen REPROGRAMADO. PS01–PS05 comprueban realización, cronología, historia y reprogramación.
- `resultado_etapa` representa cierres distintos de adopción. El traslado exige organización y condiciones; el trigger diferido exige fecha de cierre coincidente. PJ-08 comprueba rechazo de resultado incompatible; no se documenta todavía una ejecución positiva específica de traslado.

Estas escrituras de finalización de adopción, reingreso, seguimiento, restricciones y otros resultados se preparan mediante DML del propietario sujeto a restricciones y triggers; no se afirma que existan rutinas públicas específicas para ellas.

## Integración clínica (RN-12 y RN-13)

`indicacion` pertenece a una revisión veterinaria. La sustitución conserva el historial y valida animal y cronología. `indicacion_diagnostico` utiliza dos FK contextuales que impiden asociar diagnósticos de una revisión ajena (corrección A2; PC06/PC07).

| Rutina | Propósito |
|---|---|
| `CALL huellas.registrar_aplicacion(bigint,timestamptz,bigint,text)` | ID de aplicación, fecha real, responsable y observaciones. Bloquea la fila, valida cronología y datos completos, registra la ejecución una sola vez. |
| `huellas.estado_aplicacion(bigint) → text` | Consulta estado derivado: REALIZADA, PROGRAMADA o VENCIDA según fecha real y planificada. |
| `huellas.generar_reporte_pendientes()` | Consulta aplicaciones sin fecha real. |

PC01–PC05 comprueban ejecución, repetición, fecha anterior a evaluación y datos incompletos. No se incorpora un cuarto proceso de negocio; se documenta la integridad clínica del modelo.

## Consultas del bloque

Las vistas se instalan mediante [13_jeank_consultas.sql](sql/13_jeank_consultas.sql).

| Vista | Uso |
|---|---|
| `v_indicaciones_jeank`, `v_aplicaciones_jeank` | Indicaciones y ejecución clínica. |
| `v_reservas_jeank`, `v_reservas_vigentes_jeank` | Historial y adjudicaciones activas. |
| `v_adopciones_jeank`, `v_responsables_adopcion_jeank` | Formalizaciones y responsables. |
| `v_restricciones_jeank`, `v_seguimientos_jeank` | Decisiones restrictivas y seguimiento. |
| `v_resultados_etapa_jeank`, `v_reingresos_jeank` | Otros resultados y retornos. |
| `v_control_adopciones_jeank` | Coherencia del cierre de adopción. |

## Permisos y errores

El rol `huellas_g05_operador` consulta y ejecuta las operaciones autorizadas, sin DML directo en las nueve tablas. Las rutinas de escritura públicas usan SECURITY DEFINER y search_path controlado. PP01 comprueba el rechazo 42501 al actualizar directamente una indicación. No se atribuye a ese caso la comprobación individual de todos los privilegios.

| SQLSTATE | Causa comprobada en pruebas |
|---|---|
| P1006 | Estancia esperada distinta de la vigente. |
| P2025 | Etapa ajena o incompatible. |
| P3005 | Aplicación ya realizada. |
| P3008 | Planificación anterior a evaluación. |
| P3011 | Datos de aplicación realizada incompletos. |
| P3015 | Restricción vigente documentada. |
| P3017 | Reserva ya finalizada. |
| P3021 | Animal con reserva vigente. |
| P3022 | Resultado incompatible con adopción. |
| P3042 | Seguimiento con resultado definitivo. |
| P3045 | Seguimiento anterior a adopción. |
| P3048 | Reprogramación de otra adopción. |
| 23503 | FK contextual clínica incumplida. |
| 42501 | Permiso insuficiente. |

Los restantes códigos P3001–P3065 y sus condiciones se definen en 11. Ante error no controlado, ejecutar ROLLBACK antes de otra transacción. No reintentar sin consultar el contexto vigente.

## Reproducción y alcance

[README](README.md) contiene el orden de instalación y pruebas; [Casos_Jeank](pruebas/Casos_Jeank.md) identifica los 25 casos PJ, PC, PS y PP. [Instalación](evidencias/Ejecucion_Jeank_Instalacion.md) registra la comprobación de las 28 tablas y formalización en base nueva. Los resultados cubren los escenarios ejecutados; las pruebas declarativas y fronteras todavía no aisladas se identifican en la matriz consolidada. La grabación se documentará en [Defensa](Defensa.md).
