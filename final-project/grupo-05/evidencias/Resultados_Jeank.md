
# Resultados del bloque de Jean Carlos

## 1. Identificación

- Proyecto: Refugio Huellas Seguras.
- Grupo: 05.
- Responsable: Jean Carlos Segura.
- Proceso: G05-P03 — Reserva y formalización de adopciones.
- Motor: PostgreSQL 16.
- Cliente utilizado: psql 16.16.
- Sistema operativo: Windows.
- Zona horaria: America/Costa_Rica.
- Datos utilizados: exclusivamente ficticios.

## 2. Alcance

Se implementaron las nueve relaciones asignadas:

- INDICACION.
- INDICACION_DIAGNOSTICO.
- APLICACION_INDICACION.
- RESERVA.
- ADOPCION.
- ADOPCION_RESPONSABLE.
- SEGUIMIENTO_ADOPCION.
- RESTRICCION_PERSONA.
- RESULTADO_ETAPA.

El bloque se integra con las estructuras de alojamiento,
solicitudes, compatibilidad, disponibilidad y evaluaciones
veterinarias desarrolladas por los demás integrantes.

## 3. Resultados del proceso G05-P03

| Código | Escenario | Resultado observado | Estado |
|---|---|---|---|
| PJ-01 | Reserva válida | Reserva registrada correctamente | Superada |
| PJ-02 | Segunda reserva vigente para el mismo animal | P3021: El animal ya tiene una reserva vigente | Superada |
| PJ-03 | Persona con restricción vigente | P3015: La persona tiene una restriccion vigente documentada | Superada |
| PJ-04 | Formalización válida | Adopción registrada y cierre consistente | Superada |
| PJ-05 | Formalización repetida | P3017: La reserva ya fue finalizada | Superada |
| PJ-06 | Contexto de ingreso incorrecto | P2025: La adjudicación requiere la etapa abierta del animal indicado | Superada |
| PJ-07 | Adopciones individuales de una misma solicitud | Dos adopciones consistentes | Superada |
| PJ-08 | Resultado incompatible con adopción | P3022: El ingreso ya fue cerrado mediante una adopcion | Superada |
| PJ-09 | Devolución voluntaria | Nuevo ingreso 18, evaluación inicial y cero restricciones automáticas | Superada |
| PJ-10 | Reservas concurrentes | Una sesión confirma y la otra recibe P3021 | Superada |
| PJ-11 | Atomicidad de formalización | P1006, sin efectos parciales y reintento exitoso | Superada |
| PJ-12 | Instalación e integración | 28 tablas y formalización consistente en base nueva | Superada |

## 4. Integridad clínica

| Código | Escenario | Resultado observado | Estado |
|---|---|---|---|
| PC-01 | Estado de aplicación realizada | REALIZADA | Superada |
| PC-02 | Modificación de aplicación realizada | P3005 | Superada |
| PC-03 | Fecha planificada anterior a evaluación | P3008 | Superada |
| PC-04 | Aplicación sin responsable | P3011 | Superada |
| PC-05 | Registro válido de aplicación | Aplicación 3002 REALIZADA | Superada |
| PC-06 | Asociación con evaluación incorrecta | 23503: indicacion_diagnostico_contexto_fk | Superada |
| PC-07 | Asociación con evaluación correcta | Inserción válida dentro de transacción reversible | Superada |

## 5. Seguimiento de adopciones

| Código | Escenario | Resultado observado | Estado |
|---|---|---|---|
| PS-01 | Seguimiento válido | REALIZADO | Superada |
| PS-02 | Seguimiento anterior a adopción | P3045 | Superada |
| PS-03 | Modificación de seguimiento definitivo | P3042 | Superada |
| PS-04 | Reprogramación válida | Seguimiento 4 vinculado al seguimiento 3 | Superada |
| PS-05 | Reprogramación de otra adopción | P3048 | Superada |

## 6. Permisos

| Código | Escenario | Resultado observado | Estado |
|---|---|---|---|
| PP-01 | Modificación directa de indicación por operador | Permiso denegado | Superada |

## 7. Estado final de la ejecución secuencial

| Adopción | Animal | Ingreso | Integridad |
|---|---|---|---|
| 1 | HS-01 | 1 | CONSISTENTE |
| 2 | HS-02 | 2 | CONSISTENTE |
| 4 | HS-03 | 3 | CONSISTENTE |

Las tres adopciones tienen a la persona 101 como
responsable adoptivo.

La adopción 1 conserva su historial de devolución
voluntaria y el animal HS-01 cuenta con un nuevo
ingreso identificado con el número 18.

La persona 101 pudo reservar y adoptar posteriormente
al animal HS-03, sin una prohibición automática.

## 8. Correcciones verificadas

- Asociación contextual entre indicación y diagnóstico.
- Correspondencia entre animal e ingreso de adopción.
- Referencia al receptor de una devolución.
- Compatibilidad individual vinculada con la reserva.
- Exclusividad de reserva vigente.
- Confirmación transaccional de adopciones.
- Permisos de la función de comprobación diferida.
- Conservación del historial clínico y de seguimiento.

## 9. Resumen

Se verificaron 33 casos identificados:

- 18 casos principales PJ.
- 9 casos clínicos PC.
- 5 casos de seguimiento PS.
- 1 caso de permisos PP.

Los casos negativos obtuvieron los rechazos esperados.
Las comprobaciones positivas confirmaron los estados
consultados en PostgreSQL.

La cobertura se limita a los escenarios documentados;
la matriz de integridad identifica las demás reglas
y su mecanismo de implementación.

## 10. Evidencias relacionadas

- [Ejecución secuencial](Ejecucion_Jeank_Secuencial.md).
- [Ejecución concurrente](Ejecucion_Jeank_Concurrencia.md).
- [Instalación](Ejecucion_Jeank_Instalacion.md).
- [Casos reproducibles](../pruebas/Casos_Jeank.md).
