# Uso de Inteligencia Artificial — Grupo 08: Envíos Conecta

## 1. Declaración

El grupo **sí utilizó** herramientas de inteligencia artificial en la segunda entrega, conforme a lo que permite el enunciado general (sección 10) y el anexo del Grupo 08 (secciones A y F). Todo material incorporado fue revisado por el grupo, y cada integrante debe poder explicar su propósito, sus límites y cómo se validó.

## 2. Herramientas

| Herramienta | Proveedor | Modelo | Medio de uso | Integrante(s) que la usaron |
|---|---|---|---|---|
| Claude | Anthropic | Claude Sonnet 5.5 | claude.ai (chat) | Eddy, Gherlan |
| Claude | Anthropic | Claude Opus 5.5 | claude.ai (chat) | Eddy |

## 3. Aportes de la IA

| # | Aporte | Incorporado | Dónde |
|---|---|---|---|
| IA-01 | Lectura y resumen del enunciado general, el anexo del Grupo 08 y la especificación del control de cambios | Como apoyo, no como texto entregado | — |
| IA-02 | Revisión del modelo relacional del Proyecto 1 y de los scripts de Lab03 para identificar defectos frente al anexo (por ejemplo, recolección obligatoria en ENVIO, eventos simultáneos, restricciones de devolución) | Sí, como hallazgos pendientes de decisión | `Control_de_Cambios.md`, secciones 1.3 y 4.3 |
| IA-03 | Cruce de las reglas RN-01 a RN-25 y los supuestos S-01 a S-19 con el modelo y el anexo, señalando qué cubre la estructura, qué requiere un mecanismo adicional y qué supuestos contradicen el anexo (S-01, S-09, S-11, S-16 con S-19) | Sí | `Control_de_Cambios.md`, secciones 2 y 4 |
| IA-04 | Propuesta del criterio de desempate para el evento actual (momento del hecho, luego momento de registro, luego identificador del evento; los eventos corregidos dejan de ser vigentes) | Sí, aceptada por el grupo | CAM-003 |
| IA-05 | Propuesta de la nueva redacción de S-01 (participantes identificados con tipo y número, coherentes con el cliente vinculado) | Sí, aceptada por el grupo | CAM-001 |
| IA-06 | Propuesta de que la nueva recolección referencie a la que reemplaza, con referencia única | Sí, aceptada por el grupo | CAM-002 |
| IA-07 | Propuesta de representación física de la devolución por paquete (eliminación de claves únicas, referencia compuesta al envío) | Sí, como propuesta a confirmar al escribir el esquema | CAM-004 |
| IA-08 | Redacción de `Control_de_Cambios.md` y de este documento a partir de las decisiones del grupo | Sí, revisado por el grupo | `Control_de_Cambios.md`, `Uso_de_IA.md` |
| IA-09 | Mapa de trabajo y una primera versión del control de cambios | **No.** El grupo los descartó porque daban por aceptados cambios que el grupo no había decidido | — |
| IA-10 | Instrucciones para verificar e instalar PostgreSQL en Windows | Como apoyo, no como texto entregado | — |
| IA-11 | Comparación del diccionario de datos del Proyecto 1 (solo PAQUETE) y del modelo relacional con las 9 tablas de Lab03; detección de que la medición aplicada ya era una FK compuesta y de que faltaba la unidad de volumen | Sí | `Control_de_Cambios.md`, sección 1.3; PEN-14; retiro de PEN-15 |
| IA-12 | Comandos para conectarse a PostgreSQL 19 (puerto y codificación) y para ejecutar los scripts de Lab03 guardando su salida; análisis del fallo de P09 en PostgreSQL 19 | Como apoyo; las evidencias son las salidas reales de la ejecución | `evidencias/lab03_0*.txt`; `Control_de_Cambios.md`, sección 3.1 |
| IA-13 | Ofrecimiento de opciones con sus consecuencias para PEN-01, PEN-04, PEN-05, PEN-09 y PEN-14, y redacción de los registros CAM-005 a CAM-009 a partir de las decisiones del grupo | Sí | `Control_de_Cambios.md`, CAM-005 a CAM-009 y secciones 4.1 y 4.3 |
| IA-14 | Versión mínima del modelo relacional consolidado: 32 relaciones con los cambios CAM-001 a CAM-009, dominios conocidos y diagrama Mermaid | Sí | `modelo/Modelo_Relacional.md` |
| IA-15 | Opciones con sus consecuencias para los pendientes de estructura (PEN-02, 03, 06, 07, 08, 11, 13, 16 a 24) y redacción de CAM-010 a CAM-023 a partir de las decisiones del grupo | Sí | `Control_de_Cambios.md`, CAM-010 a CAM-023 |
| IA-16 | Esquema físico completo en cuatro bloques, con sus restricciones, triggers y restricciones de exclusión | Sí, revisado y ejecutado por el grupo | `sql/01_esquema.sql` |
| IA-17 | Diccionario de datos, matriz de integridad, dominios cerrados, actualización de las relaciones y justificación de la excepción de BCNF | Sí | `modelo/Modelo_Relacional.md`, secciones 2, 3, 5, 6 y 7 |
| IA-18 | Revisión de las validaciones automáticas del repositorio (`.github/workflows`) para identificar condiciones del Pull Request | Como apoyo | — |

## 4. Prompts utilizados para el material incorporado

Se resumen los pedidos que dieron origen al material incorporado (no se transcribe toda la conversación).

| Aporte | Pedido del grupo a la herramienta |
|---|---|
| IA-01 | Se entregaron los tres enunciados y se pidió ayuda con el Proyecto 2, a partir del Proyecto 1 y Lab03 |
| IA-02 | Se entregaron el modelo relacional del Proyecto 1 (PDF exportado del `.drawio`) y los cinco scripts de Lab03 para su revisión |
| IA-03 | «vamos con las reglas»; se entregaron las reglas RN-01 a RN-25 y luego los supuestos S-01 a S-19 del Proyecto 1 |
| IA-04 a IA-06 | Tras decidir el grupo cómo resolver S-01, S-09, S-11 y S-16, se pidió a la herramienta completar los detalles: «eso lo puedes decidir ya que no tiene tanta relevancia» |
| IA-07, IA-08 | «haz el control de cambios entero con lo que tenemos ahora, si puedes también el de uso de ia» |
| IA-11 | Se entregó el diccionario de datos del Proyecto 1 y se pidió quitar el pendiente de comparación: «te doy el diccionario y me quitas eso» |
| IA-12 | «como verifico» (versión de PostgreSQL); «hagamos el 1» (ejecutar Lab03 en PostgreSQL 19) |
| IA-13 | Decisiones del grupo sobre cada pendiente, por ejemplo «es opcional», «un atributo», «metros cúbicos» |
| IA-14 | Continuación del paso 1, con entrega del contenido para copiar y pegar |
| IA-15 | Decisiones del grupo sobre cada pendiente, una por una («mejor vamos 1x1») |
| IA-16, IA-17 | «vamos a terminar el paso 2»; entrega del contenido por bloques para copiar y pegar |
| IA-18 | «hay alguna condicion cuando hagamos el pull request? en el lab 03 lo había» |

## 5. Decisiones propias del grupo

Estas decisiones las tomó el grupo; la herramienta solo las registró o detalló.

| Decisión | Registro |
|---|---|
| Usar PostgreSQL 19.0 | `Control_de_Cambios.md`, sección 1 |
| Permitir varios eventos de seguimiento en el mismo instante (S-11) | CAM-003 |
| Registrar una devolución por cada paquete (S-16 y S-19) | CAM-004 |
| Crear una nueva recolección al reprogramar (S-09) | CAM-002 |
| Ajustar el supuesto S-01 para que se adecúe al anexo | CAM-001 |
| Conservar `fn_prioridad_solicitud` y `fn_reporte_prioridades` de Lab03 | `Control_de_Cambios.md`, sección 3.1 |
| Rehacer el trabajo desde cero y no dar por aceptado ningún cambio que el grupo no haya decidido | Sección 3, IA-09 |
| Mantener como pendientes los hallazgos PEN-01 a PEN-23 hasta decidirlos | `Control_de_Cambios.md`, sección 4.3 |
| La recolección es opcional para el envío (PEN-01) | CAM-005 |
| La política de contenido se representa como atributo del paquete, y no como catálogo (PEN-04; se apartó de la recomendación de la herramienta) | CAM-006 |
| Ubicación de eventos con sede o descripción, al menos una de las dos (PEN-05) | CAM-007 |
| CHECK de exclusividad en la asignación (PEN-09) | CAM-008 |
| Volumen en metros cúbicos (PEN-14) | CAM-009 |
| Ejecutar los scripts de Lab03 en PostgreSQL 19 y no repetir `05_pruebas.sql` tras el fallo de P09 | `evidencias/` |
| Descartar la revisión de codificación de tildes y el registro del fallo de P09 por ahora | — |
| Categoría OTRO con descripción obligatoria en medios de contacto | CAM-010 |
| Trigger para que solo las organizaciones tengan contactos (se apartó de la recomendación de la herramienta) | CAM-011 |
| Solución mixta para los mínimos de envíos y paquetes | CAM-012 |
| Validar la tarifa aplicable en la rutina de P01 | CAM-013 |
| Destino de la solicitud como destino general, sin cambio de estructura | PEN-20 |
| Precio en colones y mediciones que solo se agregan | CAM-009, CAM-014 |
| Eliminar la referencia de la devolución a la incidencia: la devolución solo ocurre por un paquete rechazado | CAM-020 |
| Mantener solo las entregas rechazadas como causa de devolución, por la cantidad de cambios que exigía la alternativa | CAM-020 |
| Resultado de incidencia por paquete obligatorio | CAM-021 |
| Listas de valores de los dominios cerrados | `modelo/Modelo_Relacional.md`, sección 3 |

## 6. Validación del material incorporado

| Aporte | Cómo se validó | Resultado |
|---|---|---|
| IA-02, IA-03 | Contraste de cada hallazgo con el texto del anexo, las reglas RN y los supuestos S del Proyecto 1 | _Pendiente_ |
| IA-04 a IA-07 | Pruebas de la versión actual indicadas en la evidencia de cada CAM | _Pendiente: se completa al ejecutar las pruebas_ |
| IA-08 | Revisión de `Control_de_Cambios.md` frente a la especificación común (cinco secciones y diez campos por registro) | _Pendiente_ |
| IA-11 | Contraste del diccionario y del `.drawio` con `01_esquema.sql` de Lab03 | _Pendiente_ |
| IA-12 | Ejecución real en PostgreSQL 19.0: P01 a P08 aprobadas, F02 y F03 coinciden con lo esperado; P09 falla por el tipo de error capturado | Registrado en `evidencias/` |
| IA-14 | Revisión del modelo frente al `.drawio` del Proyecto 1 y los CAM registrados | _Pendiente_ |
| IA-16 | Ejecución de `sql/01_esquema.sql` en una base nueva de PostgreSQL 19.0, después de cada bloque y de cada corrección | Sin errores |

**Errores de la herramienta detectados por el grupo:**
- Presentó como plan del grupo una lista de cambios inicial que el grupo no había aprobado (IA-09). Se descartó.
- Afirmó inicialmente que los conflictos de supuestos no podían resolverse con código existente; el grupo aclaró que se resolverían en base al código nuevo de esta entrega.
- Envió una versión anterior de `Control_de_Cambios.md` en lugar de la actualizada, y en otra ocasión reenvió el archivo completo con un pendiente (PEN-22) que el grupo ya había quitado. Desde entonces solo entrega fragmentos.
- La numeración de pendientes de la herramienta dejó de coincidir con la del grupo después de que el grupo eliminó uno; la herramienta citó un número (PEN-23) que en la copia del grupo correspondía a otro pendiente (PEN-22), y el grupo agregó una fila duplicada que luego eliminó.


