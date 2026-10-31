# Evidencias de ejecución — Grupo 7 · Eventos Nexo

Ejecución en PostgreSQL 16.15 sobre una base vacía, en el orden
01 → 02 → 04 → 03 → 05, con `psql -v ON_ERROR_STOP=1`. Los cinco scripts
terminaron sin errores.

## Consultas (03_consultas.sql)

**Q1 · Estado de cuenta por evento** (también muestra las funciones
`fn_saldo_evento` y `fn_estado_pago_evento`)

| Evento | Cliente | Estado | Aprobado | Pagado | Saldo | Estado de pago |
|---|---|---|---|---|---|---|
| 1 | Ana Rojas Mora | Cerrado | 2 610 000 | 2 610 000 | 0 | Pagado |
| 2 | Café del Valle S.A. | Confirmado | 1 110 000 | 500 000 | 610 000 | Parcial |
| 3 | Luis Vargas Solís | Confirmado | 660 000 | 0 | 660 000 | Adelanto pendiente |
| 4 | Carlos Méndez Arias | Cancelado | 200 000 | 0 | 200 000 | Pendiente |

**Q2 · Clientes con saldo pendiente**

| Cliente | Cargos con saldo | Saldo |
|---|---|---|
| Luis Vargas Solís | 1 | 660 000 |
| Café del Valle S.A. | 2 | 610 000 |
| Carlos Méndez Arias | 1 | 200 000 |

**Q3 · Recaudación por medio de pago**

| Medio | Pagos | Adelantos | Total |
|---|---|---|---|
| Transferencia | 2 | 1 | 1 800 000 |
| Efectivo | 1 | 0 | 610 000 |
| SINPE Móvil | 1 | 1 | 500 000 |
| Tarjeta | 1 | 0 | 200 000 |

**Q4 · Reparto simulado de un pago de 400 000 al evento 2**

| Cargo | Pendiente | Se aplicaría |
|---|---|---|
| 6 | 260 000 | 260 000 |
| 7 | 350 000 | 140 000 |

Los cuatro resultados coinciden con los esperados en el script.

## Rutinas (04_rutinas.sql)

| ID | Llamada | Resultado |
|---|---|---|
| R01 | `fn_saldo_evento` / `fn_estado_pago_evento` para los 4 eventos | Ver Q1: cada evento cae en una rama distinta de la decisión |
| R02 | `SELECT fn_saldo_evento(999);` | `ERROR: El evento 999 no existe.` |
| R03 | `sp_registrar_pago`: caso exitoso y caso rechazado | Ver T03, T04 (éxito) y T10 (rechazo) |
| R04 | `sp_aplicar_pago` (cursor) | Ver T02; su reparto en T03 coincide con Q4 (versión por conjuntos) |

## Pruebas (05_pruebas.sql)

La precondición y la sentencia de cada prueba están documentadas en el
script.

| ID | Tipo | Esperado | Observado | Conclusión |
|---|---|---|---|---|
| T01 | Válida | Cliente organización insertado | Insertado, id_persona = NULL | PASA |
| T02 | Válida | Adelanto en efectivo aplicado; saldo 610 000 | Aplicado 50 000; saldo 610 000 | PASA |
| T03 | Válida | Cargo 6 recibe 260 000, cargo 7 recibe 140 000; saldo 210 000 | 260 000 / 140 000; saldo 210 000 | PASA |
| T04 | Válida | Penalización pagada; estado Pagado | Saldo 0; Pagado | PASA |
| T05 | Inválida | 23505 `uq_pago_medio_referencia` | 23505 `uq_pago_medio_referencia` | PASA |
| T06 | Inválida | 23503 `fk_cargo_evento` | 23503 `fk_cargo_evento` | PASA |
| T07 | Inválida | 23503 `fk_aplicacion_pago_cargo` | 23503 `fk_aplicacion_pago_cargo` | PASA |
| T08 | Inválida | 23514 `ck_cliente_arco_exclusivo` | 23514 `ck_cliente_arco_exclusivo` | PASA |
| T09 | Inválida | 23502 en `medio_pago` | 23502 en `medio_pago` | PASA |
| T10 | Inválida | P0001; no se inserta el pago | «el monto 1000000.00 excede el saldo pendiente 610000.00»; pagos antes = 1, después = 1 | PASA |
| T11 | Inválida | 23514 `ck_cargo_origen` | 23514 `ck_cargo_origen` | PASA |

**Resumen:** 4 de 4 válidas y 7 de 7 inválidas se comportan como se
esperaba. El script termina en `ROLLBACK` y no deja cambios.
