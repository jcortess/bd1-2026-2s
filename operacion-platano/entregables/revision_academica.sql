\set ON_ERROR_STOP on
\pset pager off
-- Salida administrativa; datos descriptivos, nunca nuevas reglas.
-- No reconstruye la elegibilidad en fechas históricas: no hay fecha de
-- aprobación, de matrícula ni expediente externo en el modelo disponible.
\echo 'Matrículas no retiradas sin constancia actual de TODOS sus requisitos'
select m.id_matricula, e.carnet, e.nombre, cu.codigo as curso,
       req.codigo as requisito_sin_aprobacion_registrada
from matricula m
join estudiante e on e.id_estudiante = m.id_estudiante
join grupo g on g.id_grupo = m.id_grupo
join curso cu on cu.id_curso = g.id_curso
join requisito r on r.id_curso = cu.id_curso
join curso req on req.id_curso = r.id_curso_requisito
where m.estado = 'matriculado'
  and not exists (
      select 1 from matricula previa
      join grupo gp on gp.id_grupo = previa.id_grupo
      where previa.id_estudiante = e.id_estudiante
        and gp.id_curso = r.id_curso_requisito
        and previa.estado = 'matriculado' and previa.nota >= 70
  )
order by m.id_matricula, req.codigo;

\echo 'Grupos sin docente: temporalmente permitidos por reglas §2'
select g.id_grupo, cu.codigo, g.ciclo
from grupo g join curso cu on cu.id_curso = g.id_curso
where g.id_profesor is null order by g.id_grupo;

\echo 'Notas pendientes: incluye conflicto heredado de Irene'
select m.id_matricula, e.carnet, cu.codigo
from matricula m join estudiante e using (id_estudiante)
join grupo g using (id_grupo) join curso cu using (id_curso)
where m.estado = 'matriculado' and m.nota is null order by m.id_matricula;
