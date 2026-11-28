# Evidencia de ejecución: cobertura adicional Jeank

## 1. Entorno de ejecución

- Fecha: 28 de noviembre de 2026.
- Motor: PostgreSQL 16.
- Cliente: psql desde PowerShell.
- Base de datos independiente: `huellas_g05_cobertura`.
- Script: `pruebas/13_cobertura_adicional_jeank.sql`.
- Datos utilizados: ficticios.

## 2. Preparación reproducible

Los archivos fueron ejecutados en el siguiente orden:

1. `sql/15_instalar_proyecto_completo.sql`
2. `pruebas/05_preparacion_jeank.sql`
3. `pruebas/09_bloque_jeank.sql`
4. `pruebas/06_preparacion_concurrencia_jeank.sql`
5. `pruebas/07_devolucion_jeank.sql`
6. `pruebas/13_cobertura_adicional_jeank.sql`

La instalación completa confirmó 28 tablas físicas. Todos los scripts de preparación finalizaron correctamente.

## 3. Resultados observados

| Caso | Resultado esperado | Resultado observado | Estado |
|---|---|---|---|
| PJ-13 | Aprobar sin crear reserva automáticamente. | Solicitud 3 aprobada sin reservas asociadas. | Superada |
| PJ-14 | Finalizar una reserva independientemente de la adopción. | Reserva 4 finalizada; ingreso y estancia permanecieron abiertos. | Superada |
| PJ-15 | Permitir reservar al finalizar una restricción. | Reserva 4 registrada exactamente al finalizar la restricción de la persona 103. | Superada |
| PJ-16 | Rechazar un reingreso de otro animal. | SQLSTATE P3052. Sin efectos parciales. | Superada |
| PJ-17 | Registrar traslado válido y cerrar la etapa. | Resultado 3 registrado y cierre confirmado mediante COMMIT. | Superada |
| PJ-18 | Rechazar traslado sin organización de destino. | Restricción resultado_traslado_chk, SQLSTATE 23514. | Superada |
| PC-08 | Rechazar asociación clínica duplicada. | Restricción indicacion_diagnostico_pkey, SQLSTATE 23505. | Superada |
| PC-09 | Impedir modificaciones del historial clínico. | SQLSTATE P2001. Descripción original conservada. | Superada |

## 4. Extractos de la ejecución

```text
NOTICE: PJ-13: SUPERADA
NOTICE: PJ-15: SUPERADA - RESTRICCION FINALIZADA
NOTICE: PJ-14: SUPERADA - RESERVA FINALIZADA SIN ADOPCION
NOTICE: PJ-16: RECHAZO ESPERADO - El reingreso corresponde a otro animal - P3052
NOTICE: PJ-16: SUPERADA
NOTICE: PJ-18: RECHAZO ESPERADO - resultado_traslado_chk - 23514
NOTICE: PJ-18: SUPERADA
NOTICE: PJ-17: SUPERADA
NOTICE: PC-08: RECHAZO ESPERADO - indicacion_diagnostico_pkey - 23505
NOTICE: PC-08: SUPERADA
NOTICE: PC-09: SUPERADA
```

Extractos de la salida real, omitiendo prefijos de archivo y números de línea.

## 5. Estado persistido

### Reservas

| Reserva | Solicitud | Animal | Inicio | Finalización |
|---|---|---|---|---|
| 1 | 1 | HS-01 | 07/10/2026 13:00 | 07/10/2026 14:00 |
| 3 | 1 | HS-02 | 07/10/2026 15:00 | 07/10/2026 16:00 |
| 4 | 3 | HS-03 | 09/10/2026 08:00 | 09/10/2026 09:00 |

### Restricción

La restricción 1, correspondiente a la persona 103, inició el 7 de octubre de 2026 a las 10:00 y finalizó el 9 de octubre de 2026 a las 08:00.

La reserva 4 fue aceptada exactamente en el límite de finalización de la restricción.

### Resultado de etapa

- Resultado: 3.
- Tipo: TRASLADO.
- Organización de destino: 1.
- Fecha del resultado: 13/10/2026 10:00.
- Fecha de cierre del ingreso: 13/10/2026 10:00.

### Integridad clínica

Se conservaron las tres asociaciones originales:

| Indicación | Evaluación | Diagnóstico |
|---|---|---|
| 2001 | 1001 | 1 |
| 2002 | 1001 | 2 |
| 2003 | 1002 | 1 |

La indicación 2001 conservó su descripción original: Tratamiento dermatologico ficticio.

### Control de adopciones

| Adopción | Animal | Ingreso | Estado |
|---|---|---|---|
| 1 | HS-01 | 1 | CONSISTENTE |
| 2 | HS-02 | 2 | CONSISTENTE |

Las fechas de entrega, cierre del ingreso y finalización de reserva coinciden en ambas adopciones.

## 6. Conclusión

Los ocho casos adicionales fueron superados. Se verificaron restricciones de identidad, referencias contextuales, conservación histórica, límites temporales, independencia de operaciones y cierre de etapas mediante resultados no adoptivos.

Las operaciones públicas de reserva se ejecutaron mediante el rol operador. Las comprobaciones directas de integridad histórica y traslado se realizaron con privilegios administrativos.

El bloque Jeank acumula 33 casos de prueba distintos ejecutados satisfactoriamente, considerando las ejecuciones anteriores y la presente ampliación.

La cobertura obtenida no implica que todas las combinaciones posibles de restricciones hayan sido probadas exhaustivamente.
