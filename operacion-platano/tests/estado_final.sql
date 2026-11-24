\pset pager off
\echo 'CONTEOS TRAS ROLLBACK: 3,12,3,8,8,17,4,4'
select 'carrera' as tabla, count(*) from carrera
union all select 'estudiante', count(*) from estudiante
union all select 'profesor', count(*) from profesor
union all select 'curso', count(*) from curso
union all select 'grupo', count(*) from grupo
union all select 'matricula', count(*) from matricula
union all select 'requisito', count(*) from requisito
union all select 'auditoria', count(*) from auditoria;
\echo 'RESIDUOS SINTETICOS: CERO'
select sum(cantidad) as filas_sinteticas from (
select count(*) as cantidad from carrera where id_carrera<0
union all select count(*) from estudiante where id_estudiante<0
union all select count(*) from profesor where id_profesor<0
union all select count(*) from curso where id_curso<0
union all select count(*) from grupo where id_grupo<0
union all select count(*) from matricula where id_matricula<0
union all select count(*) from requisito where id_requisito<0
union all select count(*) from auditoria where id_auditoria<0
) residuos;
\echo 'TIPO DEFINITIVO DE NOTA: numeric SIN ESCALA FIJA'
select format_type(atttypid,atttypmod) as tipo_nota
from pg_attribute where attrelid='matricula'::regclass and attname='nota';
\echo 'EXPEDIENTES HEREDADOS: MATRICULAS CON REQUISITOS SIN APROBACION REGISTRADA'
-- Esto no reconstruye el momento de admisión: no hay fechas de calificación.
-- Un resultado indica falta de respaldo actual, no permiso para inventar notas
-- previas ni anular la nota existente. La consulta 9 verifica elegibilidad actual.
select e.carnet, cu.codigo as curso_matriculado, m.estado, m.nota,
       previo.codigo as requisito_sin_respaldo
from matricula m
join estudiante e on e.id_estudiante=m.id_estudiante
join grupo g on g.id_grupo=m.id_grupo
join curso cu on cu.id_curso=g.id_curso
join requisito r on r.id_curso=cu.id_curso
join curso previo on previo.id_curso=r.id_curso_requisito
where m.estado='matriculado' and not exists (
    select 1 from matricula anterior join grupo ga on ga.id_grupo=anterior.id_grupo
    where anterior.id_estudiante=m.id_estudiante
      and ga.id_curso=r.id_curso_requisito
      and anterior.estado='matriculado' and anterior.nota>=70
)
order by e.carnet,cu.codigo,previo.codigo;
\echo 'RELACIONES PROTEGIDAS POR CLAVES FORANEAS'
select conrelid::regclass as tabla,pg_get_constraintdef(oid) as referencia
from pg_constraint where contype='f' and connamespace='public'::regnamespace
order by conrelid::regclass::text,conname;
\echo 'NULABILIDAD: ESTUDIANTE CARRERA NO; GRUPO PROFESOR SI; MATRICULA NOTA SI'
select table_name,column_name,is_nullable from information_schema.columns
where table_schema='public' and (table_name,column_name) in
(('estudiante','id_carrera'),('grupo','id_profesor'),('matricula','nota'))
order by table_name,column_name;
