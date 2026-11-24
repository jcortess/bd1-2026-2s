# Uso de IA · Aporte de Jason

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
