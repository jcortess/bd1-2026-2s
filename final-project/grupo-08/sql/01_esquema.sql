-- =====================================================================
-- 01_esquema.sql
-- Proyecto final IC-4301 - Grupo 08: Envíos Conecta
-- Esquema físico completo (32 relaciones)
-- Motor: PostgreSQL 19.0
-- Requiere: una base de datos nueva y vacía, dedicada al proyecto.
-- Convención: pk_ / fk_ / uq_ / ck_ / trg_ / fn_ + <tabla>_<detalle>
-- Unidades (CAM-009): peso en kg, dimensiones en cm, volumen en m3.
-- Los cambios respecto al Proyecto 1 y Lab03 se marcan con [CAM-NNN]
-- (ver Control_de_Cambios.md).
-- =====================================================================


-- =====================================================================
-- BLOQUE 1. CLIENTES Y PARTES
-- Origen: Lab03 (01_esquema.sql), con CAM-001, CAM-010 y CAM-011.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CLIENTE
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    tipo_id               VARCHAR(20)  NOT NULL,
    numero_id             VARCHAR(30)  NOT NULL,
    nombre_razon_social   VARCHAR(150) NOT NULL,
    tipo_cliente          VARCHAR(20)  NOT NULL,
    condicion_contractual VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (tipo_id, numero_id),
    CONSTRAINT ck_cliente_tipo_id
        CHECK (tipo_id IN ('CEDULA_FISICA', 'CEDULA_JURIDICA', 'DIMEX', 'PASAPORTE')),
    CONSTRAINT ck_cliente_tipo_cliente
        CHECK (tipo_cliente IN ('PERSONA_FISICA', 'PERSONA_JURIDICA')),
    CONSTRAINT ck_cliente_condicion
        CHECK (condicion_contractual IN ('SIN_CONTRATO', 'CONTRATO_ESTANDAR', 'CONTRATO_CORPORATIVO')),
    CONSTRAINT ck_cliente_nombre_no_vacio
        CHECK (length(trim(nombre_razon_social)) > 0)
);

-- ---------------------------------------------------------------------
-- 2. MEDIO_CONTACTO_CLIENTE  [CAM-010]
-- ---------------------------------------------------------------------
CREATE TABLE medio_contacto_cliente (
    tipo_id           VARCHAR(20)  NOT NULL,
    numero_id         VARCHAR(30)  NOT NULL,
    tipo_medio        VARCHAR(20)  NOT NULL,
    valor             VARCHAR(120) NOT NULL,
    descripcion_medio VARCHAR(120),            -- [CAM-010] solo cuando tipo_medio = 'OTRO'
    CONSTRAINT pk_medio_contacto_cliente
        PRIMARY KEY (tipo_id, numero_id, tipo_medio, valor),
    CONSTRAINT fk_medio_contacto_cliente_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_medio_contacto_cliente_tipo
        CHECK (tipo_medio IN ('TELEFONO', 'CORREO', 'WHATSAPP', 'OTRO')),   -- [CAM-010]
    CONSTRAINT ck_medio_contacto_cliente_valor_no_vacio
        CHECK (length(trim(valor)) > 0),
    CONSTRAINT ck_medio_contacto_cliente_descripcion            -- [CAM-010]
        CHECK ((tipo_medio = 'OTRO'  AND descripcion_medio IS NOT NULL
                                     AND length(trim(descripcion_medio)) > 0)
            OR (tipo_medio <> 'OTRO' AND descripcion_medio IS NULL))
);

-- ---------------------------------------------------------------------
-- 3. DIRECCION_HABITUAL
-- ---------------------------------------------------------------------
CREATE TABLE direccion_habitual (
    tipo_id               VARCHAR(20)  NOT NULL,
    numero_id             VARCHAR(30)  NOT NULL,
    num_direccion         SMALLINT     NOT NULL,   -- consecutivo por cliente
    provincia             VARCHAR(40)  NOT NULL,
    canton                VARCHAR(40)  NOT NULL,
    distrito              VARCHAR(40)  NOT NULL,
    otras_senas           VARCHAR(250) NOT NULL,
    instrucciones_acceso  VARCHAR(250),
    referencia_geografica VARCHAR(250),
    activa                BOOLEAN      NOT NULL,
    CONSTRAINT pk_direccion_habitual
        PRIMARY KEY (tipo_id, numero_id, num_direccion),
    CONSTRAINT fk_direccion_habitual_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_direccion_habitual_num
        CHECK (num_direccion > 0),
    CONSTRAINT ck_direccion_habitual_provincia
        CHECK (provincia IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                             'GUANACASTE', 'PUNTARENAS', 'LIMON')),
    CONSTRAINT ck_direccion_habitual_canton_no_vacio
        CHECK (length(trim(canton)) > 0),
    CONSTRAINT ck_direccion_habitual_distrito_no_vacio
        CHECK (length(trim(distrito)) > 0),
    CONSTRAINT ck_direccion_habitual_senas_no_vacio
        CHECK (length(trim(otras_senas)) > 0)
);

-- ---------------------------------------------------------------------
-- 4. CONTACTO  (regla RN-02 / S-02 garantizada por triggers [CAM-011])
-- ---------------------------------------------------------------------
CREATE TABLE contacto (
    id_contacto INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo_id     VARCHAR(20)  NOT NULL,
    numero_id   VARCHAR(30)  NOT NULL,
    nombre      VARCHAR(120) NOT NULL,
    CONSTRAINT pk_contacto PRIMARY KEY (id_contacto),
    CONSTRAINT fk_contacto_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_contacto_nombre_no_vacio
        CHECK (length(trim(nombre)) > 0)
);

CREATE INDEX idx_contacto_cliente ON contacto (tipo_id, numero_id);

-- ---------------------------------------------------------------------
-- 5. FACULTAD_CONTACTO
-- ---------------------------------------------------------------------
CREATE TABLE facultad_contacto (
    id_contacto INTEGER     NOT NULL,
    facultad    VARCHAR(40) NOT NULL,
    CONSTRAINT pk_facultad_contacto PRIMARY KEY (id_contacto, facultad),
    CONSTRAINT fk_facultad_contacto_contacto
        FOREIGN KEY (id_contacto) REFERENCES contacto (id_contacto)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_facultad_contacto_facultad
        CHECK (facultad IN ('SOLICITAR_SERVICIOS', 'RECIBIR_REPORTES', 'AUTORIZAR_CARGOS'))
);

-- ---------------------------------------------------------------------
-- 6. MEDIO_CONTACTO_CONTACTO  [CAM-010]
-- ---------------------------------------------------------------------
CREATE TABLE medio_contacto_contacto (
    id_contacto       INTEGER      NOT NULL,
    tipo_medio        VARCHAR(20)  NOT NULL,
    valor             VARCHAR(120) NOT NULL,
    descripcion_medio VARCHAR(120),            -- [CAM-010]
    CONSTRAINT pk_medio_contacto_contacto
        PRIMARY KEY (id_contacto, tipo_medio, valor),
    CONSTRAINT fk_medio_contacto_contacto_contacto
        FOREIGN KEY (id_contacto) REFERENCES contacto (id_contacto)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_medio_contacto_contacto_tipo
        CHECK (tipo_medio IN ('TELEFONO', 'CORREO', 'WHATSAPP', 'OTRO')),   -- [CAM-010]
    CONSTRAINT ck_medio_contacto_contacto_valor_no_vacio
        CHECK (length(trim(valor)) > 0),
    CONSTRAINT ck_medio_contacto_contacto_descripcion           -- [CAM-010]
        CHECK ((tipo_medio = 'OTRO'  AND descripcion_medio IS NOT NULL
                                     AND length(trim(descripcion_medio)) > 0)
            OR (tipo_medio <> 'OTRO' AND descripcion_medio IS NULL))
);

-- ---------------------------------------------------------------------
-- 7. PARTICIPANTE  [CAM-001]
-- Puede o no ser un cliente registrado (RN-04). Se identifica con tipo y
-- número (S-01 modificado); si está vinculado a un cliente, ambos coinciden.
-- ---------------------------------------------------------------------
CREATE TABLE participante (
    id_participante     INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo_identificacion VARCHAR(20)  NOT NULL,   -- [CAM-001]
    identificacion      VARCHAR(30)  NOT NULL,
    nombre              VARCHAR(120) NOT NULL,
    tipo_id             VARCHAR(20),             -- NULL si no es cliente
    numero_id           VARCHAR(30),
    CONSTRAINT pk_participante PRIMARY KEY (id_participante),
    CONSTRAINT uq_participante_identificacion                    -- [CAM-001]
        UNIQUE (tipo_identificacion, identificacion),
    CONSTRAINT uq_participante_cliente UNIQUE (tipo_id, numero_id),
    CONSTRAINT fk_participante_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_participante_tipo_identificacion               -- [CAM-001]
        CHECK (tipo_identificacion IN ('CEDULA_FISICA', 'CEDULA_JURIDICA', 'DIMEX', 'PASAPORTE')),
    -- Una FK compuesta con una sola columna NULL no se valida (MATCH SIMPLE)
    CONSTRAINT ck_participante_cliente_completo
        CHECK ((tipo_id IS NULL) = (numero_id IS NULL)),
    CONSTRAINT ck_participante_coincide_cliente                  -- [CAM-001]
        CHECK (tipo_id IS NULL
               OR (tipo_id = tipo_identificacion AND numero_id = identificacion)),
    CONSTRAINT ck_participante_identificacion_no_vacio
        CHECK (length(trim(identificacion)) > 0),
    CONSTRAINT ck_participante_nombre_no_vacio
        CHECK (length(trim(nombre)) > 0)
);

-- ---------------------------------------------------------------------
-- 8. MEDIO_CONTACTO_PARTICIPANTE  [CAM-010]
-- ---------------------------------------------------------------------
CREATE TABLE medio_contacto_participante (
    id_participante   INTEGER      NOT NULL,
    tipo_medio        VARCHAR(20)  NOT NULL,
    valor             VARCHAR(120) NOT NULL,
    descripcion_medio VARCHAR(120),            -- [CAM-010]
    CONSTRAINT pk_medio_contacto_participante
        PRIMARY KEY (id_participante, tipo_medio, valor),
    CONSTRAINT fk_medio_contacto_participante_participante
        FOREIGN KEY (id_participante) REFERENCES participante (id_participante)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_medio_contacto_participante_tipo
        CHECK (tipo_medio IN ('TELEFONO', 'CORREO', 'WHATSAPP', 'OTRO')),   -- [CAM-010]
    CONSTRAINT ck_medio_contacto_participante_valor_no_vacio
        CHECK (length(trim(valor)) > 0),
    CONSTRAINT ck_medio_contacto_participante_descripcion       -- [CAM-010]
        CHECK ((tipo_medio = 'OTRO'  AND descripcion_medio IS NOT NULL
                                     AND length(trim(descripcion_medio)) > 0)
            OR (tipo_medio <> 'OTRO' AND descripcion_medio IS NULL))
);

-- ---------------------------------------------------------------------
-- 9. TRIGGERS DE RN-02 / S-02: solo organizaciones con contactos [CAM-011]
-- Los errores usan ERRCODE check_violation y un nombre de restricción,
-- para que las pruebas puedan identificar la causa del rechazo.
-- ---------------------------------------------------------------------

-- 9.1 Al insertar un contacto o cambiar su cliente.
--     FOR SHARE bloquea la fila del cliente hasta el final de la
--     transacción, para que una sesión concurrente no pueda cambiar
--     su tipo mientras se registra el contacto.
--     Si el cliente no existe, se deja pasar: la FK lo rechaza con su
--     propia causa (referencia desconocida).
CREATE FUNCTION fn_contacto_solo_organizacion()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo_cliente VARCHAR(20);
BEGIN
    SELECT c.tipo_cliente
      INTO v_tipo_cliente
    FROM cliente c
    WHERE c.tipo_id = NEW.tipo_id
      AND c.numero_id = NEW.numero_id
    FOR SHARE;

    IF FOUND AND v_tipo_cliente <> 'PERSONA_JURIDICA' THEN
        RAISE EXCEPTION 'El cliente (%, %) no es una organización: no puede registrar contactos (RN-02)',
            NEW.tipo_id, NEW.numero_id
            USING ERRCODE = 'check_violation',
                  CONSTRAINT = 'ck_contacto_cliente_organizacion';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_contacto_solo_organizacion
    BEFORE INSERT OR UPDATE OF tipo_id, numero_id ON contacto
    FOR EACH ROW
    EXECUTE FUNCTION fn_contacto_solo_organizacion();

-- 9.2 Al cambiar el tipo de un cliente que tiene contactos.
CREATE FUNCTION fn_cliente_tipo_con_contactos()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1
               FROM contacto co
               WHERE co.tipo_id = OLD.tipo_id
                 AND co.numero_id = OLD.numero_id) THEN
        RAISE EXCEPTION 'El cliente (%, %) tiene contactos: no puede dejar de ser organización (RN-02)',
            OLD.tipo_id, OLD.numero_id
            USING ERRCODE = 'check_violation',
                  CONSTRAINT = 'ck_cliente_organizacion_con_contactos';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cliente_tipo_con_contactos
    BEFORE UPDATE OF tipo_cliente ON cliente
    FOR EACH ROW
    WHEN (OLD.tipo_cliente = 'PERSONA_JURIDICA'
          AND NEW.tipo_cliente <> 'PERSONA_JURIDICA')
    EXECUTE FUNCTION fn_cliente_tipo_con_contactos();

-- =====================================================================
-- BLOQUE 2. SEDES, PERSONAL, SOLICITUDES, ENVÍOS Y PAQUETES
-- SEDE y PERSONAL se crean aquí porque MEDICION y PAQUETE las referencian.
-- La FK de ENVIO hacia RECOLECCION se agrega en el bloque 3.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 9. SEDE
-- ---------------------------------------------------------------------
CREATE TABLE sede (
    id_sede     INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre      VARCHAR(100) NOT NULL,
    tipo        VARCHAR(30)  NOT NULL,
    provincia   VARCHAR(40)  NOT NULL,
    canton      VARCHAR(40)  NOT NULL,
    distrito    VARCHAR(40)  NOT NULL,
    otras_senas VARCHAR(250) NOT NULL,
    zona        VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_sede PRIMARY KEY (id_sede),
    CONSTRAINT ck_sede_tipo
        CHECK (tipo IN ('CENTRO_DISTRIBUCION', 'SUCURSAL')),
    CONSTRAINT ck_sede_provincia
        CHECK (provincia IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                             'GUANACASTE', 'PUNTARENAS', 'LIMON')),
    CONSTRAINT ck_sede_textos_no_vacios
        CHECK (length(trim(nombre)) > 0 AND length(trim(canton)) > 0
           AND length(trim(distrito)) > 0 AND length(trim(otras_senas)) > 0
           AND length(trim(zona)) > 0)
);

-- ---------------------------------------------------------------------
-- 10. PERSONAL
-- ---------------------------------------------------------------------
CREATE TABLE personal (
    id_personal    INTEGER GENERATED ALWAYS AS IDENTITY,
    identificacion VARCHAR(30)  NOT NULL,
    nombre         VARCHAR(120) NOT NULL,
    CONSTRAINT pk_personal PRIMARY KEY (id_personal),
    CONSTRAINT uq_personal_identificacion UNIQUE (identificacion),
    CONSTRAINT ck_personal_textos_no_vacios
        CHECK (length(trim(identificacion)) > 0 AND length(trim(nombre)) > 0)
);

-- ---------------------------------------------------------------------
-- 11. SOLICITUD  (Lab03, sin cambios en estructura)
-- destino: destino general de la solicitud; los destinos concretos
-- están en cada envío (supuesto de PEN-20).
-- ---------------------------------------------------------------------
CREATE TABLE solicitud (
    id_solicitud                  INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo_id                       VARCHAR(20)  NOT NULL,
    numero_id                     VARCHAR(30)  NOT NULL,
    fecha                         DATE         NOT NULL,
    lugar_recoleccion_provincia   VARCHAR(40)  NOT NULL,
    lugar_recoleccion_canton      VARCHAR(40)  NOT NULL,
    lugar_recoleccion_distrito    VARCHAR(40)  NOT NULL,
    lugar_recoleccion_otras_senas VARCHAR(250) NOT NULL,
    periodo_previsto_inicio       TIMESTAMPTZ  NOT NULL,
    periodo_previsto_fin          TIMESTAMPTZ  NOT NULL,
    destino                       VARCHAR(250) NOT NULL,
    nivel_servicio                VARCHAR(30)  NOT NULL,
    observaciones                 TEXT,
    CONSTRAINT pk_solicitud PRIMARY KEY (id_solicitud),
    CONSTRAINT fk_solicitud_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_solicitud_provincia
        CHECK (lugar_recoleccion_provincia IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                                               'GUANACASTE', 'PUNTARENAS', 'LIMON')),
    CONSTRAINT ck_solicitud_canton_no_vacio
        CHECK (length(trim(lugar_recoleccion_canton)) > 0),
    CONSTRAINT ck_solicitud_distrito_no_vacio
        CHECK (length(trim(lugar_recoleccion_distrito)) > 0),
    CONSTRAINT ck_solicitud_senas_no_vacio
        CHECK (length(trim(lugar_recoleccion_otras_senas)) > 0),
    CONSTRAINT ck_solicitud_periodo
        CHECK (periodo_previsto_fin >= periodo_previsto_inicio),
    CONSTRAINT ck_solicitud_destino_no_vacio
        CHECK (length(trim(destino)) > 0),
    CONSTRAINT ck_solicitud_nivel_servicio
        CHECK (nivel_servicio IN ('ECONOMICO', 'ESTANDAR', 'EXPRESS', 'MISMO_DIA'))
);

CREATE INDEX idx_solicitud_cliente ON solicitud (tipo_id, numero_id);

-- ---------------------------------------------------------------------
-- 12. TARIFA  [CAM-009, CAM-013]
-- Tarifa general (sin cliente) o de contrato (con cliente).
-- Peso en kg, volumen en m3, precio en colones (CRC).
-- La aplicabilidad al pagador y la vigencia se validan en la rutina de P01.
-- ---------------------------------------------------------------------
CREATE TABLE tarifa (
    id_tarifa          INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo_id            VARCHAR(20),
    numero_id          VARCHAR(30),
    nivel_servicio     VARCHAR(30)    NOT NULL,
    zona_origen        VARCHAR(60)    NOT NULL,
    zona_destino       VARCHAR(60)    NOT NULL,
    rango_peso_min     NUMERIC(10,3)  NOT NULL,   -- kg
    rango_peso_max     NUMERIC(10,3)  NOT NULL,   -- kg
    rango_volumen_min  NUMERIC(10,6)  NOT NULL,   -- m3
    rango_volumen_max  NUMERIC(10,6)  NOT NULL,   -- m3
    condicion_especial VARCHAR(100),
    precio             NUMERIC(12,2)  NOT NULL,   -- CRC
    vigencia_inicio    DATE           NOT NULL,
    vigencia_fin       DATE,
    CONSTRAINT pk_tarifa PRIMARY KEY (id_tarifa),
    CONSTRAINT fk_tarifa_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_tarifa_cliente_completo                        -- [CAM-013]
        CHECK ((tipo_id IS NULL) = (numero_id IS NULL)),
    CONSTRAINT ck_tarifa_nivel_servicio
        CHECK (nivel_servicio IN ('ECONOMICO', 'ESTANDAR', 'EXPRESS', 'MISMO_DIA')),
    CONSTRAINT ck_tarifa_zonas_no_vacias
        CHECK (length(trim(zona_origen)) > 0 AND length(trim(zona_destino)) > 0),
    CONSTRAINT ck_tarifa_rango_peso
        CHECK (rango_peso_min >= 0 AND rango_peso_max > rango_peso_min),
    CONSTRAINT ck_tarifa_rango_volumen
        CHECK (rango_volumen_min >= 0 AND rango_volumen_max > rango_volumen_min),
    CONSTRAINT ck_tarifa_precio
        CHECK (precio > 0),
    CONSTRAINT ck_tarifa_vigencia
        CHECK (vigencia_fin IS NULL OR vigencia_fin >= vigencia_inicio)
);

-- ---------------------------------------------------------------------
-- 13. ENVIO  [CAM-005, CAM-009, CAM-012, CAM-013]
-- Direcciones y cotización se guardan tal como se usaron (RN-04, RN-08, S-03).
-- id_recoleccion es opcional (CAM-005); su FK se crea en el bloque 3.
-- ---------------------------------------------------------------------
CREATE TABLE envio (
    numero_guia                  VARCHAR(20)   NOT NULL,
    id_solicitud                 INTEGER       NOT NULL,
    id_recoleccion               INTEGER,                    -- [CAM-005]
    tipo_id_pagador              VARCHAR(20)   NOT NULL,
    numero_id_pagador            VARCHAR(30)   NOT NULL,
    id_participante_remitente    INTEGER       NOT NULL,
    id_participante_destinatario INTEGER       NOT NULL,
    id_tarifa                    INTEGER       NOT NULL,
    fecha_creacion               DATE          NOT NULL,
    servicio                     VARCHAR(30)   NOT NULL,
    origen_provincia             VARCHAR(40)   NOT NULL,
    origen_canton                VARCHAR(40)   NOT NULL,
    origen_distrito              VARCHAR(40)   NOT NULL,
    origen_otras_senas           VARCHAR(250)  NOT NULL,
    destino_provincia            VARCHAR(40)   NOT NULL,
    destino_canton               VARCHAR(40)   NOT NULL,
    destino_distrito             VARCHAR(40)   NOT NULL,
    destino_otras_senas          VARCHAR(250)  NOT NULL,
    precio_cotizado              NUMERIC(12,2) NOT NULL,     -- CRC
    cotiz_zona_origen            VARCHAR(60)   NOT NULL,
    cotiz_zona_destino           VARCHAR(60)   NOT NULL,
    cotiz_peso                   NUMERIC(10,3) NOT NULL,     -- kg [CAM-009]
    cotiz_volumen                NUMERIC(10,6) NOT NULL,     -- m3 [CAM-009]
    cotiz_condiciones            VARCHAR(250),
    CONSTRAINT pk_envio PRIMARY KEY (numero_guia),
    CONSTRAINT fk_envio_solicitud
        FOREIGN KEY (id_solicitud) REFERENCES solicitud (id_solicitud)
        ON DELETE RESTRICT,
    CONSTRAINT fk_envio_pagador
        FOREIGN KEY (tipo_id_pagador, numero_id_pagador)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_envio_remitente
        FOREIGN KEY (id_participante_remitente) REFERENCES participante (id_participante)
        ON DELETE RESTRICT,
    CONSTRAINT fk_envio_destinatario
        FOREIGN KEY (id_participante_destinatario) REFERENCES participante (id_participante)
        ON DELETE RESTRICT,
    CONSTRAINT fk_envio_tarifa
        FOREIGN KEY (id_tarifa) REFERENCES tarifa (id_tarifa)
        ON DELETE RESTRICT,
    CONSTRAINT ck_envio_guia_no_vacia
        CHECK (length(trim(numero_guia)) > 0),
    CONSTRAINT ck_envio_servicio
        CHECK (servicio IN ('ECONOMICO', 'ESTANDAR', 'EXPRESS', 'MISMO_DIA')),
    CONSTRAINT ck_envio_provincias
        CHECK (origen_provincia  IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                                     'GUANACASTE', 'PUNTARENAS', 'LIMON')
           AND destino_provincia IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                                     'GUANACASTE', 'PUNTARENAS', 'LIMON')),
    CONSTRAINT ck_envio_direcciones_no_vacias
        CHECK (length(trim(origen_canton)) > 0  AND length(trim(origen_distrito)) > 0
           AND length(trim(origen_otras_senas)) > 0
           AND length(trim(destino_canton)) > 0 AND length(trim(destino_distrito)) > 0
           AND length(trim(destino_otras_senas)) > 0),
    CONSTRAINT ck_envio_cotizacion
        CHECK (precio_cotizado > 0 AND cotiz_peso > 0 AND cotiz_volumen > 0
           AND length(trim(cotiz_zona_origen)) > 0
           AND length(trim(cotiz_zona_destino)) > 0)
);

CREATE INDEX idx_envio_solicitud ON envio (id_solicitud);
CREATE INDEX idx_envio_pagador   ON envio (tipo_id_pagador, numero_id_pagador);

-- ---------------------------------------------------------------------
-- 14. PAQUETE  [CAM-006, CAM-009, CAM-012]
-- Declarado: peso en kg, dimensiones en cm. La FK a la medición aplicada
-- se agrega después de crear MEDICION (referencia circular).
-- ---------------------------------------------------------------------
CREATE TABLE paquete (
    numero_guia           VARCHAR(20)   NOT NULL,
    num_paquete           SMALLINT      NOT NULL,
    peso_declarado        NUMERIC(10,3) NOT NULL,   -- kg
    largo_declarado       NUMERIC(8,2)  NOT NULL,   -- cm
    ancho_declarado       NUMERIC(8,2)  NOT NULL,   -- cm
    alto_declarado        NUMERIC(8,2)  NOT NULL,   -- cm
    descripcion           VARCHAR(250)  NOT NULL,
    politica_contenido    VARCHAR(20)   NOT NULL,   -- [CAM-006]
    documento_respaldo    VARCHAR(250),
    revision_fecha_hora   TIMESTAMPTZ,
    revision_resultado    VARCHAR(20),
    revision_razon        VARCHAR(250),
    id_personal_revisor   INTEGER,
    num_medicion_aplicada SMALLINT,                 -- NULL: se usaron los valores declarados (S-07)
    CONSTRAINT pk_paquete PRIMARY KEY (numero_guia, num_paquete),
    CONSTRAINT fk_paquete_envio
        FOREIGN KEY (numero_guia) REFERENCES envio (numero_guia)
        ON DELETE CASCADE,
    CONSTRAINT fk_paquete_revisor
        FOREIGN KEY (id_personal_revisor) REFERENCES personal (id_personal)
        ON DELETE RESTRICT,
    CONSTRAINT ck_paquete_num
        CHECK (num_paquete > 0),
    CONSTRAINT ck_paquete_declarado
        CHECK (peso_declarado > 0 AND largo_declarado > 0
           AND ancho_declarado > 0 AND alto_declarado > 0),
    CONSTRAINT ck_paquete_descripcion_no_vacia
        CHECK (length(trim(descripcion)) > 0),
    CONSTRAINT ck_paquete_politica                               -- [CAM-006]
        CHECK (politica_contenido IN ('PERMITIDO', 'PROHIBIDO', 'EXIGE_RESPALDO')),
    CONSTRAINT ck_paquete_revision_resultado
        CHECK (revision_resultado IN ('ACEPTADO', 'RETENIDO', 'RECHAZADO')),
    -- Revisión completa o ausente: resultado, momento y revisor van juntos (RN-11)
    CONSTRAINT ck_paquete_revision_completa
        CHECK ((revision_resultado IS NULL) = (revision_fecha_hora IS NULL)
           AND (revision_resultado IS NULL) = (id_personal_revisor IS NULL)),
    -- Razón obligatoria si no se acepta (diccionario P1, RN-11)
    CONSTRAINT ck_paquete_revision_razon
        CHECK (revision_resultado NOT IN ('RETENIDO', 'RECHAZADO')
               OR (revision_razon IS NOT NULL AND length(trim(revision_razon)) > 0)),
    -- Material prohibido solo puede rechazarse (RN-11) [CAM-006]
    CONSTRAINT ck_paquete_prohibido_rechazado
        CHECK (politica_contenido <> 'PROHIBIDO'
               OR revision_resultado IS NULL OR revision_resultado = 'RECHAZADO'),
    -- Contenido que exige respaldo no se acepta sin documento (RN-11) [CAM-006]
    CONSTRAINT ck_paquete_respaldo_exigido
        CHECK (NOT (politica_contenido = 'EXIGE_RESPALDO'
                    AND revision_resultado = 'ACEPTADO'
                    AND documento_respaldo IS NULL))
);

-- ---------------------------------------------------------------------
-- 15. CONDICION_MANEJO_PAQUETE
-- ---------------------------------------------------------------------
CREATE TABLE condicion_manejo_paquete (
    numero_guia VARCHAR(20) NOT NULL,
    num_paquete SMALLINT    NOT NULL,
    condicion   VARCHAR(30) NOT NULL,
    CONSTRAINT pk_condicion_manejo_paquete PRIMARY KEY (numero_guia, num_paquete, condicion),
    CONSTRAINT fk_condicion_manejo_paquete_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE CASCADE,
    CONSTRAINT ck_condicion_manejo_paquete_condicion
        CHECK (condicion IN ('FRAGIL', 'REFRIGERACION', 'PRUEBA_IDENTIDAD'))
);

-- ---------------------------------------------------------------------
-- 16. MEDICION  [CAM-009]
-- Peso en kg, dimensiones en cm. Una nueva medición se agrega sin
-- reemplazar las anteriores (RN-10).
-- ---------------------------------------------------------------------
CREATE TABLE medicion (
    numero_guia  VARCHAR(20)   NOT NULL,
    num_paquete  SMALLINT      NOT NULL,
    num_medicion SMALLINT      NOT NULL,
    id_sede      INTEGER       NOT NULL,
    fecha_hora   TIMESTAMPTZ   NOT NULL,
    peso         NUMERIC(10,3) NOT NULL,   -- kg
    largo        NUMERIC(8,2)  NOT NULL,   -- cm
    ancho        NUMERIC(8,2)  NOT NULL,   -- cm
    alto         NUMERIC(8,2)  NOT NULL,   -- cm
    CONSTRAINT pk_medicion PRIMARY KEY (numero_guia, num_paquete, num_medicion),
    CONSTRAINT fk_medicion_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE CASCADE,
    CONSTRAINT fk_medicion_sede
        FOREIGN KEY (id_sede) REFERENCES sede (id_sede)
        ON DELETE RESTRICT,
    CONSTRAINT ck_medicion_num
        CHECK (num_medicion > 0),
    CONSTRAINT ck_medicion_valores
        CHECK (peso > 0 AND largo > 0 AND ancho > 0 AND alto > 0)
);

-- Medición aplicada: siempre del mismo paquete (FK compuesta, S-07).
-- Con num_medicion_aplicada NULL la FK no se evalúa (valores declarados).
ALTER TABLE paquete
    ADD CONSTRAINT fk_paquete_medicion_aplicada
        FOREIGN KEY (numero_guia, num_paquete, num_medicion_aplicada)
        REFERENCES medicion (numero_guia, num_paquete, num_medicion)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------------------
-- 17. MÍNIMO DE UN PAQUETE POR ENVÍO  [CAM-012]
-- Triggers diferidos: se verifican al confirmar la transacción, así el
-- envío y sus paquetes pueden insertarse en cualquier orden dentro de ella.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_envio_con_paquetes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_guia VARCHAR(20);
BEGIN
    IF TG_TABLE_NAME = 'envio' THEN
        v_guia := NEW.numero_guia;
    ELSE
        v_guia := OLD.numero_guia;   -- paquete eliminado o movido
    END IF;

    -- Si el envío ya no existe (se eliminó junto con sus paquetes), no aplica.
    IF EXISTS (SELECT 1 FROM envio e WHERE e.numero_guia = v_guia)
       AND NOT EXISTS (SELECT 1 FROM paquete p WHERE p.numero_guia = v_guia) THEN
        RAISE EXCEPTION 'El envío % no tiene paquetes: todo envío debe contener al menos uno (S-06, RN-07)',
            v_guia
            USING ERRCODE = 'check_violation',
                  CONSTRAINT = 'ck_envio_con_paquetes';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_envio_con_paquetes
    AFTER INSERT ON envio
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION fn_envio_con_paquetes();

CREATE CONSTRAINT TRIGGER trg_paquete_envio_no_vacio
    AFTER DELETE OR UPDATE OF numero_guia ON paquete
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION fn_envio_con_paquetes();

-- ---------------------------------------------------------------------
-- 18. LAS MEDICIONES NO SE MODIFICAN NI SE BORRAN  [CAM-014]
-- Una nueva medición se agrega sin reemplazar las anteriores (RN-10).
-- Solo se permite borrar mediciones cuando se borra su paquete
-- (eliminación en cascada desde PAQUETE).
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_medicion_solo_agregar()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE'
       AND NOT EXISTS (SELECT 1
                       FROM paquete p
                       WHERE p.numero_guia = OLD.numero_guia
                         AND p.num_paquete = OLD.num_paquete) THEN
        RETURN OLD;   -- el paquete ya fue eliminado: cascada permitida
    END IF;

    RAISE EXCEPTION 'La medición % del paquete (%, %) no puede modificarse ni eliminarse: registre una nueva medición (RN-10)',
        OLD.num_medicion, OLD.numero_guia, OLD.num_paquete
        USING ERRCODE = 'check_violation',
              CONSTRAINT = 'ck_medicion_solo_agregar';
END;
$$;

CREATE TRIGGER trg_medicion_solo_agregar
    BEFORE UPDATE OR DELETE ON medicion
    FOR EACH ROW
    EXECUTE FUNCTION fn_medicion_solo_agregar();

-- =====================================================================
-- BLOQUE 3. RECOLECCIÓN Y LOGÍSTICA
-- Requiere btree_gist para las restricciones de exclusión (CAM-015).
-- Es una extensión de confianza: la puede crear el dueño de la base,
-- sin superusuario (PostgreSQL 13 o superior).
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ---------------------------------------------------------------------
-- 19. RECOLECCION  [CAM-002]
-- La dirección es una copia opcional (S-08): se registra cuando hay un
-- único punto. Excepción de BCNF justificada en Modelo_Relacional.md, sección 7.
-- Una reprogramación crea una nueva recolección que referencia a la anterior.
-- ---------------------------------------------------------------------
CREATE TABLE recoleccion (
    id_recoleccion          INTEGER GENERATED ALWAYS AS IDENTITY,
    fecha                   DATE         NOT NULL,
    franja_inicio           TIME         NOT NULL,
    franja_fin              TIME         NOT NULL,
    direccion_provincia     VARCHAR(40),
    direccion_canton        VARCHAR(40),
    direccion_distrito      VARCHAR(40),
    direccion_otras_senas   VARCHAR(250),
    estado                  VARCHAR(20)  NOT NULL,
    id_recoleccion_anterior INTEGER,                        -- [CAM-002]
    CONSTRAINT pk_recoleccion PRIMARY KEY (id_recoleccion),
    CONSTRAINT uq_recoleccion_anterior UNIQUE (id_recoleccion_anterior),   -- [CAM-002]
    CONSTRAINT fk_recoleccion_anterior                                    -- [CAM-002]
        FOREIGN KEY (id_recoleccion_anterior) REFERENCES recoleccion (id_recoleccion)
        ON DELETE RESTRICT,
    CONSTRAINT ck_recoleccion_no_autorreferencia                         -- [CAM-002]
        CHECK (id_recoleccion_anterior <> id_recoleccion),
    CONSTRAINT ck_recoleccion_franja
        CHECK (franja_fin > franja_inicio),
    -- Dirección completa o ausente
    CONSTRAINT ck_recoleccion_direccion_completa
        CHECK ((direccion_provincia IS NULL) = (direccion_canton IS NULL)
           AND (direccion_provincia IS NULL) = (direccion_distrito IS NULL)
           AND (direccion_provincia IS NULL) = (direccion_otras_senas IS NULL)),
    CONSTRAINT ck_recoleccion_direccion_valores
        CHECK (direccion_provincia IS NULL
               OR (direccion_provincia IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                                           'GUANACASTE', 'PUNTARENAS', 'LIMON')
                   AND length(trim(direccion_canton)) > 0
                   AND length(trim(direccion_distrito)) > 0
                   AND length(trim(direccion_otras_senas)) > 0)),
    CONSTRAINT ck_recoleccion_estado
        CHECK (estado IN ('PLANIFICADA', 'COMPLETADA', 'FALLIDA', 'REPROGRAMADA'))
);

-- ---------------------------------------------------------------------
-- 20. INTENTO_RECOLECCION
-- ---------------------------------------------------------------------
CREATE TABLE intento_recoleccion (
    id_recoleccion INTEGER      NOT NULL,
    num_intento    SMALLINT     NOT NULL,
    fecha_hora     TIMESTAMPTZ  NOT NULL,
    resultado      VARCHAR(20)  NOT NULL,
    observacion    VARCHAR(250),
    CONSTRAINT pk_intento_recoleccion PRIMARY KEY (id_recoleccion, num_intento),
    CONSTRAINT fk_intento_recoleccion_recoleccion
        FOREIGN KEY (id_recoleccion) REFERENCES recoleccion (id_recoleccion)
        ON DELETE CASCADE,
    CONSTRAINT ck_intento_recoleccion_num
        CHECK (num_intento > 0),
    CONSTRAINT ck_intento_recoleccion_resultado
        CHECK (resultado IN ('EXITOSO', 'FALLIDO'))
);

-- FK de ENVIO hacia RECOLECCION, opcional  [CAM-005]
ALTER TABLE envio
    ADD CONSTRAINT fk_envio_recoleccion
        FOREIGN KEY (id_recoleccion) REFERENCES recoleccion (id_recoleccion)
        ON DELETE RESTRICT;

CREATE INDEX idx_envio_recoleccion ON envio (id_recoleccion);

-- ---------------------------------------------------------------------
-- 21. VEHICULO  [CAM-009]
-- Capacidad de peso en kg y de volumen en m3.
-- ---------------------------------------------------------------------
CREATE TABLE vehiculo (
    id_interno          INTEGER GENERATED ALWAYS AS IDENTITY,
    placa               VARCHAR(10)   NOT NULL,
    tipo                VARCHAR(20)   NOT NULL,
    capacidad_peso      NUMERIC(10,3) NOT NULL,   -- kg
    capacidad_volumen   NUMERIC(10,6) NOT NULL,   -- m3
    refrigerado         BOOLEAN       NOT NULL,
    condicion_operativa VARCHAR(20)   NOT NULL,
    CONSTRAINT pk_vehiculo PRIMARY KEY (id_interno),
    CONSTRAINT uq_vehiculo_placa UNIQUE (placa),
    CONSTRAINT ck_vehiculo_placa_no_vacia
        CHECK (length(trim(placa)) > 0),
    CONSTRAINT ck_vehiculo_tipo
        CHECK (tipo IN ('MOTOCICLETA', 'AUTOMOVIL', 'PANEL', 'CAMION')),
    CONSTRAINT ck_vehiculo_capacidades
        CHECK (capacidad_peso > 0 AND capacidad_volumen > 0),
    CONSTRAINT ck_vehiculo_condicion
        CHECK (condicion_operativa IN ('OPERATIVO', 'EN_MANTENIMIENTO', 'FUERA_DE_SERVICIO'))
);

-- ---------------------------------------------------------------------
-- 22. PERIODO_FUERA_SERVICIO  [CAM-015]
-- fin NULL: periodo abierto (sigue fuera de servicio).
-- Los periodos de un mismo vehículo no se superponen.
-- ---------------------------------------------------------------------
CREATE TABLE periodo_fuera_servicio (
    id_interno INTEGER     NOT NULL,
    inicio     TIMESTAMPTZ NOT NULL,
    fin        TIMESTAMPTZ,
    CONSTRAINT pk_periodo_fuera_servicio PRIMARY KEY (id_interno, inicio),
    CONSTRAINT fk_periodo_fuera_servicio_vehiculo
        FOREIGN KEY (id_interno) REFERENCES vehiculo (id_interno)
        ON DELETE CASCADE,
    CONSTRAINT ck_periodo_fuera_servicio_intervalo
        CHECK (fin IS NULL OR fin > inicio),
    CONSTRAINT ex_periodo_fuera_servicio_traslape                       -- [CAM-015]
        EXCLUDE USING gist (id_interno WITH =,
                            (tstzrange(inicio, fin, '[)')) WITH &&)
);

-- ---------------------------------------------------------------------
-- 23. FUNCION_PERSONAL
-- ---------------------------------------------------------------------
CREATE TABLE funcion_personal (
    id_personal INTEGER     NOT NULL,
    funcion     VARCHAR(30) NOT NULL,
    CONSTRAINT pk_funcion_personal PRIMARY KEY (id_personal, funcion),
    CONSTRAINT fk_funcion_personal_personal
        FOREIGN KEY (id_personal) REFERENCES personal (id_personal)
        ON DELETE CASCADE,
    CONSTRAINT ck_funcion_personal_funcion
        CHECK (funcion IN ('CONDUCTOR', 'MENSAJERO', 'OPERADOR_SEDE'))
);

-- ---------------------------------------------------------------------
-- 24. RUTA  [CAM-017]
-- Ruta de catálogo: no es una salida concreta (G08-P02).
-- ---------------------------------------------------------------------
CREATE TABLE ruta (
    id_ruta         INTEGER GENERATED ALWAYS AS IDENTITY,
    id_sede_origen  INTEGER      NOT NULL,
    id_sede_destino INTEGER,
    nombre          VARCHAR(100) NOT NULL,
    zona_destino    VARCHAR(60),
    CONSTRAINT pk_ruta PRIMARY KEY (id_ruta),
    CONSTRAINT fk_ruta_sede_origen
        FOREIGN KEY (id_sede_origen) REFERENCES sede (id_sede)
        ON DELETE RESTRICT,
    CONSTRAINT fk_ruta_sede_destino
        FOREIGN KEY (id_sede_destino) REFERENCES sede (id_sede)
        ON DELETE RESTRICT,
    CONSTRAINT ck_ruta_nombre_no_vacio
        CHECK (length(trim(nombre)) > 0),
    CONSTRAINT ck_ruta_destino                                          -- [CAM-017]
        CHECK (id_sede_destino IS NOT NULL
               OR (zona_destino IS NOT NULL AND length(trim(zona_destino)) > 0))
);

-- ---------------------------------------------------------------------
-- 25. SALIDA_RUTA
-- Salida concreta y fechada de una ruta.
-- ---------------------------------------------------------------------
CREATE TABLE salida_ruta (
    id_salida INTEGER GENERATED ALWAYS AS IDENTITY,
    id_ruta   INTEGER     NOT NULL,
    fecha     DATE        NOT NULL,
    estado    VARCHAR(20) NOT NULL,
    CONSTRAINT pk_salida_ruta PRIMARY KEY (id_salida),
    CONSTRAINT fk_salida_ruta_ruta
        FOREIGN KEY (id_ruta) REFERENCES ruta (id_ruta)
        ON DELETE RESTRICT,
    CONSTRAINT ck_salida_ruta_estado
        CHECK (estado IN ('PLANIFICADA', 'CONFIRMADA', 'EN_RUTA', 'FINALIZADA', 'CANCELADA'))
);

-- ---------------------------------------------------------------------
-- 26. SALIDA_PAQUETE  (manifiesto de la salida)
-- ---------------------------------------------------------------------
CREATE TABLE salida_paquete (
    id_salida        INTEGER     NOT NULL,
    numero_guia      VARCHAR(20) NOT NULL,
    num_paquete      SMALLINT    NOT NULL,
    momento_registro TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_salida_paquete PRIMARY KEY (id_salida, numero_guia, num_paquete),
    CONSTRAINT fk_salida_paquete_salida
        FOREIGN KEY (id_salida) REFERENCES salida_ruta (id_salida)
        ON DELETE CASCADE,
    CONSTRAINT fk_salida_paquete_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE RESTRICT
);

CREATE INDEX idx_salida_paquete_paquete ON salida_paquete (numero_guia, num_paquete);

-- ---------------------------------------------------------------------
-- 27. ASIGNACION  [CAM-008, CAM-015, CAM-016]
-- Atiende exactamente una operación: una recolección o una salida.
-- Intervalo [inicio, fin): puede empezar justo cuando termina otra (S-13).
-- Solo las asignaciones vigentes se comparan por traslape; al sustituir,
-- la original pasa a vigente = false y se conserva (RN-23).
-- ---------------------------------------------------------------------
CREATE TABLE asignacion (
    id_asignacion            INTEGER GENERATED ALWAYS AS IDENTITY,
    id_personal              INTEGER      NOT NULL,
    id_vehiculo              INTEGER      NOT NULL,
    id_recoleccion           INTEGER,
    id_salida                INTEGER,
    id_asignacion_sustituida INTEGER,
    inicio                   TIMESTAMPTZ  NOT NULL,
    fin                      TIMESTAMPTZ  NOT NULL,
    funcion_ejercida         VARCHAR(30)  NOT NULL,
    momento_registro         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    motivo_cambio            VARCHAR(250),
    vigente                  BOOLEAN      NOT NULL DEFAULT TRUE,   -- [CAM-015]
    CONSTRAINT pk_asignacion PRIMARY KEY (id_asignacion),
    CONSTRAINT uq_asignacion_sustituida UNIQUE (id_asignacion_sustituida),
    CONSTRAINT fk_asignacion_personal
        FOREIGN KEY (id_personal) REFERENCES personal (id_personal)
        ON DELETE RESTRICT,
    CONSTRAINT fk_asignacion_vehiculo
        FOREIGN KEY (id_vehiculo) REFERENCES vehiculo (id_interno)
        ON DELETE RESTRICT,
    CONSTRAINT fk_asignacion_recoleccion
        FOREIGN KEY (id_recoleccion) REFERENCES recoleccion (id_recoleccion)
        ON DELETE RESTRICT,
    CONSTRAINT fk_asignacion_salida
        FOREIGN KEY (id_salida) REFERENCES salida_ruta (id_salida)
        ON DELETE RESTRICT,
    CONSTRAINT fk_asignacion_sustituida
        FOREIGN KEY (id_asignacion_sustituida) REFERENCES asignacion (id_asignacion)
        ON DELETE RESTRICT,
    CONSTRAINT fk_asignacion_funcion_personal                           -- [CAM-016]
        FOREIGN KEY (id_personal, funcion_ejercida)
        REFERENCES funcion_personal (id_personal, funcion)
        ON DELETE RESTRICT,
    CONSTRAINT ck_asignacion_una_operacion                              -- [CAM-008]
        CHECK ((id_recoleccion IS NULL) <> (id_salida IS NULL)),
    CONSTRAINT ck_asignacion_intervalo                                  -- [CAM-015]
        CHECK (fin > inicio),
    CONSTRAINT ck_asignacion_funcion
        CHECK (funcion_ejercida IN ('CONDUCTOR', 'MENSAJERO', 'OPERADOR_SEDE')),
    CONSTRAINT ck_asignacion_no_autorreferencia
        CHECK (id_asignacion_sustituida <> id_asignacion),
    -- Una sustitución conserva el motivo del cambio (RN-23)
    CONSTRAINT ck_asignacion_motivo_sustitucion
        CHECK (id_asignacion_sustituida IS NULL
               OR (motivo_cambio IS NOT NULL AND length(trim(motivo_cambio)) > 0)),
    CONSTRAINT ex_asignacion_personal_traslape                          -- [CAM-015]
        EXCLUDE USING gist (id_personal WITH =,
                            (tstzrange(inicio, fin, '[)')) WITH &&)
        WHERE (vigente),
    CONSTRAINT ex_asignacion_vehiculo_traslape                          -- [CAM-015]
        EXCLUDE USING gist (id_vehiculo WITH =,
                            (tstzrange(inicio, fin, '[)')) WITH &&)
        WHERE (vigente)
);

CREATE INDEX idx_asignacion_salida      ON asignacion (id_salida);
CREATE INDEX idx_asignacion_recoleccion ON asignacion (id_recoleccion);

-- =====================================================================
-- BLOQUE 4. ENTREGAS, INCIDENCIAS, DEVOLUCIONES Y SEGUIMIENTO
-- =====================================================================

-- ---------------------------------------------------------------------
-- 28. ENTREGA
-- La dirección utilizada es una copia (S-03, S-17). El receptor puede
-- ser distinto del destinatario (S-18).
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
    id_entrega              INTEGER GENERATED ALWAYS AS IDENTITY,
    id_personal             INTEGER      NOT NULL,
    fecha_hora              TIMESTAMPTZ  NOT NULL,
    direccion_provincia     VARCHAR(40)  NOT NULL,
    direccion_canton        VARCHAR(40)  NOT NULL,
    direccion_distrito      VARCHAR(40)  NOT NULL,
    direccion_otras_senas   VARCHAR(250) NOT NULL,
    receptor_nombre         VARCHAR(120),
    receptor_identificacion VARCHAR(30),
    documento_mostrado      VARCHAR(60),
    constancia              VARCHAR(250),
    motivo                  VARCHAR(250),
    evidencia               VARCHAR(250),
    proxima_accion          VARCHAR(30),
    funcion_mensajero       VARCHAR(30)  NOT NULL DEFAULT 'MENSAJERO',   -- [CAM-022]
    CONSTRAINT pk_entrega PRIMARY KEY (id_entrega),
    CONSTRAINT fk_entrega_personal
        FOREIGN KEY (id_personal) REFERENCES personal (id_personal)
        ON DELETE RESTRICT,
    CONSTRAINT fk_entrega_mensajero                                    -- [CAM-022]
        FOREIGN KEY (id_personal, funcion_mensajero)
        REFERENCES funcion_personal (id_personal, funcion)
        ON DELETE RESTRICT,
    CONSTRAINT ck_entrega_funcion_mensajero                            -- [CAM-022]
        CHECK (funcion_mensajero = 'MENSAJERO'),
    CONSTRAINT ck_entrega_direccion
        CHECK (direccion_provincia IN ('SAN_JOSE', 'ALAJUELA', 'CARTAGO', 'HEREDIA',
                                       'GUANACASTE', 'PUNTARENAS', 'LIMON')
           AND length(trim(direccion_canton)) > 0
           AND length(trim(direccion_distrito)) > 0
           AND length(trim(direccion_otras_senas)) > 0),
    -- Receptor completo o ausente (S-18)
    CONSTRAINT ck_entrega_receptor_completo
        CHECK ((receptor_nombre IS NULL) = (receptor_identificacion IS NULL)),
    CONSTRAINT ck_entrega_proxima_accion
        CHECK (proxima_accion IN ('NUEVO_INTENTO', 'RETIRO_EN_SEDE',
                                  'DEVOLUCION_REMITENTE', 'OTRA'))
);

-- ---------------------------------------------------------------------
-- 29. ENTREGA_PAQUETE  [CAM-019, CAM-020]
-- Varios intentos por paquete, una sola entrega final (RN-16).
-- ---------------------------------------------------------------------
CREATE TABLE entrega_paquete (
    id_entrega  INTEGER     NOT NULL,
    numero_guia VARCHAR(20) NOT NULL,
    num_paquete SMALLINT    NOT NULL,
    resultado   VARCHAR(20) NOT NULL,
    es_final    BOOLEAN     NOT NULL,
    CONSTRAINT pk_entrega_paquete PRIMARY KEY (id_entrega, numero_guia, num_paquete),
    -- Destino de la FK de DEVOLUCION_PAQUETE (superclave) [CAM-020]
    CONSTRAINT uq_entrega_paquete_resultado
        UNIQUE (id_entrega, numero_guia, num_paquete, resultado),
    CONSTRAINT fk_entrega_paquete_entrega
        FOREIGN KEY (id_entrega) REFERENCES entrega (id_entrega)
        ON DELETE CASCADE,
    CONSTRAINT fk_entrega_paquete_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT ck_entrega_paquete_resultado
        CHECK (resultado IN ('ENTREGADO', 'RECHAZADO', 'NO_COMPLETADO'))
);

-- Una sola entrega final por paquete (RN-16) [CAM-019]
CREATE UNIQUE INDEX uq_entrega_paquete_final
    ON entrega_paquete (numero_guia, num_paquete)
    WHERE es_final;

-- ---------------------------------------------------------------------
-- 29.1 DATOS DE LA ENTREGA SEGÚN EL RESULTADO DE SUS PAQUETES (RN-15) [CAM-023]
-- El resultado está por paquete y los datos por entrega, así que se
-- verifican al confirmar la transacción (trigger diferido):
--   - Algún paquete ENTREGADO: receptor y constancia.
--   - Algún paquete ENTREGADO con PRUEBA_IDENTIDAD: documento mostrado.
--   - Algún paquete NO_COMPLETADO o RECHAZADO: motivo y próxima acción.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_entrega_datos_resultado()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_entrega entrega%ROWTYPE;
BEGIN
    SELECT * INTO v_entrega
    FROM entrega e
    WHERE e.id_entrega = NEW.id_entrega;

    IF NOT FOUND THEN
        RETURN NULL;   -- la entrega se eliminó en la misma transacción
    END IF;

    -- Entrega exitosa: receptor y constancia
    IF EXISTS (SELECT 1 FROM entrega_paquete ep
               WHERE ep.id_entrega = v_entrega.id_entrega
                 AND ep.resultado = 'ENTREGADO')
       AND (v_entrega.receptor_nombre IS NULL
            OR v_entrega.constancia IS NULL
            OR length(trim(v_entrega.constancia)) = 0) THEN
        RAISE EXCEPTION 'La entrega % tiene paquetes entregados: debe registrar receptor y constancia (RN-15)',
            v_entrega.id_entrega
            USING ERRCODE = 'check_violation',
                  CONSTRAINT = 'ck_entrega_exitosa_receptor';
    END IF;

    -- Paquete con prueba de identidad entregado: documento mostrado
    IF EXISTS (SELECT 1
               FROM entrega_paquete ep
               JOIN condicion_manejo_paquete c
                 ON c.numero_guia = ep.numero_guia
                AND c.num_paquete = ep.num_paquete
               WHERE ep.id_entrega = v_entrega.id_entrega
                 AND ep.resultado = 'ENTREGADO'
                 AND c.condicion = 'PRUEBA_IDENTIDAD')
       AND (v_entrega.documento_mostrado IS NULL
            OR length(trim(v_entrega.documento_mostrado)) = 0) THEN
        RAISE EXCEPTION 'La entrega % incluye paquetes con prueba de identidad: debe registrar el documento mostrado (RN-15)',
            v_entrega.id_entrega
            USING ERRCODE = 'check_violation',
                  CONSTRAINT = 'ck_entrega_documento_identidad';
    END IF;

    -- Entrega no completada o rechazada: motivo y próxima acción
    IF EXISTS (SELECT 1 FROM entrega_paquete ep
               WHERE ep.id_entrega = v_entrega.id_entrega
                 AND ep.resultado IN ('NO_COMPLETADO', 'RECHAZADO'))
       AND (v_entrega.motivo IS NULL
            OR length(trim(v_entrega.motivo)) = 0
            OR v_entrega.proxima_accion IS NULL) THEN
        RAISE EXCEPTION 'La entrega % tiene paquetes no entregados: debe registrar motivo y próxima acción (RN-15)',
            v_entrega.id_entrega
            USING ERRCODE = 'check_violation',
                  CONSTRAINT = 'ck_entrega_no_completada_motivo';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_entrega_paquete_datos_resultado
    AFTER INSERT OR UPDATE ON entrega_paquete
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION fn_entrega_datos_resultado();

CREATE CONSTRAINT TRIGGER trg_entrega_datos_resultado
    AFTER UPDATE ON entrega
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION fn_entrega_datos_resultado();

-- ---------------------------------------------------------------------
-- 30. INCIDENCIA
-- ---------------------------------------------------------------------
CREATE TABLE incidencia (
    id_incidencia INTEGER GENERATED ALWAYS AS IDENTITY,
    id_personal   INTEGER      NOT NULL,   -- responsable de atención
    tipo          VARCHAR(30)  NOT NULL,
    fecha         DATE         NOT NULL,
    descripcion   VARCHAR(500) NOT NULL,
    estado        VARCHAR(20)  NOT NULL,
    resolucion    VARCHAR(500),
    CONSTRAINT pk_incidencia PRIMARY KEY (id_incidencia),
    CONSTRAINT fk_incidencia_personal
        FOREIGN KEY (id_personal) REFERENCES personal (id_personal)
        ON DELETE RESTRICT,
    CONSTRAINT ck_incidencia_tipo
        CHECK (tipo IN ('DANO', 'PERDIDA', 'DIRECCION_INCORRECTA', 'ATRASO',
                        'DOCUMENTACION_FALTANTE', 'RUPTURA_CONDICIONES')),
    CONSTRAINT ck_incidencia_descripcion_no_vacia
        CHECK (length(trim(descripcion)) > 0),
    CONSTRAINT ck_incidencia_estado
        CHECK (estado IN ('ABIERTA', 'EN_ATENCION', 'RESUELTA')),
    -- Una incidencia resuelta registra su resolución (RN-17)
    CONSTRAINT ck_incidencia_resolucion
        CHECK (estado <> 'RESUELTA'
               OR (resolucion IS NOT NULL AND length(trim(resolucion)) > 0))
);

-- ---------------------------------------------------------------------
-- 31. INCIDENCIA_PAQUETE  [CAM-021]
-- Resultado individual por paquete afectado (RN-18).
-- ---------------------------------------------------------------------
CREATE TABLE incidencia_paquete (
    id_incidencia INTEGER     NOT NULL,
    numero_guia   VARCHAR(20) NOT NULL,
    num_paquete   SMALLINT    NOT NULL,
    resultado     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',   -- [CAM-021]
    CONSTRAINT pk_incidencia_paquete PRIMARY KEY (id_incidencia, numero_guia, num_paquete),
    CONSTRAINT fk_incidencia_paquete_incidencia
        FOREIGN KEY (id_incidencia) REFERENCES incidencia (id_incidencia)
        ON DELETE CASCADE,
    CONSTRAINT fk_incidencia_paquete_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT ck_incidencia_paquete_resultado                         -- [CAM-021]
        CHECK (resultado IN ('PENDIENTE', 'RESUELTO', 'SIN_SOLUCION'))
);

CREATE INDEX idx_incidencia_paquete_paquete ON incidencia_paquete (numero_guia, num_paquete);

-- ---------------------------------------------------------------------
-- 32. DEVOLUCION  [CAM-004, CAM-020]
-- Resolución del envío para un paquete rechazado (RN-19).
-- La causa (entrega) está en DEVOLUCION_PAQUETE (CAM-020).
-- ---------------------------------------------------------------------
CREATE TABLE devolucion (
    id_devolucion INTEGER GENERATED ALWAYS AS IDENTITY,
    numero_guia   VARCHAR(20)  NOT NULL,
    fecha         DATE         NOT NULL,
    motivo        VARCHAR(250) NOT NULL,
    CONSTRAINT pk_devolucion PRIMARY KEY (id_devolucion),
    CONSTRAINT uq_devolucion_envio UNIQUE (id_devolucion, numero_guia),   -- [CAM-004]
    CONSTRAINT fk_devolucion_envio
        FOREIGN KEY (numero_guia) REFERENCES envio (numero_guia)
        ON DELETE RESTRICT,
    CONSTRAINT ck_devolucion_motivo_no_vacio
        CHECK (length(trim(motivo)) > 0)
);

-- ---------------------------------------------------------------------
-- 33. DEVOLUCION_PAQUETE  [CAM-004, CAM-012, CAM-018, CAM-020]
-- Una devolución, un paquete; un paquete se devuelve una sola vez.
-- El paquete pertenece al envío de la devolución y fue RECHAZADO en la
-- entrega indicada. Devolución y paquete se registran en la misma
-- transacción (ruta controlada, CAM-012).
-- ---------------------------------------------------------------------
CREATE TABLE devolucion_paquete (
    numero_guia       VARCHAR(20) NOT NULL,
    num_paquete       SMALLINT    NOT NULL,
    id_devolucion     INTEGER     NOT NULL,
    id_entrega        INTEGER     NOT NULL,                        -- [CAM-020]
    resultado_entrega VARCHAR(20) NOT NULL DEFAULT 'RECHAZADO',    -- [CAM-020]
    CONSTRAINT pk_devolucion_paquete PRIMARY KEY (numero_guia, num_paquete),
    CONSTRAINT uq_devolucion_paquete_devolucion UNIQUE (id_devolucion),              -- [CAM-004]
    CONSTRAINT uq_devolucion_paquete_contexto                                      -- [CAM-018]
        UNIQUE (id_devolucion, numero_guia, num_paquete),
    CONSTRAINT fk_devolucion_paquete_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT fk_devolucion_paquete_devolucion                                    -- [CAM-004]
        FOREIGN KEY (id_devolucion, numero_guia)
        REFERENCES devolucion (id_devolucion, numero_guia)
        ON DELETE CASCADE,
    CONSTRAINT fk_devolucion_paquete_entrega_rechazada                             -- [CAM-020]
        FOREIGN KEY (id_entrega, numero_guia, num_paquete, resultado_entrega)
        REFERENCES entrega_paquete (id_entrega, numero_guia, num_paquete, resultado)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_devolucion_paquete_rechazado                                     -- [CAM-020]
        CHECK (resultado_entrega = 'RECHAZADO')
);

-- ---------------------------------------------------------------------
-- 34. EVENTO_SEGUIMIENTO  [CAM-003, CAM-007, CAM-018]
-- Sin UK (paquete, momento): se permiten eventos simultáneos (CAM-003).
-- Evento actual: último por momento, momento_registro e id_evento,
-- excluyendo los eventos corregidos.
-- La salida, la devolución y el evento corregido deben ser del mismo
-- paquete (FK compuestas, CAM-018).
-- ---------------------------------------------------------------------
CREATE TABLE evento_seguimiento (
    id_evento             INTEGER GENERATED ALWAYS AS IDENTITY,
    numero_guia           VARCHAR(20)  NOT NULL,
    num_paquete           SMALLINT     NOT NULL,
    momento               TIMESTAMPTZ  NOT NULL,                  -- cuándo ocurrió el hecho
    momento_registro      TIMESTAMPTZ  NOT NULL DEFAULT now(),    -- [CAM-003] cuándo se registró
    id_personal           INTEGER      NOT NULL,                  -- responsable o autor de la corrección
    id_sede               INTEGER,
    descripcion_ubicacion VARCHAR(250),                           -- [CAM-007]
    id_salida             INTEGER,
    id_devolucion         INTEGER,
    id_evento_corregido   INTEGER,
    tipo_evento           VARCHAR(30)  NOT NULL,
    situacion             VARCHAR(30)  NOT NULL,
    condicion             VARCHAR(20)  NOT NULL,
    observaciones         VARCHAR(500),
    motivo_correccion     VARCHAR(250),
    CONSTRAINT pk_evento_seguimiento PRIMARY KEY (id_evento),
    -- Destino de la FK de corrección (superclave) [CAM-018]
    CONSTRAINT uq_evento_seguimiento_paquete
        UNIQUE (id_evento, numero_guia, num_paquete),
    CONSTRAINT uq_evento_seguimiento_corregido UNIQUE (id_evento_corregido),
    CONSTRAINT fk_evento_seguimiento_paquete
        FOREIGN KEY (numero_guia, num_paquete) REFERENCES paquete (numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evento_seguimiento_personal
        FOREIGN KEY (id_personal) REFERENCES personal (id_personal)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evento_seguimiento_sede
        FOREIGN KEY (id_sede) REFERENCES sede (id_sede)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evento_seguimiento_salida_paquete                       -- [CAM-018]
        FOREIGN KEY (id_salida, numero_guia, num_paquete)
        REFERENCES salida_paquete (id_salida, numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evento_seguimiento_devolucion_paquete                   -- [CAM-018]
        FOREIGN KEY (id_devolucion, numero_guia, num_paquete)
        REFERENCES devolucion_paquete (id_devolucion, numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT fk_evento_seguimiento_corregido                            -- [CAM-018]
        FOREIGN KEY (id_evento_corregido, numero_guia, num_paquete)
        REFERENCES evento_seguimiento (id_evento, numero_guia, num_paquete)
        ON DELETE RESTRICT,
    CONSTRAINT ck_evento_seguimiento_ubicacion                            -- [CAM-007]
        CHECK (id_sede IS NOT NULL
               OR (descripcion_ubicacion IS NOT NULL AND length(trim(descripcion_ubicacion)) > 0)),
    CONSTRAINT ck_evento_seguimiento_no_autorreferencia
        CHECK (id_evento_corregido <> id_evento),
    -- Una corrección indica por qué; el motivo solo existe en correcciones (RN-25)
    CONSTRAINT ck_evento_seguimiento_correccion
        CHECK ((id_evento_corregido IS NULL) = (motivo_correccion IS NULL)
               AND (motivo_correccion IS NULL OR length(trim(motivo_correccion)) > 0)),
    CONSTRAINT ck_evento_seguimiento_tipo
        CHECK (tipo_evento IN ('RECEPCION', 'INGRESO_SEDE', 'SALIDA_SEDE', 'EN_RUTA',
                               'TRANSFERENCIA', 'INTENTO_ENTREGA', 'ENTREGA', 'DEVOLUCION')),
    CONSTRAINT ck_evento_seguimiento_situacion
        CHECK (situacion IN ('EN_SEDE', 'EN_TRANSITO', 'EN_REPARTO', 'ENTREGADO',
                             'EN_DEVOLUCION', 'RETENIDO')),
    CONSTRAINT ck_evento_seguimiento_condicion
        CHECK (condicion IN ('BUEN_ESTADO', 'DANADO', 'INCOMPLETO'))
);

-- Orden cronológico por paquete para derivar el evento actual [CAM-003]
CREATE INDEX idx_evento_seguimiento_orden
    ON evento_seguimiento (numero_guia, num_paquete, momento, momento_registro, id_evento);

-- ---------------------------------------------------------------------
-- 35. LOS EVENTOS NO SE MODIFICAN NI SE ELIMINAN (RN-25)
-- Un error se corrige registrando un nuevo evento con id_evento_corregido.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_evento_seguimiento_inmutable()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'El evento % no puede modificarse ni eliminarse: registre una corrección (RN-25)',
        OLD.id_evento
        USING ERRCODE = 'check_violation',
              CONSTRAINT = 'ck_evento_seguimiento_inmutable';
END;
$$;

CREATE TRIGGER trg_evento_seguimiento_inmutable
    BEFORE UPDATE OR DELETE ON evento_seguimiento
    FOR EACH ROW
    EXECUTE FUNCTION fn_evento_seguimiento_inmutable();