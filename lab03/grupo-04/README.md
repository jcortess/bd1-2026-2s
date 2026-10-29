# Laboratorio 3 — Grupo 04

IC-4301 · Bases de Datos I · Alquileres El Roble

## Integrantes

- Carlos Andrés Hidalgo Gutiérrez.
- Brack Roxel Rivas Hernández.

## Proceso

Administración de autorizaciones para clientes organización: registro de personas autorizadas, asignación de facultades y consulta de vigencia.

El subsistema comprende PERSONA, CLIENTE, AUTORIZACION, FACULTAD y AUTORIZACION_FACULTAD, tomadas del modelo normalizado del Proyecto 1. No incluye la ejecución de reservas, contratos, entregas ni devoluciones.

## Archivos y documentación

- [Esquema SQL](sql/01_esquema.sql).
- [Preparación y ejecución](documentacion/ejecucion-esquema.md).
- [Alcance y reglas](documentacion/alcance-laboratorio.md).
- [Modelo lógico](modelo/fragmento-modelo-logico.md).
- [Diccionario, diseño físico y trazabilidad](documentacion/diseno-fisico-y-trazabilidad.md).
- [Documentos de referencia](documentacion/base-proyecto-1.md).
- [Revisión del Proyecto 1 y registro de IA](documentacion/retroalimentacion-y-uso-ia.md).

## Orden de ejecución

PostgreSQL 17. Orden de los scripts del laboratorio sobre una base vacía:

1. `sql/01_esquema.sql`.
2. `sql/02_datos.sql`.
3. `sql/04_rutinas.sql`.
4. `sql/03_consultas.sql`.
5. `sql/05_pruebas.sql`.

## Entrega

Rama `grupo-04`. Pull Request hacia `main`, abierto y sin merge.
