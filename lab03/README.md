# IC-4301 · Bases de Datos I
## Laboratorio 3 — Del modelo lógico a la implementación física

**Tecnológico de Costa Rica · Escuela de Computación · II semestre 2026**  
**Modalidad:** trabajo por equipos, utilizando el caso de negocio asignado en el Proyecto 1.  
**Motor requerido:** PostgreSQL.  
**Entrega:** repositorio con scripts SQL, documentación técnica y evidencia de pruebas.  
**Fecha y medio de entrega:** los indicados por el profesor en la plataforma del curso.

---

## 1. Situación de partida

Durante el Proyecto 1 cada equipo analizó un caso de negocio, documentó requisitos y reglas, construyó un modelo conceptual y derivó un modelo lógico relacional. En este laboratorio dejarán de trabajar únicamente sobre diagramas: deberán **materializar una parte coherente de ese diseño** en PostgreSQL, cargar datos, verificar restricciones e implementar operaciones mediante programación almacenada.

**No se entregará un esquema común resuelto.** Cada equipo es responsable de seleccionar, justificar y construir su propia implementación a partir de los productos de su Proyecto 1. No se evalúa la cantidad de tablas creadas, sino la fidelidad al modelo y la capacidad de explicar y probar las decisiones.

## 2. Resultados de aprendizaje

Al finalizar, el equipo deberá ser capaz de:

1. Transformar un subconjunto consistente del modelo lógico en objetos físicos de PostgreSQL.
2. Elegir y justificar tipos de datos, claves, nulabilidad y restricciones de integridad.
3. Construir scripts reproducibles de creación y carga inicial.
4. Probar casos válidos e inválidos y analizar los resultados.
5. Implementar funciones y procedimientos en PL/pgSQL vinculados con reglas u operaciones reales del caso.
6. Explicar divergencias entre el modelo lógico y el esquema implementado, sin cambiar silenciosamente las reglas del negocio.

## 3. Alcance y selección del subsistema

A partir del modelo relacional del Proyecto 1, escojan **un proceso de negocio completo y acotado**, no tablas aisladas sin relación. Como referencia de tamaño, se esperan aproximadamente **4 a 6 tablas vinculadas**; se permiten más o menos si el equipo justifica que el proceso elegido requiere otra cantidad. La complejidad y cobertura de relaciones importa más que el conteo.

El subsistema seleccionado debe permitir:

- Identificar al menos una entidad principal y sus asociaciones relevantes.
- Implementar al menos una relación de tipo uno-a-muchos; si el caso seleccionado incluye una relación muchos-a-muchos, materializarla mediante la tabla correspondiente. **No inventen asociaciones para cumplir un requisito formal.**
- Representar restricciones verificables mediante mecanismos nativos de PostgreSQL.
- Realizar al menos una operación de negocio que involucre más de una tabla.

Entreguen una breve explicación del límite elegido: qué proceso implementan, qué entidades forman parte y qué queda fuera. Si una regla depende de una entidad externa al subconjunto, expliquen cómo la manejarán: incluir esa entidad mínima, ampliar el alcance o documentar explícitamente la limitación. No eliminen claves foráneas para hacer funcionar el ejercicio.

## 4. Actividades

### Parte A — Del modelo lógico al esquema físico (25 puntos)

**A1. Trazabilidad (7 puntos).** Presenten el fragmento del modelo lógico utilizado y una matriz breve con las columnas: relación lógica, tabla física, clave primaria, claves foráneas, restricciones relevantes y justificación de cambios. El diseño físico debe corresponder con los identificadores, cardinalidades y reglas ya definidos, salvo correcciones justificadas.

**A2. Scripts de definición (13 puntos).** Construyan `01_esquema.sql` con instrucciones `CREATE TABLE`, tipos de datos adecuados, `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK` y `DEFAULT` cuando correspondan a reglas reales. Agreguen `CREATE INDEX` solo cuando exista una razón técnica distinta de los índices generados por las claves; expliquen el propósito de cada índice adicional. Utilicen nombres consistentes para tablas, columnas y restricciones.

**A3. Reproducibilidad (5 puntos).** El script debe poder ejecutarse en una base de datos PostgreSQL vacía, respetar dependencias entre objetos y terminar sin errores. Documenten la versión de PostgreSQL utilizada y las instrucciones para preparar el entorno. No dependan de objetos creados manualmente en DBeaver.

### Parte B — Datos, consultas e integridad (20 puntos)

**B1. Datos representativos (7 puntos).** Elaboren `02_datos.sql` con datos ficticios coherentes que cubran los escenarios esenciales del proceso elegido. No utilicen datos personales reales. Deben existir suficientes registros para observar relaciones y resultados distintos; documenten por qué el conjunto de datos es suficiente.

**B2. Consultas (6 puntos).** Elaboren `03_consultas.sql` con **al menos tres consultas útiles para el negocio**, entre ellas una que combine dos o más tablas y otra que utilice agregación (`GROUP BY`, `HAVING` o una función agregada, según corresponda). Incluyan la pregunta de negocio que responde cada consulta y el resultado esperado para sus datos de prueba.

**B3. Pruebas de integridad (7 puntos).** Elaboren `05_pruebas.sql` con **al menos seis pruebas identificadas**, incluidas **tres que deben funcionar y tres que deben fallar o ser rechazadas** por una regla concreta. Cubran, según el modelo, unicidad, referencias, obligatoriedad, rangos o estados permitidos. Para cada prueba documenten: precondición, sentencia ejecutada, resultado esperado, resultado observado y conclusión. Las pruebas inválidas deben ejecutarse sin impedir que continúe el resto del conjunto (por ejemplo, usando transacciones y puntos de recuperación, o ejecutándolas individualmente). No basta con capturas de mensajes de error.

### Parte C — Programación almacenada (25 puntos)

Elaboren `04_rutinas.sql`. Las rutinas deben corresponder a acciones o consultas justificadas por el caso de negocio; **no se aceptan funciones triviales creadas solo para cumplir la cantidad**.

**C1. Funciones (8 puntos).** Implementen **dos funciones** en PL/pgSQL: una que reciba parámetros y retorne un valor calculado o una respuesta de consulta útil; otra que incluya una decisión de negocio (`IF`, `CASE` u otra estructura justificada). Documenten parámetros, retorno, reglas y ejemplos de ejecución.

**C2. Procedimiento almacenado (10 puntos).** Implementen **un procedimiento** que ejecute una operación de negocio con inserción o actualización en una o más tablas. Debe validar al menos una condición antes de modificar información, y comunicar claramente por qué se rechaza una operación inválida (por ejemplo, mediante `RAISE EXCEPTION`). Prueben el caso exitoso y el rechazado. Las restricciones declarativas deben permanecer en el esquema: el procedimiento **no las reemplaza**.

**C3. Técnica procedimental adicional (7 puntos).** Incorporen una técnica del temario de semana 12 en una rutina o demostración acotada: **cursor explícito, tabla temporal o SQL dinámico**. Justifiquen su elección y expliquen por qué su solución resulta apropiada. No usen SQL dinámico para consultas de estructura fija; si utilizan identificadores variables, protéjanlos correctamente. Si la técnica es meramente didáctica y existe una solución más sencilla con SQL basado en conjuntos, deben mostrar y discutir esa alternativa.

### Parte D — Documentación y defensa técnica (30 puntos)

**D1. Informe (6 puntos).** Incluyan en `README.md`: descripción del proceso implementado, fragmento de modelo lógico, matriz de trazabilidad, instrucciones de ejecución, decisiones de diseño físico, justificación de las rutinas, limitaciones y enlace a evidencias.

**D2. Evidencia de ejecución (4 puntos).** Incluyan resultados verificables de consultas, pruebas de integridad y llamadas a las rutinas. Las evidencias deben estar asociadas con un ID de prueba o consulta, no presentarse como capturas sin explicación.

**D3. Defensa individual mediante video (20 puntos).**

Cada integrante del equipo deberá entregar un video individual de **máximo 5 minutos**, en el que explique una parte del diseño e implementación de la base de datos, ejecute al menos una prueba funcional y justifique una decisión técnica tomada durante el desarrollo del laboratorio.

**Condiciones de la grabación:**

- La cámara deberá permanecer encendida durante toda la grabación, permitiendo identificar al estudiante.
- El video deberá realizarse en una sola toma continua, **sin cortes, pausas, ediciones ni montajes**.
- El estudiante deberá compartir su pantalla para mostrar el código SQL, la ejecución de las pruebas y sus resultados, manteniendo visible su cámara.
- La explicación deberá realizarse con sus propias palabras, demostrando comprensión de lo implementado.
- No se aceptarán videos que consistan únicamente en leer el código o el documento entregado.

**Evaluación:** La calificación será individual y considerará la claridad de la explicación, el dominio técnico, la ejecución de la prueba y la capacidad para justificar las decisiones tomadas. La presentación del video sustituye la defensa presencial del laboratorio.

## 5. Entregables y estructura

```text
grupo-XX/
├── README.md                         # obligatorio
├── modelo/                           # sugerido
│   └── fragmento-modelo-logico.pdf   # o imagen legible
├── sql/                              # obligatorio
│   ├── 01_esquema.sql                # obligatorio
│   ├── 02_datos.sql                  # obligatorio
│   ├── 03_consultas.sql              # obligatorio
│   ├── 04_rutinas.sql                # obligatorio
│   └── 05_pruebas.sql                # obligatorio
└── evidencias/                       # sugerido
    └── resultados.md                 # o PDF con pruebas identificadas
```

`README.md` y los cinco scripts dentro de `sql/` son **obligatorios**: deben existir con exactamente esos nombres y rutas, pues la validación automática del Pull Request (ver abajo) rechaza la entrega si falta alguno. Las carpetas `modelo/` y `evidencias/` son una organización **sugerida** para el fragmento del modelo lógico y la evidencia de ejecución; el CI no exige esos nombres, solo que cualquier archivo entregado use una extensión permitida.

**Orden de ejecución:** `01_esquema.sql` → `02_datos.sql` → `04_rutinas.sql` → `03_consultas.sql` → `05_pruebas.sql`.

Los scripts deberán ejecutarse de forma reproducible en un entorno limpio. Documenten explícitamente si para repetirlos es necesario recrear una base de datos de laboratorio. Eviten comandos de eliminación destructiva sin explicación.

### Validación automática del Pull Request

La entrega se realiza mediante un **Pull Request hacia `main`**. Un flujo de GitHub Actions valida automáticamente la estructura antes de aceptar la entrega. Tengan en cuenta:

- **Un Pull Request debe contener cambios de un solo grupo.** No mezclen archivos de `lab03/<grupo>/` de distintos equipos en el mismo PR.
- **Rutas obligatorias:** todo cambio debe vivir bajo `lab03/<grupo>/`. Como mínimo deben existir:
  - `lab03/<grupo>/README.md`
  - `lab03/<grupo>/sql/01_esquema.sql`
  - `lab03/<grupo>/sql/02_datos.sql`
  - `lab03/<grupo>/sql/03_consultas.sql`
  - `lab03/<grupo>/sql/04_rutinas.sql`
  - `lab03/<grupo>/sql/05_pruebas.sql`
- **Extensiones permitidas:** `.md`, `.sql`, `.pdf`, `.png`, `.jpg`, `.jpeg`. Cualquier otro tipo de archivo (por ejemplo `.docx`, `.xlsx`, `.zip`) es rechazado.
- **Tamaño máximo por archivo:** 1 MiB para `.md`/`.sql`, 10 MiB para `.pdf`, 5 MiB para imágenes (`.png`/`.jpg`/`.jpeg`).
- **No se aceptan archivos vacíos.**
- Los archivos `.md` y `.sql` deben guardarse como texto UTF-8 válido, sin datos binarios.
- Los `.pdf` y las imágenes deben tener una firma de archivo válida (no basta con cambiar la extensión).

Si el Pull Request no cumple alguna de estas condiciones, la entrega será **rechazada automáticamente** y deberán corregirla antes de volver a solicitar revisión.

## 6. Rúbrica (100 puntos)

| Criterio | Puntos |
|---|---:|
| A1. Trazabilidad entre modelo y esquema | 7 |
| A2. Tablas, tipos, claves y restricciones | 13 |
| A3. Reproducibilidad | 5 |
| B1. Datos de prueba representativos | 7 |
| B2. Consultas de negocio | 6 |
| B3. Pruebas de integridad | 7 |
| C1. Dos funciones justificadas | 8 |
| C2. Procedimiento con validación | 10 |
| C3. Técnica procedimental adicional | 7 |
| D1. Documentación y decisiones | 6 |
| D2. Evidencias | 4 |
| D3. Defensa técnica | 20 |
| **Total** | **100** |

## 7. Criterios de evaluación importantes

- Una implementación que ejecuta sin errores **no demuestra por sí sola** que el diseño represente bien el negocio.
- No se penalizará una corrección razonada del Proyecto 1; sí se penalizarán cambios no documentados que alteren requisitos o cardinalidades.
- Las reglas que pueden expresarse mediante `CHECK`, `UNIQUE`, claves o referencias deben preferir esos mecanismos frente a código procedural innecesario.
- Las funciones y procedimientos deben tener propósito verificable y pruebas reproducibles.
- No se exige interfaz gráfica, API, despliegue a la nube ni implementación completa de todos los procesos del proyecto.
- **Los triggers no son obligatorios en este laboratorio**: corresponden al siguiente bloque práctico. Pueden mencionarse como solución futura, pero no sustituyen los requisitos actuales.
- Si se utilizaron herramientas de inteligencia artificial, el grupo debe revisar y comprender todo el código entregado; durante la defensa podrá pedirse explicar o adaptar cualquier fragmento.

## 8. Comprobación final antes de entregar

- [ ] El subconjunto escogido representa un proceso de negocio reconocible.
- [ ] El esquema SQL conserva las relaciones y restricciones del diseño aprobado o documenta sus correcciones.
- [ ] Los scripts funcionan en el orden indicado sobre una base vacía.
- [ ] Las consultas responden preguntas concretas del caso.
- [ ] Las pruebas demuestran tanto operaciones válidas como rechazos previstos.
- [ ] Las funciones y el procedimiento se pueden ejecutar y están documentados.
- [ ] Cada integrante puede defender las decisiones técnicas.

---

**Propósito central:** demostrar que pasar del modelo lógico al físico significa preservar hechos, asociaciones y reglas del negocio en un SGBD real, no simplemente dibujar tablas y traducirlas a `CREATE TABLE`.
