-- ==================================
-- Labotario 3 - Dilan Andrey Sibaja Ugalde
-- 01_esquema - definicion del esquema fisico (Postgress)
--proceso de negocio: registro de una finca por un productor
--version de PostgreSQL utilizada: 18
-- ==================================
-- rutinas de sql
--rutina 1 total de fincas de un responsable
-- parametros: p_responsable_id = id del responsable al que queremos consultar
CREATE OR REPLACE FUNCTION total_fincas_de_responsable(p_responsable_id VARCHAR) RETURNS INTEGER LANGUAGE sql AS $$
SELECT COUNT(DISTINCT (productor_id, finca_id))::INTEGER
FROM registro_en_historial
WHERE responsable_id = p_responsable_id;
$$;