# Base documental del Proyecto 1

## Inventario de fuentes aportadas

Estos nombres identifican archivos proporcionados para la planificación; no son enlaces ni archivos incorporados al repositorio.

| Archivo | Utilización prevista |
|---|---|
| Proyecto_1.pdf | Indicaciones generales del diseño conceptual y lógico |
| Proyecto_1_Aclaraciones_Complementarias-2.pdf | Modelo final, identificadores estables y tratamiento de supuestos |
| Analisis-de-Alquileres-El-Roble-4.pdf | Reglas RN-01 a RN-25, supuestos AS y alcance |
| Modelo-Conceptual-10.pdf | Entidades y asociaciones conceptuales |
| diagrama-conceptual-5.svg | Fuente gráfica conceptual; revisión visual detallada pendiente |
| Modelo-Relacional-11.pdf | Transformación inicial de 26 relaciones y restricciones |
| diagrama-relacional-7.svg | Fuente gráfica relacional inicial; revisión visual detallada pendiente |
| Normalizacion-3.pdf | Resultado normalizado de 29 relaciones |
| diagrama-relacional-normalizado-6.svg | Fuente gráfica del resultado final; revisión visual detallada pendiente |
| Diccionario-8.pdf | Atributos, claves, obligatoriedad y dominios del resultado final |
| Matriz-de-Trazabilidad-9.pdf | Correspondencia de reglas con el modelo final |

## Criterio de continuidad

El resultado normalizado es la base lógica final, conforme a las aclaraciones del Proyecto 1. No debe sustituirse por el esquema inicial sin justificación.

RESERVACION separa la identidad y cliente de las versiones de RESERVA; CARGO_ASIGNACION y CARGO_INCIDENCIA separan vínculos opcionales de CARGO. Esos módulos quedan fuera del subsistema seleccionado; sus cambios no deben revertirse en futuras ampliaciones. Las cinco relaciones seleccionadas conservan las definiciones del modelo relacional, según la correspondencia del resultado normalizado indicada por la matriz.

## Registro de pendientes y decisiones

| ID | Asunto | Estado y acción |
|---|---|---|
| P-01 | Revisión del profesor | Pendiente de identificar archivo, imagen o página. No se atribuyen observaciones no verificadas. |
| P-02 | Alcance | Definido en alcance-laboratorio.md: autorizaciones y cinco relaciones. No equivale a aprobación docente. |
| P-03 | Vigencia | Decisiones DL-01 y DL-02 documentadas; implementación y pruebas de límites pendientes. |
| P-04 | Reglas procedimentales | Decisiones DL-03 a DL-06 y límites de escrituras directas documentados; implementación pendiente. |
| P-05 | Coherencia gráfica | Pendiente contrastar el fragmento con diagramas originales y exportarlo a formato permitido. |

Consultar el [documento de alcance](alcance-laboratorio.md). Los asuntos definidos documentalmente aún requieren verificación técnica; no se consideran pruebas aprobadas.

## Tratamiento de correcciones

Cada observación se registrará con fuente, elemento afectado, decisión, justificación y prueba prevista. No se modificarán silenciosamente los archivos históricos del Proyecto 1 ni se renumerarán RN o AS. Las decisiones DL son adicionales del laboratorio, no reglas originales ni observaciones atribuidas al profesor.
