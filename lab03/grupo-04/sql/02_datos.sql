-- Datos ficticios; IDs explicitos compatibles con 01_esquema.sql.
-- Fecha de referencia: 2026-10-29 10:00:00-06.
BEGIN;
INSERT INTO public.persona (id_persona, tipo_identificacion, identificacion, nombre) VALUES
(1, 'Documento de prueba', 'DOC-FICT-001', 'Ana Prueba'),
(2, 'Documento de prueba', 'DOC-FICT-002', 'Bruno Prueba'),
(3, 'Documento de prueba', 'DOC-FICT-003', 'Carla Prueba'),
(4, 'Documento de prueba', 'DOC-FICT-004', 'Diego Prueba'),
(5, 'Documento de prueba', 'DOC-FICT-005', 'Elena Prueba');
INSERT INTO public.cliente (id_cliente, tipo_cliente, id_persona, identificacion_organizacion, razon_social, direccion) VALUES
(1, 'Física', 1, NULL, NULL, 'Direccion ficticia A'),
(2, 'Organización', NULL, 'ORG-FICT-002', 'Constructora de Prueba', 'Direccion ficticia B'),
(3, 'Organización', NULL, 'ORG-FICT-003', 'Jardines de Prueba', 'Direccion ficticia C'),
(4, 'Organización', NULL, 'ORG-FICT-004', 'Organizacion sin Autorizaciones', 'Direccion ficticia D');
INSERT INTO public.facultad (id_facultad, nombre) VALUES
(1, 'Reservar'), (2, 'Recibir'), (3, 'Devolver'), (4, 'Consultar cotizacion');
INSERT INTO public.autorizacion (id_autorizacion, id_cliente, id_persona, inicio_vigencia, fin_vigencia) VALUES
(1, 2, 2, '2026-01-01 08:00:00-06', '2026-12-31 18:00:00-06'),
(2, 2, 3, '2026-06-01 08:00:00-06', NULL),
(3, 2, 4, '2026-01-01 08:00:00-06', '2026-02-01 08:00:00-06'),
(4, 2, 5, '2026-12-01 08:00:00-06', '2027-01-01 08:00:00-06'),
(5, 3, 2, '2026-01-01 08:00:00-06', '2026-12-31 18:00:00-06'),
(6, 2, 2, '2026-10-01 08:00:00-06', '2026-12-31 18:00:00-06');
INSERT INTO public.autorizacion_facultad (id_autorizacion, id_facultad) VALUES
(1,1), (1,2), (2,2), (2,3), (3,1), (4,1), (5,3), (6,1);
COMMIT;
