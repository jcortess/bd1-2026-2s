# Esquemas
## Estudiante y profesor

Estos son los esquemas de estudiante  y profesor originales (a carrera no se le realizaron modificaciones):
![carrera, estudiante y profesor antes de las correcciones](../capturas_antes_de_correcciones/esquemas_antes_del_cambio_1.png)

El esquema de estudiantes muestra 2 problemas: 
    
    1. no tiene el carnet como UNIQUE, lo que permite que existan carnet repetidos y rompe la regla 1.2 de reglas_negocio.md. Si bien en AGENTS.md se menciona que hay procesos provisionales que requieren que existan 2 carnet iguales, estos procesos no se mencionan en reglas_negocio.md por lo que se decidio ignorar esta anotacion.

    2. la carrera no tiene un NOT NULL, por lo que se permiten estudiantes sin carrera, lo que rompe la regla 1.1 de reglas_negocio.md.
    
Soluciones para los problemas de estudiante:

    1. se agrego el UNIQUE al carnet
    2. se agrego un NOT NULL a carrera

El esquema de profesor presenta el problema de que la cedula no tiene restriccion UNIQUE, lo que permite que existan varios profesores con la misma cedula.

Solucion: se agrego un UNIQUE a la cedula en profesor.

El esquema de carrera no presenta contradicciones por si solo y sigue reglas_negocio.md, por lo que no se requieren modificaciones.

## Curso, grupo y matricula

Estos son los esquemas de curso, grupo y matricula originales  (a grupo no se le realizaron modificaciones):
![curso, grupo y matricula antes de las correcciones](../capturas_antes_de_correcciones/esquemas_antes_del_cambio_2.png)

El esquema de curso presenta el problema de que los creditos no tienen ningun limitador que impida que los creditos sean 0 o negativo, lo que rompe con la regla 3.1 de reglas_negocio.md.

Solucion: se agrego un CHECK(creditos >= 1)

El esquema de grupo no presenta ningun problema por si solo y cumple con reglas_negocio.md por lo que no se requieren modificaciones.

El esquema de matricula presenta 2 problemas:

    1. el par (id_estudiante,id_grupo) no tiene un UNIQUE que impida que existan dos iguales, lo que rompe con la regla 4.1 de reglas_negocio.md
    2. la nota no tiene ningun limitador que impida que sea menor a 0 o mayor a 100, por lo que rompe con la regla 4.2 de reglas_negocio.md
    
Soluciones:

    1. se agrego UNIQUE (id_estudiante,id_grupo)
    2. se agrego CHECK(nota >= 0 AND nota <=100)

## Requisito y auditoria

Estos son los esquemas de requisito y auditoria originales:
![curso, grupo y matricula antes de las correcciones](../capturas_antes_de_correcciones/esquemas_antes_del_cambio_3.png)

El esquema de requisito presenta el problema de que no hay nada que impida que en el par (id_curso, id_curso_requisito) sean el mismo id, lo que significa que un curso puede ser requisito de si mismo, lo que rompe la regla 6.2 de reglas_negocio.md

Solucion: se agrego un CHECK(id_curso <> id_curso_requisito) para el par (id_curso,id_curso_requisito)

El esquema de auditoria no rompe ninguna regla, pero presenta dependencias como (id_auditoria->accion,descripcion,fecha,usuario), aunque id_registro no sea parte de la clave elegida se puede concluir que (accion, descripcion, fecha, usuario) son mas propios de un registro que de la auditoria que contiene el registro. Ademas, se permite que varios registros tengan un id nulo o el mismo id para la misma auditoria.

Solucion: se normalizo el esquema y se descompuso en auditoria, que contiene (id_auditoria PK, tabla_afectada) y registro, que contiene (id_auditoria PK FK, id_registro PK, accion, descripcion, fecha, usuario).

## Resultados

Tablas de carrera, estudiante, profesor:
![carrera, estudiante y profesor despues de las correcciones](../capturas_despues_de_correcciones/esquemas_corregidos_1.png)

Tablas de curso, grupo y matricula:
![curso, grupo y matricula despues de las correcciones](../capturas_despues_de_correcciones/esquemas_corregidos_2.png)

Tablas de requisito, auditoria y registro:
![requisito, auditoria y registro despues de las correcciones](../capturas_despues_de_correcciones/esquemas_corregidos_3.png)


resumen de errores detectados despues de correcciones:
![resumen de errores de datos](../capturas_antes_de_correcciones/violaciones_del_sistema_anterior_despues_de_correcciones.png)

# Datos

aqui resumo los datos de los esquemas corregidos, no incluyo los datos de auditoria ni de registro debido a que la modificacion se aprecia en la estructura y no en los datos. Tampoco muestro datos de grupo ni de carrera debido a que no se les realizo ninguna modificacion

## estudiante

Datos originales de estudiante:
![datos originales de estudiante](../capturas_antes_de_correcciones/datos_estudiante_antes_de_correcciones.png)

Problemas:

    1. los estudiantes 10 y 11 comparten la misma cedula
    2. el estudiante 12 no tiene carrera

Correcciones realizadas:

    1. se cambio el carnet del estudiante 11 a 2021011, y el del 12 a 2021012 para evitar volver a romper la unicidad del carnet
    2. provisionalmente se le asigno la carrera 2 al estudiante 12 para no romper el NOT NULL de carrera

Datos despues de correcciones:
![datos corregidos de estudiante](../capturas_despues_de_correcciones/tabla_estudiante.png)

## profesor

Datos originales de profesor:
![datos originales de profesor](../capturas_antes_de_correcciones/datos_profesor_antes_de_correcciones.png)

Problemas:

    1. los profesores 1 y 4 comparten la misma cedula, lo que rompe la regla 2.1 en reglas_negocio.md. esto surge de un cambio manual descrito en la nota "2025-11-05 — Ticket SOP-2025-101: Profesor no puede ver todos sus grupos" de historial_cambios.md.
    
Correcciones realizadas:

    1. debido a que historial_cambios.md corresponde a una bitacora de cambios, se decidio eliminar al profesor 4 para mantener la unicidad de la cedula y pasar sus datos al profesor 1, asumiendo que esa era la intencion del cambio manual y que se puede confiar en la intencion de historial_cambios.md. No se encontraron los grupos asignados al profesor 4 descritos en historial_cambios.md
    

Datos despues de correcciones:
![datos corregidos de profesor](../capturas_despues_de_correcciones/tabla_profesor_corregida.png)

## curso

Datos originales de curso:
![datos originales de curso](../capturas_antes_de_correcciones/datos_curso_antes_de_correcciones.png)

Problemas:

    1. el curso 8 tiene 0 creditos, lo que rompe la regla 3.1 de reglas_negocio.md

Correcciones realizadas:

    1. se cambiaron los creditos del curso 8 de 0 creditos a 1 credito de manera provisional, asumi que la intencion era darle el minimo a ese curso.

Datos despues de correcciones:
![datos corregidos de curso](../capturas_despues_de_correcciones/tabla_curso_corregida.png)


## matricula

Datos originales de matricula:
![datos originales de matricula](../capturas_antes_de_correcciones/datos_matricula_antes_de_correcciones.png)

Problemas:

    1. el par (id_estudiante=9,id_grupo=1) se repite en las matriculas 14 y 15, lo que rompe con la regla 4.1 de reglas_negocio.md

Correcciones realizadas:

    1. se elimino la matricula 14 para cumplir con el cambio de nota descrito en auditoria "MATRICULA" registro '1', asumiendo que se puede confiar que esa era la intencion de la fila duplicada, y se conservo la matricula 15 para no romper la unicidad del par (id_estudiante, id_grupo).

Auditoria en la que se baso la decision, asumiendo que se refiere a las matriculas 14 y 15:
![auditoria de UPDATE sobre MATRICULA](../capturas_despues_de_correcciones/auditoria_registro_sobre_matricula.png)

Datos despues de correcciones:
![datos corregidos de matricula](../capturas_despues_de_correcciones/tabla_matricula_corregida.png)

## requisito

Datos originales de requisito:
![datos originales de requisito](../capturas_antes_de_correcciones/datos_requisito_antes_de_correcciones.png)

Problemas:

    1. en el requisito 5, el id_curso y id_curso_requisito tienen el mismo id(4), lo que significa que el curso con id_curso=4 (que corresponde al codigo de curso INF-2002) es requisito de si mismo, lo que rompe la regla 6.2 en reglas_negocio.md

Correcciones realizadas:

    1. se cambio provisionalmente el id_requisito de 4 a 3 en el requisito 5 para no romper la regla 6.2, el id_curso_requisito=3 corresponde al curso INF-2001, que se asumio que era anterior al curso INF-2002.

Datos despues de correcciones:
![datos corregidos de requisito](../capturas_despues_de_correcciones/tabla_requisitos_corregida.png)


# Consultas

Aclaracion: las consultas se ejecutaron con los datos corregidos de la seccion anterior, aqui solo se evalua la estructura de la consulta

## Consulta 1 (Estudiantes activos por carrera)

Estructura original de la consulta:

![estructura original de consulta 1](../capturas_antes_de_correcciones/estructura_consulta1_antes_de_correcciones.png)

No se le realizaron correcciones a la estructura de esta consulta debido a que muestra los datos correctamente

output:

![output original de consulta 1](../capturas_antes_de_correcciones/output_original_consulta1.png)

## Consulta 2 (Catálogo de cursos con cantidad de grupos y matrículas totales por carrera)

Estructura original de la consulta:

![estructura original consulta 2](../capturas_antes_de_correcciones/estructura_original_consulta2.png)

Problemas:

    1. no muestra la cantidad total de grupos.
    2. no muestra los cursos con 0 grupos ni 0 matriculas, a pesar de existir en la base de datos
    
Solucion:

    1. se agrego COUNT(DISTINCT g.id_grupo) AS total_grupos como columna de la respuesta
    2. se cambiaron los JOIN con grupo y matricula por LEFT JOIN para incluir los cursos que no tengan ni matricula ni grupo


Estructura corregida:

![estructura corregida consulta 2](../capturas_despues_de_correcciones/estructura_corregida_consulta2.png)

output original:

![output original de consulta 2](../capturas_antes_de_correcciones/output_original_consulta2.png)

output despues de las correcciones:

![output corregido consulta 2](../capturas_despues_de_correcciones/output_corregido_consulta2.png)

## Consulta 3 (Matrícula por grupo del ciclo 2026-1)

Estructura original de la consulta:

![estructura original consulta 3](../capturas_antes_de_correcciones/estructura_original_consulta3.png)

El problema que identifique fue que esta consulta tambien incluye las matriculas retiradas, y en reglas_negocio.md no se especifica si una matricula retirada ocupa un cupo dentro de un grupo, a lo mucho menciona en regla 6.4 que una retirada no se debe contar ni como aprobada ni como reprobada. Por lo tanto, se asumio que una matricula retirada no forma parte de un grupo para este tipo de consulta, por lo que se agrego (m.estado = 'matriculado') en el WHERE.

Estructura corregida:

![estructura corregida consulta 3](../capturas_despues_de_correcciones/estructura_corregida_consulta3.png)

output original:

![output original de consulta 3](../capturas_antes_de_correcciones/output_original_consulta3.png)

output despues de las correcciones:

![output corregido consulta 3](../capturas_despues_de_correcciones/output_corregido_consulta3.png)

## Consulta 4 (Resumen de matrícula histórica del curso "Bases de Datos I")

Estructura original de la consulta:

![estructura original consulta 4](../capturas_antes_de_correcciones/estructura_original_consulta4.png)

no se le realizaron correcciones, pues obtiene el total de matriculas del curso en cualquier ciclo. Como esta la estructura, tambien cuenta las matriculas retiradas, pero se decidio dejarlo asi porque a como entiendo la consulta, se busca calcular la demanda por ese curso y no se saben bajo que condiciones se retiro una matricula, solo que se solicito y despues se retiro. Por esas razones, se decidio no realizar ninguna correccion.

output:

![output consulta 4](../capturas_antes_de_correcciones/output_original_consulta4.png)

## Consulta 5 (Matrícula total histórica por nombre de curso)

Estructura original de la consulta:

![estructura original consulta 5](../capturas_antes_de_correcciones/estructura_original_consulta5.png)

No se le realizaron correcciones, pues obtiene el total de matriculas historicas de cada curso, aqui se aplica el mismo razonamiento usado en la consulta anterior para incluir matriculas retiradas.

output:

![output consulta 5](../capturas_antes_de_correcciones/output_original_consulta5.png)



## Consulta 6 (Pendientes de calificación y tasa de aprobación general)

Estructura original de la consulta:

![estructura original consulta 6](../capturas_antes_de_correcciones/estructura_original_consulta6.png)

excluye correctamente las matriculas retiradas acorde a la regla 4.4 en reglas_negocio.md, pero tambien excluye las matriculas en curso (nota=NULL), lo que rompe con la intencion de la consulta de mostrar las pendientes de calificacion y con la regla 4.3 de reglas_negocio.md.

Por lo tanto, se elimino el nota <> 0 del WHERE, tambien, se modifico tasa_aprobacion para que en vez de operar con COUNT() opere con SUM(WHEN nota IS NOT NULL THEN 1) (esta nota en pseudo-codigo es meramente ilustrativa) porque COUNT() ahora contiene las notas pendientes y segun la regla 4.3 esas no cuentan ni como aprobadas ni como reprobadas. Ademas, se agrego la columna "pendientes_de_calificacion" que contiene la suma de todas las notas nulas segun SUM(nota IS NULL THEN 1, ELSE 0).

Estructura corregida:

![estructura corregida consulta 6](../capturas_despues_de_correcciones/estructura_corregida_consulta6.png)

output original:

![output original consulta 6](../capturas_antes_de_correcciones/estructura_original_consulta6.png)

output despues de las correcciones:

![output corregido consulta 6](../capturas_despues_de_correcciones/output_corregido_consulta3.png)

## Consulta 7 (Estudiantes aprobados en Bases de Datos I (código INF-2001))

Estructura original de la consulta:

![estructura original consulta 7](../capturas_antes_de_correcciones/estructura_original_consulta7.png)

El problema con esta consulta es que usa nota > 70 para determinar si un estudiante aprobo el curso, lo que rompe la regla 5 en reglas_negocio.md. Por lo tanto, la condicion se cambio a nota >= 70 para incluir nota = 70 como aprobada y cumplir con la regla 5.

Estructura corregida:

![estructura corregida consulta 7](../capturas_despues_de_correcciones/estructura_corregida_consulta7.png)

output original:

![output original consulta 7](../capturas_antes_de_correcciones/output_original_consulta7.png)

output despues de las correcciones:

![output corregido consulta 7](../capturas_despues_de_correcciones/output_corregido_consulta7.png)

## Consulta 8 (estudiantes sin ninguna matrícula registrada)

Estructura original de la consulta:

![estructura original consulta 8](../capturas_antes_de_correcciones/estructura_original_consulta8.png)

No se realizaron correcciones porque la consulta devuelve los estudiantes sin matricula correctamente y no rompe ninguna regla de reglas_negocio.md

output:

![output consulta 8](../capturas_antes_de_correcciones/output_original_consulta8.png)

## Consulta 9 (Estudiantes habilitados para matricular Redes de Computadoras)

Estructura original de la consulta:

![estructura original consulta 9](../capturas_antes_de_correcciones/estructura_original_consulta9.png)

El problema de esta consulta es que por como esta planteada no verifica que cada estudiante haya aprobado todos los requisitos del curso, en el output original aparecen 4 estudiantes como habilitados para matricular el curso pero solo el carnet 2021002 aprobo todos los requisitos.

Por lo tanto, se modifico la consulta para que eligiera los estudiantes que aparecieran en la tabla original tantas veces como requisitos tuviera el curso en el momento. Se utilizo un SELECT COUNT() para obtener todos los requisitos de Redes de Computadoras por si acaso en algun momento la universidad (UTT) decidiera modificar los requisitos de ese curso.


Estructura corregida:

![estructura corregida consulta 9](../capturas_despues_de_correcciones/estructura_corregida_consulta9.png)

output original:

![output original consulta 9](../capturas_antes_de_correcciones/output_original_consulta9.png)

output despues de las correcciones:

![output corregido consulta 9](../capturas_despues_de_correcciones/output_corregido_consulta9.png)

## Consulta 10 (Créditos aprobados por estudiante)


Estructura original de la consulta:

![estructura original consulta 10](../capturas_antes_de_correcciones/estructura_original_consulta10.png)

El problema con esta consulta es que da filas duplicadas, como se puede ver en el output original cuando se remueve el DISTINCT, estas filas duplicadas son el resultado de hacer un JOIN innecesario a los requisitos de cada curso, y como Redes de Computadores tiene 2 requisitos, los estudiantes que aprobaran ese curso aparecen 2 veces, el equipo original de este reto uso DISTINCT para solucionarlo. Por lo tanto, como el problema surge de hacer el JOIN con requisito, se elimino este JOIN innecesario y se elimino el DISTINCT.

Estructura corregida:

![estructura corregida consulta 10](../capturas_despues_de_correcciones/estructura_corregida_consulta10.png)

output original (sin DISTINCT):

![output original consulta 10](../capturas_antes_de_correcciones/output_original_consulta10.png)

output despues de las correcciones:

![output corregido consulta 10](../capturas_despues_de_correcciones/output_corregido_consulta10.png)

## Consulta 11 (Profesores y la cantidad de grupos que imparten en el ciclo 2026-1)

Estructura original de la consulta:

![estructura original consulta 11](../capturas_antes_de_correcciones/estructura_original_consulta11.png)

No se realizaron cambios debido a que muestra correctamente los profesores que impartieron en el ciclo 2026-1 y no rompe ninguna regla de reglas_negocio.md

output:

![output consulta 11](../capturas_antes_de_correcciones/output_original_consulta11.png)

## Consulta 12 (Listado de requisitos académicos vigentes, con el nombre de cada curso y su requisito)

Estructura original de la consulta:

![estructura original consulta 12](../capturas_antes_de_correcciones/estructura_original_consulta12.png)

No se realizaron cambios debido a que la consulta muestra cada curso y sus requisitos correspondientes correctamente y no rompe ninguna regla de reglas_negocio.md

output:

![output consulta 12](../capturas_antes_de_correcciones/output_original_consulta12.png)
