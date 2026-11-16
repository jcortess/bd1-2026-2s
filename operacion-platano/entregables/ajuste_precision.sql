-- Ampliación sin pérdida para la base de validación ya creada en esta sesión.
-- Secciones oficiales 4 y 5; evidencia 22 demuestra el redondeo incorrecto.
-- La instalación desde cero usa directamente NUMERIC en 01_schema.sql.
begin;
alter table matricula alter column nota type numeric;
select format_type(atttypid,atttypmod) as tipo_nota
from pg_attribute where attrelid='matricula'::regclass and attname='nota';
commit;
