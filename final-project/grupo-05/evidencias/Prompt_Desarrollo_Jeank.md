
# Registro de asistencia de inteligencia artificial

## Responsable

Jean Carlos Segura.

## Herramienta utilizada

ChatGPT.

## Propósito

Apoyar el análisis, implementación, integración,
depuración, pruebas y documentación del bloque
G05-P03 del proyecto Refugio Huellas Seguras.

## Alcance de las consultas

Durante el desarrollo se realizaron consultas
iterativas relacionadas con:

- Interpretación de los requisitos del proyecto.
- Distribución de responsabilidades del grupo.
- Implementación de las nueve relaciones asignadas.
- Integración con los bloques de Jason y Paula.
- Corrección de anomalías del Laboratorio 3.
- Desarrollo de funciones, procedimientos y triggers.
- Implementación de restricciones contextuales.
- Control de concurrencia y atomicidad.
- Preparación de datos ficticios.
- Desarrollo de guiones SQL reproducibles.
- Interpretación de errores de PostgreSQL.
- Elaboración de documentación Markdown.

## Instrucciones de trabajo

La siguiente síntesis reconstruye el alcance de
las consultas realizadas. No constituye una
transcripción literal de un único prompt original.

1. Implementar el proceso G05-P03 y las nueve
   relaciones asignadas.
2. Respetar el modelo y las interfaces existentes
   de los demás integrantes.
3. Utilizar PostgreSQL y archivos SQL ejecutables.
4. Garantizar integridad contextual entre solicitud,
   animal, ingreso, compatibilidad, reserva y adopción.
5. Evitar reservas vigentes simultáneas.
6. Formalizar adopciones mediante operaciones atómicas.
7. Conservar el historial de adopciones y devoluciones.
8. Evitar restricciones automáticas por devolución.
9. Corregir la asociación clínica de indicaciones
   y diagnósticos de diferentes evaluaciones.
10. Preparar pruebas positivas, negativas y concurrentes.
11. Ejecutar las pruebas en bases nuevas.
12. Documentar únicamente resultados comprobados.
13. Mantener la documentación exclusivamente en Markdown.
14. Evitar modificaciones innecesarias del trabajo ajeno.

## Aportes incorporados

La asistencia se utilizó para proponer y revisar:

- Definiciones de tablas y restricciones.
- Claves foráneas contextuales.
- Funciones de reserva y formalización.
- Procedimientos de aplicaciones clínicas.
- Validaciones de seguimiento.
- Mecanismos de protección del historial.
- Guiones de instalación.
- Consultas de comprobación.
- Pruebas secuenciales y concurrentes.
- Documentación técnica.

## Validación humana

El integrante incorporó los archivos al repositorio
local y ejecutó los comandos de PostgreSQL.

Las salidas obtenidas fueron compartidas con ChatGPT
para interpretar los resultados y corregir errores.

Las propuestas de código no se consideraron
automáticamente verificadas antes de su ejecución.

## Errores identificados durante el desarrollo

- Permisos insuficientes en una comprobación diferida.
- Referencia incorrecta a un atributo de estancia.
- Pérdida del search_path local después de COMMIT.
- Dependencia de un identificador fijo de adopción.
- Verificación concurrente ejecutada antes del COMMIT.
- Nombre incorrecto de un archivo en un comando.

Los errores fueron identificados mediante las
ejecuciones y se realizaron las correcciones
correspondientes.

## Resultados comprobados

Se documentaron los casos PJ-01 a PJ-18,
PC-01 a PC-09, PS-01 a PS-05 y PP-01.

Las pruebas incluyeron operaciones válidas,
rechazos esperados, concurrencia real y
comprobaciones posteriores a COMMIT y ROLLBACK.

## Limitaciones

ChatGPT proporcionó asistencia técnica y documental.

Las ejecuciones de PostgreSQL y la incorporación
de los archivos al repositorio fueron realizadas
por el integrante en su entorno local.

Este registro resume las consultas iterativas y
no pretende reproducir literalmente toda la
conversación mantenida durante el desarrollo.

## Ampliación de cobertura mediante IA

Solicitud reconstruida: diseñar pruebas adicionales para los escenarios identificados sin evidencia específica en la matriz de integridad, utilizando las operaciones SQL existentes y una base independiente.

Se proporcionaron a ChatGPT las definiciones del esquema, las operaciones y los scripts de preparación y devolución.

Como resultado se elaboró `pruebas/13_cobertura_adicional_jeank.sql`. Jean Carlos ejecutó el archivo mediante psql y verificó los ocho resultados adicionales.

La salida real confirmó los casos PJ-13 a PJ-18 y PC-08 a PC-09. No fue necesario modificar las operaciones ni el esquema existente.

La evidencia se conserva en `evidencias/Ejecucion_Jeank_Cobertura.md`.