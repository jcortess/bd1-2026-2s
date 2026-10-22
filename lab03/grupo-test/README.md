# Laboratorio 3 — grupo-test

> ⚠️ Esta carpeta es de **prueba**, usada únicamente para validar el funcionamiento
> del flujo de GitHub Actions (`validar-lab3.yml`) del curso. No corresponde a un
> equipo real ni a una entrega evaluable.

¡Hola! Bienvenidos al repositorio del **grupo-test** para el Laboratorio 3 del curso IC-4301 · Bases de Datos I.

## Descripción del proceso implementado

Subsistema de **registro y despacho de pedidos** de una tienda pequeña: un cliente
realiza un pedido compuesto por uno o más productos (relación muchos-a-muchos
materializada en `detalle_pedido`), y el pedido avanza por los estados
`pendiente → confirmado → despachado` (o `cancelado`).

## Fragmento del modelo lógico y matriz de trazabilidad

| Relación lógica | Tabla física      | PK                        | FK                                              | Restricciones relevantes                          |
|---|---|---|---|---|
| Cliente          | `clientes`         | `cliente_id`              | —                                                | `correo` UNIQUE, NOT NULL                         |
| Producto         | `productos`         | `producto_id`              | —                                                | `precio > 0`, `existencias >= 0`                  |
| Pedido           | `pedidos`           | `pedido_id`                | `cliente_id → clientes`                         | `estado` restringido a valores permitidos (CHECK) |
| Pedido-Producto  | `detalle_pedido`    | (`pedido_id`,`producto_id`) | `pedido_id → pedidos`, `producto_id → productos` | `cantidad > 0`, `precio_unitario > 0`             |

## Instrucciones de ejecución

Requiere PostgreSQL 16.x (o compatible) y una base de datos vacía.

```bash
psql -d laboratorio3_test -f sql/01_esquema.sql
psql -d laboratorio3_test -f sql/02_datos.sql
psql -d laboratorio3_test -f sql/04_rutinas.sql
psql -d laboratorio3_test -f sql/03_consultas.sql
psql -d laboratorio3_test -f sql/05_pruebas.sql
```

## Decisiones de diseño físico

- `cliente_id`, `producto_id` y `pedido_id` son `SERIAL` para simplificar la carga de datos de prueba.
- `detalle_pedido` usa clave primaria compuesta (`pedido_id`, `producto_id`) en vez de un id propio, porque no existe un caso de negocio que necesite referenciar una línea de pedido de forma independiente.
- Se agregó `idx_pedidos_cliente_estado` porque las consultas de negocio filtran pedidos por cliente y estado con frecuencia.

## Justificación de las rutinas

- `fn_total_pedido` / `fn_categoria_pedido`: cálculo reutilizable del monto de un pedido y su clasificación, usado tanto en consultas como en el procedimiento.
- `sp_confirmar_pedido`: valida estado y existencias antes de modificar datos; las restricciones declarativas (`CHECK`, `FOREIGN KEY`) se mantienen en el esquema y no son reemplazadas por el procedimiento.
- `fn_resumen_ventas`: usa una tabla temporal como técnica procedimental adicional (C3); se documenta en `04_rutinas.sql` la alternativa equivalente basada en conjuntos.

## Limitaciones

- No se modela pago, envío ni devoluciones: el alcance se limita al ciclo pedido → confirmación → despacho.
- Los triggers no se implementan (no son obligatorios en este laboratorio).

## Evidencias

Ver `evidencias/resultados.md`.

## Video de la defensa individual

> Como esta carpeta es solo de prueba, no hay integrantes reales ni videos grabados.
> En una entrega real, cada integrante debe colocar aquí el enlace a su video
> (el repositorio no admite archivos de video), por ejemplo:
>
> - Integrante 1 — Nombre Apellido: `https://drive.google.com/...`
> - Integrante 2 — Nombre Apellido: `https://drive.google.com/...`
