-- =====================================================================
-- 01_esquema.sql
-- Proceso: registro de clientes y solicitudes de servicio
-- Motor: PostgreSQL <versión>
-- Convención: pk_ / fk_ / uq_ / ck_ + <tabla>_<detalle>
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ENTIDAD RAÍZ
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
-- 2. ATRIBUTOS MULTIVALUADOS DE CLIENTE (dependen de su existencia)
-- ---------------------------------------------------------------------
CREATE TABLE medio_contacto_cliente (
    tipo_id    VARCHAR(20)  NOT NULL,
    numero_id  VARCHAR(30)  NOT NULL,
    tipo_medio VARCHAR(20)  NOT NULL,
    valor      VARCHAR(120) NOT NULL,
    CONSTRAINT pk_medio_contacto_cliente
        PRIMARY KEY (tipo_id, numero_id, tipo_medio, valor),
    CONSTRAINT fk_medio_contacto_cliente_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_medio_contacto_cliente_tipo
        CHECK (tipo_medio IN ('TELEFONO', 'CORREO', 'WHATSAPP')),
    CONSTRAINT ck_medio_contacto_cliente_valor_no_vacio
        CHECK (length(trim(valor)) > 0)
);

CREATE TABLE direccion_habitual (
    tipo_id               VARCHAR(20)  NOT NULL,
    numero_id             VARCHAR(30)  NOT NULL,
    num_direccion         SMALLINT     NOT NULL,   -- consecutivo por cliente (clave parcial)
    provincia             VARCHAR(40)  NOT NULL,   -- comp: direccion
    canton                VARCHAR(40)  NOT NULL,   -- comp: direccion
    distrito              VARCHAR(40)  NOT NULL,   -- comp: direccion
    otras_senas           VARCHAR(250) NOT NULL,   -- comp: direccion
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
-- 3. CONTACTO y sus multivaluados
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

CREATE TABLE medio_contacto_contacto (
    id_contacto INTEGER      NOT NULL,
    tipo_medio  VARCHAR(20)  NOT NULL,
    valor       VARCHAR(120) NOT NULL,
    CONSTRAINT pk_medio_contacto_contacto
        PRIMARY KEY (id_contacto, tipo_medio, valor),
    CONSTRAINT fk_medio_contacto_contacto_contacto
        FOREIGN KEY (id_contacto) REFERENCES contacto (id_contacto)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_medio_contacto_contacto_tipo
        CHECK (tipo_medio IN ('TELEFONO', 'CORREO', 'WHATSAPP')),
    CONSTRAINT ck_medio_contacto_contacto_valor_no_vacio
        CHECK (length(trim(valor)) > 0)
);

-- ---------------------------------------------------------------------
-- 4. SOLICITUD
-- ---------------------------------------------------------------------
CREATE TABLE solicitud (
    id_solicitud                  INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo_id                       VARCHAR(20)  NOT NULL,
    numero_id                     VARCHAR(30)  NOT NULL,
    fecha                         DATE         NOT NULL,
    lugar_recoleccion_provincia   VARCHAR(40)  NOT NULL,   -- comp: lugar_recoleccion
    lugar_recoleccion_canton      VARCHAR(40)  NOT NULL,
    lugar_recoleccion_distrito    VARCHAR(40)  NOT NULL,
    lugar_recoleccion_otras_senas VARCHAR(250) NOT NULL,
    periodo_previsto_inicio       TIMESTAMPTZ  NOT NULL,   -- comp: periodo_previsto
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

-- ---------------------------------------------------------------------
-- 5. PARTICIPANTE (puede o no ser un cliente registrado)
-- ---------------------------------------------------------------------
CREATE TABLE participante (
    id_participante INTEGER GENERATED ALWAYS AS IDENTITY,
    identificacion  VARCHAR(30)  NOT NULL,
    nombre          VARCHAR(120) NOT NULL,
    tipo_id         VARCHAR(20),   -- NULL si el participante no es cliente
    numero_id       VARCHAR(30),
    CONSTRAINT pk_participante PRIMARY KEY (id_participante),
    CONSTRAINT uq_participante_cliente UNIQUE (tipo_id, numero_id),   -- UK1 del diagrama
    CONSTRAINT fk_participante_cliente
        FOREIGN KEY (tipo_id, numero_id)
        REFERENCES cliente (tipo_id, numero_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Una FK compuesta con una sola columna NULL no se valida (MATCH SIMPLE),
    -- así que se exige que ambas sean NULL o ambas tengan valor
    CONSTRAINT ck_participante_cliente_completo
        CHECK ((tipo_id IS NULL) = (numero_id IS NULL)),
    CONSTRAINT ck_participante_identificacion_no_vacio
        CHECK (length(trim(identificacion)) > 0),
    CONSTRAINT ck_participante_nombre_no_vacio
        CHECK (length(trim(nombre)) > 0)
);

CREATE TABLE medio_contacto_participante (
    id_participante INTEGER      NOT NULL,
    tipo_medio      VARCHAR(20)  NOT NULL,
    valor           VARCHAR(120) NOT NULL,
    CONSTRAINT pk_medio_contacto_participante
        PRIMARY KEY (id_participante, tipo_medio, valor),
    CONSTRAINT fk_medio_contacto_participante_participante
        FOREIGN KEY (id_participante) REFERENCES participante (id_participante)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_medio_contacto_participante_tipo
        CHECK (tipo_medio IN ('TELEFONO', 'CORREO', 'WHATSAPP')),
    CONSTRAINT ck_medio_contacto_participante_valor_no_vacio
        CHECK (length(trim(valor)) > 0)
);

-- ---------------------------------------------------------------------
-- 6. ÍNDICES ADICIONALES
-- ---------------------------------------------------------------------
-- FK compuesta sin índice previo: consultas "solicitudes de un cliente"
CREATE INDEX idx_solicitud_cliente ON solicitud (tipo_id, numero_id);
-- FK compuesta sin índice previo: "contactos de un cliente"
CREATE INDEX idx_contacto_cliente  ON contacto  (tipo_id, numero_id);