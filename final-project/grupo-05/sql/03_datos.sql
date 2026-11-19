\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = huellas, pg_catalog;
SET LOCAL TIME ZONE 'America/Costa_Rica';

-- Datos ficticios. Los identificadores de prueba se asignan en orden desde 1.
INSERT INTO persona (nombre_identificacion) VALUES
    ('Operadora de turno'), ('Oferente A'), ('Oferente pendiente'), ('Oferente con vigencia corta'),
    ('Oferente B'), ('Oferente con aprobación al límite'), ('Operador de relevo'), (NULL);

INSERT INTO medio_contacto (persona_id, tipo_medio, valor) VALUES
    (2, 'CORREO', 'oferente-a@example.invalid'), (5, 'CORREO', 'oferente-b@example.invalid');

INSERT INTO participacion (persona_id, tipo_participacion, fecha_inicio, fecha_fin, requisitos,
                           estado_aprobacion_registro, fecha_aprobacion_registro) VALUES
    (1, 'PERSONAL_PERMANENTE', '2026-10-01', NULL, NULL, NULL, NULL),
    (2, 'HOGAR_TEMPORAL', '2026-10-01', NULL, 'Condiciones del hogar verificadas', 'APROBADO', '2026-10-01'),
    (3, 'HOGAR_TEMPORAL', '2026-10-01', NULL, NULL, 'PENDIENTE', NULL),
    (4, 'HOGAR_TEMPORAL', '2026-10-01', '2026-10-06 10:00', NULL, 'APROBADO', '2026-10-01'),
    (5, 'HOGAR_TEMPORAL', '2026-10-01', NULL, 'Condiciones del hogar verificadas', 'APROBADO', '2026-10-01'),
    (6, 'HOGAR_TEMPORAL', '2026-10-01', NULL, NULL, 'APROBADO', '2026-10-06 10:00'),
    (7, 'VOLUNTARIO', '2026-10-01', NULL, NULL, NULL, NULL),
    (7, 'VETERINARIO', '2026-10-01', NULL, 'Registro ficticio', 'REGISTRADO', '2026-10-01');

INSERT INTO animal (codigo_interno, nombre, especie, edad_estimada, numero_microchip) VALUES
    ('HS-01', 'Luna', 'PERRO', 18, '000451'),
    ('HS-02', 'Milo', 'PERRO', 0, NULL),
    ('HS-03', 'Nube', 'GATO', NULL, NULL),
    ('HS-04', 'Nilo', 'PERRO', NULL, NULL),
    ('HS-05', 'Alba', 'PERRO', NULL, NULL),
    ('HS-06', 'Tico', 'PERRO', NULL, NULL),
    ('HS-07', 'Menta', 'PERRO', NULL, NULL),
    ('HS-08', 'Sol', 'PERRO', NULL, NULL),
    ('HS-09', 'Lila', 'PERRO', NULL, NULL),
    ('HS-10', 'Bruno', 'PERRO', NULL, NULL),
    ('HS-11', 'Tila', 'PERRO', NULL, NULL),
    ('HS-12', 'Kiwi', 'PERRO', NULL, NULL),
    ('HS-13', 'Coco', 'PERRO', NULL, NULL),
    ('HS-14', 'Zafiro', 'PERRO', NULL, NULL),
    ('HS-15', 'Fito', 'PERRO', NULL, NULL),
    ('HS-16', 'Canela', 'PERRO', NULL, NULL),
    ('HS-17', 'Sombra', 'PERRO', NULL, NULL);

INSERT INTO organizacion_externa (nombre_organizacion) VALUES ('Red de rescate ficticia');

INSERT INTO ingreso (animal_codigo, fecha_ingreso, lugar_ingreso, condicion_general,
                     circunstancia_ingreso, organizacion_origen_id)
SELECT codigo_interno, '2026-10-04 08:00', 'Recepción del refugio', 'Alerta al ingreso',
       CASE WHEN codigo_interno = 'HS-02' THEN 'TRASLADO' ELSE 'RESCATE' END,
       CASE WHEN codigo_interno = 'HS-02' THEN 1 END
FROM animal ORDER BY codigo_interno;

INSERT INTO ubicacion (tipo_ubicacion, nombre_descripcion, capacidad, condicion_admitida,
                       disponibilidad_desde, disponibilidad_hasta, persona_oferente_id, codigo_hogar)
VALUES
    ('AREA_INTERNA', 'Sala de convivencia', 2, 'CONVIVENCIA', NULL, NULL, NULL, NULL),
    ('HOGAR_TEMPORAL', 'Casa A, primera oferta', 1, NULL, '2026-10-05', '2026-10-10', 2, 'CASA-A'),
    ('ATENCION_EXTERNA', 'Centro de atención ficticio', NULL, NULL, NULL, NULL, NULL, NULL),
    ('HOGAR_TEMPORAL', 'Casa pendiente', 1, NULL, '2026-10-05', '2026-10-10', 3, 'CASA-P'),
    ('HOGAR_TEMPORAL', 'Casa con participación corta', 1, NULL, '2026-10-05', '2026-10-10', 4, 'CASA-C'),
    ('HOGAR_TEMPORAL', 'Casa A, segunda oferta', 1, NULL, '2026-10-10', '2026-10-15', 5, 'CASA-A'),
    ('AREA_INTERNA', 'Aislamiento de un cupo', 1, 'AISLAMIENTO', NULL, NULL, NULL, NULL),
    ('HOGAR_TEMPORAL', 'Casa X', 2, NULL, '2026-10-05', '2026-10-15', 2, 'CASA-X'),
    ('HOGAR_TEMPORAL', 'Casa Y', 2, NULL, '2026-10-05', '2026-10-15', 5, 'CASA-Y'),
    ('HOGAR_TEMPORAL', 'Casa con aprobación al límite', 1, NULL, '2026-10-05', '2026-10-10', 6, 'CASA-L'),
    ('HOGAR_TEMPORAL', 'Casa sin especies por confirmar', 1, NULL, '2026-10-05', '2026-10-10', 2, 'CASA-S');

INSERT INTO ubicacion_especie_aceptada (ubicacion_id, especie)
VALUES (2, 'PERRO'), (4, 'PERRO'), (5, 'PERRO'), (6, 'PERRO'), (8, 'PERRO'), (9, 'PERRO'), (10, 'PERRO');

COMMIT;
