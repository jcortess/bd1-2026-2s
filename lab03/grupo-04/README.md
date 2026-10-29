# Laboratorio 3 — Grupo 04

## Identificación

- Curso: IC-4301 Bases de Datos I.
- Caso: Alquileres El Roble.
- Integrantes: Carlos Andrés Hidalgo Gutiérrez y Brack Roxel Rivas Hernández.
- Rama: `grupo-04`.
- Carpeta de entrega: `lab03/grupo-04/`.

## Estado del trabajo

Preparación documental y definición del alcance. Todavía no existe una implementación SQL ejecutable ni evidencia de pruebas. La revisión del profesor sigue pendiente de identificación; no se presume aprobación docente.

## Continuidad con el Proyecto 1

El modelo inicial tiene 26 relaciones y la normalización produce el modelo final de 29, al que corresponden el diccionario y la matriz. El laboratorio implementará un subconjunto coherente de ese resultado, sin sustituirlo por un diseño nuevo.

- [Base documental y pendientes](documentacion/base-proyecto-1.md).
- [Alcance, reglas y decisiones del subsistema](documentacion/alcance-laboratorio.md).

Los PDF y SVG aportados en la planificación no están incorporados al repositorio. Su inventario no equivale a haberlos publicado.

## Proceso seleccionado

Administración y consulta de autorizaciones de personas para clientes organización: registrar una autorización y sus facultades, conservar su vigencia y consultar si una persona posee una facultad vigente para una organización en una fecha explícita.

Se implementarán PERSONA, CLIENTE, AUTORIZACION, FACULTAD y AUTORIZACION_FACULTAD. La base funcional es RN-01, RN-02, AS-02 y AS-03; AS-01 sirve de apoyo para representar tipos de cliente. El documento de alcance distingue reglas originales, decisiones adicionales y limitaciones.

Una respuesta positiva de autorización no equivale a aprobar una reserva, entrega o devolución: no valida suspensión, garantía, certificación ni disponibilidad del equipo.

## Secuencia y avance

1. Preparación documental: realizada; retroalimentación del profesor pendiente.
2. Alcance, exclusiones y decisiones funcionales: documentados; sujetos a ajustes trazables si aparece retroalimentación.
3. Próximo paso: fragmento lógico y matriz de trazabilidad lógica-física.
4. Después: esquema, datos, rutinas, consultas y pruebas.
5. Cierre: ejecución limpia, evidencias, videos individuales y PR de entrega.

## Entregables pendientes

- Fragmento lógico y matriz lógica-física.
- `sql/01_esquema.sql`.
- `sql/02_datos.sql`.
- `sql/03_consultas.sql`.
- `sql/04_rutinas.sql`.
- `sql/05_pruebas.sql`.
- Evidencias identificadas, instrucciones verificadas y videos individuales.

No se agregan scripts vacíos o simulados.

## Ejecución y entrega

Se prevé PostgreSQL 17. El entorno y sus instrucciones quedan pendientes de verificación.

Orden exigido: `01_esquema.sql` → `02_datos.sql` → `04_rutinas.sql` → `03_consultas.sql` → `05_pruebas.sql`.

Todos los cambios permanecerán en esta carpeta. Los diagramas se exportarán a PDF o imagen permitida; los videos se alojarán externamente. El PR hacia main debe permanecer abierto y con validaciones aprobadas; no se realizará merge. Se entregarán enlace del PR y SHA completo del commit final.

## Uso de IA

Perplexity se utilizó para apoyar la planificación y contrastar el alcance con los documentos aportados. El equipo debe revisar y comprender cada decisión, conservar prompts relevantes y validar la futura implementación. En esta etapa no se han ejecutado pruebas de base de datos.
