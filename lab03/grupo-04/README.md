# Laboratorio 3 — Grupo 04

## Identificación

- Curso: IC-4301 Bases de Datos I.
- Caso: Alquileres El Roble.
- Integrantes: Carlos Andrés Hidalgo Gutiérrez y Brack Roxel Rivas Hernández.
- Rama de trabajo: `grupo-04`.
- Carpeta de entrega: `lab03/grupo-04/`.

## Estado del trabajo

Etapa inicial de preparación documental. Este documento no constituye todavía el informe final ni una implementación ejecutable.

El laboratorio continuará el Proyecto 1 mediante la implementación en PostgreSQL de un proceso completo y acotado. No se implementará automáticamente la totalidad del modelo.

## Documentos de partida

Consultar el [registro de documentos y pendientes](documentacion/base-proyecto-1.md). Los archivos fuente fueron aportados en la conversación de planificación; este commit no incorpora sus PDF ni sus diagramas al repositorio.

El modelo relacional inicial contiene 26 relaciones. La normalización produce el modelo final de 29 relaciones, al que corresponden el diccionario y la matriz de trazabilidad. La selección física deberá partir de ese resultado final y documentar cualquier corrección.

## Alcance por confirmar

Se propone el proceso de administración y consulta de autorizaciones de personas para clientes organización, mediante PERSONA, CLIENTE, AUTORIZACION, FACULTAD y AUTORIZACION_FACULTAD. Esta selección es una propuesta de planificación, no una aprobación del profesor ni un esquema físico definitivo.

Antes de implementar deben identificarse las observaciones del profesor, confirmar el alcance y documentar las decisiones de vigencia y validación.

## Secuencia de trabajo

1. Identificar la retroalimentación del profesor y registrar las correcciones aplicables.
2. Confirmar proceso, alcance, exclusiones y reglas cubiertas.
3. Preparar fragmento lógico y matriz de trazabilidad lógica-física.
4. Implementar esquema y datos representativos.
5. Implementar dos funciones, un procedimiento y la técnica adicional justificada.
6. Preparar consultas y pruebas válidas e inválidas.
7. Repetir la ejecución completa sobre una base vacía.
8. Completar evidencias, documentación y videos individuales.
9. Presentar el PR hacia main, mantenerlo abierto y entregar su enlace y SHA final.

## Entregables pendientes

- Fragmento del modelo lógico.
- Matriz de trazabilidad lógica-física.
- `sql/01_esquema.sql`.
- `sql/02_datos.sql`.
- `sql/03_consultas.sql`.
- `sql/04_rutinas.sql`.
- `sql/05_pruebas.sql`.
- Evidencias identificadas y enlaces a videos individuales.

Los scripts se crearán con contenido real en sus etapas correspondientes; no se agregan archivos vacíos ni scripts simulados para aparentar una entrega completa.

## Condiciones de ejecución y entrega

Se prevé usar PostgreSQL 17 para alinearse con la validación automática. Las instrucciones definitivas del entorno quedan pendientes de implementación y verificación.

Orden exigido: `01_esquema.sql` → `02_datos.sql` → `04_rutinas.sql` → `03_consultas.sql` → `05_pruebas.sql`.

Todos los cambios deben permanecer en la carpeta del grupo. Solo se entregarán formatos permitidos por el enunciado. Los SVG de origen deberán exportarse a PDF o imagen admitida antes de incorporarlos. Los videos se alojarán externamente. No se realizará el merge del PR.

## Uso de IA y validación

Se utilizó Perplexity como apoyo para organizar esta planificación. El equipo deberá revisar y validar las propuestas antes de incorporarlas a la implementación y conservar los prompts relevantes. No se han ejecutado scripts ni pruebas de base de datos en esta etapa.
