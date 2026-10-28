
# Laboratorio 03 — Universidad Horizonte

- **Curso:** IC-4301 — Bases de Datos I
- **Grupo:** 03
- **Integrantes:** Santiago Víquez Zamora y Felipe Salazar González

## 1. Proceso implementado

Se seleccionó el subsistema de gestión curricular de Universidad Horizonte, derivado del modelo relacional del Proyecto 1.

El subsistema permite registrar carreras, escuelas, cursos, versiones de planes de estudio, la participación de cursos en cada versión y los requisitos previos o correquisitos establecidos para ellos.

Se implementan seis tablas relacionadas. Quedan fuera del alcance operativo la matrícula de estudiantes, los resultados académicos, los reconocimientos de cursos y la comprobación individual del cumplimiento de requisitos.

## 2. Fragmento del modelo lógico

[Fragmento del modelo lógico](modelo/fragmento-modelo-logico.pdf)

El fragmento seleccionado está compuesto por las siguientes relaciones:

```text
ESCUELA(
    id_escuela PK
)

CARRERA(
    id_carrera PK
)

CURSO(
    codigo_institucional PK,
    nombre,
    cantidad_creditos,
    id_escuela FK
)

VERSION_PLAN_ESTUDIOS(
    id_version_plan PK,
    vigencia,
    id_carrera FK
)

PARTICIPACION_PLAN(
    codigo_curso PK/FK,
    id_version_plan PK/FK,
    tipo_participacion,
    nivel_o_periodo_recomendado
)

REQUISITO_CURSO(
    id_version_plan PK/FK,
    codigo_curso_objetivo PK/FK,
    codigo_curso_exigido PK/FK,
    tipo_requisito PK
)
```

Las asociaciones conservadas son:

- Una escuela administra múltiples cursos; cada curso pertenece a una escuela.
- Una carrera puede tener múltiples versiones de plan; cada versión pertenece a una carrera.
- Un curso puede participar en múltiples versiones y una versión puede contener múltiples cursos. Esta asociación se materializa mediante `participacion_plan`.
- Los requisitos y correquisitos se definen para una versión del plan y relacionan un curso objetivo con un curso exigido.

## 3. Matriz de trazabilidad

| Relación lógica | Tabla física | Clave primaria | Claves foráneas | Restricciones relevantes | Justificación de cambios |
|---|---|---|---|---|---|
| ESCUELA | `escuela` | `id_escuela` | — | Identificador obligatorio y único | Se representa el identificador provisional como `INTEGER`. |
| CARRERA | `carrera` | `id_carrera` | — | Identificador obligatorio y único | Se representa el identificador provisional como `INTEGER`. |
| CURSO | `curso` | `codigo_institucional` | `id_escuela` → `escuela` | Nombre, créditos y escuela obligatorios | Se utilizan `TEXT` para código y nombre e `INTEGER` para créditos. |
| VERSION_PLAN_ESTUDIOS | `version_plan_estudios` | `id_version_plan` | `id_carrera` → `carrera` | Vigencia y carrera obligatorias | La vigencia se conserva provisionalmente como `TEXT`. |
| PARTICIPACION_PLAN | `participacion_plan` | (`codigo_curso`, `id_version_plan`) | `codigo_curso` → `curso`; `id_version_plan` → `version_plan_estudios` | Tipo obligatorio; valores `Obligatorio` y `Optativo` | La clave compuesta conserva una participación por curso y versión. La ubicación recomendada se representa mediante `TEXT` nullable. |
| REQUISITO_CURSO | `requisito_curso` | (`id_version_plan`, `codigo_curso_objetivo`, `codigo_curso_exigido`, `tipo_requisito`) | `id_version_plan` → `version_plan_estudios`; ambos códigos → `curso` | Tipo obligatorio; valores `Requisito previo` y `Correquisito` | Se conservan los roles diferenciados de curso objetivo y curso exigido, así como la clave compuesta del modelo relacional. |

## 4. Decisiones de diseño físico

Se utilizaron identificadores `INTEGER` para las entidades cuyos identificadores internos quedaron provisionales en el Proyecto 1. Los códigos institucionales de cursos se representan mediante `TEXT`, ya que contienen caracteres alfanuméricos.

Se utilizan claves primarias y foráneas para garantizar identidad e integridad referencial. Los atributos definidos como obligatorios se implementan mediante `NOT NULL`, y los dominios cerrados mediante `CHECK`.

La clave primaria de `participacion_plan` permite distinguir un mismo curso en diferentes versiones. La clave primaria de `requisito_curso` permite registrar múltiples cursos exigidos, diferenciando requisitos previos y correquisitos.

Las siguientes decisiones son provisionales:

- **Vigencia:** `TEXT NOT NULL`, porque el Proyecto 1 no establece una representación temporal concreta. No se verifica automáticamente la validez de los periodos.
- **Nivel o periodo recomendado:** `TEXT` nullable, porque el Proyecto 1 mantiene sin resolver su formato y obligatoriedad.
- **Cantidad de créditos:** `INTEGER NOT NULL`, interpretando la cantidad como un valor entero. El modelo original no establece un rango numérico ni precisa el tratamiento de créditos fraccionarios.

No se añadieron índices independientes de los creados por las claves primarias, restricciones `UNIQUE` adicionales, valores predeterminados ni eliminación en cascada, al no existir una necesidad documentada para ellos.

## 5. Datos de prueba

`02_datos.sql` incorpora información ficticia distribuida de la siguiente manera:

| Tabla | Registros |
|---|---:|
| `escuela` | 2 |
| `carrera` | 2 |
| `curso` | 8 |
| `version_plan_estudios` | 3 |
| `participacion_plan` | 16 |
| `requisito_curso` | 10 |
| **Total** | **41** |

Los datos permiten observar distintas versiones de una carrera, participación de un mismo curso en varios planes, variación de obligatoriedad y múltiples requisitos asociados a un curso.

Estos escenarios cubren las situaciones EV-02 y EV-03 documentadas en el análisis del Proyecto 1.

## 6. Consultas de negocio

El archivo `03_consultas.sql` contiene tres consultas:

| ID | Pregunta de negocio | Resultado esperado |
|---|---|---|
| Q01 | ¿Qué cursos componen la versión 102 del plan? | Siete cursos: seis obligatorios y uno optativo. |
| Q02 | ¿Qué requisitos tiene UH-BDAT1 en la versión 102? | Un requisito previo y dos correquisitos. |
| Q03 | ¿Cuántos cursos obligatorios y optativos tiene cada versión? | Versión 101: 5 y 1; versión 102: 6 y 1; versión 201: 2 y 1. |

Las consultas utilizan relaciones entre tablas y agregación mediante `COUNT` y `GROUP BY`.

Los resultados observados están registrados en [evidencias/resultados.md](evidencias/resultados.md).

## 7. Programación almacenada

El archivo `04_rutinas.sql` implementa programación almacenada mediante PL/pgSQL, utilizando las tablas del subsistema de gestión curricular de Universidad Horizonte.

### C1 — Funciones almacenadas

**Función 1: `fn_creditos_obligatorios_plan`**

- **Parámetro:** `p_id_version INTEGER`.
- **Retorno:** `INTEGER`.
- **Propósito:** calcular la suma de créditos de los cursos obligatorios de una versión del plan de estudios.
- **Funcionamiento:** consulta las tablas `participacion_plan` y `curso`, aplica el filtro de participación obligatoria y utiliza `SUM` para calcular el total. Emplea `COALESCE` para devolver cero cuando no hay cursos obligatorios.

Ejemplo:

`SELECT fn_creditos_obligatorios_plan(102);`

**Resultado esperado y observado:** 22 créditos.

**Función 2: `fn_tipo_requisitos_curso`**

- **Parámetros:** `p_codigo_curso TEXT`, `p_id_version INTEGER`.
- **Retorno:** `TEXT`.
- **Propósito:** identificar los tipos de requisitos asociados a un curso en una versión específica.
- **Funcionamiento:** valida la pertenencia del curso al plan, cuenta los requisitos previos y correquisitos, y utiliza estructuras `IF`, `ELSIF` y `ELSE` para clasificar el resultado.

Puede devolver: `Requisitos previos y correquisitos`, `Solo requisitos previos`, `Solo correquisitos`, `Sin requisitos` o `El curso no pertenece al plan`.

Ejemplo:

`SELECT fn_tipo_requisitos_curso('UH-BDAT1', 102);`

**Resultado esperado y observado:** `Requisitos previos y correquisitos`.

### C2 — Procedimiento almacenado

**Procedimiento: `sp_agregar_curso_plan`**

Permite incorporar un curso existente a una versión del plan de estudios.

**Parámetros:**

- `p_codigo_curso TEXT`
- `p_id_version INTEGER`
- `p_tipo_participacion TEXT`
- `p_nivel TEXT`

Antes de insertar, el procedimiento verifica que el curso exista, que la versión exista, que el tipo de participación sea `Obligatorio` u `Optativo` y que el curso no esté registrado previamente en esa versión.

Cuando una condición no se cumple, utiliza `RAISE EXCEPTION` para rechazar la operación y mostrar un mensaje descriptivo.

**Ejemplo de operación válida:**

`CALL sp_agregar_curso_plan('UH-RED1', 101, 'Optativo', '4');`

La inserción fue aceptada durante la prueba P03 y posteriormente revertida para conservar los datos originales.

**Ejemplo de operación inválida:**

`CALL sp_agregar_curso_plan('UH-PROG1', 102, 'Obligatorio', '1');`

La operación fue rechazada porque el curso ya pertenecía a la versión 102.

### C3 — Técnica procedimental adicional: cursor explícito

**Función: `fn_detalle_requisitos_cursor`**

- **Parámetros:** `p_codigo_curso TEXT`, `p_id_version INTEGER`.
- **Retorno:** `TEXT`.
- **Propósito:** construir un resumen descriptivo de los requisitos asociados a un curso.

La implementación utiliza un cursor explícito para recorrer individualmente los registros obtenidos de `requisito_curso`.

Se emplean las instrucciones `OPEN`, `FETCH`, `EXIT WHEN NOT FOUND` y `CLOSE`, junto con un ciclo `LOOP`.

Ejemplo:

`SELECT fn_detalle_requisitos_cursor('UH-BDAT1', 102);`

El resultado incluye un requisito previo y dos correquisitos.

También se comprobó el caso:

`SELECT fn_detalle_requisitos_cursor('UH-RED1', 102);`

**Resultado observado:** `Sin requisitos`.

**Comparación con una alternativa basada en conjuntos**

La misma concatenación puede realizarse mediante `STRING_AGG`, una función de agregación de PostgreSQL que combina los valores de múltiples filas.

El cursor permite demostrar el procesamiento secuencial mediante PL/pgSQL. Sin embargo, para generar un resumen textual sin lógica adicional por registro, `STRING_AGG` resulta más conciso y evita recorrer explícitamente los registros desde el código procedimental.

Se compararon ambas alternativas utilizando los mismos filtros y el mismo orden. Los resultados observados coincidieron.

La consulta equivalente y las evidencias se documentan en [evidencias/resultados.md](evidencias/resultados.md).

## 8. Instrucciones de ejecución

### Requisitos

- Docker.
- Imagen `postgres:17`.
- Terminal PowerShell desde la raíz del repositorio.

### Preparación inicial

Crear una instancia local de PostgreSQL:

```powershell
docker run -d `
  --name bd1-lab03 `
  -e POSTGRES_USER=bd1 `
  -e POSTGRES_PASSWORD=bd1 `
  -e POSTGRES_DB=lab03_grupo03 `
  -v bd1_lab03_data:/var/lib/postgresql/data `
  postgres:17
```

Si el contenedor ya existe y está detenido, puede iniciarse mediante:

```powershell
docker start bd1-lab03
```

### Ejecutar los scripts

Desde la raíz del repositorio:

```powershell
docker cp .\lab03\grupo-03\sql bd1-lab03:/tmp/lab03_sql
```

Ejecutar en este orden:

```powershell
docker exec bd1-lab03 psql -X -v ON_ERROR_STOP=1 -U bd1 -d lab03_grupo03 -f /tmp/lab03_sql/01_esquema.sql

docker exec bd1-lab03 psql -X -v ON_ERROR_STOP=1 -U bd1 -d lab03_grupo03 -f /tmp/lab03_sql/02_datos.sql

docker exec bd1-lab03 psql -X -v ON_ERROR_STOP=1 -U bd1 -d lab03_grupo03 -f /tmp/lab03_sql/04_rutinas.sql

docker exec bd1-lab03 psql -X -v ON_ERROR_STOP=1 -U bd1 -d lab03_grupo03 -f /tmp/lab03_sql/03_consultas.sql

docker exec bd1-lab03 psql -X -v ON_ERROR_STOP=0 -U bd1 -d lab03_grupo03 -f /tmp/lab03_sql/05_pruebas.sql
```

La ejecución completa requiere que los cinco scripts estén implementados.

Los scripts de creación y carga están diseñados para ejecutarse una vez sobre una base vacía. Para repetir íntegramente el proceso debe utilizarse una nueva base de datos de laboratorio; no deben ejecutarse sobre una base que ya contenga las mismas tablas y registros.

### Reproducibilidad verificada

Se realizaron dos verificaciones complementarias.

**Verificación inicial:** se ejecutaron los scripts `01_esquema.sql`, `02_datos.sql` y `03_consultas.sql` sobre PostgreSQL 17.11, utilizando una base independiente y el usuario `ci_runner`, sin privilegios de superusuario.

**Verificación integral local:** posteriormente, Felipe ejecutó los cinco scripts sobre una base de datos nueva llamada `lab03_revision`, utilizando PostgreSQL 17 en Docker.

El orden de ejecución fue:

1. `01_esquema.sql`
2. `02_datos.sql`
3. `04_rutinas.sql`
4. `03_consultas.sql`
5. `05_pruebas.sql`

Se verificó la creación de seis tablas, la carga de 41 registros, la creación de tres funciones y un procedimiento almacenado, la ejecución de las tres consultas de negocio y el resultado satisfactorio de las nueve pruebas.

**Conclusión:** se confirmó que los cinco archivos funcionan conjuntamente desde una base de datos vacía en el entorno local. Esta verificación no sustituye la ejecución posterior de la integración continua de GitHub.

## 9. Limitaciones

Este subsistema registra los requisitos y correquisitos de cada versión del plan, pero no determina si un estudiante concreto puede matricular un curso.

Las reglas RN-06 y RN-18 requieren información de solicitudes de matrícula, resultados académicos y reconocimientos que no pertenece al fragmento seleccionado.

Asimismo, las representaciones físicas provisionales de `vigencia` y `nivel_o_periodo_recomendado` no permiten validar todas las propiedades temporales o académicas que podrían definirse posteriormente.

## 10. Evidencias

Los resultados de ejecución se documentan en [evidencias/resultados.md](evidencias/resultados.md).

El documento incluye las evidencias de creación del esquema, carga de datos, consultas de negocio, programación almacenada y pruebas de integridad.

Se implementaron nueve pruebas:

| ID | Descripción | Resultado |
|---|---|---|
| P01 | Cálculo de créditos obligatorios | Exitosa |
| P02 | Clasificación de requisitos | Exitosa |
| P03 | Inserción válida mediante procedimiento | Exitosa |
| P04 | Rechazo de participación duplicada | Exitosa |
| P05 | Rechazo de clave foránea inexistente | Exitosa |
| P06 | Rechazo de participación inválida | Exitosa |
| P07 | Inserción válida de requisito | Exitosa |
| P08 | Actualización válida de participación | Exitosa |
| P09 | Rechazo de duplicado mediante procedimiento | Exitosa |

Las pruebas P03, P07 y P08 utilizan transacciones y puntos de guardado para revertir los cambios realizados durante su ejecución.

Las pruebas negativas capturan las excepciones esperadas y comprueban que el rechazo corresponda a la condición evaluada.

Las nueve pruebas fueron ejecutadas satisfactoriamente en el entorno local. Las precondiciones, sentencias, resultados esperados, resultados observados y conclusiones individuales se encuentran documentados en el archivo de evidencias.

## 11. Defensa individual

- **Santiago Víquez Zamora:** [Ver defensa individual](https://drive.google.com/file/d/1ZXX2p5Z0LmnglYslldHL0ezKTbHWrGOK/view?usp=sharing).
- **Felipe Salazar González:** (https://youtu.be/7n18GuYsApE)