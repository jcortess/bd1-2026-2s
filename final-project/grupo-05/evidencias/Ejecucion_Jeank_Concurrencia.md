
# Evidencia de concurrencia — Jean Carlos

## Identificación

- Prueba: PJ-10.
- Proceso: G05-P03.
- Base: huellas_g05_final_pruebas.
- Aislamiento: READ COMMITTED.
- Cliente: psql 16.16.

## Objetivo

Demostrar que dos sesiones independientes no pueden
confirmar simultáneamente reservas vigentes para
el mismo animal.

## Estado inicial

- Animal: HS-01.
- Ingreso: 1.
- Solicitud familia A: 1.
- Solicitud familia B: 2.
- Ambas solicitudes aprobadas.
- Ambas compatibilidades favorables.
- Reservas vigentes iniciales: 0.

## Guiones utilizados

- `pruebas/05_preparacion_jeank.sql`.
- `pruebas/concurrencia_jeank/01_reserva_a.sql`.
- `pruebas/concurrencia_jeank/02_reserva_b.sql`.
- `pruebas/concurrencia_jeank/03_espera.sql`.
- `pruebas/concurrencia_jeank/04_verificar.sql`.

## Intercalación observada

| Paso | Sesión | Acción | Resultado |
|---|---|---|---|
| 1 | A | BEGIN READ COMMITTED | Transacción iniciada |
| 2 | A | Registrar reserva | Reserva creada sin confirmar |
| 3 | B | BEGIN READ COMMITTED | Transacción iniciada |
| 4 | B | Registrar reserva del mismo animal | Espera por bloqueo |
| 5 | Observador | Consultar bloqueos | A bloquea a B |
| 6 | A | COMMIT | Reserva confirmada |
| 7 | B | Continuar operación | Rechazo P3021 |
| 8 | B | ROLLBACK | Intento revertido |
| 9 | Observador | Verificación final | Una sola reserva vigente |

## Bloqueo observado

| Sesión | PID |
|---|---|
| A | 17212 |
| B | 17012 |

La consulta de actividad mostró a la sesión B
esperando un bloqueo de tipo advisory.

La consulta `pg_blocking_pids` identificó a la
sesión A como bloqueadora de B.

Resultado observado:

```text
a_bloquea_b = t
```

## Resultado de sesión A

```text
COMMIT
SESION A: COMMIT EXITOSO
```

## Resultado de sesión B

```text
NOTICE: RECHAZO ESPERADO: El animal ya tiene una reserva vigente - SQLSTATE: P3021
DO
ROLLBACK
SESION B: PRUEBA FINALIZADA
```

## Verificación final

| Reserva | Solicitud | Animal | Ingreso | Fecha fin |
|---|---|---|---|---|
| 1 | 1 | HS-01 | 1 | NULL |

Las dos compatibilidades favorables se conservaron.

```text
NOTICE: PJ-10: VERIFICACION FINAL SUPERADA
DO
```

## Incidencia durante la observación

La primera ejecución del guion de verificación
se realizó antes del COMMIT de la sesión A.

La consulta no observó todavía la reserva confirmada
y produjo el mensaje:

```text
FALLO: debe existir una sola reserva vigente
```

Se repitió la verificación después de finalizar
ambas transacciones y el resultado fue satisfactorio.

La incidencia correspondió al momento de ejecución
del observador y no a una violación de exclusividad.

## Mecanismos de integridad

- Bloqueos transaccionales compartidos con el modelo.
- Validación de reserva vigente.
- Índice único parcial por animal con reserva abierta.
- Operaciones públicas controladas.
- Restricciones de escritura directa.

## Comportamiento ante reintentos

Mientras la reserva ganadora permanezca vigente,
una nueva reserva incompatible debe rechazarse.

No se presenta esta expectativa como una tercera
ejecución concurrente observada.

## Conclusión

La prueba se realizó mediante dos sesiones reales
e independientes de PostgreSQL.

Solo una reserva quedó confirmada. La segunda
operación fue rechazada por la regla de negocio
esperada y no dejó una reserva adicional.

Estado: SUPERADA.
