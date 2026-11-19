# Uso de IA · Aporte de Jason

Se utilizó ChatGPT Codex, con herramientas locales de lectura, edición y terminal, para desarrollar esta primera versión del bloque. Codex contrastó la documentación de Proyecto 1 y Lab03, propuso los mecanismos de integridad, escribió los archivos SQL y Markdown y ejecutó las pruebas PostgreSQL. El anexo y la hoja del profesor sustentan las correcciones académicas. El Word sustenta el reparto de trabajo.

## Instrucciones relevantes del usuario

- «Desarrolles la parte que me corresponde a mí, Jason Madrigal Pineda. Debes trabajar directamente en los archivos del proyecto, con SQL ejecutable, documentación y pruebas.»
- «Conserva esa decisión mientras satisfaga las exigencias actuales. Impide que cambiar el oferente de una ubicación reinterprete las estancias históricas.»
- «Tratar cierre de estancia anterior y apertura de nueva como una sola operación atómica. Si falla el destino, la estancia anterior debe conservarse.»
- «Resuelve expresamente la dependencia circular entre INGRESO.adopcion_origen_id y ADOPCION, que corresponde a Giancarlo.»
- «No presentes llamadas secuenciales como prueba de concurrencia. Identifica preparación, intercalación, confirmaciones, rechazos o reintentos y estado final.»

## Decisiones y validación

Se mantuvo N-01 y se propusieron los actores de movimiento como vínculos independientes. Se eligieron intervalos semiabiertos, una primitiva privada para el cierre futuro y un bloqueo asesor transaccional en `READ COMMITTED`. La propuesta de diseño queda documentada para revisión y defensa por parte de Jason. Esta intervención no acredita una revisión manual por los tres integrantes. [Modelo](modelo/Modelo_Jason.md) · [Proceso y límites](Procesos_Negocio.md)

Se ejecutó la carga desde cero en PostgreSQL 16.15, se verificaron persistencia y rechazos y se observaron los bloqueos con sesiones simultáneas. Las comprobaciones explícitas delimitan lo que se verificó. La integración con las relaciones de Paula y Giancarlo permanece pendiente. [Evidencia](evidencias/Resultados_Jason.md)
