-- Universidad Horizonte, Grupo 03. Pruebas de estructura e integridad.
-- Prerrequisito: 01_esquema_base.sql y 02_datos_base.sql aplicados una sola vez.
-- Ejecutar con psql -X -v ON_ERROR_STOP=1 -f ...
-- Todo el archivo corre bajo una transaccion que se revierte al finalizar.
-- Las pruebas proporcionan id_requisito explicitamente; la generacion de la
-- identidad ya se ejercita en la semilla comprometida, dado que nextval()
-- no se revierte junto con una transaccion de prueba.

BEGIN;
SET LOCAL search_path TO public;

-- Cobertura EXACTA del conjunto implementado (no se incluyen objetos de extensiones).
DO $schema$
DECLARE
    v_diferencias INTEGER;
    v_tablas INTEGER;
    v_identidad TEXT;
    v_generacion TEXT;
BEGIN
    SELECT COUNT(*) INTO v_tablas
    FROM pg_catalog.pg_tables
    WHERE schemaname = 'public';
    IF v_tablas <> 16 THEN
        RAISE EXCEPTION 'Estructura: esperado 16 tablas; actual %', v_tablas;
    END IF;

    WITH esperado (table_name, column_name, data_type, is_nullable) AS (
        VALUES
            ('estudiante', 'numero_institucional', 'text', 'NO')
            , ('estudiante', 'nombre', 'text', 'NO')
            , ('estudiante', 'primer_apellido', 'text', 'NO')
            , ('estudiante', 'segundo_apellido', 'text', 'YES')
            , ('admision', 'id_admision', 'integer', 'NO')
            , ('admision', 'numero_institucional', 'text', 'NO')
            , ('admision', 'id_sede', 'integer', 'NO')
            , ('admision', 'id_version_plan', 'integer', 'NO')
            , ('admision', 'fecha_ingreso', 'date', 'NO')
            , ('admision', 'condicion_academica', 'text', 'NO')
            , ('admision', 'activa', 'boolean', 'NO')
            , ('carrera', 'id_carrera', 'integer', 'NO')
            , ('sede', 'id_sede', 'integer', 'NO')
            , ('sede', 'nombre', 'text', 'NO')
            , ('version_plan_estudios', 'id_version_plan', 'integer', 'NO')
            , ('version_plan_estudios', 'id_carrera', 'integer', 'NO')
            , ('version_plan_estudios', 'inicio_vigencia', 'date', 'NO')
            , ('version_plan_estudios', 'fin_vigencia', 'date', 'YES')
            , ('periodo_academico', 'id_periodo', 'integer', 'NO')
            , ('periodo_academico', 'codigo_periodo', 'text', 'NO')
            , ('periodo_academico', 'fecha_inicio', 'date', 'NO')
            , ('periodo_academico', 'fecha_finalizacion', 'date', 'NO')
            , ('curso', 'codigo_institucional', 'text', 'NO')
            , ('curso', 'nombre', 'text', 'NO')
            , ('curso', 'cantidad_creditos', 'integer', 'NO')
            , ('curso', 'id_escuela', 'integer', 'NO')
            , ('escuela', 'id_escuela', 'integer', 'NO')
            , ('espacio', 'id_espacio', 'integer', 'NO')
            , ('espacio', 'id_sede', 'integer', 'NO')
            , ('espacio', 'capacidad', 'integer', 'NO')
            , ('espacio', 'ubicacion', 'text', 'NO')
            , ('docente', 'id_docente', 'integer', 'NO')
            , ('docente', 'nombre', 'text', 'NO')
            , ('carrera_sede', 'id_carrera', 'integer', 'NO')
            , ('carrera_sede', 'id_sede', 'integer', 'NO')
            , ('participacion_plan', 'codigo_curso', 'text', 'NO')
            , ('participacion_plan', 'id_version_plan', 'integer', 'NO')
            , ('participacion_plan', 'tipo_participacion', 'text', 'NO')
            , ('participacion_plan', 'nivel_o_periodo_recomendado', 'text', 'YES')
            , ('requisito_curso', 'id_version_plan', 'integer', 'NO')
            , ('requisito_curso', 'codigo_curso_objetivo', 'text', 'NO')
            , ('requisito_curso', 'codigo_curso_exigido', 'text', 'NO')
            , ('requisito_curso', 'tipo_requisito', 'text', 'NO')
            , ('requisito_curso', 'id_requisito', 'integer', 'NO')
            , ('contacto_estudiante', 'id_contacto', 'integer', 'NO')
            , ('contacto_estudiante', 'numero_institucional', 'text', 'NO')
            , ('contacto_estudiante', 'tipo_contacto', 'text', 'NO')
            , ('contacto_estudiante', 'valor', 'text', 'NO')
            , ('contacto_estudiante', 'es_principal', 'boolean', 'NO')
            , ('persona_autorizadora', 'id_autorizador', 'integer', 'NO')
            , ('persona_autorizadora', 'nombre', 'text', 'NO')
            , ('persona_autorizadora', 'identificacion_institucional', 'text', 'NO')
            , ('ventana_periodo', 'id_ventana', 'integer', 'NO')
            , ('ventana_periodo', 'id_periodo', 'integer', 'NO')
            , ('ventana_periodo', 'tipo_ventana', 'text', 'NO')
            , ('ventana_periodo', 'inicio', 'timestamp with time zone', 'NO')
            , ('ventana_periodo', 'fin', 'timestamp with time zone', 'NO')
    ),
    actual AS (
        SELECT table_name, column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name IN (
              'estudiante', 'admision', 'carrera', 'sede', 'version_plan_estudios', 'periodo_academico', 'curso', 'escuela', 'espacio', 'docente', 'carrera_sede', 'participacion_plan', 'requisito_curso', 'contacto_estudiante', 'persona_autorizadora', 'ventana_periodo'
          )
    ),
    faltan AS (SELECT * FROM esperado EXCEPT SELECT * FROM actual),
    sobran AS (SELECT * FROM actual EXCEPT SELECT * FROM esperado)
    SELECT (SELECT COUNT(*) FROM faltan) + (SELECT COUNT(*) FROM sobran)
    INTO v_diferencias;

    IF v_diferencias <> 0 THEN
        RAISE EXCEPTION 'Estructura: % diferencias en columnas/tipos/NOT NULL', v_diferencias;
    END IF;

    SELECT is_identity, identity_generation
    INTO v_identidad, v_generacion
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'requisito_curso'
      AND column_name = 'id_requisito';
    IF v_identidad IS DISTINCT FROM 'YES'
       OR v_generacion IS DISTINCT FROM 'BY DEFAULT' THEN
        RAISE EXCEPTION 'id_requisito: identidad esperada BY DEFAULT';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'btree_gist'
    ) THEN
        RAISE EXCEPTION 'Falta extension btree_gist';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
          AND tablename = 'contacto_estudiante'
          AND indexname = 'uq_contacto_principal_tipo'
    ) THEN
        RAISE EXCEPTION 'Falta indice parcial contacto principal';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'ex_ventana_tipo_periodo_no_solapado'
          AND contype = 'x'
    ) THEN
        RAISE EXCEPTION 'Falta exclusion de ventanas';
    END IF;

    RAISE NOTICE 'Estructura: 16 tablas, 57 atributos, identidad e indices verificados';
END;
$schema$;

-- Inventario de restricciones auditado contra las claves y referencias del modelo.
-- Comprueba composicion y destino de cada clave, no solamente su existencia.
DO $catalogo$
DECLARE
    v_diferencias INTEGER;
    v_acciones_invalidas INTEGER;
BEGIN
    WITH esperado (tabla, nombre, tipo, columnas, destino, columnas_destino) AS (
        VALUES
        ('escuela', 'pk_escuela', 'p', 'id_escuela', '', ''),
        ('carrera', 'pk_carrera', 'p', 'id_carrera', '', ''),
        ('sede', 'pk_sede', 'p', 'id_sede', '', ''),
        ('estudiante', 'pk_estudiante', 'p', 'numero_institucional', '', ''),
        ('docente', 'pk_docente', 'p', 'id_docente', '', ''),
        ('persona_autorizadora', 'pk_persona_autorizadora', 'p', 'id_autorizador', '', ''),
        ('periodo_academico', 'pk_periodo_academico', 'p', 'id_periodo', '', ''),
        ('curso', 'pk_curso', 'p', 'codigo_institucional', '', ''),
        ('version_plan_estudios', 'pk_version_plan_estudios', 'p', 'id_version_plan', '', ''),
        ('carrera_sede', 'pk_carrera_sede', 'p', 'id_carrera,id_sede', '', ''),
        ('espacio', 'pk_espacio', 'p', 'id_espacio', '', ''),
        ('contacto_estudiante', 'pk_contacto_estudiante', 'p', 'id_contacto', '', ''),
        ('ventana_periodo', 'pk_ventana_periodo', 'p', 'id_ventana', '', ''),
        ('participacion_plan', 'pk_participacion_plan', 'p', 'codigo_curso,id_version_plan', '', ''),
        ('requisito_curso', 'pk_requisito_curso', 'p', 'id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito', '', ''),
        ('admision', 'pk_admision', 'p', 'id_admision', '', ''),
        ('persona_autorizadora', 'uq_persona_autorizadora_identificacion', 'u', 'identificacion_institucional', '', ''),
        ('periodo_academico', 'uq_periodo_codigo', 'u', 'codigo_periodo', '', ''),
        ('contacto_estudiante', 'uq_contacto_tipo_valor', 'u', 'numero_institucional,tipo_contacto,valor', '', ''),
        ('requisito_curso', 'uq_requisito_id', 'u', 'id_requisito', '', ''),
        ('curso', 'fk_curso_escuela', 'f', 'id_escuela', 'escuela', 'id_escuela'),
        ('version_plan_estudios', 'fk_version_carrera', 'f', 'id_carrera', 'carrera', 'id_carrera'),
        ('carrera_sede', 'fk_carrera_sede_carrera', 'f', 'id_carrera', 'carrera', 'id_carrera'),
        ('carrera_sede', 'fk_carrera_sede_sede', 'f', 'id_sede', 'sede', 'id_sede'),
        ('espacio', 'fk_espacio_sede', 'f', 'id_sede', 'sede', 'id_sede'),
        ('contacto_estudiante', 'fk_contacto_estudiante', 'f', 'numero_institucional', 'estudiante', 'numero_institucional'),
        ('ventana_periodo', 'fk_ventana_periodo', 'f', 'id_periodo', 'periodo_academico', 'id_periodo'),
        ('participacion_plan', 'fk_participacion_curso', 'f', 'codigo_curso', 'curso', 'codigo_institucional'),
        ('participacion_plan', 'fk_participacion_version', 'f', 'id_version_plan', 'version_plan_estudios', 'id_version_plan'),
        ('requisito_curso', 'fk_requisito_version', 'f', 'id_version_plan', 'version_plan_estudios', 'id_version_plan'),
        ('requisito_curso', 'fk_requisito_objetivo', 'f', 'codigo_curso_objetivo', 'curso', 'codigo_institucional'),
        ('requisito_curso', 'fk_requisito_exigido', 'f', 'codigo_curso_exigido', 'curso', 'codigo_institucional'),
        ('admision', 'fk_admision_estudiante', 'f', 'numero_institucional', 'estudiante', 'numero_institucional'),
        ('admision', 'fk_admision_sede', 'f', 'id_sede', 'sede', 'id_sede'),
        ('admision', 'fk_admision_version', 'f', 'id_version_plan', 'version_plan_estudios', 'id_version_plan')
    ),
    actual AS (
        SELECT
            rel.relname::TEXT AS tabla,
            con.conname::TEXT AS nombre,
            con.contype::TEXT AS tipo,
            array_to_string(ARRAY(
                SELECT att.attname::TEXT
                FROM unnest(con.conkey) WITH ORDINALITY AS pos(num, orden)
                JOIN pg_catalog.pg_attribute att
                  ON att.attrelid=con.conrelid AND att.attnum=pos.num
                ORDER BY pos.orden
            ), ',') AS columnas,
            CASE WHEN con.contype='f' THEN ref.relname::TEXT ELSE '' END AS destino,
            CASE WHEN con.contype='f' THEN
                array_to_string(ARRAY(
                    SELECT att.attname::TEXT
                    FROM unnest(con.confkey) WITH ORDINALITY AS pos(num, orden)
                    JOIN pg_catalog.pg_attribute att
                      ON att.attrelid=con.confrelid AND att.attnum=pos.num
                    ORDER BY pos.orden
                ), ',')
            ELSE '' END AS columnas_destino
        FROM pg_catalog.pg_constraint con
        JOIN pg_catalog.pg_class rel ON rel.oid=con.conrelid
        JOIN pg_catalog.pg_namespace ns ON ns.oid=rel.relnamespace
        LEFT JOIN pg_catalog.pg_class ref ON ref.oid=con.confrelid
        WHERE ns.nspname='public' AND con.contype IN ('p','u','f')
    ),
    faltantes AS (SELECT * FROM esperado EXCEPT SELECT * FROM actual),
    inesperadas AS (SELECT * FROM actual EXCEPT SELECT * FROM esperado)
    SELECT (SELECT COUNT(*) FROM faltantes) + (SELECT COUNT(*) FROM inesperadas)
    INTO v_diferencias;

    IF v_diferencias <> 0 THEN
        RAISE EXCEPTION 'Catalogo: % diferencias en las 16 PK, 15 FK o 4 UNIQUE', v_diferencias;
    END IF;

    -- Las FK del conjunto preservan padres referenciados: nada de cascadas.
    SELECT COUNT(*) INTO v_acciones_invalidas
    FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_class rel ON rel.oid=con.conrelid
    JOIN pg_catalog.pg_namespace ns ON ns.oid=rel.relnamespace
    WHERE ns.nspname='public' AND con.contype='f'
      AND (con.confdeltype <> 'a' OR con.confupdtype <> 'a');
    IF v_acciones_invalidas <> 0 THEN
        RAISE EXCEPTION 'Catalogo: acciones FK distintas de NO ACTION';
    END IF;

    WITH esperado (tabla, nombre) AS (
        VALUES
        ('sede', 'ck_sede_nombre_no_vacio'),
        ('estudiante', 'ck_estudiante_numero_no_vacio'),
        ('estudiante', 'ck_estudiante_nombre_no_vacio'),
        ('estudiante', 'ck_estudiante_primer_apellido_no_vacio'),
        ('estudiante', 'ck_estudiante_segundo_apellido_no_vacio'),
        ('docente', 'ck_docente_nombre_no_vacio'),
        ('persona_autorizadora', 'ck_persona_autorizadora_nombre_no_vacio'),
        ('persona_autorizadora', 'ck_persona_autorizadora_identificacion_no_vacia'),
        ('periodo_academico', 'ck_periodo_codigo_no_vacio'),
        ('periodo_academico', 'ck_periodo_fechas'),
        ('curso', 'ck_curso_codigo_no_vacio'),
        ('curso', 'ck_curso_nombre_no_vacio'),
        ('curso', 'ck_curso_creditos'),
        ('version_plan_estudios', 'ck_version_vigencia'),
        ('espacio', 'ck_espacio_capacidad'),
        ('espacio', 'ck_espacio_ubicacion_no_vacia'),
        ('contacto_estudiante', 'ck_contacto_tipo_no_vacio'),
        ('contacto_estudiante', 'ck_contacto_valor_no_vacio'),
        ('ventana_periodo', 'ck_ventana_tipo'),
        ('ventana_periodo', 'ck_ventana_intervalo'),
        ('participacion_plan', 'ck_tipo_participacion'),
        ('participacion_plan', 'ck_participacion_nivel_no_vacio'),
        ('requisito_curso', 'ck_tipo_requisito'),
        ('requisito_curso', 'ck_requisito_no_autorrequisito'),
        ('admision', 'ck_admision_condicion_no_vacia')
    ),
    actual AS (
        SELECT rel.relname::TEXT, con.conname::TEXT
        FROM pg_catalog.pg_constraint con
        JOIN pg_catalog.pg_class rel ON rel.oid=con.conrelid
        JOIN pg_catalog.pg_namespace ns ON ns.oid=rel.relnamespace
        WHERE ns.nspname='public' AND con.contype='c'
    ),
    faltantes AS (SELECT * FROM esperado EXCEPT SELECT * FROM actual),
    inesperadas AS (SELECT * FROM actual EXCEPT SELECT * FROM esperado)
    SELECT (SELECT COUNT(*) FROM faltantes) + (SELECT COUNT(*) FROM inesperadas)
    INTO v_diferencias;
    IF v_diferencias <> 0 THEN
        RAISE EXCEPTION 'Catalogo: % diferencias entre las 25 CHECK esperadas y las reales', v_diferencias;
    END IF;

    -- El indice parcial debe ser UNIQUE, parcial y compuesto por las dos columnas correctas.
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_index i
        JOIN pg_catalog.pg_class idx ON idx.oid=i.indexrelid
        JOIN pg_catalog.pg_class tbl ON tbl.oid=i.indrelid
        JOIN pg_catalog.pg_namespace ns ON ns.oid=tbl.relnamespace
        WHERE ns.nspname='public'
          AND tbl.relname='contacto_estudiante'
          AND idx.relname='uq_contacto_principal_tipo'
          AND i.indisunique AND i.indpred IS NOT NULL
          AND array_to_string(ARRAY(
              SELECT a.attname::TEXT
              FROM unnest(i.indkey) WITH ORDINALITY AS pos(num, orden)
              JOIN pg_catalog.pg_attribute a
                ON a.attrelid=i.indrelid AND a.attnum=pos.num
              ORDER BY pos.orden
          ), ',')='numero_institucional,tipo_contacto'
    ) THEN
        RAISE EXCEPTION 'Catalogo: definicion incorrecta del indice unico parcial';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint con
        JOIN pg_catalog.pg_class rel ON rel.oid=con.conrelid
        JOIN pg_catalog.pg_namespace ns ON ns.oid=rel.relnamespace
        JOIN pg_catalog.pg_class idx ON idx.oid=con.conindid
        JOIN pg_catalog.pg_am am ON am.oid=idx.relam
        WHERE ns.nspname='public' AND rel.relname='ventana_periodo'
          AND con.conname='ex_ventana_tipo_periodo_no_solapado'
          AND con.contype='x' AND am.amname='gist'
    ) THEN
        RAISE EXCEPTION 'Catalogo: exclusion GiST de ventanas incorrecta o ausente';
    END IF;
    RAISE NOTICE 'Catalogo: 16 PK, 15 FK, 4 UNIQUE, 25 CHECK, indice parcial y exclusion GiST correctos';
END;
$catalogo$;

-- Datos de Lab03 preservados, incluyendo la separacion de cursos obligatorios.
DO $datos$
DECLARE
    v_creditos INTEGER;
    v_requisitos INTEGER;
    v_requisitos_generados INTEGER;
BEGIN
    SELECT COALESCE(SUM(c.cantidad_creditos),0)
    INTO v_creditos
    FROM participacion_plan p
    JOIN curso c ON c.codigo_institucional=p.codigo_curso
    WHERE p.id_version_plan=102 AND p.tipo_participacion='Obligatorio';
    IF v_creditos <> 22 THEN
        RAISE EXCEPTION 'Lab03: esperados 22 creditos; actual %', v_creditos;
    END IF;

    SELECT COUNT(*) INTO v_requisitos
    FROM requisito_curso
    WHERE id_version_plan=102 AND codigo_curso_objetivo='UH-BDAT1';
    IF v_requisitos <> 3 THEN
        RAISE EXCEPTION 'Lab03: tres requisitos esperados para UH-BDAT1 (102)';
    END IF;

    SELECT COUNT(*) INTO v_requisitos_generados
    FROM requisito_curso WHERE id_requisito IS NOT NULL;
    IF v_requisitos_generados <> 10 THEN
        RAISE EXCEPTION 'Lab03: 10 requisitos con ID alternativo generado esperados';
    END IF;

    IF (SELECT COUNT(*) FROM ventana_periodo WHERE tipo_ventana='matricula') <> 2 THEN
        RAISE EXCEPTION 'Semilla: faltan ventanas consecutivas';
    END IF;

    -- Se mantiene la posibilidad de dos ventanas de tipos distintos superpuestas.
    IF NOT EXISTS (
        SELECT 1 FROM ventana_periodo a JOIN ventana_periodo b
          ON a.id_periodo=b.id_periodo AND a.tipo_ventana<>b.tipo_ventana
        WHERE tstzrange(a.inicio,a.fin,'[)') && tstzrange(b.inicio,b.fin,'[)')
    ) THEN
        RAISE EXCEPTION 'Semilla: falta ejemplo de ventanas de tipos distintos';
    END IF;

    -- Cardinalidades basales exactas para que la semilla no se confunda con datos residuales.
    IF EXISTS (
        SELECT 1 FROM (VALUES
            ('escuela', 2),
            ('carrera', 2),
            ('sede', 2),
            ('estudiante', 2),
            ('docente', 2),
            ('persona_autorizadora', 2),
            ('periodo_academico', 1),
            ('curso', 8),
            ('version_plan_estudios', 3),
            ('carrera_sede', 3),
            ('espacio', 2),
            ('contacto_estudiante', 3),
            ('ventana_periodo', 4),
            ('participacion_plan', 16),
            ('requisito_curso', 10),
            ('admision', 2)
        ) AS esperado(tabla, cantidad)
        WHERE (
            CASE esperado.tabla
                WHEN 'escuela' THEN (SELECT COUNT(*) FROM escuela)
                WHEN 'carrera' THEN (SELECT COUNT(*) FROM carrera)
                WHEN 'sede' THEN (SELECT COUNT(*) FROM sede)
                WHEN 'estudiante' THEN (SELECT COUNT(*) FROM estudiante)
                WHEN 'docente' THEN (SELECT COUNT(*) FROM docente)
                WHEN 'persona_autorizadora' THEN (SELECT COUNT(*) FROM persona_autorizadora)
                WHEN 'periodo_academico' THEN (SELECT COUNT(*) FROM periodo_academico)
                WHEN 'curso' THEN (SELECT COUNT(*) FROM curso)
                WHEN 'version_plan_estudios' THEN (SELECT COUNT(*) FROM version_plan_estudios)
                WHEN 'carrera_sede' THEN (SELECT COUNT(*) FROM carrera_sede)
                WHEN 'espacio' THEN (SELECT COUNT(*) FROM espacio)
                WHEN 'contacto_estudiante' THEN (SELECT COUNT(*) FROM contacto_estudiante)
                WHEN 'ventana_periodo' THEN (SELECT COUNT(*) FROM ventana_periodo)
                WHEN 'participacion_plan' THEN (SELECT COUNT(*) FROM participacion_plan)
                WHEN 'requisito_curso' THEN (SELECT COUNT(*) FROM requisito_curso)
                WHEN 'admision' THEN (SELECT COUNT(*) FROM admision)
            END
        ) <> esperado.cantidad
    ) THEN
        RAISE EXCEPTION 'Semilla: cardinalidad inesperada en al menos una relacion';
    END IF;

    -- Comprobar las combinaciones de carrera y sede de las admisiones de prueba.
    IF EXISTS (
        SELECT 1 FROM admision a
        JOIN version_plan_estudios v ON v.id_version_plan = a.id_version_plan
        LEFT JOIN carrera_sede cs ON cs.id_carrera = v.id_carrera
                                 AND cs.id_sede = a.id_sede
        WHERE cs.id_carrera IS NULL
    ) THEN
        RAISE EXCEPTION 'Semilla: admision sin combinacion carrera-sede habilitada';
    END IF;

    RAISE NOTICE 'Datos iniciales: curriculo e intervalos verificados';
END;
$datos$;

-- Casos validos adicionales: deben insertarse y ser observables en la transaccion.
-- El ROLLBACK final retira estos registros de prueba.
INSERT INTO estudiante (numero_institucional, nombre, primer_apellido, segundo_apellido)
VALUES ('UH-TEST-VALIDO', 'Prueba', 'Valida', NULL);

INSERT INTO curso (codigo_institucional, nombre, cantidad_creditos, id_escuela)
VALUES ('UH-TEST-CERO', 'Curso sin creditos', 0, 1);

-- Dos contactos del mismo tipo son validos si solo uno es principal.
INSERT INTO contacto_estudiante (
    id_contacto, numero_institucional, tipo_contacto, valor, es_principal
) VALUES (905, 'UH-ALU1', 'correo', 'ana.alterno@example.test', FALSE);

-- NULL permitido en nivel_o_periodo_recomendado.
INSERT INTO participacion_plan (
    codigo_curso, id_version_plan, tipo_participacion, nivel_o_periodo_recomendado
) VALUES ('UH-PROG1', 201, 'Optativo', NULL);

-- Actualizacion valida de un valor sujeto a CHECK.
UPDATE espacio SET capacidad=31 WHERE id_espacio=1;

INSERT INTO version_plan_estudios (id_version_plan, id_carrera, inicio_vigencia, fin_vigencia)
VALUES (903, 10, DATE '2026-03-01', NULL);

INSERT INTO periodo_academico (id_periodo, codigo_periodo, fecha_inicio, fecha_finalizacion)
VALUES (903, 'PERIODO-TEST-UN-DIA', DATE '2026-03-01', DATE '2026-03-01');

-- Una persona puede tener dos admisiones diferentes y una puede ser inactiva.
-- Ambas combinaciones carrera-sede de la prueba estan habilitadas en la semilla.
INSERT INTO admision (id_admision, numero_institucional, id_sede,
                      id_version_plan, fecha_ingreso, condicion_academica, activa)
VALUES (904, 'UH-ALU1', 2, 102, DATE '2026-08-02', 'regular', FALSE);

-- Un objetivo y un curso exigido pueden no participar en la version;
-- las FK a CURSO, no a PARTICIPACION_PLAN, son intencionales.
-- ID explicito: probar la identidad automatica corresponde a la semilla,
-- evitando consumir nextval() en esta transaccion de prueba.
INSERT INTO requisito_curso (
    id_version_plan, codigo_curso_objetivo, codigo_curso_exigido,
    tipo_requisito, id_requisito
) VALUES (201, 'UH-PROG2', 'UH-PROG1', 'Requisito previo', 910000);

DO $validos$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM estudiante WHERE numero_institucional='UH-TEST-VALIDO')
       OR NOT EXISTS (SELECT 1 FROM curso WHERE codigo_institucional='UH-TEST-CERO' AND cantidad_creditos=0)
       OR NOT EXISTS (SELECT 1 FROM contacto_estudiante WHERE id_contacto=905
         AND numero_institucional='UH-ALU1' AND tipo_contacto='correo' AND es_principal=FALSE)
       OR NOT EXISTS (SELECT 1 FROM participacion_plan WHERE codigo_curso='UH-PROG1'
         AND id_version_plan=201 AND nivel_o_periodo_recomendado IS NULL)
       OR NOT EXISTS (SELECT 1 FROM espacio WHERE id_espacio=1 AND capacidad=31)
       OR NOT EXISTS (SELECT 1 FROM version_plan_estudios WHERE id_version_plan=903 AND fin_vigencia IS NULL)
       OR NOT EXISTS (SELECT 1 FROM periodo_academico WHERE id_periodo=903 AND fecha_inicio=fecha_finalizacion)
       OR NOT EXISTS (SELECT 1 FROM admision WHERE id_admision=904
          AND numero_institucional='UH-ALU1' AND id_sede=2
          AND id_version_plan=102 AND activa=FALSE)
       OR (SELECT COUNT(*) FROM admision WHERE numero_institucional='UH-ALU1') <> 2
       OR NOT EXISTS (SELECT 1 FROM requisito_curso WHERE id_version_plan=201
          AND codigo_curso_objetivo='UH-PROG2' AND codigo_curso_exigido='UH-PROG1'
          AND id_requisito IS NOT NULL) THEN
        RAISE EXCEPTION 'Casos validos: datos insertados incorrectamente';
    END IF;
    RAISE NOTICE 'Casos positivos: inserciones, actualizacion y limites verificados';
END;
$validos$;

-- Los identificadores explicitos de los casos de requisito son distintos
-- del requisito valido 910000; solo la prueba uq_requisito_id
-- duplica deliberadamente un identificador existente.
-- Pruebas negativas de caja negra con causa exacta:
-- SQLSTATE + nombre de constraint, no solo "se produjo algun error".
-- Los errores esperados se revierten dentro de subtransacciones PL/pgSQL.
DO $negativos$
DECLARE
    v_caso RECORD;
    v_codigo TEXT;
    v_restriccion TEXT;
    v_rechazado BOOLEAN;
    v_cantidad INTEGER := 0;
BEGIN
    FOR v_caso IN
        SELECT * FROM (VALUES
            ('PK duplicada', 'INSERT INTO escuela VALUES (1)', '23505', 'pk_escuela')
            , ('estudiante nombre vacio', 'INSERT INTO estudiante VALUES (''UH-NEG1'',''   '',''Rojas'',NULL)', '23514', 'ck_estudiante_nombre_no_vacio')
            , ('apellido opcional blanco', 'INSERT INTO estudiante VALUES (''UH-NEG2'',''Eva'',''Rojas'',''   '')', '23514', 'ck_estudiante_segundo_apellido_no_vacio')
            , ('contacto FK estudiante', 'INSERT INTO contacto_estudiante VALUES (91,''UH-NO-EXISTE'',''correo'',''otro@example.test'',FALSE)', '23503', 'fk_contacto_estudiante')
            , ('contacto principal duplicado', 'INSERT INTO contacto_estudiante VALUES (92,''UH-ALU1'',''correo'',''alterno@example.test'',TRUE)', '23505', 'uq_contacto_principal_tipo')
            , ('contacto terna duplicada', 'INSERT INTO contacto_estudiante VALUES (92,''UH-ALU1'',''correo'',''ana@example.test'',FALSE)', '23505', 'uq_contacto_tipo_valor')
            , ('contacto tipo blanco', 'INSERT INTO contacto_estudiante VALUES (92,''UH-ALU1'',''   '',''otro@example.test'',FALSE)', '23514', 'ck_contacto_tipo_no_vacio')
            , ('curso escuela inexistente', 'INSERT INTO curso VALUES (''UH-NEG-X'',''Curso X'',3,999)', '23503', 'fk_curso_escuela')
            , ('curso creditos negativos', 'INSERT INTO curso VALUES (''UH-NEG-X'',''Curso X'',-1,1)', '23514', 'ck_curso_creditos')
            , ('version fechas invertidas', 'INSERT INTO version_plan_estudios VALUES (991,10,DATE ''2027-01-01'',DATE ''2026-01-01'')', '23514', 'ck_version_vigencia')
            , ('participacion PK duplicada', 'INSERT INTO participacion_plan (codigo_curso,id_version_plan,tipo_participacion) VALUES (''UH-PROG1'',102,''Obligatorio'')', '23505', 'pk_participacion_plan')
            , ('participacion dominio incorrecto', 'INSERT INTO participacion_plan (codigo_curso,id_version_plan,tipo_participacion) VALUES (''UH-SIS1'',102,''Electivo'')', '23514', 'ck_tipo_participacion')
            , ('nivel opcional blanco', 'INSERT INTO participacion_plan VALUES (''UH-SIS1'',102,''Optativo'',''   '')', '23514', 'ck_participacion_nivel_no_vacio')
            , ('requisito PK duplicada', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (101,''UH-PROG2'',''UH-PROG1'',''Requisito previo'',910001)', '23505', 'pk_requisito_curso')
            , ('requisito tipo invalido', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (102,''UH-SIS1'',''UH-PROG1'',''Otro'',910002)', '23514', 'ck_tipo_requisito')
            , ('autorrequisito', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (102,''UH-MAT1'',''UH-MAT1'',''Correquisito'',910003)', '23514', 'ck_requisito_no_autorrequisito')
            , ('requisito exigido inexistente', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (102,''UH-BDAT1'',''UH-INEXISTENTE'',''Correquisito'',910004)', '23503', 'fk_requisito_exigido')
            , ('requisito alternativo duplicado', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) SELECT 102,''UH-PROG1'',''UH-SIS1'',''Correquisito'',MIN(id_requisito) FROM requisito_curso', '23505', 'uq_requisito_id')
            , ('admision estudiante inexistente', 'INSERT INTO admision VALUES (991,''UH-INEXISTENTE'',1,102,DATE ''2026-08-01'',''regular'',TRUE)', '23503', 'fk_admision_estudiante')
            , ('admision condicion vacia', 'INSERT INTO admision VALUES (991,''UH-ALU1'',1,102,DATE ''2026-08-01'',''   '',TRUE)', '23514', 'ck_admision_condicion_no_vacia')
            , ('carrera sede PK duplicada', 'INSERT INTO carrera_sede VALUES (10,1)', '23505', 'pk_carrera_sede')
            , ('espacio capacidad cero', 'INSERT INTO espacio VALUES (991,1,0,''Aula vacia'')', '23514', 'ck_espacio_capacidad')
            , ('espacio sede invalida', 'INSERT INTO espacio VALUES (991,999,15,''Aula X'')', '23503', 'fk_espacio_sede')
            , ('periodo fechas invertidas', 'INSERT INTO periodo_academico VALUES (991,''PERIODO-INV'',DATE ''2026-05-02'',DATE ''2026-05-01'')', '23514', 'ck_periodo_fechas')
            , ('periodo codigo duplicado', 'INSERT INTO periodo_academico VALUES (991,''2026-2'',DATE ''2026-05-01'',DATE ''2026-05-02'')', '23505', 'uq_periodo_codigo')
            , ('ventana tipo invalido', 'INSERT INTO ventana_periodo VALUES (991,1,''desconocido'',''2026-07-15 00:00:00-06'',''2026-07-16 00:00:00-06'')', '23514', 'ck_ventana_tipo')
            , ('ventana longitud cero', 'INSERT INTO ventana_periodo VALUES (991,1,''matricula'',''2026-07-15 00:00:00-06'',''2026-07-15 00:00:00-06'')', '23514', 'ck_ventana_intervalo')
            , ('ventana solapada', 'INSERT INTO ventana_periodo VALUES (991,1,''matricula'',''2026-07-09 00:00:00-06'',''2026-07-11 00:00:00-06'')', '23P01', 'ex_ventana_tipo_periodo_no_solapado')
            , ('ventana periodo inexistente', 'INSERT INTO ventana_periodo VALUES (991,999,''retiro'',''2026-09-01 00:00:00-06'',''2026-09-02 00:00:00-06'')', '23503', 'fk_ventana_periodo')
            , ('autorizador UQ duplicada', 'INSERT INTO persona_autorizadora VALUES (991,''Prueba'',''UH-AUT-01'')', '23505', 'uq_persona_autorizadora_identificacion')
            , ('autor nombre blanco', 'INSERT INTO persona_autorizadora VALUES (991,''    '',''UH-AUT-991'')', '23514', 'ck_persona_autorizadora_nombre_no_vacio')
            , ('delete padre referenciado', 'DELETE FROM periodo_academico WHERE id_periodo=1', '23503', 'fk_ventana_periodo')
            , ('update PK padre referenciado', 'UPDATE periodo_academico SET id_periodo=991 WHERE id_periodo=1', '23503', 'fk_ventana_periodo')
            , ('UPDATE capacidad invalida', 'UPDATE espacio SET capacidad=0 WHERE id_espacio=1', '23514', 'ck_espacio_capacidad')
            , ('sede nombre blanco', 'INSERT INTO sede VALUES (991,''   '')', '23514', 'ck_sede_nombre_no_vacio')
            , ('estudiante codigo blanco', 'INSERT INTO estudiante VALUES (''   '',''Prueba'',''Apellido'',NULL)', '23514', 'ck_estudiante_numero_no_vacio')
            , ('estudiante primer apellido blanco', 'INSERT INTO estudiante VALUES (''UH-NEG3'',''Prueba'',''   '',NULL)', '23514', 'ck_estudiante_primer_apellido_no_vacio')
            , ('docente nombre blanco', 'INSERT INTO docente VALUES (991,''   '')', '23514', 'ck_docente_nombre_no_vacio')
            , ('autorizador codigo blanco', 'INSERT INTO persona_autorizadora VALUES (991,''Autorizante'',''   '')', '23514', 'ck_persona_autorizadora_identificacion_no_vacia')
            , ('periodo codigo blanco', 'INSERT INTO periodo_academico VALUES (991,''   '',DATE ''2026-05-01'',DATE ''2026-05-02'')', '23514', 'ck_periodo_codigo_no_vacio')
            , ('curso codigo blanco', 'INSERT INTO curso VALUES (''   '',''Curso X'',3,1)', '23514', 'ck_curso_codigo_no_vacio')
            , ('curso nombre blanco', 'INSERT INTO curso VALUES (''UH-NEG-N'',''   '',3,1)', '23514', 'ck_curso_nombre_no_vacio')
            , ('espacio ubicacion blanco', 'INSERT INTO espacio VALUES (991,1,10,''   '')', '23514', 'ck_espacio_ubicacion_no_vacia')
            , ('contacto valor blanco', 'INSERT INTO contacto_estudiante VALUES (991,''UH-ALU1'',''telefono'',''   '',FALSE)', '23514', 'ck_contacto_valor_no_vacio')
            , ('version carrera inexistente', 'INSERT INTO version_plan_estudios VALUES (991,999,DATE ''2026-01-01'',NULL)', '23503', 'fk_version_carrera')
            , ('carrera sede carrera inexistente', 'INSERT INTO carrera_sede VALUES (999,1)', '23503', 'fk_carrera_sede_carrera')
            , ('carrera sede sede inexistente', 'INSERT INTO carrera_sede VALUES (10,999)', '23503', 'fk_carrera_sede_sede')
            , ('participacion curso inexistente', 'INSERT INTO participacion_plan (codigo_curso,id_version_plan,tipo_participacion) VALUES (''UH-NO-EXISTE'',102,''Optativo'')', '23503', 'fk_participacion_curso')
            , ('participacion version inexistente', 'INSERT INTO participacion_plan (codigo_curso,id_version_plan,tipo_participacion) VALUES (''UH-SIS1'',999,''Optativo'')', '23503', 'fk_participacion_version')
            , ('requisito version inexistente', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (999,''UH-PROG2'',''UH-PROG1'',''Requisito previo'',910005)', '23503', 'fk_requisito_version')
            , ('requisito objetivo inexistente', 'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (102,''UH-NO-EXISTE'',''UH-PROG1'',''Requisito previo'',910006)', '23503', 'fk_requisito_objetivo')
            , ('admision sede inexistente', 'INSERT INTO admision VALUES (991,''UH-ALU1'',999,102,DATE ''2026-08-01'',''regular'',TRUE)', '23503', 'fk_admision_sede')
            , ('admision version inexistente', 'INSERT INTO admision VALUES (991,''UH-ALU1'',1,999,DATE ''2026-08-01'',''regular'',TRUE)', '23503', 'fk_admision_version')
        ) AS casos(etiqueta, sentencia, codigo_esperado, restriccion_esperada)
    LOOP
        v_codigo := NULL;
        v_restriccion := NULL;
        v_rechazado := FALSE;
        BEGIN
            EXECUTE v_caso.sentencia;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_codigo = RETURNED_SQLSTATE,
                v_restriccion = CONSTRAINT_NAME;
            IF v_codigo IS DISTINCT FROM v_caso.codigo_esperado
               OR v_restriccion IS DISTINCT FROM v_caso.restriccion_esperada THEN
                RAISE EXCEPTION 'Caso %: error no esperado: SQLSTATE %, restriccion %. Esperado % / %',
                    v_caso.etiqueta, v_codigo, v_restriccion,
                    v_caso.codigo_esperado, v_caso.restriccion_esperada;
            END IF;
            v_rechazado := TRUE;
        END;
        IF NOT v_rechazado THEN
            RAISE EXCEPTION 'Caso %: se acepto un cambio invalido', v_caso.etiqueta;
        END IF;
        v_cantidad := v_cantidad + 1;
    END LOOP;

    IF v_cantidad <> 53 THEN
        RAISE EXCEPTION 'No se ejecutaron todos los casos negativos';
    END IF;
    RAISE NOTICE 'Casos negativos: % rechazos por causa exacta confirmados', v_cantidad;
END;
$negativos$;

-- Casos NOT NULL: comprobar columna concreta, no solo un error cualquiera.
DO $nulos$
DECLARE
    v_caso RECORD;
    v_campo TEXT;
    v_codigo TEXT;
    v_cantidad INTEGER := 0;
BEGIN
    FOR v_caso IN
        SELECT * FROM (VALUES
            ('nombre de estudiante',
             'INSERT INTO estudiante (numero_institucional,nombre,primer_apellido) VALUES (''UH-NEG-NULL'',NULL,''Prueba'')', 'nombre'),
            ('activa de admision',
             'INSERT INTO admision VALUES (991,''UH-ALU1'',1,102,DATE ''2026-08-01'',''regular'',NULL)', 'activa'),
            ('fin de ventana',
             'INSERT INTO ventana_periodo VALUES (991,1,''retiro'',''2026-10-01 00:00:00-06'',NULL)', 'fin'),
            ('tipo de requisito',
             'INSERT INTO requisito_curso (id_version_plan,codigo_curso_objetivo,codigo_curso_exigido,tipo_requisito,id_requisito) VALUES (102,''UH-SIS1'',''UH-PROG1'',NULL,910007)', 'tipo_requisito'),
            ('vigencia inicial',
             'INSERT INTO version_plan_estudios (id_version_plan,id_carrera,inicio_vigencia,fin_vigencia) VALUES (991,10,NULL,NULL)', 'inicio_vigencia')
        ) AS casos(etiqueta, sentencia, columna_esperada)
    LOOP
        v_campo := NULL;
        v_codigo := NULL;
        BEGIN
            EXECUTE v_caso.sentencia;
        EXCEPTION WHEN not_null_violation THEN
            GET STACKED DIAGNOSTICS
                v_codigo = RETURNED_SQLSTATE,
                v_campo = COLUMN_NAME;
            IF v_codigo IS DISTINCT FROM '23502'
               OR v_campo IS DISTINCT FROM v_caso.columna_esperada THEN
                RAISE EXCEPTION
                    'NOT NULL %: error inesperado (SQLSTATE %, columna %)',
                    v_caso.etiqueta, v_codigo, v_campo;
            END IF;
            v_cantidad := v_cantidad + 1;
        END;
        IF v_codigo IS NULL THEN
            RAISE EXCEPTION 'NOT NULL %: se acepto el NULL prohibido', v_caso.etiqueta;
        END IF;
    END LOOP;

    IF v_cantidad <> 5 THEN
        RAISE EXCEPTION 'NOT NULL: esperados 5 rechazos, observados %', v_cantidad;
    END IF;
    RAISE NOTICE 'Nulabilidad: 5 comprobaciones NOT NULL por columna';
END;
$nulos$;

-- Confirmacion de que los rechazos no mutaron los hechos de referencia.
DO $posterior$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM periodo_academico
                   WHERE id_periodo=1 AND codigo_periodo='2026-2')
       OR (SELECT COUNT(*) FROM ventana_periodo WHERE id_periodo=1) <> 4
       OR (SELECT COUNT(*) FROM requisito_curso) <> 11
       OR (SELECT COUNT(*) FROM contacto_estudiante WHERE numero_institucional='UH-ALU1') <> 3
       OR NOT EXISTS (SELECT 1 FROM escuela WHERE id_escuela=1) THEN
       RAISE EXCEPTION 'Se modifico indebidamente el estado tras los rechazos';
    END IF;
    RAISE NOTICE 'Estado posterior: rechazos sin efectos indebidos';
END;
$posterior$;

-- Los INSERT validos de esta prueba no persisten.
ROLLBACK;
