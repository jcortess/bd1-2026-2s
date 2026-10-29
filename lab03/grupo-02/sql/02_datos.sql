
-- LABORATORIO 3 - TALLER RUTA 27 / GRUPO 02


-- 1. REGISTRAR CLIENTES
INSERT INTO cliente
(cliente_id, identificacion, nombre_razon_social, tipo_cliente)
VALUES
(101, 'FICT-P001', 'María Rojas', 'Persona'),
(102, 'FICT-P002', 'Carlos Méndez', 'Persona'),
(103, 'FICT-O003', 'Transportes del Valle S.A.', 'Organización'),
(104, 'FICT-P004', 'Ana Solís', 'Persona'),
(105, 'FICT-O005', 'Mensajería Central S.A.', 'Organización');


-- 2. REGISTRAR VEHÍCULOS
INSERT INTO vehiculo
(vin, placa, marca, modelo, anio, tipo_combustible)
VALUES
('1HGCM82633A123456', 'ABC123', 'Honda', 'Accord', 2018, 'Gasolina'),
('3VWFE21C04M000001', 'DEF456', 'Volkswagen', 'Jetta', 2020, 'Gasolina'),
('1FTFW1ET1EFA00001', 'GHI789', 'Ford', 'F-150', 2022, 'Diésel'),
('2T1BURHE5JC000001', 'JKL012', 'Toyota', 'Corolla', 2021, 'Híbrido');


-- 3. REGISTRAR PERSONAL DEL TALLER
INSERT INTO personal
(personal_id, nombre, rol)
VALUES
(201, 'Lucía Vargas', 'Recepción'),
(202, 'Diego Mora', 'Técnico'),
(203, 'Sofía Arias', 'Técnico');


-- 4. REGISTRAR ÓRDENES DE TRABAJO
INSERT INTO orden_trabajo (
    orden_id,
    vin,
    cliente_factura_id,
    entregado_por_cliente_id,
    autorizador_cliente_id,
    receptor_id,
    fecha_hora_recepcion,
    kilometraje_ingreso,
    nivel_combustible,
    motivo_informado,
    observaciones_visibles,
    fecha_prometida_actual
)
VALUES
(9001, '1HGCM82633A123456', 101, 101, 101, 201,
 '2026-10-05 08:15', 85000, '1/2',
 'Ruido al frenar',
 'Rayón leve en puerta',
 '2026-10-07 16:00'),

(9002, '3VWFE21C04M000001', 102, 102, 102, 201,
 '2026-10-06 09:10', 42000, '3/4',
 'Pérdida de potencia',
 NULL,
 '2026-10-09 16:00'),

(9003, '1HGCM82633A123456', 101, 104, 101, 201,
 '2026-10-08 10:20', 85300, '1/4',
 'Fuga de líquido de frenos',
 'Vehículo llegó en grúa',
 NULL),

(9004, '1FTFW1ET1EFA00001', 103, 104, 103, 201,
 '2026-10-09 11:00', 99000, 'Lleno',
 'Mantenimiento preventivo',
 NULL,
 '2026-10-12 15:00'),

(9005, '2T1BURHE5JC000001', 105, 104, 105, 201,
 '2026-10-10 08:30', 23000, '1/2',
 'Revisión por vibración',
 NULL,
 NULL);


-- 5. REGISTRAR HISTORIAL DE LAS ÓRDENES
INSERT INTO historial_orden
(orden_id, estado, fecha_hora, personal_id)
VALUES
(9001, 'Recibida', '2026-10-05 08:15', 201),
(9001, 'En diagnóstico', '2026-10-05 09:00', 202),
(9001, 'En reparación', '2026-10-06 08:00', 202),

(9002, 'Recibida', '2026-10-06 09:10', 201),
(9002, 'Pendiente autorización', '2026-10-06 11:30', 201),

(9003, 'Recibida', '2026-10-08 10:20', 201),
(9003, 'En diagnóstico', '2026-10-08 11:00', 203),

(9004, 'Recibida', '2026-10-09 11:00', 201),
(9004, 'Autorizada', '2026-10-09 14:00', 201),

(9005, 'Recibida', '2026-10-10 08:30', 201),
(9005, 'Cancelada', '2026-10-10 09:10', 201);


-- 6. REGISTRAR HALLAZGOS TÉCNICOS
INSERT INTO hallazgo
(hallazgo_id, orden_id, sintoma_comprobado,
 posible_causa, urgencia, recomendacion)
VALUES
(4101, 9001,
 'Vibración leve al frenar',
 'Pastillas desgastadas',
 'Media',
 'Revisar y reemplazar pastillas'),

(4102, 9001,
 'Desgaste de limpiaparabrisas',
 'Uso normal',
 'Baja',
 'Sustituir escobillas'),

(4103, 9002,
 'Falla al acelerar',
 'Sensor defectuoso',
 'Alta',
 'Diagnóstico electrónico prioritario'),

(4104, 9003,
 'Pérdida de presión de frenado',
 'Fuga hidráulica',
 'Crítica',
 'No circular hasta reparar el sistema de frenos'),

(4105, 9004,
 'Filtro de aire sucio',
 'Intervalo de mantenimiento',
 'Baja',
 'Cambiar filtro durante el servicio');

-- RESUMEN DE DATOS INSERTADOS
-- 5 clientes
-- 4 vehículos
-- 3 trabajadores
-- 5 órdenes de trabajo
-- 11 registros de historial
-- 5 hallazgos técnicos
