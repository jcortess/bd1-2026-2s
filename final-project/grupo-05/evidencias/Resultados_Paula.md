# Resultados ejecutados · Paula · G05-P02

Estado: las nueve relaciones de Paula, la ampliación de compatibilidad y las operaciones de G05-P02 están implementadas y probadas. La entrega del equipo sigue incompleta por las nueve relaciones y G05-P03 de Jean Carlos. Esta evidencia no sustituye su trabajo ni afirma la integración de tablas ausentes.

## Entorno, instalación y fuentes

Ejecución del 24-11-2026 en bases **nuevas de pruebas**, con PostgreSQL **18.6 (Ubuntu 18.6-0ubuntu0.26.04.1), x86_64, 64 bits**, `psql` 18.6, UTF-8 y `btree_gist`. Se utilizó Ubuntu/WSL; Docker Desktop estaba detenido. Las conexiones muestran fechas en `America/Costa_Rica`. No se usaron credenciales personales ni se eliminaron bases previas. Versión del servidor/cliente y lecturas reales se localizan en [catálogo y consultas](Ejecucion_Paula_Catalogo.md).

La base de ejecución completa fue `huellas_g05_paula_20261124_c`. El [guion instalador](../sql/09_instalar_bloque_paula.sql) ejecutó 01–08 en orden, todos con salida cero: [transcripción de instalación](Ejecucion_Paula_Instalacion.md). Cargó 19 tablas (18 originales y una ampliación), 131 atributos, 36 FK; 17 ingresos, 17 iniciales y dos revisiones; dos reportes, cuatro apariciones diagnósticas y dos cambios de disponibilidad. Las solicitudes/compatibilidades estaban vacías antes de operar. [Conciliación de fuentes y hashes](../modelo/Conciliacion_Paula.md).

La regresión separada usó `huellas_g05_paula_regresion_20261124`. `_a` y `_b` son bases nuevas de los intentos fallidos de desarrollo, conservadas sin borrado; no son la evidencia de la versión que pasó.

## Pruebas secuenciales y persistencia

[02_bloque_paula.sql](../pruebas/02_bloque_paula.sql) terminó con **código 0**. Se cotejaron sus **120 identificadores previstos** con los **120 resultados únicos observados**: **105 rechazos por la causa prevista y 15 aserciones de datos**. El guion captura SQLSTATE, nombre de restricción y mensaje verdadero; propaga cualquier error distinto. Las aserciones leen valores y pertenencias, no se limitan a mensajes de éxito. [Cada caso con preparación/acción/esperado/observado/final](../pruebas/Casos_Paula.md) · [transcripción íntegra](Ejecucion_Paula_Secuencial.md).

| Casos y regla | Esperado antes de ejecutar | Observado y estado final |
|---|---|---|
| P01/P02 · RN-16/17, AC-01/02 | Crear general, luego dos intereses y entrevista sin modificar estado por su resultado. | Solicitud 1 RECIBIDA tras entrevista; HS-01/02 asociados a las 09:00 del 07-10. Evento 2 tiene resultado y observaciones, responsable 7, estado NULL. |
| P03/P04 · RN-18/19, AC-01/04 | Sin decisión: P2024. Con aprobación pero sin evaluación: P2026. Dos evaluaciones concretas distintas. | Decisión 3 APROBADA, responsable 1 y razón. HS-01 FAVORABLE/ingreso 1 y HS-02 NO_FAVORABLE/ingreso 2, mismo hogar «Casa A con patio cerrado», actividad 2. El consumidor devolvió ID favorable para HS-01 y rechazó HS-02 con P2026 e ingreso ajeno con P2025. |
| P05 · RN-18, AC-03 | Rechazo conserva razones/actividad y nueva solicitud de la misma persona permanece separada. | Solicitud 3 de persona 101 tiene recepción, pendiente, actividad de información y rechazo 8. Solicitud 4 de persona 101, posterior, RECIBIDA y general; historia anterior intacta. La solicitud 2 de otra persona considera los mismos dos animales. |
| P06 · RN-17/18, frontera de alcance | No visita universal ni plazo fijo; estados del caso con decisiones atribuidas. | Los siete estados aparecen en historia. La solicitud general 1 no requirió visita; otra solicitud sí registró visita concreta. No se agregó vencimiento automático por días. |
| P07 · README §6/7, atomicidad | Segundo detalle inexistente después de cabecera/recepción/primer detalle revierte todos. | `23503 / solicitud_animal_animal_codigo_fkey`; no existe solicitud ni evento con clave ...0099. Siguen cinco solicitudes, cinco recepciones y cuatro intereses. |
| P08–P10 · identidad/referencia/dominio/contexto | Rechazar duplicados, referencias ausentes, datos obligatorios, actor inválido, contexto cruzado y decisión no válida. | Causas exactas registradas por caso; incluida FK clínica con ambos contextos existentes. Actividades y decisión 3 permanecieron. |
| P11 · historial individual | Una pendiente posterior impide usar un favorable anterior; no lo borra. | HS-01 conserva dos valoraciones; la última quedó PENDIENTE_INFORMACION el 10-10. Consumidor: P2026. HS-02 conserva NO_FAVORABLE. |
| R01/R02 · RN-02/S-07 | Reporte desconocido válido, M:N válido, PK/FK/nulos y cambio/eliminación referencial. | Reporte 1 vinculado a HS-01/02 y reporte 2 desconocido. Rectificación válida observable dentro del fixture, restaurada al revertir. Referencias/duplicados fallaron por sus restricciones. |
| R03/P12/P13 · RN-10 | Revisión completa con profesional vigente, inicial por etapa y fronteras. | Registro 104 válido a 09:59:59.999999 del 06-10, inválido a 10:00 exactas (P2012). Peso 0.001 válido; cero/NaN rechazados. Campos faltantes: chk_revision_campos. Inicial ausente al confirmar: P2013. Dos etapas de PA-ETAPAS tienen iniciales independientes; revisión de segunda sin inicial: P2011 y evaluación al fin de primera: P2010. |
| R04/R05/H01 · RN-11 y reutilización Lab03 | Catálogo/pareja/estado válidos; solo revisión; historial conservado; consultas y conteo actuales. | HS-01: tres evaluaciones, dos revisiones y dos apariciones confirmadas. Inicial sin diagnóstico; Otitis PROVISIONAL y luego DESCARTADO en revisiones distintas. PK/UQ/FK y estados inválidos rechazados; cambios/borrados de historia P2001. |
| R06 · RN-14/15, AC-04 | Disponibilidad humana con valoración y observación; diagnóstico no determina habilitación. | HS-01 con Dermatitis CONFIRMADO y decisión HABILITADO atribuida. Suspensión/restablecimiento producen tres decisiones visibles en fixture; se revierten. No se altera disponibilidad por agregar diagnóstico. |
| R07–R09/H02 | Identidad e historia de solicitud/evento/compatibilidad, mismo animal en hogares distintos. | Duplicados PK rechazados; valoraciones de hogares de personas 101 y 102 permanecen contextualizadas en fixture. UPDATE/DELETE de hechos históricos rechazados con P2001, sin reinterpretar hogar ni perder decisiones. |
| P12/P14 | Solicitud requiere recepción; rol sin DML/TRUNCATE/privadas; READ COMMITTED. | P2020 sin recepción. 42501 por DML, TRUNCATE y consumo privado operativo; P1001 en REPEATABLE READ. |
| P15 · lecturas posteriores | Confirmados conservados, fixtures revertidos y ausencia de intentos fallidos. | Cinco solicitudes, cuatro intereses, tres valoraciones históricas, 21 evaluaciones (19 de semilla y dos iniciales P13) y dos disponibilidades. Solicitud 1 APROBADA/decisión 3; solicitud 3 RECHAZADA; solicitud 4 RECIBIDA. No existe RESERVA instalada. |

Las pruebas R/H muestran estado dentro de su transacción antes de ROLLBACK; P15 comprueba el retorno de esos antecedentes. P01–P11 y P13 tienen COMMIT y lecturas posteriores. La evidencia concurrente verifica otra vez en conexiones separadas. Los IDs saltan por intentos revertidos: no se infiere cantidad de filas a partir de una secuencia.

## Dos sesiones reales por carrera y observador

[Guiones](../pruebas/concurrencia_paula) · [transcripción con PID/bloqueos/confirmaciones](Ejecucion_Paula_Concurrencia.md) · [orden reproducible](../README.md#dos-sesiones-concurrentes-de-paula).

| Caso | Estado inicial / orden / esperado | Observado mientras ambas conexiones estaban abiertas | Estado final y conclusión |
|---|---|---|---|
| C-P01, AC-P02 / README §6 | Solicitud 13 RECIBIDA, recepción 29. A aprueba sin confirmar. B lee antecedente 29 y pide RECHAZADA. Debe esperar y detectar nueva decisión al confirmar A. | PID A 478 idle in transaction; B 482 active, `Lock/advisory`, `pg_blocking_pids={478}`, `a_bloquea_b=t`. Se liberó A solo después de observarlo. | A confirmó decisión 31 APROBADA, actor 1. B obtuvo P2021 y su COMMIT no dejó decisión ...0004. Recepción y aprobación permanecen. Ambas conexiones terminaron código 0 por captura esperada. |
| C-P02, misma solicitud / README §6 | Solicitud 14 RECIBIDA, recepción 30. A aprueba y mantiene bloqueo. B decide rechazo desde la recepción observada. A debe revertir; B puede confirmar. | PID A 496 idle in transaction; B 501 active, `Lock/advisory`, bloqueador 496. Se observó antes del ROLLBACK de A. | La decisión 33 de A no existe tras revertir; B confirmó 34 RECHAZADA, actor 7 y razón, antecedente 30. Solo recepción y rechazo. |
| C-P03, reintento e historia | Consultar clave de A confirmada; reenvío ciego no duplica. Nueva decisión informada enlaza la anterior. | Reenvío obtuvo P2021, capturado con SQLSTATE real. La clave de A sigue apuntando a decisión 31. | Solicitud 13 queda PENDIENTE_INFORMACION con decisión 36, antecedente 31. Conserva 29→31→36. Solicitud 14 conserva 30→34 RECHAZADA. Consulta posterior en autocommit confirmó las cinco filas históricas. |

La competencia es por la decisión de solicitud. La compatibilidad favorable no adjudica animal frente a otra familia; esa competencia pertenece a P03. No se usaron dos llamadas secuenciales como evidencia concurrente.

## Regresión del trabajo existente y catálogo

El [guion original de Jason](../pruebas/01_bloque_jason.sql) se ejecutó intacto en una base nueva con los 19 objetos: **salida 0**, 85 rechazos esperados y aserciones de valores correctas. [Transcripción actual](Ejecucion_Paula_Regresion_Jason.md). También se ejecutaron sus **dos carreras originales**, sin editar los guiones: cupo, A 487/B 491, espera advisory y rechazo P1014; traslado, A 506/B 513, espera advisory y rechazo P1006. La verificación final original terminó salida 0. [Transcripción concurrente de regresión](Ejecucion_Paula_Regresion_Jason_Concurrencia.md). No se confunden con las evidencias históricas de Jason/Lab03.

[03_catalogo_paula.sql](../pruebas/03_catalogo_paula.sql) comprobó las diez relaciones propias, SELECT operativo, ausencia de INSERT/UPDATE/DELETE/TRUNCATE/TRIGGER, restricciones validadas, iniciales por etapa y consumo privado no expuesto. [04_consultas_paula.sql](../pruebas/04_consultas_paula.sql) volvió a leer versión, reportes, diagnósticos, estado/historia/contextos y disponibilidades. Ambos terminaron código 0: [salida íntegra](Ejecucion_Paula_Catalogo.md).

## Errores de desarrollo corregidos y límites pendientes

El intento `_a` descubrió una negativa de contexto que fallaba antes por inicial duplicada; se cambió el dato de prueba a revisión completa y el caso final obtuvo la FK esperada. `_b` descubrió falta de permiso sobre la tabla temporal de resultados bajo SET ROLE; se concedieron SELECT/INSERT solo sobre ella, sin cambiar permisos de tablas de negocio. La ejecución `_c` pasó completa. También se corrigió codificación de texto generado desde PowerShell, sin modificar las salidas del motor. [Registro de IA](../Uso_de_IA.md).

No quedaron pruebas propias sin ejecutar. Siguen pendientes de integración las pruebas que requieren tablas de Jean Carlos: FK clínica de INDICACION_DIAGNOSTICO, reserva/adopción/restricciones y regreso/cierre integral. En particular, P15 observa ausencia de la tabla RESERVA: P02 no creó tabla ni reserva. Al integrar la tabla real debe repetirse su conteo antes/después de aprobación, sin sustituirla por una tabla testigo. No se afirma cumplida esa integración ni terminado el 100 % físico del equipo. Video, revisión humana del diseño y enlace de defensa siguen pendientes.

Los comandos y orden completos para reproducir instalación, suite, catálogo, consultas y sesiones están en [README](../README.md#bloque-de-paula-g05-p02). La copia de guiones históricos no se usa como evidencia de una ejecución actual sin repetirlos.

## Revisión final de consistencia y Git

Se compararon el catálogo, el diccionario y el diagrama: mismas 19 tablas y 131 columnas en orden; los 22 cuerpos de función nuevos coinciden con los SQL entregados. Los enlaces locales de documentos nuevos/modificados existen, la documentación es UTF-8 y el prompt archivado coincide con el adjunto. Se conservó el contenido de los 31 archivos preexistentes de SQL/pruebas de Jason y Lab03, normalizando únicamente la representación CRLF del checkout para la comparación con los blobs Git. Los aportes anteriores de Control de Cambios, Procesos y Uso de IA conservan su texto completo.

Rama final `grupo-05`; HEAD `18359c47876b1be9dd0990724966c7358318dc04`, sin divergencia respecto de `origin/grupo-05` tras fetch. `main` sigue en `c1bbe678949fceff811211ac45a209393935f065`. `git diff --check` sin errores. Cambios únicamente en `final-project/grupo-05/`: **30 archivos nuevos y 5 modificados**, sin stage, commit, push, merge ni PR.

### Archivos creados

- [Defensa.md](../Defensa.md).
- [evidencias/Ejecucion_Paula_Catalogo.md](../evidencias/Ejecucion_Paula_Catalogo.md).
- [evidencias/Ejecucion_Paula_Concurrencia.md](../evidencias/Ejecucion_Paula_Concurrencia.md).
- [evidencias/Ejecucion_Paula_Instalacion.md](../evidencias/Ejecucion_Paula_Instalacion.md).
- [evidencias/Ejecucion_Paula_Regresion_Jason.md](../evidencias/Ejecucion_Paula_Regresion_Jason.md).
- [evidencias/Ejecucion_Paula_Regresion_Jason_Concurrencia.md](../evidencias/Ejecucion_Paula_Regresion_Jason_Concurrencia.md).
- [evidencias/Ejecucion_Paula_Secuencial.md](../evidencias/Ejecucion_Paula_Secuencial.md).
- [evidencias/Prompt_Desarrollo_Paula.md](../evidencias/Prompt_Desarrollo_Paula.md).
- [evidencias/Resultados_Paula.md](../evidencias/Resultados_Paula.md).
- [modelo/Conciliacion_Paula.md](../modelo/Conciliacion_Paula.md).
- [modelo/Diagrama_Relacional.md](../modelo/Diagrama_Relacional.md).
- [modelo/Diccionario_Datos.md](../modelo/Diccionario_Datos.md).
- [modelo/Matriz_Integridad.md](../modelo/Matriz_Integridad.md).
- [modelo/Modelo_Relacional.md](../modelo/Modelo_Relacional.md).
- [pruebas/02_bloque_paula.sql](../pruebas/02_bloque_paula.sql).
- [pruebas/03_catalogo_paula.sql](../pruebas/03_catalogo_paula.sql).
- [pruebas/04_consultas_paula.sql](../pruebas/04_consultas_paula.sql).
- [pruebas/Casos_Paula.md](../pruebas/Casos_Paula.md).
- [pruebas/concurrencia_paula/00_preparacion.sql](../pruebas/concurrencia_paula/00_preparacion.sql).
- [pruebas/concurrencia_paula/01_commit_a.sql](../pruebas/concurrencia_paula/01_commit_a.sql).
- [pruebas/concurrencia_paula/02_commit_b.sql](../pruebas/concurrencia_paula/02_commit_b.sql).
- [pruebas/concurrencia_paula/03_rollback_a.sql](../pruebas/concurrencia_paula/03_rollback_a.sql).
- [pruebas/concurrencia_paula/04_rollback_b.sql](../pruebas/concurrencia_paula/04_rollback_b.sql).
- [pruebas/concurrencia_paula/05_espera.sql](../pruebas/concurrencia_paula/05_espera.sql).
- [pruebas/concurrencia_paula/06_verificar.sql](../pruebas/concurrencia_paula/06_verificar.sql).
- [sql/05_paula_esquema.sql](../sql/05_paula_esquema.sql).
- [sql/06_paula_operaciones.sql](../sql/06_paula_operaciones.sql).
- [sql/07_paula_datos.sql](../sql/07_paula_datos.sql).
- [sql/08_paula_consultas.sql](../sql/08_paula_consultas.sql).
- [sql/09_instalar_bloque_paula.sql](../sql/09_instalar_bloque_paula.sql).

### Archivos modificados

- [Control_de_Cambios.md](../Control_de_Cambios.md).
- [Integracion.md](../Integracion.md).
- [Procesos_Negocio.md](../Procesos_Negocio.md).
- [README.md](../README.md).
- [Uso_de_IA.md](../Uso_de_IA.md).
