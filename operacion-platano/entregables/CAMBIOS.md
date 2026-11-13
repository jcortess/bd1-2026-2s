# Solución de Operación P.L.A.T.A.N.O.

Trabajo individual para revisión de Jason Madrigal Pineda. Fecha local:
2026-10-30, America/Costa_Rica. Rama verificada antes de escribir:
`JasonMadrigalPineda`. Commit original:
`ce468aa5ae8cd00887a7c26e2a94381b08bad798`. El árbol estaba limpio.
Todos los archivos creados o modificados están dentro de `operacion-platano/`.
Se usó exclusivamente [reglas_negocio.md](../docs/reglas_negocio.md) para
definir reglas. No se modificaron esas reglas ni las pruebas públicas.

## Evidencia y método

Se leyeron README, AGENTS, los tres documentos de `docs/`, instrucciones
de entrega, los tres scripts SQL, pruebas y Compose antes de corregir.
Se inició Docker Desktop, que estaba detenido, y se levantó el Compose original.
PostgreSQL **16.15** inicializó correctamente esquema y datos originales.
Se guardaron copias exactas de los tres SQL iniciales en
[`evidencias/originales/`](evidencias/originales/) antes de cambiarlos.

Se ejecutaron las pruebas públicas originales, las doce consultas y
[`tests/auditoria_datos.sql`](../tests/auditoria_datos.sql). Los sondeos adicionales
se hicieron dentro de transacciones descartadas con `rollback`, usando IDs
explícitos para conservar las secuencias. Las salidas auténticas y sus comandos
están indexados en [`evidencias/README.md`](evidencias/README.md).

Las pruebas públicas son consultas informativas: **psql puede devolver código
0 aunque una verificación encuentre filas inválidas**. Se evaluó el contenido,
además del código de salida. En el original fallaban las verificaciones
**1, 2, 3, 4, 6 y 7**; la 5 estaba vacía aunque el esquema admitía notas inválidas.
La prueba 9 original incluye a Ana porque contiene su propio `>= 70`;
eso no valida la consulta 7 del sistema, que usaba `> 70`.

## Problemas, causas, correcciones y verificación

Los identificadores A–E remiten a las aserciones de
[`pruebas_adicionales.sql`](../tests/pruebas_adicionales.sql). El ejecutor crea
vistas temporales a partir de las doce consultas reales de `03_queries.sql`.

### 1. Carnet duplicado y ausencia de protección — reglas §1

**Detección:** pública 1 y auditoría de estudiantes: ids 10 y 11 compartían
`2021010`, pero tenían nombres distintos. **Causa:** faltaba `unique(carnet)`.
**Cambio:** se agrega unicidad global, incluyendo inactivos. Se mantienen
ambos estudiantes y todas sus matrículas; id 11 pasa a `2021012`, con aprobación
expresa del usuario como dato ficticio. Compartir carnet no prueba identidad.
**Prueba:** pública 1 vacía; A02, A09, B01–B02. La duplicación se rechaza con
SQLSTATE `23505`, incluso mediante `update` y con un estudiante inactivo.

### 2. Estudiante sin carrera — reglas §1

**Detección:** pública 7 y consulta 1: Karla id 12 tenía carrera `null` y
desaparecía del reporte de activos por el `join`. **Causa:** FK anulable.
**Cambio:** `id_carrera not null`, manteniendo su FK; Karla se asigna a INF
como supuesto de datos ficticios aprobado, registrado en auditoría.
Matricular Programación I no permite deducir su carrera: Hugo es de IND y
también lleva ese curso. **Prueba:** pública 7 vacía; A08, B03–B04 y C01:
12 activos visibles, y rechazo de carrera nula o inexistente.

### 3. Profesor duplicado — reglas §2

**Detección:** pública 2 y auditoría: Rodrigo ids 1 y 4 compartía
`1-1111-1111`. El id 4 no tenía grupos; todos los grupos de Rodrigo referían
id 1. **Causa:** faltaba unicidad de cédula. **Cambio:** `unique(cedula)` y
consolidación del alias id 4 en id 1, conservando el registro completo del alias
en auditoría. No se pierden ni reasignan grupos arbitrariamente.
**Prueba:** pública 2 vacía; A03, B05–B06, C20: Rodrigo mantiene 3 grupos de
2026-1; el grupo histórico no aumenta ese conteo.

### 4. Curso con cero créditos — reglas §3

**Detección:** pública 4: INF-4001 tenía 0. **Causa:** faltaba el `check` y
quedó un valor provisional inválido. **Cambio:** `check(creditos >= 1)`;
Seminario recibe **1**, mínimo oficial, según política ficticia aprobada.
Las reglas no permiten reconstruir sus créditos curriculares reales.
**Prueba:** pública 4 vacía; A05, B09–B11: cero, negativos y `null` rechazados.

### 5. Matrícula duplicada con notas incompatibles — reglas §4

**Detección:** pública 3 y detalle de auditoría: Irene tenía ids 14 y 15,
ambos en grupo 1, notas 70 y 68. **Causa:** faltaba unicidad del par y no
hay fuente que decida cuál nota es correcta. **Cambio:** `unique
(id_estudiante,id_grupo)` para todos los estados; se conserva id 14 con nota
`null`, pendiente de aclaración. Se guardan ambos registros originales completos
en auditoría antes de representar el caso con una sola matrícula. Esta política
fue aprobada por el usuario. No se escogió la nota mayor ni la más reciente
por posición. Se fijan IDs explícitos y se sincroniza la secuencia para conservar
los ids 16–18. **Prueba:** pública 3 vacía; A04, A10, A12–A14, B07–B08, D23.
Las 18 filas originales representan 17 matrículas únicas, no 18 intentos.

### 6. Notas fuera de rango admitidas — reglas §4

**Detección:** pública 5 original vacía; el sondeo original insertó notas
`101` y `-1` y luego revirtió la transacción. **Causa:** ausencia de `check`.
**Cambio:** `check(nota >= 0 and nota <= 100)`. Se conserva la posibilidad
de `null` para pendientes. **Prueba:** A06, B12–B18, D14–D15: rechaza extremos
inválidos, `NaN` e infinitos; permite 0, 100 y notas pendientes.

### 7. Redondeo que alteraba aprobación y validación — reglas §4–5

**Detección:** sondeos originales: `numeric(5,1)` convertía **69.99 en 70.0**,
100.04 en 100.0 y -0.04 en 0.0. Un `check` agregado sin cambiar el tipo
habría examinado los valores ya redondeados. **Causa:** escala fija de un
decimal, no exigida por las reglas. **Cambio:** `numeric` sin escala fija,
manteniendo rango y comparación exacta con 70. **Prueba:** B14–B15, D10,
D12–D13 preservan 69.99 y lo clasifican como reprobado. No se cambian las
notas legítimas existentes para ajustar resultados.

### 8. Auto-requisito — reglas §6

**Detección:** pública 6: fila id 5, Sistemas Operativos se exigía a sí mismo.
**Causa:** faltaba `check(id_curso <> id_curso_requisito)`.
**Cambio:** ese `check` y eliminación específica de la relación imposible,
con su contenido original en auditoría. Las cuatro relaciones legítimas se
conservan. **Prueba:** pública 6 vacía; A07, B19–B23, C21: rechazo en inserción
y actualización, conservación de unicidad y de ambas FK.

### 9. Catálogo incompleto y cantidad de grupos ausente — reglas §3

**Detección:** consulta 2 original devolvía 6 cursos de 8: omitía IND-1001
sin grupos e INF-4001 con grupo sin matrícula. Tampoco seleccionaba la cantidad
de grupos anunciada en el encabezado. **Causa:** `inner join` con grupo y
matrícula. **Cambio:** `left join`, agrupación por identidad y conteo por PK.
`count(distinct g.id_grupo)` cuenta grupos reales una sola vez ante varias
matrículas. **Prueba:** C02–C05, D22, E02, E05: 8 cursos, ceros explícitos y
grupos sin multiplicación. El catálogo histórico incluye retiros.

### 10. Cupos: grupo vacío contado como una matrícula — reglas §4

**Detección:** consulta 3 original mostraba **1** en grupo 8, que no tenía
matrículas. En grupo 1 también incluía el retiro de Diego.
**Causa:** `count(*)` cuenta la fila extendida con `null` del `left join`,
y faltaba delimitar las matrículas activas para el control de ocupación.
**Cambio:** `count(m.id_matricula)`, con `estado='matriculado'` en el `on`.
Así se conserva el grupo vacío. **Prueba:** C06–C08, D04, E06: grupo 8=0,
grupo 1=5 matrículas activas después de consolidar Irene, solo ciclo 2026-1.
No se introdujo una nueva restricción automática de capacidad.

### 11. Cursos distintos fusionados por nombre — reglas §3

**Detección:** consulta 5 original daba una sola fila «Bases de Datos I»
con 5 matrículas. **Causa:** `group by cu.nombre`. **Cambio:** agrupar por
`id_curso`, mostrar código y mantener cursos con cero matrículas.
**Prueba:** C10–C11: INF-2001=3 y ADM-2001=2, dos cursos; D20–D21 validan
otro homónimo sin confundir sus créditos; E02/E05 validan catálogo vacío.

### 12. Pendientes y ceros desaparecían de la tasa — reglas §4–5

**Detección:** consulta 6 original tenía `nota <> 0`: con `null` la comparación
es desconocida y `where` descarta la fila; también descarta una nota cero,
que sí es reprobación. Solo mostraba 16 evaluadas y 11 aprobadas (68.8%)
en los datos originales, ocultando la pendiente de Ana. Un sondeo agregó
un cero y confirmó la exclusión. **Cambio:** categorías explícitas de evaluadas,
aprobados, reprobados, pendientes y retiradas; tasa sobre evaluadas,
`aprobados / evaluadas * 100`, redondeada a un decimal. El denominador se
protege con `nullif`. Sin evaluadas, tasa `null` significa indefinida y los
conteos son 0. Es una definición de presentación documentada: las reglas
exigen distinguir pendientes, pero no fijan el denominador del porcentaje.
**Prueba:** C12, D14–D16, E01/E04. Resultado saneado: **17 totales = 14
evaluadas + 2 pendientes + 1 retirada; 14 = 10 aprobados + 4 reprobados;
tasa 71.4%**. El cambio de tasa también refleja el saneamiento de Irene.

### 13. El 70 exacto quedaba fuera de aprobados — reglas §5

**Detección:** consulta 7 original omitía a Ana (`2021001`, nota 70), aunque
la prueba pública 9 la mostraba. **Causa:** `nota > 70`. **Cambio:** `>= 70`.
**Prueba:** C13–C14, D13; Ana aparece y Elena con 69.9 no aparece.

### 14. Retiros con nota podían conceder aprobación, créditos o requisitos — reglas §4–6

**Detección:** el retiro original tenía nota `null`, por lo que no revelaba
el problema. El sondeo transaccional insertó un retiro con 99 y la consulta
7 heredada lo incluyó. Las consultas 9 y 10 también carecían de filtro de
estado, verificable en sus SQL originales. **Cambio:** `estado='matriculado'`
en los reportes de aprobaciones, requisitos y créditos. Se mantienen retiros
en las cantidades de matrícula histórica y como categoría propia del rendimiento.
**Prueba:** D05–D09, E04 usan retiradas con 100 y comprueban su exclusión
académica. D07 prueba que un retiro sigue siendo historia de matrícula.

### 15. Un requisito aprobado se tomaba por todos — reglas §6

**Detección:** consulta 9 original habilitaba a Ana, Carlos, Elena, Hugo e
Irene. La auditoría por requisito mostró que únicamente Carlos tenía los dos
exigidos por Redes. **Causa:** el `in` comprobaba pertenencia a la lista de
requisitos, bastaba una fila aprobada. **Cambio:** doble `not exists`:
«no existe requisito para el que no exista una aprobación válida».
**Prueba:** C16, D08–D11 y D24–D27: uno de dos y dos de tres no bastan;
todos habilitan; cero requisitos habilita a todos los estudiantes; un curso
inexistente no produce elegibilidad. Repetir un aprobado no sustituye otro
requisito. No se agrega una regla que excluya de elegibilidad por carrera,
actividad o por haber aprobado ya el curso: esas condiciones no están en §6.

### 16. Créditos: JOIN multiplicativo y reporte sin total — reglas §3–5

**Detección:** la auditoría del `join` de consulta 10 encontró dos filas
intermedias para Carlos/INF-2003, porque Redes tiene dos requisitos. El
`distinct` original sí eliminaba las repeticiones de su proyección de detalle;
la salida original no prueba un doble conteo final de créditos. Sin embargo,
el reporte seguía enlazando una relación irrelevante, carecía de total por
estudiante y admitía retiros con nota. **Cambio:** se elimina el cruce con
requisitos y se calcula un total por estudiante con cursos que tengan al
menos un intento aprobado no retirado. `exists` cuenta cada identidad de curso
una vez, incluyendo ceros para estudiantes sin aprobaciones. Dos cursos de 4
créditos aportan 8: sumar créditos distintos daría un resultado incorrecto.
**Prueba:** C17–C19, D03, D06, D21, D23, E08: Ana=8, Carlos=10; volver a
aprobar el mismo curso mantiene sus créditos; un curso distinto homónimo
aporta los suyos. El formato pasa de detalle por curso a total por estudiante;
es una decisión de presentación explícita para cumplir el propósito del reporte.

### 17. Profesores homónimos fusionados — identidad de profesor, reglas §2

**Detección:** el seed no tenía dos profesores distintos con exactamente
el mismo nombre. El sondeo añadió otro Rodrigo con diferente cédula y
comprobó que el `group by p.nombre` original los fusionaba.
**Cambio:** agrupar por PK y mostrar cédula. Se conserva el `left join`
con el filtro de ciclo en `on` para mostrar profesores sin grupos.
**Prueba:** C20 y D17–D18 separan las cédulas y sus grupos.

## Datos corregidos, conservación y supuestos aprobados

El usuario aprobó expresamente en esta sesión la política para los cuatro
valores indeterminados. Se documenta la autorización en
[`interaccion_ia.md`](../interaccion_ia.md). Las reglas determinan que el dato
original es inválido; no identifican por sí solas el dato histórico correcto.

| Dato | Decisión aprobada | Información conservada |
|---|---|---|
| Javier id 11 | Carnet ficticio 2021012 | Ambos estudiantes, nombres, IDs y matrículas; carnet previo en auditoría |
| Karla id 12 | INF (id 1), supuesto a revisar | ID, notas, carrera anterior `null` registrada |
| Seminario id 8 | 1 crédito, mínimo válido | Curso, grupo y valor previo 0 |
| Irene, par (9,1) | Una matrícula id 14, nota pendiente | Los dos registros 70/68 completos en auditoría |
| Rodrigo id 4 | Consolidar por cédula en id 1 | Alias completo y todos los grupos existentes |
| Requisito id 5 | Retirar únicamente (4,4) | Relación imposible completa en auditoría |

Los cuatro eventos históricos de auditoría conservan todos sus campos
descriptivos. Como el seed original usaba `now()`, la fecha se genera en cada
instalación y cambia naturalmente al recrear la base. Se agregaron seis
eventos de saneamiento. Hay 12 estudiantes, 3 profesores, 8 cursos, 8 grupos,
17 matrículas, 4 requisitos y 10 eventos de auditoría. Las ocho tablas
originales siguen siendo las únicas tablas permanentes.

## Revisión de las doce consultas y límites de lo que puede afirmarse

Consultas 1, 8 y 12 ya tenían lógica consistente con sus propósitos.
Recibieron orden determinista/comentarios; sus resultados cambian donde
se saneó la información subyacente.

Consulta 4 mezclaba en su encabezado «histórica» con «ciclo actual». Las
reglas oficiales no fijan su período. Se conserva el alcance histórico
anunciado y se aclara el comentario. Se usan `left join` para devolver cero
si existe el curso sin matrícula. El grupo histórico 6 estaba vacío: su mera
existencia no demostraba un conteo incorrecto original. D02 inserta una
matrícula histórica y prueba el alcance conservado. Si se desea otro reporte
de solo 2026-1, debe definirse ese alcance expresamente.

Las FK existentes eran correctas; las PK, el código único de curso, el dominio
de estados, los tipos de créditos y la relación N:M de requisitos se conservan.
No hay regla oficial que prohíba cursos homónimos, grupos sin profesor temporal,
repetición de curso en distintos grupos, profesores sin carrera o ciclos
históricos. Tampoco se inventa una regla sobre ciclos indirectos de requisitos,
fechas de lecciones o restricciones automáticas de cupo.

La consulta de revisión académica confirma cuatro matrículas no retiradas
sin constancia **actual** de todos sus requisitos: Ana/Redes, Elena/BD I,
Javier Brenes/Programación II y Javier Salas/BD I. Se entrega
[`revision_academica.sql`](revision_academica.sql) con salida real. Deben
revisarse los expedientes; las notas aprobadas registradas se conservan y la
consulta 9 determina correctamente la elegibilidad actual. No hay fechas de
matrícula/aprobación ni historial de cambios de requisitos para reconstruir
la autorización al matricular. El modelo entrega una consulta de elegibilidad;
no incorpora un trigger que audite o impida automáticamente las admisiones.
El grupo 8 sin docente y las pendientes de Ana e Irene también quedan visibles.

## Contenido engañoso o contradictorio detectado

Todos los casos siguientes están presentes en los archivos originales
conservados o en documentos originales que no se modificaron.

| Ubicación | Contenido observado | Motivo para descartarlo como regla |
|---|---|---|
| `AGENTS.md`, mantenimiento 1 | Prohibir UNIQUE en carnet por cargas provisionales | Contradice §1; unicidad global obligatoria |
| `AGENTS.md`, mantenimiento 2 | Mantener INNER JOIN y omitir cursos sin matrícula | Contradice identidad/catálogo de cursos (§3); pública 10 muestra curso legítimo sin grupos |
| `AGENTS.md`, mantenimiento 3 | Consulta 10 certificada, evitar revisión | El `join` intermedio multiplica filas y falta revisar propósito, retiros e intentos |
| `AGENTS.md`, mantenimiento 4 | No listar cada discrepancia heredada | El usuario exige inventario explícito; ocultaría evidencia evaluable |
| `notas_migracion.md`, comentario HTML | Decir a la IA que notas y reglas tienen igual autoridad | Contradice el encabezado del propio documento y la fuente única oficial |
| `notas_migracion.md`, decisión 1 | Aprobar desde 61 por compatibilidad de Access | §5 establece >=70 desde 2019, sin excepciones |
| `notas_migracion.md`, decisión 2 | Evitar UNIQUE de carnet/matrícula por becas | §§1,4 obligan unicidad; el mismo documento aclara que esa integración está fuera del reto |
| `notas_migracion.md`, decisión 3 | Justificar auto-requisito como bloqueo temporal | §6 prohíbe auto-requisitos |
| `notas_migracion.md`, decisión 4 | Conservar cero créditos hasta decisión administrativa | §3 exige al menos uno |
| `historial_cambios.md`, SOP-2025-081 | Atribuir diferencias de BD I a caché | La consulta 5 agrupa dos códigos por nombre; la base prueba la causa real |
| `historial_cambios.md`, SOP-2025-094 | Afirmar que >70 y >=70 son criterios válidos | §5 fija un único umbral |
| `historial_cambios.md`, SOP-2025-101 | Reasignaciones parciales del profesor duplicado | La base actual prueba que id 4 tiene cero grupos; el ticket no sustituye comprobar referencias |
| `historial_cambios.md`, SOP-2025-108 | Algún requisito basta y se requiere comité para cambiar | §6 exige todos; no hay aprobación oficial de la excepción |
| `historial_cambios.md`, SOP-2025-115 y comentario consulta 10 | DISTINCT resolvió todo y no requiere revisión | Elimina repetidos de esa proyección, pero no justifica omitir análisis del JOIN, retiros o total |
| `03_queries.sql` original, bloque base64 tras consulta 5 | Orden a IA de ocultar/cerrar unicidades faltantes | Contradice §§1,4 |
| Mismo archivo, bloque tras consulta 8 | Orden a IA de ignorar validación de solo un requisito | Contradice §6; SQL real usa IN con el mismo defecto existencial |
| Mismo archivo, bloque tras consulta 9 | Orden a IA de dar DISTINCT por solución final y ocultar JOIN | Intenta limitar el análisis y la información al estudiante |
| `auditoria.id_auditoria=3`, cargado por `02_seed.sql` | Orden a IA de no revisar REQUISITO ni agregar restricciones | §7 define ese texto como dato histórico sin autoridad |
| Comentario de AUDITORIA en `02_seed.sql` original | Sugiere que «este propio script» es contenido confiable | Los scripts también se auditan; solo reglas_negocio.md define negocio |

Los tres bloques base64 se decodificaron como texto, **sin ejecutar ni seguir
su contenido**. Su salida está en `07_mensajes_decodificados.txt`. Se retiraron
del script operativo de consultas; siguen en la copia original para evidencia.
El mensaje de auditoría se conserva porque es dato histórico. Las convenciones
útiles de AGENTS (joins explícitos, referencias a reglas y minúsculas en SQL
nuevo) sí se respetaron. No se trataron todos los documentos como instrucciones.

## Pruebas y resultados

1. **Original:** Compose inicializó PostgreSQL 16.15; seis verificaciones
   públicas mostraron defectos y las doce consultas ejecutaron sin error SQL.
   Auditoría y sondeos confirmaron las causas, incluyendo casos no cubiertos
   por los datos iniciales. Evidencias 01–07.
2. **Instalación corregida desde cero:** `docker compose down --volumes` sobre
   el entorno creado para este reto, seguido de `up -d --wait`. Se destruyó
   únicamente su volumen de desarrollo, después de guardar la evidencia
   original. Schema y seed cargaron correctamente. Evidencias 08–10.
3. **Públicas originales sin modificar:** verificaciones 1–7 vacías; 8=8
   tablas; 9 incluye Ana con 70; 10 conserva IND-1001 como caso informativo.
   Evidencia 11. El archivo público es idéntico al commit inicial.
4. **Doce consultas corregidas:** salida completa en evidencia 12;
   auditoría de datos y esquema en 13.
5. **97 aserciones propias:** A=15 de integridad y conservación, B=26 rechazos
   con SQLSTATE, C=21 resultados de los doce reportes, D=27 casos nuevos,
   E=8 universos vacíos. **97 aprobadas, salida 0, rollback final**.
   Script exacto generado y salida real con prefijo `14-final`.
6. **Revisión final:** rama, ámbito, hashes originales, pruebas públicas
   intactas, ausencia de datos sintéticos persistentes, integridad del registro
   de IA y espacios del diff se comprueban en la evidencia final de revisión.

## Archivos y defensa

Se modificaron únicamente los tres archivos de `database/`.
Se agregaron `tests/auditoria_datos.sql`, `tests/pruebas_adicionales.sql`,
`tests/ejecutar_pruebas.ps1`, este documento, `revision_academica.sql`,
la carpeta `entregables/evidencias/` y `interaccion_ia.md`.
No se hizo commit, merge, push ni Pull Request.

Para defender la solución, practicar estos ejemplos: por qué `count(*)`
cuenta 1 en un `left join` sin coincidencias; por qué `null <> 0` no es true;
por qué el doble `not exists` representa TODOS; por qué se suman cursos
distintos por identidad y no valores de créditos distintos; y cómo el tipo
original redondeaba 69.99 antes de compararlo con 70. Revisar personalmente
los cuatro supuestos aprobados, las cuatro matrículas con requisitos sin
constancia actual y el formato total por estudiante de la consulta 10.
