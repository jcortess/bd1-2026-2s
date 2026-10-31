# Diseño físico previsto, diccionario y trazabilidad

## Fuentes y estado

Fuente estructural: Modelo-Relacional-11.pdf, secciones 3 y 4; Diccionario-8.pdf, las cinco relaciones; Matriz-de-Trazabilidad-9.pdf, RN-01/RN-02 y correspondencia final. Véase el [fragmento lógico](../modelo/fragmento-modelo-logico.md). Este documento especifica el DDL futuro; no demuestra su ejecución.

## Decisiones físicas adicionales

- DF-01: nombres snake_case en minúscula sin comillas. Todas las claves simples y sus FK usarán bigint, con valores asignados explícitamente para reproducir las pruebas. No se presume autoincremento ni se cambia la identidad del negocio.
- DF-02: textos en text; valores presentes no vacíos ni solo espacios. No se imponen longitudes, formatos nacionales ni catálogos cerrados de documentos no confirmados. Comparación de unicidad exacta, sin normalización automática de mayúsculas o espacios.
- DF-03: fechas de vigencia en timestamp with time zone; entradas y ejemplos con desplazamiento explícito -06:00 y pruebas basadas en instantes fijos. No se añade una columna de zona. La vigencia conserva DL-01.
- DF-04: sin DEFAULT de negocio ni índices adicionales inicialmente; no hay valor implícito justificado ni carga medida que justifique duplicar índices de claves. Referencias con ON DELETE RESTRICT y ON UPDATE RESTRICT para conservar identidad e historial. Esto no impide que un usuario con escritura directa elimine filas no referenciadas; no equivale a seguridad global.

Estas son decisiones del laboratorio, no exigencias nuevas del caso ni correcciones ordenadas por el profesor.

## Diccionario de los 19 atributos

O = obligatorio; C = condicional u opcional. Los ejemplos son ficticios, no datos personales reales. La unicidad y las condiciones colectivas se precisan después de la tabla.

| Tabla.atributo | Significado en el negocio | Tipo previsto | Presencia y clave | Ejemplo ficticio |
|---|---|---|---|---|
| persona.id_persona | Identidad estable de quien puede ser cliente físico o representante | bigint | O, PK | 101 |
| persona.tipo_identificacion | Clase de documento que da contexto al valor identificador | text | O, candidata conjunta | Documento de prueba |
| persona.identificacion | Valor del documento dentro de su clase, no un dato numérico para cálculos | text | O, candidata conjunta | DOC-FICT-001 |
| persona.nombre | Nombre con que se identifica a la persona en las operaciones | text | O, no único | Ana Ejemplo |
| cliente.id_cliente | Identidad del participante responsable de la relación comercial | bigint | O, PK | 501 |
| cliente.tipo_cliente | Distingue persona física de organización y determina sus datos exigidos | text | O, Física u Organización | Organización |
| cliente.id_persona | Persona que constituye al cliente físico; no representa a una organización | bigint | C, FK única si presente | 101 en un cliente físico |
| cliente.identificacion_organizacion | Identificador propio de la organización cliente | text | C, única si presente | ORG-FICT-001 |
| cliente.razon_social | Denominación de la organización responsable | text | C, no única | Constructora Ejemplo Ficticia |
| cliente.direccion | Ubicación de contacto del cliente | text | O | Dirección de prueba A |
| autorizacion.id_autorizacion | Identidad del otorgamiento con período y facultades propios | bigint | O, PK | 9001 |
| autorizacion.id_cliente | Organización que concede este otorgamiento | bigint | O, FK a cliente | 501 |
| autorizacion.id_persona | Persona que recibe las facultades de este otorgamiento | bigint | O, FK a persona | 101 |
| autorizacion.inicio_vigencia | Instante desde el que pueden utilizarse las facultades concedidas | timestamp with time zone | O, incluido | 2026-10-01 08:00:00-06:00 |
| autorizacion.fin_vigencia | Límite excluido; NULL significa sin fin establecido | timestamp with time zone | Opcional | 2026-11-01 08:00:00-06:00 |
| facultad.id_facultad | Identidad estable de una acción del catálogo administrable | bigint | O, PK | 11 |
| facultad.nombre | Nombre de la acción concedible, no rol del personal interno | text | O, candidata única | Reservar |
| autorizacion_facultad.id_autorizacion | Otorgamiento al que pertenece esta concesión de facultad | bigint | O, PK conjunta y FK | 9001 |
| autorizacion_facultad.id_facultad | Acción concedida por ese otorgamiento | bigint | O, PK conjunta y FK | 11 |

### Restricciones explícitas

1. Todos los textos presentes cumplen btrim(valor) distinto de cadena vacía. NULL solo donde se permite. No se valida autenticidad de documentos.
2. persona: UNIQUE(tipo_identificacion, identificacion); nombre no es único.
3. cliente: tipo obligatorio en {Física, Organización}. Física exige id_persona no nulo y ambos campos organizacionales nulos. Organización exige id_persona nulo, identificación organizacional y razón social no nulas. Dirección siempre obligatoria. UNIQUE(id_persona) y UNIQUE(identificacion_organizacion) sin convertir NULL en un valor identificador.
4. autorizacion: cliente y persona obligatorios y existentes; fin NULL o fin > inicio. No UNIQUE(cliente, persona). Tipo organización se valida en la operación, no mediante una FK ordinaria.
5. facultad: nombre obligatorio, no vacío y único; Reservar, Recibir y Devolver son ejemplos, no lista cerrada.
6. autorizacion_facultad: PK(id_autorizacion, id_facultad), ambas FK obligatorias. No se agrega un id artificial. El mínimo una facultad requiere el procedimiento y conserva el límite DL-05.

## Matriz lógica-física A1

| Relación lógica | Tabla física | PK | FK explícitas | Restricciones relevantes | Justificación de cambios |
|---|---|---|---|---|---|
| PERSONA | persona | id_persona | Ninguna | Identificación conjunta única; textos obligatorios | DF-01/02 concretan tipos y calidad sin añadir atributos |
| CLIENTE | cliente | id_cliente | id_persona → persona.id_persona | Dos tipos; nulidad condicional; unicidades opcionales | Conserva AS-01 y sus seis atributos; DF-01/02 |
| AUTORIZACION | autorizacion | id_autorizacion | id_cliente → cliente.id_cliente; id_persona → persona.id_persona | Fechas; referencias; organización y al menos una facultad en procedimiento | Conserva RN-01/02 y AS-02; DF-03 concreta instantes; DL-01 resuelve frontera |
| FACULTAD | facultad | id_facultad | Ninguna | Nombre único y obligatorio | Conserva catálogo AS-03; DF-01/02 |
| AUTORIZACION_FACULTAD | autorizacion_facultad | id_autorizacion, id_facultad | id_autorizacion → autorizacion.id_autorizacion; id_facultad → facultad.id_facultad | Pareja irrepetible y referencias obligatorias | Conserva asociación y clave compuesta; sin nueva identidad |

DF-04 aplica a las cinco FK del subconjunto. La matriz es una especificación, no verificación de restricciones ya creadas.

## Regla, mecanismo y prueba prevista

| Fuente o decisión | Mecanismo previsto | Prueba propuesta, todavía no ejecutada |
|---|---|---|
| Identidad PERSONA | UNIQUE compuesto | T-01: rechazar documento duplicado; permitir nombres iguales |
| AS-01 | CHECK de tipo y campos + FK + UNIQUE opcionales | T-02: aceptar ambos tipos válidos y rechazar mezclas o persona inexistente |
| RN-01, AS-02 | FK + procedimiento que verifica organización | T-03: aceptar organización y rechazar cliente físico sin filas nuevas |
| RN-02, AS-03 | PK asociativa y catálogo | T-04: rechazar facultad repetida o inexistente |
| Mínimo de facultades, DL-03 | Validación y escritura atómica | T-05: rechazar lista nula, vacía, con nulos o duplicados y comprobar ausencia de filas parciales |
| RN-02, DL-01/02 | CHECK de fechas + funciones por instante | T-06: fin inválido, inicio exacto, fin exacto, fecha nula y período abierto |
| DL-04 | Consulta DISTINCT y conteo de personas distintas | T-07: dos autorizaciones vigentes sin doble conteo |
| DL-05 | Separar controles y declarar límites | T-08: contrastar controles declarativos con condiciones exclusivas de la operación, sin afirmar seguridad global |

Los IDs T son planificación; se reconciliarán con los IDs definitivos de 05_pruebas.sql. Mínimo del laboratorio: tres casos válidos y tres rechazados, además de probar las rutinas.

## Verificación pendiente

Ejecutar DDL real, comprobar tipos, permisos y comportamiento de restricciones; revisar visualmente Mermaid; probar transacciones, consultas y límites temporales. No se afirma haber completado esas verificaciones.
