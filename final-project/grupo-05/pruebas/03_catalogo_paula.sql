\set ON_ERROR_STOP on
SET search_path=huellas,pg_catalog;
-- Verificación reproducible de referencias, rutas de escritura y protección clínica.
DO $$
DECLARE v_tabla text;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY['reporte','reporte_animal','evaluacion_salud','diagnostico',
        'diagnostico_revision','cambio_disponibilidad','solicitud_adopcion','solicitud_animal',
        'evento_solicitud','compatibilidad_animal_hogar'] LOOP
        IF to_regclass('huellas.'||v_tabla) IS NULL THEN RAISE EXCEPTION 'Falta relación %',v_tabla; END IF;
        IF NOT has_table_privilege('huellas_g05_operador','huellas.'||v_tabla,'SELECT')
           OR has_table_privilege('huellas_g05_operador','huellas.'||v_tabla,'INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') THEN
            RAISE EXCEPTION 'Permisos incompatibles en %',v_tabla;
        END IF;
    END LOOP;
    IF EXISTS (SELECT FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace
        WHERE n.nspname='huellas' AND NOT c.convalidated) THEN
        RAISE EXCEPTION 'Hay restricciones sin validar';
    END IF;
    IF EXISTS (SELECT FROM ingreso i WHERE NOT EXISTS (SELECT FROM evaluacion_salud e
        WHERE e.ingreso_id=i.id_ingreso AND e.tipo_evaluacion='INICIAL')) THEN
        RAISE EXCEPTION 'Ingreso sin inicial';
    END IF;
    IF has_function_privilege('huellas_g05_operador',
        'huellas._exigir_compatibilidad(bigint,text,bigint,timestamptz)','EXECUTE') THEN
        RAISE EXCEPTION 'El consumidor privado quedó expuesto';
    END IF;
END $$;
SELECT c.relname AS relacion,count(a.attname) AS atributos,
    has_table_privilege('huellas_g05_operador',c.oid,'SELECT') AS operador_lee,
    has_table_privilege('huellas_g05_operador',c.oid,'INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') AS operador_escritura_directa
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped
WHERE n.nspname='huellas' AND c.relkind='r' GROUP BY c.oid,c.relname ORDER BY c.relname;
SELECT conrelid::regclass AS relacion,conname,pg_get_constraintdef(oid) AS definicion,convalidated
FROM pg_constraint WHERE connamespace='huellas'::regnamespace ORDER BY conrelid::regclass::text,conname;
SELECT tgrelid::regclass AS relacion,tgname,pg_get_triggerdef(oid) AS definicion
FROM pg_trigger WHERE NOT tgisinternal AND tgrelid IN
    (SELECT oid FROM pg_class WHERE relnamespace='huellas'::regnamespace) ORDER BY tgname;
