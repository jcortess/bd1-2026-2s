# Interacciones con inteligencia artificial — Universidad Horizonte

## Modelo: GPT-6

## Interacción 01 — Configuración reproducible del entorno PostgreSQL

### Prompt

Para el Proyecto Final del curso IC-4301 Bases de Datos I, Grupo 03 — Universidad Horizonte, define una configuración correcta y reproducible del entorno PostgreSQL.

Utiliza como fuentes la consigna general del Proyecto Final, el anexo del Grupo 03, los materiales del curso y la estructura existente en la rama `grupo-03-proyecto-final` del repositorio `jcortess/bd1-2026-2s`.

El entorno debe cumplir las siguientes condiciones:

1. Utilizar PostgreSQL 17, manteniendo compatibilidad con el motor empleado en Lab03.
2. Permitir que cada integrante reproduzca su propia instancia mediante Docker Compose, sin depender de rutas absolutas, credenciales personales ni configuraciones específicas del equipo de desarrollo.
3. Mantener los datos PostgreSQL en almacenamiento persistente y permitir acceder a los scripts del repositorio sin modificar los archivos anfitriones.
4. Permitir crear una base de trabajo nueva e independiente de la base administrativa.
5. Admitir conexiones simultáneas para las posteriores pruebas de transacciones y concurrencia.
6. Documentar en `README.md` los requisitos y comandos necesarios para iniciar el entorno, crear una base limpia, conectarse y detener los servicios.

Entrega la configuración propuesta para `compose.yaml`, su justificación técnica y el contenido correspondiente del README.

No implementes todavía tablas, rutinas ni procesos del negocio. No introduzcas servicios adicionales, aplicaciones auxiliares ni automatizaciones que no sean necesarias para reproducir el proyecto. No modifiques directamente el repositorio; la incorporación y validación se realizarán por separado.

### Respuesta

# Configuración del entorno — Universidad Horizonte

**Motor:** PostgreSQL 17.11
**Imagen:** `postgres:17.11-bookworm`
**Orquestación:** Docker Compose
**Alcance:** infraestructura de desarrollo y ejecución local reproducible.

### 1. Decisiones de configuración

Se propone un único servicio PostgreSQL administrado mediante Docker Compose.

La imagen `postgres:17.11-bookworm` fija una versión concreta del motor, evitando que distintas ejecuciones dependan de actualizaciones implícitas de la etiqueta de la imagen.

El servicio utiliza:

- Un volumen Docker con nombre para conservar los archivos de datos de PostgreSQL.
- Un montaje relativo de `./` hacia `/workspace`, en modo de solo lectura, para acceder posteriormente a los scripts SQL.
- Una comprobación de disponibilidad mediante `pg_isready`.
- Una base administrativa inicial `postgres`, separada de las bases destinadas a ejecutar el proyecto.
- Conexiones mediante `docker compose exec`, sin publicar puertos del contenedor en el equipo anfitrión.

Se evita ejecutar automáticamente los scripts de instalación desde el mecanismo de inicialización de la imagen PostgreSQL. Dicho mecanismo depende de la inicialización del directorio de datos y no garantiza que los scripts vuelvan a ejecutarse al reutilizar un volumen existente. La creación y carga de cada base del proyecto se realizará explícitamente y en el orden documentado.

### 2. Archivo `compose.yaml`

Ubicación: `final-project/grupo-03/compose.yaml`.

```yaml
name: bd1-g03-final

services:
  db:
    image: postgres:17.11-bookworm

    environment:
      POSTGRES_USER: bd1
      POSTGRES_PASSWORD: bd1_local
      POSTGRES_DB: postgres

    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./:/workspace:ro

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 3s
      timeout: 3s
      retries: 20

volumes:
  postgres_data:
```

La contraseña `bd1_local` corresponde exclusivamente al entorno local de desarrollo. La configuración no está destinada a exponerse como servicio PostgreSQL público ni a utilizarse en producción.

### 3. Documentación para `README.md`

Se incorpora al README el procedimiento de reproducción del entorno.

**Requisitos:** Docker Engine o Docker Desktop con soporte para contenedores Linux y Docker Compose V2.

Los comandos se ejecutan desde `final-project/grupo-03/`.

**Iniciar y comprobar el servicio:**

```powershell
docker compose config -q
docker compose up -d --wait
docker compose ps
```

**Comprobar PostgreSQL:**

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d postgres -c "SELECT current_database(), current_user, version();"
```

**Crear una base de trabajo limpia:**

```powershell
docker compose exec -T db createdb -U bd1 -T template0 universidad_horizonte_prueba_01
```

La base se crea a partir de `template0` para disponer de una base nueva, independiente de la base administrativa. La instalación completa del proyecto deberá realizarse posteriormente mediante los scripts SQL entregables.

**Comprobar que la base está vacía:**

```powershell
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U bd1 -d universidad_horizonte_prueba_01 -c "SELECT current_database(); SELECT COUNT(*) AS tablas_usuario FROM pg_tables WHERE schemaname = 'public';"
```

**Abrir sesiones PostgreSQL independientes:**

```powershell
docker compose exec db psql -X -U bd1 -d universidad_horizonte_prueba_01
```

Cada terminal establece una conexión independiente. Sus identificadores pueden comprobarse mediante:

```sql
SELECT pg_backend_pid();
```

Para salir de `psql` se utiliza `\q`.

**Detener el servicio:**

```powershell
docker compose down
```

El comando conserva el volumen persistente. No debe utilizarse `docker compose down -v` como operación ordinaria de detención, porque elimina los volúmenes asociados al proyecto.

Las instrucciones de ejecución de los scripts SQL se incorporarán cuando estos hayan sido implementados y validados.

### Verificación posterior

La configuración propuesta se incorporó manualmente a `compose.yaml` y las instrucciones de reproducción a `README.md`, tras la revisión de las decisiones técnicas.

Las comprobaciones locales realizadas produjeron los siguientes resultados:

| Comprobación                                  | Resultado observado            |
| --------------------------------------------- | ------------------------------ |
| `docker compose config -q`                    | Código de salida `0`           |
| Imagen configurada                            | `postgres:17.11-bookworm`      |
| Inicio con `docker compose up -d --wait`      | Contenedor en estado `healthy` |
| Versión del servidor                          | PostgreSQL `17.11`             |
| Montaje `/workspace`                          | `RW = false`                   |
| Montaje `/var/lib/postgresql/data`            | `RW = true`                    |
| Creación de `universidad_horizonte_prueba_01` | Código de salida `0`           |
| Tablas de usuario iniciales en `public`       | `0`                            |
| Sesiones PostgreSQL simultáneas               | PID `1421` y PID `1592`        |
| `git diff --check`                            | Sin advertencias               |

Las pruebas confirman el funcionamiento de la configuración en el entorno local utilizado. La reproducción independiente en otro equipo y la ejecución del modelo físico completo quedan fuera de estas comprobaciones.

**Resultado incorporado:** `compose.yaml` y la sección de entorno de `README.md`, con decisiones de configuración revisadas y verificaciones locales satisfactorias.


## Interacción 02 — Especificación física del modelo relacional

### Prompt

Para el Proyecto Final del curso IC-4301 Bases de Datos I, Grupo 03 — Universidad Horizonte, desarrolla la especificación física completa del modelo relacional consolidado, como primera intervención.

**Fuentes obligatorias:** la consigna general del proyecto, el anexo del Grupo 03, los seis documentos corregidos del Proyecto 1, `Control_de_Cambios.md`, los componentes pertinentes de Lab03 y el estado actual de la rama `grupo-03-proyecto-final` del repositorio `jcortess/bd1-2026-2s`.

Realiza el trabajo bajo estas condiciones:

1. Examina íntegramente las 26 relaciones y los 135 atributos del modelo corregido. Para cada atributo, determina el tipo PostgreSQL apropiado, su obligatoriedad, participación en claves y restricciones aplicables. Conserva los identificadores, nombres y decisiones ya consolidados, salvo que detectes y justifiques una incompatibilidad real.
2. Especifica las claves primarias, foráneas, candidatas, restricciones UNIQUE, CHECK y demás mecanismos declarativos necesarios. No introduzcas longitudes, límites, catálogos cerrados, relaciones ni reglas de negocio sin fundamento.
3. Examina las 20 reglas RN-01–RN-20 y las condiciones adicionales exigidas por el anexo G03. Clasifica cada garantía según pueda resolverse declarativamente, requiera un mecanismo de integridad adicional o dependa de una operación transaccional posterior. Identifica sus dependencias y el momento en que podrá comprobarse.
4. Considera explícitamente la integridad contextual, temporal, histórica y entre relaciones, incluidos cambios mediante INSERT, UPDATE y DELETE cuando correspondan. No confundas la existencia de una tabla o referencia con la garantía completa de una regla.
5. Determina las adaptaciones necesarias para conservar la compatibilidad pertinente con las seis relaciones de Lab03 y sus componentes reutilizables. Distingue conservación, modificación necesaria e incompatibilidad comprobada.
6. Define el orden lógico de construcción de las relaciones y las condiciones de verificación que deberá satisfacer la implementación posterior.

**Formato de respuesta requerido:**

- **Especificación de relaciones y atributos:** cobertura completa, organizada por relación, en tablas compactas y sin omitir atributos.
- **Integridad adicional:** correspondencia regla–condición–mecanismo propuesto–etapa de verificación.
- **Continuidad de Lab03:** componentes compatibles y adaptaciones justificadas.
- **Condiciones de aceptación:** comprobaciones concretas para verificar posteriormente el esquema físico.
- **Observaciones justificadas:** contradicciones comprobadas o decisiones genuinamente no determinadas por las fuentes, si existen.

Prioriza la precisión y la cobertura sobre la extensión. No repitas explicaciones equivalentes ni reproduzcas íntegramente los documentos fuente.

Verifica la consistencia interna de la especificación antes de presentarla. Distingue hechos documentados, decisiones técnicas propuestas y garantías que todavía no pueden declararse implementadas.

**Restricciones de alcance:** no generes scripts SQL, no implementes los procesos G03-P01, G03-P02 ni G03-P03, no modifiques archivos del repositorio, no alteres decisiones aprobadas sin identificarlo y no afirmes haber ejecutado pruebas que no se realizaron.

La respuesta debe quedar técnicamente preparada sin depender de supuestos implícitos ni de correcciones posteriores que puedan prevenirse mediante el contraste de las fuentes.

**Solicitud de revisión:**

Muy bien, según leo, no me parece que haya alguna omisión o error evidente. Sin embargo, para asegurarnos, revisa que no faltase nada más que haya pasado por alto.

**Solicitud de consolidación:**

Entendido, vas a llevar a cabo las correcciones y consolidación final necesaria para cerrar este apartado.

### Respuesta

Se elaboró una propuesta de especificación física para PostgreSQL 17.11 a partir del modelo relacional corregido de Universidad Horizonte.

El aporte de GPT-6 consistió en definir tipos de datos, nulabilidad, claves y restricciones para las 26 relaciones y 135 atributos; analizar los mecanismos necesarios para mantener RN-01 a RN-20; identificar comprobaciones entre relaciones y operaciones transaccionales; determinar la continuidad de los componentes compatibles de Lab03; y establecer el orden de construcción y los criterios de verificación del esquema.

Se conservaron las relaciones y atributos del modelo corregido. No se generaron archivos SQL ni se implementaron operaciones del negocio.

### Verificación posterior

El estudiante examinó la propuesta y solicitó una segunda revisión para comprobar omisiones o errores. La revisión identificó problemas de precisión relacionados con el estado histórico de las admisiones, los antecedentes de cambios de grupo, los conflictos horarios estudiantiles, las condiciones de los historiales, las modificaciones indirectas, una limitación de `fn_creditos_obligatorios_plan` y las convenciones temporales.

Por indicación posterior del estudiante, esos problemas se corrigieron y la propuesta quedó consolidada sin añadir relaciones ni atributos. La iniciativa de revisar nuevamente la propuesta correspondió al estudiante.

Se contrastó el diccionario corregido con su documentación consolidada: 135 atributos y 1350 campos comparados sin diferencias. La matriz de trazabilidad también coincidió para las 20 reglas, con 100 campos comparados sin diferencias.

**Resultado de la validación:** especificación consolidada documentalmente. No se ejecutaron scripts ni pruebas PostgreSQL, por lo que la eficacia de los mecanismos propuestos todavía no está verificada. No se modificaron archivos del modelo ni scripts del repositorio.


## Interacción 03 — Implementación de estructuras base del modelo físico

### Prompt

Para el Proyecto Final del curso IC-4301 Bases de Datos I, Grupo 03 — Universidad Horizonte, implementa en PostgreSQL 17.11 el primer conjunto de relaciones del modelo físico consolidado, reutilizando los componentes compatibles de Lab03.

**Fuentes obligatorias:** la consigna general del Proyecto Final, el anexo del Grupo 03, los seis documentos corregidos del Proyecto 1, `Control_de_Cambios.md`, la especificación física consolidada en la intervención anterior, los cinco archivos SQL de Lab03 y el estado actual de la rama `grupo-03-proyecto-final` del repositorio `jcortess/bd1-2026-2s`.

Antes de implementar, contrasta las fuentes pertinentes. No utilices el resumen del registro de IA como sustituto del modelo o del diccionario.

**Alcance de implementación**

Construye las siguientes 16 relaciones, que comprenden 57 atributos:

- **Identidades y catálogos:** `ESTUDIANTE`, `CARRERA`, `SEDE`, `ESCUELA`, `DOCENTE`, `PERSONA_AUTORIZADORA` y `PERIODO_ACADEMICO`.
- **Dependencias directas:** `CURSO`, `VERSION_PLAN_ESTUDIOS`, `CARRERA_SEDE`, `ESPACIO`, `CONTACTO_ESTUDIANTE` y `VENTANA_PERIODO`.
- **Currículo y admisión:** `PARTICIPACION_PLAN`, `REQUISITO_CURSO` y `ADMISION`.

Realiza el trabajo bajo las siguientes condiciones:

1. Implementa exactamente los atributos, tipos, claves, nulabilidad, referencias, dominios y restricciones aprobadas para estas relaciones. Respeta los nombres y las claves compuestas del modelo corregido. No introduzcas columnas, relaciones auxiliares, longitudes, catálogos cerrados ni reglas que no estén justificadas.
2. Reutiliza el DDL válido de las seis relaciones curriculares de Lab03, adaptándolo únicamente donde corresponda. En particular, sustituye `vigencia TEXT` por `inicio_vigencia DATE` y `fin_vigencia DATE NULL`; conserva la PK de cuatro componentes de `REQUISITO_CURSO` e incorpora `id_requisito INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE NOT NULL`, sin convertirlo en PK.
3. Implementa las restricciones declarativas correspondientes a este conjunto: PK, FK, UNIQUE, CHECK, obligatoriedad, unicidad compuesta y unicidad parcial cuando corresponda. Incluye la validación de textos obligatorios no vacíos, cantidades, intervalos temporales, dominios cerrados y demás condiciones documentadas. Usa los mecanismos nativos de PostgreSQL cuando representen correctamente la regla.
4. Para `VENTANA_PERIODO`, considera la exclusión de intervalos superpuestos del mismo tipo y periodo mediante rangos temporales y GiST. Si adoptas `btree_gist`, declara expresamente su instalación y verifica que sea necesaria y compatible con el entorno. Conserva intervalos `[inicio, fin)` y permite ventanas consecutivas sin falso solapamiento.
5. Distingue las restricciones implementables ahora de las garantías que dependen de las relaciones restantes o de mecanismos posteriores. Por ejemplo, la compatibilidad entre carrera, versión y sede de `ADMISION` requiere una comprobación contextual adicional. No la declares resuelta únicamente porque existan las FK individuales, ni introduzcas datos redundantes para simplificarla.
6. Mantén las acciones referenciales coherentes con la conservación de información académica e histórica. No utilices eliminaciones en cascada que puedan destruir hechos relevantes. Considera los efectos de `INSERT`, `UPDATE` y `DELETE`, sin atribuir al esquema parcial garantías que todavía dependen de componentes no construidos.
7. Prepara los datos ficticios mínimos necesarios para comprobar este conjunto. Reutiliza los datos compatibles de Lab03 cuando corresponda. Las vigencias textuales anteriores no definen fechas exactas: cualquier fecha incorporada para adaptarlas debe identificarse como dato ficticio, no como una conversión histórica comprobada. No precargues resultados finales de los procesos de negocio asignados.
8. Proporciona comprobaciones reproducibles de las restricciones efectivamente implementadas, incluyendo casos positivos, negativos y de frontera pertinentes. Cada prueba negativa debe aislar la restricción que pretende demostrar, sin fallar accidentalmente por otra causa. Las pruebas deben permitir continuar después de rechazos esperados y no dejar transacciones abiertas ni residuos que comprometan su repetición.
9. Conserva las tres consultas, cuatro rutinas y nueve pruebas de Lab03 como componentes de referencia para su integración y comprobación posterior. Identifica adaptaciones necesarias, sin reescribir componentes correctos ni ampliar esta intervención para ejecutar prematuramente toda la batería del modelo completo.
10. Mantén el esquema compatible con el entorno Docker Compose ya incorporado. La instalación deberá poder ejecutarse sobre una base PostgreSQL nueva, sin depender de objetos preexistentes, preparación manual oculta, rutas absolutas o credenciales personales.

**Formato de respuesta requerido**

- **Decisiones técnicas:** únicamente las necesarias para explicar la implementación, la reutilización y las restricciones seleccionadas.
- **Implementación:** archivos `.sql` completos, con rutas de destino propuestas, contenidos íntegros y orden de ejecución. Cada archivo debe ser ejecutable independientemente de Markdown; no entregues fragmentos incompletos ni código omitido por brevedad.
- **Verificación:** procedimientos y pruebas SQL reproducibles, con precondiciones, resultados esperados y comprobaciones del estado de la base. Distingue claramente resultados ejecutados de resultados previstos.
- **Correspondencia y límites:** identifica las 16 relaciones y 57 atributos cubiertos, las restricciones verificadas y las dependencias pendientes de las siguientes intervenciones. Señala incompatibilidades reales con Lab03, si las encuentras.

**Criterios de aceptación**

La entrega debe permitir comprobar que:

1. Las 16 relaciones se crean correctamente desde una base nueva, en un orden de dependencias válido.
2. Existen los 57 atributos previstos, con tipos, nulabilidad, claves y referencias correspondientes al modelo corregido.
3. Las restricciones declarativas del conjunto admiten datos válidos y rechazan datos inválidos por la causa correcta.
4. Se conservan las claves compuestas, alternativas y unicidades condicionales establecidas.
5. Las seis relaciones de Lab03 mantienen su comportamiento compatible, con las adaptaciones justificadas.
6. Los scripts y las pruebas son reproducibles, y cualquier limitación de integridad todavía pendiente queda explícitamente identificada.

**Restricciones de trabajo**

No implementes todavía las diez relaciones restantes, los mecanismos de integridad avanzada que dependan de ellas ni los procesos G03-P01, G03-P02 y G03-P03.

No generes documentación adicional, interfaces, servicios o componentes que no sean necesarios para este alcance.

No modifiques directamente el repositorio ni ejecutes operaciones de escritura mediante conectores. El estudiante incorporará personalmente los archivos después de revisar la propuesta.

Revisa la consistencia completa del SQL y de las pruebas antes de responder. No afirmes haber ejecutado PostgreSQL, comprobado concurrencia o validado resultados observados si no realizaste efectivamente dichas operaciones.

Prioriza la corrección, la mantenibilidad y la verificación sobre la extensión del texto o la cantidad de componentes creados. La respuesta debe quedar lista para revisión e incorporación, sin marcadores pendientes, simplificaciones injustificadas ni aspectos técnicos previsibles sin resolver.

**Solicitud de auditoría y corrección:**

La siguiente versión debe haber auditado completamente, identificar cualquier error en este alcance y corregirlo antes de implementarse, para posteriormente hacer las pruebas.

**Solicitud de comprobación de correspondencia con el modelo:**

Las correcciones son pertinentes y todo parte del modelado real?

**Aprobación de la versión corregida:**

Perfecto, queda aprobado, dame las versiones finales de los archivos para colocarlos y luego hacemos sus pruebas, si todo sale bien pasamos a su registro correcto

### Respuesta

GPT-6 preparó la implementación de las 16 relaciones base y sus 57 atributos en PostgreSQL 17.11, utilizando la especificación física consolidada, el modelo relacional corregido y los componentes compatibles de Lab03.

Se entregaron tres archivos SQL: `01_esquema_base.sql`, con la definición de las relaciones y sus restricciones declarativas; `02_datos_base.sql`, con datos ficticios y adaptación del núcleo curricular de Lab03; y `01_pruebas_base.sql`, con comprobaciones reproducibles de estructura, integridad y comportamiento ante operaciones válidas e inválidas.

La implementación conservó las claves compuestas y alternativas del modelo, incorporó las restricciones de unicidad condicional y utilizó rangos temporales con exclusión GiST para impedir solapamientos indebidos de ventanas académicas.

### Verificación posterior

El estudiante revisó la entrega, las revisiones identificaron defectos en el aislamiento y la repetibilidad de determinados casos negativos, particularmente por conflictos de identificadores en `REQUISITO_CURSO`. Se corrigieron siete casos afectados y se reforzaron las comprobaciones para asegurar que los rechazos correspondieran a las restricciones previstas.

También se comprobó que las correcciones fueran pertinentes y estuvieran fundamentadas en el modelo relacional, el diccionario de datos y la matriz de trazabilidad. Tras esa revisión, se aprobó expresamente la versión consolidada y la incorporó manualmente.

La ejecución en PostgreSQL 17.11 confirmó la instalación de las 16 relaciones y 57 atributos, con 16 claves primarias, 15 foráneas, cuatro restricciones UNIQUE, 25 CHECK, un índice único parcial y una exclusión GiST. Las pruebas positivas finalizaron correctamente; también se confirmaron 53 rechazos por la causa prevista y cinco comprobaciones adicionales de obligatoriedad. Una consulta posterior verificó que permanecían los 64 registros iniciales después del `ROLLBACK` de las pruebas.

**Resultado de la validación:** implementación corregida por indicación del estudiante, aprobada e incorporada manualmente, con ejecución y comprobaciones satisfactorias en PostgreSQL 17.11.


## Interacción 04 — Implementación de relaciones restantes del modelo físico

### Prompt

## 1. Contexto y objetivo

Para el Proyecto Final del curso **IC-4301 Bases de Datos I**, Grupo 03 — Universidad Horizonte, implementa en **PostgreSQL 17.11** las diez relaciones restantes del modelo físico consolidado.

El proyecto se desarrolla en el repositorio `jcortess/bd1-2026-2s`, rama `grupo-03-proyecto-final`, directorio `final-project/grupo-03/`.

La configuración del entorno PostgreSQL, la especificación física y la implementación de estructuras base están cerradas. Esta última implementó y verificó 16 relaciones y 57 atributos.

**Objetivo de esta intervención:** completar la estructura física de las 26 relaciones y 135 atributos aprobados, implementando las restricciones declarativas correspondientes al conjunto pendiente y preparando datos y pruebas reproducibles.

La intervención debe cubrir **únicamente la implementación de las relaciones restantes**, sin anticipar los mecanismos de integridad avanzada ni los procesos funcionales posteriores.

## 2. Fuentes obligatorias

Antes de escribir el SQL, contrasta directamente:

1. La consigna general del Proyecto Final y el anexo del Grupo 03.
2. La especificación oficial de `Control_de_Cambios.md`.
3. Los seis documentos originales corregidos del Proyecto 1: análisis del caso, modelo conceptual, modelo relacional, diccionario de datos, normalización y matriz de trazabilidad.
4. Sus versiones consolidadas en `modelo/` y `diagramas/` del repositorio.
5. `Control_de_Cambios.md`, especialmente las correcciones del Proyecto 1 y la continuidad de Lab03.
6. `Uso_de_IA.md`, interacción 02, que registra la especificación física consolidada del modelo.
7. Los tres scripts SQL implementados y verificados de las estructuras base.
8. Los componentes de Lab03 pertinentes para las referencias curriculares y la continuidad del modelo.

Los documentos originales corregidos deben consultarse efectivamente; no basta utilizar las conversiones Markdown. Las diferencias documentadas y justificadas en `Control_de_Cambios.md` deben respetarse, incluyendo la corrección posterior de la interpretación de P07 de Lab03.

No reabras las correcciones docentes ya incorporadas ni vuelvas a diseñar el modelo lógico. Si aparece una incompatibilidad técnica comprobable, identifícala y fundaméntala antes de proponer una modificación.

No utilices resúmenes conversacionales como sustitutos de las fuentes.

## 3. Alcance exacto de la implementación de relaciones restantes

Implementa exclusivamente las siguientes relaciones:

| Relación | Atributos |
|---|---:|
| `GRUPO` | 8 |
| `BLOQUE_HORARIO` | 7 |
| `SOLICITUD_MATRICULA` | 12 |
| `TRASLADO_PLAN` | 7 |
| `RECONOCIMIENTO_ACADEMICO` | 8 |
| `GRUPO_DOCENTE` | 3 |
| `HISTORIAL_OFERTA` | 10 |
| `HISTORIAL_SOLICITUD` | 8 |
| `EXCEPCION_REQUISITO` | 6 |
| `HISTORIAL_CORRECCION_CALIFICACION` | 9 |
| **Total** | **78** |

Estas relaciones deben complementar las 16 ya implementadas, alcanzando exactamente **26 relaciones y 135 atributos**.

Conserva sus nombres, identidades, claves, referencias, dominios, nulabilidad y decisiones de diseño consolidadas.

No agregues ni elimines atributos o relaciones sin una incompatibilidad real, identificada y justificada.

## 4. Implementación de estructuras y restricciones

### 4.1. Definición física

Implementa los `CREATE TABLE` en orden válido de dependencias, utilizando los tipos apropiados de PostgreSQL y respetando el diccionario corregido.

Incluye las garantías declarativas aplicables:

- Claves primarias simples y compuestas.
- Claves foráneas, incluidas referencias compuestas y autorreferencias.
- Restricciones `UNIQUE` y, cuando corresponda, índices únicos parciales.
- Restricciones `NOT NULL`.
- Restricciones `CHECK` sobre dominios, cantidades, intervalos, relaciones entre atributos y condiciones de nulabilidad.
- Validación de textos obligatorios no vacíos.
- Acciones referenciales compatibles con la conservación del historial.

No inventes longitudes, escalas de calificación, dominios institucionales cerrados, valores numéricos ni políticas de negocio ausentes de las fuentes.

### 4.2. Tratamiento correcto de `NULL`

Diseña y revisa expresamente las restricciones condicionales considerando la lógica ternaria de SQL.

En PostgreSQL, un `CHECK` acepta una expresión cuyo resultado sea `TRUE` o `NULL`. Por tanto, no basta construir una condición aparentemente correcta: debe rechazarse efectivamente toda combinación inválida que corresponda rechazar.

Utiliza expresiones explícitas, `IS NULL`, `IS NOT NULL`, `IS DISTINCT FROM` u otros mecanismos apropiados cuando sean necesarios para expresar correctamente la regla.

Comprueba especialmente las combinaciones opcionales de solicitudes, reconocimientos y registros históricos.

### 4.3. Condiciones particulares del modelo

Presta especial atención a estas garantías, siempre conforme al diccionario y modelo aprobados:

**GRUPO:** identificación de periodo, sede, curso y número de grupo; capacidad; modalidad; estado de oferta; unicidad contextual de la oferta.

**BLOQUE_HORARIO:** día válido, intervalo horario consistente, presencialidad y espacio obligatorio cuando corresponda. No imponer restricciones adicionales injustificadas a actividades no presenciales.

**SOLICITUD_MATRICULA:** estados permitidos, motivo de rechazo o espera, orden de espera, instante de transición, calificación y resultado académico; impedir autorreferencia directa inválida y conservar información histórica pertinente.

**TRASLADO_PLAN:** referencias a admisión y versiones, origen diferente de destino, fecha, motivo y persona autorizadora.

**RECONOCIMIENTO_ACADEMICO:** origen institucional o externo de manera excluyente, curso satisfecho vinculado a su versión mediante la referencia compuesta correspondiente, resolución y fecha. No inventar unicidad global de resoluciones.

**GRUPO_DOCENTE:** identidad compuesta y rol válido; garantizar declarativamente como máximo un responsable cuando corresponda, sin confundirlo con la garantía de existencia de un responsable para cada oferta publicada.

**HISTORIAL_OFERTA:** tipos de cambio y atributos condicionales, permitiendo representar correctamente una apertura inicial y los demás eventos válidos.

**HISTORIAL_SOLICITUD:** distinguir transiciones de evaluaciones, incluidas evaluaciones que no modifican el estado de una solicitud.

**EXCEPCION_REQUISITO:** referencia a solicitud, requisito identificado mediante `id_requisito`, autorizante, fecha y motivo, conservando la clave curricular compuesta original.

**HISTORIAL_CORRECCION_CALIFICACION:** valores anteriores y nuevos, modificaciones efectivas, motivo, fecha y autorizante, sin imponer una escala universal de calificación.

Ninguna restricción local debe impedir representar situaciones válidas que requieran los procesos posteriores.

## 5. Integridad avanzada y límites de esta intervención

Distingue estrictamente entre:

**A. Garantías implementables en esta intervención:** restricciones declarativas sobre las diez relaciones, incluidas las referencias y unicidades condicionales sustentadas por el modelo.

**B. Garantías reservadas para la integridad avanzada:** reglas que requieren comprobar otras filas, relaciones, estados históricos, compatibilidad contextual o modificaciones indirectas mediante mecanismos adicionales.

**C. Garantías operativas de fases posteriores:** decisiones completas de oferta, matrícula, espera, retiro y cambio de grupo, incluidas atomicidad y concurrencia de G03-P01, G03-P02 y G03-P03.

Entre las garantías que no deben darse por implementadas prematuramente se encuentran:

- Compatibilidad contextual e histórica de admisiones y traslados.
- Coherencia de los espacios con la sede y los periodos de los grupos.
- Ausencia de ocupaciones horarias incompatibles entre grupos.
- Existencia de exactamente un docente responsable y de los bloques requeridos para una oferta publicada.
- Correspondencia curricular completa de excepciones y solicitudes.
- Prevención de ciclos de solicitudes anteriores que excedan una autorreferencia directa.
- Concordancia entre estados vigentes y sus historiales.
- Ocupación, duplicación de matrículas activas y promociones concurrentes.

No implementes funciones, procedimientos o triggers adelantados para resolver esas garantías.

Sin embargo, **no omitas una restricción declarativa propia de esta intervención simplemente porque esté relacionada con una regla más amplia de integridad avanzada**.

Identifica claramente qué queda garantizado, qué permanece pendiente y por qué.

## 6. Compatibilidad con las estructuras base

Preserva los archivos y la implementación aprobada de las 16 relaciones base.

No modifiques las tablas, sus 57 atributos, las restricciones, los datos iniciales ni los archivos de pruebas por conveniencia.

Las referencias desde las nuevas relaciones deben utilizar las claves realmente existentes, incluidos los nombres y tipos adoptados y la clave alternativa `REQUISITO_CURSO.id_requisito`.

Si alguna incompatibilidad técnicamente demostrada impide incorporar una relación, explícala antes de modificar un componente cerrado. No apliques soluciones provisionales ni cambios silenciosos.

### Datos auxiliares

Se permite insertar registros ficticios adicionales en las relaciones base **desde el script de datos de las relaciones restantes**, cuando sean indispensables para probar las diez relaciones nuevas.

Estas inserciones deben:

- Respetar las restricciones ya verificadas.
- No alterar ni eliminar los 64 registros originales de las estructuras base.
- No modificar `02_datos_base.sql`.
- Mantener referencias coherentes y datos reproducibles.
- Distinguir preparación de contexto académico de resultados producidos por procesos operativos.

No precargues resultados finales de G03-P01, G03-P02 o G03-P03 para presentarlos después como ejecuciones reales.

## 7. Archivos que deben entregarse

Prepara únicamente los tres archivos SQL necesarios, con contenido completo:

**`sql/03_esquema_relaciones.sql`**

Crea las diez relaciones nuevas, sus claves, referencias, restricciones e índices justificados.

**`sql/04_datos_relaciones.sql`**

Incorpora los datos ficticios necesarios para probar el conjunto, incluidas las referencias adicionales justificadas a relaciones existentes.

**`pruebas/02_pruebas_relaciones.sql`**

Verifica la estructura física, las restricciones declarativas, los datos iniciales y los comportamientos válidos e inválidos correspondientes.

Estos nombres siguen la organización propuesta para el bloque y deben comprobarse contra el árbol real del repositorio antes de incorporarlos.

Los archivos deben ser ejecutables directamente mediante `psql`, sin depender de fragmentos de Markdown ni de preparación manual oculta.

No generes otros scripts, documentos, servicios ni archivos auxiliares.

## 8. Pruebas y verificación

### 8.1. Cobertura

Las pruebas deben comprobar:

- Existencia de las 26 tablas y los 135 atributos.
- Correspondencia de columnas, tipos, nulabilidad, claves y referencias con el modelo.
- Restricciones de dominio, unicidad y condiciones entre atributos.
- Inserciones válidas.
- Rechazos esperados.
- Casos límite aplicables.
- Operaciones `UPDATE` y `DELETE`, tanto permitidas como rechazadas cuando corresponda.
- Efectos de las referencias sobre actualizaciones y eliminaciones.
- Ausencia de modificaciones indebidas después de un rechazo.
- Conservación de datos históricos y referenciales.

Una misma prueba puede cubrir varias reglas cuando su resultado sea inequívoco. No establezcas una cantidad artificial de pruebas por tabla.

### 8.2. Calidad de las pruebas

Cada prueba debe identificar la condición examinada y distinguir resultado esperado de resultado observado.

Los casos negativos deben provocar el rechazo por la restricción correcta, no por otra infracción accidental.

Cuando corresponda, verifica `SQLSTATE`, nombre de restricción, columna afectada y estado posterior de los datos.

Utiliza bloques de excepción, transacciones, puntos de guardado y `ROLLBACK` conforme resulte apropiado para:

- Continuar después de rechazos esperados.
- Evitar transacciones abiertas.
- No dejar residuos que comprometan futuras ejecuciones.
- Permitir repetir las pruebas sobre una instalación válida.
- Conservar el estado inicial después de las comprobaciones temporales.

No presentes un error genérico de PostgreSQL como prueba exitosa.

### 8.3. Orden obligatorio de ejecución

Para reproducir y comprobar el conjunto completo:

1. Crear una base nueva mediante el entorno Docker Compose existente.
2. Ejecutar `sql/01_esquema_base.sql`.
3. Ejecutar `sql/02_datos_base.sql`.
4. Ejecutar y verificar `pruebas/01_pruebas_base.sql` mientras existen únicamente las 16 relaciones base.
5. Ejecutar `sql/03_esquema_relaciones.sql`.
6. Ejecutar `sql/04_datos_relaciones.sql`.
7. Ejecutar `pruebas/02_pruebas_relaciones.sql`.
8. Comprobar desde una conexión independiente las 26 relaciones, los 135 atributos y la persistencia de los datos iniciales correspondientes.

**Importante:** `01_pruebas_base.sql` comprueba deliberadamente 16 relaciones y 57 atributos. No debe ejecutarse sin adaptación sobre el esquema ampliado de 26 relaciones.

La comprobación integral posterior de todas las reglas y mecanismos avanzados corresponde a las pruebas integrales del modelo físico.

Proporciona comandos **PowerShell** concretos para ejecutar y verificar los scripts, utilizando el servicio Docker `db`, el usuario `bd1`, `psql -X`, `ON_ERROR_STOP=1` y las rutas montadas en `/workspace`.

No modifiques la configuración Docker ya aprobada.

## 9. Condiciones de aceptación

La implementación de las relaciones restantes podrá considerarse satisfactoria cuando se haya comprobado que:

1. Las diez relaciones adicionales se crean correctamente sobre las 16 existentes.
2. El esquema resultante tiene exactamente 26 relaciones y 135 atributos.
3. Los atributos, claves, referencias, dominios y restricciones declarativas corresponden a las fuentes corregidas.
4. Se preservan las claves compuestas, alternativas y unicidades condicionales justificadas.
5. Los datos iniciales de las estructuras base permanecen íntegros.
6. Los nuevos datos ficticios son referencialmente válidos y suficientes para demostrar el alcance.
7. Las pruebas positivas, negativas, de frontera y de modificación/eliminación producen resultados verificables.
8. Las operaciones fallidas no dejan efectos indebidos ni invalidan otras pruebas.
9. El conjunto puede instalarse desde una base nueva siguiendo un orden documentado.
10. Las garantías reservadas para la integridad avanzada permanecen correctamente identificadas, sin atribuirles una implementación inexistente.

Distingue expresamente las condiciones verificadas mediante ejecución real de aquellas que todavía son resultados esperados.

## 10. Forma de trabajo y control de calidad

Antes de entregar código, realiza una revisión de consistencia entre las diez relaciones, el diccionario, las referencias existentes, los datos de prueba y las restricciones propuestas.

Corrige cualquier error identificable en el alcance de la implementación de las relaciones restantes antes de presentar la versión para aprobación.

Entrega los tres SQL completos, sin pseudocódigo, fragmentos omitidos, marcadores `TODO` ni simplificaciones técnicas injustificadas.

Presenta únicamente las explicaciones necesarias para justificar decisiones relevantes y permitir su incorporación y verificación.

**No modifiques directamente el repositorio.** El estudiante revisará los archivos, los incorporará manualmente y ejecutará las pruebas en su entorno.

Después de la implementación:

1. Examina las salidas reales de PostgreSQL proporcionadas por el estudiante.
2. Si hay errores, diagnostica su causa y corrige únicamente el alcance afectado.
3. Una vez verificadas las pruebas, consolida los resultados relevantes y prepara las actualizaciones necesarias de documentación.
4. Documenta la interacción en `Uso_de_IA.md` conforme a lo exigido por el profesor, con el prompt utilizado, el aporte incorporado, las correcciones y las validaciones efectivamente realizadas.
5. No declares la implementación de las relaciones restantes cerrada hasta comprobar sus criterios de aceptación.

No agregues registros innecesarios de conversaciones ordinarias ni dupliques documentación entre archivos.

## 11. Restricciones finales

- No reabrir la especificación física ni la implementación de las estructuras base sin una incompatibilidad demostrada.
- No modificar el modelo conceptual o relacional aprobado por preferencias de implementación.
- No implementar los mecanismos de integridad avanzada.
- No implementar G03-P01, G03-P02 ni G03-P03.
- No crear interfaces, APIs, servicios ni automatizaciones adicionales.
- No inventar requisitos, reglas, resultados, pruebas o fuentes.
- No alterar archivos fuera del alcance autorizado.
- No afirmar que una operación fue verificada sin evidencia de ejecución.

**Prioridad:** corrección técnica, fidelidad al modelo, integridad, reproducibilidad, trazabilidad y simplicidad justificada.

El resultado debe quedar listo para revisión, incorporación y pruebas reales, sin trabajo adicional que no sea exigido por el proyecto.

### Respuesta

GPT-6 preparó la implementación de las diez relaciones restantes del modelo físico de Universidad Horizonte y sus 78 atributos para PostgreSQL 17.11, tomando como referencia el modelo corregido, la especificación física y las estructuras base existentes.

Se entregaron tres archivos SQL: `03_esquema_relaciones.sql`, con la definición de relaciones y restricciones declarativas; `04_datos_relaciones.sql`, con datos ficticios complementarios; y `02_pruebas_relaciones.sql`, con comprobaciones reproducibles de estructura, integridad, inserciones, modificaciones, eliminaciones y rechazos esperados.

Se conservaron las 16 relaciones base y sus 57 atributos, completando las 26 relaciones y 135 atributos del modelo. La implementación incluyó claves primarias, foráneas, restricciones de dominio, unicidades contextuales y un índice único parcial. Las garantías que requieren mecanismos adicionales de integridad contextual, histórica o transaccional no se implementaron en este conjunto.

### Verificación posterior

El estudiante examinó la propuesta y solicitó revisiones adicionales para identificar errores materiales y comprobar su correspondencia con el modelo corregido y la consigna. Las revisiones detectaron problemas en las condiciones de nulabilidad de `HISTORIAL_SOLICITUD`, inconsistencias entre determinados escenarios de prueba y restricciones que podían provocar rechazos por causas distintas de las examinadas. Se corrigieron los casos afectados y se consolidaron 102 pruebas negativas.

Por indicación del estudiante también se corrigieron referencias internas incorporadas indebidamente en los scripts y se ajustó el procedimiento de ejecución al entorno Docker Compose existente, sin modificar las estructuras base.

La ejecución en PostgreSQL 17.11 confirmó la instalación de las diez relaciones adicionales sobre las 16 existentes. Una consulta independiente verificó 26 tablas y 135 atributos. El script de datos incorporó 17 registros complementarios y finalizó con `COMMIT`.

La primera ejecución del script de pruebas se interrumpió por dos referencias incorrectas a `grupo.estado`, cuando el atributo implementado era `estado_oferta`. Se corrigieron ambas referencias y se ajustó una prueba negativa de clave primaria de `GRUPO` para evitar una infracción simultánea de unicidad contextual. Una consulta posterior confirmó que la ejecución interrumpida no dejó registros temporales persistidos.

La segunda ejecución finalizó satisfactoriamente. Se verificaron las 26 tablas, los 135 atributos y las 78 columnas nuevas, junto con los escenarios positivos, de frontera, operaciones `UPDATE` y `DELETE` y 102 casos negativos rechazados por las condiciones previstas. El script terminó mediante `ROLLBACK`, sin errores no controlados.

Una consulta independiente posterior confirmó la conservación de cuatro grupos, cinco bloques horarios, cinco asignaciones docentes, un traslado y un reconocimiento académico, sin registros temporales persistidos en las otras cinco relaciones.

**Resultado de la validación:** implementación estructural y restricciones declarativas verificadas satisfactoriamente en PostgreSQL 17.11, después de las correcciones solicitadas por el estudiante. Las garantías de integridad avanzada y los procesos G03-P01, G03-P02 y G03-P03 permanecen pendientes. No se comprobó la publicación definitiva de los archivos en la rama del repositorio.


## Interacción 05 — Implementación de integridad avanzada del modelo físico

### Prompt

# Implementación de integridad avanzada del modelo físico — Universidad Horizonte

## 1. Objetivo

Para el Proyecto Final de **IC-4301 Bases de Datos I**, Grupo 03 — Universidad Horizonte, implementa en **PostgreSQL 17.11** las garantías de integridad avanzada del modelo físico consolidado.

Repositorio: `jcortess/bd1-2026-2s`
Rama: `grupo-03-proyecto-final`
Directorio: `final-project/grupo-03/`

El modelo físico comprende **26 relaciones, 135 atributos y 20 reglas de negocio (RN-01 a RN-20)**. Sus estructuras y restricciones declarativas están implementadas.

El objetivo es completar las garantías contextuales, temporales, históricas y entre relaciones que requieren mecanismos adicionales, mediante una implementación integral y comprobaciones específicas reproducibles.

## 2. Fuentes técnicas obligatorias

Fundamenta la implementación en el contraste directo de:

1. La consigna general del Proyecto Final y el anexo específico del Grupo 03.
2. El enunciado original de Universidad Horizonte y sus aclaraciones complementarias.
3. Los seis documentos originales corregidos del Proyecto 1: análisis del caso, modelo conceptual, modelo relacional, diccionario de datos, normalización y matriz de trazabilidad. Examina también la representación gráfica del modelo conceptual.
4. Las versiones consolidadas del modelo y las decisiones de diseño documentadas en el repositorio.
5. Los scripts SQL existentes de estructuras, datos y pruebas, y los resultados técnicos correspondientes.
6. Los componentes pertinentes de Lab03 y sus adaptaciones al modelo actual.
7. El material oficial de Bases de Datos I sobre SQL, PL/pgSQL, funciones, procedimientos, triggers y transacciones.
8. La documentación oficial de PostgreSQL 17 sobre restricciones, triggers, MVCC, aislamiento, bloqueos y concurrencia.

Determina las garantías que ya están cubiertas y las que requieren mecanismos adicionales, considerando las 20 reglas de negocio y las condiciones aplicables del anexo G03.

## 3. Garantías de integridad avanzada

### 3.1. Contexto académico y trayectoria histórica

Implementa las garantías correspondientes a:

- Compatibilidad entre la carrera derivada de la versión del plan, la sede y la admisión.
- Coherencia de `CARRERA_SEDE` y `VERSION_PLAN_ESTUDIOS` con las admisiones y antecedentes que dependen de ellas.
- Consistencia de la trayectoria de cada admisión, incluyendo versión inicial, traslados sucesivos, fechas efectivas y versiones de origen y destino.
- Correspondencia del plan vigente en cada instante histórico con las solicitudes y reconocimientos asociados.
- Integridad de resoluciones académicas, curso satisfecho, versión aplicable y fecha de reconocimiento.
- Conservación de los contextos académicos utilizados en decisiones históricas.

Las comprobaciones deben preservar la independencia entre admisiones de un mismo estudiante y utilizar la trayectoria registrada para determinar el contexto correspondiente a cada operación.

### 3.2. Currículo, requisitos y satisfacción de cursos

Implementa las garantías contextuales sobre:

- Correspondencia entre requisitos, correquisitos, cursos objetivo, cursos exigidos y versiones del plan.
- Aplicabilidad de cada requisito al curso y versión evaluados.
- Identificación de cursos satisfechos por aprobación académica previa o reconocimiento válido.
- Coherencia temporal de los antecedentes utilizados para determinar satisfacción de requisitos.
- Correspondencia entre excepciones autorizadas, solicitudes, requisitos concretos y versiones evaluadas.
- Protección de las relaciones curriculares y académicas frente a modificaciones que invaliden dependencias existentes.

Las comprobaciones de satisfacción deben respetar la distinción entre requisito previo y correquisito, así como el significado histórico de los resultados y reconocimientos.

### 3.3. Periodos y ventanas académicas

Implementa las garantías temporales pertinentes para:

- Vigencias de versiones del plan y su relación con trayectorias históricas.
- Integridad de las ventanas de matrícula, modificación y retiro asociadas a cada periodo.
- Evaluación de instantes de operación utilizando los intervalos semiabiertos `[inicio, fin)`.
- Correspondencia entre fecha de solicitud, ventana de matrícula y condición de la admisión en el momento de registrar la operación.
- Correspondencia entre transiciones de retiro o modificación y sus ventanas autorizadas.
- Conservación del contexto temporal de solicitudes y transiciones previamente registradas.

Respeta la representación independiente de las fechas lectivas del periodo y sus ventanas operativas.

### 3.4. Oferta académica, docentes y horarios

Implementa las garantías sobre:

- Existencia de exactamente un docente responsable y de los bloques requeridos al confirmar una oferta publicada.
- Correspondencia entre la sede del grupo y los espacios asignados a sus actividades presenciales.
- Compatibilidad entre modalidad, presencialidad, espacios y capacidad física conforme al modelo.
- Ausencia de ocupaciones incompatibles de un mismo espacio, considerando fechas lectivas superpuestas, día de la semana e intervalos horarios.
- Consistencia entre capacidad de un grupo y ocupación confirmada.
- Conservación de solicitudes y antecedentes académicos durante cambios de oferta y cancelaciones.
- Correspondencia entre modificaciones relevantes de oferta y eventos históricos que registran estado o capacidad anterior y nueva, fecha, motivo y responsable.

Los mecanismos deben admitir la construcción transaccional de ofertas y los intervalos horarios consecutivos válidos.

### 3.5. Solicitudes, matrículas y listas de espera

Implementa las garantías transversales sobre:

- Correspondencia entre admisión, grupo, curso, periodo y versión del plan evaluada.
- Exclusividad de matrícula activa por estudiante, curso y periodo, incluyendo matrículas registradas mediante admisiones diferentes.
- Consistencia entre ocupación y capacidad del grupo.
- Conservación del contexto de las solicitudes históricas.
- Coherencia del estado de espera, orden de ingreso y momento de transición.
- Integridad de las referencias a solicitudes anteriores, incluyendo identidad de la admisión, mismo curso y periodo, grupo de destino diferente y ausencia de ciclos.
- Consistencia de los antecedentes de una matrícula durante cambios de grupo.
- Protección de estas garantías ante modificaciones de admisiones, grupos, capacidades, solicitudes y relaciones vinculadas.

Las condiciones deben mantenerse al confirmar operaciones compuestas y transacciones concurrentes.

### 3.6. Estados, eventos y correcciones académicas

Implementa las garantías sobre:

- Correspondencia entre los estados de `SOLICITUD_MATRICULA` y sus eventos en `HISTORIAL_SOLICITUD`.
- Consistencia de los estados anterior y nuevo, instantes y motivos de transición.
- Diferenciación entre transiciones reales y evaluaciones de espera sin cambio de estado.
- Coherencia entre la oferta vigente y los eventos de `HISTORIAL_OFERTA`.
- Correspondencia entre correcciones de calificación o resultado académico y sus valores anteriores y nuevos.
- Integridad de la secuencia de correcciones, sus fechas, motivos y autorizaciones.
- Conservación de antecedentes y prevención de modificaciones que contradigan hechos históricos.

Los mecanismos que registren cambios autorizados deben utilizar los datos efectivos de la operación y conservar su consistencia transaccional.

## 4. Diseño e implementación técnica

Selecciona el mecanismo PostgreSQL más adecuado para cada garantía, reutilizando las restricciones declarativas existentes y empleando funciones PL/pgSQL, triggers, comprobaciones diferibles y sincronización transaccional según corresponda.

El diseño debe considerar:

1. Invariantes exactos y relaciones involucradas.
2. Operaciones `INSERT`, `UPDATE` y `DELETE` que puedan afectar cada garantía.
3. Modificaciones indirectas desde tablas referenciadas.
4. Dependencias entre funciones, triggers y restricciones.
5. Comprobaciones inmediatas y diferidas según el estado que debe garantizarse.
6. Consistencia al finalizar operaciones compuestas.
7. Tratamiento correcto de `NULL` y comparaciones históricas.
8. Comportamiento ante operaciones sobre varias filas.
9. Concurrencia, MVCC, niveles de aislamiento, bloqueos e interbloqueos.
10. Protección de las garantías mediante las rutas de escritura pertinentes.
11. Diagnósticos específicos de las infracciones detectadas.
12. Compatibilidad con las estructuras, restricciones y **81 registros iniciales**.

Verifica que las garantías se mantengan tanto en operaciones individuales como en transacciones concurrentes, considerando los cambios de las relaciones que intervienen en cada comprobación.

Selecciona mecanismos correctos, eficientes, mantenibles y proporcionados a las necesidades del modelo.

## 5. Archivos de implementación

Desarrolla los scripts SQL completos conforme a la organización y numeración existente:

### `sql/05_integridad_avanzada.sql`

Implementación integral de los mecanismos avanzados, incluidas las funciones PL/pgSQL, triggers, restricciones y demás objetos técnicamente necesarios.

El script debe establecer el orden correcto de instalación, comprobar la compatibilidad de los registros existentes y conservar la integridad de las estructuras y datos previamente incorporados.

### `pruebas/03_pruebas_integridad_avanzada.sql`

Batería reproducible de comprobaciones específicas para los nuevos mecanismos.

Debe contener los casos positivos, negativos, de frontera, históricos y de modificación necesarios para demostrar su comportamiento, con preparación controlada y comprobación de los resultados.

Incorpora las secuencias SQL requeridas para las pruebas de concurrencia desde conexiones independientes, organizadas conforme a las dependencias reales de ejecución.

Los scripts deben ser completos, ejecutables mediante `psql` y técnicamente consistentes entre sí.

## 6. Pruebas y verificación

### 6.1. Cobertura

Comprueba:

- Instalación y existencia de todos los mecanismos incorporados.
- Aceptación de situaciones válidas.
- Rechazo de incompatibilidades por la causa prevista.
- Casos límite contextuales, curriculares, temporales e históricos.
- Operaciones `INSERT`, `UPDATE` y `DELETE` pertinentes.
- Modificaciones indirectas de relaciones vinculadas.
- Estados intermedios y finales de operaciones compuestas.
- Integridad y preservación de antecedentes.
- Ausencia de efectos parciales incompatibles.
- Comportamiento bajo transacciones concurrentes.
- Compatibilidad con las restricciones y registros existentes.
- Repetibilidad y conservación del estado inicial después de las pruebas temporales.

### 6.2. Calidad de las pruebas

Cada caso debe identificar:

1. Regla o condición examinada.
2. Precondiciones y datos de preparación.
3. Operación que se ejecuta.
4. Resultado esperado.
5. Consulta de comprobación del resultado y estado posterior.

Los casos negativos deben aislar el mecanismo que pretenden comprobar. Utiliza `SQLSTATE`, diagnósticos específicos y verificaciones del estado de los datos cuando correspondan.

Controla las pruebas mediante transacciones, bloques de excepción, puntos de guardado y `ROLLBACK` según su necesidad. Considera también los efectos no transaccionales de las secuencias PostgreSQL.

Las verificaciones concurrentes deben especificar las acciones de cada sesión, sus intercalaciones, confirmaciones o rechazos y las consultas del estado final.

### 6.3. Procedimiento de ejecución

Proporciona el orden de instalación y los comandos PowerShell necesarios para ejecutar y comprobar los mecanismos en el entorno Docker Compose existente.

Utiliza:

- PostgreSQL 17.11.
- Servicio `db`.
- Usuario `bd1`.
- `psql -X -v ON_ERROR_STOP=1`.
- Rutas montadas bajo `/workspace`.

Identifica las precondiciones de ejecución, los resultados esperados y las consultas de comprobación posteriores.

Verifica la integridad de la instalación y los datos iniciales antes de ejecutar las pruebas específicas.

## 7. Formato de entrega

Presenta la implementación completa con:

**Decisiones técnicas:** mecanismos utilizados y justificación de las decisiones relevantes.

**Cobertura:** correspondencia entre reglas de negocio, garantías, mecanismos y pruebas.

**Archivos SQL:** scripts completos, organizados y ejecutables.

**Verificación:** procedimientos de ejecución, comandos PowerShell, resultados esperados y comprobaciones del estado de la base.

Revisa previamente la consistencia del conjunto, sus dependencias y la correspondencia con las fuentes.

## 8. Condiciones de aceptación

La implementación será satisfactoria cuando:

1. Estén cubiertas todas las garantías avanzadas pertinentes de las 20 reglas de negocio y del anexo G03.
2. Los mecanismos correspondan al modelo físico consolidado.
3. Se mantengan válidas las estructuras, restricciones y datos iniciales.
4. La instalación complete correctamente sus dependencias.
5. Las situaciones válidas sean aceptadas.
6. Las incompatibilidades se rechacen por la condición correcta.
7. Las reglas permanezcan protegidas ante modificaciones directas e indirectas.
8. Se conserve la coherencia contextual, temporal e histórica.
9. Las operaciones compuestas mantengan atomicidad.
10. Las condiciones concurrentes pertinentes preserven los invariantes.
11. Las comprobaciones específicas sean reproducibles y permitan verificar el estado posterior.
12. La implementación disponga de evidencia técnica suficiente para acreditar sus garantías en PostgreSQL 17.11.

**Prioridad:** corrección técnica, cobertura integral, fidelidad al modelo, robustez transaccional, eficiencia, mantenibilidad y verificabilidad.

### Respuesta

GPT-6 preparó inicialmente dos archivos SQL para incorporar las garantías de integridad avanzada al modelo físico de Universidad Horizonte en PostgreSQL 17.11, tomando como referencia las 26 relaciones, 135 atributos y 20 reglas de negocio del modelo corregido.

Se entregaron `sql/05_integridad_avanzada.sql`, con funciones PL/pgSQL, triggers, auditoría de cambios, comprobaciones contextuales e históricas, validaciones diferibles y mecanismos de sincronización transaccional; y `pruebas/03_pruebas_integridad_avanzada.sql`, con escenarios positivos, negativos, temporales, históricos y de operaciones compuestas, además de instrucciones para comprobar concurrencia mediante sesiones independientes.

Los mecanismos se plantearon sobre las estructuras y restricciones declarativas existentes, sin incorporar nuevas relaciones ni atributos. Su alcance fue preservar la integridad entre relaciones, la trayectoria académica, los requisitos curriculares, las ventanas operativas, la oferta y los horarios, la capacidad, las solicitudes, los estados y los historiales. No se desarrollaron los procesos funcionales completos G03-P01, G03-P02 ni G03-P03.

### Verificación posterior

El estudiante examinó la primera implementación y detectó posibles errores y omisiones que impedían aceptarla directamente. A partir de esa revisión, elaboró y proporcionó versiones propias corregidas de ambos archivos, que sustituyeron las entregas iniciales como base del trabajo posterior. Se reforzaron aspectos relacionados con la reconstrucción histórica, los controles temporales, la conservación de antecedentes, las operaciones compuestas, las modificaciones indirectas y la cobertura de pruebas.

Por solicitud expresa del estudiante, las versiones corregidas fueron sometidas a revisiones adicionales de correspondencia con el caso original de Universidad Horizonte, sus aclaraciones, el modelo corregido y las consignas general y específica del Grupo 03. También se utilizó ChatGPT Work para realizar una auditoría estática más amplia y preparar nuevas versiones corregidas de los archivos. La revisión posterior permitió identificar y ajustar casos de prueba con referencias o condiciones de preparación inadecuadas, así como comprobaciones históricas y de integridad que requerían mayor precisión.

El estudiante aprobó expresamente dos decisiones adicionales: exigir una evaluación motivada correspondiente al mismo instante efectivo cuando se omite a un candidato anterior en lista de espera, y conservar un instante efectivo compartido para representar el retiro y la nueva adjudicación de un cambio de grupo dentro de una misma transacción. Ambas decisiones se incorporaron a los mecanismos y a sus comprobaciones correspondientes.

**Resultado de la validación:** los archivos fueron corregidos mediante las revisiones solicitadas y las decisiones aprobadas por el estudiante, y posteriormente examinados por inspección técnica y documental. El estudiante comunicó su incorporación manual.&#x20;
