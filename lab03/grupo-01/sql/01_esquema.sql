-- Laboratorio 03 - Grupo 01
-- Subsistema de Atención médica, diagnóstico y tratamiento clínico
-- Caso: Clínica Los Robles
-- Motor: PostgreSQL 14+

BEGIN;

-- Limpieza previa en orden inverso de dependencias para garantizar reproducibilidad (A3)
DROP TABLE IF EXISTS tratamiento_diagnostico_nm CASCADE;
DROP TABLE IF EXISTS tratamiento CASCADE;
DROP TABLE IF EXISTS consulta_diagnostico_nm CASCADE;
DROP TABLE IF EXISTS observacion_clinica CASCADE;
DROP TABLE IF EXISTS consulta CASCADE;
DROP TABLE IF EXISTS diagnostico CASCADE;

-- Catálogo maestro estandarizado de patologías y diagnósticos (ej. CIE-10) [AL-14, RN-20]
CREATE TABLE diagnostico (
    codigo_diagnostico TEXT
        CONSTRAINT pk_diagnostico PRIMARY KEY,
    descripcion_diagnostico TEXT NOT NULL
);

-- Entidad principal que modela el acto clínico ambulatorio o de urgencias [AL-11, RN-16, RN-17, S-12]
CREATE TABLE consulta (
    id_consulta INTEGER
        CONSTRAINT pk_consulta PRIMARY KEY,
    id_paciente INTEGER NOT NULL,
    id_medico INTEGER NOT NULL,
    -- Cita de origen; permite NULL en atenciones directas de urgencia [RN-16]
    id_cita INTEGER,
    fecha_hora_inicio TIMESTAMP NOT NULL,
    motivo_clinico TEXT NOT NULL,
    resumen_general TEXT NOT NULL,

    -- Una cita atendida no puede derivar en múltiples consultas [RN-16, S-09]
    CONSTRAINT uq_consulta_cita
        UNIQUE (id_cita)
);

-- Notas de evolución y examen físico con control de versiones inmutable [AL-12, AL-13, RN-19, S-13]
CREATE TABLE observacion_clinica (
    id_consulta INTEGER NOT NULL,
    consecutivo_observacion INTEGER NOT NULL,
    num_version INTEGER NOT NULL DEFAULT 1,
    contenido_observacion TEXT NOT NULL,
    fecha_hora_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    es_vigente BOOLEAN NOT NULL DEFAULT TRUE,

    -- Identificación unívoca por consulta, nota y número de revisión
    CONSTRAINT pk_observacion_clinica
        PRIMARY KEY (id_consulta, consecutivo_observacion, num_version),

    CONSTRAINT fk_observacion_consulta
        FOREIGN KEY (id_consulta)
        REFERENCES consulta (id_consulta)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- El número de versión debe ser estrictamente positivo
    CONSTRAINT ck_observacion_version_positiva
        CHECK (num_version >= 1)
);

-- Tabla asociativa M:N que relaciona la consulta con diagnósticos del catálogo [RN-20, S-16]
CREATE TABLE consulta_diagnostico_nm (
    id_consulta INTEGER NOT NULL,
    codigo_diagnostico TEXT NOT NULL,
    tipo_categoria TEXT NOT NULL,
    condicion TEXT NOT NULL,

    CONSTRAINT pk_consulta_diagnostico_nm
        PRIMARY KEY (id_consulta, codigo_diagnostico),

    CONSTRAINT fk_cd_consulta
        FOREIGN KEY (id_consulta)
        REFERENCES consulta (id_consulta)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_cd_diagnostico
        FOREIGN KEY (codigo_diagnostico)
        REFERENCES diagnostico (codigo_diagnostico)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Dominios cerrados según Supuesto S-16 y RN-20
    CONSTRAINT ck_cd_tipo_categoria
        CHECK (tipo_categoria IN ('Principal', 'Secundario')),

    CONSTRAINT ck_cd_condicion
        CHECK (condicion IN ('Presuntivo', 'Confirmado', 'Descartado'))
);

-- Prescripciones e indicaciones terapéuticas derivadas de la consulta [RN-21, RN-25, RN-26]
CREATE TABLE tratamiento (
    id_tratamiento INTEGER
        CONSTRAINT pk_tratamiento PRIMARY KEY,
    id_consulta INTEGER NOT NULL,
    -- Puntero autorreferencial 1:1 para la trazabilidad de sustitución médica [RN-26]
    id_tratamiento_sustituido INTEGER,
    tipo_tratamiento TEXT NOT NULL,
    instrucciones TEXT NOT NULL,
    fecha_inicio_prevista DATE NOT NULL,
    fecha_fin_prevista DATE,
    estado_actual TEXT NOT NULL,
    dosis TEXT,
    frecuencia TEXT,
    cantidad_sesiones INTEGER,

    -- Un tratamiento sustituido sólo puede ser relevado por uno nuevo como máximo [RN-26, S-15]
    CONSTRAINT uq_tratamiento_sustituido
        UNIQUE (id_tratamiento_sustituido),

    CONSTRAINT fk_tratamiento_consulta
        FOREIGN KEY (id_consulta)
        REFERENCES consulta (id_consulta)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Relación recursiva de sustitución clínica
    CONSTRAINT fk_tratamiento_sustitucion
        FOREIGN KEY (id_tratamiento_sustituido)
        REFERENCES tratamiento (id_tratamiento)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Un tratamiento no puede sustituirse a sí mismo
    CONSTRAINT ck_tratamiento_no_autosustitucion
        CHECK (id_tratamiento_sustituido <> id_tratamiento),

    -- Consistencia de ventana temporal [RN-25]
    CONSTRAINT ck_tratamiento_fechas
        CHECK (fecha_fin_prevista IS NULL OR fecha_fin_prevista >= fecha_inicio_prevista),

    -- Dominios cerrados según Supuesto S-16
    CONSTRAINT ck_tratamiento_tipo
        CHECK (tipo_tratamiento IN ('Medicamento', 'Procedimiento', 'Indicación', 'Recomendación')),

    CONSTRAINT ck_tratamiento_estado
        CHECK (estado_actual IN ('Planificado', 'Iniciado', 'Completado', 'Suspendido', 'Sustituido')),

    -- La cantidad de sesiones debe ser estrictamente positiva si se indica
    CONSTRAINT ck_tratamiento_sesiones_positivas
        CHECK (cantidad_sesiones IS NULL OR cantidad_sesiones > 0)
);

-- Tabla asociativa M:N entre tratamientos y patologías abordadas [RN-21]
CREATE TABLE tratamiento_diagnostico_nm (
    id_tratamiento INTEGER NOT NULL,
    codigo_diagnostico TEXT NOT NULL,

    CONSTRAINT pk_tratamiento_diagnostico_nm
        PRIMARY KEY (id_tratamiento, codigo_diagnostico),

    CONSTRAINT fk_td_tratamiento
        FOREIGN KEY (id_tratamiento)
        REFERENCES tratamiento (id_tratamiento)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_td_diagnostico
        FOREIGN KEY (codigo_diagnostico)
        REFERENCES diagnostico (codigo_diagnostico)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMIT;