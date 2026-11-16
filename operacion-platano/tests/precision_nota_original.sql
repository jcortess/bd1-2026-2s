-- Diagnóstico previo a cambiar numeric(5,1); únicamente datos temporales.
begin;
insert into matricula(id_matricula,id_estudiante,id_grupo,nota) values
(-801,6,2,-0.01),(-802,6,3,100.01),(-803,6,4,69.99);
select id_matricula,nota as valor_almacenado,nota>=70 as clasifica_aprobado
from matricula where id_matricula in (-801,-802,-803) order by id_matricula desc;
rollback;
