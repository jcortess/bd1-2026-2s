
-- LABORATORIO 3 - TALLER RUTA 27
-- GRUPO 02
-- Archivo: 03_consultas.sql
-- Responsable: Jimena
-- Consultas útiles para la gestión del taller.

-- ==========================================
-- CONSULTA 1: ÓRDENES PENDIENTES DE ATENCIÓN
-- ==========================================
-- Pregunta de negocio:
-- ¿Qué vehículos están en diagnóstico o
-- pendientes de autorización?

WITH ultimo_estado AS (
    SELECT DISTINCT ON (orden_id)
        orden_id,
        estado,
        fecha_hora
    FROM historial_orden
    ORDER BY orden_id,
             fecha_hora DESC,
             historial_id DESC
)
SELECT
    o.orden_id,
    v.placa,
    c.nombre_razon_social AS cliente,
    u.estado,
    o.fecha_hora_recepcion
FROM orden_trabajo o
JOIN vehiculo v
    ON o.vin = v.vin
JOIN cliente c
    ON o.cliente_factura_id = c.cliente_id
JOIN ultimo_estado u
    ON o.orden_id = u.orden_id
WHERE u.estado IN (
    'En diagnóstico',
    'Pendiente autorización'
)
ORDER BY o.orden_id;


-- ==========================================
-- CONSULTA 2: CANTIDAD DE VISITAS POR VEHÍCULO
-- ==========================================
-- Pregunta de negocio:
-- ¿Cuántas veces ha ingresado cada vehículo?

SELECT
    v.placa,
    v.marca,
    v.modelo,
    COUNT(o.orden_id) AS total_visitas
FROM vehiculo v
LEFT JOIN orden_trabajo o
    ON v.vin = o.vin
GROUP BY
    v.vin,
    v.placa,
    v.marca,
    v.modelo
ORDER BY total_visitas DESC, v.placa;


-- ==========================================
-- CONSULTA 3: HALLAZGOS DE ALTA URGENCIA
-- ==========================================
-- Pregunta de negocio:
-- ¿Qué vehículos presentan problemas
-- de urgencia alta o crítica?

SELECT
    h.hallazgo_id,
    o.orden_id,
    v.placa,
    h.sintoma_comprobado,
    h.urgencia,
    h.recomendacion
FROM hallazgo h
JOIN orden_trabajo o
    ON h.orden_id = o.orden_id
JOIN vehiculo v
    ON o.vin = v.vin
WHERE h.urgencia IN ('Alta', 'Crítica')
ORDER BY
    CASE h.urgencia
        WHEN 'Crítica' THEN 1
        WHEN 'Alta' THEN 2
    END,
    o.orden_id;


-- ==========================================
-- CONSULTA 4: RESUMEN DE ESTADOS ACTUALES
-- ==========================================
-- Pregunta de negocio:
-- ¿Cuántas órdenes existen en cada estado?

WITH ultimo_estado AS (
    SELECT DISTINCT ON (orden_id)
        orden_id,
        estado
    FROM historial_orden
    ORDER BY orden_id,
             fecha_hora DESC,
             historial_id DESC
)
SELECT
    estado,
    COUNT(*) AS cantidad_ordenes
FROM ultimo_estado
GROUP BY estado
ORDER BY estado;
