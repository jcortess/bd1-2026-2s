# Laboratorio 3 — Grupo 08

¡Hola! Bienvenidos al repositorio del **Grupo 08** para el Laboratorio 3 del curso IC-4301 · Bases de Datos I.

## 1. Descripción del proceso implementado

### Proceso de negocio de Envíos Conecta

Para este laboratorio se utilizará el proceso de registro de clientes, participantes (remitentes y destinatarios), sus medios de contacto, direcciones habituales y solicitudes de servicio de los clientes. Este proceso se centra en la gestión de las formas de contacto de los clientes y participantes de los servicios de envío.

Los participantes pueden ser o no clientes y cuentan con sus propios medios de contacto. Un cliente que sea una organización puede tener varias personas de contacto, cada una con una o varias facultades y uno o varios medios de contacto.

### Alcance: qué tablas entran y qué queda fuera

Las tablas contempladas dentro del alcance son:

* `cliente`
* `participante`
* `contacto`
* `facultad_contacto`
* `direccion_habitual`
* `medio_contacto_cliente`
* `medio_contacto_contacto`
* `medio_contacto_participante`
* `solicitud`

Quedan fuera tablas como `envio`, `paquete` o `tarifa`, ya que corresponden a otros procesos del negocio que no forman parte del alcance definido para este laboratorio.

## 2. Matriz de trazabilidad

Notación: **PK** = clave primaria, **FK** = clave foránea, **UQ** = restricción UNIQUE. Todas las claves foráneas hacia `cliente` son compuestas `(tipo_id, numero_id)`.

| Relación lógica | Tabla física | PK | FK (acción referencial) | Restricciones relevantes | Justificación de cambios |
|---|---|---|---|---|---|
| CLIENTE | `cliente` | `(tipo_id, numero_id)` | n/a | `ck_cliente_tipo_id`, `ck_cliente_tipo_cliente`, `ck_cliente_condicion` (dominios cerrados); `ck_cliente_nombre_no_vacio`; todos los atributos `NOT NULL` | Dominios cerrados con `CHECK` (ver nota 2) |
| MEDIO_CONTACTO_CLIENTE (multivaluado) | `medio_contacto_cliente` | `(tipo_id, numero_id, tipo_medio, valor)` | `fk_medio_contacto_cliente_cliente` → `cliente`: `ON DELETE CASCADE` | `ck_medio_contacto_cliente_tipo`, `ck_medio_contacto_cliente_valor_no_vacio` | Dominio de `tipo_medio` cerrado (nota 2) |
| DIRECCION_HABITUAL (multivaluado) | `direccion_habitual` | `(tipo_id, numero_id, num_direccion)` | `fk_direccion_habitual_cliente` → `cliente`: `ON DELETE CASCADE` | `ck_direccion_habitual_num` (> 0), `ck_direccion_habitual_provincia`, textos no vacíos; `instrucciones_acceso` y `referencia_geografica` admiten `NULL` | Atributo compuesto `direccion` aplanado en columnas (nota 1); provincia cerrada (nota 2) |
| CONTACTO | `contacto` | `id_contacto` (IDENTITY) | `fk_contacto_cliente` → `cliente`: `ON DELETE RESTRICT` | `ck_contacto_nombre_no_vacio`; `tipo_id` y `numero_id` `NOT NULL` | Ninguno. Índice `idx_contacto_cliente` sobre la FK compuesta |
| FACULTAD_CONTACTO (multivaluado) | `facultad_contacto` | `(id_contacto, facultad)` | `fk_facultad_contacto_contacto` → `contacto`: `ON DELETE CASCADE` | `ck_facultad_contacto_facultad` | Dominio de `facultad` cerrado (nota 2) |
| MEDIO_CONTACTO_CONTACTO (multivaluado) | `medio_contacto_contacto` | `(id_contacto, tipo_medio, valor)` | `fk_medio_contacto_contacto_contacto` → `contacto`: `ON DELETE CASCADE` | `ck_medio_contacto_contacto_tipo`, `ck_medio_contacto_contacto_valor_no_vacio` | Mismo dominio de `tipo_medio` que las otras dos tablas de medios |
| SOLICITUD | `solicitud` | `id_solicitud` (IDENTITY) | `fk_solicitud_cliente` → `cliente`: `ON DELETE RESTRICT` | `ck_solicitud_periodo` (fin ≥ inicio), `ck_solicitud_provincia`, `ck_solicitud_nivel_servicio`, textos no vacíos; `observaciones` admite `NULL` | Atributos compuestos `lugar_recoleccion` y `periodo_previsto` aplanados (nota 1); dominios cerrados (nota 2) |
| PARTICIPANTE | `participante` | `id_participante` (IDENTITY) | `fk_participante_cliente` → `cliente`: `ON DELETE RESTRICT` (FK nullable) | `uq_participante_cliente` (UK1 del modelo), `ck_participante_cliente_completo`, textos no vacíos | `CHECK` adicional por la FK compuesta nullable (nota 3) |
| MEDIO_CONTACTO_PARTICIPANTE (multivaluado) | `medio_contacto_participante` | `(id_participante, tipo_medio, valor)` | `fk_medio_contacto_participante_participante` → `participante`: `ON DELETE CASCADE` | `ck_medio_contacto_participante_tipo`, `ck_medio_contacto_participante_valor_no_vacio` | Mismo dominio de `tipo_medio` |

### Notas sobre los cambios respecto al modelo lógico

1. **Atributos compuestos.** Se implementaron como columnas con prefijo (`lugar_recoleccion_provincia`, `periodo_previsto_inicio`, etc.), conservando los nombres de componentes del modelo. No se crearon tablas adicionales.
2. **Dominios cerrados.** El modelo define los atributos pero no sus valores. El equipo cerró con `CHECK` los dominios de `tipo_id`, `tipo_cliente`, `condicion_contractual`, `tipo_medio`, `facultad`, `provincia` y `nivel_servicio` para garantizar consistencia en la base de datos. Es una decisión de diseño que no cambia requisitos ni cardinalidades. `cantón` y `distrito` quedan como texto libre (ver Limitaciones).
3. **FK compuesta nullable en `participante`.** En PostgreSQL una FK compuesta con una sola columna `NULL` no se valida (`MATCH SIMPLE`). Se agregó `ck_participante_cliente_completo` para exigir que `tipo_id` y `numero_id` sean ambos `NULL` o ambos tengan valor, lo que refleja la regla implícita del modelo: un participante o es un cliente identificado o no lo es.
4. **Acciones referenciales.** `CASCADE` en las tablas de atributos multivaluados (no existen sin su dueño). `RESTRICT` en `contacto`, `solicitud` y `participante` (tienen identidad propia y no se borra al cliente con historial).
5. **Claves sustitutas.** `id_contacto`, `id_solicitud` e `id_participante` se generan con `GENERATED ALWAYS AS IDENTITY`, tal como están definidos en el modelo.
6. **`NOT NULL`.** Se respetó la obligatoriedad marcada en el modelo (NN / NULL).
7. **Índices adicionales.** `idx_solicitud_cliente` e `idx_contacto_cliente` sobre las FK compuestas, porque PostgreSQL no indexa automáticamente las claves foráneas y ninguna PK ni UNIQUE las cubre.

## 3. Instrucciones de ejecución

### 3.1 Entorno

- **Motor:** PostgreSQL 17.11 (contenedor Docker `bd1-semana09`, imagen `postgres:17`).
- **Usuario:** `bd1`.
- **Base de datos del laboratorio:** `lab3`, que debe estar **vacía** antes de ejecutar los scripts.
- **Cliente:** `psql`, ejecutado dentro del contenedor con `docker exec`.

La versión se verifica con:

```powershell
docker exec -it bd1-semana09 psql -U bd1 -d lab3 -c "SELECT version();"
```

### 3.2 Preparar el entorno

Levantar el contenedor (si está detenido) y crear la base vacía. Los comandos se ejecutan desde la carpeta `lab03/grupo-08`:

```powershell
docker start bd1-semana09
docker exec -it bd1-semana09 psql -U bd1 -d bd1 -c "CREATE DATABASE lab3;"
```

Si la base `lab3` ya existe y se necesita repetir desde cero, se elimina y se vuelve a crear. Este `DROP DATABASE` es un paso del procedimiento de trabajo y **no forma parte de los scripts entregados**:

```powershell
docker exec -it bd1-semana09 psql -U bd1 -d bd1 -c "DROP DATABASE IF EXISTS lab3;"
docker exec -it bd1-semana09 psql -U bd1 -d bd1 -c "CREATE DATABASE lab3;"
```

Los comandos de creación y eliminación se conectan a la base `bd1` porque PostgreSQL no permite borrar la base a la que se está conectado.

### 3.3 Ejecutar los scripts

Copiar los scripts al contenedor y ejecutarlos en el orden indicado por el enunciado:

```powershell
docker exec bd1-semana09 rm -rf /tmp/sql
docker cp sql bd1-semana09:/tmp/sql

docker exec -it bd1-semana09 psql -U bd1 -d lab3 -v ON_ERROR_STOP=1 -f /tmp/sql/01_esquema.sql
docker exec -it bd1-semana09 psql -U bd1 -d lab3 -v ON_ERROR_STOP=1 -f /tmp/sql/02_datos.sql
docker exec -it bd1-semana09 psql -U bd1 -d lab3 -v ON_ERROR_STOP=1 -f /tmp/sql/04_rutinas.sql
docker exec -it bd1-semana09 psql -U bd1 -d lab3 -f /tmp/sql/03_consultas.sql
docker exec -it bd1-semana09 psql -U bd1 -d lab3 -f /tmp/sql/05_pruebas.sql
```

| Orden | Script | Contenido |
|---|---|---|
| 1 | `01_esquema.sql` | Tablas, claves, restricciones e índices |
| 2 | `02_datos.sql` | Datos ficticios de prueba |
| 3 | `04_rutinas.sql` | Funciones y procedimiento almacenado |
| 4 | `03_consultas.sql` | Consultas de negocio |
| 5 | `05_pruebas.sql` | Pruebas de integridad, funciones y procedimiento |

Los scripts `01`, `02` y `04` se ejecutan con `ON_ERROR_STOP=1` para detenerse en el primer error. El script `05` se ejecuta sin esa opción porque contiene pruebas que deben ser rechazadas por la base de datos; esos rechazos se controlan dentro de bloques `DO ... EXCEPTION` y el resto de las pruebas continúa.

### 3.4 Verificación de la carga

Después de ejecutar `01`, `02` y `04`, dentro de `psql -U bd1 -d lab3`:

```sql
\dt
SELECT COUNT(*) FROM cliente;
SELECT COUNT(*) FROM solicitud;
SELECT fn_prioridad_solicitud(5);
```

Resultados esperados: 9 tablas, 6 clientes, 7 solicitudes y la prioridad `CRITICA`.

### 3.5 Repetir la ejecución

- Los scripts **no contienen sentencias `DROP`**: están diseñados para ejecutarse sobre una base vacía.
- Para repetir la ejecución hay que **recrear la base `lab3`** (sección 4.2). Los

## 4. Decisiones de diseño físico

### 4.1 Tipos de datos

| Tipo | Dónde se usa | Justificación |
|---|---|---|
| `VARCHAR(n)` | Identificaciones, nombres, textos con longitud acotada | Limita la longitud según el dato. Se usó `TEXT` solo en `observaciones`, que es de extensión libre |
| `INTEGER` con `GENERATED ALWAYS AS IDENTITY` | `id_contacto`, `id_solicitud`, `id_participante` | Es la forma estándar actual en PostgreSQL frente a `SERIAL`. `ALWAYS` impide asignar el ID a mano por error |
| `SMALLINT` | `num_direccion` | Es un consecutivo por cliente y nunca crece mucho |
| `DATE` | `solicitud.fecha` | Solo importa el día en que se hizo la solicitud |
| `TIMESTAMPTZ` | `periodo_previsto_inicio` y `periodo_previsto_fin` | Es un momento exacto de recolección. Con zona horaria evita ambigüedades al comparar o mostrar la hora |
| `BOOLEAN` | `direccion_habitual.activa` | Solo tiene dos estados |

Las longitudes de los `VARCHAR` son decisiones del equipo, porque el modelo lógico no las define.

### 4.2 Claves

- **Claves naturales compuestas:** `cliente` usa `(tipo_id, numero_id)`, tal como lo define el modelo, y las demás tablas la referencian con una FK compuesta.
- **Claves parciales:** `direccion_habitual.num_direccion` es un consecutivo por cliente. No es `IDENTITY`: el valor se asigna en el `INSERT` y se repite entre clientes distintos.
- **Claves sustitutas:** `contacto`, `solicitud` y `participante` tienen su propio identificador generado.
- **Tablas de atributos multivaluados:** la PK incluye todos los atributos del valor, de modo que un cliente puede tener varios medios del mismo tipo pero no el mismo medio repetido.

### 4.3 Dominios cerrados con `CHECK`

El modelo lógico define los atributos pero no sus valores. El equipo cerró estos dominios:

| Atributo | Valores permitidos |
|---|---|
| `cliente.tipo_id` | `CEDULA_FISICA`, `CEDULA_JURIDICA`, `DIMEX`, `PASAPORTE` |
| `cliente.tipo_cliente` | `PERSONA_FISICA`, `PERSONA_JURIDICA` |
| `cliente.condicion_contractual` | `SIN_CONTRATO`, `CONTRATO_ESTANDAR`, `CONTRATO_CORPORATIVO` |
| `tipo_medio` (3 tablas) | `TELEFONO`, `CORREO`, `WHATSAPP` |
| `facultad_contacto.facultad` | `SOLICITAR_SERVICIOS`, `RECIBIR_REPORTES`, `AUTORIZAR_CARGOS` |
| `provincia` (2 tablas) | Las 7 provincias de Costa Rica |
| `solicitud.nivel_servicio` | `ECONOMICO`, `ESTANDAR`, `EXPRESS`, `MISMO_DIA` |

Se prefirió `CHECK` sobre `ENUM` o una tabla catálogo porque las listas son cortas y estables, no agrega tablas al subconjunto y los mensajes de error nombran la restricción violada. El costo es que agregar un valor exige modificar la restricción con `ALTER TABLE`.

Otros `CHECK`:
- Coherencia entre columnas: `periodo_previsto_fin >= periodo_previsto_inicio`.
- Rango: `num_direccion > 0`.
- Texto no vacío en nombres, valores de contacto, destino y señas, porque `NOT NULL` no impide cadenas vacías.
- `ck_participante_cliente_completo`, que exige que `tipo_id` y `numero_id` sean ambos `NULL` o ambos tengan valor.

### 4.4 Nulabilidad

Todo atributo es `NOT NULL` salvo los que el modelo marca como opcionales: `direccion_habitual.instrucciones_acceso` y `referencia_geografica`, `solicitud.observaciones` y `participante.tipo_id` y `numero_id` (un participante puede no ser cliente).

### 4.5 Acciones referenciales

- **`ON DELETE CASCADE`:** `medio_contacto_cliente`, `direccion_habitual`, `facultad_contacto`, `medio_contacto_contacto` y `medio_contacto_participante`. Son atributos multivaluados que no existen sin su dueño.
- **`ON DELETE RESTRICT`:** `contacto`, `solicitud` y `participante`. Tienen identidad propia y no se debe borrar un cliente con historial.
- **`ON UPDATE CASCADE`** en todas, para que un cambio de identificación se propague.

### 4.6 `DEFAULT`

El esquema no define valores por defecto, porque el modelo no establece ninguno. Los valores de `activa`, `fecha` y demás se indican siempre en el `INSERT`.

### 4.7 Índices adicionales

| Índice | Columnas | Propósito |
|---|---|---|
| `idx_solicitud_cliente` | `solicitud (tipo_id, numero_id)` | PostgreSQL no indexa automáticamente las FK. Acelera "solicitudes de un cliente" (consultas C1 a C3 y `fn_solicitudes_cliente`) |
| `idx_contacto_cliente` | `contacto (tipo_id, numero_id)` | La PK de `contacto` es solo `id_contacto`, así que la FK compuesta no tenía índice. Acelera "contactos de un cliente" (consulta C5) |

No se crearon índices sobre las demás FK, porque las PK compuestas de las tablas multivaluadas ya empiezan por la columna de referencia, y el `UNIQUE` de `participante` cubre la suya.

### 4.8 Datos de prueba

`02_datos.sql` contiene datos ficticios, sin información personal real:

| Tabla | Filas |
|---|---|
| `cliente` | 6 |
| `medio_contacto_cliente` | 7 |
| `direccion_habitual` | 6 |
| `contacto` | 4 |
| `facultad_contacto` | 6 |
| `medio_contacto_contacto` | 5 |
| `solicitud` | 7 |
| `participante` | 4 |
| `medio_contacto_participante` | 3 |

**Por qué es suficiente:**
- Cubre los 4 tipos de identificación, los 2 tipos de cliente y las 3 condiciones contractuales.
- Hay clientes con 0, 1 y varias direcciones, y con 0, 1 y varias solicitudes, así que `INNER JOIN` y `LEFT JOIN` dan resultados distintos.
- Incluye los 4 niveles de servicio, solicitudes con y sin `observaciones`, y una dirección inactiva.
- Hay contactos con una y con varias facultades.
- Hay participantes que son clientes y otros que no, lo que ejercita las columnas `NULL`.
- Permite predecir a mano el resultado de cada consulta y de cada función.

## 5. Justificación de las rutinas

### 5.1. `fn_solicitudes_cliente`

Esta función permite consultar las solicitudes asociadas a un cliente mediante su identificación, con la posibilidad de establecer un rango de fechas. Se implementó para centralizar la consulta y la validación de existencia del cliente. Esta última permite distinguir entre un cliente inexistente y uno que existe, pero todavía no tiene solicitudes registradas. Los parámetros de fecha opcionales permiten reutilizar la función para consultas generales o períodos específicos sin duplicar instrucciones SQL.

### 5.2. `fn_prioridad_solicitud`

Esta función determina la prioridad de una solicitud a partir de su nivel de servicio y la condición contractual del cliente. Se implementó para centralizar las reglas de clasificación y evitar que estas tengan que repetirse en diferentes consultas o procesos. El uso de `CASE` permite establecer un orden explícito de evaluación, necesario porque algunas condiciones tienen precedencia sobre otras. Además, se valida que la solicitud exista antes de determinar su prioridad.

### 5.3. `sp_registrar_contacto`

Este procedimiento permite registrar un contacto asociado a un cliente, incluyendo su facultad y medio de contacto inicial. Se implementó para agrupar las inserciones necesarias en las tres tablas involucradas y aplicar la regla de negocio RN-02, que establece que únicamente las personas jurídicas pueden tener contactos registrados. Al realizar las operaciones dentro de una misma transacción, se evita que un error deje información parcialmente registrada.

### 5.4. `fn_reporte_prioridades`

Esta función genera un reporte con el identificador de cada solicitud, el nombre del cliente y la prioridad correspondiente. Su implementación utiliza un cursor explícito para recorrer las solicitudes y procesarlas individualmente, reutilizando `fn_prioridad_solicitud` para determinar cada prioridad.

El cursor se incorpora como una técnica de procesamiento procedural que permite ejecutar operaciones para cada registro. Sin embargo, para este caso también es posible obtener el mismo resultado mediante una consulta basada en conjuntos, utilizando las condiciones de clasificación directamente en un `CASE`. Esta alternativa es más sencilla y normalmente más eficiente, por lo que el cursor se utiliza principalmente con fines didácticos.

## 6. Videos de la defensa individual
| Integrante | Enlace |
|---|---|
|Eddy Guiltres Rivas|---|
|Gherlan Cerdas|---|