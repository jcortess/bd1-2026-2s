
-- Laboratorio 03 - Grupo 03
-- Programacion almacenada

-- C1: Funcion para calcular los creditos obligatorios
-- de una version del plan de estudios.

CREATE OR REPLACE FUNCTION fn_creditos_obligatorios_plan(
    p_id_version INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COALESCE(SUM(c.cantidad_creditos), 0)
    INTO v_total
    FROM participacion_plan AS p
    JOIN curso AS c
        ON c.codigo_institucional = p.codigo_curso
    WHERE p.id_version_plan = p_id_version
      AND p.tipo_participacion = 'Obligatorio';

    RETURN v_total;
END;
$$;


-- C1: Segunda funcion
-- Clasifica los requisitos de un curso dentro de un plan.

CREATE OR REPLACE FUNCTION fn_tipo_requisitos_curso(
    p_codigo_curso TEXT,
    p_id_version INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_previos INTEGER;
    v_correquisitos INTEGER;
BEGIN
    -- Verificar que el curso pertenezca al plan.
    IF NOT EXISTS (
        SELECT 1
        FROM participacion_plan
        WHERE codigo_curso = p_codigo_curso
          AND id_version_plan = p_id_version
    ) THEN
        RETURN 'El curso no pertenece al plan';
    END IF;

    -- Contar los requisitos de cada tipo.
    SELECT
        COUNT(*) FILTER (
            WHERE tipo_requisito = 'Requisito previo'
        ),
        COUNT(*) FILTER (
            WHERE tipo_requisito = 'Correquisito'
        )
    INTO v_previos, v_correquisitos
    FROM requisito_curso
    WHERE codigo_curso_objetivo = p_codigo_curso
      AND id_version_plan = p_id_version;

    -- Decidir el resultado segun los requisitos.
    IF v_previos > 0 AND v_correquisitos > 0 THEN
        RETURN 'Requisitos previos y correquisitos';

    ELSIF v_previos > 0 THEN
        RETURN 'Solo requisitos previos';

    ELSIF v_correquisitos > 0 THEN
        RETURN 'Solo correquisitos';

    ELSE
        RETURN 'Sin requisitos';
    END IF;
END;
$$;


-- C2: Procedimiento para agregar un curso a un plan

CREATE OR REPLACE PROCEDURE sp_agregar_curso_plan(
    p_codigo_curso TEXT,
    p_id_version INTEGER,
    p_tipo_participacion TEXT,
    p_nivel TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Verificar que el curso exista
    IF NOT EXISTS (
        SELECT 1
        FROM curso
        WHERE codigo_institucional = p_codigo_curso
    ) THEN
        RAISE EXCEPTION 'El curso % no existe',
            p_codigo_curso;
    END IF;

    -- Verificar que la version del plan exista
    IF NOT EXISTS (
        SELECT 1
        FROM version_plan_estudios
        WHERE id_version_plan = p_id_version
    ) THEN
        RAISE EXCEPTION 'La version % no existe',
            p_id_version;
    END IF;

    -- Verificar el tipo de participacion
    IF p_tipo_participacion IS NULL
       OR p_tipo_participacion NOT IN (
           'Obligatorio', 'Optativo'
       ) THEN
        RAISE EXCEPTION 'Tipo de participacion invalido: %',
            p_tipo_participacion;
    END IF;

    -- Evitar participaciones duplicadas
    IF EXISTS (
        SELECT 1
        FROM participacion_plan
        WHERE codigo_curso = p_codigo_curso
          AND id_version_plan = p_id_version
    ) THEN
        RAISE EXCEPTION
            'El curso % ya pertenece a la version %',
            p_codigo_curso, p_id_version;
    END IF;

    -- Registrar la participacion
    INSERT INTO participacion_plan (
        codigo_curso,
        id_version_plan,
        tipo_participacion,
        nivel_o_periodo_recomendado
    )
    VALUES (
        p_codigo_curso,
        p_id_version,
        p_tipo_participacion,
        p_nivel
    );

END;
$$;


-- C3: Tecnica procedimental adicional
-- Cursor explicito para listar requisitos de un curso.

CREATE OR REPLACE FUNCTION fn_detalle_requisitos_cursor(
    p_codigo_curso TEXT,
    p_id_version INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_registro RECORD;
    v_detalle TEXT := '';

    -- Declaracion del cursor
    cur_requisitos CURSOR FOR
        SELECT
            r.tipo_requisito,
            c.codigo_institucional,
            c.nombre
        FROM requisito_curso AS r
        JOIN curso AS c
            ON c.codigo_institucional = r.codigo_curso_exigido
        WHERE r.codigo_curso_objetivo = p_codigo_curso
          AND r.id_version_plan = p_id_version
        ORDER BY
            CASE WHEN r.tipo_requisito = 'Requisito previo'
                 THEN 0 ELSE 1 END,
            c.codigo_institucional;

BEGIN
    -- Validar que el curso pertenezca al plan
    IF NOT EXISTS (
        SELECT 1
        FROM participacion_plan
        WHERE codigo_curso = p_codigo_curso
          AND id_version_plan = p_id_version
    ) THEN
        RETURN 'El curso no pertenece al plan';
    END IF;

    -- Abrir el cursor
    OPEN cur_requisitos;

    LOOP
        -- Obtener el siguiente registro
        FETCH cur_requisitos INTO v_registro;

        -- Terminar cuando no existan mas registros
        EXIT WHEN NOT FOUND;

        IF v_detalle <> '' THEN
            v_detalle := v_detalle || E'\n';
        END IF;

        -- Agregar el requisito al texto
        v_detalle := v_detalle || FORMAT(
            '%s: %s (%s)',
            v_registro.tipo_requisito,
            v_registro.nombre,
            v_registro.codigo_institucional
        );
    END LOOP;

    -- Cerrar el cursor
    CLOSE cur_requisitos;

    IF v_detalle = '' THEN
        RETURN 'Sin requisitos';
    END IF;

    RETURN v_detalle;
END;
$$;