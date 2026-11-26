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
