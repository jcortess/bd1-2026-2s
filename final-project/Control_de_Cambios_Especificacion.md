# Especificación de `Control_de_Cambios.md`

El documento debe permitir reconstruir **Proyecto 1 → Lab03 → segunda entrega**, tanto para cambios como para reutilización. No se valora el número de modificaciones: se valora que sean necesarias, coherentes con el caso, trazables y verificadas. No modifica notas de entregas anteriores.

## 1. Identificación y versiones de referencia

Indiquen grupo/integrantes, caso, versión de la segunda entrega y archivos/versiones utilizados del Proyecto 1 y Lab03. Diferencien modelo inicial del resultado final normalizado. Si la entrega anterior era provisional o tenía artefactos contradictorios, identifíquenlos y expliquen la consolidación elegida y su fuente. Una relación no presente en el recorte Lab03 debe registrarse como no implementada allí, no como relación inexistente en Proyecto 1.

## 2. Registro de cambios

Usen identificadores estables propios, sin una cantidad mínima. Cada registro incluirá todos estos campos:

| Campo | Información verificable |
|---|---|
| Identificador del cambio | Código único para enlazar modelo, SQL y pruebas. |
| Fuente u origen | Caso/sección, regla, comentario docente identificable, defecto probado con identificador o necesidad del proceso asignado. Distinguir requisito, observación formativa, supuesto y decisión propia. |
| Elemento afectado | Relación, atributo, clave, referencia, dominio, regla, consulta, rutina, operación, prueba o documento. |
| Situación anterior | Qué decía P1, qué llegó a Lab03 y qué se observó realmente. Si no existía, decirlo; no simular una evolución inexistente. |
| Modificación realizada | Qué cambia en la versión actual, con diferencia concreta antes/después. No basta «se corrigió». |
| Justificación | Por qué conserva/mejora fidelidad al caso o permite el proceso, y por qué no introduce una política arbitraria. |
| Reglas relacionadas | Identificadores propios y fuente; si se renumeraron, correspondencia con anteriores. |
| Impacto en modelo y operaciones | Dependencias, datos afectados, historia, firmas/rutas elegidas y pruebas que dejan de ser válidas. |
| Archivos modificados | Rutas dentro de la entrega y secciones/objetos identificables. |
| Evidencia de validación | Pruebas de la versión actual, esperado/observado, consultas de estado y resultado; enlace a evidencia. |

Cuando corresponda, agreguen alternativas consideradas, riesgos de migración y decisión sobre datos históricos. El documento describe su implementación; no basta copiar una recomendación del profesor como si ya se hubiera ejecutado.

## 3. Reutilización sin modificación

Incluyan una sección separada con componente, archivo/versión de origen, propósito, reglas que cubre, razón para conservarlo, dependencias compatibles y pruebas actuales que confirman que sigue funcionando. Puede enlazarse un mismo componente con varios procesos. No es obligatorio cambiarlo para obtener reconocimiento.

## 4. Cobertura y pendientes

Incluyan la correspondencia entre todas las relaciones de partida y el modelo completo actual, con referencia a su matriz de integridad. Distingan ampliación/corrección de una renominación. Ninguna relación puede desaparecer por estar fuera de los procesos asignados. Una regla declarada «no representable completamente en el lógico» debe ahora señalar cómo se verifica y qué prueba lo demuestra.

Identifiquen supuestos aún pendientes, con fragmento, pregunta e impacto. No presenten como resuelto un defecto que sigue reproducible. Las recomendaciones opcionales no adoptadas pueden documentarse con razón; no se exige implementarlas si no derivan del caso ni del alcance aprobado.

## 5. Comprobación al entregar

Una persona revisora debe poder partir de cualquier cambio, encontrar su origen, localizar los archivos actuales y repetir su validación. También debe poder partir de una relación o regla y reconocer si se conservó, se implementó por primera vez o se corrigió. El control no exige historiales inventados, captura de toda conversación con IA ni una rutina distinta por registro.
