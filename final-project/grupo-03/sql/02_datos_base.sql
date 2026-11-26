-- Universidad Horizonte, Grupo 03. Datos iniciales ficticios.
-- Curriculo: datos originales de lab03/grupo-03/sql/02_datos.sql.
-- Adaptacion temporal: 2024-2025 y 2026-2027 se expresan con fechas ficticias
-- de 1 de enero a 31 de diciembre; NO se infieren fechas institucionales reales.
-- Ejecutar una sola vez, tras 01_esquema_base.sql, sobre la base nueva.

BEGIN;
SET LOCAL search_path TO public;

INSERT INTO escuela (id_escuela) VALUES (1), (2);
INSERT INTO carrera (id_carrera) VALUES (10), (20);

INSERT INTO sede (id_sede, nombre) VALUES
    (1, 'Sede Norte'), (2, 'Sede Central');

INSERT INTO estudiante (numero_institucional, nombre, primer_apellido, segundo_apellido) VALUES
    ('UH-ALU1', 'Ana', 'Jimenez', NULL),
    ('UH-ALU2', 'Luis', 'Rojas', 'Mora');

INSERT INTO docente (id_docente, nombre) VALUES
    (1, 'Docente Uno'), (2, 'Docente Dos');

INSERT INTO persona_autorizadora (id_autorizador, nombre, identificacion_institucional) VALUES
    (1, 'Autorizante Uno', 'UH-AUT-01'),
    (2, 'Autorizante Dos', 'UH-AUT-02');

INSERT INTO periodo_academico (
    id_periodo, codigo_periodo, fecha_inicio, fecha_finalizacion
) VALUES
    (1, '2026-2', DATE '2026-08-01', DATE '2026-12-15');

-- Registros curriculares del Lab03.
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

INSERT INTO version_plan_estudios (
    id_version_plan, inicio_vigencia, fin_vigencia, id_carrera
) VALUES
    (101, DATE '2024-01-01', DATE '2025-12-31', 10),
    (102, DATE '2026-01-01', DATE '2027-12-31', 10),
    (201, DATE '2026-01-01', DATE '2027-12-31', 20);

INSERT INTO carrera_sede (id_carrera, id_sede) VALUES
    (10, 1), (10, 2), (20, 2);

INSERT INTO espacio (id_espacio, id_sede, capacidad, ubicacion) VALUES
    (1, 1, 30, 'Edificio Norte, aula 1'),
    (2, 2, 20, 'Edificio Central, aula 2');

INSERT INTO contacto_estudiante (
    id_contacto, numero_institucional, tipo_contacto, valor, es_principal
) VALUES
    (1, 'UH-ALU1', 'correo', 'ana@example.test', TRUE),
    (2, 'UH-ALU1', 'telefono', '0000-0001', TRUE),
    (3, 'UH-ALU2', 'correo', 'luis@example.test', TRUE);

-- Los instantes y offsets se fijan explicitamente SOLO para este conjunto ficticio.
INSERT INTO ventana_periodo (
    id_ventana, id_periodo, tipo_ventana, inicio, fin
) VALUES
    (1, 1, 'matricula', '2026-07-01 00:00:00-06', '2026-07-10 00:00:00-06'),
    (2, 1, 'matricula', '2026-07-10 00:00:00-06', '2026-07-12 00:00:00-06'),
    (3, 1, 'modificacion', '2026-07-10 00:00:00-06', '2026-07-15 00:00:00-06'),
    (4, 1, 'retiro', '2026-08-01 00:00:00-06', '2026-08-20 00:00:00-06');

INSERT INTO participacion_plan (
    codigo_curso, id_version_plan, tipo_participacion, nivel_o_periodo_recomendado
) VALUES
    ('UH-PROG1', 101, 'Obligatorio', '1'),
    ('UH-MAT1',  101, 'Obligatorio', '1'),
    ('UH-PROG2', 101, 'Obligatorio', '2'),
    ('UH-BDAT1', 101, 'Obligatorio', '3'),
    ('UH-ALG1',  101, 'Obligatorio', '3'),
    ('UH-EST1',  101, 'Optativo',    '4'),
    ('UH-PROG1', 102, 'Obligatorio', '1'),
    ('UH-MAT1',  102, 'Obligatorio', '1'),
    ('UH-PROG2', 102, 'Obligatorio', '2'),
    ('UH-BDAT1', 102, 'Obligatorio', '3'),
    ('UH-ALG1',  102, 'Obligatorio', '3'),
    ('UH-EST1',  102, 'Obligatorio', '3'),
    ('UH-RED1',  102, 'Optativo',    '4'),
    ('UH-MAT1', 201, 'Obligatorio', '1'),
    ('UH-SIS1', 201, 'Obligatorio', '2'),
    ('UH-EST1', 201, 'Optativo',    '3');

INSERT INTO requisito_curso (
    id_version_plan, codigo_curso_objetivo, codigo_curso_exigido, tipo_requisito
) VALUES
    (101, 'UH-PROG2', 'UH-PROG1', 'Requisito previo'),
    (101, 'UH-BDAT1', 'UH-PROG2', 'Requisito previo'),
    (101, 'UH-BDAT1', 'UH-MAT1', 'Correquisito'),
    (101, 'UH-ALG1',  'UH-PROG2', 'Requisito previo'),
    (102, 'UH-PROG2', 'UH-PROG1', 'Requisito previo'),
    (102, 'UH-BDAT1', 'UH-PROG2', 'Requisito previo'),
    (102, 'UH-BDAT1', 'UH-MAT1', 'Correquisito'),
    (102, 'UH-BDAT1', 'UH-EST1', 'Correquisito'),
    (102, 'UH-ALG1',  'UH-PROG2', 'Requisito previo'),
    (201, 'UH-SIS1',  'UH-MAT1', 'Correquisito');

INSERT INTO admision (
    id_admision, numero_institucional, id_sede, id_version_plan,
    fecha_ingreso, condicion_academica, activa
) VALUES
    (1, 'UH-ALU1', 1, 102, DATE '2026-08-01', 'regular', TRUE),
    (2, 'UH-ALU2', 2, 201, DATE '2026-08-15', 'regular', TRUE);

COMMIT;
