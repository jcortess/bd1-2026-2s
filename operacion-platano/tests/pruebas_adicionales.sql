-- Ejecutar con tests/ejecutar_pruebas.ps1 (genera las vistas de los reportes).
-- Todo queda dentro de una transacción con ROLLBACK. IDs negativos explícitos
-- evitan que las pruebas consuman secuencias de la base de demostración.
create temp table resultados_pruebas (nombre text primary key);
create function pg_temp.comprobar(condicion boolean, nombre text) returns void
language plpgsql as $$
begin
    if condicion is distinct from true then
        raise exception 'FALLO: %', nombre;
    end if;
    insert into resultados_pruebas values (nombre);
end;
$$;
create function pg_temp.rechazar(comando text, codigo text, nombre text) returns void
language plpgsql as $$
declare recibido text;
begin
    begin
        execute comando;
    exception when others then
        get stacked diagnostics recibido = returned_sqlstate;
    end;
    perform pg_temp.comprobar(recibido = codigo, nombre || ' (SQLSTATE ' || codigo || ')');
end;
$$;

\echo 'A. Reglas estructurales y conservación del seed'
select pg_temp.comprobar((select count(*) = 8 from information_schema.tables where table_schema = 'public'), 'A01 ocho tablas públicas');
select pg_temp.comprobar(not exists (select carnet from estudiante group by carnet having count(*) > 1), 'A02 carnet único');
select pg_temp.comprobar(not exists (select cedula from profesor group by cedula having count(*) > 1), 'A03 cédula única');
select pg_temp.comprobar(not exists (select 1 from matricula group by id_estudiante, id_grupo having count(*) > 1), 'A04 matrícula única');
select pg_temp.comprobar(not exists (select 1 from curso where creditos < 1), 'A05 créditos válidos');
select pg_temp.comprobar(not exists (select 1 from matricula where nota < 0 or nota > 100), 'A06 notas válidas');
select pg_temp.comprobar(not exists (select 1 from requisito where id_curso = id_curso_requisito), 'A07 sin auto-requisitos');
select pg_temp.comprobar(not exists (select 1 from estudiante where id_carrera is null), 'A08 carrera obligatoria');
select pg_temp.comprobar((select count(*) = 12 from estudiante), 'A09 se conservan doce estudiantes');
select pg_temp.comprobar((select count(*) = 17 from matricula), 'A10 diecisiete matrículas tras consolidar un duplicado');
select pg_temp.comprobar((select count(*) = 10 from auditoria), 'A11 cuatro eventos históricos y seis saneamientos');
select pg_temp.comprobar((select nota is null from matricula where id_matricula = 14), 'A12 conflicto de Irene pendiente');
select pg_temp.comprobar((select count(*) = 1 from matricula where id_matricula = 18 and id_estudiante = 12), 'A13 IDs posteriores al duplicado conservados');
select pg_temp.comprobar((select last_value = 18 from matricula_id_matricula_seq), 'A14 secuencia sincronizada');
select pg_temp.comprobar((select count(*) = 4 from auditoria where id_auditoria <= 4), 'A15 auditoría histórica conservada');

\echo 'B. Rechazos de INSERT y UPDATE: se valida SQLSTATE, no solo un error cualquiera'
select pg_temp.rechazar($q$insert into estudiante values (-101,'2021001','Duplicado',1,'2026-01-01',false)$q$, '23505', 'B01 carnet repetido incluso inactivo');
select pg_temp.rechazar($q$update estudiante set carnet = '2021001' where id_estudiante = 2$q$, '23505', 'B02 carnet duplicado por UPDATE');
select pg_temp.rechazar($q$update estudiante set id_carrera = null where id_estudiante = 1$q$, '23502', 'B03 carrera NULL');
select pg_temp.rechazar($q$update estudiante set id_carrera = -999 where id_estudiante = 1$q$, '23503', 'B04 carrera inexistente');
select pg_temp.rechazar($q$insert into profesor values (-101,'1-1111-1111','Alias',1)$q$, '23505', 'B05 profesor duplicado');
select pg_temp.rechazar($q$update profesor set cedula = '1-1111-1111' where id_profesor = 2$q$, '23505', 'B06 cédula duplicada por UPDATE');
select pg_temp.rechazar($q$insert into matricula values (-101,1,1,90,'matriculado')$q$, '23505', 'B07 matrícula duplicada activa');
select pg_temp.rechazar($q$insert into matricula values (-101,1,1,null,'retirado')$q$, '23505', 'B08 duplicado retirado también prohibido');
select pg_temp.rechazar($q$update curso set creditos = 0 where id_curso = 8$q$, '23514', 'B09 cero créditos');
select pg_temp.rechazar($q$update curso set creditos = -1 where id_curso = 8$q$, '23514', 'B10 créditos negativos');
select pg_temp.rechazar($q$update curso set creditos = null where id_curso = 8$q$, '23502', 'B11 créditos NULL');
select pg_temp.rechazar($q$update matricula set nota = -1 where id_matricula = 1$q$, '23514', 'B12 nota negativa');
select pg_temp.rechazar($q$update matricula set nota = 101 where id_matricula = 1$q$, '23514', 'B13 nota mayor de cien');
select pg_temp.rechazar($q$update matricula set nota = -0.0001 where id_matricula = 1$q$, '23514', 'B14 negativo pequeño no se redondea a cero');
select pg_temp.rechazar($q$update matricula set nota = 100.0001 where id_matricula = 1$q$, '23514', 'B15 exceso pequeño no se redondea a cien');
select pg_temp.rechazar($q$update matricula set nota = 'NaN'::numeric where id_matricula = 1$q$, '23514', 'B16 NaN inválido');
select pg_temp.rechazar($q$update matricula set nota = 'Infinity'::numeric where id_matricula = 1$q$, '23514', 'B17 infinito inválido');
select pg_temp.rechazar($q$update matricula set nota = '-Infinity'::numeric where id_matricula = 1$q$, '23514', 'B18 infinito negativo inválido');
select pg_temp.rechazar($q$insert into requisito values (-101,4,4)$q$, '23514', 'B19 auto-requisito por INSERT');
select pg_temp.rechazar($q$update requisito set id_curso_requisito = id_curso where id_requisito = 1$q$, '23514', 'B20 auto-requisito por UPDATE');
select pg_temp.rechazar($q$insert into requisito values (-101,2,1)$q$, '23505', 'B21 requisito duplicado');
select pg_temp.rechazar($q$insert into requisito values (-101,-999,1)$q$, '23503', 'B22 FK curso requerido');
select pg_temp.rechazar($q$insert into requisito values (-101,2,-999)$q$, '23503', 'B23 FK requisito');
select pg_temp.rechazar($q$insert into matricula values (-101,-999,1,70,'matriculado')$q$, '23503', 'B24 FK estudiante');
select pg_temp.rechazar($q$insert into matricula values (-101,1,-999,70,'matriculado')$q$, '23503', 'B25 FK grupo');
select pg_temp.rechazar($q$update grupo set id_profesor = -999 where id_grupo = 8$q$, '23503', 'B26 FK profesor opcional pero existente');

\echo 'C. Los doce reportes sobre datos saneados'
select pg_temp.comprobar((select count(*) = 12 from prueba_consulta_1), 'C01 activos con carrera visibles');
select pg_temp.comprobar((select count(*) = 8 from prueba_consulta_2), 'C02 catálogo de ocho cursos');
select pg_temp.comprobar((select total_grupos = 0 and total_matriculas = 0 from prueba_consulta_2 where codigo = 'IND-1001'), 'C03 curso sin grupos visible con ceros');
select pg_temp.comprobar((select total_grupos = 1 and total_matriculas = 0 from prueba_consulta_2 where codigo = 'INF-4001'), 'C04 curso con grupo vacío');
select pg_temp.comprobar((select total_grupos = 2 and total_matriculas = 3 from prueba_consulta_2 where codigo = 'INF-2001'), 'C05 grupos no multiplicados por matrículas');
select pg_temp.comprobar((select matriculados = 0 from prueba_consulta_3 where id_grupo = 8), 'C06 grupo vacío con cero matrículas');
select pg_temp.comprobar((select matriculados = 5 from prueba_consulta_3 where id_grupo = 1), 'C07 retiro excluido del cupo');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_3 where id_grupo = 6), 'C08 control de cupo solo ciclo 2026-1');
select pg_temp.comprobar((select matriculas = 3 from prueba_consulta_4), 'C09 resumen histórico inicial');
select pg_temp.comprobar((select count(*) = 2 from prueba_consulta_5 where curso = 'Bases de Datos I'), 'C10 homónimos separados');
select pg_temp.comprobar((select total_matriculas = 3 from prueba_consulta_5 where codigo = 'INF-2001') and (select total_matriculas = 2 from prueba_consulta_5 where codigo = 'ADM-2001'), 'C11 conteos de cursos homónimos');
select pg_temp.comprobar((select total_matriculas = 17 and total_evaluadas = 14 and aprobados = 10 and reprobados = 4 and pendientes = 2 and retiradas = 1 and tasa_aprobacion = 71.4 from prueba_consulta_6), 'C12 rendimiento 10 de 14 y dos pendientes');
select pg_temp.comprobar(exists (select 1 from prueba_consulta_7 where carnet = '2021001' and nota = 70), 'C13 nota 70 aprueba');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_7 where carnet = '2021005'), 'C14 nota 69.9 reprueba');
select pg_temp.comprobar((select count(*) = 1 from prueba_consulta_8) and exists (select 1 from prueba_consulta_8 where carnet = '2021006'), 'C15 solo Fabián carece de matrícula');
select pg_temp.comprobar((select count(*) = 1 from prueba_consulta_9) and exists (select 1 from prueba_consulta_9 where carnet = '2021002'), 'C16 solo Carlos cumple todos los requisitos');
select pg_temp.comprobar((select creditos_aprobados = 8 from prueba_consulta_10 where carnet = '2021001'), 'C17 dos cursos de cuatro créditos suman ocho');
select pg_temp.comprobar((select creditos_aprobados = 10 from prueba_consulta_10 where carnet = '2021002'), 'C18 Redes no se multiplica por dos requisitos');
select pg_temp.comprobar((select count(*) = 12 from prueba_consulta_10) and (select creditos_aprobados = 0 from prueba_consulta_10 where carnet = '2021006'), 'C19 estudiantes sin aprobaciones tienen cero');
select pg_temp.comprobar((select cantidad_grupos = 3 from prueba_consulta_11 where cedula = '1-1111-1111'), 'C20 grupos de Rodrigo consolidados');
select pg_temp.comprobar((select count(*) = 4 from prueba_consulta_12), 'C21 listado de cuatro requisitos legítimos');

\echo 'D. Casos nuevos, sin datos permanentes'
update estudiante set activo = false where id_estudiante = 6;
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_1 where carnet = '2021006'), 'D01 inactivo excluido del reporte de activos');
update estudiante set activo = true where id_estudiante = 6;

-- Aprobación repetida del mismo curso en otro grupo/ciclo, legítima (§4).
insert into matricula values (-1001,1,6,70,'matriculado');
select pg_temp.comprobar((select matriculas = 4 from prueba_consulta_4), 'D02 histórico incluye otro ciclo');
select pg_temp.comprobar((select creditos_aprobados = 8 from prueba_consulta_10 where carnet = '2021001'), 'D03 repetir curso no duplica créditos');
select pg_temp.comprobar((select matriculados = 3 from prueba_consulta_3 where id_grupo = 3), 'D04 matrícula histórica no afecta cupo actual');

-- Un retiro con nota alta no aprueba ni satisface requisitos.
insert into matricula values (-1002,6,3,100,'retirado');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_7 where carnet = '2021006'), 'D05 retiro con cien no aprueba');
select pg_temp.comprobar((select creditos_aprobados = 0 from prueba_consulta_10 where carnet = '2021006'), 'D06 retiro no da créditos');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_8 where carnet = '2021006'), 'D07 retiro es historial de matrícula');
insert into matricula values (-1003,1,4,100,'retirado');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_9 where carnet = '2021001'), 'D08 retiro no satisface requisito');
update matricula set estado = 'matriculado', nota = null where id_matricula = -1003;
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_9 where carnet = '2021001'), 'D09 pendiente no satisface requisito');
update matricula set nota = 69.99 where id_matricula = -1003;
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_9 where carnet = '2021001'), 'D10 69.99 no satisface requisito');
update matricula set nota = 70 where id_matricula = -1003;
select pg_temp.comprobar(exists (select 1 from prueba_consulta_9 where carnet = '2021001'), 'D11 requisito con setenta sí habilita');

update matricula set nota = 69.99 where id_matricula = 2;
select pg_temp.comprobar((select nota = 69.99 from matricula where id_matricula = 2), 'D12 precisión original preservada');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_7 where carnet = '2021001' and nota = 69.99), 'D13 69.99 no se convierte en aprobado');
update matricula set nota = 70 where id_matricula = 2;
update matricula set nota = 0 where id_matricula = 5;
select pg_temp.comprobar((select total_evaluadas = 16 and aprobados = 12 and reprobados = 4 from prueba_consulta_6), 'D14 cero es reprobación evaluada');
update matricula set nota = 100 where id_matricula = 5;
select pg_temp.comprobar((select aprobados = 13 and reprobados = 3 from prueba_consulta_6), 'D15 extremo cien es válido');
select pg_temp.comprobar((select total_matriculas = total_evaluadas + pendientes + retiradas and total_evaluadas = aprobados + reprobados from prueba_consulta_6), 'D16 conciliación de todas las categorías');

-- Profesor homónimo con otra cédula, y curso homónimo con otro código.
insert into profesor values (-1001,'TST-CEDULA','Rodrigo Salas Umaña',1);
insert into curso values (-1001,'TST-HOMONIMO','Programación I',4,1);
insert into grupo values (-1001,-1001,null,'2026-1',10),(-1002,3,-1001,'2026-1',10);
insert into matricula values (-1004,1,-1001,70,'matriculado');
select pg_temp.comprobar((select count(*) = 2 from prueba_consulta_11 where profesor = 'Rodrigo Salas Umaña'), 'D17 profesores homónimos separados');
select pg_temp.comprobar((select cantidad_grupos = 1 from prueba_consulta_11 where cedula = 'TST-CEDULA'), 'D18 grupos propios del profesor homónimo');
select pg_temp.comprobar((select id_profesor is null from grupo where id_grupo = -1001), 'D19 profesor temporal NULL permitido');
select pg_temp.comprobar((select count(*) = 2 from prueba_consulta_5 where curso = 'Programación I'), 'D20 curso homónimo no fusionado');
select pg_temp.comprobar((select creditos_aprobados = 15 from prueba_consulta_10 where carnet = '2021001'), 'D21 créditos de curso distinto aunque nombre coincida');
select pg_temp.comprobar((select total_grupos = 3 from prueba_consulta_2 where codigo = 'INF-2001'), 'D22 grupo adicional sin matrículas contado');
select pg_temp.comprobar((select creditos_aprobados = 0 from prueba_consulta_10 where carnet = '2021009'), 'D23 pendiente de Irene no otorga créditos');

-- Más de dos requisitos y requisitos duplicados por intentos.
insert into requisito values (-1001,5,3);
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_9 where carnet = '2021002'), 'D24 dos de tres requisitos no bastan');
select pg_temp.comprobar(exists (select 1 from prueba_consulta_9 where carnet = '2021001'), 'D25 todos los tres requisitos sí habilitan');
delete from requisito where id_curso = 5;
select pg_temp.comprobar((select count(*) = 12 from prueba_consulta_9), 'D26 cero requisitos habilita incluso sin aprobaciones');
update curso set codigo = 'TST-AUSENTE' where id_curso = 5;
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_9), 'D27 curso inexistente no habilita a nadie');

\echo 'E. Universos vacíos: cero conteos, tasa indefinida y conservación del catálogo'
delete from matricula;
select pg_temp.comprobar((select total_matriculas = 0 and total_evaluadas = 0 and aprobados = 0 and reprobados = 0 and pendientes = 0 and retiradas = 0 and tasa_aprobacion is null from prueba_consulta_6), 'E01 base sin matrículas no falla ni inventa tasa');
select pg_temp.comprobar((select count(*) = 9 from prueba_consulta_2) and not exists (select 1 from prueba_consulta_2 where total_matriculas <> 0), 'E02 catálogo sin matrículas permanece completo');
select pg_temp.comprobar((select matriculas = 0 from prueba_consulta_4), 'E03 resumen histórico devuelve cero');
insert into matricula values (-1101,1,1,null,'matriculado'),(-1102,2,1,100,'retirado');
select pg_temp.comprobar((select total_matriculas = 2 and total_evaluadas = 0 and pendientes = 1 and retiradas = 1 and tasa_aprobacion is null from prueba_consulta_6), 'E04 solo pendientes y retirados no inventan tasa');
delete from matricula;
delete from grupo;
select pg_temp.comprobar((select count(*) = 9 from prueba_consulta_2) and not exists (select 1 from prueba_consulta_2 where total_grupos <> 0), 'E05 catálogo sin grupos permanece completo');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_3), 'E06 sin grupos no hay cupos ficticios');
select pg_temp.comprobar((select count(*) = 12 from prueba_consulta_8), 'E07 sin matrículas aparecen todos los estudiantes');
select pg_temp.comprobar(not exists (select 1 from prueba_consulta_10 where creditos_aprobados <> 0), 'E08 sin aprobaciones todos tienen cero créditos');

\echo 'RESULTADOS: cualquier aserción fallida aborta con exit code distinto de cero'
select nombre as prueba_aprobada from resultados_pruebas order by nombre;
select count(*) as pruebas_aprobadas from resultados_pruebas;
