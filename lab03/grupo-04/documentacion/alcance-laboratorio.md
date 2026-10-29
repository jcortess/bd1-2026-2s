# Alcance del Laboratorio 3 — Grupo 04

## 1. Proceso y objetivo

Se selecciona la administración y consulta de autorizaciones de personas para clientes organización de Alquileres El Roble. El proceso comienza con un cliente, una persona y facultades previamente registrados; termina con una autorización completa y consultable por fecha, o con un rechazo explicado sin inserciones parciales.

La preparación de esos datos de referencia forma parte del laboratorio. El proceso no ejecuta las acciones de reservar, recibir o devolver equipos: consulta la facultad registrada que tales acciones utilizarían.

Esta es una decisión de alcance del laboratorio, no una aprobación del profesor. La revisión docente sigue pendiente de identificación y podría motivar correcciones documentadas.

## 2. Fuentes y reglas conservadas

Fuentes: Análisis, secciones de reglas y supuestos; Modelo relacional, secciones 3, 4 y 11; Matriz de trazabilidad, RN-01 y RN-02 y correspondencia del resultado normalizado; Diccionario, las cinco relaciones seleccionadas. Los archivos se identifican en base-proyecto-1.md.

| Referencia | Cobertura prevista |
|---|---|
| RN-01 | Registrar varias personas autorizadas por una organización |
| RN-02 | Registrar facultades diferentes y comprobar vigencia para la consulta |
| AS-01 | Conservar CLIENTE con tipo y datos condicionales; PERSONA evita duplicar identidad de clientes físicos |
| AS-02 | Rechazar el otorgamiento a clientes físicos |
| AS-03 | Mantener un catálogo administrable de facultades, no tres columnas booleanas |

No se renumeran estas referencias. El análisis representa supuestos con AS; no deben presentarse como reglas explícitas originales.

## 3. Relaciones incluidas y dependencias

| Relación | Papel y relaciones relevantes |
|---|---|
| PERSONA | Identidad; identificación única por tipo y valor; referenciada por CLIENTE y AUTORIZACION |
| CLIENTE | Cliente responsable; enlace opcional a PERSONA según tipo; concede autorizaciones solo si es organización |
| AUTORIZACION | Vincula un cliente con una persona, inicio obligatorio y fin opcional |
| FACULTAD | Catálogo con nombre único |
| AUTORIZACION_FACULTAD | PK compuesta por autorización y facultad; materializa la relación muchos-a-muchos |

Se conservan los atributos y claves de estas relaciones. No se elimina la FK de CLIENTE a PERSONA ni se convierte CLIENTE en una tabla exclusiva de organizaciones. Se requieren clientes físicos para demostrar la validación del tipo.

Todas las FK de las cinco relaciones tienen destino dentro del subconjunto. Contactos, suspensiones y certificaciones son módulos relacionados pero no prerrequisitos de integridad referencial para registrar una autorización. La omisión de esos módulos se declara como límite funcional, no como cumplimiento de sus reglas.

## 4. Operación de negocio prevista

Otorgar una autorización con una o varias facultades.

1. Comprobar existencia de cliente y persona.
2. Comprobar que el cliente es organización.
3. Validar fechas y lista de facultades.
4. Comprobar que todas las facultades existen.
5. Insertar AUTORIZACION y sus vínculos de AUTORIZACION_FACULTAD como una operación atómica.
6. Si se rechaza cualquier condición, comunicar el motivo sin conservar una autorización incompleta.

El diseño de parámetros, tipos físicos y manejo transaccional se concretará en las etapas de esquema y rutinas. No se ha implementado ni probado esta operación.

## 5. Decisiones adicionales del laboratorio

Son decisiones propuestas para hacer verificable la implementación, no información explícita atribuida al caso o al profesor. Su aprobación permite usarlas como contrato de implementación.

### DL-01 — Límites de vigencia

Se utilizará el intervalo [inicio, fin): el inicio está incluido y el fin excluido. Si fin está ausente, no hay límite superior establecido. Fin presente debe ser estrictamente posterior al inicio. Una autorización futura puede registrarse, pero no cuenta como vigente antes de su inicio.

La elección resuelve una ambigüedad de frontera. Si el negocio exige fin inclusivo, deben cambiar el predicado de consulta y las pruebas, no solo la documentación. Se probarán el instante anterior al inicio, el inicio exacto, un punto interior y el fin exacto.

### DL-02 — Fecha explícita y resultados

Las consultas funcionales recibirán una fecha y hora de referencia explícita, no dependerán implícitamente del reloj actual. Una fecha nula será entrada inválida. La función de facultades devolverá un conjunto vacío si los identificadores existen pero no hay facultades vigentes; identificadores inexistentes se rechazarán con explicación. La función de decisión distinguirá entrada inválida de ausencia de autorización vigente suficiente. Los tipos exactos de retorno quedan para la especificación de rutinas.

### DL-03 — Lista de facultades

El otorgamiento rechazará listas nulas, vacías, con elementos nulos, duplicados o inexistentes. No eliminará silenciosamente duplicados. Una autorización válida tendrá al menos una facultad y nunca repetirá un vínculo.

### DL-04 — Varias autorizaciones

No se impondrá unicidad global a (id_cliente, id_persona) ni se inventará una prohibición de períodos superpuestos. Si varias autorizaciones vigentes conceden la misma facultad, las consultas de facultades la mostrarán una sola vez. Los conteos de personas usarán personas distintas.

### DL-05 — Separación de controles

PK, FK, obligatoriedad, unicidad y restricciones de fila permanecerán en el esquema. El procedimiento comprobará cliente organización y lista no vacía, además de las validaciones necesarias. La evidencia deberá demostrar que el rechazo no deja filas parciales.

No se afirmará que el procedimiento garantiza las reglas frente a todo acceso directo. Sin medidas adicionales, un usuario con permisos de escritura puede eludir validaciones procedimentales, eliminar todas las facultades o cambiar el tipo del cliente referenciado. El control de permisos y una garantía global para tales escrituras quedan fuera de esta implementación académica y deben constar como limitación.

### DL-06 — Conservación y operación acotada

La operación ofrecida registra nuevas autorizaciones; no incluirá rutinas para revocar, eliminar o modificar autorizaciones existentes. El paso del tiempo no borra sus registros. La expiración se obtiene de las fechas, no de un estado nuevo añadido sin fundamento.

## 6. Exclusiones y límites de la respuesta

Quedan fuera contratos, reservaciones, inventario, tarifas, asignaciones, inspecciones, entregas, devoluciones, mantenimiento, garantías, cargos y sus respectivos procesos. También quedan fuera contactos, suspensiones, certificaciones, permisos del personal interno, revocación anticipada y auditoría completa de cambios.

Una respuesta positiva significa únicamente que existe una facultad registrada y vigente para la persona, organización y fecha consultadas. No significa que pueda completarse una entrega: RN-03, RN-04, RN-08 y RN-10, entre otras, necesitan controles no incluidos. No se certifica el cumplimiento de las otras 23 reglas RN por este recorte.

## 7. Cobertura prevista del enunciado

- A: cinco relaciones del modelo final, fragmento lógico, trazabilidad y restricciones físicas.
- B: datos ficticios con autorizaciones vigentes, vencidas, futuras y abiertas; tres consultas útiles, con combinación y agregación; al menos seis pruebas, tres válidas y tres rechazadas.
- C: función de facultades vigentes, función con decisión, procedimiento de otorgamiento y demostración con tabla temporal y alternativa basada en conjuntos. Nombres y firmas se concretarán después.
- D: instrucciones reproducibles, evidencias identificadas y videos individuales.

Esta cobertura es planificación, no calificación ni evidencia de ejecución. La siguiente etapa elaborará el fragmento lógico y la matriz lógica-física; no se crean SQL ni diagramas definitivos en este paso.
