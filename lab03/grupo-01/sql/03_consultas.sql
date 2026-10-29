
-- LABORATORIO 3 - GRUPO 01
-- CLINICA LOS ROBLES
-- B2. CONSULTAS DE NEGOCIO
-- Archivo: 03_consultas.sql


-- ==================================================
-- Q01. Diagnosticos registrados por consulta
-- Pregunta:
-- Que diagnosticos se registraron en cada consulta?
-- Regla: RN-20
-- ==================================================

SELECT
    c.id_consulta,
    c.fecha_hora_inicio,
    d.codigo_diagnostico,
    d.descripcion_diagnostico,
    cd.tipo_categoria,
    cd.condicion
FROM consulta c
INNER JOIN consulta_diagnostico_nm cd
    ON c.id_consulta = cd.id_consulta
INNER JOIN diagnostico d
    ON cd.codigo_diagnostico = d.codigo_diagnostico
ORDER BY
    c.id_consulta,
    CASE
        WHEN cd.tipo_categoria = 'Principal' THEN 0
        ELSE 1
    END,
    d.codigo_diagnostico;


-- ==================================================
-- Q02. Cantidad de diagnosticos por consulta
-- Pregunta:
-- Cuantos diagnosticos principales y secundarios
-- tiene cada consulta?
-- Regla: RN-20
-- ==================================================

SELECT
    c.id_consulta,
    COUNT(cd.codigo_diagnostico) AS total_diagnosticos,
    SUM(
        CASE
            WHEN cd.tipo_categoria = 'Principal' THEN 1
            ELSE 0
        END
    ) AS principales,
    SUM(
        CASE
            WHEN cd.tipo_categoria = 'Secundario' THEN 1
            ELSE 0
        END
    ) AS secundarios
FROM consulta c
LEFT JOIN consulta_diagnostico_nm cd
    ON c.id_consulta = cd.id_consulta
GROUP BY
    c.id_consulta
ORDER BY
    c.id_consulta;


-- ==================================================
-- Q03. Historial de sustitucion de tratamientos
-- Pregunta:
-- Que tratamientos sustituyen a otros y
-- cual es el estado de ambos?
-- Regla: RN-26
-- ==================================================

SELECT
    nuevo.id_consulta,
    anterior.id_tratamiento AS tratamiento_anterior,
    nuevo.id_tratamiento AS tratamiento_nuevo,
    anterior.estado_actual AS estado_anterior,
    nuevo.estado_actual AS estado_nuevo,
    anterior.fecha_inicio_prevista AS inicio_anterior,
    nuevo.fecha_inicio_prevista AS inicio_nuevo
FROM tratamiento nuevo
INNER JOIN tratamiento anterior
    ON nuevo.id_tratamiento_sustituido =
       anterior.id_tratamiento
ORDER BY
    nuevo.id_tratamiento;


-- ==================================================
-- Q04. Observaciones clinicas vigentes
-- Pregunta:
-- Cuales son las versiones vigentes de las
-- observaciones registradas en cada consulta?
-- Regla: RN-19 y supuesto S-13
-- ==================================================

SELECT
    id_consulta,
    consecutivo_observacion,
    num_version,
    contenido_observacion,
    fecha_hora_registro
FROM observacion_clinica
WHERE es_vigente = TRUE
ORDER BY
    id_consulta,
    consecutivo_observacion;
