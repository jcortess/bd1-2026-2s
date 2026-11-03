# IC-4301 Bases de Datos I — Proyecto, entrega final

## 1. Propósito y resultados de aprendizaje

La segunda entrega transforma el diseño del Proyecto 1 en una base de datos PostgreSQL completa y verificable. Deben demostrar que pueden convertir relaciones y reglas del negocio en estructuras físicas coherentes, implementar decisiones y cambios de estado, preservar historia, explicar rechazos y probar que varias operaciones no dejan datos incompatibles.

El trabajo se ejecuta directamente en PostgreSQL. **La unidad de evaluación funcional es el proceso del anexo de su grupo**, no la cantidad de rutinas escritas. Cada anexo delimita las operaciones incluidas y las dependencias que pueden prepararse como datos de prueba.

## 2. Dos dimensiones obligatorias del alcance

### 2.1 Modelo físico completo

Implementen el **100 % de las relaciones de su modelo relacional final**, con las correcciones justificadas del Proyecto 1 y Lab03. El resultado de normalización, el diccionario, las referencias y las reglas deben corresponder al mismo modelo.

El diseño previo es el punto de partida. Si está incompleto, contradictorio o no representa una situación asignada, deben corregirlo o ampliarlo y documentar la decisión. Conserven la cobertura de todos los hechos y relaciones originales; no reduzcan el modelo, eliminen historia o excluyan reglas para ajustar el trabajo a lo ya hecho en Lab03. Una transformación física justificada debe permitir rastrear cada relación y su información; no basta presentar menos tablas sin explicar esa correspondencia.

Evidentemente no les voy a correjir los esquemas, eso es parte de este entregable. Ustedes seleccionan tipos adecuados, identificadores, referencias, dominios, nulabilidad y mecanismos de integridad. Una fecha debe representar un día válido; una cantidad debe tener unidad y significado; una referencia debe conservar la identidad completa y el contexto exigido por la regla. Un identificador de un objeto interno del modelo completo no puede justificarse ahora como «referencia externa» para omitir su relación o comprobación.

### 2.2 Procesos asignados

Implementen las operaciones necesarias para resolver los procesos de su anexo con sus excepciones y resultados observables. No se pide construir flujos operativos para todas las entidades del negocio. Los catálogos, hechos previos y resultados de procesos no asignados pueden prepararse mediante datos de prueba, respetando las reglas y dejando clara su procedencia.

**No confundan preparación de datos con resolución del proceso:** no vale precargar el estado final y mostrarlo como si la operación lo hubiera producido. Deben ejecutarse las modificaciones evaluadas y comprobarse después sus efectos persistidos. De igual forma, cuando yo lo valide, me daré cuenta si los procesos cumplen o no.

Las relaciones que no participan en esos procesos siguen siendo obligatorias y se verifican mediante pruebas de integridad. No se exigen frontend, backend, API REST, integración con clientes externos ni otro motor de base de datos.

## 3. Conciliación Proyecto 1 → Lab03 → segunda entrega

Entreguen en Markdown una versión consolidada del modelo, diccionario y trazabilidad, actualizados en los aspectos que hayan cambiado. Identifiquen de qué artefacto parte cada relación y qué se conserva, corrige o amplía. Si dos fuentes discrepan, describan ambas y fundamenten la decisión; no elijan una solo porque su archivo dice «final».

Reutilicen consultas, restricciones, datos, funciones, procedimientos y pruebas válidas de Lab03. Adáptenlos cuando el modelo completo cambie sus dependencias. No se exige reescribir un componente correcto para producir código nuevo. Al reutilizarlo, vuelvan a comprobarlo en el conjunto actual y distingan el resultado histórico del resultado de esta entrega.

Las notas anteriores no se recalculan. Las observaciones formativas no se convierten automáticamente en sanciones. Deben corregir lo que contradiga las reglas aplicables del caso o impida el alcance actual; las recomendaciones opcionales se mantienen identificadas como tales. Toda decisión de cambio o reutilización se registra en `Control_de_Cambios.md`, conforme a la [especificación común](Control_de_Cambios_Especificacion.md).

## 4. Integridad y cobertura del modelo completo

Entreguen una matriz en Markdown que permita encontrar, para cada relación y regla aplicable, su representación física, el mecanismo que la mantiene y las pruebas que la verifican. Para relaciones fuera de los procesos asignados, comprueben al menos las siguientes categorías donde correspondan:

| Aspecto | Qué se debe comprobar |
|---|---|
| Identidad | Alta válida; rechazo de duplicación de clave primaria o alternativa; identidad compuesta completa. |
| Referencias | Vínculo válido; referencia inexistente o incompleta; comportamiento al modificar/eliminar un objeto referenciado. |
| Dominios y obligatoriedad | Valores válidos, nulos permitidos/prohibidos, valor fuera del dominio y extremos relevantes de fechas/cantidades. |
| Contexto | Los registros relacionados pertenecen al mismo paciente, solicitud, contrato, evento, envío, productor u otro contexto que el caso exija. |
| Reglas entre filas o relaciones | Cantidades acumuladas, exclusividad, vigencia, estados, historia y condiciones de cierre cuando apliquen. |

No se impone un número de pruebas por tabla. Una prueba puede cubrir varias relaciones; cada categoría aplicable debe tener evidencia identificable. Justifiquen expresamente «no aplica». Una relación vacía sin prueba, un listado de sus columnas o una fila marcada «cumple» no demuestran integridad.

Mantengan reglas también en las operaciones permitidas de modificación y eliminación, no solamente al insertar la semilla. Documenten las rutas de escritura admitidas y sus permisos. Si una garantía depende de una operación controlada, debe quedar claro por qué una ruta habilitada no puede eludirla. No se exige un trigger como solución universal ni un sistema de autenticación de aplicación.

## 5. Consultas y programación PostgreSQL

Seleccionen y justifiquen SQL y PL/pgSQL según la necesidad real. No hay una cuota obligatoria de funciones, procedimientos, cursores, tablas temporales o triggers. Un proceso puede componerse de varias operaciones y una rutina puede atender varias situaciones, si sus límites y resultados son comprensibles y verificables.

Documenten para cada operación pública su propósito, información recibida, datos que devuelve o modifica, precondiciones, rechazos y alcance de la transacción. Ustedes eligen nombres, firmas, organización y técnicas. No les voy a imponer un formato para los nombres, ni tampoco un formato de respuesta para una aplicación, aunque sería interesante que investiguen cual es el estándar en la industria.

Las consultas deben permitir comprobar estados actuales, historias y agregados necesarios para aceptar el proceso. No basta mostrar avisos o contar filas sin comprobar pertenencia y valores relevantes. Cuando una temporal requiera la misma sesión o transacción para consumirse, documenten esa condición. No usen SQL dinámico ni otras técnicas solo para incrementar el número de componentes.

## 6. Transacciones, errores y concurrencia

Definan qué cambios constituyen una sola decisión del negocio. Si una operación falla, no deben quedar cabeceras sin detalle requerido, recursos consumidos sin compromiso válido, historia que contradiga el estado actual ni cantidades parcialmente aplicadas. Si un rechazo del negocio debe conservarse —por ejemplo una solicitud rechazada—, pueden persistir su resultado y razón, pero no los efectos propios de una aceptación. Distingan este rechazo registrado de un error técnico que aborta la operación.

Los errores deben permitir reconocer la causa: referencia desconocida, dato fuera del dominio, estado incompatible, conflicto de capacidad, autorización inválida u otra condición del caso. Conserven evidencia del error real y del estado posterior; no se impone un texto ni SQLSTATE particular.

Para los recursos o decisiones compartidos de sus procesos, demuestren con sesiones PostgreSQL concurrentes qué ocurre cuando se compite por el mismo cupo, unidad, cantidad o estado. Describan estado inicial, intercalación, confirmaciones/rechazos y estado final. El resultado aceptable respeta la regla: puede haber espera, rechazo o necesidad documentada de reintento. No se admite declarar que funciona en concurrencia porque dos llamadas secuenciales dieron el resultado esperado.

Seleccionen el mecanismo de control; no se prescribe algoritmo, nivel de aislamiento o clase de bloqueo. Una operación que se reintenta tras un conflicto no debe terminar duplicando los efectos ya confirmados. Documenten qué conoce quien ejecuta cuando una transacción es rechazada o su resultado debe verificarse antes de volver a enviarla.

## 7. Pruebas y evidencia verificable

Cada prueba debe identificar: regla/proceso, estado inicial y preparación, acción ejecutada, resultado esperado definido antes de ejecutarla, resultado observado, consultas de comprobación y conclusión. Incluyan casos positivos, negativos, de frontera y concurrentes pertinentes a su negocio.

Comprueben valores y vínculos persistidos después de confirmar. Para un rechazo comprueben ausencia de efectos indebidos; para una operación multirregistro incluyan un fallo que permita verificar su atomicidad. Si las pruebas se revierten para ser repetibles, capturen primero el estado observable dentro de la transacción y expliquen el cierre. Incluyan además demostración de confirmación y lectura posterior cuando afirmen persistencia. No son suficientes mensajes preparados, resultados esperados copiados como observados o capturas sin acción reproducible.

Usen datos ficticios, coherentes y suficientes para distinguir resultados: por ejemplo dos contextos válidos diferentes para probar un cruce indebido. No usen información personal real. Los datos de una auditoría anterior pueden servir como antecedente, pero no sustituyen ejecutar y comprobar la versión actual.

Las pruebas negativas deben distinguir el rechazo correcto de otro error accidental. Un identificador inexistente no demuestra una regla temporal si la ejecución falla antes por referencia. El guion debe indicar cómo maneja errores esperados y cómo permite alcanzar el resto de las pruebas. No debe dejar transacciones abiertas ni depender de continuar manualmente sin explicación.

## 8. Instalación y reproducción desde una base limpia

Declaren versión de PostgreSQL utilizada, cliente/comandos y cualquier extensión realmente necesaria. No se presume compatibilidad con versiones no probadas. Debe ser posible crear una base de trabajo nueva, ejecutar los archivos en el orden documentado y obtener el modelo completo, los datos y los resultados de pruebas sin crear objetos manualmente.

La preparación debe ejecutarse exclusivamente sobre una base nueva destinada al proyecto. No borren bases preexistentes ni incluyan credenciales personales. Documenten cómo reconocer la base de prueba y cómo repetir cada conjunto sin conflictos causados por residuos. Los scripts de prueba deben distinguir fallos previstos de errores inesperados. Si se usa una alternativa opcional, indiquen cómo se activa y qué resultado equivalente demuestra.

## 9. Entregables y estructura

Se entrega un único paquete organizado. Pueden cambiar los nombres de archivos SQL y su división si el README indica de forma inequívoca el orden y propósito. Los documentos expresamente nombrados deben estar identificables.

**Documentación escrita:** toda la documentación de esta segunda entrega debe presentarse únicamente en archivos Markdown (`.md`). Esto incluye modelo, diccionario, decisiones de diseño, descripción de procesos y operaciones, tablas de requisitos, matrices de trazabilidad, escenarios y resultados esperados/observados de pruebas, conclusiones y control de cambios. No se aceptarán `.docx`, `.doc`, `.pdf`, `.xlsx` ni `.xls` como documentación, ni se debe duplicar el mismo contenido en distintos formatos. Este requisito aplica a la nueva entrega; no exige convertir los documentos de entregas anteriores.

**Implementación ejecutable:** los scripts PostgreSQL deben entregarse como archivos `.sql` independientes que permitan construir el esquema físico completo, cargar los datos de prueba y ejecutar las operaciones y validaciones correspondientes. La documentación Markdown explica su orden de ejecución. Los bloques SQL en Markdown pueden acompañar una explicación, pero no sustituyen los archivos `.sql` ejecutables.

**Diagramas:** se permite Mermaid dentro de Markdown y, cuando sean necesarias para representar adecuadamente el modelo, imágenes de diagramas `.png` o `.svg` referenciadas desde los documentos. Los diagramas deben corresponder al modelo relacional y físico actualizado. No se acepta un PDF como sustituto del diagrama requerido.

Mantengan la organización existente cuando sea equivalente a la siguiente. Los nombres `Modelo_Relacional.md`, `Procesos_Negocio.md` y `Pruebas.md`, así como la carpeta `diagramas/`, son ejemplos de organización; no obligan a crear documentos o carpetas adicionales si su contenido ya está identificado en una estructura equivalente.

| Contenido | Qué debe incluir |
|---|---|
| `README.md` | Descripción del proyecto e integrantes/grupo; versión y requisitos; creación de base nueva; orden de carga y ejecución de los archivos `.sql`; rutas de pruebas; recuperación de errores esperados y limpieza de datos de prueba; puede incluir el enlace accesible a la defensa en video. |
| `modelo/` | Documentación `.md` del modelo relacional consolidado completo, diccionario actualizado, matriz relación/regla–mecanismo–prueba y decisiones de diseño/ambigüedades; por ejemplo, `Modelo_Relacional.md`. |
| Documentación de procesos | Descripción en `.md` de los procesos y operaciones implementados; por ejemplo, `Procesos_Negocio.md`, o su sección equivalente en la documentación existente. |
| `sql/` | Archivos `.sql` ejecutables de esquema completo, datos de prueba, consultas, rutinas y validaciones según la organización elegida. Los scripts de pruebas pueden conservarse en `pruebas/` si el README identifica su orden. No se proporcionan plantillas resueltas. |
| `pruebas/` | Documentación `.md` de casos reproducibles, resultados esperados/observados y comprobaciones —por ejemplo, `Pruebas.md`—, y guiones `.sql` para pruebas y sesiones concurrentes con orden de pasos. |
| `evidencias/` | Registro documentado en `.md` de la ejecución de la versión entregada, resultados esperados/observados, errores, estados finales y conclusión, con las evidencias técnicas auxiliares referenciadas. |
| `diagramas/`, cuando corresponda | Imágenes `.png` o `.svg` del modelo actualizado; también se admite Mermaid dentro de los documentos Markdown, sin exigir una carpeta adicional. |
| `Control_de_Cambios.md` | Trazabilidad de cambios y componentes reutilizados sin modificación. |
| `Uso_de_IA.md` | Declaración de uso o no uso, herramientas y aportes relevantes, prompts utilizados para material incorporado, decisiones propias y validaciones. |
| `Defensa.md` | Participantes identificados e índice que permita localizar las explicaciones y demostraciones; enlace al video o referencia a la sección del `README.md` que lo contiene. |

No entreguen solamente un respaldo binario ni dependan de una base ya preparada en su computadora. No es necesario distribuir entornos externos, aplicaciones o servicios.

## 10. Defensa en video y uso de IA

Todos los integrantes deben participar de manera identificable. Cada persona debe explicar una parte sustantiva, relacionar una decisión con su regla, recorrer el efecto de una operación sobre los datos e interpretar una prueba o rechazo. La participación no se limita a leer la introducción o mostrar su nombre.

En el video deben poder reconocerse el entorno, la versión entregada, una ejecución con comprobación de datos y la explicación de integridad, transacción y concurrencia pertinente. El README y los guiones deben permitir repetir lo mostrado. No se establece aquí duración del video ni fecha de entrega.

La defensa conserva su modalidad de video, cámara encendida siempre y buena iluminación por favor. Se permite entregar un enlace accesible desde `README.md` que permita al profesor revisar la grabación; no se exige incorporar archivos de video pesados al repositorio o paquete de entrega. La identificación de participantes y el índice se documentan en Markdown, conforme a la sección 9.

**Está permitido usar IA** para desarrollar, revisar y probar SQL. Se valora funcionamiento real, fidelidad al caso, pruebas reproducibles e independientes de mensajes de éxito y comprensión individual. El tiempo de escritura manual no es la medida principal de dificultad. Quien incorpora una propuesta debe poder explicar su propósito, límites y evidencia de validación; no basta atribuir una decisión a una herramienta.

## 11. Lectura del anexo y asuntos no definidos

El anexo de su grupo precisa la aceptación funcional. Las pruebas de aceptación son comportamientos a demostrar, no algoritmos ni esquemas de solución. No adopten como regla del negocio un umbral de un ejemplo si su fuente lo identifica como supuesto.

Los valores temporales definidos expresamente en el caso, las aclaraciones o los requisitos de esta entrega son obligatorios: apliquen la cantidad de días y su contexto y prueben sus fronteras. No creen plazos numéricos adicionales cuando no sean necesarios para los procesos. Si una regla requiere un valor que las fuentes no fijan, documenten la interpretación y su efecto; un ejemplo o supuesto de Lab03 no se convierte por sí solo en requisito general.

Si el caso admite varias interpretaciones, documenten fragmento, pregunta, supuesto e impacto. Una decisión que contradiga una condición explícita o reduzca un proceso asignado requiere aclaración docente; no puede quedar escondida entre supuestos.
