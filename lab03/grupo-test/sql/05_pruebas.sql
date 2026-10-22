-- ============================================================
-- Laboratorio 3 · grupo-test
-- 05_pruebas.sql — Pruebas de integridad y de rutinas
-- Cada prueba usa un SAVEPOINT para poder revertirla sin afectar
-- al resto del conjunto, incluidas las que deben fallar.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- Prueba 01 (debe funcionar)
-- Precondición: cliente 1 existe, correo distinto a los ya usados.
-- Sentencia: INSERT de un nuevo cliente con correo único.
-- Resultado esperado: inserción exitosa.
-- Resultado observado / conclusión: se registra tras ejecutar.
-- ------------------------------------------------------------
SAVEPOINT p01;
INSERT INTO clientes (nombre, correo) VALUES ('David Solís', 'david.solis@example.com');
-- Observado: 1 fila insertada -> OK, cumple UNIQUE y NOT NULL.
RELEASE SAVEPOINT p01;

-- ------------------------------------------------------------
-- Prueba 02 (debe fallar — UNIQUE)
-- Precondición: 'ana.rojas@example.com' ya existe en clientes.
-- Sentencia: INSERT con un correo duplicado.
-- Resultado esperado: error de violación de restricción UNIQUE.
-- ------------------------------------------------------------
SAVEPOINT p02;
INSERT INTO clientes (nombre, correo) VALUES ('Otra Persona', 'ana.rojas@example.com');
-- Observado: ERROR  duplicate key value violates unique constraint
-- Conclusión: la restricción UNIQUE sobre correo funciona como se esperaba.
ROLLBACK TO SAVEPOINT p02;

-- ------------------------------------------------------------
-- Prueba 03 (debe fallar — FOREIGN KEY)
-- Precondición: no existe cliente_id = 999.
-- Sentencia: INSERT de un pedido referenciando un cliente inexistente.
-- Resultado esperado: error de violación de llave foránea.
-- ------------------------------------------------------------
SAVEPOINT p03;
INSERT INTO pedidos (cliente_id, estado) VALUES (999, 'pendiente');
-- Observado: ERROR  insert or update on table "pedidos" violates
-- foreign key constraint.
-- Conclusión: no se pueden crear pedidos para clientes inexistentes.
ROLLBACK TO SAVEPOINT p03;

-- ------------------------------------------------------------
-- Prueba 04 (debe fallar — CHECK)
-- Precondición: la tabla productos exige precio > 0.
-- Sentencia: INSERT de un producto con precio negativo.
-- Resultado esperado: error de violación de restricción CHECK.
-- ------------------------------------------------------------
SAVEPOINT p04;
INSERT INTO productos (nombre, precio, existencias) VALUES ('Producto inválido', -5.00, 10);
-- Observado: ERROR  new row for relation "productos" violates
-- check constraint.
-- Conclusión: no se aceptan precios no positivos.
ROLLBACK TO SAVEPOINT p04;

-- ------------------------------------------------------------
-- Prueba 05 (debe funcionar — procedimiento, caso exitoso)
-- Precondición: pedido 2 está 'pendiente' y hay 8 monitores en
-- existencia (se solicita 1).
-- Sentencia: CALL sp_confirmar_pedido(2).
-- Resultado esperado: el pedido pasa a 'confirmado' y se descuenta
-- 1 unidad de existencias del producto 3.
-- ------------------------------------------------------------
SAVEPOINT p05;
CALL sp_confirmar_pedido(2);
-- Observado: estado de pedidos.pedido_id = 2 -> 'confirmado';
-- productos.existencias de producto_id = 3 -> 7.
-- Conclusión: el procedimiento valida y actualiza correctamente.
RELEASE SAVEPOINT p05;

-- ------------------------------------------------------------
-- Prueba 06 (debe fallar — regla de negocio en el procedimiento)
-- Precondición: pedido 1 ya está en estado 'despachado'.
-- Sentencia: CALL sp_confirmar_pedido(1).
-- Resultado esperado: RAISE EXCEPTION porque el pedido no está
-- 'pendiente'.
-- ------------------------------------------------------------
SAVEPOINT p06;
CALL sp_confirmar_pedido(1);
-- Observado: ERROR  El pedido 1 no está pendiente (estado actual: despachado)
-- Conclusión: el procedimiento rechaza operaciones sobre pedidos
-- que ya avanzaron de estado, sin depender únicamente de CHECK.
ROLLBACK TO SAVEPOINT p06;

COMMIT;
