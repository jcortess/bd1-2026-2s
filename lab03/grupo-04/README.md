# Laboratorio 3 — Grupo 04

## Identificación

- IC-4301 Bases de Datos I; caso Alquileres El Roble.
- Integrantes: Carlos Andrés Hidalgo Gutiérrez y Brack Roxel Rivas Hernández.
- Rama: `grupo-04`; entrega: `lab03/grupo-04/`.

## Estado

Pasos 1 a 3 documentados: base, alcance y diseño lógico-físico previsto. La retroalimentación del Proyecto 1 ya fue identificada en las dos hojas de calificación aportadas. No se han implementado ni ejecutado scripts SQL; tampoco se presume aprobación docente del laboratorio.

## Proceso y continuidad

Se implementará la administración y consulta de autorizaciones de personas para clientes organización mediante PERSONA, CLIENTE, AUTORIZACION, FACULTAD y AUTORIZACION_FACULTAD. Corresponde a RN-01, RN-02 y los supuestos AS-01 a AS-03 aplicables. Una respuesta positiva de autorización no valida suspensión, garantía, certificación ni disponibilidad del equipo.

La base es el resultado normalizado de 29 relaciones, no únicamente la transformación inicial de 26. El subsistema conserva sus cinco relaciones y 19 atributos; no se rediseña el proyecto completo.

## Documentación

- [Base y pendientes](documentacion/base-proyecto-1.md).
- [Alcance y decisiones funcionales](documentacion/alcance-laboratorio.md).
- [Fragmento lógico con diagrama y cardinalidades](modelo/fragmento-modelo-logico.md).
- [Diccionario físico y matrices de trazabilidad](documentacion/diseno-fisico-y-trazabilidad.md).
- [Retroalimentación, uso de IA y validación pendiente](documentacion/retroalimentacion-y-uso-ia.md).

Los PDF, SVG y Excel originales no están publicados aquí. Los Excel no son un formato admitido para la entrega; se registra su retroalimentación en Markdown. El diagrama se incluye como código Mermaid dentro de un archivo .md; su representación visual debe revisarse en GitHub antes de entregar. No se ha generado un PDF ni se afirma haber validado visualmente los SVG originales.

## Próximo paso y pendientes

Implementar `sql/01_esquema.sql` conforme al diseño documentado y comprobarlo en una base PostgreSQL vacía. Después completar datos, consultas, rutinas, pruebas, evidencias y videos.

Faltan los cinco scripts obligatorios: `01_esquema.sql`, `02_datos.sql`, `03_consultas.sql`, `04_rutinas.sql` y `05_pruebas.sql`, dentro de sql/. No se agregan archivos vacíos ni se presenta la planificación como ejecución exitosa.

## Ejecución y entrega

Se prevé PostgreSQL 17. Preparación del entorno e instrucciones verificadas: pendientes. Orden exigido: esquema → datos → rutinas → consultas → pruebas.

Todos los cambios permanecerán en la carpeta del grupo. Solo se usarán extensiones permitidas; videos externos y enlaces individuales. El PR hacia main debe permanecer abierto, sin merge, con validaciones aprobadas. Se entregarán su enlace y el SHA completo final.

## IA

Perplexity apoya la documentación. El registro enlazado conserva prompts, propuestas y validación documental, sin atribuir al equipo comprobaciones técnicas que aún no realizó.
