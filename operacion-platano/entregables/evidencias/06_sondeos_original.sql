\set ON_ERROR_STOP on
\echo 'REDONDEO HEREDADO: puede convertir reprobacion en aprobacion y ocultar fuera de rango'
select n as entrada, n::numeric(5,1) as almacenada from (values (69.99::numeric), (100.04), (-0.04)) as t(n);
\echo 'DEFECTOS DE ESQUEMA: inserciones que actualmente acepta (solo prueba, ROLLBACK)'
begin;
insert into estudiante (id_estudiante,carnet,nombre,id_carrera,fecha_ingreso,activo)
values (-9101,'2021001','Duplicado inactivo',null,'2026-01-01',false);
insert into matricula (id_matricula,id_estudiante,id_grupo,nota)
values (-9101,1,1,101),(-9102,1,2,-1),(-9103,1,6,69.99);
select id_matricula,nota from matricula where id_matricula < 0 order by id_matricula;
rollback;
\echo 'MATRICULAS CON REQUISITOS ACTUALMENTE INCOMPLETOS (no hay fechas para reconstruir admision)'
select e.carnet, cu.codigo, m.id_matricula, m.nota
from matricula m join estudiante e using(id_estudiante)
join grupo g using(id_grupo) join curso cu using(id_curso)
where m.estado='matriculado' and exists (
select 1 from requisito r where r.id_curso=cu.id_curso and not exists (
select 1 from matricula previa join grupo gp on gp.id_grupo=previa.id_grupo
where previa.id_estudiante=e.id_estudiante and gp.id_curso=r.id_curso_requisito
and previa.nota>=70 and previa.estado='matriculado')) order by m.id_matricula;