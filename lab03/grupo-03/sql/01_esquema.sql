-- Laboratorio 03 - Grupo 03
-- Subsistema curricular de Universidad Horizonte.

BEGIN;

CREATE TABLE escuela (
    id_escuela INTEGER
        CONSTRAINT pk_escuela PRIMARY KEY
);

CREATE TABLE carrera (
    id_carrera INTEGER
        CONSTRAINT pk_carrera PRIMARY KEY
);

CREATE TABLE curso (
    codigo_institucional TEXT
        CONSTRAINT pk_curso PRIMARY KEY,
    nombre TEXT NOT NULL,
    cantidad_creditos INTEGER NOT NULL,
    id_escuela INTEGER NOT NULL,

    CONSTRAINT fk_curso_escuela
        FOREIGN KEY (id_escuela)
        REFERENCES escuela (id_escuela)
);

CREATE TABLE version_plan_estudios (
    id_version_plan INTEGER
        CONSTRAINT pk_version_plan_estudios PRIMARY KEY,

    -- Representacion temporal provisional.
    vigencia TEXT NOT NULL,
    id_carrera INTEGER NOT NULL,

    CONSTRAINT fk_version_carrera
        FOREIGN KEY (id_carrera)
        REFERENCES carrera (id_carrera)
);

CREATE TABLE participacion_plan (
    codigo_curso TEXT NOT NULL,
    id_version_plan INTEGER NOT NULL,
    tipo_participacion TEXT NOT NULL,

    -- Formato y obligatoriedad pendientes en Proyecto 1.
    nivel_o_periodo_recomendado TEXT,

    CONSTRAINT pk_participacion_plan
        PRIMARY KEY (codigo_curso, id_version_plan),

    CONSTRAINT fk_participacion_curso
        FOREIGN KEY (codigo_curso)
        REFERENCES curso (codigo_institucional),

    CONSTRAINT fk_participacion_version
        FOREIGN KEY (id_version_plan)
        REFERENCES version_plan_estudios (id_version_plan),

    CONSTRAINT ck_tipo_participacion
        CHECK (tipo_participacion IN ('Obligatorio', 'Optativo'))
);

CREATE TABLE requisito_curso (
    id_version_plan INTEGER NOT NULL,
    codigo_curso_objetivo TEXT NOT NULL,
    codigo_curso_exigido TEXT NOT NULL,
    tipo_requisito TEXT NOT NULL,

    CONSTRAINT pk_requisito_curso
        PRIMARY KEY (
            id_version_plan,
            codigo_curso_objetivo,
            codigo_curso_exigido,
            tipo_requisito
        ),

    CONSTRAINT fk_requisito_version
        FOREIGN KEY (id_version_plan)
        REFERENCES version_plan_estudios (id_version_plan),

    CONSTRAINT fk_requisito_objetivo
        FOREIGN KEY (codigo_curso_objetivo)
        REFERENCES curso (codigo_institucional),

    CONSTRAINT fk_requisito_exigido
        FOREIGN KEY (codigo_curso_exigido)
        REFERENCES curso (codigo_institucional),

    CONSTRAINT ck_tipo_requisito
        CHECK (
            tipo_requisito IN ('Requisito previo', 'Correquisito')
        )
);

COMMIT;
