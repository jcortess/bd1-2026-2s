-- ==================================
-- Labotario 3 - Dilan Andrey Sibaja Ugalde
-- 02_datos - definicion del esquema fisico (Postgress)
--proceso de negocio: registro de una finca por un productor
--version de PostgreSQL utilizada: 18
-- ==================================
-- suficiente para observar las relaciones:
-- (1 o varios) correo_productor -> productor <- telefono_productor (1 o varios)
-- (1 o varios) correo_persona_responsable -> persona_responsable  <- telefono_persona_responsable  (1 o varios)
-- productor <-- finca --> persona_responsable 
-- productor <-- finca --> null
-- finca<--historial<--registro_responsables--> persona_responsable
BEGIN;
-- 1. Productores
INSERT INTO productores (
        productor_id,
        nombre,
        fecha_de_afiliacion,
        condicion
    )
VALUES (
        'productor-0001',
        'Manuel Alfaro Ugalde',
        '15/03/2021',
        'activo'
    ),
    (
        'productor-0002',
        'Juan Rodríguez Mora',
        '02/08/2022',
        'activo'
    );
-- Teléfonos de productores
INSERT INTO telefonos_productor (productor_id, telefono)
VALUES ('productor-0001', '2460-1234'),
    ('productor-0001', '8845-6721'),
    ('productor-0001', '2461-9087'),
    ('productor-0002', '8712-3456');
-- Correos de productores
INSERT INTO correos_productor (productor_id, correo)
VALUES ('productor-0001', 'contacto@losandes.co.cr'),
    (
        'productor-0001',
        'administracion@losandes.co.cr'
    ),
    ('productor-0002', 'juan.rodriguez@gmail.com');
-- 2. Personas responsables
INSERT INTO personas_responsables (responsable_id, nombre)
VALUES ('responsable-0001', 'María Fernández Solís'),
    ('responsable-0002', 'Carlos Vargas Jiménez'),
    ('responsable-0003', 'Ana Lucía Rojas Campos');
-- Teléfonos de personas responsables
INSERT INTO telefonos_persona_responsable (responsable_id, telefono)
VALUES ('responsable-0001', '8890-1122'),
    ('responsable-0001', '2237-4455'),
    ('responsable-0002', '7015-3344'),
    ('responsable-0003', '8321-9988'),
    ('responsable-0003', '2278-6601'),
    ('responsable-0003', '6190-2273');
-- Correos de personas responsables
INSERT INTO correos_persona_responsable (responsable_id, correo)
VALUES ('responsable-0001', 'maria.fernandez@gmail.com'),
    ('responsable-0002', 'carlos.vargas@gmail.com'),
    (
        'responsable-0002',
        'cvargas@fincaslaesperanza.com'
    ),
    ('responsable-0003', 'analucia.rojas@outlook.com');
-- 3. Fincas (productor <- finca -> responsable)
INSERT INTO fincas (
        productor_id,
        finca_id,
        responsable_id,
        provincia,
        canton,
        distrito,
        indicacion_especifica,
        area_aproximada
    )
VALUES (
        'productor-0001',
        'finca-0001',
        'responsable-0001',
        'Alajuela',
        'San Carlos',
        'Quesada',
        '200 metros norte de la iglesia católica',
        '1500 m²'
    ),
    (
        'productor-0001',
        'finca-0002',
        'responsable-0002',
        'Heredia',
        'Sarapiquí',
        'Puerto Viejo',
        'Camino a La Chiripa, 3 km al este de la escuela',
        '25000 m²'
    ),
    (
        'productor-0002',
        'finca-0001',
        'responsable-0003',
        'Cartago',
        'Turrialba',
        'Santa Rosa',
        'Frente al río, portón verde',
        '12000.50 m²'
    ),
    (
        'productor-0002',
        'finca-0002',
        NULL,
        'Guanacaste',
        'Nicoya',
        'Nosara',
        '1 km sur del palo de mango del parque,',
        '8000.75 m²'
    );
-- 4. Historiales (uno por finca, relación 1 a 1)
INSERT INTO historiales_responsable (
        historial_responsables_id,
        productor_id,
        finca_id
    )
VALUES (
        'historialR-0001',
        'productor-0001',
        'finca-0001'
    ),
    (
        'historialR-0002',
        'productor-0001',
        'finca-0002'
    ),
    (
        'historialR-0003',
        'productor-0002',
        'finca-0001'
    ),
    (
        'historialR-0004',
        'productor-0002',
        'finca-0002'
    );
-- 5. Registros en historial (historial <- registro -> responsable)
INSERT INTO registro_en_historial (
        historial_responsables_id,
        productor_id,
        finca_id,
        responsable_id,
        fecha_de_ingreso_como_responsable,
        fecha_de_salida_como_responsable
    )
VALUES (
        'historialR-0001',
        'productor-0001',
        'finca-0001',
        'responsable-0002',
        '10/01/2020',
        '14/03/2021'
    ),
    (
        'historialR-0001',
        'productor-0001',
        'finca-0001',
        'responsable-0001',
        '15/03/2021',
        NULL
    ),
    (
        'historialR-0002',
        'productor-0001',
        'finca-0002',
        'responsable-0002',
        '01/06/2021',
        NULL
    ),
    (
        'historialR-0003',
        'productor-0002',
        'finca-0001',
        'responsable-0001',
        '05/02/2022',
        '30/09/2023'
    ),
    (
        'historialR-0003',
        'productor-0002',
        'finca-0001',
        'responsable-0003',
        '01/10/2023',
        NULL
    ),
    (
        'historialR-0004',
        'productor-0002',
        'finca-0002',
        'responsable-0003',
        '01/01/2024',
        '31/12/2024'
    );
COMMIT;