-- Ejecutar con entregables/verificar_reportes.py: usa los doce SELECT reales.
-- El ejecutor abre una transacción y termina con ROLLBACK, incluso ante error
-- (psql ON_ERROR_STOP cierra la conexión). Los ids de prueba son explícitos.
-- Una secuencia temporal conserva el conteo al volver a un SAVEPOINT y
-- desaparece al cerrar la sesión; no consume secuencias de las tablas reales.
create temporary sequence contador_pruebas;

create function pg_temp.comprobar(condicion boolean, etiqueta text) returns void
language plpgsql as $$
begin
    if condicion is distinct from true then
        raise exception 'FALLO: %', etiqueta;
    end if;
    perform nextval('pg_temp.contador_pruebas');
    raise notice 'OK: %', etiqueta;
end;
$$;

-- Cada intento fallido se revierte en el subbloque de excepción.
-- SQLSTATE distingue unicidad (23505), FK (23503), CHECK (23514) y NULL (23502).
create function pg_temp.rechazar(sentencia text, esperado text, etiqueta text) returns void
language plpgsql as $$
declare obtenido text;
begin
    begin
        execute sentencia;
    exception when others then
        get stacked diagnostics obtenido = returned_sqlstate;
        if obtenido <> esperado then
            raise exception 'FALLO %: SQLSTATE %, esperado %', etiqueta, obtenido, esperado;
        end if;
        perform pg_temp.comprobar(true, etiqueta);
        return;
    end;
    raise exception 'FALLO %: se aceptó un dato inválido', etiqueta;
end;
$$;

\echo 'A. EXPECTATIVAS CONCRETAS SOBRE LA CARGA REPARADA'
do $$ begin
    perform pg_temp.comprobar((select count(*) = 12 from estudiante), 'A01 conserva los doce estudiantes');
    perform pg_temp.comprobar((select count(*) = 8 from curso), 'A02 conserva los ocho cursos');
    perform pg_temp.comprobar((select count(*) = 8 from grupo), 'A03 conserva los ocho grupos');
    perform pg_temp.comprobar((select count(*) = 17 from matricula), 'A04 matrícula consolidada: 17 filas');
    perform pg_temp.comprobar((select count(*) = 4 from auditoria), 'A05 conserva los cuatro registros históricos');
    perform pg_temp.comprobar((select count(*) = 12 from reporte_1), 'Q01 activos incluye a Karla con carrera');
    perform pg_temp.comprobar((select count(*) = 8 from reporte_2), 'Q02 catálogo completo');
    perform pg_temp.comprobar((select total_grupos = 0 and total_matriculas = 0 from reporte_2 where codigo = 'IND-1001'), 'Q02 curso sin grupos');
    perform pg_temp.comprobar((select total_grupos = 1 and total_matriculas = 0 from reporte_2 where codigo = 'INF-4001'), 'Q02 grupo sin matrícula');
    perform pg_temp.comprobar((select total_grupos = 2 and total_matriculas = 3 from reporte_2 where codigo = 'INF-2001'), 'Q02 no multiplica el conteo de grupos');
    perform pg_temp.comprobar((select sum(total_matriculas) = 17 and sum(total_grupos) = 8 from reporte_2), 'Q02 totales históricos completos');
    perform pg_temp.comprobar((select count(*) = 7 from reporte_3), 'Q03 solo siete grupos del ciclo actual');
    perform pg_temp.comprobar((select matriculados = 0 from reporte_3 where id_grupo = 8), 'Q03 grupo vacío cuenta cero');
    perform pg_temp.comprobar((select matriculados = 5 from reporte_3 where id_grupo = 1), 'Q03 retiro no ocupa cupo');
    perform pg_temp.comprobar((select matriculas = 3 from reporte_4), 'Q04 carga actual inicial de BD I');
    perform pg_temp.comprobar((select count(*) = 8 from reporte_5), 'Q05 una fila por identidad de curso');
    perform pg_temp.comprobar((select total_matriculas = 3 from reporte_5 where codigo = 'INF-2001'), 'Q05 BD Informática separado');
    perform pg_temp.comprobar((select total_matriculas = 2 from reporte_5 where codigo = 'ADM-2001'), 'Q05 BD Administración separado');
    perform pg_temp.comprobar((select total_matriculas = 16 and total_evaluadas = 15 and aprobados = 11 and reprobados = 4 and pendientes = 1 and tasa_aprobacion = 73.3 from reporte_6), 'Q06 clasificación y tasa 11 de 15');
    perform pg_temp.comprobar((select count(*) = 2 from reporte_7), 'Q07 dos aprobados de BD I');
    perform pg_temp.comprobar(exists(select 1 from reporte_7 where carnet = '2021001' and nota = 70), 'Q07 Ana aprueba con setenta');
    perform pg_temp.comprobar((select array_agg(carnet::text) = array['2021006'] from reporte_8), 'Q08 Fabián sin ninguna matrícula');
    perform pg_temp.comprobar((select array_agg(carnet::text) = array['2021002'] from reporte_9), 'Q09 solo Carlos satisface todos');
    perform pg_temp.comprobar((select count(*) = 12 and sum(creditos_aprobados) = 40 from reporte_10), 'Q10 doce estudiantes y cuarenta créditos totales');
    perform pg_temp.comprobar((select creditos_aprobados = 8 from reporte_10 where carnet = '2021001'), 'Q10 dos cursos de cuatro aportan ocho');
    perform pg_temp.comprobar((select creditos_aprobados = 10 from reporte_10 where carnet = '2021002'), 'Q10 Carlos obtiene diez sin multiplicación por requisitos');
    perform pg_temp.comprobar((select creditos_aprobados = 0 from reporte_10 where carnet = '2021006'), 'Q10 estudiante sin matrícula conserva cero');
    perform pg_temp.comprobar((select count(*) = 3 and sum(cantidad_grupos) = 6 from reporte_11), 'Q11 tres profesores y seis grupos asignados actuales');
    perform pg_temp.comprobar((select cantidad_grupos = 3 from reporte_11 where cedula = '1-1111-1111'), 'Q11 ciclo anterior excluido');
    perform pg_temp.comprobar((select count(*) = 4 from reporte_12), 'Q12 cuatro requisitos vigentes');
    perform pg_temp.comprobar((select count(*) = 2 from reporte_12 where curso = 'INF-2003'), 'Q12 Redes conserva dos requisitos');
end $$;

\echo 'B. RECHAZO ESTRUCTURAL DE DATOS INVALIDOS'
do $$ begin
    perform pg_temp.rechazar($s$insert into estudiante values(-900,'2021001','Duplicado',1,current_date,true)$s$, '23505','B01 carnet duplicado activo');
    perform pg_temp.rechazar($s$insert into estudiante values(-900,'2021001','Duplicado',1,current_date,false)$s$, '23505','B02 carnet duplicado inactivo');
    perform pg_temp.rechazar($s$insert into estudiante values(-900,'TEST-NULL','Sin carrera',null,current_date,true)$s$, '23502','B03 carrera obligatoria');
    perform pg_temp.rechazar($s$insert into profesor values(-900,'1-1111-1111','Duplicado',1)$s$, '23505','B04 cédula duplicada');
    perform pg_temp.rechazar($s$insert into curso values(-900,'TEST-C0','Inválido',0,1)$s$, '23514','B05 créditos cero');
    perform pg_temp.rechazar($s$insert into curso values(-900,'TEST-CN','Inválido',-1,1)$s$, '23514','B06 créditos negativos');
    perform pg_temp.rechazar($s$insert into curso values(-900,'TEST-CNULL','Inválido',null,1)$s$, '23502','B07 créditos ausentes');
    perform pg_temp.rechazar($s$insert into matricula values(-900,1,1,80,'matriculado')$s$, '23505','B08 matrícula duplicada activa');
    perform pg_temp.rechazar($s$insert into matricula values(-900,1,1,80,'retirado')$s$, '23505','B09 par único incluso retirado');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,-0.1,'matriculado')$s$, '23514','B10 nota negativa');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,100.1,'matriculado')$s$, '23514','B11 nota superior a cien');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,'NaN','matriculado')$s$, '23514','B12 nota NaN rechazada');
    perform pg_temp.rechazar($s$insert into requisito values(-900,1,1)$s$, '23514','B13 autorrequisito');
    perform pg_temp.rechazar($s$insert into requisito values(-900,2,1)$s$, '23505','B14 requisito repetido');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,80,'desconocido')$s$, '23514','B15 estado inválido');
    perform pg_temp.rechazar($s$insert into estudiante values(-900,'TEST-FK','Sin carrera válida',-999,current_date,true)$s$, '23503','B16 FK estudiante carrera');
    perform pg_temp.rechazar($s$insert into profesor values(-900,'TEST-FK','Profesor',-999)$s$, '23503','B17 FK profesor carrera');
    perform pg_temp.rechazar($s$insert into curso values(-900,'TEST-FK','Curso',1,-999)$s$, '23503','B18 FK curso carrera');
    perform pg_temp.rechazar($s$insert into grupo values(-900,-999,null,'2026-1',1)$s$, '23503','B19 FK grupo curso');
    perform pg_temp.rechazar($s$insert into grupo values(-900,1,-999,'2026-1',1)$s$, '23503','B20 FK grupo profesor');
    perform pg_temp.rechazar($s$insert into matricula values(-900,-999,1,80,'matriculado')$s$, '23503','B21 FK matrícula estudiante');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,-999,80,'matriculado')$s$, '23503','B22 FK matrícula grupo');
    perform pg_temp.rechazar($s$insert into requisito values(-900,-999,1)$s$, '23503','B23 FK requisito destino');
    perform pg_temp.rechazar($s$insert into requisito values(-900,1,-999)$s$, '23503','B24 FK requisito previo');
    perform pg_temp.rechazar($s$update matricula set nota=101 where id_matricula=1$s$, '23514','B25 rango también protegido en UPDATE');
    perform pg_temp.rechazar($s$update estudiante set carnet='2021001' where id_estudiante=2$s$, '23505','B26 unicidad también protegida en UPDATE');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,-0.01,'matriculado')$s$, '23514','B27 negativo de dos decimales no se redondea a cero');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,100.01,'matriculado')$s$, '23514','B28 exceso de dos decimales no se redondea a cien');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,'Infinity','matriculado')$s$, '23514','B29 infinito positivo rechazado');
    perform pg_temp.rechazar($s$insert into matricula values(-900,6,2,'-Infinity','matriculado')$s$, '23514','B30 infinito negativo rechazado');
end $$;

-- Continúan casos de comportamiento con filas sintéticas; todo será revertido.
\echo 'C. IDENTIDADES DISTINTAS CON NOMBRES IGUALES Y AUSENCIAS VALIDAS'
insert into carrera values (-101,'TEST-A','Carrera homonima',1),(-102,'TEST-B','Carrera homonima',1);
insert into curso values
(-101,'TEST-A','Curso homonimo',4,-101),(-102,'TEST-B','Curso homonimo',4,-102),
(-103,'TEST-C','Curso sin grupos',1,-101);
insert into profesor values
(-101,'TEST-P1','Docente homonimo',null),(-102,'TEST-P2','Docente homonimo',null),
(-103,'TEST-P3','Docente sin grupos',null);
insert into grupo values
(-101,-101,-101,'2026-1',10),(-102,-102,-102,'2026-1',10),
(-103,3,-101,'2025-2',10),(-104,3,-101,'2026-1',10),
(-105,1,null,'2026-1',10),(-106,4,-102,'2026-1',10),(-107,-101,-101,'2026-1',10);
insert into estudiante values
(-101,'TEST-A','Estudiante homonimo',1,current_date,true),
(-102,'TEST-B','Estudiante homonimo',1,current_date,true),
(-103,'TEST-C','Estudiante inactivo',1,current_date,false);
do $$ begin
    perform pg_temp.comprobar((select count(*) = 2 from reporte_1 where carnet in ('TEST-A','TEST-B')), 'C01 estudiantes homónimos separados');
    perform pg_temp.comprobar(not exists(select 1 from reporte_1 where carnet='TEST-C'), 'C02 reporte de activos excluye inactivo');
    perform pg_temp.comprobar((select count(*) = 2 from reporte_2 where codigo in ('TEST-A','TEST-B')), 'C03 carreras y cursos homónimos separados');
    perform pg_temp.comprobar((select total_grupos=0 and total_matriculas=0 from reporte_2 where codigo='TEST-C'), 'C04 nuevo curso sin grupos visible');
    perform pg_temp.comprobar((select count(*)=6 and bool_and(matriculados=0) from reporte_3 where id_grupo < 0), 'C05 grupos vacíos actuales y sin profesor válidos');
    perform pg_temp.comprobar((select count(*)=2 from reporte_11 where profesor='Docente homonimo'), 'C06 profesores homónimos separados');
    perform pg_temp.comprobar((select cantidad_grupos=3 from reporte_11 where cedula='TEST-P1'), 'C07 grupos actuales por profesor sin el histórico');
    perform pg_temp.comprobar((select cantidad_grupos=0 from reporte_11 where cedula='TEST-P3'), 'C08 profesor sin grupos conservado');
    perform pg_temp.comprobar((select count(*)=3 from reporte_8 where carnet like 'TEST-%'), 'C09 sin matrícula incluye activos e inactivos');
    perform pg_temp.comprobar((select count(*)=3 and bool_and(creditos_aprobados=0) from reporte_10 where carnet like 'TEST-%'), 'C10 créditos cero conserva todos los estudiantes');
end $$;

savepoint frontera;
\echo 'D. EXTREMOS VALIDOS Y FRONTERA DE APROBACION'
insert into matricula values
(-201,-101,-101,0,'matriculado'),(-202,-101,-102,100,'matriculado'),
(-203,-101,-104,69.9,'matriculado'),(-204,-102,-104,70,'matriculado'),
(-205,-102,-101,null,'matriculado');
do $$ begin
    perform pg_temp.comprobar((select total_matriculas=21 and total_evaluadas=19 and aprobados=13 and reprobados=6 and pendientes=2 and tasa_aprobacion=68.4 from reporte_6), 'D01 cero y cien válidos, 69.9 reprueba, setenta aprueba, NULL pendiente');
    perform pg_temp.comprobar(not exists(select 1 from reporte_7 where carnet='TEST-A'), 'D02 69.9 no aprueba BD I');
    perform pg_temp.comprobar(exists(select 1 from reporte_7 where carnet='TEST-B' and nota=70), 'D03 setenta exacto aprueba BD I');
    perform pg_temp.comprobar((select creditos_aprobados=4 from reporte_10 where carnet='TEST-A'), 'D04 cero y 69.9 no otorgan créditos');
    perform pg_temp.comprobar((select creditos_aprobados=4 from reporte_10 where carnet='TEST-B'), 'D05 pendiente no otorga créditos');
    perform pg_temp.comprobar(not exists(select 1 from reporte_8 where carnet='TEST-A'), 'D06 matrícula reprobada sigue siendo matrícula registrada');
end $$;
rollback to frontera;

savepoint retirados;
\echo 'E. RETIRADOS CON NOTA ALTA Y PENDIENTE'
insert into matricula values
(-301,-101,-104,100,'retirado'),(-302,-101,-105,100,'retirado'),
(-303,-101,-106,100,'retirado'),(-304,-102,-101,null,'retirado');
do $$ begin
    perform pg_temp.comprobar((select total_matriculas=16 and total_evaluadas=15 and aprobados=11 and reprobados=4 and pendientes=1 and tasa_aprobacion=73.3 from reporte_6), 'E01 retiros excluidos de todos los conteos de rendimiento');
    perform pg_temp.comprobar(not exists(select 1 from reporte_7 where carnet='TEST-A'), 'E02 retirado con cien no aprueba');
    perform pg_temp.comprobar(not exists(select 1 from reporte_9 where carnet='TEST-A'), 'E03 requisitos retirados no habilitan');
    perform pg_temp.comprobar((select creditos_aprobados=0 from reporte_10 where carnet='TEST-A'), 'E04 retiros no otorgan créditos');
    perform pg_temp.comprobar((select bool_and(matriculados=0) from reporte_3 where id_grupo<0), 'E05 grupo con solo retirados sigue vacío para cupo');
    perform pg_temp.comprobar(not exists(select 1 from reporte_8 where carnet='TEST-A'), 'E06 retirado sí tiene matrícula histórica registrada');
end $$;
rollback to retirados;

savepoint creditos;
\echo 'F. REPETICION DEL MISMO CURSO Y CURSOS DISTINTOS DE IGUAL CREDITAJE'
insert into matricula values
(-401,-101,-101,70,'matriculado'),(-402,-101,-107,100,'matriculado'),
(-403,-101,-102,70,'matriculado');
insert into requisito values (-401,-101,1),(-402,-101,4);
do $$ begin
    perform pg_temp.comprobar((select creditos_aprobados=8 from reporte_10 where carnet='TEST-A'), 'F01 dos aprobaciones del mismo curso cuentan una vez; otro curso de cuatro suma cuatro');
    perform pg_temp.comprobar((select count(*)=1 from reporte_10 where carnet='TEST-A'), 'F02 una fila de créditos por estudiante');
    perform pg_temp.comprobar((select total_grupos=2 and total_matriculas=2 from reporte_2 where codigo='TEST-A'), 'F03 catálogo conserva intentos legítimos en grupos distintos');
    perform pg_temp.comprobar((select count(*)=2 from reporte_5 where curso='Curso homonimo'), 'F04 cursos homónimos no se fusionan al tener matrícula');
end $$;
rollback to creditos;

savepoint requisitos;
\echo 'G. TODOS LOS REQUISITOS, NO ALGUNO; PENDIENTES Y RETIRADOS'
insert into matricula values
(-501,-101,-105,70,'matriculado'),(-502,-102,-105,100,'matriculado'),
(-503,-102,-106,100,'retirado');
do $$ begin
    perform pg_temp.comprobar(not exists(select 1 from reporte_9 where carnet in ('TEST-A','TEST-B')), 'G01 un solo requisito válido no basta');
end $$;
insert into matricula values (-504,-101,-106,null,'matriculado');
do $$ begin
    perform pg_temp.comprobar(not exists(select 1 from reporte_9 where carnet='TEST-A'), 'G02 requisito pendiente no basta');
end $$;
update matricula set nota=70 where id_matricula=-504;
insert into matricula values (-505,-101,1,80,'matriculado');
do $$ begin
    perform pg_temp.comprobar((select count(*)=1 from reporte_9 where carnet='TEST-A'), 'G03 ambos con setenta habilitan una vez aunque se repita un requisito aprobado');
    perform pg_temp.comprobar(not exists(select 1 from reporte_9 where carnet='TEST-B'), 'G04 aprobación retirada no satisface el segundo requisito');
end $$;
savepoint cero_requisitos;
-- Cambiar temporalmente el destino de esos requisitos deja Redes sin previos.
update requisito set id_curso=-101 where id_curso=5;
do $$ begin
    perform pg_temp.comprobar((select count(*) from reporte_9)=(select count(*) from estudiante), 'G05 cero requisitos: todos satisfacen la condición');
end $$;
rollback to cero_requisitos;
savepoint curso_ausente;
update curso set codigo='TEST-REDES' where id_curso=5;
do $$ begin
    perform pg_temp.comprobar(not exists(select 1 from reporte_9), 'G06 curso destino inexistente no habilita a nadie');
end $$;
rollback to curso_ausente;
rollback to requisitos;

savepoint ciclos;
\echo 'H. DIFERENCIA ENTRE HISTORICO Y CICLO SOLICITADO'
insert into matricula values (-601,-101,-103,80,'matriculado');
do $$ begin
    perform pg_temp.comprobar((select matriculas=3 from reporte_4), 'H01 matrícula de 2025-2 no altera carga 2026-1');
    perform pg_temp.comprobar((select total_matriculas=4 from reporte_2 where codigo='INF-2001'), 'H02 catálogo histórico sí incluye matrícula anterior');
    perform pg_temp.comprobar((select total_matriculas=4 from reporte_5 where codigo='INF-2001'), 'H03 popularidad histórica sí incluye matrícula anterior');
end $$;
insert into matricula values (-602,-101,-104,80,'matriculado');
do $$ begin
    perform pg_temp.comprobar((select matriculas=4 from reporte_4), 'H04 matrícula de 2026-1 sí altera carga actual');
end $$;
rollback to ciclos;

savepoint ciclo_vacio;
-- Mover temporalmente las matrículas de BD a otro grupo deja su ciclo vacío.
-- Los estudiantes 1, 5 y 11 no estaban matriculados en el grupo sintético.
update matricula set id_grupo=-101 where id_grupo=3;
do $$ begin
    perform pg_temp.comprobar((select count(*)=1 and max(matriculas)=0 from reporte_4), 'H05 ciclo sin matrícula devuelve una fila con cero');
end $$;
update grupo set ciclo='TEST-OTRO' where id_curso=3;
do $$ begin
    perform pg_temp.comprobar((select count(*)=1 and max(matriculas)=0 from reporte_4), 'H06 curso sin grupos actuales devuelve una fila con cero');
end $$;
rollback to ciclo_vacio;

savepoint sin_evaluadas;
\echo 'I. SIN EVALUACIONES Y SIN MATRICULAS INCLUIDAS'
update matricula set estado='retirado';
do $$ begin
    perform pg_temp.comprobar((select total_matriculas=0 and total_evaluadas=0 and aprobados=0 and reprobados=0 and pendientes=0 and tasa_aprobacion is null from reporte_6), 'I01 sin filas incluidas no hay división por cero');
    perform pg_temp.comprobar((select bool_and(creditos_aprobados=0) from reporte_10), 'I02 todos retirados producen cero créditos');
end $$;
insert into matricula values (-701,-101,-101,null,'matriculado');
do $$ begin
    perform pg_temp.comprobar((select total_matriculas=1 and total_evaluadas=0 and aprobados=0 and reprobados=0 and pendientes=1 and tasa_aprobacion is null from reporte_6), 'I03 solo pendiente tiene tasa desconocida y conteo explícito');
end $$;
rollback to sin_evaluadas;

savepoint precision;
\echo 'J. DECIMALES RECIBIDOS SIN REDONDEO IMPLICITO DEL UMBRAL'
insert into matricula values (-801,-101,-104,69.99,'matriculado');
do $$ begin
    perform pg_temp.comprobar((select nota=69.99 from matricula where id_matricula=-801), 'J01 conserva exactamente 69.99');
    perform pg_temp.comprobar(not exists(select 1 from reporte_7 where carnet='TEST-A'), 'J02 69.99 no se convierte en aprobación');
end $$;
rollback to precision;

\echo 'RESUMEN DE ASERCIONES APROBADAS'
select last_value as aserciones_aprobadas from contador_pruebas;
-- Los NOTICE OK identifican cada aserción; cualquier fallo aborta el ejecutor.
