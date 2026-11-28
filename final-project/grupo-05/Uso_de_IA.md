# Uso de IA · Grupo 05 · Huellas Seguras

## Aporte de Jason

Se utilizó ChatGPT Codex, con herramientas locales de lectura, edición y terminal, para desarrollar esta primera versión del bloque. Codex contrastó la documentación de Proyecto 1 y Lab03, propuso los mecanismos de integridad, escribió los archivos SQL y Markdown y ejecutó las pruebas PostgreSQL. El anexo y la hoja del profesor sustentan las correcciones académicas. El Word sustenta el reparto de trabajo.

## Instrucciones relevantes del usuario

- «Desarrolles la parte que me corresponde a mí, Jason Madrigal Pineda. Debes trabajar directamente en los archivos del proyecto, con SQL ejecutable, documentación y pruebas.»
- «Conserva esa decisión mientras satisfaga las exigencias actuales. Impide que cambiar el oferente de una ubicación reinterprete las estancias históricas.»
- «Tratar cierre de estancia anterior y apertura de nueva como una sola operación atómica. Si falla el destino, la estancia anterior debe conservarse.»
- Resolver la dependencia circular entre INGRESO.adopcion_origen_id y ADOPCION, a cargo de Jean Carlos.
- «No presentes llamadas secuenciales como prueba de concurrencia. Identifica preparación, intercalación, confirmaciones, rechazos o reintentos y estado final.»

## Decisiones y validación

Se mantuvo N-01 y se propusieron los actores de movimiento como vínculos independientes. Se eligieron intervalos semiabiertos, una primitiva privada para el cierre futuro y un bloqueo asesor transaccional en `READ COMMITTED`. La propuesta de diseño queda documentada para revisión y defensa por parte de Jason. Esta intervención no acredita una revisión manual por los tres integrantes. [Modelo](modelo/Modelo_Jason.md) · [Proceso y límites](Procesos_Negocio.md)

Se ejecutó la carga desde cero en PostgreSQL 16.15, se verificaron persistencia y rechazos y se observaron los bloqueos con sesiones simultáneas. Las comprobaciones explícitas delimitan lo que se verificó. La integración con las relaciones de Paula y Jean Carlos permanece pendiente. [Evidencia](evidencias/Resultados_Jason.md)

## Aporte de Paula · 24 de noviembre de 2026

Herramienta de IA utilizada: **ChatGPT Codex** para analizar fuentes, proponer/implementar SQL, preparar pruebas y consolidar Markdown. Se usaron Git/terminal local, Python para extraer Word/Excel/PDF y contrastar artefactos, PostgreSQL/psql para ejecuciones reales y documentación oficial del repositorio/PostgreSQL para requisitos y mecanismos. Esas herramientas auxiliares no se presentan como otras conversaciones de IA. El texto histórico de Jason se conserva; lo que allí era pendiente se actualiza mediante este apartado, sin inventar prompts o validaciones de Jean Carlos.

### Prompt relevante y alcance incorporado

La solicitud íntegra está conservada en [Prompt_Desarrollo_Paula.md](evidencias/Prompt_Desarrollo_Paula.md), con origen y SHA-256. Incluye trabajar en grupo-05 sin push/merge/PR, leer los cinco materiales y antecedentes, implementar exclusivamente las nueve relaciones y G05-P02 de Paula, corregir compatibilidad/diagnóstico/eventos/obligatoriedad, ejecutar pruebas reales y documentar honestamente las dependencias. Fue el único prompt de desarrollo de esta intervención. Las peticiones de ejecución autónoma no se interpretaron como autorización para modificar la asignación de los compañeros.

La asistencia incorporada está en `sql/05_paula_esquema.sql`, `06_paula_operaciones.sql`, `07_paula_datos.sql`, `08_paula_consultas.sql`, `09_instalar_bloque_paula.sql`; pruebas `02_bloque_paula.sql`, `03_catalogo_paula.sql`, `04_consultas_paula.sql` y sesiones `concurrencia_paula/`; modelo, diccionario, diagrama, matriz, casos, evidencias y anexos documentales de esta versión. Los SQL de Jason y Lab03 no se editaron. El inventario de archivos y las fuentes precisas están en [Resultados de Paula](evidencias/Resultados_Paula.md) y [Conciliación](modelo/Conciliacion_Paula.md).

### Decisiones propuestas por Codex

Compatibilidad individual histórica con FK compuestas y hogar inmutable por solicitud; estado derivado de decisiones con antecedente vigente; clave UUID para reconocer reenvíos sin duplicar; reutilización del bloqueo compartido y READ COMMITTED; inicial por etapa exigida al confirmar; registro veterinario vigente y conservación de historia clínica/administrativa. Se conservan la pareja de diagnóstico, la completitud de revisión y consultas válidas de Lab03, adaptando referencias reales del modelo final. Las decisiones D-P01…D-P10 se justifican en el [modelo](modelo/Modelo_Relacional.md).

Estas decisiones están **propuestas e implementadas por Codex** para revisión de Paula y del equipo. No se afirma que Paula, Jason o Jean Carlos hayan revisado/aprobado manualmente el código nuevo. La decisión sobre consumo de la nueva relación por P03 está explícitamente pendiente de revisión de Jean Carlos; no se modificaron tablas ajenas para dar ese acuerdo por hecho. La defensa debe demostrar la comprensión individual del material incorporado.

### Validaciones realmente ejecutadas

- Bases nuevas de pruebas, sin eliminar bases previas. La ejecución completa que pasó está en `huellas_g05_paula_20261124_c`; la regresión de Jason se hizo en `huellas_g05_paula_regresion_20261124`. PostgreSQL y psql 18.6 sobre Ubuntu/WSL, UTF-8 y `btree_gist`; Docker estaba detenido. No se declara probada la ampliación en 16.15 por haber sido esa la versión histórica de Jason/Lab03.
- Instalación 01–08 por el guion 09 y consultas reales: 19 tablas físicas y 131 atributos. Diccionario/diagrama derivados del catálogo, con claves, tipos, nulabilidad, dominios, índices y triggers actuales.
- Suite de Paula: 120 identificadores previstos y observados, 105 rechazos con causa esperada y 15 aserciones de valores/vínculos. Preparaciones, acciones, consultas, COMMIT/ROLLBACK y resultados completos están en las transcripciones. Se comprobó fallo de segundo detalle sin cabecera/recepción parciales.
- Dos carreras concurrentes de Paula con sesiones psql simultáneas y una observadora: B esperó Lock/advisory; con COMMIT de A obtuvo P2021 y con ROLLBACK de A confirmó. La lectura final preservó historia y el reintento informado enlazó una decisión nueva.
- Se ejecutaron el guion original de Jason (85 rechazos esperados y aserciones) y sus dos carreras originales en el esquema ampliado, sin modificar esos archivos. Sus resultados actuales se distinguen de la evidencia histórica del 19-11.
- Auditoría ejecutable de permisos y restricciones validadas en todas las tablas de Paula; lectura de catálogo y consultas posteriores en conexión nueva. Comparación de archivos Markdown/SQL, diagrama y enlaces locales para consistencia documental.

### Errores encontrados y corregidos durante esta intervención

| Error realmente observado | Corrección y validación |
|---|---|
| Primer intento del caso R03-contexto-ajeno obtenía `evaluacion_inicial_etapa_uq` antes de llegar a la FK pretendida: la etapa ya tenía inicial. | Preparar una revisión completa con registro válido y animal de otra etapa, evitando el duplicado inicial accidental. Repetir desde otra base; la causa observada final fue `23503 / evaluacion_ingreso_animal_fk`. |
| Segundo intento: P14, al usar SET ROLE, no podía insertar el resultado del rechazo en la tabla temporal creada por el instalador. | Conceder SELECT/INSERT únicamente sobre esa tabla temporal al rol de prueba. No se habilitó DML de producción. Suite final completa y auditoría de permisos pasaron. |
| La codificación predeterminada de la tubería PowerShell→Python sustituyó acentos en texto documental generado. | Usar UTF-8 explícito, corregir el texto y conservar intactas las salidas reales del motor. Se releyeron los documentos, se restauró el prompt exacto del adjunto y se contrastaron catálogo/diagrama/diccionario. No afectó los SQL escritos con apply_patch ni sus resultados. |

Las bases `_a` y `_b` conservan los intentos fallidos de pruebas; no se borraron ni se les atribuye una suite completa aprobada. Los defectos anteriores eran del guion/documentación generados durante esta sesión: no se atribuyen retrospectivamente a una IA o conversación de P1/Lab03 sin evidencia. Los resultados finales publicados corresponden a la repetición corregida.

### Limitaciones y pendientes verificables

Los nueve objetos de Jean Carlos y G05-P03 no están en el esquema final disponible; faltan su consumo real de compatibilidad/disponibilidad, corrección A2 de INDICACION_DIAGNOSTICO, regreso ligado a adopción, restricciones y exclusión de resultados/cierre completo. No se ejecutaron pruebas sobre esas tablas ausentes. La ausencia de reservas automáticas se constata sin tabla RESERVA real instalada, cuya comprobación antes/después debe repetirse al integrarla. Video, minutajes y aprobación humana del diseño siguen pendientes. No se inventan enlaces ni una certificación de coherencia del 100 % del proyecto del equipo.

## Aporte de Jean Carlos · 28 de noviembre de 2026

### Herramientas utilizadas

Se utilizó ChatGPT como herramienta de asistencia para el análisis de requisitos, diseño de mecanismos de integridad, generación y corrección de código SQL, preparación de pruebas y consolidación de documentación técnica. Visual Studio Code, PowerShell, Git, PostgreSQL y psql fueron herramientas de desarrollo y validación. Jean Carlos ejecutó las pruebas en su entorno local siguiendo las instrucciones preparadas con asistencia de ChatGPT.

### Instrucciones y alcance de la asistencia

La conversación iterativa se orientó a implementar las nueve relaciones asignadas y G05-P03, conservar los aportes de Jason y Paula, corregir A2 de Lab03, integrar reservas, adopciones, devoluciones y cierres, preparar pruebas válidas, negativas, concurrentes y de atomicidad, analizar resultados reales y consolidar la documentación sin atribuir resultados a pruebas no ejecutadas.

El [registro de instrucciones relevantes](evidencias/Prompt_Desarrollo_Jeank.md) es una reconstrucción de las instrucciones principales, no una transcripción literal completa.

### Componentes desarrollados con asistencia de IA

| Archivo | Propósito |
|---|---|
| `sql/10_jeank_esquema.sql` | Nueve relaciones físicas. |
| `sql/11_jeank_operaciones.sql` | Operaciones, funciones, procedimientos, triggers y permisos. |
| `sql/12_jeank_datos.sql` | Antecedentes ficticios. |
| `sql/13_jeank_consultas.sql` | Vistas y consultas de control. |
| `sql/14_instalar_bloque_jeank.sql` | Instalación del bloque. |
| `sql/15_instalar_proyecto_completo.sql` | Instalación consolidada. |
| `pruebas/05_preparacion_jeank.sql` a `pruebas/12_atomicidad_jeank.sql` | Preparación y pruebas. |
| `pruebas/concurrencia_jeank/` | Sesiones independientes. |
| `pruebas/Casos_Jeank.md` | Identificación de casos. |
| `evidencias/` | Resultados y ejecuciones del bloque. |
| `modelo/` | Consolidación del modelo, diccionario, diagrama y matriz. |

También se utilizó asistencia para actualizar README, Integración, Procesos de Negocio, Control de Cambios, Uso de IA y preparar la defensa.

### Decisiones técnicas propuestas con asistencia de IA

- Claves foráneas compuestas para garantizar el contexto entre indicaciones y diagnósticos.
- Consumo de compatibilidad individual y disponibilidad del bloque de Paula.
- Índice único parcial para impedir reservas vigentes simultáneas del mismo animal.
- Reutilización del bloqueo asesor transaccional de Jason y aislamiento READ COMMITTED.
- Formalización y cierre de reserva, estancia e ingreso dentro de una transacción.
- Restricciones diferidas para comprobar la adopción al confirmar.
- Reingresos vinculados con la adopción del mismo animal.
- Restricciones de personas como decisiones independientes, sin generarlas automáticamente por devolución voluntaria.
- Conservación del historial de seguimientos y reprogramaciones.
- Restricción de escrituras directas del rol operativo.

Véanse [Modelo Relacional](modelo/Modelo_Relacional.md), [Matriz de Integridad](modelo/Matriz_Integridad.md) y [Control de Cambios](Control_de_Cambios.md).

### Validaciones realmente ejecutadas

Se utilizó PostgreSQL y psql 16.16 en Windows, bases nuevas UTF-8 y extensión `btree_gist`. Se verificaron instalación de 28 tablas, reserva válida, exclusividad, restricción vigente, formalización individual, repetición rechazada, contexto incompatible, exclusión de resultados, devolución voluntaria con nuevo ingreso y sin restricción automática, concurrencia con dos sesiones y observador, atomicidad ante estancia incorrecta, aplicaciones clínicas, corrección contextual A2, seguimientos y reprogramaciones, protección de resultados definitivos y rechazo de escritura directa no autorizada.

Se documentaron 33 casos identificados: 18 PJ, nueve PC, cinco PS y uno PP. Las evidencias son:

- [Ejecución de cobertura adicional](evidencias/Ejecucion_Jeank_Cobertura.md).
- [Resultados](evidencias/Resultados_Jeank.md).
- [Ejecución secuencial](evidencias/Ejecucion_Jeank_Secuencial.md).
- [Ejecución concurrente](evidencias/Ejecucion_Jeank_Concurrencia.md).
- [Instalación](evidencias/Ejecucion_Jeank_Instalacion.md).
- [Casos de prueba](pruebas/Casos_Jeank.md).

### Errores encontrados y corregidos

| Error observado | Corrección y validación |
|---|---|
| Permisos insuficientes en la comprobación diferida de adopción. | SECURITY DEFINER y search_path controlado en `_adopcion_diferida_jeank`; formalización verificada desde rol operativo en base nueva. |
| Referencia a `es.fecha_fin`. | Sustitución por `es.fecha_fin_real`; instalación posterior verificada. |
| Identificador fijo de adopción en prueba de devolución. | Localización por contexto real, sin depender de identificadores consumidos en intentos previos. |
| Consulta posterior al COMMIT sin search_path requerido. | Corrección del contexto de consulta y comprobación de datos persistidos. |
| Verificación concurrente antes de confirmar A. | Repetición después de COMMIT de A y ROLLBACK de B; una sola reserva vigente. |
| Diferencias de codificación en terminal. | Lectura explícita UTF-8 de documentos; no se confunde visualización con fallo de integridad. |

Los intentos fallidos no se presentan como ejecuciones satisfactorias.

### Participación humana y responsabilidad académica

Jean Carlos participó en la ejecución de comandos, creación y modificación de archivos, preparación de bases, ejecución de scripts, coordinación de sesiones concurrentes y comunicación de resultados. ChatGPT proporcionó propuestas de implementación, instrucciones, análisis de errores y asistencia documental. La validación de los escenarios específicos no sustituye la revisión humana ni la comprensión individual necesaria para la defensa.

### Estado de la integración y limitaciones

Se encuentran implementadas las 27 relaciones originales y la ampliación de compatibilidad animal–hogar, para un total de 28 tablas. Las dependencias principales se integraron y se verificaron formalización, cierre atómico, concurrencia, devolución voluntaria y corrección A2. Los pendientes de los apartados históricos corresponden a sus respectivas versiones, no al estado vigente.

Los 33 casos no constituyen una comprobación exhaustiva de todas las combinaciones de integridad. La matriz distingue mecanismos implementados de escenarios con evidencia específica.

Con asistencia de ChatGPT se diseñaron ocho pruebas adicionales, posteriormente ejecutadas por Jean Carlos mediante PostgreSQL y psql en una base independiente. Los resultados fueron contrastados con la salida real de ejecución.

Se verificaron la independencia entre aprobación y reserva, la finalización independiente de reservas, el límite temporal de restricciones, el contexto de reingresos, los traslados y la integridad histórica clínica.

No se atribuye una aprobación humana conjunta ni se inventan resultados, enlaces de video o minutajes de defensa.
