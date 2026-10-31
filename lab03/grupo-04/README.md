# Laboratorio 3 — Grupo 04

IC-4301 · Bases de Datos I · Alquileres El Roble

## Integrantes

- Carlos Andrés Hidalgo Gutiérrez.
- Brack Roxel Rivas Hernández.

## Proceso

Administración de autorizaciones para clientes organización: personas autorizadas, facultades y vigencia. Comprende PERSONA, CLIENTE, AUTORIZACION, FACULTAD y AUTORIZACION_FACULTAD del modelo normalizado del Proyecto 1. No ejecuta reservas, contratos, entregas ni devoluciones.

## Archivos y documentación

- [Scripts SQL](sql/).
- [Preparación del entorno](documentacion/ejecucion-esquema.md).
- [Rutinas, consultas y pruebas](documentacion/rutinas-y-pruebas.md).
- [Alcance y reglas](documentacion/alcance-laboratorio.md).
- [Modelo lógico](modelo/fragmento-modelo-logico.md).
- [Diccionario y trazabilidad](documentacion/diseno-fisico-y-trazabilidad.md).
- [Referencias](documentacion/base-proyecto-1.md).
- [Revisión y registro de IA](documentacion/retroalimentacion-y-uso-ia.md).

## Ejecución

PostgreSQL 17, base vacía e identificadores explícitos. Orden:

1. `sql/01_esquema.sql`.
2. `sql/02_datos.sql`.
3. `sql/04_rutinas.sql`.
4. `sql/03_consultas.sql`.
5. `sql/05_pruebas.sql`.

## Entrega

Rama `grupo-04`. Pull Request hacia `main`, abierto y sin merge.
