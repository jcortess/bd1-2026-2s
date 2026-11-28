
\set ON_ERROR_STOP on

\echo ==================================================
\echo HUELLAS SEGURAS - GRUPO 05
\echo INSTALACION DEL BLOQUE 
\echo ==================================================

\echo [1/4] Creando modelo fisico...
\ir 10_jeank_esquema.sql

\echo [2/4] Instalando operaciones y validaciones...
\ir 11_jeank_operaciones.sql

\echo [3/4] Insertando datos ficticios...
\ir 12_jeank_datos.sql

\echo [4/4] Instalando vistas y consultas...
\ir 13_jeank_consultas.sql

\echo ==================================================
\echo INSTALACION DEL BLOQUE COMPLETADA
\echo ==================================================

SELECT COUNT(*) AS total_tablas
FROM information_schema.tables
WHERE table_schema = 'huellas'
  AND table_type = 'BASE TABLE';
