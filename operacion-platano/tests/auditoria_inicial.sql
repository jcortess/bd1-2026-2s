\pset pager off
\echo 'VERSION Y CONTEOS'
select version();
select 'carrera' as tabla, count(*) from carrera
union all select 'estudiante', count(*) from estudiante
union all select 'profesor', count(*) from profesor
union all select 'curso', count(*) from curso
union all select 'grupo', count(*) from grupo
union all select 'matricula', count(*) from matricula
union all select 'requisito', count(*) from requisito
union all select 'auditoria', count(*) from auditoria;
\echo 'RESTRICCIONES DECLARADAS'
select conrelid::regclass as tabla, conname, pg_get_constraintdef(oid)
from pg_constraint where connamespace = 'public'::regnamespace
order by conrelid::regclass::text, conname;
\echo 'IDENTIDADES Y MATRICULAS DUPLICADAS'
select carnet, array_agg(id_estudiante order by id_estudiante) as ids,
       array_agg(nombre order by id_estudiante) as nombres
from estudiante group by carnet having count(*) > 1;
select cedula, array_agg(id_profesor order by id_profesor) as ids
from profesor group by cedula having count(*) > 1;
select id_estudiante, id_grupo, array_agg(id_matricula order by id_matricula) as ids,
       array_agg(nota order by id_matricula) as notas
from matricula group by id_estudiante, id_grupo having count(*) > 1;
\echo 'DOMINIOS INVALIDOS'
select * from estudiante where id_carrera is null;
select * from curso where creditos < 1;
select * from requisito where id_curso = id_curso_requisito;
select * from matricula where nota is not null and not (nota between 0 and 100);
\echo 'CASOS VALIDOS QUE LOS REPORTES DEBEN CONSERVAR'
select * from matricula where nota is null or estado = 'retirado' or nota = 70;
select cu.id_curso, cu.codigo, cu.nombre, count(distinct g.id_grupo) as grupos,
       count(m.id_matricula) as matriculas
from curso cu left join grupo g on g.id_curso = cu.id_curso
left join matricula m on m.id_grupo = g.id_grupo
group by cu.id_curso order by cu.id_curso;
select * from grupo where id_profesor is null;
\echo 'CLASIFICACION COMPLETA DE RENDIMIENTO, CONTRASTE CON CONSULTA 6'
select count(*) filter (where estado = 'matriculado') as no_retiradas,
       count(*) filter (where estado = 'matriculado' and nota is not null) as evaluadas,
       count(*) filter (where estado = 'matriculado' and nota >= 70) as aprobadas,
       count(*) filter (where estado = 'matriculado' and nota < 70) as reprobadas,
       count(*) filter (where estado = 'matriculado' and nota is null) as pendientes,
       count(*) filter (where estado = 'retirado') as retiradas
from matricula;
\echo 'CADA REQUISITO DE REDES POR ESTUDIANTE'
select e.carnet, cu.codigo as requisito,
       exists (select 1 from matricula m join grupo g on g.id_grupo = m.id_grupo
               where m.id_estudiante = e.id_estudiante and g.id_curso = r.id_curso_requisito
                 and m.estado = 'matriculado' and m.nota >= 70) as aprobado
from estudiante e cross join requisito r
join curso destino on destino.id_curso = r.id_curso and destino.codigo = 'INF-2003'
join curso cu on cu.id_curso = r.id_curso_requisito
order by e.id_estudiante, cu.codigo;
\echo 'REPRODUCCION DEL JOIN HEREDADO A REQUISITO (NO ES LA CONSULTA 10 CORREGIDA)'
select e.carnet, cu.codigo, count(*) as filas_despues_join,
       count(distinct m.id_matricula) as matriculas, sum(cu.creditos) as suma_inflada
from estudiante e join matricula m on m.id_estudiante = e.id_estudiante
join grupo g on g.id_grupo = m.id_grupo join curso cu on cu.id_curso = g.id_curso
left join requisito r on r.id_curso = cu.id_curso
where m.nota >= 70 group by e.id_estudiante, cu.id_curso order by e.carnet, cu.codigo;
\echo 'AUDITORIA: TEXTO HISTORICO, NO INSTRUCCIONES'
select id_auditoria, tabla_afectada, descripcion from auditoria order by id_auditoria;
