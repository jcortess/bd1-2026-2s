-- ============================================================
-- Laboratorio 3 · grupo-test
-- 03_consultas.sql — Consultas de negocio
-- Ejecutar después de 01_esquema.sql, 02_datos.sql y 04_rutinas.sql.
-- ============================================================

-- ------------------------------------------------------------
-- Consulta 1 (combina dos o más tablas)
-- Pregunta de negocio: ¿qué pedidos ha realizado cada cliente y
-- en qué estado se encuentran?
-- Resultado esperado con los datos de prueba: 4 filas, una por
-- pedido, con el nombre del cliente correspondiente.
-- ------------------------------------------------------------
SELECT c.nombre   AS cliente,
       pe.pedido_id,
       pe.estado,
       pe.creado_en
  FROM pedidos pe
  JOIN clientes c ON c.cliente_id = pe.cliente_id
 ORDER BY pe.pedido_id;

-- ------------------------------------------------------------
-- Consulta 2 (agregación)
-- Pregunta de negocio: ¿cuál es el monto total vendido por
-- producto, considerando solo pedidos no cancelados?
-- Resultado esperado: 3 productos con ventas (teclado, mouse,
-- monitor); "Audífonos USB" no aparece porque su único pedido
-- está cancelado.
-- ------------------------------------------------------------
SELECT p.nombre                                AS producto,
       SUM(d.cantidad)                          AS unidades_vendidas,
       SUM(d.cantidad * d.precio_unitario)      AS total_vendido
  FROM detalle_pedido d
  JOIN productos p ON p.producto_id = d.producto_id
  JOIN pedidos pe   ON pe.pedido_id = d.pedido_id
 WHERE pe.estado <> 'cancelado'
 GROUP BY p.nombre
HAVING SUM(d.cantidad * d.precio_unitario) > 0
 ORDER BY total_vendido DESC;

-- ------------------------------------------------------------
-- Consulta 3
-- Pregunta de negocio: ¿cuánto suma cada pedido y cómo se
-- clasifica según el monto, usando las funciones de 04_rutinas.sql?
-- Resultado esperado: 4 filas (una por pedido) con su total y
-- categoría ('bajo' | 'medio' | 'alto').
-- ------------------------------------------------------------
SELECT pedido_id,
       fn_total_pedido(pedido_id)     AS total,
       fn_categoria_pedido(pedido_id) AS categoria
  FROM pedidos
 ORDER BY pedido_id;

-- ------------------------------------------------------------
-- Consulta 4 (usa la rutina de técnica procedimental adicional)
-- Pregunta de negocio: ¿cuál es el resumen general de ventas
-- por producto (todas las unidades y el total facturado)?
-- ------------------------------------------------------------
SELECT * FROM fn_resumen_ventas();
