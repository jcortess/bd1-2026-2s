# Alcance del Laboratorio 3 — Grupo 04

## Proceso, fuentes y cobertura

Administrar y consultar autorizaciones de personas para clientes organización. Con cliente, persona y facultades previamente registrados, la operación termina con una autorización completa y consultable por fecha o con rechazo explicado sin filas parciales. La preparación de datos de referencia está incluida. No se ejecutan reservas, entregas ni devoluciones.

Fuentes: Análisis, RN-01/RN-02 y AS-01/AS-02/AS-03; Modelo relacional, secciones 3, 4 y 11; Diccionario de las cinco relaciones; Matriz y correspondencia del resultado normalizado.

Se conservan PERSONA, CLIENTE, AUTORIZACION, FACULTAD y AUTORIZACION_FACULTAD, con sus 19 atributos. Todas sus FK tienen destino en el subconjunto. CLIENTE mantiene ambos tipos y su enlace opcional a PERSONA; los clientes físicos permiten probar el rechazo de autorizaciones no admitidas. No se eliminan referencias ni se agregan asociaciones artificiales.

RN-01 permite varias personas autorizadas; RN-02 exige comprobar facultad y vigencia. AS-01 sustenta la representación de tipos de cliente; AS-02 limita autorizaciones a organizaciones; AS-03 mantiene el catálogo administrable. Estos supuestos no se presentan como reglas explícitas del caso.

La retroalimentación docente ya está identificada en las hojas aportadas; su tratamiento se registra en retroalimentacion-y-uso-ia.md. No exige sustituir el modelo relacional ni la normalización, calificados como excelentes, y no constituye aprobación del alcance del laboratorio.

## Operación principal prevista

Otorgar autorización: comprobar existencia de cliente y persona, tipo organización, período válido y lista de facultades válida; insertar autorización y vínculos de forma atómica o rechazar sin inserciones parciales. Firmas y manejo transaccional se concretarán al implementar.

## Decisiones funcionales conservadas

- DL-01: intervalo [inicio, fin), con inicio incluido y fin excluido. Fin ausente significa sin límite superior establecido; fin presente debe ser posterior al inicio. Una autorización futura no cuenta antes de su inicio. Probar instante anterior, inicio, interior y fin exacto. Si cambia la convención, ajustar consultas y pruebas.
- DL-02: fecha y hora explícitas; fecha nula inválida. La consulta de facultades devuelve conjunto vacío si las entidades existen pero no hay facultades vigentes; rechaza identificadores inexistentes. La función de decisión distingue entrada inválida de ausencia de autorización suficiente. Retornos exactos pendientes de especificación.
- DL-03: rechazar listas nulas, vacías, con nulos, duplicados o facultades inexistentes; no depurar silenciosamente. Al menos una facultad por autorización creada mediante la operación.
- DL-04: no imponer UNIQUE(cliente, persona) ni prohibir traslapes sin regla del negocio. Unir facultades vigentes sin duplicarlas y contar personas distintas.
- DL-05: mantener PK, FK, NOT NULL, UNIQUE y CHECK; el procedimiento agrega validación de organización y conjunto no vacío. No garantiza esas condiciones frente a cualquier escritura directa: pueden eliminarse todas las facultades o cambiarse el tipo de un cliente si existen permisos. Garantía global y control de permisos quedan fuera y no deben afirmarse como implementados.
- DL-06: ofrecer registro, no rutinas de modificación, revocación o eliminación. Expiración derivada de fechas, sin borrar historial ni añadir estado sin fundamento.

Son decisiones adicionales del laboratorio, no observaciones atribuidas al profesor.

## Exclusiones

Contactos, suspensiones, certificaciones y permisos del personal interno; contratos, reservas, inventario, tarifas, asignaciones, inspecciones, entregas, devoluciones, mantenimiento, garantías y cargos; revocación anticipada y auditoría completa. No se implementan sus módulos ni se eliminan sus reglas del proyecto global.

Una respuesta positiva solo demuestra facultad registrada y vigente para organización, persona y fecha. No acredita condiciones de entrega, suspensión, garantía, certificación o disponibilidad; no certifica las otras 23 RN.

## Cobertura del laboratorio y estado

A: fragmento, matriz y restricciones. B: datos representativos, tres consultas con combinación y agregación, seis pruebas como mínimo, tres válidas y tres rechazadas. C: dos funciones útiles, procedimiento de otorgamiento y demostración con tabla temporal y alternativa basada en conjuntos. D: instrucciones, evidencias y videos individuales.

El paso 3 documenta el diseño en ../modelo/fragmento-modelo-logico.md y diseno-fisico-y-trazabilidad.md. La cobertura sigue siendo planificación: aún no hay DDL ni ejecución. Las decisiones físicas DF complementan, sin renumerar, las DL.
