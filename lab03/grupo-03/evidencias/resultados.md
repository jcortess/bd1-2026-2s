# Evidencias de ejecución — Laboratorio 03

## Entorno de verificación

- Motor: PostgreSQL 17.11.
- Base de prueba: `ci_grupo_03`.
- Usuario: `ci_runner`, sin privilegios de superusuario.
- Ejecución mediante `psql` dentro de Docker.

## A2 — Creación del esquema

**Resultado esperado:** creación de seis tablas sin errores.

**Resultado observado:** seis instrucciones `CREATE TABLE`, seguidas de `COMMIT`.

**Conclusión:** el script `01_esquema.sql` se ejecutó correctamente sobre una base vacía.

## B1 — Carga de datos

| Tabla | Registros insertados |
|---|---:|
| `escuela` | 2 |
| `carrera` | 2 |
| `curso` | 8 |
| `version_plan_estudios` | 3 |
| `participacion_plan` | 16 |
| `requisito_curso` | 10 |
| **Total** | **41** |

**Resultado observado:** todas las inserciones finalizaron correctamente y la transacción confirmó los cambios mediante `COMMIT`.

## B2 — Consultas

### Q01 — Cursos de una versión del plan

**Pregunta:** ¿Qué cursos componen la versión 102 y cuál es su tipo de participación?

**Resultado esperado:** siete cursos, seis obligatorios y uno optativo.

**Resultado observado:**

| codigo_institucional | nombre | tipo_participacion | nivel_o_periodo_recomendado |
|---|---|---|---|
| UH-MAT1 | Matematica Discreta | Obligatorio | 1 |
| UH-PROG1 | Introduccion a la Programacion | Obligatorio | 1 |
| UH-PROG2 | Programacion Intermedia | Obligatorio | 2 |
| UH-ALG1 | Algoritmos y Estructuras | Obligatorio | 3 |
| UH-BDAT1 | Bases de Datos | Obligatorio | 3 |
| UH-EST1 | Estadistica Aplicada | Obligatorio | 3 |
| UH-RED1 | Redes de Computadoras | Optativo | 4 |

La consulta devolvió siete registros.

**Conclusión:** se recuperaron correctamente los cursos correspondientes a la versión 102 mediante la relación entre `participacion_plan` y `curso`.

### Q02 — Requisitos de un curso

**Pregunta:** ¿Qué requisitos previos y correquisitos tiene UH-BDAT1 en la versión 102?

**Resultado esperado:** un requisito previo y dos correquisitos.

**Resultado observado:**

| tipo_requisito | codigo_exigido | curso_exigido |
|---|---|---|
| Correquisito | UH-EST1 | Estadistica Aplicada |
| Correquisito | UH-MAT1 | Matematica Discreta |
| Requisito previo | UH-PROG2 | Programacion Intermedia |

La consulta devolvió tres registros.

**Conclusión:** se identificaron correctamente los tres requisitos registrados para el curso en la versión seleccionada.

### Q03 — Distribución de cursos por versión

**Pregunta:** ¿Cuántos cursos obligatorios y optativos tiene cada versión del plan?

**Resultado esperado:** versión 101 con cinco obligatorios y un optativo; versión 102 con seis obligatorios y un optativo; versión 201 con dos obligatorios y un optativo.

**Resultado observado:**

| id_version_plan | tipo_participacion | cantidad_cursos |
|---|---|---:|
| 101 | Obligatorio | 5 |
| 101 | Optativo | 1 |
| 102 | Obligatorio | 6 |
| 102 | Optativo | 1 |
| 201 | Obligatorio | 2 |
| 201 | Optativo | 1 |

La consulta devolvió seis agrupaciones, correspondientes a las combinaciones de versión y tipo de participación existentes.

**Conclusión:** la agregación mediante `COUNT` y `GROUP BY` produjo las cantidades esperadas.

## A3 — Reproducibilidad

Se crearon una base de datos independiente y un usuario sin privilegios de superusuario. Sobre la base inicialmente vacía se ejecutaron correctamente:

1. `01_esquema.sql`
2. `02_datos.sql`
3. `03_consultas.sql`

Posteriormente se ejecutaron `04_rutinas.sql` y `05_pruebas.sql` sobre la misma base, utilizando `ON_ERROR_STOP=1`.

**Resultado observado:** se crearon tres funciones y un procedimiento almacenado; las nueve pruebas emitieron sus respectivos avisos de éxito, sin errores inesperados.

**Conclusión:** se verificó la creación del esquema y la carga inicial sobre PostgreSQL vacío, así como la ejecución satisfactoria de las rutinas y pruebas sobre la base preparada.

## B3 — Pruebas de integridad y funcionamiento

### Entorno y precondiciones generales

- PostgreSQL mediante la imagen Docker `postgres:17`, contenedor `bd1-lab03`.
- Base de datos `ci_grupo_03`, usuario `ci_runner`, cliente `psql` y terminal PowerShell.
- Esquema y datos iniciales cargados mediante `01_esquema.sql` y `02_datos.sql`.
- Funciones y procedimiento creados mediante `04_rutinas.sql`.
- Datos iniciales sin modificaciones persistentes que alteren las precondiciones de cada prueba.
- Las instrucciones SQL se ejecutan dentro de `psql`; PowerShell se utiliza para invocar Docker.

**Comando de ejecución:**

```powershell
docker exec bd1-lab03 psql -X -v ON_ERROR_STOP=1 -U ci_runner -d ci_grupo_03 -f /tmp/05_pruebas.sql
```

Los bloques de `05_pruebas.sql` comprueban los resultados y emiten `RAISE NOTICE` al aprobar. Las pruebas negativas capturan la excepción esperada; una excepción distinta o un resultado inesperado provoca el fallo. P03, P07 y P08 emplean `SAVEPOINT` y `ROLLBACK TO SAVEPOINT` para deshacer los cambios de prueba antes de `COMMIT`.

Las sentencias siguientes corresponden a las operaciones centrales y consultas de comprobación. Los controles automáticos completos se encuentran en `05_pruebas.sql`. Las inserciones negativas de P04–P06 y la llamada negativa de P09 producirán un error esperado si se ejecutan aisladamente, fuera de sus bloques de manejo de excepciones.

### P01 — Cálculo de créditos obligatorios

**Precondición:** existe la versión 102 con sus seis cursos obligatorios y los créditos de los datos iniciales.

**SQL:**

```sql
SELECT fn_creditos_obligatorios_plan(102);
```

**Resultado esperado:** `22` créditos; los cursos optativos no se incluyen.

**Resultado observado:** `P01 EXITOSA: 22 creditos obligatorios`.

**Conclusión:** la función calculó el total esperado para la versión 102.

### P02 — Clasificación de requisitos

**Precondición:** `UH-BDAT1` pertenece a la versión 102 y tiene un requisito previo y dos correquisitos.

**SQL:**

```sql
SELECT fn_tipo_requisitos_curso('UH-BDAT1', 102);
```

**Resultado esperado:** `Requisitos previos y correquisitos`.

**Resultado observado:** `P02 EXITOSA: Requisitos previos y correquisitos`.

**Conclusión:** la función reconoció correctamente la coexistencia de ambos tipos de requisitos.

### P03 — Inserción válida mediante el procedimiento

**Precondición:** existen el curso `UH-RED1` y la versión 101, pero esa participación todavía no está registrada.

**SQL:**

```sql
BEGIN;
SAVEPOINT prueba_p03;

CALL sp_agregar_curso_plan('UH-RED1', 101, 'Optativo', '4');

SELECT codigo_curso, id_version_plan, tipo_participacion,
       nivel_o_periodo_recomendado
FROM participacion_plan
WHERE codigo_curso = 'UH-RED1' AND id_version_plan = 101;

ROLLBACK TO SAVEPOINT prueba_p03;
COMMIT;
```

**Resultado esperado:** se inserta temporalmente la participación como `Optativo`, con nivel `4`; después de revertir, la participación deja de existir.

**Resultado observado:** `P03 EXITOSA: curso agregado correctamente`. El bloque automático verificó la existencia de la participación optativa antes de revertirla.

**Conclusión:** el procedimiento permitió la inserción válida y la transacción deshizo el cambio de prueba.

### P04 — Rechazo de una participación duplicada

**Precondición:** `UH-PROG1` ya pertenece a la versión 102.

**SQL:**

```sql
INSERT INTO participacion_plan
    (codigo_curso, id_version_plan, tipo_participacion)
VALUES ('UH-PROG1', 102, 'Obligatorio');
```

**Resultado esperado:** rechazo por `unique_violation` de la restricción `pk_participacion_plan`. El bloque comprueba el nombre de la restricción y emite `P04 EXITOSA: duplicado rechazado`.

**Resultado observado:** `P04 EXITOSA: duplicado rechazado`.

**Conclusión:** la clave primaria impidió registrar dos veces el mismo curso en la misma versión.

### P05 — Rechazo de un curso inexistente

**Precondición:** existe la versión 101 y no existe el curso `UH-INEXISTENTE`.

**SQL:**

```sql
INSERT INTO participacion_plan
    (codigo_curso, id_version_plan, tipo_participacion)
VALUES ('UH-INEXISTENTE', 101, 'Optativo');
```

**Resultado esperado:** rechazo por `foreign_key_violation` de `fk_participacion_curso`; aviso del bloque: `P05 EXITOSA: clave foranea rechazada`.

**Resultado observado:** `P05 EXITOSA: clave foranea rechazada`.

**Conclusión:** la clave foránea evitó una participación que apuntara a un curso inexistente.

### P06 — Rechazo de un tipo de participación inválido

**Precondición:** existen `UH-RED1` y la versión 101, y la participación no existe. P03 ya revirtió su inserción.

**SQL:**

```sql
INSERT INTO participacion_plan
    (codigo_curso, id_version_plan, tipo_participacion)
VALUES ('UH-RED1', 101, 'Electivo');
```

**Resultado esperado:** rechazo por `check_violation` de `ck_tipo_participacion`, ya que solo se admiten `Obligatorio` y `Optativo`; aviso del bloque: `P06 EXITOSA: tipo invalido rechazado`.

**Resultado observado:** `P06 EXITOSA: tipo invalido rechazado`.

**Conclusión:** la restricción `CHECK` protegió el dominio del tipo de participación.

### P07 — Inserción válida de un requisito

**Precondición:** existen la versión 201 y los cursos `UH-EST1` y `UH-MAT1`, y la relación indicada no está registrada previamente.

**SQL:**

```sql
BEGIN;
SAVEPOINT prueba_p07;

INSERT INTO requisito_curso
    (id_version_plan, codigo_curso_objetivo,
     codigo_curso_exigido, tipo_requisito)
VALUES (201, 'UH-EST1', 'UH-MAT1', 'Requisito previo');

SELECT *
FROM requisito_curso
WHERE id_version_plan = 201
  AND codigo_curso_objetivo = 'UH-EST1'
  AND codigo_curso_exigido = 'UH-MAT1'
  AND tipo_requisito = 'Requisito previo';

ROLLBACK TO SAVEPOINT prueba_p07;
COMMIT;
```

**Resultado esperado:** inserción y comprobación de una fila; aviso `P07 EXITOSA: requisito insertado`. La relación se elimina al revertir al punto de guardado.

**Resultado observado:** `P07 EXITOSA: requisito insertado`.

**Conclusión:** se aceptó una relación válida conforme a las restricciones implementadas y se revirtió el cambio de prueba.

### P08 — Actualización válida de una participación

**Precondición:** `UH-RED1` figura como `Optativo` en la versión 102.

**SQL:**

```sql
BEGIN;
SAVEPOINT prueba_p08;

UPDATE participacion_plan
SET tipo_participacion = 'Obligatorio'
WHERE codigo_curso = 'UH-RED1' AND id_version_plan = 102;

SELECT tipo_participacion
FROM participacion_plan
WHERE codigo_curso = 'UH-RED1' AND id_version_plan = 102;

ROLLBACK TO SAVEPOINT prueba_p08;
COMMIT;
```

**Resultado esperado:** el tipo cambia temporalmente a `Obligatorio`; aviso `P08 EXITOSA: participacion actualizada`. Después de revertir, permanece como `Optativo`.

**Resultado observado:** `P08 EXITOSA: participacion actualizada`.

**Conclusión:** se permitió la actualización a un valor válido y se conservó el estado inicial mediante la reversión.

### P09 — Rechazo de duplicados desde el procedimiento

**Precondición:** `UH-PROG1` ya pertenece a la versión 102.

**SQL:**

```sql
CALL sp_agregar_curso_plan('UH-PROG1', 102, 'Obligatorio', '1');
```

**Resultado esperado:** el procedimiento lanza la excepción `El curso UH-PROG1 ya pertenece a la version 102`. El bloque comprueba ese mensaje exacto y emite `P09 EXITOSA: procedimiento rechazo duplicado`.

**Resultado observado:** `P09 EXITOSA: procedimiento rechazo duplicado`.

**Conclusión:** la validación del procedimiento rechazó la operación antes de insertar. P04 comprueba la protección de la clave primaria mediante un `INSERT` directo; P09 comprueba la validación explícita de la rutina.

### Salida de ejecución de las pruebas

```text
psql:/tmp/05_pruebas.sql:25: NOTICE:  P01 EXITOSA: 22 creditos obligatorios
DO
psql:/tmp/05_pruebas.sql:51: NOTICE:  P02 EXITOSA: Requisitos previos y correquisitos
DO
BEGIN
SAVEPOINT
DO
ROLLBACK
psql:/tmp/05_pruebas.sql:92: NOTICE:  P03 EXITOSA: curso agregado correctamente
COMMIT
psql:/tmp/05_pruebas.sql:130: NOTICE:  P04 EXITOSA: duplicado rechazado
DO
psql:/tmp/05_pruebas.sql:165: NOTICE:  P05 EXITOSA: clave foranea rechazada
DO
DO
BEGIN
psql:/tmp/05_pruebas.sql:200: NOTICE:  P06 EXITOSA: tipo invalido rechazado
SAVEPOINT
psql:/tmp/05_pruebas.sql:246: NOTICE:  P07 EXITOSA: requisito insertado
DO
ROLLBACK
COMMIT
BEGIN
SAVEPOINT
DO
psql:/tmp/05_pruebas.sql:286: NOTICE:  P08 EXITOSA: participacion actualizada
ROLLBACK
COMMIT
psql:/tmp/05_pruebas.sql:335: NOTICE:  P09 EXITOSA: procedimiento rechazo duplicado
DO
```

**Conclusión:** las nueve pruebas finalizaron correctamente con `ON_ERROR_STOP=1`. Las pruebas negativas capturaron las excepciones esperadas sin interrumpir el conjunto.

## C3 — Comprobación complementaria: cursor frente a STRING_AGG

**Precondiciones:** la función `fn_detalle_requisitos_cursor` está creada; `UH-BDAT1` y `UH-RED1` pertenecen a la versión 102.

**SQL con cursor:**

```sql
SELECT fn_detalle_requisitos_cursor('UH-BDAT1', 102);
SELECT fn_detalle_requisitos_cursor('UH-RED1', 102);
```

Para `UH-BDAT1`, el resultado esperado contiene estas líneas, con los requisitos previos primero y los códigos ordenados dentro de cada tipo:

```text
Requisito previo: Programacion Intermedia (UH-PROG2)
Correquisito: Estadistica Aplicada (UH-EST1)
Correquisito: Matematica Discreta (UH-MAT1)
```

Para `UH-RED1`, el resultado esperado es `Sin requisitos`.

**Consulta equivalente con agregación**, conservando la validación de pertenencia, el orden y el tratamiento del conjunto vacío:

```sql
WITH parametros AS (
    SELECT 'UH-BDAT1'::text AS codigo, 102::integer AS version
)
SELECT CASE
    WHEN NOT EXISTS (
        SELECT 1
        FROM participacion_plan AS p
        WHERE p.codigo_curso = x.codigo
          AND p.id_version_plan = x.version
    ) THEN 'El curso no pertenece al plan'
    ELSE COALESCE((
        SELECT STRING_AGG(
            FORMAT('%s: %s (%s)',
                   r.tipo_requisito, c.nombre, c.codigo_institucional),
            E'\n' ORDER BY
                CASE WHEN r.tipo_requisito = 'Requisito previo'
                     THEN 0 ELSE 1 END,
                c.codigo_institucional
        )
        FROM requisito_curso AS r
        JOIN curso AS c
          ON c.codigo_institucional = r.codigo_curso_exigido
        WHERE r.codigo_curso_objetivo = x.codigo
          AND r.id_version_plan = x.version
    ), 'Sin requisitos')
END AS detalle
FROM parametros AS x;
```

Para comprobar el caso sin requisitos se sustituye `UH-BDAT1` por `UH-RED1` en los parámetros.

**Resultado observado:** se obtuvo `Sin requisitos` para `fn_detalle_requisitos_cursor('UH-RED1', 102)` y se reportó coincidencia entre ambas alternativas para los casos comparados.

**Explicación y conclusión:** el cursor explícito de la función utiliza `OPEN`, `FETCH`, `EXIT WHEN NOT FOUND` y `CLOSE` para recorrer cada fila y construir el texto. Su propósito en el laboratorio es demostrar control procedimental. `STRING_AGG` expresa la concatenación como una operación de agregación y resulta más conciso para este caso. La equivalencia requiere aplicar los mismos filtros, formato, separador y orden, además de tratar la ausencia de filas y la falta de pertenencia al plan. La coincidencia reportada valida los casos comparados; no constituye una medición de rendimiento ni una prueba exhaustiva de todas las entradas.