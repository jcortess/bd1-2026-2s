-- IC-4301 | Laboratorio 3 | Grupo 04 | Alquileres El Roble
-- Script de inserción de datos de prueba (02_datos.sql)

BEGIN;

-- 1. Insertar Personas
INSERT INTO public.persona (tipo_identificacion, identificacion, nombre) VALUES
('Cédula Física', '101110222', 'Carlos Hidalgo'),
('Cédula Física', '202220333', 'Jeremy Solis'),
('Cédula Física', '303330444', 'Keilyn Vega'),
('Cédula Física', '404440555', 'Bryan Charpentier'),
('DIMEX',         '155800123456', 'Stefanie Lara');

-- 2. Insertar Clientes
-- Cliente Físico (asociado a la persona 1)
INSERT INTO public.cliente (tipo_cliente, id_persona, identificacion_organizacion, razon_social, direccion) VALUES
('Física', 1, NULL, NULL, 'Ciudad Quesada, Alajuela');

-- Cliente Organización
INSERT INTO public.cliente (tipo_cliente, id_persona, identificacion_organizacion, razon_social, direccion) VALUES
('Organización', NULL, '3-101-123456', 'Constructora El Roble S.A.', 'Santa Clara, San Carlos');

-- 3. Insertar Catálogo de Facultades
INSERT INTO public.facultad (nombre) VALUES
('Firmar Contratos de Arrendamiento'),
('Retirar Maquinaria y Equipo'),
('Autorizar Mantenimiento'),
('Gestionar Cobros y Facturación');

-- 4. Insertar Autorizaciones
-- Autorización 1: Cliente Organización (ID 2) autoriza a la Persona 2 (Felipe Salazar)
INSERT INTO public.autorizacion (id_cliente, id_persona, inicio_vigencia, fin_vigencia) VALUES
(2, 2, '2026-01-01 08:00:00-06', '2026-12-31 18:00:00-06');

-- Autorización 2: Cliente Físico (ID 1) autoriza a la Persona 3 (Santiago Víquez) sin fin de vigencia (indefinida)
INSERT INTO public.autorizacion (id_cliente, id_persona, inicio_vigencia, fin_vigencia) VALUES
(1, 3, '2026-06-01 08:00:00-06', NULL);

-- 5. Asignar Facultades a las Autorizaciones
-- La Autorización 1 tiene facultades 1 y 2
INSERT INTO public.autorizacion_facultad (id_autorizacion, id_facultad) VALUES
(1, 1),
(1, 2);

-- La Autorización 2 tiene la facultad 2
INSERT INTO public.autorizacion_facultad (id_autorizacion, id_facultad) VALUES
(2, 2);

COMMIT;