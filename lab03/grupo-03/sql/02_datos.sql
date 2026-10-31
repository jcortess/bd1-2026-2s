
-- Laboratorio 03 - Grupo 03
-- Datos ficticios del subsistema curricular.

BEGIN;

-- 1. Escuelas y carreras
INSERT INTO escuela (id_escuela) VALUES
    (1),
    (2);

INSERT INTO carrera (id_carrera) VALUES
    (10),
    (20);

-- 2. Cursos del catalogo institucional ficticio
INSERT INTO curso (
    codigo_institucional, nombre, cantidad_creditos, id_escuela
) VALUES
    ('UH-PROG1', 'Introduccion a la Programacion', 4, 1),
    ('UH-PROG2', 'Programacion Intermedia', 4, 1),
    ('UH-BDAT1', 'Bases de Datos', 4, 1),
    ('UH-ALG1',  'Algoritmos y Estructuras', 4, 1),
    ('UH-MAT1',  'Matematica Discreta', 3, 2),
    ('UH-EST1',  'Estadistica Aplicada', 3, 2),
    ('UH-RED1',  'Redes de Computadoras', 3, 1),
    ('UH-SIS1',  'Sistemas Digitales', 3, 1);

-- 3. Versiones de los planes de estudio
-- La vigencia se almacena como texto provisional.
INSERT INTO version_plan_estudios (
    id_version_plan, vigencia, id_carrera
) VALUES
    (101, '2024-2025', 10),
    (102, '2026-2027', 10),
    (201, '2026-2027', 20);

-- 4. Participacion de cursos en cada version del plan
INSERT INTO participacion_plan (
    codigo_curso,
    id_version_plan,
    tipo_participacion,
    nivel_o_periodo_recomendado
) VALUES
    -- Version 101
    ('UH-PROG1', 101, 'Obligatorio', '1'),
    ('UH-MAT1',  101, 'Obligatorio', '1'),
    ('UH-PROG2', 101, 'Obligatorio', '2'),
    ('UH-BDAT1', 101, 'Obligatorio', '3'),
    ('UH-ALG1',  101, 'Obligatorio', '3'),
    ('UH-EST1',  101, 'Optativo',    '4'),

    -- Version 102
    ('UH-PROG1', 102, 'Obligatorio', '1'),
    ('UH-MAT1',  102, 'Obligatorio', '1'),
    ('UH-PROG2', 102, 'Obligatorio', '2'),
    ('UH-BDAT1', 102, 'Obligatorio', '3'),
    ('UH-ALG1',  102, 'Obligatorio', '3'),
    ('UH-EST1',  102, 'Obligatorio', '3'),
    ('UH-RED1',  102, 'Optativo',    '4'),

    -- Version 201
    ('UH-MAT1', 201, 'Obligatorio', '1'),
    ('UH-SIS1', 201, 'Obligatorio', '2'),
    ('UH-EST1', 201, 'Optativo',    '3');

-- 5. Requisitos previos y correquisitos
INSERT INTO requisito_curso (
    id_version_plan,
    codigo_curso_objetivo,
    codigo_curso_exigido,
    tipo_requisito
) VALUES
    -- Version 101
    (101, 'UH-PROG2', 'UH-PROG1', 'Requisito previo'),
    (101, 'UH-BDAT1', 'UH-PROG2', 'Requisito previo'),
    (101, 'UH-BDAT1', 'UH-MAT1',  'Correquisito'),
    (101, 'UH-ALG1',  'UH-PROG2', 'Requisito previo'),

    -- Version 102
    (102, 'UH-PROG2', 'UH-PROG1', 'Requisito previo'),
    (102, 'UH-BDAT1', 'UH-PROG2', 'Requisito previo'),
    (102, 'UH-BDAT1', 'UH-MAT1',  'Correquisito'),
    (102, 'UH-BDAT1', 'UH-EST1',  'Correquisito'),
    (102, 'UH-ALG1',  'UH-PROG2', 'Requisito previo'),

    -- Version 201
    (201, 'UH-SIS1',  'UH-MAT1',  'Correquisito');

COMMIT;
