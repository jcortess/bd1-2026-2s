
# Evidencia de ejecución secuencial — Jean Carlos

## Entorno

- Base de datos: huellas_g05_secuencial.
- Cliente: psql 16.16.
- Sistema operativo: Windows.
- Esquema: huellas.
- Zona horaria: America/Costa_Rica.
- Rol operativo: huellas_g05_operador.

Este documento conserva extractos de los resultados
realmente observados durante las ejecuciones.

## 1. Preparación

Archivo: `pruebas/05_preparacion_jeank.sql`.

Se prepararon las solicitudes de las familias 101 y 102,
las compatibilidades individuales y las estancias
necesarias para las pruebas.

## 2. Primer bloque secuencial

Archivo: `pruebas/09_bloque_jeank.sql`.

### Salida observada

```text
PJ-01: SUPERADA
PJ-02: SUPERADA - El animal ya tiene una reserva vigente
PJ-04: SUPERADA
PJ-05: SUPERADA - La reserva ya fue finalizada
PJ-06: SUPERADA - La adjudicación requiere la etapa abierta del animal indicado
PJ-07: SUPERADA
PJ-08: SUPERADA - El ingreso ya fue cerrado mediante una adopcion
PC-01: SUPERADA
PC-02: SUPERADA - La aplicacion ya fue realizada
PC-03: SUPERADA - La fecha planificada es anterior a la evaluacion
PC-04: SUPERADA - Debe indicar fecha, responsable y observaciones
PC-05: SUPERADA
==== FIN DEL PRIMER BLOQUE SECUENCIAL ====
```

### Estado consultado

| Adopción | Animal | Ingreso | Fecha de entrega | Integridad |
|---|---|---|---|---|
| 1 | HS-01 | 1 | 2026-10-07 14:00:00-06 | CONSISTENTE |
| 2 | HS-02 | 2 | 2026-10-07 16:00:00-06 | CONSISTENTE |

Las fechas de cierre del ingreso y de la reserva
coincidieron con las fechas de entrega.

| Aplicación | Estado |
|---|---|
| 3001 | REALIZADA |
| 3002 | REALIZADA |
| 3003 | PROGRAMADA |

## 3. Restricción vigente

Archivos:

- `pruebas/06_preparacion_concurrencia_jeank.sql`.
- `pruebas/10_pruebas_complementarias_jeank.sql`.

### Estado inicial

- Solicitud: 3.
- Solicitante: 103.
- Animal: HS-03.
- Ingreso: 3.
- Compatibilidad: 4, FAVORABLE.
- Estancia: 3.
- Restricción vigente: 1.

### Salida observada

```text
PJ-03: SUPERADA - La persona tiene una restriccion vigente documentada - SQLSTATE: P3015
ROLLBACK
PJ-03: SIN EFECTOS PARCIALES
```

La restricción existente se conservó y no se generó
una reserva para la solicitud 3.

## 4. Devolución voluntaria

Archivo: `pruebas/07_devolucion_jeank.sql`.

### Salida observada

```text
BEGIN
UPDATE 1
INSERT 0 1
INSERT 0 1
COMMIT
PJ-09: SUPERADA
```

| Adopción | Animal | Finalización | Fecha |
|---|---|---|---|
| 1 | HS-01 | DEVOLUCION_VOLUNTARIA | 2026-10-10 09:00:00-06 |

| Ingreso | Animal | Circunstancia | Adopción origen | Cierre |
|---|---|---|---|---|
| 1 | HS-01 | RESCATE | NULL | 2026-10-07 14:00:00-06 |
| 18 | HS-01 | DEVOLUCION | 1 | NULL |

La consulta de restricciones de la persona 101
devolvió cero filas.

La aserción final comprobó la existencia de la
evaluación inicial del nuevo ingreso.

## 5. Integridad clínica, seguimiento y permisos

Archivo: `pruebas/11_integridad_final_jeank.sql`.

### Salida observada

```text
PC-06: SUPERADA - SQLSTATE: 23503 - Restriccion: indicacion_diagnostico_contexto_fk
PC-07: SUPERADA
PS-01: SUPERADA
PS-02: SUPERADA - El seguimiento no puede ser anterior a la adopcion
PS-03: SUPERADA - El seguimiento ya tiene un resultado definitivo
PS-04: SUPERADA
PS-05: SUPERADA - La reprogramacion pertenece a otra adopcion
PP-01: SUPERADA - permiso denegado a la tabla indicacion
==== FIN DE INTEGRIDAD FINAL JEANK ====
```

### Asociaciones clínicas conservadas

| Indicación | Evaluación | Diagnóstico |
|---|---|---|
| 2001 | 1001 | 1 |
| 2002 | 1001 | 2 |
| 2003 | 1002 | 1 |

La asociación válida adicional de PC-07 se comprobó
antes de ROLLBACK y no quedó persistida.

### Seguimientos persistidos

| ID | Adopción | Fecha prevista | Estado | Origen |
|---|---|---|---|---|
| 1 | 2 | 2026-10-12 09:00:00-06 | REALIZADO | NULL |
| 3 | 2 | 2026-10-15 09:00:00-06 | REPROGRAMADO | NULL |
| 4 | 2 | 2026-10-20 09:00:00-06 | PENDIENTE | 3 |

El seguimiento 1 registró fecha efectiva,
resultado y acuerdo.

## 6. Preparación de atomicidad

Archivo: `pruebas/08_preparacion_dos_sesiones_jeank.sql`.

| Solicitud | Solicitante | Estado | Compatibilidad |
|---|---|---|---|
| 4 | 101 | APROBADA | 5, FAVORABLE |
| 5 | 102 | APROBADA | 6, FAVORABLE |

Ambas compatibilidades corresponden al animal HS-03,
ingreso 3.

La consulta de reservas de HS-03 devolvió cero filas.

## 7. Atomicidad

Archivo: `pruebas/12_atomicidad_jeank.sql`.

### Estado inicial

- Reserva: 5.
- Solicitud: 4.
- Animal: HS-03.
- Ingreso: 3.
- Estancia vigente: 3.
- Compatibilidad: 5.
- Responsable adoptivo: 101.

### Rechazo observado

```text
RESERVA CREADA: 5
PJ-09 COMPLEMENTARIA: NUEVA RESERVA PERMITIDA
PJ-11: RECHAZO ESPERADO - La estancia vigente difiere de la esperada - SQLSTATE: P1006
ROLLBACK
PJ-11: SUPERADA - SIN EFECTOS PARCIALES
```

### Comparación antes y después del rechazo

| Elemento | Antes | Después |
|---|---|---|
| Reserva 5 | Vigente | Vigente |
| Ingreso 3 | Abierto | Abierto |
| Estancia 3 | Abierta | Abierta |
| Adopciones del ingreso 3 | 0 | 0 |

No se encontraron responsables huérfanos.

### Reintento correcto

```text
BEGIN
SET
COMMIT
PJ-11: REINTENTO CORRECTO SUPERADO
==== FIN DE PRUEBA DE ATOMICIDAD ====
```

| Adopción | Animal | Ingreso | Integridad |
|---|---|---|---|
| 1 | HS-01 | 1 | CONSISTENTE |
| 2 | HS-02 | 2 | CONSISTENTE |
| 4 | HS-03 | 3 | CONSISTENTE |

La estancia 3 quedó cerrada el
2026-10-11 14:00:00-06.

Las secuencias pueden consumir identificadores durante
intentos revertidos. Los saltos observados no representan
pérdida de integridad.

## 8. Conclusión

Los guiones alcanzaron sus mensajes finales y las
consultas de comprobación confirmaron los estados
esperados.

Las operaciones inválidas fueron rechazadas y las
operaciones válidas conservaron la coherencia entre
las relaciones involucradas.
