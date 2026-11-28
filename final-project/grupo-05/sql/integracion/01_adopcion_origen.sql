\set ON_ERROR_STOP on
BEGIN;

-- Ejecutar solo después de crear ADOPCION con su FK de etapa y la clave
-- UNIQUE (id_adopcion, animal_codigo). Un fallo deja el bloqueo previo intacto.
ALTER TABLE huellas.ingreso ADD CONSTRAINT ingreso_adopcion_origen_fk
    FOREIGN KEY (adopcion_origen_id, animal_codigo)
    REFERENCES huellas.adopcion (id_adopcion, animal_codigo);
ALTER TABLE huellas.ingreso DROP CONSTRAINT zz_ingreso_adopcion_pendiente;
-- Conserva ingreso_receptor, ingreso_detalle, ingreso_origen_adopcion y la
-- unicidad opcional. La temporalidad y el tipo de cierre se verifican en P03.

COMMIT;
