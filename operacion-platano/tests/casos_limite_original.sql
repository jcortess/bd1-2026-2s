-- Ejecutar con entregables/verificar_reportes.py --pruebas tests/casos_limite_original.sql.
-- Diagnóstico de defectos con los reportes ORIGINALES; rollback a cargo del ejecutor.
\echo 'ORIGINAL: EL ESQUEMA ACEPTA NOTA -1 Y 101 (DEBERIA RECHAZARLAS)'
insert into matricula(id_matricula,id_estudiante,id_grupo,nota) values (-101,6,2,-1),(-102,6,3,101);
select id_matricula,nota from matricula where id_matricula in (-101,-102) order by id_matricula;
delete from matricula where id_matricula in (-101,-102);
\echo 'ORIGINAL: RETIRADO CON 100 NO DEBE APROBAR, DAR CREDITOS NI HABILITAR'
insert into matricula(id_matricula,id_estudiante,id_grupo,nota,estado)
values (-103,6,3,100,'retirado'),(-104,6,4,100,'retirado');
select * from reporte_7 where carnet = '2021006';
select * from reporte_9 where carnet = '2021006';
select * from reporte_10 where carnet = '2021006';
delete from matricula where id_matricula in (-103,-104);
\echo 'ORIGINAL: CERO ES NOTA EVALUADA REPROBADA; DEBE AUMENTAR TOTAL_EVALUADAS'
select * from reporte_6;
insert into matricula(id_matricula,id_estudiante,id_grupo,nota) values (-105,6,2,0);
select * from reporte_6;
delete from matricula where id_matricula = -105;
\echo 'ORIGINAL: MATRICULA HISTORICA NO DEBE AUMENTAR CARGA DE 2026-1'
select * from reporte_4;
insert into matricula(id_matricula,id_estudiante,id_grupo,nota) values (-106,6,6,80);
select * from reporte_4;
delete from matricula where id_matricula = -106;
\echo 'ORIGINAL: DOS PROFESORES HOMONIMOS NO DEBEN FUSIONARSE'
insert into profesor(id_profesor,cedula,nombre) values
(-101,'TEST-P1','Docente homonimo'),(-102,'TEST-P2','Docente homonimo');
select * from reporte_11 where profesor = 'Docente homonimo';
\echo 'ORIGINAL: CREDITOS NO PRODUCE TOTAL POR ESTUDIANTE NI ESTUDIANTES CON CERO'
select * from reporte_10 where carnet in ('2021002','2021006');
