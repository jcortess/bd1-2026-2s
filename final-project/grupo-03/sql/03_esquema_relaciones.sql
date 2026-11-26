-- Universidad Horizonte, Grupo 03. Diez relaciones adicionales (78 atributos).
-- Prerrequisito: 01_esquema_base.sql instalado en PostgreSQL 17.11.
-- Las referencias y restricciones locales no sustituyen las verificaciones
-- contextuales, historicas ni las operaciones de G03-P01, G03-P02 y G03-P03.

BEGIN;
SET LOCAL search_path TO public;

CREATE TABLE grupo (
    id_grupo INTEGER CONSTRAINT pk_grupo PRIMARY KEY,
    numero_grupo INTEGER NOT NULL,
    codigo_curso TEXT NOT NULL,
    id_periodo INTEGER NOT NULL,
    id_sede INTEGER NOT NULL,
    capacidad INTEGER NOT NULL,
    modalidad TEXT NOT NULL,
    estado_oferta TEXT NOT NULL,
    CONSTRAINT fk_grupo_curso FOREIGN KEY (codigo_curso)
        REFERENCES curso (codigo_institucional),
    CONSTRAINT fk_grupo_periodo FOREIGN KEY (id_periodo)
        REFERENCES periodo_academico (id_periodo),
    CONSTRAINT fk_grupo_sede FOREIGN KEY (id_sede)
        REFERENCES sede (id_sede),
    CONSTRAINT uq_grupo_contexto UNIQUE (id_periodo, id_sede, codigo_curso, numero_grupo),
    CONSTRAINT ck_grupo_capacidad CHECK (capacidad >= 0),
    CONSTRAINT ck_grupo_modalidad CHECK (modalidad IN ('presencial', 'virtual', 'mixta')),
    CONSTRAINT ck_grupo_estado CHECK (estado_oferta IN ('abierta', 'cerrada', 'cancelada'))
);

CREATE TABLE bloque_horario (
    id_bloque INTEGER CONSTRAINT pk_bloque_horario PRIMARY KEY,
    id_grupo INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    hora_inicio TIME WITHOUT TIME ZONE NOT NULL,
    hora_fin TIME WITHOUT TIME ZONE NOT NULL,
    es_presencial BOOLEAN NOT NULL,
    id_espacio INTEGER,
    CONSTRAINT fk_bloque_grupo FOREIGN KEY (id_grupo)
        REFERENCES grupo (id_grupo),
    CONSTRAINT fk_bloque_espacio FOREIGN KEY (id_espacio)
        REFERENCES espacio (id_espacio),
    CONSTRAINT ck_bloque_dia CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_bloque_horas CHECK (hora_inicio < hora_fin),
    CONSTRAINT ck_bloque_espacio_presencial CHECK (
        NOT es_presencial OR id_espacio IS NOT NULL
    )
);

CREATE TABLE traslado_plan (
    id_traslado INTEGER CONSTRAINT pk_traslado_plan PRIMARY KEY,
    id_admision INTEGER NOT NULL,
    id_version_origen INTEGER NOT NULL,
    id_version_destino INTEGER NOT NULL,
    fecha TIMESTAMP WITH TIME ZONE NOT NULL,
    motivo TEXT NOT NULL,
    id_autorizador INTEGER NOT NULL,
    CONSTRAINT fk_traslado_admision FOREIGN KEY (id_admision)
        REFERENCES admision (id_admision),
    CONSTRAINT fk_traslado_origen FOREIGN KEY (id_version_origen)
        REFERENCES version_plan_estudios (id_version_plan),
    CONSTRAINT fk_traslado_destino FOREIGN KEY (id_version_destino)
        REFERENCES version_plan_estudios (id_version_plan),
    CONSTRAINT fk_traslado_autorizador FOREIGN KEY (id_autorizador)
        REFERENCES persona_autorizadora (id_autorizador),
    CONSTRAINT ck_traslado_versiones_distintas CHECK (
        id_version_origen <> id_version_destino
    ),
    CONSTRAINT ck_traslado_motivo_no_vacio CHECK (motivo ~ '[^[:space:]]')
);

CREATE TABLE reconocimiento_academico (
    id_reconocimiento INTEGER CONSTRAINT pk_reconocimiento_academico PRIMARY KEY,
    id_admision INTEGER NOT NULL,
    referencia_curso_reconocido TEXT,
    codigo_curso_reconocido TEXT,
    id_version_plan INTEGER NOT NULL,
    codigo_curso_satisfecho TEXT NOT NULL,
    resolucion_academica TEXT NOT NULL,
    fecha_resolucion TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_reconocimiento_admision FOREIGN KEY (id_admision)
        REFERENCES admision (id_admision),
    CONSTRAINT fk_reconocimiento_curso_origen FOREIGN KEY (codigo_curso_reconocido)
        REFERENCES curso (codigo_institucional),
    CONSTRAINT fk_reconocimiento_participacion FOREIGN KEY (
        codigo_curso_satisfecho, id_version_plan
    ) REFERENCES participacion_plan (codigo_curso, id_version_plan),
    CONSTRAINT ck_reconocimiento_origen_exclusivo CHECK (
        (referencia_curso_reconocido IS NULL)
        <> (codigo_curso_reconocido IS NULL)
    ),
    CONSTRAINT ck_reconocimiento_referencia_no_vacia CHECK (
        referencia_curso_reconocido IS NULL
        OR referencia_curso_reconocido ~ '[^[:space:]]'
    ),
    CONSTRAINT ck_reconocimiento_resolucion_no_vacia CHECK (
        resolucion_academica ~ '[^[:space:]]'
    )
);

CREATE TABLE grupo_docente (
    id_grupo INTEGER NOT NULL,
    id_docente INTEGER NOT NULL,
    rol TEXT NOT NULL,
    CONSTRAINT pk_grupo_docente PRIMARY KEY (id_grupo, id_docente),
    CONSTRAINT fk_grupo_docente_grupo FOREIGN KEY (id_grupo)
        REFERENCES grupo (id_grupo),
    CONSTRAINT fk_grupo_docente_docente FOREIGN KEY (id_docente)
        REFERENCES docente (id_docente),
    CONSTRAINT ck_grupo_docente_rol CHECK (rol IN ('responsable', 'adicional'))
);

-- Garantiza a lo sumo un responsable; la existencia de uno al publicar
-- se comprueba al confirmar la publicacion de la oferta.
CREATE UNIQUE INDEX uq_grupo_docente_responsable
    ON grupo_docente (id_grupo)
    WHERE rol = 'responsable';

CREATE TABLE historial_oferta (
    id_cambio INTEGER CONSTRAINT pk_historial_oferta PRIMARY KEY,
    id_grupo INTEGER NOT NULL,
    tipo_cambio TEXT NOT NULL,
    estado_anterior TEXT,
    estado_nuevo TEXT,
    cupo_anterior INTEGER,
    cupo_nuevo INTEGER,
    fecha_cambio TIMESTAMP WITH TIME ZONE NOT NULL,
    motivo TEXT NOT NULL,
    id_responsable INTEGER NOT NULL,
    CONSTRAINT fk_historial_oferta_grupo FOREIGN KEY (id_grupo)
        REFERENCES grupo (id_grupo),
    CONSTRAINT fk_historial_oferta_responsable FOREIGN KEY (id_responsable)
        REFERENCES persona_autorizadora (id_autorizador),
    CONSTRAINT ck_historial_oferta_tipo CHECK (
        tipo_cambio IN ('apertura', 'cierre', 'cancelacion', 'cambio_cupo')
    ),
    CONSTRAINT ck_historial_oferta_estados CHECK (
        (estado_anterior IS NULL OR estado_anterior IN ('abierta', 'cerrada', 'cancelada'))
        AND (estado_nuevo IS NULL OR estado_nuevo IN ('abierta', 'cerrada', 'cancelada'))
    ),
    CONSTRAINT ck_historial_oferta_cupos CHECK (
        (cupo_anterior IS NULL OR cupo_anterior >= 0)
        AND (cupo_nuevo IS NULL OR cupo_nuevo >= 0)
    ),
    CONSTRAINT ck_historial_oferta_motivo_no_vacio CHECK (motivo ~ '[^[:space:]]'),
    CONSTRAINT ck_historial_oferta_forma CHECK (
        tipo_cambio NOT IN ('apertura', 'cierre', 'cancelacion', 'cambio_cupo')
        OR
        (tipo_cambio = 'cambio_cupo'
         AND estado_anterior IS NULL AND estado_nuevo IS NULL
         AND cupo_anterior IS NOT NULL AND cupo_nuevo IS NOT NULL
         AND cupo_anterior <> cupo_nuevo)
        OR
        (tipo_cambio = 'apertura'
         AND cupo_anterior IS NULL AND cupo_nuevo IS NULL
         AND estado_nuevo IS NOT NULL AND estado_nuevo = 'abierta'
         AND (estado_anterior IS NULL OR estado_anterior <> estado_nuevo))
        OR
        (tipo_cambio = 'cierre'
         AND cupo_anterior IS NULL AND cupo_nuevo IS NULL
         AND estado_anterior IS NOT NULL AND estado_nuevo IS NOT NULL
         AND estado_nuevo = 'cerrada'
         AND estado_anterior <> estado_nuevo)
        OR
        (tipo_cambio = 'cancelacion'
         AND cupo_anterior IS NULL AND cupo_nuevo IS NULL
         AND estado_anterior IS NOT NULL AND estado_nuevo IS NOT NULL
         AND estado_nuevo = 'cancelada'
         AND estado_anterior <> estado_nuevo)
    )
);

CREATE TABLE solicitud_matricula (
    id_solicitud INTEGER CONSTRAINT pk_solicitud_matricula PRIMARY KEY,
    id_admision INTEGER NOT NULL,
    id_grupo INTEGER NOT NULL,
    id_solicitud_anterior INTEGER,
    id_version_plan_evaluada INTEGER NOT NULL,
    fecha_solicitud TIMESTAMP WITH TIME ZONE NOT NULL,
    estado TEXT NOT NULL,
    razon_rechazo_espera TEXT,
    orden_espera INTEGER,
    momento_transicion TIMESTAMP WITH TIME ZONE,
    calificacion TEXT,
    resultado_academico TEXT,
    CONSTRAINT fk_solicitud_admision FOREIGN KEY (id_admision)
        REFERENCES admision (id_admision),
    CONSTRAINT fk_solicitud_grupo FOREIGN KEY (id_grupo)
        REFERENCES grupo (id_grupo),
    CONSTRAINT fk_solicitud_anterior FOREIGN KEY (id_solicitud_anterior)
        REFERENCES solicitud_matricula (id_solicitud),
    CONSTRAINT fk_solicitud_version FOREIGN KEY (id_version_plan_evaluada)
        REFERENCES version_plan_estudios (id_version_plan),
    CONSTRAINT ck_solicitud_no_autorreferencia CHECK (
        id_solicitud_anterior IS DISTINCT FROM id_solicitud
    ),
    CONSTRAINT ck_solicitud_estado CHECK (
        estado IN ('matriculada', 'rechazada', 'en_espera', 'retirada', 'anulada')
    ),
    CONSTRAINT ck_solicitud_razon CHECK (
        (razon_rechazo_espera IS NULL OR razon_rechazo_espera ~ '[^[:space:]]')
        AND
        (estado NOT IN ('rechazada', 'en_espera') OR razon_rechazo_espera IS NOT NULL)
    ),
    CONSTRAINT ck_solicitud_orden_espera CHECK (
        (orden_espera IS NULL OR orden_espera > 0)
        AND (estado <> 'en_espera' OR orden_espera IS NOT NULL)
    ),
    CONSTRAINT ck_solicitud_calificacion_no_vacia CHECK (
        calificacion IS NULL OR calificacion ~ '[^[:space:]]'
    ),
    CONSTRAINT ck_solicitud_resultado CHECK (
        resultado_academico IS NULL
        OR resultado_academico IN (
            'aprobado', 'reprobado', 'incompleto', 'retiro_justificado'
        )
    )
);

CREATE TABLE historial_solicitud (
    id_evento INTEGER CONSTRAINT pk_historial_solicitud PRIMARY KEY,
    id_solicitud INTEGER NOT NULL,
    tipo_evento TEXT NOT NULL,
    estado_anterior TEXT,
    estado_nuevo TEXT,
    fecha_evento TIMESTAMP WITH TIME ZONE NOT NULL,
    motivo TEXT,
    id_actor INTEGER,
    CONSTRAINT fk_historial_solicitud_solicitud FOREIGN KEY (id_solicitud)
        REFERENCES solicitud_matricula (id_solicitud),
    CONSTRAINT fk_historial_solicitud_actor FOREIGN KEY (id_actor)
        REFERENCES persona_autorizadora (id_autorizador),
    CONSTRAINT ck_historial_solicitud_tipo CHECK (
        tipo_evento IN ('transicion', 'evaluacion_espera')
    ),
    CONSTRAINT ck_historial_solicitud_estados CHECK (
        (estado_anterior IS NULL OR estado_anterior IN (
            'matriculada', 'rechazada', 'en_espera', 'retirada', 'anulada'
        ))
        AND (estado_nuevo IS NULL OR estado_nuevo IN (
            'matriculada', 'rechazada', 'en_espera', 'retirada', 'anulada'
        ))
    ),
    CONSTRAINT ck_historial_solicitud_motivo_no_vacio CHECK (
        motivo IS NULL OR motivo ~ '[^[:space:]]'
    ),
    CONSTRAINT ck_historial_solicitud_forma CHECK (
        tipo_evento NOT IN ('transicion', 'evaluacion_espera')
        OR
        (tipo_evento = 'transicion'
         AND estado_nuevo IS NOT NULL
         AND estado_anterior IS DISTINCT FROM estado_nuevo)
        OR
        (tipo_evento = 'evaluacion_espera'
         AND motivo IS NOT NULL
         AND ((estado_anterior IS NULL AND estado_nuevo IS NULL)
              OR (estado_anterior IS NOT NULL AND estado_nuevo IS NOT NULL
                  AND estado_anterior = estado_nuevo)))
    )
);

CREATE TABLE excepcion_requisito (
    id_excepcion INTEGER CONSTRAINT pk_excepcion_requisito PRIMARY KEY,
    id_solicitud INTEGER NOT NULL,
    id_requisito INTEGER NOT NULL,
    id_autorizador INTEGER NOT NULL,
    fecha_autorizacion TIMESTAMP WITH TIME ZONE NOT NULL,
    motivo TEXT NOT NULL,
    CONSTRAINT fk_excepcion_solicitud FOREIGN KEY (id_solicitud)
        REFERENCES solicitud_matricula (id_solicitud),
    CONSTRAINT fk_excepcion_requisito FOREIGN KEY (id_requisito)
        REFERENCES requisito_curso (id_requisito),
    CONSTRAINT fk_excepcion_autorizador FOREIGN KEY (id_autorizador)
        REFERENCES persona_autorizadora (id_autorizador),
    CONSTRAINT ck_excepcion_motivo_no_vacio CHECK (motivo ~ '[^[:space:]]')
);

CREATE TABLE historial_correccion_calificacion (
    id_correccion INTEGER CONSTRAINT pk_historial_correccion_calificacion PRIMARY KEY,
    id_solicitud INTEGER NOT NULL,
    calificacion_anterior TEXT,
    calificacion_nueva TEXT,
    resultado_anterior TEXT,
    resultado_nuevo TEXT,
    fecha_correccion TIMESTAMP WITH TIME ZONE NOT NULL,
    motivo TEXT NOT NULL,
    id_autorizador INTEGER NOT NULL,
    CONSTRAINT fk_correccion_solicitud FOREIGN KEY (id_solicitud)
        REFERENCES solicitud_matricula (id_solicitud),
    CONSTRAINT fk_correccion_autorizador FOREIGN KEY (id_autorizador)
        REFERENCES persona_autorizadora (id_autorizador),
    CONSTRAINT ck_correccion_calificaciones_no_vacias CHECK (
        (calificacion_anterior IS NULL OR calificacion_anterior ~ '[^[:space:]]')
        AND (calificacion_nueva IS NULL OR calificacion_nueva ~ '[^[:space:]]')
    ),
    CONSTRAINT ck_correccion_resultados CHECK (
        (resultado_anterior IS NULL OR resultado_anterior IN (
            'aprobado', 'reprobado', 'incompleto', 'retiro_justificado'
        ))
        AND (resultado_nuevo IS NULL OR resultado_nuevo IN (
            'aprobado', 'reprobado', 'incompleto', 'retiro_justificado'
        ))
    ),
    CONSTRAINT ck_correccion_cambio_real CHECK (
        calificacion_anterior IS DISTINCT FROM calificacion_nueva
        OR resultado_anterior IS DISTINCT FROM resultado_nuevo
    ),
    CONSTRAINT ck_correccion_motivo_no_vacio CHECK (motivo ~ '[^[:space:]]')
);

COMMIT;
