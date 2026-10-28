
-- Q01. ¿Que cursos componen la version 102 del plan?
-- Esperado: 7 cursos, 6 obligatorios y 1 optativo.

SELECT
    c.codigo_institucional,
    c.nombre,
    p.tipo_participacion,
    p.nivel_o_periodo_recomendado
FROM participacion_plan AS p
JOIN curso AS c
    ON c.codigo_institucional = p.codigo_curso
WHERE p.id_version_plan = 102
ORDER BY
    p.nivel_o_periodo_recomendado NULLS LAST,
    c.codigo_institucional;


-- Q02. ¿Que requisitos tiene Bases de Datos en la version 102?
-- Esperado: 1 requisito previo y 2 correquisitos.

SELECT
    r.tipo_requisito,
    c.codigo_institucional AS codigo_exigido,
    c.nombre AS curso_exigido
FROM requisito_curso AS r
JOIN curso AS c
    ON c.codigo_institucional = r.codigo_curso_exigido
WHERE r.id_version_plan = 102
  AND r.codigo_curso_objetivo = 'UH-BDAT1'
ORDER BY
    r.tipo_requisito,
    c.codigo_institucional;


-- Q03. ¿Cuantos cursos obligatorios y optativos tiene cada version?
-- Esperado:
-- Version 101: 5 obligatorios, 1 optativo.
-- Version 102: 6 obligatorios, 1 optativo.
-- Version 201: 2 obligatorios, 1 optativo.

SELECT
    p.id_version_plan,
    p.tipo_participacion,
    COUNT(*) AS cantidad_cursos
FROM participacion_plan AS p
GROUP BY
    p.id_version_plan,
    p.tipo_participacion
ORDER BY
    p.id_version_plan,
    p.tipo_participacion;
