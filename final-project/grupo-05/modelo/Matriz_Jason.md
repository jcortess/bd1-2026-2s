# Matriz de integridad · Bloque de Jason

RN-01 a RN-25 mantienen los números del Proyecto 1 §2. Los criterios AC provienen del anexo. Las referencias I, M y C remiten a las sentencias y resultados de esta entrega. La columna de integridad indica la regla y el mecanismo físico que debe mantenerse en las rutas documentadas. [Modelo y diccionario](Modelo_Jason.md) · [Guion secuencial](../pruebas/01_bloque_jason.sql) · [Resultados](../evidencias/Resultados_Jason.md)

| Relación | Regla y mecanismo | Prueba |
|---|---|---|
| PERSONA | RN-09, S-06/S-07. PK propia, nombre opcional con dominio de texto. La FK de cada rol o hecho conserva la identidad aunque cambien los datos descriptivos. | I01–I02, I03, I10. |
| MEDIO_CONTACTO | S-07. PK propia, persona existente y tipo y valor obligatorios. Una persona puede carecer de medios conocidos y el dato de contacto no identifica a la persona. | I02. |
| PARTICIPACION | RN-07/09. FK a persona, rol y estado con dominios, periodo válido, fecha de aprobación obligatoria por estado y verificación de aprobación previa y vigente en el movimiento. El trigger y la FK preservan la evidencia histórica. | I03, M05, M06, M09. |
| ANIMAL | RN-01/03. Código estable por PK y trigger. Edad no negativa, especie común y obligatoria, microchip único si se conoce. Se preserva la especie usada para validar una admisión. | I04, I11, M07. |
| ORGANIZACION_EXTERNA | RN-04/25, S-09. PK propia y nombre obligatorio. FK desde INGRESO; se conserva la fila remesante. La FK desde RESULTADO_ETAPA corresponde a la integración. | I05–I06. |
| INGRESO | RN-01/02/04/23/25. Animal, datos básicos y situación obligatorios. CHECK condicional por motivo y organización. No se exige reporte. Etapas disjuntas con GiST. El trigger protege el ingreso utilizado y el cierre exige terminar el alojamiento. FK a PERSONA y CHECK para el receptor. La referencia inversa de adopción condiciona habilitar el regreso. | M01, M03, I06, I10–I11. |
| UBICACION | RN-06/07/08 y S-03/S-11/S-13. CHECK de datos por tipo, FK a oferente y exclusión de ofertas solapadas. Trigger y FK preservan configuraciones e identidad utilizadas. | M02, M06–M11, I07. |
| UBICACION_ESPECIE_ACEPTADA | RN-07. PK compuesta con dominio común y FK. El trigger restringe el tipo y protege el requisito usado en la historia. El movimiento exige coincidencia de especie. | M07, I08. |
| ESTANCIA | RN-05/06/07/08/14. FK contextual a etapa, FK de lugar y actores, CHECK de fechas y cierre, exclusión por rango real, admisión controlada, serialización transaccional y ausencia de permisos de DML para el operador. | M01–M11, I09, I11–I12, C1–C2. |

PERSONA y ANIMAL son raíces del bloque y no requieren una referencia saliente. Los nombres descriptivos o el valor de un medio se admiten repetidos. UBICACION y ESTANCIA manejan reglas de contexto según el tipo de destino. Un hogar en preparación puede carecer de especies o aprobación, pero no recibe animales hasta satisfacer ambas condiciones. El bloqueo de devoluciones impide aún ejecutar la FK del receptor con un regreso válido. I10 verifica que la FK existe y quedó validada en el catálogo y que el receptor se exige. [Pendientes de integración](../Integracion.md)

## Criterios de G05-P01

| Criterio | Mecanismo | Evidencia |
|---|---|---|
| AC-G05-P01-01 | FK de etapa, exclusión temporal y vistas `ubicacion_actual` e `historial_alojamiento`. | M01/M04/M06/M10–M11, I09/I11, C2. |
| AC-G05-P01-02 | Validación por tipo, datos del hogar, aprobación, periodo y capacidad calculada en puntos de admisión. | M02/M03/M05–M11, I03/I07/I08, C1. |
| AC-G05-P01-03 | Cierre del origen y alta del destino en una llamada. Si se rechaza el destino, se revierte el cierre de origen. | M05 con lectura posterior al `COMMIT`. |
| AC-G05-P01-04 | Bloqueo asesor, relectura en `READ COMMITTED`, comparación del origen esperado y comprobación posterior en otra conexión. | C1, C2 e I12. |

## Reglas con integración pendiente

| Regla del Proyecto 1 | Pendiente | Responsable |
|---|---|---|
| RN-02 | Vínculo de reportes con varios animales. | Paula |
| RN-10–11 | Evaluación inicial por etapa, registro veterinario vigente, revisiones y observaciones diagnósticas. | Paula |
| RN-12–13 | Origen y sustitución de indicaciones, diagnóstico en la revisión de origen y datos de aplicación realizada. | Jean Carlos y Paula para la referencia |
| RN-14–15 | Documentar la valoración de habilitación y el cambio de disponibilidad con actor, fecha y observación. La valoración de traslados ya está incluida. | Paula |
| RN-16–19 | Interés, actividades, historial de decisiones y valoración de compatibilidad entre animal y hogar concreto. | Paula |
| RN-20–22 | Reserva exclusiva, formalización individual con responsables y seguimiento. | Jean Carlos |
| RN-23 | FK de adopción origen, contexto y cronología del regreso. | Jean Carlos con Jason |
| RN-24 | Restricción con decisión registrada. | Jean Carlos |
| RN-25 | Adoptar el contrato de cierre y comprobar exclusión de resultados, organización de destino y condiciones de traslado. | Jean Carlos con Jason |
