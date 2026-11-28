# Solicitud de desarrollo incorporada con asistencia de IA

Origen: archivo adjunto `Pasted text.txt`, sesión Codex de Paula, 24-11-2026. SHA-256 del original: `4b65c1196d3adde3b8aebffc1fa336ded2d04e30f8d53650b18901dab3b21856`. Se conserva el texto del usuario como registro de alcance, no como evidencia de revisión humana ni como garantía de que todo el equipo ya esté completo.

---

Actúa como un desarrollador especializado en PostgreSQL, diseño de bases de datos relacionales, PL/pgSQL, integridad de datos, transacciones, concurrencia y documentación técnica.

Tu objetivo es desarrollar completamente la parte que me corresponde del proyecto final del curso IC-4301 Bases de Datos I, denominado **Refugio Huellas Seguras — Grupo 05**.

Soy **María Paula Romero Garro (Paula)** y mis compañeros de equipo son Jason Madrigal Pineda y Jean Carlos Segura Vargas.

No necesito que me enseñes a desarrollar el proyecto ni que me expliques cada proceso mientras trabajas. Necesito que analices los materiales, tomes las decisiones técnicas justificadas que correspondan, implementes la solución directamente en los archivos del repositorio, ejecutes las pruebas, corrijas los errores y completes la documentación correspondiente a mi asignación.

No quiero recibir únicamente propuestas, ejemplos de código, recomendaciones, instrucciones para implementar posteriormente o una planificación. Quiero que realices efectivamente el trabajo.

## 1. Repositorio y rama de trabajo

Repositorio de GitHub:

https://github.com/jcortess/bd1-2026-2s

Rama de trabajo obligatoria:

`grupo-05`

Carpeta principal del proyecto final:

`final-project/grupo-05/`

Carpeta correspondiente al Laboratorio 3:

`lab03/grupo-05/`

Antes de modificar cualquier archivo:

- Identifica el repositorio local y sus remotos.
- Verifica el estado actual mediante Git.
- Comprueba que estás trabajando sobre la rama `grupo-05`.
- Si estás en otra rama, cambia a `grupo-05` de manera segura, sin perder modificaciones existentes.
- Revisa los cambios actuales, tanto los confirmados como los pendientes.
- Identifica el trabajo que ya realizaron mis compañeros.
- Verifica si existen diferencias relevantes entre la rama local y la remota.
- Conserva cualquier modificación previa que no corresponda a tu trabajo.

Está estrictamente prohibido modificar la rama `main`, realizar cambios destructivos en Git, eliminar trabajo de otros integrantes o sobrescribir modificaciones existentes sin justificación.

Utiliza los archivos de `lab03/grupo-05/` como antecedentes y fuentes de reutilización. No modifiques esa carpeta.

Todos los archivos nuevos y modificaciones de la implementación deben quedar dentro de `final-project/grupo-05/`.

No realices push, merge ni crees el pull request sin mi autorización expresa.

## 2. Lectura obligatoria de los materiales

Antes de comenzar la implementación, lee, analiza y comprende completamente los siguientes materiales.

### A. Proyecto final

Inspecciona recursivamente todos los archivos existentes dentro de:

`final-project/grupo-05/`

Revisa los archivos SQL, Markdown, diagramas, datos de prueba, documentación, funciones, procedimientos, restricciones y cualquier otro componente existente.

Además, lee los archivos oficiales:

- `final-project/README.md`
- `final-project/Control_de_Cambios_Especificacion.md`
- `final-project/grupo-05/05_Grupo_05_Refugio.md`

Referencias oficiales:

https://github.com/jcortess/bd1-2026-2s/blob/main/final-project/README.md

https://github.com/jcortess/bd1-2026-2s/blob/main/final-project/Control_de_Cambios_Especificacion.md

https://github.com/jcortess/bd1-2026-2s/blob/main/final-project/grupo-05/05_Grupo_05_Refugio.md

Consulta las instrucciones vigentes del profesor, incluyendo cualquier modificación posterior que resulte aplicable.

### B. Laboratorio 3

Lee y comprende todos los archivos de:

`lab03/grupo-05/`

Esto incluye:

- Enunciado e instrucciones del laboratorio.
- Implementación realizada por el grupo.
- Modelo utilizado.
- Scripts SQL.
- Funciones y procedimientos.
- Restricciones y validaciones.
- Datos de prueba.
- Consultas.
- Evidencias.
- Documentación.
- Correcciones, observaciones y retroalimentación del profesor.
- Historial relevante de modificaciones, cuando esté disponible.

Determina qué componentes pueden reutilizarse directamente, cuáles necesitan adaptaciones y cuáles deben corregirse.

No reescribas componentes que ya funcionan correctamente únicamente para generar código nuevo.

### C. Documentos adjuntos

Lee completamente los siguientes documentos que proporcionaré junto con este prompt:

1. `Distribucion Proyecto Final(1).docx`: contiene la distribución de responsabilidades entre los integrantes.
2. `Hoja_Calificacion_Proyecto_ROMERO GARRO MARIA PAULA.xlsx`: contiene las observaciones y correcciones realizadas por el profesor en el Proyecto 1.
3. `Huellas_Seguras(1).pdf`: contiene el desarrollo completo del Proyecto 1, incluyendo análisis del caso, reglas de negocio, modelo conceptual, modelo relacional, normalización, diccionario y trazabilidad.
4. `README.md`: contiene las instrucciones generales de la entrega final.
5. `Control_de_Cambios_Especificacion.md`: contiene las instrucciones oficiales para documentar cambios y reutilizaciones.

Si existen otros archivos de correcciones del profesor relacionados con el Proyecto 1 o Lab03, también debes analizarlos.

No te limites a leer los nombres de los archivos, introducciones o primeras páginas. Examina las tablas, diagramas, reglas, atributos, identificadores, observaciones y demás contenido relevante.

Si algún documento no puede abrirse o no se encuentra disponible, identifica claramente cuál es y continúa con las tareas que puedan resolverse utilizando las fuentes disponibles. No inventes su contenido.

## 3. Conciliación de las entregas anteriores

Antes de diseñar nuevas estructuras, realiza una conciliación técnica entre:

**Proyecto 1 → Correcciones del profesor → Lab03 → Correcciones de Lab03 → Proyecto final.**

Identifica internamente:

- El modelo relacional normalizado del Proyecto 1.
- Las 27 relaciones originales del proyecto.
- Las reglas de negocio aplicables.
- Las ambigüedades y supuestos adoptados.
- Las inconsistencias entre modelo conceptual, relacional y diccionario.
- Las correcciones solicitadas por el profesor.
- Los componentes implementados y validados en Lab03.
- Las diferencias entre Lab03 y el modelo completo.
- Los componentes que ya existen en el proyecto final.
- Las dependencias entre mi trabajo y el de mis compañeros.
- Los requisitos específicos de aceptación del anexo del Grupo 05.

No asumas que Lab03 sustituye el modelo relacional completo del Proyecto 1.

Si existen contradicciones entre los documentos, conserva la fidelidad al caso, a las instrucciones oficiales vigentes y a las reglas explícitas del negocio. Documenta las discrepancias y justifica la decisión adoptada.

Distingue claramente entre requisitos obligatorios, observaciones formativas, recomendaciones opcionales, supuestos y decisiones propias de diseño.

Esta conciliación debe servir como base para desarrollar el proyecto, no como sustituto de la implementación.

## 4. Mi responsabilidad dentro del proyecto

Desarrolla exclusivamente las responsabilidades asignadas a Paula en el documento de distribución.

Mi proceso principal es:

**G05-P02 — Solicitudes y compatibilidad.**

También soy responsable de implementar las siguientes nueve relaciones:

1. `REPORTE`
2. `REPORTE_ANIMAL`
3. `EVALUACION_SALUD`
4. `DIAGNOSTICO`
5. `DIAGNOSTICO_REVISION`
6. `CAMBIO_DISPONIBILIDAD`
7. `SOLICITUD_ADOPCION`
8. `SOLICITUD_ANIMAL`
9. `EVENTO_SOLICITUD`

Mis responsabilidades complementarias incluyen:

- Reportes de animales.
- Evaluaciones de salud.
- Revisiones veterinarias y diagnósticos.
- Cambios de disponibilidad para adopción.
- Consolidación del modelo relacional actualizado.
- Consolidación del diccionario de datos.
- Actualización del diagrama del modelo.
- Consolidación de la matriz relación/regla–mecanismo–prueba.
- Revisión de la cobertura de pruebas.
- Consolidación del archivo `Uso_de_IA.md`.
- Documentación y evidencias de mis cambios.
- Preparación de los aportes correspondientes a mi parte de la defensa.

Aunque debo consolidar determinados documentos generales, no debes implementar los procesos funcionales asignados a mis compañeros.

## 5. Correcciones obligatorias del Proyecto 1

Presta especial atención a las observaciones del profesor contenidas en la hoja de calificación.

### 5.1. Compatibilidad animal–hogar

El profesor identificó que el modelo original permite registrar los animales de interés de una solicitud, pero no representa explícitamente la evaluación de compatibilidad entre un animal concreto y el hogar interesado.

Debes corregir esta deficiencia.

Diferencia correctamente:

- El interés de una persona por un animal.
- Las actividades de evaluación de una solicitud.
- El resultado de entrevistas o visitas.
- La decisión general de la solicitud.
- La evaluación de compatibilidad individual animal–hogar.
- La reserva de un animal.
- La formalización de una adopción.

Analiza si corresponde incorporar una relación adicional, ampliar las relaciones existentes o utilizar otra estructura relacional que represente correctamente estos hechos.

La solución debe permitir conservar el resultado de la evaluación, su contexto y el historial correspondiente, según las reglas aplicables.

Una solicitud aprobada no significa que todos sus animales sean compatibles ni que queden reservados automáticamente.

Esta corrección debe reflejarse en el modelo, SQL, diccionario, diagramas, matriz de integridad, pruebas y control de cambios.

### 5.2. Identificación de DIAGNOSTICO_REVISION

El profesor identificó una inconsistencia entre el identificador utilizado en el modelo conceptual y la clave compuesta utilizada en el modelo relacional.

En el Proyecto 1 aparecen las alternativas:

- `id_diagnostico_revision`
- Clave compuesta `(evaluacion_id, diagnostico_id)`.

Analiza ambas alternativas, las dependencias y la implementación existente en Lab03.

Selecciona o conserva la alternativa que resulte coherente con el modelo completo, justificando la transformación y evitando contradicciones entre los documentos y el esquema físico.

Comprueba especialmente las dependencias con las relaciones clínicas asignadas a Jean Carlos.

### 5.3. Obligatoriedad de información clínica

Revisa las restricciones de obligatoriedad de `EVALUACION_SALUD` y las demás relaciones clínicas de mi responsabilidad.

Distingue entre:

- Evaluación inicial.
- Revisión veterinaria.
- Información desconocida.
- Información opcional.
- Información obligatoria según el tipo de evaluación o evento.

No permitas que una revisión veterinaria efectuada quede registrada sin los datos exigidos por las reglas del negocio.

Valida que los profesionales responsables, fechas, motivos, observaciones, peso, recomendaciones y diagnósticos se representen conforme al caso, las correcciones del profesor y las decisiones justificadas del modelo.

### 5.4. EVENTO_SOLICITUD

El profesor indicó que el atributo `resultado_estado` puede generar confusión entre el resultado de una actividad y el estado general de la solicitud.

Corrige esta inconsistencia.

Diferencia los resultados de entrevistas, visitas y demás actividades de evaluación de las decisiones que modifican el estado de una solicitud.

Conserva el historial de eventos, fechas, responsables, observaciones y razones.

No sobrescribas decisiones anteriores de forma que se pierda su trazabilidad.

### 5.5. Diccionario y trazabilidad

Revisa las observaciones relacionadas con:

- Referencias C01–C09 que no aparecen desarrolladas.
- Referencias a una sección 9 inexistente.
- Dominios categóricos sin definir.
- Confusión entre valores de ejemplo y restricciones reales.
- Obligatoriedad de atributos insuficientemente especificada.
- Asociación incorrecta de `PERSONA.id_persona` con RN-01.
- Correspondencia insuficiente entre los supuestos S-01 a S-16 y las reglas de negocio.
- Cobertura incompleta de RN-19.
- Clasificación incorrecta de la ausencia del receptor de una devolución en RN-23.
- Afirmaciones de coherencia entre artefactos que no están respaldadas por pruebas.

Corrige los aspectos de mi responsabilidad y los errores documentales que me corresponde consolidar.

No inventes el contenido de los hallazgos C01–C09. Recupera su contenido original si existe; en caso contrario, elimina o corrige las referencias inválidas de manera justificada.

### 5.6. Correcciones correspondientes a otros integrantes

El profesor también identificó aspectos como:

- Ausencia de una referencia que identifique quién recibió un animal devuelto.
- Necesidad de garantizar que `ADOPCION.animal_codigo` e `ingreso_id` correspondan al mismo animal.

Aunque debes considerar estas correcciones para comprender el modelo completo y consolidar la documentación, no debes asumir la implementación de las relaciones asignadas a Jason o Jean Carlos.

Identifica las dependencias, revisa si ya están resueltas y documenta cualquier ajuste pendiente que corresponda a mis compañeros.

## 6. Implementación del proceso G05-P02

Desarrolla completamente el proceso de solicitudes y compatibilidad de acuerdo con el anexo oficial del Grupo 05.

Lee primero todos sus criterios de aceptación. Las indicaciones de este prompt no sustituyen los requisitos oficiales del anexo.

La implementación debe permitir, como mínimo:

### 6.1. Registro de solicitudes

- Crear solicitudes de adopción sin animales específicos.
- Crear solicitudes asociadas con uno o varios animales.
- Asociar animales posteriormente a una solicitud general, cuando corresponda.
- Registrar la información exigida sobre la vivienda, integrantes del hogar, experiencia con animales y condiciones de cuidado.
- Mantener la relación correcta entre el solicitante, su hogar y los animales de interés.
- Evitar asociaciones duplicadas o inválidas.

### 6.2. Actividades de evaluación

Implementa el registro de las actividades requeridas por el caso, incluyendo entrevistas, visitas al hogar y otras actividades contempladas en las fuentes oficiales.

Cada actividad debe conservar:

- Fecha.
- Responsable.
- Tipo de actividad.
- Resultado.
- Observaciones.
- Referencia a la solicitud correspondiente.

Garantiza que los actores, referencias y datos sean válidos.

### 6.3. Decisiones e historial

Implementa las operaciones necesarias para gestionar los estados de una solicitud, considerando los estados definidos en el caso:

- Recibida.
- En evaluación.
- Pendiente de información.
- Aprobada.
- Rechazada.
- Cancelada.
- Vencida.

Determina las transiciones permitidas a partir de las fuentes oficiales.

Conserva las decisiones anteriores, sus fechas, responsables y razones.

No inventes restricciones de transición, plazos, cantidades mínimas de actividades o políticas de aprobación que no estén respaldadas por las fuentes. Cuando una interpretación sea necesaria, documéntala.

Permite que una persona presente una nueva solicitud después de que una anterior haya sido rechazada, conservando el historial de ambas.

### 6.4. Compatibilidad individual

Implementa la evaluación de compatibilidad entre un animal concreto y el hogar asociado con una solicitud.

Debe ser posible que una misma solicitud contenga varios animales con diferentes resultados de compatibilidad.

Comprueba que:

- La evaluación corresponda a la solicitud y al animal correctos.
- No se confunda el interés con una evaluación favorable.
- Se conserven los resultados y decisiones pertinentes.
- No se acepten referencias o contextos incorrectos.
- Las decisiones respeten las precondiciones establecidas en el anexo.
- La aprobación general no produzca reservas automáticamente.

La estructura y las consultas desarrolladas deben poder ser utilizadas posteriormente por el proceso G05-P03 de Jean Carlos, sin duplicar información ni generar inconsistencias.

### 6.5. Consultas de comprobación

Implementa las consultas necesarias para verificar:

- Solicitudes registradas.
- Animales asociados con una solicitud.
- Solicitudes generales sin animales.
- Estado vigente de una solicitud.
- Historial cronológico de actividades y decisiones.
- Resultados individuales de compatibilidad.
- Solicitudes rechazadas y posteriores.
- Contexto de las evaluaciones.
- Ausencia de reservas automáticas.
- Cualquier otro resultado requerido por el anexo oficial.

No utilices únicamente mensajes de éxito para demostrar el funcionamiento. Comprueba directamente los valores y relaciones persistidos en la base de datos.

## 7. Implementación de las nueve relaciones asignadas

Desarrolla, corrige o completa físicamente en PostgreSQL las nueve relaciones de mi responsabilidad.

Para cada relación, analiza:

- Atributos.
- Tipos de datos.
- Clave primaria.
- Claves alternativas.
- Claves foráneas.
- Claves compuestas.
- Nulabilidad.
- Restricciones de dominio.
- Restricciones de contexto.
- Integridad referencial.
- Comportamiento ante modificaciones y eliminaciones.
- Dependencias con otras relaciones.
- Reglas de negocio.
- Necesidad de índices.
- Conservación del historial.
- Correspondencia con el modelo original y normalizado.

Utiliza restricciones declarativas cuando sean suficientes y funciones, procedimientos, triggers u otros mecanismos PostgreSQL cuando las reglas realmente lo necesiten.

No incorpores mecanismos innecesarios únicamente para aumentar la cantidad de componentes técnicos.

No elimines ninguna de las 27 relaciones originales para simplificar la implementación.

Si debes transformar o ampliar una relación, conserva la cobertura de todos los hechos originales y documenta su correspondencia.

Para las relaciones que no forman parte directamente de G05-P02, implementa su estructura física, datos ficticios y pruebas de integridad aplicables.

No desarrolles un cuarto proceso funcional de atención médica, ya que no forma parte de los procesos asignados al grupo.

## 8. Reutilización del Laboratorio 3

Reutiliza los componentes válidos del Laboratorio 3 que correspondan a mi bloque, especialmente los relacionados con evaluaciones de salud, revisiones y diagnósticos.

Para cada componente relevante:

- Identifica su archivo y versión de origen.
- Comprueba si continúa siendo compatible con el modelo completo.
- Determina si necesita modificaciones.
- Adapta las referencias y dependencias cuando corresponda.
- Ejecuta nuevamente sus pruebas.
- Comprueba su funcionamiento en la implementación actual.
- Documenta su reutilización o modificación.

Si encuentras correcciones pendientes del profesor en Lab03 que afecten mi bloque, resuélvelas.

No presentes las pruebas históricas de Lab03 como si fueran evidencia de la versión actual.

## 9. Transacciones, atomicidad y concurrencia

Las operaciones de G05-P02 deben cumplir los requisitos de integridad transaccional establecidos en el README oficial.

Implementa los mecanismos necesarios para garantizar que una operación compuesta no deje cambios parciales.

Considera especialmente:

- Actualización del estado de una solicitud.
- Registro de decisiones y su historial.
- Evaluaciones de compatibilidad.
- Operaciones que afecten simultáneamente varias relaciones.
- Dos sesiones intentando modificar una misma solicitud.
- Conflictos entre decisiones concurrentes.
- Reintentos que puedan duplicar efectos.

Selecciona el mecanismo de control de concurrencia apropiado según las necesidades reales del proceso.

Diferencia un rechazo válido del negocio, que puede requerir conservar su resultado y razón, de un error técnico que debe abortar la operación.

Las rutas de escritura permitidas no deben permitir eludir las garantías de integridad.

Los errores deben ser reconocibles y permitir identificar su causa real.

## 10. Pruebas obligatorias

No consideres terminada una implementación hasta haber realizado y comprobado sus pruebas.

Desarrolla archivos SQL ejecutables y documentación Markdown para las pruebas.

### 10.1. Pruebas del proceso G05-P02

Incluye todos los criterios de aceptación definidos en el anexo y, como mínimo, los siguientes escenarios:

- Solicitud general sin animales.
- Solicitud con varios animales.
- Dos animales con resultados de compatibilidad diferentes.
- Asociación posterior de animales, cuando corresponda.
- Registro de actividades de evaluación.
- Registro de decisiones válidas.
- Conservación del historial.
- Nueva solicitud después de un rechazo.
- Rechazo de una operación sin decisión válida cuando sea exigida.
- Referencias inexistentes.
- Asociaciones de contextos incorrectos.
- Operaciones duplicadas o incompatibles.
- Aprobación sin generación automática de reservas.
- Casos de frontera pertinentes.
- Fallo intermedio que permita demostrar atomicidad.
- Dos sesiones concurrentes compitiendo por actualizar una misma solicitud.

### 10.2. Pruebas de integridad de las relaciones

Para mis nueve relaciones y cualquier ampliación necesaria, comprueba todas las categorías aplicables:

- Identidad.
- Referencias.
- Dominios.
- Obligatoriedad.
- Contexto.
- Reglas entre filas o relaciones.
- Modificación.
- Eliminación.
- Conservación de historia.

No es obligatorio generar una cantidad fija de pruebas por tabla. Una prueba puede cubrir varias reglas y relaciones, siempre que su cobertura sea identificable.

Cuando una categoría no aplique, justifícalo.

### 10.3. Evidencia de cada prueba

Cada prueba debe identificar:

- Código de prueba.
- Regla o proceso evaluado.
- Relaciones involucradas.
- Estado inicial.
- Datos y preparación.
- Acción ejecutada.
- Resultado esperado, definido antes de ejecutar.
- Resultado realmente observado.
- Consultas de comprobación.
- Estado final.
- Conclusión.
- Referencia al archivo SQL ejecutable.

Los casos negativos deben demostrar que la operación falla por la razón esperada, no por un error accidental diferente.

Comprueba los datos persistidos después del `COMMIT` cuando corresponda.

No utilices resultados esperados como resultados observados.

### 10.4. Pruebas concurrentes

Prepara y ejecuta pruebas mediante dos sesiones reales de PostgreSQL.

Incluye los guiones SQL correspondientes a cada sesión y documenta:

- Estado inicial.
- Orden de ejecución.
- Intercalación de operaciones.
- Bloqueos, esperas o rechazos observados.
- Confirmaciones.
- Reversiones.
- Estado final.
- Comportamiento esperado ante un reintento.

No simules concurrencia mediante dos llamadas secuenciales.

### 10.5. Entorno de pruebas

Utiliza exclusivamente una base de datos nueva destinada a las pruebas del proyecto.

No elimines bases de datos preexistentes ni utilices información personal real.

Registra la versión de PostgreSQL realmente utilizada.

Si el entorno no permite ejecutar PostgreSQL o abrir sesiones concurrentes, deja preparados los guiones reproducibles, pero identifica las pruebas como pendientes de ejecución. No inventes evidencias ni afirmes que una prueba pasó cuando no pudo ejecutarse.

## 11. Documentación del modelo relacional

Según la distribución del proyecto, soy responsable de consolidar la documentación del modelo.

Revisa la estructura documental existente antes de crear archivos nuevos.

Completa o actualiza la documentación dentro de `modelo/` o su estructura equivalente.

Debe incluir:

- Modelo relacional consolidado.
- Correspondencia de las 27 relaciones originales con el modelo físico actual.
- Nuevas relaciones incorporadas justificadamente.
- Atributos.
- Claves primarias.
- Claves alternativas.
- Claves foráneas.
- Cardinalidades.
- Restricciones.
- Dependencias.
- Decisiones de diseño.
- Ambigüedades y supuestos.
- Transformaciones realizadas.
- Correspondencia entre Proyecto 1, Lab03 y la entrega final.

Comprueba que el modelo relacional, el diccionario, los diagramas y los scripts SQL representen las mismas estructuras.

Consolida los aportes existentes de Jason y Jean Carlos sin inventar implementaciones que todavía no hayan realizado.

Si alguna parte de sus bloques está pendiente, identifica expresamente su estado.

## 12. Diccionario de datos

Completa y actualiza el diccionario de datos del proyecto según las instrucciones oficiales.

Para cada atributo, documenta los aspectos aplicables:

- Relación.
- Nombre del atributo.
- Descripción.
- Tipo de dato PostgreSQL.
- Dominio.
- Obligatoriedad.
- Valor por defecto, cuando corresponda.
- Clave primaria.
- Clave foránea.
- Claves alternativas.
- Restricciones.
- Referencias.
- Reglas de negocio relacionadas.
- Condiciones especiales de integridad.

Diferencia claramente la información opcional de aquella cuya obligatoriedad depende del tipo de operación.

El diccionario debe corresponder exactamente a la implementación física disponible.

No conserves atributos eliminados o modificados sin documentar la transformación correspondiente.

## 13. Diagramación del modelo

Actualiza el diagrama relacional para que represente el modelo consolidado.

Utiliza Mermaid dentro de Markdown o imágenes SVG/PNG cuando sean necesarias, respetando los formatos permitidos por el profesor.

El diagrama debe mostrar correctamente:

- Relaciones.
- Identificadores.
- Claves.
- Referencias.
- Cardinalidades.
- Asociaciones.
- Nuevas estructuras de compatibilidad.
- Dependencias clínicas.
- Dependencias con los demás procesos.

No generes diagramas que contradigan el esquema SQL.

Respeta la organización actual si ya existe un mecanismo adecuado de diagramación.

## 14. Matriz de integridad y trazabilidad

Consolida la matriz relación/regla–mecanismo–prueba exigida por el profesor.

Incluye, como mínimo, la información necesaria para identificar:

| Campo | Contenido |
|---|---|
| Relación | Nombre de la relación original o actual |
| Regla de negocio | Identificador y fuente |
| Representación física | Tabla, atributo o estructura que representa la regla |
| Mecanismo de integridad | Restricción, FK, CHECK, función, procedimiento, trigger u otro |
| Categoría de integridad | Identidad, referencia, dominio, contexto u otra |
| Prueba | Identificador de la prueba correspondiente |
| Evidencia | Archivo o sección que contiene el resultado |
| Estado | Verificada, pendiente o no aplica, según corresponda |

La matriz debe permitir localizar cada regla y comprobar cómo se implementa y verifica.

Asegura la cobertura completa de mi bloque.

Para las relaciones de los otros integrantes, consolida únicamente los mecanismos y pruebas que puedan comprobarse a partir de sus aportes reales.

No marques una relación como verificada si no existe evidencia suficiente.

Identifica las pruebas pendientes y su responsable.

## 15. Control de cambios

Aunque Jean Carlos es el responsable de consolidar `Control_de_Cambios.md`, debes preparar y registrar los cambios correspondientes a mi implementación.

Sigue exactamente las instrucciones de:

`Control_de_Cambios_Especificacion.md`

Cada registro de cambio debe contener:

- Identificador único.
- Fuente u origen.
- Elemento afectado.
- Situación anterior en Proyecto 1.
- Situación correspondiente en Lab03.
- Modificación realizada.
- Justificación.
- Reglas relacionadas.
- Impacto sobre el modelo y las operaciones.
- Archivos modificados.
- Evidencias de validación.

Documenta especialmente las correcciones solicitadas por el profesor.

Incluye también los componentes reutilizados sin modificaciones, diferenciándolos de aquellos que sí fueron adaptados.

No inventes una evolución de un componente que no existía en una entrega anterior.

Si el archivo general ya contiene aportes de mis compañeros, conserva su contenido y añade únicamente los registros que me correspondan, siguiendo la estructura existente.

## 16. Uso de inteligencia artificial

Soy responsable de consolidar `Uso_de_IA.md`.

Crea o actualiza este archivo respetando los requisitos del profesor.

Documenta de manera transparente:

- Herramientas de IA utilizadas.
- Propósito de su utilización.
- Prompts relevantes.
- Aportes incorporados.
- Archivos o componentes desarrollados con asistencia de IA.
- Decisiones técnicas adoptadas.
- Validaciones ejecutadas.
- Errores encontrados y corregidos.
- Limitaciones identificadas.
- Pruebas y resultados realmente comprobados.

Incluye el prompt de desarrollo actual o su referencia identificable.

Conserva los registros previos de mis compañeros.

No inventes herramientas, conversaciones, prompts, decisiones humanas ni validaciones realizadas por ellos.

Si sus aportes todavía no están disponibles, identifica esa información como pendiente de incorporación.

Distingue las decisiones propuestas por Codex de las decisiones que realmente hayan sido revisadas o aprobadas por los integrantes.

## 17. Integración con el trabajo de mis compañeros

Respeta la distribución establecida en el documento.

### Jason — G05-P01

Responsable del proceso de ubicación, capacidad y traslados.

Sus relaciones asignadas son:

- `PERSONA`
- `MEDIO_CONTACTO`
- `PARTICIPACION`
- `ANIMAL`
- `INGRESO`
- `ORGANIZACION_EXTERNA`
- `UBICACION`
- `UBICACION_ESPECIE_ACEPTADA`
- `ESTANCIA`

También es responsable de consolidar la instalación y el README.

### Jean Carlos — G05-P03

Responsable del proceso de reserva y formalización de adopciones.

Sus relaciones asignadas son:

- `INDICACION`
- `INDICACION_DIAGNOSTICO`
- `APLICACION_INDICACION`
- `RESERVA`
- `ADOPCION`
- `ADOPCION_RESPONSABLE`
- `SEGUIMIENTO_ADOPCION`
- `RESTRICCION_PERSONA`
- `RESULTADO_ETAPA`

También es responsable de consolidar el control de cambios y la defensa.

### Reglas de integración

- No dupliques tablas que ya existen.
- No redefinas las estructuras de otros integrantes de forma unilateral.
- No cambies nombres de atributos compartidos sin analizar sus dependencias.
- No elimines funciones, pruebas o documentación ajena.
- Respeta las convenciones de nomenclatura del proyecto.
- Utiliza las claves y referencias existentes cuando sean correctas.
- Identifica posibles conflictos de integración.
- Documenta los cambios compartidos que necesiten aprobación.
- Mantén las interfaces de datos necesarias para conectar los tres procesos.

La compatibilidad animal–hogar debe poder ser consumida por G05-P03 de manera coherente.

Las evaluaciones y diagnósticos deben integrarse correctamente con las indicaciones clínicas.

Las solicitudes, reportes y evaluaciones deben utilizar las referencias de personas, animales e ingresos correspondientes al modelo común.

Si alguna dependencia aún no está implementada, prepara datos ficticios o estructuras auxiliares exclusivamente de prueba cuando las instrucciones oficiales lo permitan.

No presentes esas estructuras auxiliares como parte terminada del trabajo de otro integrante.

## 18. Organización de archivos

Respeta la estructura existente del repositorio.

La organización general exigida por el profesor contempla:

- `README.md`
- `modelo/`
- `sql/`
- `pruebas/`
- `evidencias/`
- `diagramas/`, cuando corresponda.
- `Control_de_Cambios.md`
- `Uso_de_IA.md`
- `Defensa.md`
- Documentación de procesos.

No crees archivos redundantes si ya existen documentos equivalentes.

Toda la documentación escrita de la entrega final debe estar exclusivamente en Markdown (`.md`).

Toda la implementación ejecutable debe estar en archivos `.sql` independientes.

Los bloques SQL incluidos en Markdown no sustituyen los scripts ejecutables.

No generes documentos Word, Excel o PDF como entregables de esta segunda entrega.

No desarrolles frontend, backend, API REST, aplicaciones externas ni utilices otro motor de bases de datos.

Mantén el proyecto exclusivamente dentro del alcance académico establecido.

## 19. Documentación del proceso y aportes a la defensa

Documenta las operaciones públicas de G05-P02, incluyendo:

- Propósito.
- Parámetros.
- Precondiciones.
- Datos modificados.
- Resultados.
- Rechazos posibles.
- Alcance transaccional.
- Mecanismos de integridad.
- Control de concurrencia.
- Forma de ejecución.
- Consultas de comprobación.
- Referencias a pruebas.

Prepara los aportes técnicos correspondientes a mi participación en la defensa, utilizando la estructura existente de `Defensa.md` o dejando identificada la información que Jean Carlos debe consolidar.

Incluye las operaciones y comandos reproducibles que permitan demostrar mi trabajo, una decisión de diseño relevante, un caso válido, un rechazo y el comportamiento concurrente correspondiente.

No inventes enlaces de videos, grabaciones o participaciones que todavía no se hayan realizado.

## 20. Metodología de ejecución autónoma

Trabaja de manera autónoma y continua.

Realiza internamente las siguientes etapas:

1. Verificación del repositorio y rama.
2. Lectura completa de archivos y documentos.
3. Identificación del estado actual del proyecto.
4. Conciliación del Proyecto 1 y Lab03.
5. Análisis de las correcciones del profesor.
6. Identificación de mis responsabilidades y dependencias.
7. Diseño o ajuste de las relaciones asignadas.
8. Implementación SQL.
9. Implementación de G05-P02.
10. Reutilización y adaptación de Lab03.
11. Desarrollo de datos ficticios.
12. Implementación de las pruebas.
13. Ejecución de pruebas.
14. Corrección de errores.
15. Consolidación de documentación.
16. Verificación de consistencia.
17. Revisión de los cambios mediante Git.
18. Comprobación final del cumplimiento.

No necesito que me expliques cada una de estas etapas mientras las realizas.

No te detengas después de presentar un plan.

No solicites mi autorización para cada modificación ordinaria dentro de mi bloque.

Si encuentras una decisión compartida que requiere aprobación del equipo, documenta el asunto, evita modificar unilateralmente el trabajo ajeno y continúa con las tareas independientes que sí puedas completar.

No reduzcas el alcance por conveniencia ni dejes funciones incompletas, pseudocódigo o marcadores TODO en tareas que puedas resolver.

Corrige los errores detectados durante las pruebas y vuelve a ejecutar las validaciones necesarias.

## 21. Criterios para considerar terminado el trabajo

Antes de finalizar, comprueba que:

- Estás trabajando exclusivamente en la rama `grupo-05`.
- Las modificaciones pertenecen a `final-project/grupo-05/`.
- Mis nueve relaciones están implementadas.
- Se han aplicado las correcciones del profesor correspondientes a mi bloque.
- Se ha corregido la ausencia de compatibilidad animal–hogar.
- G05-P02 está completamente implementado.
- Se cumplen los criterios de aceptación del anexo.
- Se conserva el historial de solicitudes y decisiones.
- El interés, la aprobación, la compatibilidad y la reserva son conceptos diferenciados.
- Se han reutilizado y revalidado los componentes pertinentes de Lab03.
- Existen pruebas válidas, inválidas, de frontera y concurrentes.
- Se ha comprobado la atomicidad de las operaciones aplicables.
- Las evidencias corresponden a ejecuciones reales.
- El modelo y diccionario coinciden con el SQL.
- La matriz permite localizar mecanismos y pruebas.
- El diagrama corresponde al modelo actualizado.
- Mis cambios están documentados.
- `Uso_de_IA.md` está actualizado con información verificable.
- Los aportes disponibles de mis compañeros se han consolidado correctamente.
- No se ha modificado ni eliminado trabajo ajeno.
- No existen errores conocidos de ejecución sin identificar.
- Los archivos cumplen los formatos establecidos por el profesor.
- El trabajo puede reproducirse desde una base de datos nueva una vez que las dependencias del equipo estén disponibles.

No declares terminado un requisito que todavía dependa de una implementación pendiente de otro integrante o de una prueba que no se haya ejecutado.

## 22. Informe final

Una vez que hayas realizado el trabajo, proporciona únicamente un informe final conciso que contenga:

1. Estado general de mi implementación.
2. Archivos creados.
3. Archivos modificados.
4. Relaciones implementadas o corregidas.
5. Operaciones de G05-P02 implementadas.
6. Correcciones del profesor resueltas.
7. Componentes reutilizados de Lab03.
8. Pruebas ejecutadas y sus resultados.
9. Documentación completada.
10. Dependencias o asuntos pendientes de otros integrantes.
11. Pruebas que no pudieron ejecutarse y su motivo.
12. Estado final de Git.
13. Comandos necesarios para reproducir las pruebas de mi bloque.

No necesito una explicación extensa del desarrollo, ni una clase sobre PostgreSQL, ni que me muestres todo el código en el chat.

El resultado principal debe estar implementado directamente en los archivos del repositorio.

**Comienza ahora. Lee todos los materiales disponibles y desarrolla en su totalidad la parte asignada a Paula, respetando las instrucciones oficiales, las correcciones del profesor, la distribución del equipo y la rama de trabajo `grupo-05`.**