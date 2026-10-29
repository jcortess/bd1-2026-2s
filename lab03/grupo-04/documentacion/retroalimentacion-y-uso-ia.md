# Retroalimentación del Proyecto 1 y registro de IA

## Fuentes verificadas

Hoja Calificación, columna Observaciones, de Hoja_Calificacion_Proyecto_RIVAS-HERNANDEZ-BRACK-ROXEL.xlsx y Hoja_Calificacion_Proyecto_HIDALGO-GUTIERREZ-CARLOS-ANDRES-2.xlsx. Ambas contienen las mismas observaciones en los criterios siguientes. Los Excel no se incorporan al repositorio.

Modelo relacional, normalización y matriz fueron evaluados como excelentes. No se interpreta la retroalimentación como orden de rediseñarlos. Tampoco hay aprobación explícita del alcance del Lab 3.

## Tratamiento acotado al laboratorio

| ID | Observación docente y ubicación referida | Acción documental | Estado y límite |
|---|---|---|---|
| RF-01 | Modelo conceptual, páginas 5–8: figura dependiente de explicaciones complementarias | Fragmento con PK/FK, cardinalidades y condiciones junto a la figura | Preparado para las cinco relaciones; falta revisión visual. No corrige el conceptual completo |
| RF-02 | Diccionario, páginas 1–4: descripciones que repiten el nombre del campo | Definir semántica de los 19 atributos del subsistema | Documentado; revisión del equipo pendiente |
| RF-03 | Diccionario, páginas 1–13 y 5–7: dominios, ejemplos y condiciones genéricos o remitidos sin precisión | Tipos físicos propuestos, ejemplos ficticios, nulidad y restricciones explícitas | Documentado para este recorte, no las 29 relaciones; DDL pendiente |
| RF-04 | Uso de IA: faltan prompts relevantes, sugerencias y validación técnica propia | Registro inicial siguiente | Iniciado; no sustituye validación personal ni evidencia de ejecución |

Los problemas de suspensiones, inspecciones o cierre citados por el profesor quedan fuera del recorte. Su exclusión no significa que hayan sido corregidos globalmente. Se conservan los originales del Proyecto 1.

## Prompts relevantes de esta conversación

Herramienta: Perplexity. Propósito: planificar y documentar el paso del modelo lógico a una implementación parcial. Se registran textos del usuario; las respuestas incorporadas se resumen sin inventar una transcripción completa.

- PR-IA-01: «@GitHub Ok, quiero que recuerdes que estos son los archivos que se tomaron en cuenta y se entregaron en el primer proyecto (también está la revisión del profe), en el primer proyecto el cuál en buena teoría se debe de pasar de la parte teórica a la parte práctica. Luego, el grupo de nosotros es el 04. Yo anteriormente cree una rama llamada grupo-04 en el que se va a trabajar el lab. Quiero que me específiques con detalle que seguir para completar con éxito el lab». Originó la ruta y la propuesta de autorizaciones.
- PR-IA-02: «@GitHub Realicemos el segundo paso». Originó el documento de alcance y DL-01 a DL-06; su publicación fue autorizada con «@GitHub yes». La aprobación de publicación no equivale a validación técnica del equipo.
- PR-IA-03: «@GitHub En estas hojas de excel estaba la retroalimentación del primer proyecto. Ahora vamos con el paso 3». Origina el fragmento, diccionario, matrices y este seguimiento. Su publicación requiere confirmación.

## Sugerencias y contraste realizado

| Propuesta | Tratamiento | Contraste documental realizado por el asistente | Pendiente del equipo |
|---|---|---|---|
| Usar cinco relaciones existentes | Incorporada al alcance publicado | Comparadas con secciones 3/4 del relacional y correspondencia final de la matriz | Confirmar fidelidad y defender el recorte |
| Convención [inicio, fin) | Publicada como DL-01, no regla explícita | No contradice fin posterior a inicio; la frontera no estaba precisada | Validar interpretación y probar límites |
| Tipos y controles DF-01 a DF-04 | Propuestos en paso 3 | Distinguidos de dominios conceptuales originales | Aprobar, ejecutar DDL y verificar resultados |
| Garantizar mínimo de facultades solo con FK | Descartada durante revisión documental, no atribuida a una respuesta previa | La matriz ya indica validación adicional | Probar procedimiento y explicar límites de acceso directo |
| Marcar como corregido todo el Proyecto 1 | No adoptada | La entrega actual solo desarrolla cinco relaciones | Mantener seguimiento de observaciones externas al recorte |

## Estado real de validación

Se leyeron las hojas de retroalimentación y se contrastó la especificación textual de las relaciones. No se ejecutaron SQL ni pruebas; no se validó visualmente el SVG ni el render de Mermaid. La revisión independiente y justificación propia del equipo siguen pendientes y deben documentarse con responsable, fecha, resultado y evidencia al realizarlas.

Antes de entregar, ampliar este registro con los prompts que originen código incorporado, propuestas aceptadas o corregidas, errores detectados y pruebas efectivamente ejecutadas. Este registro inicial no certifica cumplimiento final del requisito de IA.
