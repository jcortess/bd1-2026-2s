-- Universidad Horizonte, Grupo 03. Datos ficticios complementarios.
-- Prerrequisitos: 01/02 base y 03_esquema_relaciones.sql, en ese orden.
-- No constituyen resultados de ejecutar G03-P01, G03-P02 ni G03-P03.
-- Sus operaciones y transiciones se probaran en una transaccion revertida.

BEGIN;
SET LOCAL search_path TO public;

-- Admision historica adicional para representar un traslado no asignado.
INSERT INTO admision (
    id_admision, numero_institucional, id_sede, id_version_plan,
    fecha_ingreso, condicion_academica, activa
) VALUES (3, 'UH-ALU1', 1, 102, DATE '2024-08-01', 'regular', TRUE);

INSERT INTO grupo (
    id_grupo, numero_grupo, codigo_curso, id_periodo, id_sede,
    capacidad, modalidad, estado_oferta
) VALUES
    (10, 1, 'UH-BDAT1', 1, 1, 0, 'presencial', 'cerrada'),
    (11, 1, 'UH-MAT1',  1, 2, 3, 'virtual',    'cerrada'),
    (12, 1, 'UH-PROG1', 1, 1, 2, 'mixta',     'cerrada'),
    (13, 2, 'UH-BDAT1', 1, 1, 1, 'presencial','cerrada');

INSERT INTO bloque_horario (
    id_bloque, id_grupo, dia_semana, hora_inicio, hora_fin,
    es_presencial, id_espacio
) VALUES
    (100, 10, 1, TIME '08:00', TIME '10:00', TRUE, 1),
    (101, 11, 1, TIME '08:00', TIME '10:00', FALSE, NULL),
    (102, 12, 1, TIME '10:00', TIME '12:00', TRUE, 1),
    (103, 12, 2, TIME '08:00', TIME '09:00', FALSE, NULL),
    (104, 13, 3, TIME '08:00', TIME '10:00', TRUE, 1);

INSERT INTO grupo_docente (id_grupo, id_docente, rol) VALUES
    (10, 1, 'responsable'),
    (11, 2, 'responsable'),
    (12, 1, 'responsable'),
    (12, 2, 'adicional'),
    (13, 2, 'responsable');

-- Traslado y reconocimiento: hechos academicos de procesos no asignados.
-- La admision 3 conserva la version 102 como asignacion actual.
INSERT INTO traslado_plan (
    id_traslado, id_admision, id_version_origen,
    id_version_destino, fecha, motivo, id_autorizador
) VALUES (
    200, 3, 101, 102, '2026-02-02 09:00:00-06',
    'Actualizacion voluntaria al plan 102', 1
);

INSERT INTO reconocimiento_academico (
    id_reconocimiento, id_admision, referencia_curso_reconocido,
    codigo_curso_reconocido, id_version_plan,
    codigo_curso_satisfecho, resolucion_academica, fecha_resolucion
) VALUES (
    300, 1, 'EXT-FUND-101', NULL, 102,
    'UH-PROG1', 'RES-UH-300', '2026-09-03 10:00:00-06'
);

-- Sin solicitudes matriculadas, listas de espera o cambios de oferta
-- precargados: las pruebas temporales verifican esas estructuras.
COMMIT;
