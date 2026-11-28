# Diccionario físico consolidado

Versión de consolidación 2.0, 28 de noviembre de 2026. Integra los bloques de Jason, Paula y Jean Carlos, con las 28 tablas físicas del esquema huellas: las 27 relaciones originales del modelo P1 y la ampliación compatibilidad_animal_hogar.

La implementación integrada fue instalada y validada en PostgreSQL 16.16 mediante sql/15_instalar_proyecto_completo.sql. Se conserva la documentación de catálogo de los bloques anteriores, originalmente obtenida en PostgreSQL 18.6, y se incorpora la documentación del bloque G05-P03.

Cada sección define la relación de todas sus filas. NN es obligatoriedad física; las condiciones adicionales están en la descripción, CHECK y triggers de la misma sección. Todos los tipos `huellas.*` se definen en los scripts 01/05. `texto_no_vacio` exige al menos un carácter no blanco; `instante` es `timestamptz` finito; `especie_animal` usa `^[A-Z][A-Z0-9_]*$`; `estado_solicitud` contiene los siete estados RN-18. Los instantes tienen precisión de microsegundos y se muestran en Costa Rica. NULL significa ausencia; no sustituir datos desconocidos por cero o cadena vacía. Los IDs generados admiten saltos al revertir transacciones.

Las FK usan `ON UPDATE NO ACTION ON DELETE NO ACTION`, salvo acción explícita mostrada en su definición; no hay cascadas destructivas nuevas. Una FK opcional con valor también exige referencia válida. UQ contextual compuesto es una superclave para referencia, no una nueva clave mínima cuando ya contiene una PK. El estado actual se obtiene de vistas, no de atributos duplicados en la solicitud o el animal. Los CHECK de categorías son restricciones reales; los ejemplos en prosa no amplían sus enumeraciones. Restricciones y triggers se incluyen literalmente para localizar cada condición.


## animal

Reglas: RN-01/03; S-01/S-14.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `codigo_interno` | Código estable del animal a lo largo de sus etapas. | `huellas.texto_no_vacio` | Sí | — | animal_pkey: PRIMARY KEY (codigo_interno) |
| `nombre` | Nombre actual del animal, si se conoce. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `especie` | Código común de especie; PERRO y GATO son ejemplos. | `huellas.especie_animal` | Sí | — | — |
| `sexo` | Sexo conocido. | `text` | No; ver condición | — | — |
| `color` | Color o patrón observado. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `tamano_aproximado` | Categoría de tamaño aproximado. | `text` | No; ver condición | — | — |
| `edad_estimada` | Edad entera en meses, no negativa. | `integer` | No; ver condición | — | — |
| `senas_particulares` | Rasgos descriptivos conocidos. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `numero_microchip` | Microchip vigente textual; conserva ceros iniciales y unicidad cuando existe. | `huellas.texto_no_vacio` | No; ver condición | — | animal_numero_microchip_key: UNIQUE (numero_microchip) |

Restricciones declarativas:

- `animal_codigo_interno_not_null`: `NOT NULL codigo_interno`.
- `animal_edad_estimada_check`: `CHECK ((edad_estimada >= 0))`.
- `animal_especie_not_null`: `NOT NULL especie`.
- `animal_numero_microchip_check`: `CHECK (((numero_microchip)::text = btrim((numero_microchip)::text)))`.
- `animal_numero_microchip_key`: `UNIQUE (numero_microchip)`.
- `animal_pkey`: `PRIMARY KEY (codigo_interno)`.
- `animal_sexo_check`: `CHECK ((sexo = ANY (ARRAY['HEMBRA'::text, 'MACHO'::text])))`.
- `animal_tamano_aproximado_check`: `CHECK ((tamano_aproximado = ANY (ARRAY['PEQUENO'::text, 'MEDIANO'::text, 'GRANDE'::text])))`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX animal_numero_microchip_key ON huellas.animal USING btree (numero_microchip)`.
- `CREATE UNIQUE INDEX animal_pkey ON huellas.animal USING btree (codigo_interno)`.

Mecanismos adicionales:

- `CREATE TRIGGER animal_historia BEFORE UPDATE ON huellas.animal FOR EACH ROW EXECUTE FUNCTION huellas._preservar_animal()`.
- `CREATE TRIGGER animal_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.animal FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## cambio_disponibilidad

Reglas: RN-14/15.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_cambio` | Identidad de la decisión de disponibilidad. | `bigint` | Sí | IDENTITY BY DEFAULT | cambio_disponibilidad_pkey: PRIMARY KEY (id_cambio) |
| `animal_codigo` | Código del animal al que pertenece el hecho. | `huellas.texto_no_vacio` | Sí | — | disponibilidad_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `ingreso_id` | Etapa exacta; las FK contextuales mantienen el mismo animal. | `bigint` | Sí | — | disponibilidad_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `fecha` | Instante real del hecho, ordenado por ID cuando coincide. | `huellas.instante` | Sí | — | — |
| `estado_disponibilidad` | HABILITADO o NO_DISPONIBLE; decisión atribuible por etapa. | `text` | Sí | — | — |
| `responsable_id` | Persona responsable del hecho/decisión. | `bigint` | Sí | — | cambio_disponibilidad_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |
| `participacion_responsable_id` | Participación de personal/voluntario vigente que respalda la atribución. | `bigint` | Sí | — | cambio_disponibilidad_participacion_responsable_id_fkey: FOREIGN KEY (participacion_responsable_id) REFERENCES huellas.participacion(id_participacion) |
| `observacion_general` | Fundamento general obligatorio de la disponibilidad. | `huellas.texto_no_vacio` | Sí | — | — |
| `valoracion_sanitaria` | Valoración humana utilizada; no deriva automáticamente de diagnósticos. | `huellas.texto_no_vacio` | Sí | — | — |

Restricciones declarativas:

- `cambio_disponibilidad_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `cambio_disponibilidad_estado_disponibilidad_check`: `CHECK ((estado_disponibilidad = ANY (ARRAY['HABILITADO'::text, 'NO_DISPONIBLE'::text])))`.
- `cambio_disponibilidad_estado_disponibilidad_not_null`: `NOT NULL estado_disponibilidad`.
- `cambio_disponibilidad_fecha_not_null`: `NOT NULL fecha`.
- `cambio_disponibilidad_id_cambio_check`: `CHECK ((id_cambio > 0))`.
- `cambio_disponibilidad_id_cambio_not_null`: `NOT NULL id_cambio`.
- `cambio_disponibilidad_ingreso_id_not_null`: `NOT NULL ingreso_id`.
- `cambio_disponibilidad_observacion_general_not_null`: `NOT NULL observacion_general`.
- `cambio_disponibilidad_participacion_responsable_id_fkey`: `FOREIGN KEY (participacion_responsable_id) REFERENCES huellas.participacion(id_participacion)`.
- `cambio_disponibilidad_participacion_responsable_id_not_null`: `NOT NULL participacion_responsable_id`.
- `cambio_disponibilidad_pkey`: `PRIMARY KEY (id_cambio)`.
- `cambio_disponibilidad_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `cambio_disponibilidad_responsable_id_not_null`: `NOT NULL responsable_id`.
- `cambio_disponibilidad_valoracion_sanitaria_not_null`: `NOT NULL valoracion_sanitaria`.
- `disponibilidad_ingreso_animal_fk`: `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX cambio_disponibilidad_pkey ON huellas.cambio_disponibilidad USING btree (id_cambio)`.
- `CREATE INDEX disponibilidad_contexto_fecha_idx ON huellas.cambio_disponibilidad USING btree (animal_codigo, ingreso_id, fecha DESC, id_cambio DESC)`.

Mecanismos adicionales:

- `CREATE TRIGGER disponibilidad_contexto BEFORE INSERT ON huellas.cambio_disponibilidad FOR EACH ROW EXECUTE FUNCTION huellas._validar_disponibilidad_paula()`.
- `CREATE TRIGGER disponibilidad_historia BEFORE DELETE OR UPDATE ON huellas.cambio_disponibilidad FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER disponibilidad_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.cambio_disponibilidad FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## compatibilidad_animal_hogar

Reglas: RN-19; AC-G05-P02-01/04.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_compatibilidad` | Identidad de la valoración individual animal–hogar–etapa. | `bigint` | Sí | IDENTITY BY DEFAULT | compatibilidad_animal_hogar_pkey: PRIMARY KEY (id_compatibilidad); compatibilidad_contexto_uq: UNIQUE (id_compatibilidad, solicitud_id, animal_codigo, ingreso_id) |
| `clave_operacion` | UUID aportado por quien ejecuta; único en cada relación para reconocer un reenvío confirmado. | `uuid` | Sí | — | compatibilidad_animal_hogar_clave_operacion_key: UNIQUE (clave_operacion) |
| `solicitud_id` | Solicitud/hogar al que pertenece el hecho. | `bigint` | Sí | — | compatibilidad_actividad_fk: FOREIGN KEY (actividad_contexto_id, solicitud_id) REFERENCES huellas.evento_solicitud(id_evento_solicitud, solicitud_id); compatibilidad_contexto_uq: UNIQUE (id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); compatibilidad_interes_fk: FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo) |
| `animal_codigo` | Código del animal al que pertenece el hecho. | `huellas.texto_no_vacio` | Sí | — | compatibilidad_contexto_uq: UNIQUE (id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); compatibilidad_ingreso_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo); compatibilidad_interes_fk: FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo) |
| `ingreso_id` | Etapa exacta; las FK contextuales mantienen el mismo animal. | `bigint` | Sí | — | compatibilidad_contexto_uq: UNIQUE (id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); compatibilidad_ingreso_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `fecha` | Instante real del hecho, ordenado por ID cuando coincide. | `huellas.instante` | Sí | — | — |
| `responsable_id` | Persona responsable del hecho/decisión. | `bigint` | Sí | — | compatibilidad_animal_hogar_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |
| `participacion_responsable_id` | Participación de personal/voluntario vigente que respalda la atribución. | `bigint` | Sí | — | compatibilidad_animal_hogar_participacion_responsable_id_fkey: FOREIGN KEY (participacion_responsable_id) REFERENCES huellas.participacion(id_participacion) |
| `resultado` | FAVORABLE, NO_FAVORABLE o PENDIENTE_INFORMACION. | `text` | Sí | — | — |
| `valoracion_hogar` | Valoración concreta de necesidades del animal frente al hogar de esta solicitud. | `huellas.texto_no_vacio` | Sí | — | — |
| `razon` | Fundamento obligatorio de decisiones/compatibilidad; NULL en actividades. | `huellas.texto_no_vacio` | Sí | — | — |
| `observaciones` | Constancia del hecho; requerida en revisiones y actividades, opcional en decisiones. | `huellas.texto_no_vacio` | Sí | — | — |
| `actividad_contexto_id` | Actividad previa opcional de la misma solicitud; no permite referir una decisión. | `bigint` | No; ver condición | — | compatibilidad_actividad_fk: FOREIGN KEY (actividad_contexto_id, solicitud_id) REFERENCES huellas.evento_solicitud(id_evento_solicitud, solicitud_id) |

Restricciones declarativas:

- `compatibilidad_actividad_fk`: `FOREIGN KEY (actividad_contexto_id, solicitud_id) REFERENCES huellas.evento_solicitud(id_evento_solicitud, solicitud_id)`.
- `compatibilidad_animal_hogar_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `compatibilidad_animal_hogar_clave_operacion_key`: `UNIQUE (clave_operacion)`.
- `compatibilidad_animal_hogar_clave_operacion_not_null`: `NOT NULL clave_operacion`.
- `compatibilidad_animal_hogar_fecha_not_null`: `NOT NULL fecha`.
- `compatibilidad_animal_hogar_id_compatibilidad_check`: `CHECK ((id_compatibilidad > 0))`.
- `compatibilidad_animal_hogar_id_compatibilidad_not_null`: `NOT NULL id_compatibilidad`.
- `compatibilidad_animal_hogar_ingreso_id_not_null`: `NOT NULL ingreso_id`.
- `compatibilidad_animal_hogar_observaciones_not_null`: `NOT NULL observaciones`.
- `compatibilidad_animal_hogar_participacion_responsable__not_null`: `NOT NULL participacion_responsable_id`.
- `compatibilidad_animal_hogar_participacion_responsable_id_fkey`: `FOREIGN KEY (participacion_responsable_id) REFERENCES huellas.participacion(id_participacion)`.
- `compatibilidad_animal_hogar_pkey`: `PRIMARY KEY (id_compatibilidad)`.
- `compatibilidad_animal_hogar_razon_not_null`: `NOT NULL razon`.
- `compatibilidad_animal_hogar_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `compatibilidad_animal_hogar_responsable_id_not_null`: `NOT NULL responsable_id`.
- `compatibilidad_animal_hogar_resultado_check`: `CHECK ((resultado = ANY (ARRAY['FAVORABLE'::text, 'NO_FAVORABLE'::text, 'PENDIENTE_INFORMACION'::text])))`.
- `compatibilidad_animal_hogar_resultado_not_null`: `NOT NULL resultado`.
- `compatibilidad_animal_hogar_solicitud_id_not_null`: `NOT NULL solicitud_id`.
- `compatibilidad_animal_hogar_valoracion_hogar_not_null`: `NOT NULL valoracion_hogar`.
- `compatibilidad_contexto_uq`: `UNIQUE (id_compatibilidad, solicitud_id, animal_codigo, ingreso_id)`.
- `compatibilidad_ingreso_fk`: `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo)`.
- `compatibilidad_interes_fk`: `FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX compatibilidad_animal_hogar_clave_operacion_key ON huellas.compatibilidad_animal_hogar USING btree (clave_operacion)`.
- `CREATE UNIQUE INDEX compatibilidad_animal_hogar_pkey ON huellas.compatibilidad_animal_hogar USING btree (id_compatibilidad)`.
- `CREATE UNIQUE INDEX compatibilidad_contexto_uq ON huellas.compatibilidad_animal_hogar USING btree (id_compatibilidad, solicitud_id, animal_codigo, ingreso_id)`.
- `CREATE INDEX compatibilidad_vigente_idx ON huellas.compatibilidad_animal_hogar USING btree (solicitud_id, animal_codigo, ingreso_id, fecha DESC, id_compatibilidad DESC)`.

Mecanismos adicionales:

- `CREATE TRIGGER compatibilidad_contexto BEFORE INSERT ON huellas.compatibilidad_animal_hogar FOR EACH ROW EXECUTE FUNCTION huellas._validar_compatibilidad_paula()`.
- `CREATE TRIGGER compatibilidad_historia BEFORE DELETE OR UPDATE ON huellas.compatibilidad_animal_hogar FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER compatibilidad_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.compatibilidad_animal_hogar FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## diagnostico

Reglas: RN-11.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_diagnostico` | Identidad del catálogo de diagnósticos. | `bigint` | Sí | IDENTITY BY DEFAULT | diagnostico_pkey: PRIMARY KEY (id_diagnostico) |
| `nombre_estandarizado` | Nombre estandarizado único, no vacío y sin espacios exteriores. | `huellas.texto_no_vacio` | Sí | — | diagnostico_nombre_estandarizado_key: UNIQUE (nombre_estandarizado) |

Restricciones declarativas:

- `diagnostico_id_diagnostico_check`: `CHECK ((id_diagnostico > 0))`.
- `diagnostico_id_diagnostico_not_null`: `NOT NULL id_diagnostico`.
- `diagnostico_nombre_estandarizado_check`: `CHECK (((nombre_estandarizado)::text = btrim((nombre_estandarizado)::text)))`.
- `diagnostico_nombre_estandarizado_key`: `UNIQUE (nombre_estandarizado)`.
- `diagnostico_nombre_estandarizado_not_null`: `NOT NULL nombre_estandarizado`.
- `diagnostico_pkey`: `PRIMARY KEY (id_diagnostico)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX diagnostico_nombre_estandarizado_key ON huellas.diagnostico USING btree (nombre_estandarizado)`.
- `CREATE UNIQUE INDEX diagnostico_pkey ON huellas.diagnostico USING btree (id_diagnostico)`.

Mecanismos adicionales:

- `CREATE TRIGGER diagnostico_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.diagnostico FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## diagnostico_revision

Reglas: RN-11/12.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `evaluacion_id` | Revisión veterinaria de origen. | `bigint` | Sí | — | diagnostico_revision_pkey: PRIMARY KEY (evaluacion_id, diagnostico_id); fk_diagnostico_revision_evaluacion: FOREIGN KEY (evaluacion_id, tipo_evaluacion) REFERENCES huellas.evaluacion_salud(id_evaluacion, tipo_evaluacion) |
| `tipo_evaluacion` | INICIAL o REVISION_VETERINARIA; en la hija es discriminador fijo. | `text` | Sí | 'REVISION_VETERINARIA'::text | fk_diagnostico_revision_evaluacion: FOREIGN KEY (evaluacion_id, tipo_evaluacion) REFERENCES huellas.evaluacion_salud(id_evaluacion, tipo_evaluacion) |
| `diagnostico_id` | Diagnóstico del catálogo en esa revisión. | `bigint` | Sí | — | diagnostico_revision_diagnostico_id_fkey: FOREIGN KEY (diagnostico_id) REFERENCES huellas.diagnostico(id_diagnostico); diagnostico_revision_pkey: PRIMARY KEY (evaluacion_id, diagnostico_id) |
| `estado_diagnostico` | PROVISIONAL, CONFIRMADO o DESCARTADO en esa revisión concreta. | `text` | Sí | — | — |

Restricciones declarativas:

- `diagnostico_revision_diagnostico_id_fkey`: `FOREIGN KEY (diagnostico_id) REFERENCES huellas.diagnostico(id_diagnostico)`.
- `diagnostico_revision_diagnostico_id_not_null`: `NOT NULL diagnostico_id`.
- `diagnostico_revision_estado_diagnostico_check`: `CHECK ((estado_diagnostico = ANY (ARRAY['PROVISIONAL'::text, 'CONFIRMADO'::text, 'DESCARTADO'::text])))`.
- `diagnostico_revision_estado_diagnostico_not_null`: `NOT NULL estado_diagnostico`.
- `diagnostico_revision_evaluacion_id_not_null`: `NOT NULL evaluacion_id`.
- `diagnostico_revision_pkey`: `PRIMARY KEY (evaluacion_id, diagnostico_id)`.
- `diagnostico_revision_tipo_evaluacion_check`: `CHECK ((tipo_evaluacion = 'REVISION_VETERINARIA'::text))`.
- `diagnostico_revision_tipo_evaluacion_not_null`: `NOT NULL tipo_evaluacion`.
- `fk_diagnostico_revision_evaluacion`: `FOREIGN KEY (evaluacion_id, tipo_evaluacion) REFERENCES huellas.evaluacion_salud(id_evaluacion, tipo_evaluacion)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX diagnostico_revision_catalogo_idx ON huellas.diagnostico_revision USING btree (diagnostico_id)`.
- `CREATE UNIQUE INDEX diagnostico_revision_pkey ON huellas.diagnostico_revision USING btree (evaluacion_id, diagnostico_id)`.

Mecanismos adicionales:

- `CREATE TRIGGER diagnostico_revision_historia BEFORE DELETE OR UPDATE ON huellas.diagnostico_revision FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER diagnostico_revision_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.diagnostico_revision FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## estancia

Reglas: RN-05/06/07/08/14; N-01.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_estancia` | Identidad del alojamiento histórico. | `bigint` | Sí | IDENTITY BY DEFAULT | estancia_pkey: PRIMARY KEY (id_estancia) |
| `animal_codigo` | Código del animal al que pertenece el hecho. | `huellas.texto_no_vacio` | Sí | — | estancia_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `ingreso_id` | Etapa exacta; las FK contextuales mantienen el mismo animal. | `bigint` | Sí | — | estancia_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `ubicacion_id` | Lugar/oferta del alojamiento o especie aceptada. | `bigint` | Sí | — | estancia_ubicacion_id_fkey: FOREIGN KEY (ubicacion_id) REFERENCES huellas.ubicacion(id_ubicacion) |
| `fecha_inicio_real` | Instante de llegada real. | `huellas.instante` | Sí | — | — |
| `fecha_fin_real` | Instante real de salida; NULL mientras siga alojado. | `huellas.instante` | No; ver condición | — | — |
| `fecha_inicio_prevista` | Inicio acordado; obligatorio en hogar temporal. | `huellas.instante` | No; ver condición | — | — |
| `fecha_fin_prevista` | Fin acordado; obligatorio en hogar temporal. | `huellas.instante` | No; ver condición | — | — |
| `condicion_especial` | Acuerdos especiales conocidos. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `condicion_alojamiento` | Condición declarada, requerida y comparada en área interna. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `actor_entrada_id` | Persona que registró la llegada. | `bigint` | Sí | — | estancia_actor_entrada_id_fkey: FOREIGN KEY (actor_entrada_id) REFERENCES huellas.persona(id_persona) |
| `actor_salida_id` | Persona que registró la salida; va junto a su fecha. | `bigint` | No; ver condición | — | estancia_actor_salida_id_fkey: FOREIGN KEY (actor_salida_id) REFERENCES huellas.persona(id_persona) |
| `aprobacion_hogar_id` | Participación que acredita aprobación previa del oferente. | `bigint` | No; ver condición | — | estancia_aprobacion_hogar_id_fkey: FOREIGN KEY (aprobacion_hogar_id) REFERENCES huellas.participacion(id_participacion) |
| `valoracion_sanitaria` | Valoración humana utilizada; no deriva automáticamente de diagnósticos. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `estancia_actor_entrada_id_fkey`: `FOREIGN KEY (actor_entrada_id) REFERENCES huellas.persona(id_persona)`.
- `estancia_actor_entrada_id_not_null`: `NOT NULL actor_entrada_id`.
- `estancia_actor_salida_id_fkey`: `FOREIGN KEY (actor_salida_id) REFERENCES huellas.persona(id_persona)`.
- `estancia_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `estancia_aprobacion_hogar_id_fkey`: `FOREIGN KEY (aprobacion_hogar_id) REFERENCES huellas.participacion(id_participacion)`.
- `estancia_cierre`: `CHECK (((fecha_fin_real IS NULL) = (actor_salida_id IS NULL)))`.
- `estancia_fecha_inicio_real_not_null`: `NOT NULL fecha_inicio_real`.
- `estancia_id_estancia_check`: `CHECK ((id_estancia > 0))`.
- `estancia_id_estancia_not_null`: `NOT NULL id_estancia`.
- `estancia_ingreso_animal_fk`: `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo)`.
- `estancia_ingreso_id_not_null`: `NOT NULL ingreso_id`.
- `estancia_no_solapa`: `EXCLUDE USING gist (((animal_codigo)::text) WITH =, tstzrange((fecha_inicio_real)::timestamp with time zone, (fecha_fin_real)::timestamp with time zone, '[)'::text) WITH &&)`.
- `estancia_periodo_previsto`: `CHECK ((((fecha_inicio_prevista IS NULL) = (fecha_fin_prevista IS NULL)) AND ((fecha_fin_prevista IS NULL) OR ((fecha_fin_prevista)::timestamp with time zone > (fecha_inicio_prevista)::timestamp with time zone))))`.
- `estancia_periodo_real`: `CHECK (((fecha_fin_real IS NULL) OR ((fecha_fin_real)::timestamp with time zone > (fecha_inicio_real)::timestamp with time zone)))`.
- `estancia_pkey`: `PRIMARY KEY (id_estancia)`.
- `estancia_ubicacion_id_fkey`: `FOREIGN KEY (ubicacion_id) REFERENCES huellas.ubicacion(id_ubicacion)`.
- `estancia_ubicacion_id_not_null`: `NOT NULL ubicacion_id`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX estancia_abierta_animal_idx ON huellas.estancia USING btree (animal_codigo) WHERE (fecha_fin_real IS NULL)`.
- `CREATE INDEX estancia_aprobacion_idx ON huellas.estancia USING btree (aprobacion_hogar_id) WHERE (aprobacion_hogar_id IS NOT NULL)`.
- `CREATE INDEX estancia_ingreso_idx ON huellas.estancia USING btree (ingreso_id)`.
- `CREATE INDEX estancia_no_solapa ON huellas.estancia USING gist (((animal_codigo)::text), tstzrange((fecha_inicio_real)::timestamp with time zone, (fecha_fin_real)::timestamp with time zone, '[)'::text))`.
- `CREATE UNIQUE INDEX estancia_pkey ON huellas.estancia USING btree (id_estancia)`.
- `CREATE INDEX estancia_ubicacion_inicio_idx ON huellas.estancia USING btree (ubicacion_id, fecha_inicio_real)`.

Mecanismos adicionales:

Sin trigger propio; se mantienen las restricciones declarativas y los permisos descritos en el proceso.

## evaluacion_salud

Reglas: RN-10; S-02.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_evaluacion` | Identidad de evaluación inicial o revisión. | `bigint` | Sí | IDENTITY BY DEFAULT | evaluacion_salud_pkey: PRIMARY KEY (id_evaluacion); uq_evaluacion_id_tipo: UNIQUE (id_evaluacion, tipo_evaluacion) |
| `animal_codigo` | Código del animal al que pertenece el hecho. | `huellas.texto_no_vacio` | Sí | — | evaluacion_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `ingreso_id` | Etapa exacta; las FK contextuales mantienen el mismo animal. | `bigint` | Sí | — | evaluacion_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `tipo_evaluacion` | INICIAL o REVISION_VETERINARIA; en la hija es discriminador fijo. | `text` | Sí | — | uq_evaluacion_id_tipo: UNIQUE (id_evaluacion, tipo_evaluacion) |
| `fecha_evaluacion` | Instante real dentro de su etapa. | `huellas.instante` | Sí | — | — |
| `veterinario_id` | Profesional; requerido en revisión y opcional en inicial. | `bigint` | No; ver condición | — | evaluacion_salud_veterinario_id_fkey: FOREIGN KEY (veterinario_id) REFERENCES huellas.persona(id_persona) |
| `registro_veterinario_id` | Participación VETERINARIO/REGISTRADO vigente del profesional en la evaluación. | `bigint` | No; ver condición | — | evaluacion_salud_registro_veterinario_id_fkey: FOREIGN KEY (registro_veterinario_id) REFERENCES huellas.participacion(id_participacion) |
| `motivo` | Motivo clínico; requerido para revisión efectuada. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `observaciones` | Constancia del hecho; requerida en revisiones y actividades, opcional en decisiones. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `peso` | Peso en kg, numeric(7,3), positivo y finito; requerido en revisión. | `numeric(7,3)` | No; ver condición | — | — |
| `recomendaciones` | Recomendación clínica, requerida en revisión; puede declarar que no hay recomendaciones adicionales. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `chk_revision_campos`: `CHECK (((tipo_evaluacion <> 'REVISION_VETERINARIA'::text) OR ((veterinario_id IS NOT NULL) AND (registro_veterinario_id IS NOT NULL) AND (motivo IS NOT NULL) AND (observaciones IS NOT NULL) AND (peso IS NOT NULL) AND (recomendaciones IS NOT NULL))))`.
- `evaluacion_ingreso_animal_fk`: `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo)`.
- `evaluacion_inicial_paula`: `TRIGGER DEFERRABLE INITIALLY DEFERRED`.
- `evaluacion_registro_par`: `CHECK (((veterinario_id IS NULL) = (registro_veterinario_id IS NULL)))`.
- `evaluacion_salud_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `evaluacion_salud_fecha_evaluacion_not_null`: `NOT NULL fecha_evaluacion`.
- `evaluacion_salud_id_evaluacion_check`: `CHECK ((id_evaluacion > 0))`.
- `evaluacion_salud_id_evaluacion_not_null`: `NOT NULL id_evaluacion`.
- `evaluacion_salud_ingreso_id_not_null`: `NOT NULL ingreso_id`.
- `evaluacion_salud_peso_check`: `CHECK (((peso > (0)::numeric) AND (peso < 'Infinity'::numeric)))`.
- `evaluacion_salud_pkey`: `PRIMARY KEY (id_evaluacion)`.
- `evaluacion_salud_registro_veterinario_id_fkey`: `FOREIGN KEY (registro_veterinario_id) REFERENCES huellas.participacion(id_participacion)`.
- `evaluacion_salud_tipo_evaluacion_check`: `CHECK ((tipo_evaluacion = ANY (ARRAY['INICIAL'::text, 'REVISION_VETERINARIA'::text])))`.
- `evaluacion_salud_tipo_evaluacion_not_null`: `NOT NULL tipo_evaluacion`.
- `evaluacion_salud_veterinario_id_fkey`: `FOREIGN KEY (veterinario_id) REFERENCES huellas.persona(id_persona)`.
- `uq_evaluacion_id_tipo`: `UNIQUE (id_evaluacion, tipo_evaluacion)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX evaluacion_animal_fecha_idx ON huellas.evaluacion_salud USING btree (animal_codigo, fecha_evaluacion)`.
- `CREATE UNIQUE INDEX evaluacion_inicial_etapa_uq ON huellas.evaluacion_salud USING btree (ingreso_id) WHERE (tipo_evaluacion = 'INICIAL'::text)`.
- `CREATE INDEX evaluacion_registro_idx ON huellas.evaluacion_salud USING btree (registro_veterinario_id)`.
- `CREATE UNIQUE INDEX evaluacion_salud_pkey ON huellas.evaluacion_salud USING btree (id_evaluacion)`.
- `CREATE UNIQUE INDEX uq_evaluacion_id_tipo ON huellas.evaluacion_salud USING btree (id_evaluacion, tipo_evaluacion)`.

Mecanismos adicionales:

- `CREATE TRIGGER evaluacion_contexto BEFORE INSERT ON huellas.evaluacion_salud FOR EACH ROW EXECUTE FUNCTION huellas._validar_evaluacion_paula()`.
- `CREATE TRIGGER evaluacion_historia BEFORE DELETE OR UPDATE ON huellas.evaluacion_salud FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE CONSTRAINT TRIGGER evaluacion_inicial_paula AFTER INSERT ON huellas.evaluacion_salud DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION huellas._exigir_inicial_paula()`.
- `CREATE TRIGGER evaluacion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.evaluacion_salud FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## evento_solicitud

Reglas: RN-17/18.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_evento_solicitud` | Identidad de actividad, recepción o decisión conservada. | `bigint` | Sí | IDENTITY BY DEFAULT | evento_contexto_uq: UNIQUE (id_evento_solicitud, solicitud_id); evento_solicitud_pkey: PRIMARY KEY (id_evento_solicitud) |
| `clave_operacion` | UUID aportado por quien ejecuta; único en cada relación para reconocer un reenvío confirmado. | `uuid` | Sí | — | evento_solicitud_clave_operacion_key: UNIQUE (clave_operacion) |
| `solicitud_id` | Solicitud/hogar al que pertenece el hecho. | `bigint` | Sí | — | evento_antecedente_fk: FOREIGN KEY (antecedente_decision_id, solicitud_id) REFERENCES huellas.evento_solicitud(id_evento_solicitud, solicitud_id); evento_contexto_uq: UNIQUE (id_evento_solicitud, solicitud_id); evento_solicitud_solicitud_id_fkey: FOREIGN KEY (solicitud_id) REFERENCES huellas.solicitud_adopcion(id_solicitud) |
| `fecha` | Instante real del hecho, ordenado por ID cuando coincide. | `huellas.instante` | Sí | — | — |
| `tipo_evento` | RECEPCION, ENTREVISTA, VISITA_HOGAR, INFORMACION, OTRA_ACTIVIDAD o DECISION. | `text` | Sí | — | — |
| `responsable_id` | Persona responsable del hecho/decisión. | `bigint` | Sí | — | evento_solicitud_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |
| `participacion_responsable_id` | Participación de personal/voluntario vigente que respalda la atribución. | `bigint` | Sí | — | evento_solicitud_participacion_responsable_id_fkey: FOREIGN KEY (participacion_responsable_id) REFERENCES huellas.participacion(id_participacion) |
| `resultado_actividad` | Resultado descriptivo obligatorio de actividad; NULL en recepción/decisión. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `estado_resultante` | Estado general solo en RECEPCION/DECISION; dominio de los siete estados RN-18. | `huellas.estado_solicitud` | No; ver condición | — | — |
| `observaciones` | Constancia del hecho; requerida en revisiones y actividades, opcional en decisiones. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `razon` | Fundamento obligatorio de decisiones/compatibilidad; NULL en actividades. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `antecedente_decision_id` | última decisión observada, de la misma solicitud; obligatoria en DECISION por trigger. | `bigint` | No; ver condición | — | evento_antecedente_fk: FOREIGN KEY (antecedente_decision_id, solicitud_id) REFERENCES huellas.evento_solicitud(id_evento_solicitud, solicitud_id) |

Restricciones declarativas:

- `evento_antecedente_fk`: `FOREIGN KEY (antecedente_decision_id, solicitud_id) REFERENCES huellas.evento_solicitud(id_evento_solicitud, solicitud_id)`.
- `evento_contenido`: `CHECK ((((tipo_evento = ANY (ARRAY['RECEPCION'::text, 'DECISION'::text])) AND (estado_resultante IS NOT NULL) AND (razon IS NOT NULL) AND (resultado_actividad IS NULL)) OR ((tipo_evento <> ALL (ARRAY['RECEPCION'::text, 'DECISION'::text])) AND (resultado_actividad IS NOT NULL) AND (observaciones IS NOT NULL) AND (estado_resultante IS NULL) AND (razon IS NULL) AND (antecedente_decision_id IS NULL))))`.
- `evento_contexto_uq`: `UNIQUE (id_evento_solicitud, solicitud_id)`.
- `evento_recepcion`: `CHECK (((tipo_evento <> 'RECEPCION'::text) OR (((estado_resultante)::text = 'RECIBIDA'::text) AND (antecedente_decision_id IS NULL))))`.
- `evento_solicitud_clave_operacion_key`: `UNIQUE (clave_operacion)`.
- `evento_solicitud_clave_operacion_not_null`: `NOT NULL clave_operacion`.
- `evento_solicitud_fecha_not_null`: `NOT NULL fecha`.
- `evento_solicitud_id_evento_solicitud_check`: `CHECK ((id_evento_solicitud > 0))`.
- `evento_solicitud_id_evento_solicitud_not_null`: `NOT NULL id_evento_solicitud`.
- `evento_solicitud_participacion_responsable_id_fkey`: `FOREIGN KEY (participacion_responsable_id) REFERENCES huellas.participacion(id_participacion)`.
- `evento_solicitud_participacion_responsable_id_not_null`: `NOT NULL participacion_responsable_id`.
- `evento_solicitud_pkey`: `PRIMARY KEY (id_evento_solicitud)`.
- `evento_solicitud_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `evento_solicitud_responsable_id_not_null`: `NOT NULL responsable_id`.
- `evento_solicitud_solicitud_id_fkey`: `FOREIGN KEY (solicitud_id) REFERENCES huellas.solicitud_adopcion(id_solicitud)`.
- `evento_solicitud_solicitud_id_not_null`: `NOT NULL solicitud_id`.
- `evento_solicitud_tipo_evento_check`: `CHECK ((tipo_evento = ANY (ARRAY['RECEPCION'::text, 'ENTREVISTA'::text, 'VISITA_HOGAR'::text, 'INFORMACION'::text, 'OTRA_ACTIVIDAD'::text, 'DECISION'::text])))`.
- `evento_solicitud_tipo_evento_not_null`: `NOT NULL tipo_evento`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX evento_contexto_uq ON huellas.evento_solicitud USING btree (id_evento_solicitud, solicitud_id)`.
- `CREATE INDEX evento_historia_idx ON huellas.evento_solicitud USING btree (solicitud_id, fecha, id_evento_solicitud)`.
- `CREATE UNIQUE INDEX evento_solicitud_clave_operacion_key ON huellas.evento_solicitud USING btree (clave_operacion)`.
- `CREATE UNIQUE INDEX evento_solicitud_pkey ON huellas.evento_solicitud USING btree (id_evento_solicitud)`.
- `CREATE UNIQUE INDEX evento_una_recepcion_uq ON huellas.evento_solicitud USING btree (solicitud_id) WHERE (tipo_evento = 'RECEPCION'::text)`.

Mecanismos adicionales:

- `CREATE TRIGGER evento_contexto BEFORE INSERT ON huellas.evento_solicitud FOR EACH ROW EXECUTE FUNCTION huellas._validar_evento_paula()`.
- `CREATE TRIGGER evento_historia BEFORE DELETE OR UPDATE ON huellas.evento_solicitud FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER evento_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.evento_solicitud FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## ingreso

Reglas: RN-01/02/04/10/23/25.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_ingreso` | Identidad de una etapa de ingreso. | `bigint` | Sí | IDENTITY BY DEFAULT | ingreso_animal_uq: UNIQUE (id_ingreso, animal_codigo); ingreso_pkey: PRIMARY KEY (id_ingreso) |
| `animal_codigo` | Código del animal al que pertenece el hecho. Debe coincidir con el animal de la adopción de origen cuando exista. | `huellas.texto_no_vacio` | Sí | — | ingreso_animal_codigo_fkey: FOREIGN KEY (animal_codigo) REFERENCES huellas.animal(codigo_interno); ingreso_animal_uq: UNIQUE (id_ingreso, animal_codigo); ingreso_adopcion_origen_fk: FOREIGN KEY (adopcion_origen_id, animal_codigo) REFERENCES huellas.adopcion(id_adopcion, animal_codigo) |
| `fecha_ingreso` | Inicio inclusivo de etapa. | `huellas.instante` | Sí | — | — |
| `lugar_ingreso` | Lugar de recepción del animal. | `huellas.texto_no_vacio` | Sí | — | — |
| `condicion_general` | Condición observada al ingreso. | `huellas.texto_no_vacio` | Sí | — | — |
| `circunstancia_ingreso` | Circunstancia que origina la etapa. | `text` | Sí | — | — |
| `detalle_circunstancia` | Detalle exigido para OTRA o regreso. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `propietario_anterior_id` | Persona propietaria conocida; no confiere derecho automático. | `bigint` | No; ver condición | — | ingreso_propietario_anterior_id_fkey: FOREIGN KEY (propietario_anterior_id) REFERENCES huellas.persona(id_persona) |
| `organizacion_origen_id` | Organización remesante, exclusiva de TRASLADO. | `bigint` | No; ver condición | — | ingreso_organizacion_origen_id_fkey: FOREIGN KEY (organizacion_origen_id) REFERENCES huellas.organizacion_externa(id_organizacion) |

| `adopcion_origen_id` | Adopción finalizada que origina una devolución o recuperación del mismo animal. | `bigint` | No; ver condición | — | ingreso_adopcion_origen_id_key: UNIQUE (adopcion_origen_id); ingreso_adopcion_origen_fk: FOREIGN KEY (adopcion_origen_id, animal_codigo) REFERENCES huellas.adopcion(id_adopcion, animal_codigo) |

| `receptor_devolucion_id` | Persona que recibió una devolución/recuperación; requerida en esos regresos. | `bigint` | No; ver condición | — | ingreso_receptor_devolucion_id_fkey: FOREIGN KEY (receptor_devolucion_id) REFERENCES huellas.persona(id_persona) |
| `fecha_cierre` | Fin exclusivo de la etapa, si terminó. | `huellas.instante` | No; ver condición | — | — |

Restricciones declarativas:

- `ingreso_adopcion_origen_id_check`: `CHECK ((adopcion_origen_id > 0))`.
- `ingreso_adopcion_origen_id_key`: `UNIQUE (adopcion_origen_id)`.
- `ingreso_animal_codigo_fkey`: `FOREIGN KEY (animal_codigo) REFERENCES huellas.animal(codigo_interno)`.
- `ingreso_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `ingreso_animal_uq`: `UNIQUE (id_ingreso, animal_codigo)`.
- `ingreso_circunstancia_ingreso_check`: `CHECK ((circunstancia_ingreso = ANY (ARRAY['RESCATE'::text, 'ENTREGA_VOLUNTARIA'::text, 'TRASLADO'::text, 'DEVOLUCION'::text, 'RECUPERACION'::text, 'OTRA'::text])))`.
- `ingreso_circunstancia_ingreso_not_null`: `NOT NULL circunstancia_ingreso`.
- `ingreso_condicion_general_not_null`: `NOT NULL condicion_general`.
- `ingreso_detalle`: `CHECK (((circunstancia_ingreso <> ALL (ARRAY['DEVOLUCION'::text, 'RECUPERACION'::text, 'OTRA'::text])) OR (detalle_circunstancia IS NOT NULL)))`.
- `ingreso_etapas_no_solapan`: `EXCLUDE USING gist (((animal_codigo)::text) WITH =, tstzrange((fecha_ingreso)::timestamp with time zone, (fecha_cierre)::timestamp with time zone, '[)'::text) WITH &&)`.
- `ingreso_fecha_ingreso_not_null`: `NOT NULL fecha_ingreso`.
- `ingreso_id_ingreso_check`: `CHECK ((id_ingreso > 0))`.
- `ingreso_id_ingreso_not_null`: `NOT NULL id_ingreso`.
- `ingreso_inicial_paula`: `TRIGGER DEFERRABLE INITIALLY DEFERRED`.
- `ingreso_lugar_ingreso_not_null`: `NOT NULL lugar_ingreso`.
- `ingreso_organizacion`: `CHECK (((circunstancia_ingreso = 'TRASLADO'::text) = (organizacion_origen_id IS NOT NULL)))`.
- `ingreso_organizacion_origen_id_fkey`: `FOREIGN KEY (organizacion_origen_id) REFERENCES huellas.organizacion_externa(id_organizacion)`.
- `ingreso_origen_adopcion`: `CHECK (((circunstancia_ingreso = ANY (ARRAY['DEVOLUCION'::text, 'RECUPERACION'::text])) = (adopcion_origen_id IS NOT NULL)))`.
- `ingreso_periodo`: `CHECK (((fecha_cierre IS NULL) OR ((fecha_cierre)::timestamp with time zone > (fecha_ingreso)::timestamp with time zone)))`.
- `ingreso_pkey`: `PRIMARY KEY (id_ingreso)`.
- `ingreso_propietario_anterior_id_fkey`: `FOREIGN KEY (propietario_anterior_id) REFERENCES huellas.persona(id_persona)`.
- `ingreso_receptor`: `CHECK (((circunstancia_ingreso = ANY (ARRAY['DEVOLUCION'::text, 'RECUPERACION'::text])) = (receptor_devolucion_id IS NOT NULL)))`.
- `ingreso_receptor_devolucion_id_fkey`: `FOREIGN KEY (receptor_devolucion_id) REFERENCES huellas.persona(id_persona)`.
- `ingreso_adopcion_origen_fk`: `FOREIGN KEY (adopcion_origen_id, animal_codigo) REFERENCES huellas.adopcion(id_adopcion, animal_codigo)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX ingreso_adopcion_origen_id_key ON huellas.ingreso USING btree (adopcion_origen_id)`.
- `CREATE UNIQUE INDEX ingreso_animal_uq ON huellas.ingreso USING btree (id_ingreso, animal_codigo)`.
- `CREATE INDEX ingreso_etapas_no_solapan ON huellas.ingreso USING gist (((animal_codigo)::text), tstzrange((fecha_ingreso)::timestamp with time zone, (fecha_cierre)::timestamp with time zone, '[)'::text))`.
- `CREATE UNIQUE INDEX ingreso_pkey ON huellas.ingreso USING btree (id_ingreso)`.

Mecanismos adicionales:

- `CREATE TRIGGER ingreso_historia BEFORE UPDATE ON huellas.ingreso FOR EACH ROW EXECUTE FUNCTION huellas._preservar_ingreso()`.
- `CREATE CONSTRAINT TRIGGER ingreso_inicial_paula AFTER INSERT OR UPDATE ON huellas.ingreso DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION huellas._exigir_inicial_paula()`.
- `CREATE TRIGGER ingreso_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.ingreso FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER zz_ingreso_contexto_paula BEFORE UPDATE ON huellas.ingreso FOR EACH ROW EXECUTE FUNCTION huellas._preservar_etapa_clinica_paula()`.
- `_validar_reingreso_jeank()`: valida que la adopción de origen exista, corresponda al mismo animal, se encuentre finalizada y que la circunstancia y fecha del nuevo ingreso sean compatibles con su finalización.
- El nuevo ingreso por devolución o recuperación requiere una evaluación inicial propia.
- Una devolución voluntaria no genera automáticamente una restricción para la persona adoptante.
- Evidencia de integración: PJ-09.


## medio_contacto

Reglas: RN-09; S-07.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_medio` | Identidad del medio de contacto. | `bigint` | Sí | IDENTITY BY DEFAULT | medio_contacto_pkey: PRIMARY KEY (id_medio) |
| `persona_id` | Persona titular del contacto o participación. | `bigint` | Sí | — | medio_contacto_persona_id_fkey: FOREIGN KEY (persona_id) REFERENCES huellas.persona(id_persona) |
| `tipo_medio` | Clase declarada del contacto; texto abierto (CORREO es ejemplo). | `huellas.texto_no_vacio` | Sí | — | — |
| `valor` | Dato conocido de contacto. | `huellas.texto_no_vacio` | Sí | — | — |

Restricciones declarativas:

- `medio_contacto_id_medio_check`: `CHECK ((id_medio > 0))`.
- `medio_contacto_id_medio_not_null`: `NOT NULL id_medio`.
- `medio_contacto_persona_id_fkey`: `FOREIGN KEY (persona_id) REFERENCES huellas.persona(id_persona)`.
- `medio_contacto_persona_id_not_null`: `NOT NULL persona_id`.
- `medio_contacto_pkey`: `PRIMARY KEY (id_medio)`.
- `medio_contacto_tipo_medio_not_null`: `NOT NULL tipo_medio`.
- `medio_contacto_valor_not_null`: `NOT NULL valor`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX medio_contacto_pkey ON huellas.medio_contacto USING btree (id_medio)`.

Mecanismos adicionales:

Sin trigger propio; se mantienen las restricciones declarativas y los permisos descritos en el proceso.

## organizacion_externa

Reglas: RN-04/25; S-09.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_organizacion` | Identidad de organización externa. | `bigint` | Sí | IDENTITY BY DEFAULT | organizacion_externa_pkey: PRIMARY KEY (id_organizacion) |
| `nombre_organizacion` | Nombre conocido; no identifica por sí solo. | `huellas.texto_no_vacio` | Sí | — | — |

Restricciones declarativas:

- `organizacion_externa_id_organizacion_check`: `CHECK ((id_organizacion > 0))`.
- `organizacion_externa_id_organizacion_not_null`: `NOT NULL id_organizacion`.
- `organizacion_externa_nombre_organizacion_not_null`: `NOT NULL nombre_organizacion`.
- `organizacion_externa_pkey`: `PRIMARY KEY (id_organizacion)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX organizacion_externa_pkey ON huellas.organizacion_externa USING btree (id_organizacion)`.

Mecanismos adicionales:

Sin trigger propio; se mantienen las restricciones declarativas y los permisos descritos en el proceso.

## participacion

Reglas: RN-07/09/10.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_participacion` | Identidad de un periodo/rol de participación. | `bigint` | Sí | IDENTITY BY DEFAULT | participacion_pkey: PRIMARY KEY (id_participacion) |
| `persona_id` | Persona titular del contacto o participación. | `bigint` | Sí | — | participacion_persona_id_fkey: FOREIGN KEY (persona_id) REFERENCES huellas.persona(id_persona) |
| `tipo_participacion` | Rol desempeñado en ese periodo. | `text` | Sí | — | — |
| `fecha_inicio` | Inicio inclusivo de participación. | `huellas.instante` | Sí | — | — |
| `fecha_fin` | Fin exclusivo; NULL expresa periodo abierto. | `huellas.instante` | No; ver condición | — | — |
| `requisitos` | Requisitos documentados de la participación. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `estado_aprobacion_registro` | Decisión de aprobación o registro del rol. | `text` | No; ver condición | — | — |
| `fecha_aprobacion_registro` | Instante de la decisión de aprobación/registro. | `huellas.instante` | No; ver condición | — | — |

Restricciones declarativas:

- `participacion_aprobacion`: `CHECK ((((tipo_participacion <> 'HOGAR_TEMPORAL'::text) OR ((estado_aprobacion_registro IS NOT NULL) AND (estado_aprobacion_registro <> 'REGISTRADO'::text))) AND ((fecha_aprobacion_registro IS NOT NULL) = COALESCE((estado_aprobacion_registro = ANY (ARRAY['APROBADO'::text, 'REGISTRADO'::text])), false)) AND ((fecha_fin IS NULL) OR ((fecha_aprobacion_registro)::timestamp with time zone < (fecha_fin)::timestamp with time zone))))`.
- `participacion_estado_aprobacion_registro_check`: `CHECK ((estado_aprobacion_registro = ANY (ARRAY['PENDIENTE'::text, 'APROBADO'::text, 'REGISTRADO'::text, 'RECHAZADO'::text])))`.
- `participacion_fecha_inicio_not_null`: `NOT NULL fecha_inicio`.
- `participacion_id_participacion_check`: `CHECK ((id_participacion > 0))`.
- `participacion_id_participacion_not_null`: `NOT NULL id_participacion`.
- `participacion_periodo`: `CHECK (((fecha_fin IS NULL) OR ((fecha_fin)::timestamp with time zone > (fecha_inicio)::timestamp with time zone)))`.
- `participacion_persona_id_fkey`: `FOREIGN KEY (persona_id) REFERENCES huellas.persona(id_persona)`.
- `participacion_persona_id_not_null`: `NOT NULL persona_id`.
- `participacion_pkey`: `PRIMARY KEY (id_participacion)`.
- `participacion_tipo_participacion_check`: `CHECK ((tipo_participacion = ANY (ARRAY['PERSONAL_PERMANENTE'::text, 'VOLUNTARIO'::text, 'VETERINARIO'::text, 'HOGAR_TEMPORAL'::text, 'SOLICITANTE'::text, 'ADOPTANTE'::text])))`.
- `participacion_tipo_participacion_not_null`: `NOT NULL tipo_participacion`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX participacion_oferente_idx ON huellas.participacion USING btree (persona_id, fecha_aprobacion_registro) WHERE ((tipo_participacion = 'HOGAR_TEMPORAL'::text) AND (estado_aprobacion_registro = 'APROBADO'::text))`.
- `CREATE UNIQUE INDEX participacion_pkey ON huellas.participacion USING btree (id_participacion)`.

Mecanismos adicionales:

- `CREATE TRIGGER participacion_contexto_paula BEFORE UPDATE ON huellas.participacion FOR EACH ROW EXECUTE FUNCTION huellas._preservar_registro_paula()`.
- `CREATE TRIGGER participacion_historia BEFORE UPDATE ON huellas.participacion FOR EACH ROW EXECUTE FUNCTION huellas._preservar_participacion()`.
- `CREATE TRIGGER participacion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.participacion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## persona

Reglas: RN-09; S-06/S-07.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_persona` | Identidad propia de la persona; RN-09, no RN-01. | `bigint` | Sí | IDENTITY BY DEFAULT | persona_pkey: PRIMARY KEY (id_persona) |
| `nombre_identificacion` | Nombre o identificación conocida; su ausencia no duplica la identidad. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `persona_id_persona_check`: `CHECK ((id_persona > 0))`.
- `persona_id_persona_not_null`: `NOT NULL id_persona`.
- `persona_pkey`: `PRIMARY KEY (id_persona)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX persona_pkey ON huellas.persona USING btree (id_persona)`.

Mecanismos adicionales:

Sin trigger propio; se mantienen las restricciones declarativas y los permisos descritos en el proceso.

## reporte

Reglas: RN-02; S-07.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_reporte` | Identidad del reporte. | `bigint` | Sí | IDENTITY BY DEFAULT | reporte_pkey: PRIMARY KEY (id_reporte) |
| `reportante_id` | Persona reportante si pudo identificarse (S-07). | `bigint` | No; ver condición | — | reporte_reportante_id_fkey: FOREIGN KEY (reportante_id) REFERENCES huellas.persona(id_persona) |
| `fecha_reporte` | Instante conocido; NULL si se desconoce. | `huellas.instante` | No; ver condición | — | — |
| `lugar_aproximado` | Descripción disponible del lugar reportado. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `situacion_observada` | Relato disponible de la situación de los animales. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `reporte_id_reporte_check`: `CHECK ((id_reporte > 0))`.
- `reporte_id_reporte_not_null`: `NOT NULL id_reporte`.
- `reporte_pkey`: `PRIMARY KEY (id_reporte)`.
- `reporte_reportante_id_fkey`: `FOREIGN KEY (reportante_id) REFERENCES huellas.persona(id_persona)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX reporte_pkey ON huellas.reporte USING btree (id_reporte)`.

Mecanismos adicionales:

- `CREATE TRIGGER reporte_fecha BEFORE INSERT OR UPDATE ON huellas.reporte FOR EACH ROW EXECUTE FUNCTION huellas._validar_fecha_reporte_paula()`.
- `CREATE TRIGGER reporte_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.reporte FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## reporte_animal

Reglas: RN-02.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `reporte_id` | Reporte asociado al animal identificado. | `bigint` | Sí | — | reporte_animal_pkey: PRIMARY KEY (reporte_id, animal_codigo); reporte_animal_reporte_id_fkey: FOREIGN KEY (reporte_id) REFERENCES huellas.reporte(id_reporte) |
| `animal_codigo` | Código del animal al que pertenece el hecho. | `huellas.texto_no_vacio` | Sí | — | reporte_animal_animal_codigo_fkey: FOREIGN KEY (animal_codigo) REFERENCES huellas.animal(codigo_interno); reporte_animal_pkey: PRIMARY KEY (reporte_id, animal_codigo) |

Restricciones declarativas:

- `reporte_animal_animal_codigo_fkey`: `FOREIGN KEY (animal_codigo) REFERENCES huellas.animal(codigo_interno)`.
- `reporte_animal_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `reporte_animal_pkey`: `PRIMARY KEY (reporte_id, animal_codigo)`.
- `reporte_animal_reporte_id_fkey`: `FOREIGN KEY (reporte_id) REFERENCES huellas.reporte(id_reporte)`.
- `reporte_animal_reporte_id_not_null`: `NOT NULL reporte_id`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX reporte_animal_inverso_idx ON huellas.reporte_animal USING btree (animal_codigo)`.
- `CREATE UNIQUE INDEX reporte_animal_pkey ON huellas.reporte_animal USING btree (reporte_id, animal_codigo)`.

Mecanismos adicionales:

- `CREATE TRIGGER reporte_animal_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.reporte_animal FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## solicitud_adopcion

Reglas: RN-09/16/18; S-16.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_solicitud` | Identidad de la solicitud y de la instantánea concreta de su hogar. | `bigint` | Sí | IDENTITY BY DEFAULT | solicitud_adopcion_pkey: PRIMARY KEY (id_solicitud) |
| `clave_operacion` | UUID aportado por quien ejecuta; único en cada relación para reconocer un reenvío confirmado. | `uuid` | Sí | — | solicitud_adopcion_clave_operacion_key: UNIQUE (clave_operacion) |
| `solicitante_id` | Persona solicitante; admite solicitudes posteriores de la misma persona. | `bigint` | Sí | — | solicitud_adopcion_solicitante_id_fkey: FOREIGN KEY (solicitante_id) REFERENCES huellas.persona(id_persona) |
| `fecha_solicitud` | Instante real de recepción. | `huellas.instante` | Sí | — | — |
| `informacion_vivienda` | Instantánea de la vivienda de esta solicitud. | `huellas.texto_no_vacio` | Sí | — | — |
| `integrantes_hogar` | Descripción del hogar; texto según S-16. | `huellas.texto_no_vacio` | Sí | — | — |
| `experiencia_animales` | Experiencia declarada, incluida ausencia de experiencia expresada como texto. | `huellas.texto_no_vacio` | Sí | — | — |
| `condiciones_cuidado` | Condiciones ofrecidas de atención y recursos. | `huellas.texto_no_vacio` | Sí | — | — |

Restricciones declarativas:

- `solicitud_adopcion_clave_operacion_key`: `UNIQUE (clave_operacion)`.
- `solicitud_adopcion_clave_operacion_not_null`: `NOT NULL clave_operacion`.
- `solicitud_adopcion_condiciones_cuidado_not_null`: `NOT NULL condiciones_cuidado`.
- `solicitud_adopcion_experiencia_animales_not_null`: `NOT NULL experiencia_animales`.
- `solicitud_adopcion_fecha_solicitud_not_null`: `NOT NULL fecha_solicitud`.
- `solicitud_adopcion_id_solicitud_check`: `CHECK ((id_solicitud > 0))`.
- `solicitud_adopcion_id_solicitud_not_null`: `NOT NULL id_solicitud`.
- `solicitud_adopcion_informacion_vivienda_not_null`: `NOT NULL informacion_vivienda`.
- `solicitud_adopcion_integrantes_hogar_not_null`: `NOT NULL integrantes_hogar`.
- `solicitud_adopcion_pkey`: `PRIMARY KEY (id_solicitud)`.
- `solicitud_adopcion_solicitante_id_fkey`: `FOREIGN KEY (solicitante_id) REFERENCES huellas.persona(id_persona)`.
- `solicitud_adopcion_solicitante_id_not_null`: `NOT NULL solicitante_id`.
- `solicitud_recepcion`: `TRIGGER DEFERRABLE INITIALLY DEFERRED`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX solicitud_adopcion_clave_operacion_key ON huellas.solicitud_adopcion USING btree (clave_operacion)`.
- `CREATE UNIQUE INDEX solicitud_adopcion_pkey ON huellas.solicitud_adopcion USING btree (id_solicitud)`.
- `CREATE INDEX solicitud_persona_fecha_idx ON huellas.solicitud_adopcion USING btree (solicitante_id, fecha_solicitud)`.

Mecanismos adicionales:

- `CREATE TRIGGER solicitud_fecha BEFORE INSERT ON huellas.solicitud_adopcion FOR EACH ROW EXECUTE FUNCTION huellas._validar_solicitud_paula()`.
- `CREATE TRIGGER solicitud_historia BEFORE DELETE OR UPDATE ON huellas.solicitud_adopcion FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE CONSTRAINT TRIGGER solicitud_recepcion AFTER INSERT ON huellas.solicitud_adopcion DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION huellas._exigir_recepcion_paula()`.
- `CREATE TRIGGER solicitud_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.solicitud_adopcion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## solicitud_animal

Reglas: RN-16/19; S-10.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `solicitud_id` | Solicitud/hogar al que pertenece el hecho. | `bigint` | Sí | — | solicitud_animal_pkey: PRIMARY KEY (solicitud_id, animal_codigo); solicitud_animal_solicitud_id_fkey: FOREIGN KEY (solicitud_id) REFERENCES huellas.solicitud_adopcion(id_solicitud) |
| `animal_codigo` | Código del animal al que pertenece el hecho. | `huellas.texto_no_vacio` | Sí | — | solicitud_animal_animal_codigo_fkey: FOREIGN KEY (animal_codigo) REFERENCES huellas.animal(codigo_interno); solicitud_animal_pkey: PRIMARY KEY (solicitud_id, animal_codigo) |
| `fecha_interes` | Instante de inclusión del animal en la solicitud; no es una evaluación. | `huellas.instante` | Sí | — | — |

Restricciones declarativas:

- `solicitud_animal_animal_codigo_fkey`: `FOREIGN KEY (animal_codigo) REFERENCES huellas.animal(codigo_interno)`.
- `solicitud_animal_animal_codigo_not_null`: `NOT NULL animal_codigo`.
- `solicitud_animal_fecha_interes_not_null`: `NOT NULL fecha_interes`.
- `solicitud_animal_pkey`: `PRIMARY KEY (solicitud_id, animal_codigo)`.
- `solicitud_animal_solicitud_id_fkey`: `FOREIGN KEY (solicitud_id) REFERENCES huellas.solicitud_adopcion(id_solicitud)`.
- `solicitud_animal_solicitud_id_not_null`: `NOT NULL solicitud_id`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX solicitud_animal_inverso_idx ON huellas.solicitud_animal USING btree (animal_codigo)`.
- `CREATE UNIQUE INDEX solicitud_animal_pkey ON huellas.solicitud_animal USING btree (solicitud_id, animal_codigo)`.

Mecanismos adicionales:

- `CREATE TRIGGER interes_contexto BEFORE INSERT ON huellas.solicitud_animal FOR EACH ROW EXECUTE FUNCTION huellas._validar_interes_paula()`.
- `CREATE TRIGGER interes_historia BEFORE DELETE OR UPDATE ON huellas.solicitud_animal FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER interes_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.solicitud_animal FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## ubicacion

Reglas: RN-06/07/08; S-03/S-11/S-13.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_ubicacion` | Identidad de lugar/oferta histórica. | `bigint` | Sí | IDENTITY BY DEFAULT | ubicacion_pkey: PRIMARY KEY (id_ubicacion) |
| `tipo_ubicacion` | área interna, hogar temporal o atención externa. | `text` | Sí | — | — |
| `nombre_descripcion` | Descripción del lugar. | `huellas.texto_no_vacio` | Sí | — | — |
| `capacidad` | Número entero positivo de animales; NULL en atención externa. | `integer` | No; ver condición | — | — |
| `condicion_admitida` | Condición declarada del área, texto abierto. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `disponibilidad_desde` | Inicio inclusivo del periodo ofrecido por hogar temporal. | `huellas.instante` | No; ver condición | — | — |
| `disponibilidad_hasta` | Fin exclusivo de la oferta del hogar. | `huellas.instante` | No; ver condición | — | — |
| `persona_oferente_id` | Persona oferente; permite derivar responsabilidad histórica N-01. | `bigint` | No; ver condición | — | ubicacion_persona_oferente_id_fkey: FOREIGN KEY (persona_oferente_id) REFERENCES huellas.persona(id_persona) |
| `codigo_hogar` | Identidad del hogar físico entre ofertas diferentes. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `ubicacion_capacidad_check`: `CHECK ((capacidad > 0))`.
- `ubicacion_id_ubicacion_check`: `CHECK ((id_ubicacion > 0))`.
- `ubicacion_id_ubicacion_not_null`: `NOT NULL id_ubicacion`.
- `ubicacion_nombre_descripcion_not_null`: `NOT NULL nombre_descripcion`.
- `ubicacion_ofertas_no_solapan`: `EXCLUDE USING gist (((codigo_hogar)::text) WITH =, tstzrange((disponibilidad_desde)::timestamp with time zone, (disponibilidad_hasta)::timestamp with time zone, '[)'::text) WITH &&) WHERE ((tipo_ubicacion = 'HOGAR_TEMPORAL'::text))`.
- `ubicacion_persona_oferente_id_fkey`: `FOREIGN KEY (persona_oferente_id) REFERENCES huellas.persona(id_persona)`.
- `ubicacion_pkey`: `PRIMARY KEY (id_ubicacion)`.
- `ubicacion_por_tipo`: `CHECK ((((tipo_ubicacion <> 'ATENCION_EXTERNA'::text) = (capacidad IS NOT NULL)) AND ((tipo_ubicacion = 'AREA_INTERNA'::text) = (condicion_admitida IS NOT NULL)) AND ((tipo_ubicacion = 'HOGAR_TEMPORAL'::text) = (disponibilidad_desde IS NOT NULL)) AND ((tipo_ubicacion = 'HOGAR_TEMPORAL'::text) = (disponibilidad_hasta IS NOT NULL)) AND ((tipo_ubicacion = 'HOGAR_TEMPORAL'::text) = (persona_oferente_id IS NOT NULL)) AND ((tipo_ubicacion = 'HOGAR_TEMPORAL'::text) = (codigo_hogar IS NOT NULL)) AND ((tipo_ubicacion <> 'HOGAR_TEMPORAL'::text) OR ((disponibilidad_desde)::timestamp with time zone < (disponibilidad_hasta)::timestamp with time zone))))`.
- `ubicacion_tipo_ubicacion_check`: `CHECK ((tipo_ubicacion = ANY (ARRAY['AREA_INTERNA'::text, 'HOGAR_TEMPORAL'::text, 'ATENCION_EXTERNA'::text])))`.
- `ubicacion_tipo_ubicacion_not_null`: `NOT NULL tipo_ubicacion`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX ubicacion_ofertas_no_solapan ON huellas.ubicacion USING gist (((codigo_hogar)::text), tstzrange((disponibilidad_desde)::timestamp with time zone, (disponibilidad_hasta)::timestamp with time zone, '[)'::text)) WHERE (tipo_ubicacion = 'HOGAR_TEMPORAL'::text)`.
- `CREATE UNIQUE INDEX ubicacion_pkey ON huellas.ubicacion USING btree (id_ubicacion)`.

Mecanismos adicionales:

- `CREATE TRIGGER ubicacion_historia BEFORE UPDATE ON huellas.ubicacion FOR EACH ROW EXECUTE FUNCTION huellas._preservar_ubicacion()`.
- `CREATE TRIGGER ubicacion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.ubicacion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## ubicacion_especie_aceptada

Reglas: RN-07.

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `ubicacion_id` | Lugar/oferta del alojamiento o especie aceptada. | `bigint` | Sí | — | ubicacion_especie_aceptada_pkey: PRIMARY KEY (ubicacion_id, especie); ubicacion_especie_aceptada_ubicacion_id_fkey: FOREIGN KEY (ubicacion_id) REFERENCES huellas.ubicacion(id_ubicacion) |
| `especie` | Código común de especie; PERRO y GATO son ejemplos. | `huellas.especie_animal` | Sí | — | ubicacion_especie_aceptada_pkey: PRIMARY KEY (ubicacion_id, especie) |

Restricciones declarativas:

- `ubicacion_especie_aceptada_especie_not_null`: `NOT NULL especie`.
- `ubicacion_especie_aceptada_pkey`: `PRIMARY KEY (ubicacion_id, especie)`.
- `ubicacion_especie_aceptada_ubicacion_id_fkey`: `FOREIGN KEY (ubicacion_id) REFERENCES huellas.ubicacion(id_ubicacion)`.
- `ubicacion_especie_aceptada_ubicacion_id_not_null`: `NOT NULL ubicacion_id`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX ubicacion_especie_aceptada_pkey ON huellas.ubicacion_especie_aceptada USING btree (ubicacion_id, especie)`.

Mecanismos adicionales:

- `CREATE TRIGGER especie_aceptada_historia BEFORE INSERT OR DELETE OR UPDATE ON huellas.ubicacion_especie_aceptada FOR EACH ROW EXECUTE FUNCTION huellas._preservar_especies()`.
- `CREATE TRIGGER especie_aceptada_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.ubicacion_especie_aceptada FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.

## adopcion

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_adopcion` | Identidad de la adopción individual. | `bigint` | Sí | IDENTITY BY DEFAULT | adopcion_animal_uq: UNIQUE (id_adopcion, animal_codigo); adopcion_pkey: PRIMARY KEY (id_adopcion) |
| `clave_operacion` | UUID único de la operación. | `uuid` | Sí | — | adopcion_clave_operacion_key: UNIQUE (clave_operacion) |
| `reserva_id` | Reserva que origina la adopción. | `bigint` | Sí | — | adopcion_reserva_contexto_fk: FOREIGN KEY (reserva_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.reserva(id_reserva, solicitud_id, animal_codigo, ingreso_id); adopcion_reserva_id_key: UNIQUE (reserva_id) |
| `solicitud_id` | Solicitud del hogar interesado. | `bigint` | Sí | — | adopcion_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); adopcion_reserva_contexto_fk: FOREIGN KEY (reserva_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.reserva(id_reserva, solicitud_id, animal_codigo, ingreso_id); adopcion_solicitud_animal_fk: FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo) |
| `animal_codigo` | Código del animal del contexto. | `huellas.texto_no_vacio` | Sí | — | adopcion_animal_uq: UNIQUE (id_adopcion, animal_codigo); adopcion_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); adopcion_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo); adopcion_reserva_contexto_fk: FOREIGN KEY (reserva_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.reserva(id_reserva, solicitud_id, animal_codigo, ingreso_id); adopcion_solicitud_animal_fk: FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo) |
| `ingreso_id` | Etapa de ingreso correspondiente. | `bigint` | Sí | — | adopcion_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); adopcion_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo); adopcion_ingreso_id_key: UNIQUE (ingreso_id); adopcion_reserva_contexto_fk: FOREIGN KEY (reserva_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.reserva(id_reserva, solicitud_id, animal_codigo, ingreso_id) |
| `compatibilidad_id` | Valoración de compatibilidad del contexto. | `bigint` | Sí | — | adopcion_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id) |
| `fecha_entrega` | Instante de entrega del animal. | `huellas.instante` | Sí | — | — |
| `condiciones_aceptadas` | Condiciones aceptadas para la adopción. | `huellas.texto_no_vacio` | Sí | — | — |
| `responsable_entrega_id` | Persona responsable de la entrega. | `bigint` | Sí | — | adopcion_responsable_entrega_id_fkey: FOREIGN KEY (responsable_entrega_id) REFERENCES huellas.persona(id_persona) |
| `tipo_finalizacion` | Categoría de finalización según CHECK. | `text` | No; ver condición | — | — |
| `fecha_finalizacion` | Instante de finalización, si existe. | `huellas.instante` | No; ver condición | — | — |

Restricciones declarativas:

- `adopcion_animal_uq`: `UNIQUE (id_adopcion, animal_codigo)`.
- `adopcion_clave_operacion_key`: `UNIQUE (clave_operacion)`.
- `adopcion_compatibilidad_fk`: `FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id)`.
- `adopcion_finalizacion_fecha_chk`: `CHECK (((fecha_finalizacion IS NULL) OR ((fecha_finalizacion)::timestamp with time zone >= (fecha_entrega)::timestamp with time zone)))`.
- `adopcion_finalizacion_par_chk`: `CHECK (((tipo_finalizacion IS NULL) = (fecha_finalizacion IS NULL)))`.
- `adopcion_id_adopcion_check`: `CHECK ((id_adopcion > 0))`.
- `adopcion_ingreso_animal_fk`: `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo)`.
- `adopcion_ingreso_id_key`: `UNIQUE (ingreso_id)`.
- `adopcion_integridad_final`: `TRIGGER DEFERRABLE INITIALLY DEFERRED`.
- `adopcion_pkey`: `PRIMARY KEY (id_adopcion)`.
- `adopcion_reserva_contexto_fk`: `FOREIGN KEY (reserva_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.reserva(id_reserva, solicitud_id, animal_codigo, ingreso_id)`.
- `adopcion_reserva_id_key`: `UNIQUE (reserva_id)`.
- `adopcion_responsable_entrega_id_fkey`: `FOREIGN KEY (responsable_entrega_id) REFERENCES huellas.persona(id_persona)`.
- `adopcion_solicitud_animal_fk`: `FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo)`.
- `adopcion_tipo_finalizacion_check`: `CHECK ((tipo_finalizacion = ANY (ARRAY['SATISFACTORIA'::text, 'DEVOLUCION_VOLUNTARIA'::text, 'RECUPERACION_POR_INCUMPLIMIENTO'::text, 'PERDIDA_CONTACTO'::text])))`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX adopcion_animal_idx ON huellas.adopcion USING btree (animal_codigo)`.
- `CREATE UNIQUE INDEX adopcion_animal_uq ON huellas.adopcion USING btree (id_adopcion, animal_codigo)`.
- `CREATE UNIQUE INDEX adopcion_clave_operacion_key ON huellas.adopcion USING btree (clave_operacion)`.
- `CREATE UNIQUE INDEX adopcion_ingreso_id_key ON huellas.adopcion USING btree (ingreso_id)`.
- `CREATE UNIQUE INDEX adopcion_pkey ON huellas.adopcion USING btree (id_adopcion)`.
- `CREATE UNIQUE INDEX adopcion_reserva_id_key ON huellas.adopcion USING btree (reserva_id)`.
- `CREATE INDEX adopcion_solicitud_idx ON huellas.adopcion USING btree (solicitud_id, animal_codigo)`.

Mecanismos adicionales:

- `CREATE TRIGGER adopcion_finalizacion_validar BEFORE DELETE OR UPDATE ON huellas.adopcion FOR EACH ROW EXECUTE FUNCTION huellas._validar_finalizacion_adopcion_jeank()`.
- `CREATE CONSTRAINT TRIGGER adopcion_integridad_final AFTER INSERT OR UPDATE ON huellas.adopcion DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION huellas._adopcion_diferida_jeank()`.
- `CREATE TRIGGER adopcion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.adopcion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER adopcion_validar BEFORE INSERT ON huellas.adopcion FOR EACH ROW EXECUTE FUNCTION huellas._validar_adopcion_jeank()`.


## adopcion_responsable

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `adopcion_id` | Adopción a la que pertenece el registro. | `bigint` | Sí | — | adopcion_responsable_adopcion_id_fkey: FOREIGN KEY (adopcion_id) REFERENCES huellas.adopcion(id_adopcion); adopcion_responsable_pkey: PRIMARY KEY (adopcion_id, persona_id) |
| `persona_id` | Persona adoptante responsable. | `bigint` | Sí | — | adopcion_responsable_persona_id_fkey: FOREIGN KEY (persona_id) REFERENCES huellas.persona(id_persona); adopcion_responsable_pkey: PRIMARY KEY (adopcion_id, persona_id) |

Restricciones declarativas:

- `adopcion_responsable_adopcion_id_fkey`: `FOREIGN KEY (adopcion_id) REFERENCES huellas.adopcion(id_adopcion)`.
- `adopcion_responsable_persona_id_fkey`: `FOREIGN KEY (persona_id) REFERENCES huellas.persona(id_persona)`.
- `adopcion_responsable_pkey`: `PRIMARY KEY (adopcion_id, persona_id)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX adopcion_responsable_persona_idx ON huellas.adopcion_responsable USING btree (persona_id)`.
- `CREATE UNIQUE INDEX adopcion_responsable_pkey ON huellas.adopcion_responsable USING btree (adopcion_id, persona_id)`.

Mecanismos adicionales:

- `CREATE TRIGGER adopcion_responsable_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.adopcion_responsable FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER adopcion_responsable_validar BEFORE INSERT OR DELETE OR UPDATE ON huellas.adopcion_responsable FOR EACH ROW EXECUTE FUNCTION huellas._validar_responsable_adopcion_jeank()`.


## aplicacion_indicacion

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_aplicacion` | Identidad de la aplicación clínica. | `bigint` | Sí | IDENTITY BY DEFAULT | aplicacion_indicacion_pkey: PRIMARY KEY (id_aplicacion) |
| `indicacion_id` | Indicación clínica correspondiente. | `bigint` | Sí | — | aplicacion_indicacion_indicacion_id_fkey: FOREIGN KEY (indicacion_id) REFERENCES huellas.indicacion(id_indicacion) |
| `fecha_planificada` | Instante planificado de aplicación. | `huellas.instante` | Sí | — | — |
| `fecha_real` | Instante real de aplicación; NULL si no realizada. | `huellas.instante` | No; ver condición | — | — |
| `responsable_id` | Persona responsable del hecho. | `bigint` | No; ver condición | — | aplicacion_indicacion_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |
| `observaciones` | Observaciones de la aplicación. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `aplicacion_indicacion_id_aplicacion_check`: `CHECK ((id_aplicacion > 0))`.
- `aplicacion_indicacion_indicacion_id_fkey`: `FOREIGN KEY (indicacion_id) REFERENCES huellas.indicacion(id_indicacion)`.
- `aplicacion_indicacion_pkey`: `PRIMARY KEY (id_aplicacion)`.
- `aplicacion_indicacion_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `aplicacion_realizada_chk`: `CHECK (((fecha_real IS NULL) OR ((responsable_id IS NOT NULL) AND (observaciones IS NOT NULL))))`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX aplicacion_indicacion_idx ON huellas.aplicacion_indicacion USING btree (indicacion_id)`.
- `CREATE UNIQUE INDEX aplicacion_indicacion_pkey ON huellas.aplicacion_indicacion USING btree (id_aplicacion)`.

Mecanismos adicionales:

- `CREATE TRIGGER aplicacion_indicacion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.aplicacion_indicacion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER aplicacion_validar BEFORE INSERT OR DELETE OR UPDATE ON huellas.aplicacion_indicacion FOR EACH ROW EXECUTE FUNCTION huellas._validar_aplicacion_jeank()`.


## indicacion

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_indicacion` | Identidad de la indicación clínica. | `bigint` | Sí | IDENTITY BY DEFAULT | indicacion_contexto_uq: UNIQUE (id_indicacion, evaluacion_id); indicacion_pkey: PRIMARY KEY (id_indicacion) |
| `evaluacion_id` | Revisión veterinaria de origen. | `bigint` | Sí | — | indicacion_contexto_uq: UNIQUE (id_indicacion, evaluacion_id); indicacion_revision_fk: FOREIGN KEY (evaluacion_id, tipo_evaluacion) REFERENCES huellas.evaluacion_salud(id_evaluacion, tipo_evaluacion) |
| `tipo_evaluacion` | Discriminador fijo REVISION_VETERINARIA. | `text` | Sí | 'REVISION_VETERINARIA'::text | indicacion_revision_fk: FOREIGN KEY (evaluacion_id, tipo_evaluacion) REFERENCES huellas.evaluacion_salud(id_evaluacion, tipo_evaluacion) |
| `tipo_indicacion` | Categoría clínica según CHECK. | `text` | Sí | — | — |
| `descripcion` | Descripción de la indicación. | `huellas.texto_no_vacio` | Sí | — | — |
| `estado_indicacion` | Estado descriptivo opcional. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `indicacion_sustituida_id` | Indicación anterior sustituida, si existe. | `bigint` | No; ver condición | — | indicacion_indicacion_sustituida_id_fkey: FOREIGN KEY (indicacion_sustituida_id) REFERENCES huellas.indicacion(id_indicacion) |

Restricciones declarativas:

- `indicacion_contexto_uq`: `UNIQUE (id_indicacion, evaluacion_id)`.
- `indicacion_id_indicacion_check`: `CHECK ((id_indicacion > 0))`.
- `indicacion_indicacion_sustituida_id_fkey`: `FOREIGN KEY (indicacion_sustituida_id) REFERENCES huellas.indicacion(id_indicacion)`.
- `indicacion_no_autosustitucion`: `CHECK ((indicacion_sustituida_id <> id_indicacion))`.
- `indicacion_pkey`: `PRIMARY KEY (id_indicacion)`.
- `indicacion_revision_fk`: `FOREIGN KEY (evaluacion_id, tipo_evaluacion) REFERENCES huellas.evaluacion_salud(id_evaluacion, tipo_evaluacion)`.
- `indicacion_tipo_evaluacion_check`: `CHECK ((tipo_evaluacion = 'REVISION_VETERINARIA'::text))`.
- `indicacion_tipo_indicacion_check`: `CHECK ((tipo_indicacion = ANY (ARRAY['TRATAMIENTO'::text, 'MEDICAMENTO'::text, 'VACUNA'::text, 'PROCEDIMIENTO'::text, 'CONTROL_POSTERIOR'::text])))`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX indicacion_contexto_uq ON huellas.indicacion USING btree (id_indicacion, evaluacion_id)`.
- `CREATE INDEX indicacion_evaluacion_idx ON huellas.indicacion USING btree (evaluacion_id)`.
- `CREATE UNIQUE INDEX indicacion_pkey ON huellas.indicacion USING btree (id_indicacion)`.
- `CREATE INDEX indicacion_sustituida_idx ON huellas.indicacion USING btree (indicacion_sustituida_id)`.

Mecanismos adicionales:

- `CREATE TRIGGER indicacion_historia BEFORE DELETE OR UPDATE ON huellas.indicacion FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER indicacion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.indicacion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER indicacion_validar BEFORE INSERT ON huellas.indicacion FOR EACH ROW EXECUTE FUNCTION huellas._validar_indicacion_jeank()`.


## indicacion_diagnostico

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `indicacion_id` | Indicación clínica correspondiente. | `bigint` | Sí | — | indicacion_diagnostico_contexto_fk: FOREIGN KEY (indicacion_id, evaluacion_id) REFERENCES huellas.indicacion(id_indicacion, evaluacion_id); indicacion_diagnostico_pkey: PRIMARY KEY (indicacion_id, diagnostico_id) |
| `evaluacion_id` | Revisión veterinaria de origen. | `bigint` | Sí | — | indicacion_diagnostico_contexto_fk: FOREIGN KEY (indicacion_id, evaluacion_id) REFERENCES huellas.indicacion(id_indicacion, evaluacion_id); indicacion_diagnostico_revision_fk: FOREIGN KEY (evaluacion_id, diagnostico_id) REFERENCES huellas.diagnostico_revision(evaluacion_id, diagnostico_id) |
| `diagnostico_id` | Diagnóstico de la misma revisión. | `bigint` | Sí | — | indicacion_diagnostico_pkey: PRIMARY KEY (indicacion_id, diagnostico_id); indicacion_diagnostico_revision_fk: FOREIGN KEY (evaluacion_id, diagnostico_id) REFERENCES huellas.diagnostico_revision(evaluacion_id, diagnostico_id) |

Restricciones declarativas:

- `indicacion_diagnostico_contexto_fk`: `FOREIGN KEY (indicacion_id, evaluacion_id) REFERENCES huellas.indicacion(id_indicacion, evaluacion_id)`.
- `indicacion_diagnostico_pkey`: `PRIMARY KEY (indicacion_id, diagnostico_id)`.
- `indicacion_diagnostico_revision_fk`: `FOREIGN KEY (evaluacion_id, diagnostico_id) REFERENCES huellas.diagnostico_revision(evaluacion_id, diagnostico_id)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX indicacion_diagnostico_pkey ON huellas.indicacion_diagnostico USING btree (indicacion_id, diagnostico_id)`.
- `CREATE INDEX indicacion_diagnostico_revision_idx ON huellas.indicacion_diagnostico USING btree (evaluacion_id, diagnostico_id)`.

Mecanismos adicionales:

- `CREATE TRIGGER indicacion_diagnostico_historia BEFORE DELETE OR UPDATE ON huellas.indicacion_diagnostico FOR EACH ROW EXECUTE FUNCTION huellas._solo_insercion_paula()`.
- `CREATE TRIGGER indicacion_diagnostico_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.indicacion_diagnostico FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.


## reserva

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_reserva` | Identidad de la reserva. | `bigint` | Sí | IDENTITY BY DEFAULT | reserva_contexto_uq: UNIQUE (id_reserva, solicitud_id, animal_codigo, ingreso_id); reserva_pkey: PRIMARY KEY (id_reserva) |
| `clave_operacion` | UUID único de la operación. | `uuid` | Sí | — | reserva_clave_operacion_key: UNIQUE (clave_operacion) |
| `solicitud_id` | Solicitud del hogar interesado. | `bigint` | Sí | — | reserva_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); reserva_contexto_uq: UNIQUE (id_reserva, solicitud_id, animal_codigo, ingreso_id); reserva_solicitud_animal_fk: FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo) |
| `animal_codigo` | Código del animal del contexto. | `huellas.texto_no_vacio` | Sí | — | reserva_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); reserva_contexto_uq: UNIQUE (id_reserva, solicitud_id, animal_codigo, ingreso_id); reserva_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo); reserva_solicitud_animal_fk: FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo) |
| `ingreso_id` | Etapa de ingreso correspondiente. | `bigint` | Sí | — | reserva_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id); reserva_contexto_uq: UNIQUE (id_reserva, solicitud_id, animal_codigo, ingreso_id); reserva_ingreso_animal_fk: FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo) |
| `compatibilidad_id` | Valoración de compatibilidad del contexto. | `bigint` | Sí | — | reserva_compatibilidad_fk: FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id) |
| `fecha_reserva` | Instante de creación de la reserva. | `huellas.instante` | Sí | — | — |
| `fecha_fin_reserva` | Fin de la reserva; NULL mientras esté vigente. | `huellas.instante` | No; ver condición | — | — |
| `responsable_id` | Persona responsable del hecho. | `bigint` | Sí | — | reserva_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |

Restricciones declarativas:

- `reserva_clave_operacion_key`: `UNIQUE (clave_operacion)`.
- `reserva_compatibilidad_fk`: `FOREIGN KEY (compatibilidad_id, solicitud_id, animal_codigo, ingreso_id) REFERENCES huellas.compatibilidad_animal_hogar(id_compatibilidad, solicitud_id, animal_codigo, ingreso_id)`.
- `reserva_contexto_uq`: `UNIQUE (id_reserva, solicitud_id, animal_codigo, ingreso_id)`.
- `reserva_id_reserva_check`: `CHECK ((id_reserva > 0))`.
- `reserva_ingreso_animal_fk`: `FOREIGN KEY (ingreso_id, animal_codigo) REFERENCES huellas.ingreso(id_ingreso, animal_codigo)`.
- `reserva_periodo_chk`: `CHECK (((fecha_fin_reserva IS NULL) OR ((fecha_fin_reserva)::timestamp with time zone >= (fecha_reserva)::timestamp with time zone)))`.
- `reserva_pkey`: `PRIMARY KEY (id_reserva)`.
- `reserva_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `reserva_solicitud_animal_fk`: `FOREIGN KEY (solicitud_id, animal_codigo) REFERENCES huellas.solicitud_animal(solicitud_id, animal_codigo)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX reserva_animal_vigente_uq ON huellas.reserva USING btree (animal_codigo) WHERE (fecha_fin_reserva IS NULL)`.
- `CREATE UNIQUE INDEX reserva_clave_operacion_key ON huellas.reserva USING btree (clave_operacion)`.
- `CREATE UNIQUE INDEX reserva_contexto_uq ON huellas.reserva USING btree (id_reserva, solicitud_id, animal_codigo, ingreso_id)`.
- `CREATE INDEX reserva_ingreso_idx ON huellas.reserva USING btree (ingreso_id)`.
- `CREATE UNIQUE INDEX reserva_pkey ON huellas.reserva USING btree (id_reserva)`.
- `CREATE INDEX reserva_solicitud_idx ON huellas.reserva USING btree (solicitud_id, animal_codigo)`.

Mecanismos adicionales:

- `CREATE TRIGGER reserva_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.reserva FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER reserva_validar BEFORE INSERT OR DELETE OR UPDATE ON huellas.reserva FOR EACH ROW EXECUTE FUNCTION huellas._validar_reserva_jeank()`.


## restriccion_persona

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_restriccion` | Identidad de la restricción documentada. | `bigint` | Sí | IDENTITY BY DEFAULT | restriccion_persona_pkey: PRIMARY KEY (id_restriccion) |
| `persona_afectada_id` | Persona sujeta a la restricción. | `bigint` | Sí | — | restriccion_persona_persona_afectada_id_fkey: FOREIGN KEY (persona_afectada_id) REFERENCES huellas.persona(id_persona) |
| `motivo` | Fundamento documentado de la restricción. | `huellas.texto_no_vacio` | Sí | — | — |
| `fecha_inicio` | Inicio de vigencia. | `huellas.instante` | Sí | — | — |
| `fecha_fin` | Fin de vigencia; NULL si abierta. | `huellas.instante` | No; ver condición | — | — |
| `responsable_decision_id` | Persona que decide la restricción. | `bigint` | Sí | — | restriccion_persona_responsable_decision_id_fkey: FOREIGN KEY (responsable_decision_id) REFERENCES huellas.persona(id_persona) |

Restricciones declarativas:

- `restriccion_periodo_chk`: `CHECK (((fecha_fin IS NULL) OR ((fecha_fin)::timestamp with time zone >= (fecha_inicio)::timestamp with time zone)))`.
- `restriccion_persona_id_restriccion_check`: `CHECK ((id_restriccion > 0))`.
- `restriccion_persona_persona_afectada_id_fkey`: `FOREIGN KEY (persona_afectada_id) REFERENCES huellas.persona(id_persona)`.
- `restriccion_persona_pkey`: `PRIMARY KEY (id_restriccion)`.
- `restriccion_persona_responsable_decision_id_fkey`: `FOREIGN KEY (responsable_decision_id) REFERENCES huellas.persona(id_persona)`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX restriccion_persona_pkey ON huellas.restriccion_persona USING btree (id_restriccion)`.
- `CREATE INDEX restriccion_persona_vigencia_idx ON huellas.restriccion_persona USING btree (persona_afectada_id, fecha_inicio, fecha_fin)`.

Mecanismos adicionales:

- `CREATE TRIGGER restriccion_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.restriccion_persona FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER restriccion_validar BEFORE INSERT OR DELETE OR UPDATE ON huellas.restriccion_persona FOR EACH ROW EXECUTE FUNCTION huellas._validar_restriccion_jeank()`.


## resultado_etapa

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_resultado` | Identidad del resultado de etapa. | `bigint` | Sí | IDENTITY BY DEFAULT | resultado_etapa_pkey: PRIMARY KEY (id_resultado) |
| `ingreso_id` | Etapa de ingreso correspondiente. | `bigint` | Sí | — | resultado_etapa_ingreso_id_fkey: FOREIGN KEY (ingreso_id) REFERENCES huellas.ingreso(id_ingreso); resultado_etapa_ingreso_id_key: UNIQUE (ingreso_id) |
| `tipo_resultado` | Categoría de resultado según CHECK. | `text` | Sí | — | — |
| `fecha` | Instante del resultado. | `huellas.instante` | Sí | — | — |
| `circunstancias` | Descripción del resultado. | `huellas.texto_no_vacio` | Sí | — | — |
| `responsable_id` | Persona responsable del hecho. | `bigint` | Sí | — | resultado_etapa_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |
| `organizacion_destino_id` | Organización de destino del traslado. | `bigint` | No; ver condición | — | resultado_etapa_organizacion_destino_id_fkey: FOREIGN KEY (organizacion_destino_id) REFERENCES huellas.organizacion_externa(id_organizacion) |
| `condiciones_traslado` | Condiciones documentadas del traslado. | `huellas.texto_no_vacio` | No; ver condición | — | — |

Restricciones declarativas:

- `resultado_etapa_id_resultado_check`: `CHECK ((id_resultado > 0))`.
- `resultado_etapa_ingreso_id_fkey`: `FOREIGN KEY (ingreso_id) REFERENCES huellas.ingreso(id_ingreso)`.
- `resultado_etapa_ingreso_id_key`: `UNIQUE (ingreso_id)`.
- `resultado_etapa_organizacion_destino_id_fkey`: `FOREIGN KEY (organizacion_destino_id) REFERENCES huellas.organizacion_externa(id_organizacion)`.
- `resultado_etapa_pkey`: `PRIMARY KEY (id_resultado)`.
- `resultado_etapa_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `resultado_etapa_tipo_resultado_check`: `CHECK ((tipo_resultado = ANY (ARRAY['REUNIFICACION'::text, 'TRASLADO'::text, 'CUIDADO_PROLONGADO'::text, 'FALLECIMIENTO'::text])))`.
- `resultado_integridad_final`: `TRIGGER DEFERRABLE INITIALLY DEFERRED`.
- `resultado_traslado_chk`: `CHECK (((tipo_resultado <> 'TRASLADO'::text) OR ((organizacion_destino_id IS NOT NULL) AND (condiciones_traslado IS NOT NULL))))`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE UNIQUE INDEX resultado_etapa_ingreso_id_key ON huellas.resultado_etapa USING btree (ingreso_id)`.
- `CREATE UNIQUE INDEX resultado_etapa_pkey ON huellas.resultado_etapa USING btree (id_resultado)`.
- `CREATE INDEX resultado_organizacion_idx ON huellas.resultado_etapa USING btree (organizacion_destino_id)`.

Mecanismos adicionales:

- `CREATE TRIGGER resultado_etapa_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.resultado_etapa FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER resultado_etapa_validar BEFORE INSERT OR DELETE OR UPDATE ON huellas.resultado_etapa FOR EACH ROW EXECUTE FUNCTION huellas._validar_resultado_etapa_jeank()`.
- `CREATE CONSTRAINT TRIGGER resultado_integridad_final AFTER INSERT ON huellas.resultado_etapa DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION huellas._resultado_diferido_jeank()`.


## seguimiento_adopcion

| Atributo | Descripción y dominio | Tipo PostgreSQL | Obligatorio | Predeterminado | Claves y referencias |
|---|---|---|---|---|---|
| `id_seguimiento` | Identidad del seguimiento. | `bigint` | Sí | IDENTITY BY DEFAULT | seguimiento_adopcion_pkey: PRIMARY KEY (id_seguimiento); seguimiento_contexto_uq: UNIQUE (id_seguimiento, adopcion_id) |
| `adopcion_id` | Adopción a la que pertenece el registro. | `bigint` | Sí | — | seguimiento_adopcion_adopcion_id_fkey: FOREIGN KEY (adopcion_id) REFERENCES huellas.adopcion(id_adopcion); seguimiento_contexto_uq: UNIQUE (id_seguimiento, adopcion_id); seguimiento_origen_fk: FOREIGN KEY (seguimiento_origen_id, adopcion_id) REFERENCES huellas.seguimiento_adopcion(id_seguimiento, adopcion_id) |
| `fecha_prevista` | Instante previsto del seguimiento. | `huellas.instante` | Sí | — | — |
| `fecha_efectiva` | Instante efectivo del seguimiento realizado. | `huellas.instante` | No; ver condición | — | — |
| `responsable_id` | Persona responsable del hecho. | `bigint` | Sí | — | seguimiento_adopcion_responsable_id_fkey: FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona) |
| `medio` | Medio de seguimiento según CHECK. | `text` | Sí | — | — |
| `resultado` | Resultado documentado del seguimiento. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `acuerdo` | Acuerdo de seguimiento, si existe. | `huellas.texto_no_vacio` | No; ver condición | — | — |
| `estado_seguimiento` | Estado del seguimiento según CHECK. | `text` | Sí | — | — |
| `seguimiento_origen_id` | Seguimiento anterior de la misma adopción. | `bigint` | No; ver condición | — | seguimiento_origen_fk: FOREIGN KEY (seguimiento_origen_id, adopcion_id) REFERENCES huellas.seguimiento_adopcion(id_seguimiento, adopcion_id) |

Restricciones declarativas:

- `seguimiento_adopcion_adopcion_id_fkey`: `FOREIGN KEY (adopcion_id) REFERENCES huellas.adopcion(id_adopcion)`.
- `seguimiento_adopcion_estado_seguimiento_check`: `CHECK ((estado_seguimiento = ANY (ARRAY['PENDIENTE'::text, 'REALIZADO'::text, 'REPROGRAMADO'::text, 'NO_REALIZADO'::text])))`.
- `seguimiento_adopcion_id_seguimiento_check`: `CHECK ((id_seguimiento > 0))`.
- `seguimiento_adopcion_medio_check`: `CHECK ((medio = ANY (ARRAY['LLAMADA'::text, 'MENSAJE'::text, 'VISITA'::text, 'REVISION_VETERINARIA'::text])))`.
- `seguimiento_adopcion_pkey`: `PRIMARY KEY (id_seguimiento)`.
- `seguimiento_adopcion_responsable_id_fkey`: `FOREIGN KEY (responsable_id) REFERENCES huellas.persona(id_persona)`.
- `seguimiento_contexto_uq`: `UNIQUE (id_seguimiento, adopcion_id)`.
- `seguimiento_no_autorreferencia_chk`: `CHECK ((seguimiento_origen_id <> id_seguimiento))`.
- `seguimiento_origen_fk`: `FOREIGN KEY (seguimiento_origen_id, adopcion_id) REFERENCES huellas.seguimiento_adopcion(id_seguimiento, adopcion_id)`.
- `seguimiento_realizado_chk`: `CHECK ((((estado_seguimiento = 'REALIZADO'::text) AND (fecha_efectiva IS NOT NULL) AND (resultado IS NOT NULL)) OR ((estado_seguimiento <> 'REALIZADO'::text) AND (fecha_efectiva IS NULL))))`.

Índices (incluye soporte de PK/UQ y parciales):

- `CREATE INDEX seguimiento_adopcion_idx ON huellas.seguimiento_adopcion USING btree (adopcion_id)`.
- `CREATE UNIQUE INDEX seguimiento_adopcion_pkey ON huellas.seguimiento_adopcion USING btree (id_seguimiento)`.
- `CREATE UNIQUE INDEX seguimiento_contexto_uq ON huellas.seguimiento_adopcion USING btree (id_seguimiento, adopcion_id)`.
- `CREATE INDEX seguimiento_origen_idx ON huellas.seguimiento_adopcion USING btree (seguimiento_origen_id)`.
- `CREATE UNIQUE INDEX seguimiento_reprogramacion_uq ON huellas.seguimiento_adopcion USING btree (seguimiento_origen_id) WHERE (seguimiento_origen_id IS NOT NULL)`.

Mecanismos adicionales:

- `CREATE TRIGGER seguimiento_serializar BEFORE INSERT OR DELETE OR UPDATE ON huellas.seguimiento_adopcion FOR EACH STATEMENT EXECUTE FUNCTION huellas._serializar_catalogo()`.
- `CREATE TRIGGER seguimiento_validar BEFORE INSERT OR DELETE OR UPDATE ON huellas.seguimiento_adopcion FOR EACH ROW EXECUTE FUNCTION huellas._validar_seguimiento_jeank()`.
