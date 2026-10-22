# Evidencias de ejecución — grupo-test

## Consultas (`03_consultas.sql`)

**Consulta 1** — pedidos por cliente y estado:

| cliente     | pedido_id | estado      |
|---|---:|---|
| Ana Rojas   | 1 | despachado  |
| Ana Rojas   | 2 | confirmado  |
| Luis Mora   | 3 | confirmado  |
| Carla Vega  | 4 | cancelado   |

**Consulta 2** — total vendido por producto (excluye pedidos cancelados):

| producto          | unidades_vendidas | total_vendido |
|---|---:|---:|
| Monitor 24"       | 1 | 150.00 |
| Mouse óptico      | 5 | 62.50  |
| Teclado mecánico  | 1 | 35.00  |

## Pruebas de integridad (`05_pruebas.sql`)

| ID | Esperado | Observado | Conclusión |
|---|---|---|---|
| p01 | éxito | 1 fila insertada | cliente nuevo con correo único se inserta correctamente |
| p02 | error UNIQUE | `duplicate key value violates unique constraint` | correos duplicados se rechazan |
| p03 | error FOREIGN KEY | `violates foreign key constraint` | no se aceptan pedidos de clientes inexistentes |
| p04 | error CHECK | `violates check constraint` | no se aceptan precios no positivos |
| p05 | éxito | pedido 2 → `confirmado`, existencias de monitor 8 → 7 | `sp_confirmar_pedido` valida y actualiza correctamente |
| p06 | error de negocio | `El pedido 1 no está pendiente (estado actual: despachado)` | el procedimiento rechaza confirmar pedidos ya avanzados |

## Rutinas (`04_rutinas.sql`)

- `SELECT fn_total_pedido(1);` → `60.00`
- `SELECT fn_categoria_pedido(3);` → `'medio'`
- `CALL sp_confirmar_pedido(2);` → ejecución exitosa
- `CALL sp_confirmar_pedido(1);` → rechazado con mensaje explícito
