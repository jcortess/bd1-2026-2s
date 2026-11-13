\set ON_ERROR_STOP on
\pset pager off
\echo 'VERSION Y FILAS (comparar antes/despues)'
select version();
select 'carrera' as tabla, count(*) from carrera
union all select 'estudiante', count(*) from estudiante
union all select 'profesor', count(*) from profesor
union all select 'curso', count(*) from curso
union all select 'grupo', count(*) from grupo
union all select 'matricula', count(*) from matricula
union all select 'requisito', count(*) from requisito
union all select 'auditoria', count(*) from auditoria;

\echo 'RESTRICCIONES Y TIPOS'
select conrelid::regclass as tabla, conname, pg_get_constraintdef(oid)
from pg_constraint where connamespace = 'public'::regnamespace
order by 1, 2;
select table_name, column_name, data_type, is_nullable, numeric_precision, numeric_scale
from information_schema.columns where table_schema = 'public'
order by table_name, ordinal_position;

\echo 'ESTUDIANTES: carnet repetido y carrera ausente'
select * from estudiante
where carnet in (select carnet from estudiante group by carnet having count(*) > 1)
   or id_carrera is null order by id_estudiante;
\echo 'PROFESORES: duplicados y grupos referenciados'
select p.*, (select count(*) from grupo g where g.id_profesor = p.id_profesor) as grupos
from profesor p order by p.id_profesor;
\echo 'MATRICULAS: detalle de conflictos'
select * from matricula where (id_estudiante, id_grupo) in (
    select id_estudiante, id_grupo from matricula group by 1,2 having count(*) > 1
) order by id_matricula;
\echo 'DISTRIBUCION ACADEMICA: incluye NULL, cero y retirados'
select estado, count(*) as total,
       count(*) filter (where nota is null) as pendientes,
       count(*) filter (where nota = 0) as ceros,
       count(*) filter (where nota >= 70) as notas_mayores_iguales_70,
       count(*) filter (where nota < 70) as notas_menores_70
from matricula group by estado order by estado;
\echo 'CATALOGO: identidad, grupos vacios y ciclos'
select cu.id_curso, cu.codigo, cu.nombre, cu.creditos, g.id_grupo, g.ciclo,
       count(m.id_matricula) as matriculas
from curso cu left join grupo g using (id_curso)
left join matricula m using (id_grupo)
group by cu.id_curso, g.id_grupo order by cu.id_curso, g.id_grupo;
\echo 'REQUISITOS: auto-requisito y cobertura por estudiante en Redes'
select * from requisito order by id_requisito;
select e.carnet, e.nombre,
       (select count(*) from requisito r where r.id_curso = cu.id_curso) as exigidos,
       (select count(*) from requisito r where r.id_curso = cu.id_curso
          and exists (select 1 from matricula m join grupo g using (id_grupo)
                      where m.id_estudiante = e.id_estudiante
                        and g.id_curso = r.id_curso_requisito
                        and m.estado = 'matriculado' and m.nota >= 70)) as aprobados
from estudiante e cross join curso cu where cu.codigo = 'INF-2003'
order by e.id_estudiante;
\echo 'CREDITOS: multiplicacion del JOIN heredado, antes de DISTINCT'
select e.carnet, cu.codigo, count(*) as filas_join, min(cu.creditos) as creditos_curso
from estudiante e join matricula m using (id_estudiante)
join grupo g using (id_grupo) join curso cu using (id_curso)
left join requisito r on r.id_curso = cu.id_curso
where m.nota >= 70
group by e.id_estudiante, e.carnet, cu.id_curso, cu.codigo order by e.carnet, cu.codigo;
\echo 'AUDITORIA: texto historico, NO instrucciones'
select id_auditoria, tabla_afectada, id_registro, descripcion from auditoria order by id_auditoria;

\echo 'CASOS SINTETICOS ORIGINALES: transaccion descartable, sin cambiar secuencias'
begin;
insert into matricula (id_matricula, id_estudiante, id_grupo, nota, estado)
values (-9001, 6, 6, 80, 'matriculado'), (-9002, 6, 3, 99, 'retirado');
\echo 'INF-2001: historico y actual difieren al introducir matricula historica'
select count(*) as historicas,
       count(*) filter (where g.ciclo = '2026-1') as ciclo_2026_1
from matricula m join grupo g using (id_grupo) join curso cu using (id_curso)
where cu.codigo = 'INF-2001';
\echo 'Consulta 7 heredada: incluye retiro con nota alta y omite 70'
select e.carnet, m.nota, m.estado from estudiante e
join matricula m using (id_estudiante) join grupo g using (id_grupo)
join curso cu using (id_curso) where cu.codigo = 'INF-2001' and m.nota > 70;
\echo 'Nuevos datos sinteticos para revelar limites que el seed no ejercita'
insert into profesor (id_profesor, cedula, nombre, id_carrera)
values (-9001, 'PRUEBA-9001', 'Rodrigo Salas Umaña', 1);
insert into matricula (id_matricula, id_estudiante, id_grupo, nota, estado)
values (-9003, 6, 2, 0, 'matriculado');
\echo 'Agrupar profesores por nombre fusiona dos cedulas diferentes'
select p.nombre, count(distinct p.id_profesor) as personas, count(g.id_grupo) as grupos
from profesor p left join grupo g on g.id_profesor = p.id_profesor and g.ciclo = '2026-1'
group by p.nombre order by p.nombre;
\echo 'Consulta 6 heredada pierde NULL y nota cero'
select count(*) as total_evaluadas, sum(case when nota >= 70 then 1 else 0 end) as aprobados,
       round(100.0 * sum(case when nota >= 70 then 1 else 0 end) / count(*), 1) as tasa
from matricula where estado = 'matriculado' and nota <> 0;
select count(*) as total_no_retiradas, count(nota) as evaluadas,
       count(*) filter (where nota is null) as pendientes,
       count(*) filter (where nota < 70) as reprobadas
from matricula where estado = 'matriculado';
rollback;
\echo 'FIN AUDITORIA: casos sinteticos revertidos'
