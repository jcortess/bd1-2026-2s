
# Casos reproducibles del bloque de Jean Carlos

## 1. Preparación general

Los casos utilizan datos ficticios y una instalación
completa del esquema huellas.

Las condiciones esperadas están expresadas mediante
aserciones SQL, códigos SQLSTATE o mensajes de rechazo.

Las evidencias observadas se encuentran en
`evidencias/Resultados_Jeank.md` y los documentos
de ejecución relacionados.

## 2. Orden de ejecución secuencial

Utilizar una base nueva para reproducir la secuencia.

| Orden | Archivo |
|---|---|
| 1 | sql/15_instalar_proyecto_completo.sql |
| 2 | pruebas/05_preparacion_jeank.sql |
| 3 | pruebas/09_bloque_jeank.sql |
| 4 | pruebas/06_preparacion_concurrencia_jeank.sql |
| 5 | pruebas/10_pruebas_complementarias_jeank.sql |
| 6 | pruebas/07_devolucion_jeank.sql |
| 7 | pruebas/11_integridad_final_jeank.sql |
| 8 | pruebas/08_preparacion_dos_sesiones_jeank.sql |
| 9 | pruebas/12_atomicidad_jeank.sql |

No ejecutar los archivos únicamente según su
numeración, debido a sus dependencias de preparación.

Los guiones no son idempotentes sobre una base que
ya contiene los resultados de una ejecución anterior.

## 3. Casos del proceso G05-P03

| Código | Relaciones principales | Acción | Esperado | Observado | Guion |
|---|---|---|---|---|---|
| PJ-01 | Reserva, solicitud, compatibilidad | Reservar HS-01 | Reserva vigente | Superada | 09 |
| PJ-02 | Reserva | Reservar HS-01 para otra familia | P3021 | Rechazo esperado | 09 |
| PJ-03 | Reserva, restricción | Reservar con persona restringida | Rechazo por restricción | P3015 | 10 |
| PJ-04 | Adopción, reserva, ingreso, estancia | Formalizar adopción | Cierre consistente | Superada | 09 |
| PJ-05 | Adopción, reserva | Repetir formalización | P3017 | Rechazo esperado | 09 |
| PJ-06 | Reserva, ingreso, compatibilidad | Utilizar ingreso incorrecto | P2025 | Rechazo esperado | 09 |
| PJ-07 | Adopción, solicitud | Adoptar segundo animal | Dos adopciones individuales | Superada | 09 |
| PJ-08 | Resultado, adopción | Insertar resultado incompatible | P3022 | Rechazo esperado | 09 |
| PJ-09 | Adopción, ingreso, evaluación, restricción | Registrar devolución | Nuevo ingreso sin restricción automática | Ingreso 18 y cero restricciones | 07 y 12 |
| PJ-10 | Reserva | Competencia entre sesiones | Una reserva vigente | Una reserva confirmada y P3021 | concurrencia_jeank |
| PJ-11 | Adopción, responsable, reserva, ingreso, estancia | Formalizar con estancia incorrecta | Rechazo sin cambios parciales | P1006 y reintento exitoso | 12 |
| PJ-12 | Modelo completo | Instalar y formalizar | 28 tablas y adopción consistente | Superada | sql/15 y validación |

## 4. Casos clínicos

| Código | Relación | Acción | Esperado | Observado | Guion |
|---|---|---|---|---|---|
| PC-01 | Aplicación | Consultar estado de 3001 | REALIZADA | REALIZADA | 09 |
| PC-02 | Aplicación | Registrar nuevamente 3001 | P3005 | Rechazo esperado | 09 |
| PC-03 | Aplicación | Planificar antes de evaluación | P3008 | Rechazo esperado | 09 |
| PC-04 | Aplicación | Registrar sin responsable | P3011 | Rechazo esperado | 09 |
| PC-05 | Aplicación | Registrar aplicación 3002 | REALIZADA | REALIZADA | 09 |
| PC-06 | Indicación diagnóstico | Asociar indicación 2001 con evaluación 1002 | FK contextual | 23503 | 11 |
| PC-07 | Indicación diagnóstico | Asociar indicación 2001 con evaluación 1001 y diagnóstico 2 | Inserción válida | Superada y revertida | 11 |

## 5. Seguimiento y permisos

| Código | Relación | Acción | Esperado | Observado | Guion |
|---|---|---|---|---|---|
| PS-01 | Seguimiento | Completar seguimiento | REALIZADO | Superada | 11 |
| PS-02 | Seguimiento | Fecha anterior a entrega | P3045 | Rechazo esperado | 11 |
| PS-03 | Seguimiento | Modificar resultado definitivo | P3042 | Rechazo esperado | 11 |
| PS-04 | Seguimiento | Reprogramar con fecha posterior | Vínculo válido | Superada | 11 |
| PS-05 | Seguimiento | Reprogramar desde otra adopción | P3048 | Rechazo esperado | 11 |
| PP-01 | Indicación | UPDATE directo como operador | Permiso denegado | Rechazo esperado | 11 |

## 6. Estados iniciales y finales

| Conjunto | Estado inicial | Estado final |
|---|---|---|
| PJ-01 a PJ-08, excepto PJ-03 | Solicitudes aprobadas y compatibilidades favorables | Dos adopciones consistentes |
| PC-01 a PC-05 | Aplicaciones clínicas de semilla | Aplicaciones 3001 y 3002 realizadas |
| PJ-03 | Persona 103 restringida | Sin reserva de solicitud 3 |
| PJ-09 | Adopción de HS-01 vigente | Adopción finalizada e ingreso 18 abierto |
| PC-06 y PC-07 | Tres asociaciones clínicas | Tres asociaciones conservadas |
| PS-01 a PS-05 | Sin seguimientos | Tres seguimientos persistidos |
| PP-01 | Rol operativo sin DML directo | Indicación conservada |
| PJ-11 | Reserva 5 e ingreso 3 abiertos | Rechazo sin parciales y adopción consistente |

## 7. Concurrencia

La prueba PJ-10 requiere una base independiente,
instalación completa y preparación mediante el
archivo 05.

Abrir las sesiones A y B en terminales diferentes.

Ejecutar los guiones 01 y 02 de concurrencia_jeank.

Mientras B espera, ejecutar el guion 03 desde
una tercera terminal observadora.

Confirmar A cuando el bloqueo haya sido comprobado.

Esperar el rechazo y ROLLBACK de B.

Ejecutar el guion 04 únicamente después de que
ambas sesiones hayan finalizado.

La intercalación observada se documenta en:

[Concurrencia](../evidencias/Ejecucion_Jeank_Concurrencia.md).

## 8. Evidencias

- [Resultados](../evidencias/Resultados_Jeank.md).
- [Secuencial](../evidencias/Ejecucion_Jeank_Secuencial.md).
- [Concurrencia](../evidencias/Ejecucion_Jeank_Concurrencia.md).
- [Instalación](../evidencias/Ejecucion_Jeank_Instalacion.md).

Los casos aquí enumerados corresponden a ejecuciones
realizadas. La cobertura de otras restricciones
debe identificarse individualmente en la matriz
de integridad.

## Casos adicionales de cobertura

Script: `13_cobertura_adicional_jeank.sql`.

| Caso | Relación u operación | Escenario | Resultado esperado | Estado |
|---|---|---|---|---|
| PJ-13 | SOLICITUD_ADOPCION | Solicitud aprobada sin reserva | Ausencia de reserva automática | Superada |
| PJ-14 | RESERVA | Finalización independiente | Reserva cerrada sin adopción; etapa abierta | Superada |
| PJ-15 | RESTRICCION_PERSONA | Reserva en el límite de finalización | Operación permitida | Superada |
| PJ-16 | INGRESO | Origen correspondiente a otro animal | Rechazo P3052 | Superada |
| PJ-17 | RESULTADO_ETAPA | Traslado con destino y condiciones | Cierre consistente de etapa | Superada |
| PJ-18 | RESULTADO_ETAPA | Traslado sin organización de destino | Rechazo 23514 | Superada |
| PC-08 | INDICACION_DIAGNOSTICO | Asociación duplicada | Rechazo 23505 | Superada |
| PC-09 | INDICACION | Modificación histórica | Rechazo P2001 | Superada |

Los ocho casos fueron ejecutados en `huellas_g05_cobertura`.

Evidencia: [Ejecución de cobertura adicional](../evidencias/Ejecucion_Jeank_Cobertura.md).

Total acumulado: 33 casos distintos ejecutados satisfactoriamente.