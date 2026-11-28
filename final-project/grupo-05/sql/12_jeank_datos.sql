
\set ON_ERROR_STOP on

BEGIN;

SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';

-- ============================================================
-- HUELLAS SEGURAS - GRUPO 05
-- DATOS FICTICIOS DEL BLOQUE 
-- ============================================================

-- 1. INDICACIONES VETERINARIAS

INSERT INTO indicacion (
    id_indicacion,
    evaluacion_id,
    tipo_indicacion,
    descripcion,
    estado_indicacion
)
VALUES
    (
        2001,
        1001,
        'TRATAMIENTO',
        'Tratamiento dermatologico ficticio',
        'VIGENTE'
    ),
    (
        2002,
        1001,
        'CONTROL_POSTERIOR',
        'Control veterinario de oido',
        'VIGENTE'
    );

-- Indicacion que sustituye una anterior.

INSERT INTO indicacion (
    id_indicacion,
    evaluacion_id,
    tipo_indicacion,
    descripcion,
    estado_indicacion,
    indicacion_sustituida_id
)
VALUES (
    2003,
    1002,
    'TRATAMIENTO',
    'Ajuste ficticio del tratamiento dermatologico',
    'VIGENTE',
    2001
);


-- 2. DIAGNOSTICOS ASOCIADOS A LAS INDICACIONES

INSERT INTO indicacion_diagnostico (
    indicacion_id,
    evaluacion_id,
    diagnostico_id
)
VALUES
    (2001, 1001, 1),
    (2002, 1001, 2),
    (2003, 1002, 1);


-- 3. APLICACIONES DE INDICACIONES

INSERT INTO aplicacion_indicacion (
    id_aplicacion,
    indicacion_id,
    fecha_planificada,
    fecha_real,
    responsable_id,
    observaciones
)
VALUES (
    3001,
    2001,
    '2026-10-05 11:00',
    '2026-10-05 11:15',
    7,
    'Aplicacion ficticia realizada'
);

INSERT INTO aplicacion_indicacion (
    id_aplicacion,
    indicacion_id,
    fecha_planificada
)
VALUES
    (3002, 2002, '2026-10-07 09:00'),
    (3003, 2003, '2026-12-15 09:00');


-- 4. SINCRONIZAR IDENTIDADES

SELECT setval(
    pg_get_serial_sequence(
        'indicacion',
        'id_indicacion'
    ),
    (SELECT max(id_indicacion) FROM indicacion)
);

SELECT setval(
    pg_get_serial_sequence(
        'aplicacion_indicacion',
        'id_aplicacion'
    ),
    (SELECT max(id_aplicacion) FROM aplicacion_indicacion)
);


-- 5. RESTRICCION DOCUMENTADA DE EJEMPLO

INSERT INTO restriccion_persona (
    persona_afectada_id,
    motivo,
    fecha_inicio,
    responsable_decision_id
)
VALUES (
    103,
    'Decision ficticia documentada para pruebas de integridad',
    '2026-10-07 10:00',
    1
);


COMMIT;
