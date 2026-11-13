-- Operación P.L.A.T.A.N.O. — reportes corregidos.
-- Única fuente normativa: docs/reglas_negocio.md.
-- Los reportes históricos de matrícula (2, 4, 5) incluyen retirados;
-- los de rendimiento (6, 7, 9, 10) excluyen retirados (§4).

-- Consulta 1: Estudiantes activos por carrera (§1). Sin cambios de lógica.
select c.nombre as carrera, e.carnet, e.nombre as estudiante
from estudiante e
join carrera c on c.id_carrera = e.id_carrera
where e.activo = true
order by c.nombre, e.nombre, e.carnet;

-- Consulta 2: Catálogo completo, con grupos y matrículas históricas (§3).
-- DISTINCT cuenta cada grupo una vez, aunque tenga muchas matrículas.
select ca.nombre as carrera, cu.codigo, cu.nombre as curso,
       count(distinct g.id_grupo) as total_grupos,
       count(m.id_matricula) as total_matriculas
from carrera ca
join curso cu on cu.id_carrera = ca.id_carrera
left join grupo g on g.id_curso = cu.id_curso
left join matricula m on m.id_grupo = g.id_grupo
group by ca.id_carrera, cu.id_curso
order by ca.nombre, cu.codigo;

-- Consulta 3: Matrícula activa por grupo de 2026-1, control de cupo (§4).
-- Contar la PK evita la fila NULL del LEFT JOIN. Un retiro libera cupo.
select g.id_grupo, cu.codigo, cu.nombre as curso, g.cupo,
       count(m.id_matricula) as matriculados
from grupo g
join curso cu on cu.id_curso = g.id_curso
left join matricula m on m.id_grupo = g.id_grupo and m.estado = 'matriculado'
where g.ciclo = '2026-1'
group by g.id_grupo, cu.id_curso
order by g.id_grupo;

-- Consulta 4: Matrícula HISTÓRICA de INF-2001, todos los ciclos (§3).
-- Se conserva el alcance histórico; las reglas no ordenan limitar el ciclo.
select cu.codigo, cu.nombre, count(m.id_matricula) as matriculas
from curso cu
left join grupo g on g.id_curso = cu.id_curso
left join matricula m on m.id_grupo = g.id_grupo
where cu.codigo = 'INF-2001'
group by cu.id_curso;

-- Consulta 5: Popularidad histórica por identidad de curso, no nombre (§3).
select cu.codigo, cu.nombre as curso, count(m.id_matricula) as total_matriculas
from curso cu
left join grupo g on g.id_curso = cu.id_curso
left join matricula m on m.id_grupo = g.id_grupo
group by cu.id_curso
order by total_matriculas desc, cu.codigo;

-- Consulta 6: Rendimiento general (§4-5).
-- total_matriculas = evaluadas + pendientes + retiradas.
-- Tasa = aprobados / evaluadas; NULL significa que aún no hay evaluadas.
select count(*) as total_matriculas,
       count(*) filter (where estado = 'matriculado' and nota is not null) as total_evaluadas,
       count(*) filter (where estado = 'matriculado' and nota >= 70) as aprobados,
       count(*) filter (where estado = 'matriculado' and nota < 70) as reprobados,
       count(*) filter (where estado = 'matriculado' and nota is null) as pendientes,
       count(*) filter (where estado = 'retirado') as retiradas,
       round(100.0 * count(*) filter (where estado = 'matriculado' and nota >= 70)
             / nullif(count(*) filter (where estado = 'matriculado' and nota is not null), 0),
             1) as tasa_aprobacion
from matricula;

-- Consulta 7: Intentos aprobados en INF-2001, incluye 70 exacto (§4-5).
select e.carnet, e.nombre, m.nota
from matricula m
join grupo g on g.id_grupo = m.id_grupo
join curso cu on cu.id_curso = g.id_curso
join estudiante e on e.id_estudiante = m.id_estudiante
where cu.codigo = 'INF-2001'
  and m.estado = 'matriculado'
  and m.nota >= 70
order by e.nombre, e.carnet, m.id_matricula;

-- Consulta 8: Sin NINGUNA matrícula registrada, incluidos retiros.
-- Sin cambios de lógica: un retiro también es una matrícula histórica.
select e.carnet, e.nombre
from estudiante e
left join matricula m on m.id_estudiante = e.id_estudiante
where m.id_matricula is null
order by e.nombre, e.carnet;

-- Consulta 9: Habilitados para INF-2003 (§6).
-- No debe existir un requisito para el que falte una aprobación válida.
-- Cero requisitos habilita a todos; curso inexistente no habilita a nadie.
select e.carnet, e.nombre
from estudiante e
join curso cu on cu.codigo = 'INF-2003'
where not exists (
    select 1 from requisito r
    where r.id_curso = cu.id_curso
      and not exists (
          select 1 from matricula m
          join grupo g on g.id_grupo = m.id_grupo
          where m.id_estudiante = e.id_estudiante
            and g.id_curso = r.id_curso_requisito
            and m.estado = 'matriculado'
            and m.nota >= 70
      )
)
order by e.nombre, e.carnet;

-- Consulta 10: Total de créditos aprobados por estudiante (§3-5).
-- EXISTS cuenta cada curso una sola vez, sin multiplicar por requisitos
-- ni por intentos. Dos cursos de 4 créditos aportan 8, no SUM(DISTINCT 4).
select e.carnet, e.nombre, coalesce(sum(cu.creditos), 0) as creditos_aprobados
from estudiante e
left join curso cu on exists (
    select 1 from matricula m
    join grupo g on g.id_grupo = m.id_grupo
    where m.id_estudiante = e.id_estudiante
      and g.id_curso = cu.id_curso
      and m.estado = 'matriculado'
      and m.nota >= 70
)
group by e.id_estudiante
order by e.nombre, e.carnet;

-- Consulta 11: Profesores por identidad, incluyendo cero grupos (§2).
select p.cedula, p.nombre as profesor, count(g.id_grupo) as cantidad_grupos
from profesor p
left join grupo g on g.id_profesor = p.id_profesor and g.ciclo = '2026-1'
group by p.id_profesor
order by p.nombre, p.cedula;

-- Consulta 12: Requisitos por códigos de curso (§3, §6), sin cambios de lógica.
select cu.codigo as curso, cu.nombre as curso_nombre,
       req.codigo as requisito, req.nombre as requisito_nombre
from requisito r
join curso cu on cu.id_curso = r.id_curso
join curso req on req.id_curso = r.id_curso_requisito
order by cu.codigo, req.codigo;