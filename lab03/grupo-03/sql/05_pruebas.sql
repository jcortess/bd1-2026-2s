
-- Laboratorio 03 - Grupo 03
-- Pruebas de integridad y funcionamiento

-- P01: Calculo de creditos obligatorios
-- Precondicion: existe la version 102 con sus cursos.
-- Esperado: 22 creditos.

DO $$
DECLARE
    v_resultado INTEGER;
BEGIN
    SELECT fn_creditos_obligatorios_plan(102)
    INTO v_resultado;

    IF v_resultado IS DISTINCT FROM 22 THEN
        RAISE EXCEPTION
            'P01 FALLIDA: esperado 22, obtenido %',
            v_resultado;
    END IF;

    RAISE NOTICE
        'P01 EXITOSA: 22 creditos obligatorios';
END;
$$;


-- P02: Clasificacion de requisitos
-- Precondicion: UH-BDAT1 pertenece a la version 102.
-- Esperado: requisitos previos y correquisitos.

DO $$
DECLARE
    v_resultado TEXT;
BEGIN
    SELECT fn_tipo_requisitos_curso(
        'UH-BDAT1', 102
    )
    INTO v_resultado;

    IF v_resultado IS DISTINCT FROM
       'Requisitos previos y correquisitos' THEN
        RAISE EXCEPTION
            'P02 FALLIDA: resultado %',
            v_resultado;
    END IF;

    RAISE NOTICE
        'P02 EXITOSA: %', v_resultado;
END;
$$;


-- P03: Insercion valida con procedimiento
-- Precondicion: UH-RED1 no pertenece al plan 101.
-- Esperado: insercion exitosa.
-- Se revierte la insercion al terminar.

BEGIN;
SAVEPOINT prueba_p03;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM participacion_plan
        WHERE codigo_curso = 'UH-RED1'
          AND id_version_plan = 101
    ) THEN
        RAISE EXCEPTION
            'P03: precondicion incumplida';
    END IF;

    CALL sp_agregar_curso_plan(
        'UH-RED1', 101, 'Optativo', '4'
    );

    IF NOT EXISTS (
        SELECT 1
        FROM participacion_plan
        WHERE codigo_curso = 'UH-RED1'
          AND id_version_plan = 101
          AND tipo_participacion = 'Optativo'
    ) THEN
        RAISE EXCEPTION
            'P03 FALLIDA: no se inserto el curso';
    END IF;

    RAISE NOTICE
        'P03 EXITOSA: curso agregado correctamente';
END;
$$;

ROLLBACK TO SAVEPOINT prueba_p03;
COMMIT;


-- P04: Rechazar una participacion duplicada
-- Precondicion: UH-PROG1 ya pertenece al plan 102.
-- Esperado: rechazo por clave primaria duplicada.

DO $$
DECLARE
    v_restriccion TEXT;
BEGIN
    BEGIN
        INSERT INTO participacion_plan (
            codigo_curso,
            id_version_plan,
            tipo_participacion
        )
        VALUES ('UH-PROG1', 102, 'Obligatorio');

        RAISE EXCEPTION
            'P04 FALLIDA: se permitio el duplicado';

    EXCEPTION
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS
                v_restriccion = CONSTRAINT_NAME;

            IF v_restriccion <> 'pk_participacion_plan' THEN
                RAISE;
            END IF;

            RAISE NOTICE
                'P04 EXITOSA: duplicado rechazado';
    END;
END;
$$;


-- P05: Rechazar un curso inexistente
-- Precondicion: UH-INEXISTENTE no existe.
-- Esperado: rechazo por clave foranea.

DO $$
DECLARE
    v_restriccion TEXT;
BEGIN
    BEGIN
        INSERT INTO participacion_plan (
            codigo_curso,
            id_version_plan,
            tipo_participacion
        )
        VALUES ('UH-INEXISTENTE', 101, 'Optativo');

        RAISE EXCEPTION
            'P05 FALLIDA: se permitio un curso inexistente';

    EXCEPTION
        WHEN foreign_key_violation THEN
            GET STACKED DIAGNOSTICS
                v_restriccion = CONSTRAINT_NAME;

            IF v_restriccion <> 'fk_participacion_curso' THEN
                RAISE;
            END IF;

            RAISE NOTICE
                'P05 EXITOSA: clave foranea rechazada';
    END;
END;
$$;


-- P06: Rechazar un tipo de participacion invalido
-- Precondicion: UH-RED1 no pertenece al plan 101.
-- Esperado: rechazo por restriccion CHECK.

DO $$
DECLARE
    v_restriccion TEXT;
BEGIN
    BEGIN
        INSERT INTO participacion_plan (
            codigo_curso,
            id_version_plan,
            tipo_participacion
        )
        VALUES ('UH-RED1', 101, 'Electivo');

        RAISE EXCEPTION
            'P06 FALLIDA: se permitio un tipo invalido';

    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS
                v_restriccion = CONSTRAINT_NAME;

            IF v_restriccion <> 'ck_tipo_participacion' THEN
                RAISE;
            END IF;

            RAISE NOTICE
                'P06 EXITOSA: tipo invalido rechazado';
    END;
END;
$$;


-- P07: Insercion valida de un requisito
-- Precondicion: los cursos UH-EST1 y UH-MAT1 existen
-- y la relacion indicada no esta registrada previamente.
-- Esperado: insercion exitosa.
-- Esperado: insercion exitosa.

BEGIN;
SAVEPOINT prueba_p07;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM requisito_curso
        WHERE id_version_plan = 201
          AND codigo_curso_objetivo = 'UH-EST1'
          AND codigo_curso_exigido = 'UH-MAT1'
          AND tipo_requisito = 'Requisito previo'
    ) THEN
        RAISE EXCEPTION 'P07: precondicion incumplida';
    END IF;

    INSERT INTO requisito_curso (
        id_version_plan,
        codigo_curso_objetivo,
        codigo_curso_exigido,
        tipo_requisito
    )
    VALUES (
        201, 'UH-EST1', 'UH-MAT1', 'Requisito previo'
    );

    IF NOT EXISTS (
        SELECT 1 FROM requisito_curso
        WHERE id_version_plan = 201
          AND codigo_curso_objetivo = 'UH-EST1'
          AND codigo_curso_exigido = 'UH-MAT1'
          AND tipo_requisito = 'Requisito previo'
    ) THEN
        RAISE EXCEPTION 'P07 FALLIDA';
    END IF;

    RAISE NOTICE 'P07 EXITOSA: requisito insertado';
END;
$$;

ROLLBACK TO SAVEPOINT prueba_p07;
COMMIT;


-- P08: Actualizacion valida de participacion
-- Precondicion: UH-RED1 es optativo en version 102.
-- Esperado: cambio temporal a obligatorio.

BEGIN;
SAVEPOINT prueba_p08;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM participacion_plan
        WHERE codigo_curso = 'UH-RED1'
          AND id_version_plan = 102
          AND tipo_participacion = 'Optativo'
    ) THEN
        RAISE EXCEPTION 'P08: precondicion incumplida';
    END IF;

    UPDATE participacion_plan
    SET tipo_participacion = 'Obligatorio'
    WHERE codigo_curso = 'UH-RED1'
      AND id_version_plan = 102;

    IF NOT EXISTS (
        SELECT 1 FROM participacion_plan
        WHERE codigo_curso = 'UH-RED1'
          AND id_version_plan = 102
          AND tipo_participacion = 'Obligatorio'
    ) THEN
        RAISE EXCEPTION 'P08 FALLIDA';
    END IF;

    RAISE NOTICE 'P08 EXITOSA: participacion actualizada';
END;
$$;

ROLLBACK TO SAVEPOINT prueba_p08;
COMMIT;


-- P09: Rechazo del procedimiento almacenado
-- Precondicion: UH-PROG1 pertenece a la version 102.
-- Esperado: el procedimiento rechaza el duplicado.

DO $$
DECLARE
    v_rechazado BOOLEAN := FALSE;
    v_mensaje TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM participacion_plan
        WHERE codigo_curso = 'UH-PROG1'
          AND id_version_plan = 102
    ) THEN
        RAISE EXCEPTION 'P09: precondicion incumplida';
    END IF;

    BEGIN
        CALL sp_agregar_curso_plan(
            'UH-PROG1', 102, 'Obligatorio', '1'
        );

    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS
            v_mensaje = MESSAGE_TEXT;

        IF v_mensaje =
            'El curso UH-PROG1 ya pertenece a la version 102'
        THEN
            v_rechazado := TRUE;
        ELSE
            RAISE;
        END IF;
    END;

    IF NOT v_rechazado THEN
        RAISE EXCEPTION
            'P09 FALLIDA: el procedimiento permitio duplicado';
    END IF;

    RAISE NOTICE
        'P09 EXITOSA: procedimiento rechazo duplicado';
END;
$$;