-- ============================================================
-- Laboratorio 3 · grupo-test
-- 04_rutinas.sql — Programación almacenada
-- ============================================================

-- ------------------------------------------------------------
-- C1a. Función: total de un pedido.
-- Parámetros: p_pedido_id (id del pedido).
-- Retorna: NUMERIC con la suma de cantidad * precio_unitario
--          de todas las líneas del pedido.
-- Ejemplo: SELECT fn_total_pedido(1);  -- 60.00
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_pedido(p_pedido_id INTEGER)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
BEGIN
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
      INTO v_total
      FROM detalle_pedido
     WHERE pedido_id = p_pedido_id;

    RETURN v_total;
END;
$$;

-- ------------------------------------------------------------
-- C1b. Función con decisión de negocio: clasifica un pedido
-- según su monto total.
-- Parámetros: p_pedido_id (id del pedido).
-- Retorna: TEXT con la categoría ('bajo', 'medio', 'alto').
-- Regla de negocio: bajo < 20, medio 20-100, alto > 100.
-- Ejemplo: SELECT fn_categoria_pedido(3);  -- 'medio'
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_categoria_pedido(p_pedido_id INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
BEGIN
    v_total := fn_total_pedido(p_pedido_id);

    IF v_total < 20 THEN
        RETURN 'bajo';
    ELSIF v_total <= 100 THEN
        RETURN 'medio';
    ELSE
        RETURN 'alto';
    END IF;
END;
$$;

-- ------------------------------------------------------------
-- C2. Procedimiento: confirmar un pedido.
-- Valida que el pedido esté en estado 'pendiente' y que exista
-- suficiente existencia de cada producto solicitado antes de
-- descontar inventario y cambiar el estado a 'confirmado'.
-- Rechaza la operación con RAISE EXCEPTION si no se cumple.
--
-- Prueba exitosa:  CALL sp_confirmar_pedido(2);
-- Prueba rechazada: CALL sp_confirmar_pedido(1); -- ya está despachado
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_confirmar_pedido(p_pedido_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual VARCHAR(20);
    r RECORD;
BEGIN
    SELECT estado INTO v_estado_actual
      FROM pedidos
     WHERE pedido_id = p_pedido_id
     FOR UPDATE;

    IF v_estado_actual IS NULL THEN
        RAISE EXCEPTION 'El pedido % no existe', p_pedido_id;
    END IF;

    IF v_estado_actual <> 'pendiente' THEN
        RAISE EXCEPTION 'El pedido % no está pendiente (estado actual: %)',
            p_pedido_id, v_estado_actual;
    END IF;

    FOR r IN
        SELECT d.producto_id, d.cantidad, p.existencias, p.nombre
          FROM detalle_pedido d
          JOIN productos p ON p.producto_id = d.producto_id
         WHERE d.pedido_id = p_pedido_id
    LOOP
        IF r.existencias < r.cantidad THEN
            RAISE EXCEPTION 'Existencias insuficientes de "%" (disponible: %, solicitado: %)',
                r.nombre, r.existencias, r.cantidad;
        END IF;
    END LOOP;

    UPDATE productos p
       SET existencias = p.existencias - d.cantidad
      FROM detalle_pedido d
     WHERE p.producto_id = d.producto_id
       AND d.pedido_id = p_pedido_id;

    UPDATE pedidos
       SET estado = 'confirmado'
     WHERE pedido_id = p_pedido_id;
END;
$$;

-- ------------------------------------------------------------
-- C3. Técnica procedimental adicional: tabla temporal.
-- Genera un resumen de ventas por producto usando una tabla
-- temporal, útil cuando el resultado intermedio se consulta
-- más de una vez dentro de la misma rutina.
--
-- Justificación: se eligió tabla temporal (en vez de cursor) porque
-- el cálculo se resuelve naturalmente con SQL basado en conjuntos
-- (GROUP BY); el cursor sería una técnica innecesaria aquí. La tabla
-- temporal sí aporta valor porque el resumen se reutiliza dos veces
-- (para el total general y para el detalle por producto) sin
-- recalcular el JOIN + GROUP BY cada vez.
--
-- Alternativa más simple basada en conjuntos (sin tabla temporal),
-- discutida y documentada como referencia:
--   SELECT p.nombre, SUM(d.cantidad) AS unidades,
--          SUM(d.cantidad * d.precio_unitario) AS total
--     FROM detalle_pedido d JOIN productos p ON p.producto_id = d.producto_id
--    GROUP BY p.nombre ORDER BY total DESC;
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_resumen_ventas()
RETURNS TABLE(nombre VARCHAR(80), unidades BIGINT, total NUMERIC(12,2))
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS tmp_resumen_ventas;

    CREATE TEMP TABLE tmp_resumen_ventas ON COMMIT DROP AS
    SELECT p.nombre        AS nombre,
           SUM(d.cantidad) AS unidades,
           SUM(d.cantidad * d.precio_unitario) AS total
      FROM detalle_pedido d
      JOIN productos p ON p.producto_id = d.producto_id
     GROUP BY p.nombre;

    RETURN QUERY
        SELECT tmp_resumen_ventas.nombre,
               tmp_resumen_ventas.unidades,
               tmp_resumen_ventas.total
          FROM tmp_resumen_ventas
         ORDER BY tmp_resumen_ventas.total DESC;
END;
$$;

-- Ejemplo de ejecución: SELECT * FROM fn_resumen_ventas();
