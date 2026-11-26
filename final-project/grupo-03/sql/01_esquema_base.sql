-- Universidad Horizonte, Grupo 03. Modelo fisico: 16 relaciones base (57 atributos).
-- Requiere PostgreSQL 17 y una base NUEVA destinada al proyecto.
-- Conserva nombres y claves curriculares de Lab03.

BEGIN;
SET LOCAL search_path TO public;

-- Igualdad GiST para INTEGER y TEXT en la exclusion temporal de ventanas.
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;

CREATE TABLE escuela (
    id_escuela INTEGER CONSTRAINT pk_escuela PRIMARY KEY
);

CREATE TABLE carrera (
    id_carrera INTEGER CONSTRAINT pk_carrera PRIMARY KEY
);

CREATE TABLE sede (
    id_sede INTEGER CONSTRAINT pk_sede PRIMARY KEY,
    nombre TEXT NOT NULL,
    CONSTRAINT ck_sede_nombre_no_vacio CHECK (nombre ~ '[^[:space:]]')
);

CREATE TABLE estudiante (
    numero_institucional TEXT CONSTRAINT pk_estudiante PRIMARY KEY,
    nombre TEXT NOT NULL,
    primer_apellido TEXT NOT NULL,
    segundo_apellido TEXT,
    CONSTRAINT ck_estudiante_numero_no_vacio CHECK (numero_institucional ~ '[^[:space:]]'),
    CONSTRAINT ck_estudiante_nombre_no_vacio CHECK (nombre ~ '[^[:space:]]'),
    CONSTRAINT ck_estudiante_primer_apellido_no_vacio CHECK (primer_apellido ~ '[^[:space:]]'),
    CONSTRAINT ck_estudiante_segundo_apellido_no_vacio CHECK (
        segundo_apellido IS NULL OR segundo_apellido ~ '[^[:space:]]'
    )
);

CREATE TABLE docente (
    id_docente INTEGER CONSTRAINT pk_docente PRIMARY KEY,
    nombre TEXT NOT NULL,
    CONSTRAINT ck_docente_nombre_no_vacio CHECK (nombre ~ '[^[:space:]]')
);

CREATE TABLE persona_autorizadora (
    id_autorizador INTEGER CONSTRAINT pk_persona_autorizadora PRIMARY KEY,
    nombre TEXT NOT NULL,
    identificacion_institucional TEXT NOT NULL,
    CONSTRAINT uq_persona_autorizadora_identificacion UNIQUE (identificacion_institucional),
    CONSTRAINT ck_persona_autorizadora_nombre_no_vacio CHECK (nombre ~ '[^[:space:]]'),
    CONSTRAINT ck_persona_autorizadora_identificacion_no_vacia CHECK (
        identificacion_institucional ~ '[^[:space:]]'
    )
);

CREATE TABLE periodo_academico (
    id_periodo INTEGER CONSTRAINT pk_periodo_academico PRIMARY KEY,
    codigo_periodo TEXT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_finalizacion DATE NOT NULL,
    CONSTRAINT uq_periodo_codigo UNIQUE (codigo_periodo),
    CONSTRAINT ck_periodo_codigo_no_vacio CHECK (codigo_periodo ~ '[^[:space:]]'),
    CONSTRAINT ck_periodo_fechas CHECK (fecha_finalizacion >= fecha_inicio)
);

-- Subsistema curricular adaptado de lab03/grupo-03/sql/01_esquema.sql.
CREATE TABLE curso (
    codigo_institucional TEXT CONSTRAINT pk_curso PRIMARY KEY,
    nombre TEXT NOT NULL,
    cantidad_creditos INTEGER NOT NULL,
    id_escuela INTEGER NOT NULL,
    CONSTRAINT fk_curso_escuela FOREIGN KEY (id_escuela)
        REFERENCES escuela (id_escuela),
    CONSTRAINT ck_curso_codigo_no_vacio CHECK (codigo_institucional ~ '[^[:space:]]'),
    CONSTRAINT ck_curso_nombre_no_vacio CHECK (nombre ~ '[^[:space:]]'),
    CONSTRAINT ck_curso_creditos CHECK (cantidad_creditos >= 0)
);

CREATE TABLE version_plan_estudios (
    id_version_plan INTEGER CONSTRAINT pk_version_plan_estudios PRIMARY KEY,
    id_carrera INTEGER NOT NULL,
    inicio_vigencia DATE NOT NULL,
    fin_vigencia DATE,
    CONSTRAINT fk_version_carrera FOREIGN KEY (id_carrera)
        REFERENCES carrera (id_carrera),
    CONSTRAINT ck_version_vigencia CHECK (
        fin_vigencia IS NULL OR fin_vigencia >= inicio_vigencia
    )
);

CREATE TABLE carrera_sede (
    id_carrera INTEGER NOT NULL,
    id_sede INTEGER NOT NULL,
    CONSTRAINT pk_carrera_sede PRIMARY KEY (id_carrera, id_sede),
    CONSTRAINT fk_carrera_sede_carrera FOREIGN KEY (id_carrera)
        REFERENCES carrera (id_carrera),
    CONSTRAINT fk_carrera_sede_sede FOREIGN KEY (id_sede)
        REFERENCES sede (id_sede)
);

CREATE TABLE espacio (
    id_espacio INTEGER CONSTRAINT pk_espacio PRIMARY KEY,
    id_sede INTEGER NOT NULL,
    capacidad INTEGER NOT NULL,
    ubicacion TEXT NOT NULL,
    CONSTRAINT fk_espacio_sede FOREIGN KEY (id_sede)
        REFERENCES sede (id_sede),
    CONSTRAINT ck_espacio_capacidad CHECK (capacidad > 0),
    CONSTRAINT ck_espacio_ubicacion_no_vacia CHECK (ubicacion ~ '[^[:space:]]')
);

CREATE TABLE contacto_estudiante (
    id_contacto INTEGER CONSTRAINT pk_contacto_estudiante PRIMARY KEY,
    numero_institucional TEXT NOT NULL,
    tipo_contacto TEXT NOT NULL,
    valor TEXT NOT NULL,
    es_principal BOOLEAN NOT NULL,
    CONSTRAINT fk_contacto_estudiante FOREIGN KEY (numero_institucional)
        REFERENCES estudiante (numero_institucional),
    CONSTRAINT uq_contacto_tipo_valor UNIQUE (numero_institucional, tipo_contacto, valor),
    CONSTRAINT ck_contacto_tipo_no_vacio CHECK (tipo_contacto ~ '[^[:space:]]'),
    CONSTRAINT ck_contacto_valor_no_vacio CHECK (valor ~ '[^[:space:]]')
);

CREATE UNIQUE INDEX uq_contacto_principal_tipo
    ON contacto_estudiante (numero_institucional, tipo_contacto)
    WHERE es_principal = TRUE;

CREATE TABLE ventana_periodo (
    id_ventana INTEGER CONSTRAINT pk_ventana_periodo PRIMARY KEY,
    id_periodo INTEGER NOT NULL,
    tipo_ventana TEXT NOT NULL,
    inicio TIMESTAMP WITH TIME ZONE NOT NULL,
    fin TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_ventana_periodo FOREIGN KEY (id_periodo)
        REFERENCES periodo_academico (id_periodo),
    CONSTRAINT ck_ventana_tipo CHECK (
        tipo_ventana IN ('matricula', 'modificacion', 'retiro')
    ),
    CONSTRAINT ck_ventana_intervalo CHECK (fin > inicio),
    CONSTRAINT ex_ventana_tipo_periodo_no_solapado EXCLUDE USING gist (
        id_periodo WITH =,
        tipo_ventana WITH =,
        tstzrange(inicio, fin, '[)') WITH &&
    )
);

-- PK y FK curriculares de Lab03 conservadas.
CREATE TABLE participacion_plan (
    codigo_curso TEXT NOT NULL,
    id_version_plan INTEGER NOT NULL,
    tipo_participacion TEXT NOT NULL,
    nivel_o_periodo_recomendado TEXT,
    CONSTRAINT pk_participacion_plan PRIMARY KEY (codigo_curso, id_version_plan),
    CONSTRAINT fk_participacion_curso FOREIGN KEY (codigo_curso)
        REFERENCES curso (codigo_institucional),
    CONSTRAINT fk_participacion_version FOREIGN KEY (id_version_plan)
        REFERENCES version_plan_estudios (id_version_plan),
    CONSTRAINT ck_tipo_participacion CHECK (
        tipo_participacion IN ('Obligatorio', 'Optativo')
    ),
    CONSTRAINT ck_participacion_nivel_no_vacio CHECK (
        nivel_o_periodo_recomendado IS NULL
        OR nivel_o_periodo_recomendado ~ '[^[:space:]]'
    )
);

CREATE TABLE requisito_curso (
    id_version_plan INTEGER NOT NULL,
    codigo_curso_objetivo TEXT NOT NULL,
    codigo_curso_exigido TEXT NOT NULL,
    tipo_requisito TEXT NOT NULL,
    id_requisito INTEGER GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    CONSTRAINT pk_requisito_curso PRIMARY KEY (
        id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito
    ),
    CONSTRAINT uq_requisito_id UNIQUE (id_requisito),
    CONSTRAINT fk_requisito_version FOREIGN KEY (id_version_plan)
        REFERENCES version_plan_estudios (id_version_plan),
    CONSTRAINT fk_requisito_objetivo FOREIGN KEY (codigo_curso_objetivo)
        REFERENCES curso (codigo_institucional),
    CONSTRAINT fk_requisito_exigido FOREIGN KEY (codigo_curso_exigido)
        REFERENCES curso (codigo_institucional),
    CONSTRAINT ck_tipo_requisito CHECK (
        tipo_requisito IN ('Requisito previo', 'Correquisito')
    ),
    CONSTRAINT ck_requisito_no_autorrequisito CHECK (
        codigo_curso_objetivo <> codigo_curso_exigido
    )
);

CREATE TABLE admision (
    id_admision INTEGER CONSTRAINT pk_admision PRIMARY KEY,
    numero_institucional TEXT NOT NULL,
    id_sede INTEGER NOT NULL,
    id_version_plan INTEGER NOT NULL,
    fecha_ingreso DATE NOT NULL,
    condicion_academica TEXT NOT NULL,
    activa BOOLEAN NOT NULL,
    CONSTRAINT fk_admision_estudiante FOREIGN KEY (numero_institucional)
        REFERENCES estudiante (numero_institucional),
    CONSTRAINT fk_admision_sede FOREIGN KEY (id_sede)
        REFERENCES sede (id_sede),
    CONSTRAINT fk_admision_version FOREIGN KEY (id_version_plan)
        REFERENCES version_plan_estudios (id_version_plan),
    CONSTRAINT ck_admision_condicion_no_vacia CHECK (
        condicion_academica ~ '[^[:space:]]'
    )
);

COMMIT;
