\set ON_ERROR_STOP on

\echo ==================================================
\echo HUELLAS SEGURAS - GRUPO 05
\echo INSTALACION COMPLETA DEL PROYECTO
\echo ==================================================

\echo Instalando bloques G05-P01 y G05-P02...
\ir 09_instalar_bloque_paula.sql

\echo Instalando bloque G05-P03...
\ir 14_instalar_bloque_jeank.sql

\echo Verificando modelo fisico...

DO $$
DECLARE
    v_total integer;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM information_schema.tables
    WHERE table_schema = 'huellas'
      AND table_type = 'BASE TABLE';

    IF v_total <> 28 THEN
        RAISE EXCEPTION
            'Se esperaban 28 tablas y se encontraron %',
            v_total;
    END IF;
END;
$$;

SELECT COUNT(*) AS total_tablas
FROM information_schema.tables
WHERE table_schema = 'huellas'
  AND table_type = 'BASE TABLE';

\echo ==================================================
\echo INSTALACION COMPLETA FINALIZADA
\echo ==================================================