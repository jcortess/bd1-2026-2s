-- Universidad Horizonte, Grupo 03. Pruebas de integridad de relaciones adicionales.
-- Ejecutar despues de probar las 16 relaciones base, crear las diez tablas
-- y cargar 04_datos_relaciones.sql. Repetible: la prueba termina en ROLLBACK.
-- No sustituye la validacion contextual ni las pruebas de G03-P01, G03-P02 y G03-P03.

BEGIN;
SET LOCAL search_path TO public;

-- 1. Metadatos: inventario exacto (26 tablas, 135 atributos) y
--    78 columnas nuevas con nombre, tipo y nulabilidad del diccionario.
DO $validacion$
DECLARE
    v_tablas INTEGER;
    v_atributos INTEGER;
    v_diferencias TEXT;
BEGIN
    SELECT COUNT(*) INTO v_tablas
    FROM pg_tables WHERE schemaname = 'public';
    SELECT COUNT(*) INTO v_atributos
    FROM information_schema.columns WHERE table_schema = 'public';
    IF v_tablas <> 26 OR v_atributos <> 135 THEN
        RAISE EXCEPTION 'estructura: esperado 26/135, obtenido %/%',
            v_tablas, v_atributos;
    END IF;

    WITH esperado(tabla, columna, tipo, nullable) AS (
        VALUES
        ('grupo', 'id_grupo', 'integer', 'NO'),
        ('grupo', 'numero_grupo', 'integer', 'NO'),
        ('grupo', 'codigo_curso', 'text', 'NO'),
        ('grupo', 'id_periodo', 'integer', 'NO'),
        ('grupo', 'id_sede', 'integer', 'NO'),
        ('grupo', 'capacidad', 'integer', 'NO'),
        ('grupo', 'modalidad', 'text', 'NO'),
        ('grupo', 'estado_oferta', 'text', 'NO'),
        ('bloque_horario', 'id_bloque', 'integer', 'NO'),
        ('bloque_horario', 'id_grupo', 'integer', 'NO'),
        ('bloque_horario', 'dia_semana', 'integer', 'NO'),
        ('bloque_horario', 'hora_inicio', 'time without time zone', 'NO'),
        ('bloque_horario', 'hora_fin', 'time without time zone', 'NO'),
        ('bloque_horario', 'es_presencial', 'boolean', 'NO'),
        ('bloque_horario', 'id_espacio', 'integer', 'YES'),
        ('solicitud_matricula', 'id_solicitud', 'integer', 'NO'),
        ('solicitud_matricula', 'id_admision', 'integer', 'NO'),
        ('solicitud_matricula', 'id_grupo', 'integer', 'NO'),
        ('solicitud_matricula', 'id_solicitud_anterior', 'integer', 'YES'),
        ('solicitud_matricula', 'id_version_plan_evaluada', 'integer', 'NO'),
        ('solicitud_matricula', 'fecha_solicitud', 'timestamp with time zone', 'NO'),
        ('solicitud_matricula', 'estado', 'text', 'NO'),
        ('solicitud_matricula', 'razon_rechazo_espera', 'text', 'YES'),
        ('solicitud_matricula', 'orden_espera', 'integer', 'YES'),
        ('solicitud_matricula', 'momento_transicion', 'timestamp with time zone', 'YES'),
        ('solicitud_matricula', 'calificacion', 'text', 'YES'),
        ('solicitud_matricula', 'resultado_academico', 'text', 'YES'),
        ('traslado_plan', 'id_traslado', 'integer', 'NO'),
        ('traslado_plan', 'id_admision', 'integer', 'NO'),
        ('traslado_plan', 'id_version_origen', 'integer', 'NO'),
        ('traslado_plan', 'id_version_destino', 'integer', 'NO'),
        ('traslado_plan', 'fecha', 'timestamp with time zone', 'NO'),
        ('traslado_plan', 'motivo', 'text', 'NO'),
        ('traslado_plan', 'id_autorizador', 'integer', 'NO'),
        ('reconocimiento_academico', 'id_reconocimiento', 'integer', 'NO'),
        ('reconocimiento_academico', 'id_admision', 'integer', 'NO'),
        ('reconocimiento_academico', 'referencia_curso_reconocido', 'text', 'YES'),
        ('reconocimiento_academico', 'codigo_curso_reconocido', 'text', 'YES'),
        ('reconocimiento_academico', 'id_version_plan', 'integer', 'NO'),
        ('reconocimiento_academico', 'codigo_curso_satisfecho', 'text', 'NO'),
        ('reconocimiento_academico', 'resolucion_academica', 'text', 'NO'),
        ('reconocimiento_academico', 'fecha_resolucion', 'timestamp with time zone', 'NO'),
        ('grupo_docente', 'id_grupo', 'integer', 'NO'),
        ('grupo_docente', 'id_docente', 'integer', 'NO'),
        ('grupo_docente', 'rol', 'text', 'NO'),
        ('historial_oferta', 'id_cambio', 'integer', 'NO'),
        ('historial_oferta', 'id_grupo', 'integer', 'NO'),
        ('historial_oferta', 'tipo_cambio', 'text', 'NO'),
        ('historial_oferta', 'estado_anterior', 'text', 'YES'),
        ('historial_oferta', 'estado_nuevo', 'text', 'YES'),
        ('historial_oferta', 'cupo_anterior', 'integer', 'YES'),
        ('historial_oferta', 'cupo_nuevo', 'integer', 'YES'),
        ('historial_oferta', 'fecha_cambio', 'timestamp with time zone', 'NO'),
        ('historial_oferta', 'motivo', 'text', 'NO'),
        ('historial_oferta', 'id_responsable', 'integer', 'NO'),
        ('historial_solicitud', 'id_evento', 'integer', 'NO'),
        ('historial_solicitud', 'id_solicitud', 'integer', 'NO'),
        ('historial_solicitud', 'tipo_evento', 'text', 'NO'),
        ('historial_solicitud', 'estado_anterior', 'text', 'YES'),
        ('historial_solicitud', 'estado_nuevo', 'text', 'YES'),
        ('historial_solicitud', 'fecha_evento', 'timestamp with time zone', 'NO'),
        ('historial_solicitud', 'motivo', 'text', 'YES'),
        ('historial_solicitud', 'id_actor', 'integer', 'YES'),
        ('excepcion_requisito', 'id_excepcion', 'integer', 'NO'),
        ('excepcion_requisito', 'id_solicitud', 'integer', 'NO'),
        ('excepcion_requisito', 'id_requisito', 'integer', 'NO'),
        ('excepcion_requisito', 'id_autorizador', 'integer', 'NO'),
        ('excepcion_requisito', 'fecha_autorizacion', 'timestamp with time zone', 'NO'),
        ('excepcion_requisito', 'motivo', 'text', 'NO'),
        ('historial_correccion_calificacion', 'id_correccion', 'integer', 'NO'),
        ('historial_correccion_calificacion', 'id_solicitud', 'integer', 'NO'),
        ('historial_correccion_calificacion', 'calificacion_anterior', 'text', 'YES'),
        ('historial_correccion_calificacion', 'calificacion_nueva', 'text', 'YES'),
        ('historial_correccion_calificacion', 'resultado_anterior', 'text', 'YES'),
        ('historial_correccion_calificacion', 'resultado_nuevo', 'text', 'YES'),
        ('historial_correccion_calificacion', 'fecha_correccion', 'timestamp with time zone', 'NO'),
        ('historial_correccion_calificacion', 'motivo', 'text', 'NO'),
        ('historial_correccion_calificacion', 'id_autorizador', 'integer', 'NO')
    ), observado AS (
        SELECT table_name AS tabla, column_name AS columna,
               data_type AS tipo, is_nullable AS nullable
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name IN (SELECT DISTINCT tabla FROM esperado)
    ), diferencias AS (
        SELECT COALESCE(e.tabla, o.tabla) AS tabla,
               COALESCE(e.columna, o.columna) AS columna
        FROM esperado e
        FULL OUTER JOIN observado o
          ON o.tabla = e.tabla AND o.columna = e.columna
        WHERE e.columna IS NULL OR o.columna IS NULL
           OR e.tipo IS DISTINCT FROM o.tipo
           OR e.nullable IS DISTINCT FROM o.nullable
    )
    SELECT string_agg(tabla || '.' || columna, ', ' ORDER BY tabla, columna)
    INTO v_diferencias FROM diferencias;

    IF v_diferencias IS NOT NULL THEN
        RAISE EXCEPTION 'atributos no conformes: %', v_diferencias;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_index i
        JOIN pg_class ix ON ix.oid = i.indexrelid
        JOIN pg_class t ON t.oid = i.indrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = 'public'
          AND t.relname = 'grupo_docente'
          AND ix.relname = 'uq_grupo_docente_responsable'
          AND i.indisunique
          AND i.indpred IS NOT NULL
          AND pg_get_expr(i.indpred, i.indrelid) LIKE '%rol%responsable%'
    ) THEN
        RAISE EXCEPTION 'falta indice UNICO parcial del responsable';
    END IF;

    IF (SELECT COUNT(*) FROM admision WHERE id_admision IN (1,2,3)) <> 3
       OR (SELECT COUNT(*) FROM grupo) <> 4
       OR (SELECT COUNT(*) FROM bloque_horario) <> 5
       OR (SELECT COUNT(*) FROM grupo_docente) <> 5
       OR (SELECT COUNT(*) FROM traslado_plan) <> 1
       OR (SELECT COUNT(*) FROM reconocimiento_academico) <> 1
       OR (SELECT COUNT(*) FROM solicitud_matricula) <> 0
       OR (SELECT COUNT(*) FROM historial_oferta) <> 0
       OR (SELECT COUNT(*) FROM historial_solicitud) <> 0
       OR (SELECT COUNT(*) FROM excepcion_requisito) <> 0
       OR (SELECT COUNT(*) FROM historial_correccion_calificacion) <> 0 THEN
        RAISE EXCEPTION 'semilla no coincide con los datos esperados';
    END IF;
    RAISE NOTICE 'estructura conforme: 26 tablas, 135 atributos, 78 nuevas columnas';
    RAISE NOTICE 'datos iniciales conformes (sin resultados operativos precargados)';
END;
$validacion$;

-- 2. Contexto y casos positivos y de frontera, dentro de la transaccion revertida.
-- Estos hechos son fixtures sinteticos de integridad declarativa, NO la
-- ejecucion ni evidencia de G03-P01/P02/P03. El modelo completo se valida
-- por separado mediante los mecanismos y procesos correspondientes.

-- Grupos adicionales para limites (capacidad cero, modalidad y horario).
INSERT INTO grupo (
    id_grupo, numero_grupo, codigo_curso, id_periodo, id_sede,
    capacidad, modalidad, estado_oferta
) VALUES
    (20, 1, 'UH-RED1',  1, 1, 0, 'virtual',     'cerrada'),
    (21, 2, 'UH-PROG1', 1, 1, 1, 'presencial', 'cerrada'),
    (23, 3, 'UH-PROG1', 1, 1, 0, 'virtual',     'cerrada');

-- DELETE permitido de un grupo sin referencias.
DELETE FROM grupo WHERE id_grupo = 23;

INSERT INTO bloque_horario (
    id_bloque, id_grupo, dia_semana, hora_inicio, hora_fin,
    es_presencial, id_espacio
) VALUES
    (900, 20, 7, TIME '12:00', TIME '13:00', FALSE, 1),
    (902, 21, 2, TIME '12:00', TIME '13:00', TRUE, 1);

-- El bloque no presencial con espacio no esta expresamente prohibido.
-- No existe ocupacion simultanea del espacio: el bloque 902 es martes 12-13.
UPDATE bloque_horario SET hora_fin = TIME '13:30' WHERE id_bloque = 900;
UPDATE grupo SET capacidad = 1 WHERE id_grupo = 20;

INSERT INTO grupo_docente (id_grupo, id_docente, rol) VALUES
    (20, 1, 'responsable'),
    (21, 2, 'responsable');

-- Dos admisiones historicas de prueba, con version vigente tras traslado;
-- las fechas preceden a las solicitudes de julio.
INSERT INTO admision (
    id_admision, numero_institucional, id_sede, id_version_plan,
    fecha_ingreso, condicion_academica, activa
) VALUES
    (4, 'UH-ALU2', 2, 102, DATE '2024-09-01', 'regular', TRUE),
    (5, 'UH-ALU1', 1, 102, DATE '2024-10-01', 'regular', TRUE);

INSERT INTO traslado_plan (
    id_traslado, id_admision, id_version_origen,
    id_version_destino, fecha, motivo, id_autorizador
) VALUES
    (900, 4, 101, 102, '2026-03-01 09:00:00-06',
        'Traslado de contexto academico', 2),
    (901, 5, 101, 102, '2026-03-02 09:00:00-06',
        'Traslado para probar referencia sin otras dependencias', 2);

-- Reconocimiento institucional valido y reconocimientos externos que
-- preparan el expediente, sin implementar el flujo de reconocimiento.
INSERT INTO reconocimiento_academico (
    id_reconocimiento, id_admision, referencia_curso_reconocido,
    codigo_curso_reconocido, id_version_plan, codigo_curso_satisfecho,
    resolucion_academica, fecha_resolucion
) VALUES
    (900, 1, NULL, 'UH-BDAT1', 102, 'UH-BDAT1',
        'RES-PRUEBA-900', '2026-09-04 10:00:00-06'),
    (910, 3, 'EXT-MAT-910', NULL, 102, 'UH-MAT1',
        'RES-PRUEBA-910', '2026-03-11 10:00:00-06'),
    (911, 3, 'EXT-EST-911', NULL, 102, 'UH-EST1',
        'RES-PRUEBA-911', '2026-03-11 11:00:00-06'),
    (912, 4, 'EXT-EST-912', NULL, 102, 'UH-EST1',
        'RES-PRUEBA-912', '2026-03-12 10:00:00-06');

-- Oferta temporal abierta con eventos de apertura coherentes con
-- el estado actual; no representa el procedimiento G03-P01.
INSERT INTO historial_oferta (
    id_cambio, id_grupo, tipo_cambio, estado_anterior, estado_nuevo,
    cupo_anterior, cupo_nuevo, fecha_cambio, motivo, id_responsable
) VALUES
    (910, 11, 'apertura', 'cerrada', 'abierta', NULL, NULL,
        '2026-07-02 08:00:00-06', 'Oferta para prueba declarativa', 1),
    (911, 12, 'apertura', 'cerrada', 'abierta', NULL, NULL,
        '2026-07-02 08:00:00-06', 'Oferta para prueba declarativa', 1),
    (912, 13, 'apertura', 'cerrada', 'abierta', NULL, NULL,
        '2026-07-02 08:00:00-06', 'Oferta para prueba declarativa', 1);
UPDATE grupo SET estado_oferta = 'abierta' WHERE id_grupo IN (11, 12, 13);

-- Los cuatro tipos de cambio: los valores anteriores/nuevos tienen
-- continuidad y el grupo 20 queda con estado y cupo actuales coherentes.
INSERT INTO historial_oferta (
    id_cambio, id_grupo, tipo_cambio, estado_anterior, estado_nuevo,
    cupo_anterior, cupo_nuevo, fecha_cambio, motivo, id_responsable
) VALUES
    (900, 20, 'apertura', 'cerrada', 'abierta', NULL, NULL,
        '2026-07-02 08:00:00-06', 'Apertura de prueba', 1),
    (901, 20, 'cambio_cupo', NULL, NULL, 0, 1,
        '2026-07-02 09:00:00-06', 'Ajuste de cupo de prueba', 1),
    (902, 20, 'cierre', 'abierta', 'cerrada', NULL, NULL,
        '2026-07-02 10:00:00-06', 'Cierre de prueba', 1),
    (903, 20, 'cancelacion', 'cerrada', 'cancelada', NULL, NULL,
        '2026-07-02 11:00:00-06', 'Cancelacion de prueba', 1);
UPDATE grupo SET estado_oferta = 'cancelada' WHERE id_grupo = 20;

-- Solicitudes temporales con admisiones ya existentes en julio:
-- 903 matricula MAT1 (correquisito del alumno 2);
-- 901 matricula BDAT1 (alumno 1), llenando el unico cupo del grupo 13;
-- 900 solicita el mismo grupo estando lleno y pasa inicialmente a espera;
-- 902 rechaza cambio al grupo 10, cerrado y con capacidad cero;
-- 904 fue matriculada en PROG1 y retirada dentro de la ventana;
-- 905 quedo anulada administrativamente.
INSERT INTO solicitud_matricula (
    id_solicitud, id_admision, id_grupo, id_solicitud_anterior,
    id_version_plan_evaluada, fecha_solicitud, estado,
    razon_rechazo_espera, orden_espera, momento_transicion,
    calificacion, resultado_academico
) VALUES
    (903, 4, 11, NULL, 102, '2026-07-03 08:00:00-06', 'matriculada',
        NULL, NULL, NULL, NULL, NULL),
    (901, 3, 13, NULL, 102, '2026-07-04 08:00:00-06', 'matriculada',
        NULL, NULL, NULL, NULL, NULL),
    (900, 4, 13, NULL, 102, '2026-07-05 08:00:00-06', 'en_espera',
        'Sin cupo al solicitar', 1, NULL, NULL, NULL),
    (902, 3, 10, 901, 102, '2026-07-05 08:30:00-06', 'rechazada',
        'Oferta cerrada y cupo cero', NULL, NULL, NULL, NULL),
    (904, 3, 12, NULL, 102, '2026-07-09 08:00:00-06', 'retirada',
        NULL, NULL, NULL, NULL, NULL),
    (905, 4, 12, NULL, 102, '2026-07-06 08:00:00-06', 'anulada',
        NULL, NULL, NULL, NULL, NULL);

-- Excepcion autorizada a PROG2, requisito previo de BDAT1;
-- co-requisitos de 901 y 900 estan satisfechos por reconocimiento
-- de EST1 y por reconocimiento/matricula del mismo periodo de MAT1.
INSERT INTO excepcion_requisito (
    id_excepcion, id_solicitud, id_requisito, id_autorizador,
    fecha_autorizacion, motivo
)
SELECT x.id_excepcion, x.id_solicitud, r.id_requisito, x.id_autorizador,
       x.fecha_autorizacion, x.motivo
FROM (VALUES
    (900, 901, 1, '2026-07-04 08:01:00-06'::timestamptz,
        'Excepcion autorizada al requisito previo PROG2'),
    (901, 900, 2, '2026-07-05 08:01:00-06'::timestamptz,
        'Excepcion autorizada al requisito previo PROG2')
) AS x(id_excepcion,id_solicitud,id_autorizador,fecha_autorizacion,motivo)
JOIN requisito_curso r
  ON r.id_version_plan = 102
 AND r.codigo_curso_objetivo = 'UH-BDAT1'
 AND r.codigo_curso_exigido = 'UH-PROG2'
 AND r.tipo_requisito = 'Requisito previo';

INSERT INTO historial_solicitud (
    id_evento, id_solicitud, tipo_evento, estado_anterior,
    estado_nuevo, fecha_evento, motivo, id_actor
) VALUES
    (900, 903, 'transicion', NULL, 'matriculada',
        '2026-07-03 08:00:00-06', NULL, NULL),
    (901, 901, 'transicion', NULL, 'matriculada',
        '2026-07-04 08:05:00-06', NULL, NULL),
    (902, 900, 'transicion', NULL, 'en_espera',
        '2026-07-05 08:05:00-06', 'Ingreso a espera por cupo', NULL),
    (903, 900, 'evaluacion_espera', 'en_espera', 'en_espera',
        '2026-07-08 12:00:00-06', 'Aun no hay cupo adicional', NULL),
    (904, 902, 'transicion', NULL, 'rechazada',
        '2026-07-05 08:30:00-06', 'Oferta cerrada y cupo cero', NULL),
    (905, 904, 'transicion', NULL, 'matriculada',
        '2026-07-09 08:00:00-06', NULL, NULL),
    (906, 904, 'transicion', 'matriculada', 'retirada',
        '2026-08-05 09:00:00-06', 'Retiro durante ventana autorizada', NULL),
    (907, 905, 'transicion', NULL, 'anulada',
        '2026-07-06 08:15:00-06', 'Anulacion administrativa', 1),
    (908, 900, 'evaluacion_espera', NULL, NULL,
        '2026-07-08 12:05:00-06', 'Permanece en espera', NULL);

-- Se incrementa temporalmente la capacidad del grupo lleno y se
-- documenta el cambio; se comprueba una transicion representable, NO
-- el procedimiento de promocion ni sus condiciones de concurrencia.
INSERT INTO historial_oferta (
    id_cambio, id_grupo, tipo_cambio, estado_anterior, estado_nuevo,
    cupo_anterior, cupo_nuevo, fecha_cambio, motivo, id_responsable
) VALUES (950, 13, 'cambio_cupo', NULL, NULL, 1, 2,
          '2026-07-08 13:00:00-06', 'Ampliacion de cupo de prueba', 1);
UPDATE grupo SET capacidad = 2 WHERE id_grupo = 13;

INSERT INTO historial_solicitud (
    id_evento, id_solicitud, tipo_evento, estado_anterior,
    estado_nuevo, fecha_evento, motivo, id_actor
) VALUES (909, 900, 'transicion', 'en_espera', 'matriculada',
          '2026-07-08 14:00:00-06', 'Cupo disponible tras ampliacion', NULL);
UPDATE solicitud_matricula
SET estado = 'matriculada', momento_transicion = '2026-07-08 14:00:00-06'
WHERE id_solicitud = 900;

-- Se prepara el primer resultado al finalizar el periodo lectivo;
-- la fecha de solicitud permanece en julio. Esto no implementa notas.
UPDATE solicitud_matricula
SET calificacion = '80', resultado_academico = 'incompleto'
WHERE id_solicitud = 901;

-- Correcciones secuenciales coherentes con la calificacion actual.
INSERT INTO historial_correccion_calificacion (
    id_correccion, id_solicitud, calificacion_anterior,
    calificacion_nueva, resultado_anterior, resultado_nuevo,
    fecha_correccion, motivo, id_autorizador
) VALUES (900, 901, '80', '85', 'incompleto', 'aprobado',
          '2026-12-16 12:00:00-06', 'Rectificacion de registro', 1);
UPDATE solicitud_matricula
SET calificacion = '85', resultado_academico = 'aprobado'
WHERE id_solicitud = 901;
INSERT INTO historial_correccion_calificacion (
    id_correccion, id_solicitud, calificacion_anterior,
    calificacion_nueva, resultado_anterior, resultado_nuevo,
    fecha_correccion, motivo, id_autorizador
) VALUES (901, 901, '85', '90', 'aprobado', 'aprobado',
          '2026-12-17 12:00:00-06', 'Segunda rectificacion', 1);
UPDATE solicitud_matricula SET calificacion = '90' WHERE id_solicitud = 901;

-- UPDATE permitido de reconocimiento preservando el origen XOR.
UPDATE reconocimiento_academico
SET referencia_curso_reconocido = 'EXT-OTRO', codigo_curso_reconocido = NULL
WHERE id_reconocimiento = 900;
UPDATE reconocimiento_academico
SET referencia_curso_reconocido = NULL, codigo_curso_reconocido = 'UH-BDAT1'
WHERE id_reconocimiento = 900;

DO $validacion$
DECLARE
    v_integros BOOLEAN;
BEGIN
    SELECT (
       (SELECT COUNT(*) FROM grupo WHERE id_grupo IN (20, 21)) = 2
       AND NOT EXISTS (SELECT 1 FROM grupo WHERE id_grupo = 23)
       AND (SELECT COUNT(*) FROM historial_oferta WHERE id_cambio IN (900,901,902,903,910,911,912,950)) = 8
       AND (SELECT COUNT(*) FROM solicitud_matricula WHERE id_solicitud BETWEEN 900 AND 905) = 6
       AND (SELECT COUNT(*) FROM excepcion_requisito WHERE id_excepcion IN (900,901)) = 2
       AND (SELECT estado_oferta = 'cancelada' AND capacidad = 1 FROM grupo WHERE id_grupo = 20)
       AND (SELECT estado_oferta = 'abierta' AND capacidad = 2 FROM grupo WHERE id_grupo = 13)
       AND (SELECT estado = 'matriculada' AND orden_espera = 1
                   AND razon_rechazo_espera = 'Sin cupo al solicitar'
                   AND momento_transicion = '2026-07-08 14:00:00-06'::timestamptz
            FROM solicitud_matricula WHERE id_solicitud = 900)
       AND (SELECT estado = 'matriculada' AND calificacion = '90'
                   AND resultado_academico = 'aprobado'
            FROM solicitud_matricula WHERE id_solicitud = 901)
       AND (SELECT estado = 'retirada' FROM solicitud_matricula WHERE id_solicitud = 904)
       AND (SELECT estado = 'anulada' FROM solicitud_matricula WHERE id_solicitud = 905)
       AND (SELECT COUNT(*) = 2 FROM historial_correccion_calificacion
            WHERE id_solicitud = 901)
    ) INTO v_integros;
    IF v_integros IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'inconsistencias en los hechos positivos de prueba';
    END IF;
    RAISE NOTICE 'casos positivos, fronteras y UPDATE/DELETE permitidos conformes';
END;
$validacion$;

-- 3. Casos negativos. Cada sentencia se ejecuta en subtransaccion
--    PL/pgSQL; solo se acepta el SQLSTATE y la restriccion/columna exactos.
DO $validacion$
DECLARE
    r RECORD;
    v_sqlstate TEXT;
    v_restriccion TEXT;
    v_columna TEXT;
    v_detalle TEXT;
    v_antes INTEGER[];
    v_despues INTEGER[];
    v_exitos INTEGER := 0;
BEGIN
    v_antes := ARRAY[
        (SELECT COUNT(*) FROM grupo),
        (SELECT COUNT(*) FROM bloque_horario),
        (SELECT COUNT(*) FROM solicitud_matricula),
        (SELECT COUNT(*) FROM traslado_plan),
        (SELECT COUNT(*) FROM reconocimiento_academico),
        (SELECT COUNT(*) FROM grupo_docente),
        (SELECT COUNT(*) FROM historial_oferta),
        (SELECT COUNT(*) FROM historial_solicitud),
        (SELECT COUNT(*) FROM excepcion_requisito),
        (SELECT COUNT(*) FROM historial_correccion_calificacion)
    ];
    FOR r IN
        SELECT prueba, estado_esperado, origen_esperado, sentencia
        FROM (VALUES
            ('grupo PK', '23505', 'pk_grupo', $sql$INSERT INTO grupo VALUES (20,99,'UH-RED1',1,1,2,'virtual','cerrada')$sql$),
            ('grupo UQ contexto', '23505', 'uq_grupo_contexto', $sql$INSERT INTO grupo VALUES (990,1,'UH-BDAT1',1,1,2,'virtual','cerrada')$sql$),
            ('grupo capacidad negativa', '23514', 'ck_grupo_capacidad', $sql$INSERT INTO grupo VALUES (990,99,'UH-RED1',1,1,-1,'virtual','cerrada')$sql$),
            ('grupo modalidad', '23514', 'ck_grupo_modalidad', $sql$INSERT INTO grupo VALUES (990,99,'UH-RED1',1,1,2,'hibrida','cerrada')$sql$),
            ('grupo estado', '23514', 'ck_grupo_estado', $sql$INSERT INTO grupo VALUES (990,99,'UH-RED1',1,1,2,'virtual','borrador')$sql$),
            ('grupo FK curso', '23503', 'fk_grupo_curso', $sql$INSERT INTO grupo VALUES (990,1,'CURSO-INVALIDO',1,1,2,'virtual','cerrada')$sql$),
            ('grupo FK periodo', '23503', 'fk_grupo_periodo', $sql$INSERT INTO grupo VALUES (990,1,'UH-RED1',999999,1,2,'virtual','cerrada')$sql$),
            ('grupo FK sede', '23503', 'fk_grupo_sede', $sql$INSERT INTO grupo VALUES (990,1,'UH-RED1',1,999999,2,'virtual','cerrada')$sql$),
            ('grupo NOT NULL capacidad', '23502', 'capacidad', $sql$INSERT INTO grupo VALUES (990,99,'UH-RED1',1,1,NULL,'virtual','cerrada')$sql$),
            ('bloque PK', '23505', 'pk_bloque_horario', $sql$INSERT INTO bloque_horario VALUES (900,20,1,TIME '12:00',TIME '13:00',FALSE,1)$sql$),
            ('bloque dia cero', '23514', 'ck_bloque_dia', $sql$INSERT INTO bloque_horario VALUES (990,20,0,TIME '12:00',TIME '13:00',TRUE,1)$sql$),
            ('bloque dia ocho', '23514', 'ck_bloque_dia', $sql$INSERT INTO bloque_horario VALUES (990,20,8,TIME '12:00',TIME '13:00',TRUE,1)$sql$),
            ('bloque hora igual', '23514', 'ck_bloque_horas', $sql$INSERT INTO bloque_horario VALUES (990,20,1,TIME '12:00',TIME '12:00',TRUE,1)$sql$),
            ('bloque hora invertida', '23514', 'ck_bloque_horas', $sql$INSERT INTO bloque_horario VALUES (990,20,1,TIME '14:00',TIME '13:00',TRUE,1)$sql$),
            ('bloque presencial sin espacio', '23514', 'ck_bloque_espacio_presencial', $sql$INSERT INTO bloque_horario VALUES (990,20,1,TIME '12:00',TIME '13:00',TRUE,NULL)$sql$),
            ('bloque FK espacio', '23503', 'fk_bloque_espacio', $sql$INSERT INTO bloque_horario VALUES (990,20,1,TIME '12:00',TIME '13:00',TRUE,999999)$sql$),
            ('bloque FK grupo', '23503', 'fk_bloque_grupo', $sql$INSERT INTO bloque_horario VALUES (990,999999,1,TIME '12:00',TIME '13:00',TRUE,1)$sql$),
            ('bloque NOT NULL es_presencial', '23502', 'es_presencial', $sql$INSERT INTO bloque_horario VALUES (990,20,1,TIME '12:00',TIME '13:00',NULL,1)$sql$),
            ('traslado PK', '23505', 'pk_traslado_plan', $sql$INSERT INTO traslado_plan VALUES (900,3,101,102,'2026-03-03 10:00:00-06','Motivo de prueba',1)$sql$),
            ('traslado versiones iguales', '23514', 'ck_traslado_versiones_distintas', $sql$INSERT INTO traslado_plan VALUES (990,3,101,101,'2026-03-03 10:00:00-06','Motivo de prueba',1)$sql$),
            ('traslado motivo blanco', '23514', 'ck_traslado_motivo_no_vacio', $sql$INSERT INTO traslado_plan VALUES (990,3,101,102,'2026-03-03 10:00:00-06','   ',1)$sql$),
            ('traslado FK admision', '23503', 'fk_traslado_admision', $sql$INSERT INTO traslado_plan VALUES (990,999999,101,102,'2026-03-03 10:00:00-06','Motivo de prueba',1)$sql$),
            ('traslado FK origen', '23503', 'fk_traslado_origen', $sql$INSERT INTO traslado_plan VALUES (990,3,999999,102,'2026-03-03 10:00:00-06','Motivo de prueba',1)$sql$),
            ('traslado FK destino', '23503', 'fk_traslado_destino', $sql$INSERT INTO traslado_plan VALUES (990,3,101,999999,'2026-03-03 10:00:00-06','Motivo de prueba',1)$sql$),
            ('traslado FK autorizador', '23503', 'fk_traslado_autorizador', $sql$INSERT INTO traslado_plan VALUES (990,3,101,102,'2026-03-03 10:00:00-06','Motivo de prueba',999999)$sql$),
            ('reconocimiento PK', '23505', 'pk_reconocimiento_academico', $sql$INSERT INTO reconocimiento_academico VALUES (900,1,NULL,'UH-MAT1',102,'UH-BDAT1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento ambos origenes', '23514', 'ck_reconocimiento_origen_exclusivo', $sql$INSERT INTO reconocimiento_academico VALUES (990,1,'EXT-001','UH-PROG1',102,'UH-BDAT1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento sin origen', '23514', 'ck_reconocimiento_origen_exclusivo', $sql$INSERT INTO reconocimiento_academico VALUES (990,1,NULL,NULL,102,'UH-BDAT1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento externo blanco', '23514', 'ck_reconocimiento_referencia_no_vacia', $sql$INSERT INTO reconocimiento_academico VALUES (990,1,'   ',NULL,102,'UH-BDAT1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento resolucion blanca', '23514', 'ck_reconocimiento_resolucion_no_vacia', $sql$INSERT INTO reconocimiento_academico VALUES (990,1,'EXT-001',NULL,102,'UH-BDAT1','    ','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento FK admision', '23503', 'fk_reconocimiento_admision', $sql$INSERT INTO reconocimiento_academico VALUES (990,999999,'EXT-001',NULL,102,'UH-BDAT1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento FK origen institucional', '23503', 'fk_reconocimiento_curso_origen', $sql$INSERT INTO reconocimiento_academico VALUES (990,1,NULL,'UH-NOEXISTE',102,'UH-BDAT1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('reconocimiento FK compuesta', '23503', 'fk_reconocimiento_participacion', $sql$INSERT INTO reconocimiento_academico VALUES (990,1,'EXT-001',NULL,102,'UH-SIS1','RES-100','2026-09-04 10:00:00-06')$sql$),
            ('grupo_docente PK', '23505', 'pk_grupo_docente', $sql$INSERT INTO grupo_docente VALUES (12,2,'adicional')$sql$),
            ('grupo_docente responsable unico', '23505', 'uq_grupo_docente_responsable', $sql$INSERT INTO grupo_docente VALUES (10,2,'responsable')$sql$),
            ('grupo_docente rol', '23514', 'ck_grupo_docente_rol', $sql$INSERT INTO grupo_docente VALUES (20,2,'observador')$sql$),
            ('grupo_docente FK grupo', '23503', 'fk_grupo_docente_grupo', $sql$INSERT INTO grupo_docente VALUES (999999,2,'adicional')$sql$),
            ('grupo_docente FK docente', '23503', 'fk_grupo_docente_docente', $sql$INSERT INTO grupo_docente VALUES (20,999999,'adicional')$sql$),
            ('grupo_docente NOT NULL rol', '23502', 'rol', $sql$INSERT INTO grupo_docente VALUES (20,2,NULL)$sql$),
            ('oferta PK', '23505', 'pk_historial_oferta', $sql$INSERT INTO historial_oferta VALUES (900,20,'apertura',NULL,'abierta',NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta tipo', '23514', 'ck_historial_oferta_tipo', $sql$INSERT INTO historial_oferta VALUES (990,20,'modificacion',NULL,'abierta',NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta estado ilegal', '23514', 'ck_historial_oferta_estados', $sql$INSERT INTO historial_oferta VALUES (990,20,'apertura','reservada','abierta',NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta cupo negativo', '23514', 'ck_historial_oferta_cupos', $sql$INSERT INTO historial_oferta VALUES (990,20,'cambio_cupo',NULL,NULL,-1,0,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta sin cambio cupo', '23514', 'ck_historial_oferta_forma', $sql$INSERT INTO historial_oferta VALUES (990,20,'cambio_cupo',NULL,NULL,2,2,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta cambio cupo incompleto', '23514', 'ck_historial_oferta_forma', $sql$INSERT INTO historial_oferta VALUES (990,20,'cambio_cupo',NULL,NULL,NULL,3,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta apertura sin nuevo estado', '23514', 'ck_historial_oferta_forma', $sql$INSERT INTO historial_oferta VALUES (990,20,'apertura',NULL,NULL,NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta cierre sin estado anterior', '23514', 'ck_historial_oferta_forma', $sql$INSERT INTO historial_oferta VALUES (990,20,'cierre',NULL,'cerrada',NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta cancelacion sin estado nuevo', '23514', 'ck_historial_oferta_forma', $sql$INSERT INTO historial_oferta VALUES (990,20,'cancelacion','abierta',NULL,NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta motivo blanco', '23514', 'ck_historial_oferta_motivo_no_vacio', $sql$INSERT INTO historial_oferta VALUES (990,20,'apertura',NULL,'abierta',NULL,NULL,'2026-07-02 08:00:00-06','  ',1)$sql$),
            ('oferta FK grupo', '23503', 'fk_historial_oferta_grupo', $sql$INSERT INTO historial_oferta VALUES (990,999999,'apertura',NULL,'abierta',NULL,NULL,'2026-07-02 08:00:00-06','Motivo',1)$sql$),
            ('oferta FK responsable', '23503', 'fk_historial_oferta_responsable', $sql$INSERT INTO historial_oferta VALUES (990,20,'apertura',NULL,'abierta',NULL,NULL,'2026-07-02 08:00:00-06','Motivo',999999)$sql$),
            ('solicitud PK', '23505', 'pk_solicitud_matricula', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (901,1,10,NULL,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud estado', '23514', 'ck_solicitud_estado', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','pendiente',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud razon rechazo ausente', '23514', 'ck_solicitud_razon', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','rechazada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud razon espera blanca', '23514', 'ck_solicitud_razon', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','en_espera','  ',1,NULL,NULL)$sql$),
            ('solicitud orden cero', '23514', 'ck_solicitud_orden_espera', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','matriculada',NULL,0,NULL,NULL)$sql$),
            ('solicitud espera sin orden', '23514', 'ck_solicitud_orden_espera', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','en_espera','Sin cupo',NULL,NULL,NULL)$sql$),
            ('solicitud autorreferencia', '23514', 'ck_solicitud_no_autorreferencia', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,990,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud calificacion vacia', '23514', 'ck_solicitud_calificacion_no_vacia', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,'  ',NULL)$sql$),
            ('solicitud resultado invalido', '23514', 'ck_solicitud_resultado', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,'desconocido')$sql$),
            ('solicitud FK admision', '23503', 'fk_solicitud_admision', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,999999,10,NULL,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud FK grupo', '23503', 'fk_solicitud_grupo', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,999999,NULL,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud FK anterior', '23503', 'fk_solicitud_anterior', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,999999,102,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud FK version', '23503', 'fk_solicitud_version', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,999999,'2026-07-04 08:00:00-06','matriculada',NULL,NULL,NULL,NULL)$sql$),
            ('solicitud NOT NULL estado', '23502', 'estado', $sql$INSERT INTO solicitud_matricula (id_solicitud,id_admision,id_grupo,id_solicitud_anterior,id_version_plan_evaluada,fecha_solicitud,estado,razon_rechazo_espera,orden_espera,calificacion,resultado_academico) VALUES (990,1,10,NULL,102,'2026-07-04 08:00:00-06',NULL,NULL,NULL,NULL,NULL)$sql$),
            ('hist solicitud PK', '23505', 'pk_historial_solicitud', $sql$INSERT INTO historial_solicitud VALUES (900,901,'transicion',NULL,'matriculada','2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud tipo', '23514', 'ck_historial_solicitud_tipo', $sql$INSERT INTO historial_solicitud VALUES (990,901,'revision',NULL,'matriculada','2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud estado invalido', '23514', 'ck_historial_solicitud_estados', $sql$INSERT INTO historial_solicitud VALUES (990,901,'transicion',NULL,'pendiente','2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud transicion sin destino', '23514', 'ck_historial_solicitud_forma', $sql$INSERT INTO historial_solicitud VALUES (990,901,'transicion',NULL,NULL,'2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud transicion sin cambio', '23514', 'ck_historial_solicitud_forma', $sql$INSERT INTO historial_solicitud VALUES (990,901,'transicion','matriculada','matriculada','2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud evaluacion sin motivo', '23514', 'ck_historial_solicitud_forma', $sql$INSERT INTO historial_solicitud VALUES (990,901,'evaluacion_espera','en_espera','en_espera','2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud evaluacion que cambia', '23514', 'ck_historial_solicitud_forma', $sql$INSERT INTO historial_solicitud VALUES (990,901,'evaluacion_espera','en_espera','matriculada','2026-07-04 08:00:00-06','Cambio invalido',NULL)$sql$),
            ('hist solicitud evaluacion con solo destino', '23514', 'ck_historial_solicitud_forma', $sql$INSERT INTO historial_solicitud VALUES (990,900,'evaluacion_espera',NULL,'matriculada','2026-07-08 12:00:00-06','No debe expresar transicion parcial',NULL)$sql$),
            ('hist solicitud evaluacion con solo origen', '23514', 'ck_historial_solicitud_forma', $sql$INSERT INTO historial_solicitud VALUES (990,900,'evaluacion_espera','en_espera',NULL,'2026-07-08 12:00:00-06','No debe expresar transicion parcial',NULL)$sql$),
            ('hist solicitud motivo blanco', '23514', 'ck_historial_solicitud_motivo_no_vacio', $sql$INSERT INTO historial_solicitud VALUES (990,901,'transicion',NULL,'matriculada','2026-07-04 08:00:00-06','  ',NULL)$sql$),
            ('hist solicitud FK solicitud', '23503', 'fk_historial_solicitud_solicitud', $sql$INSERT INTO historial_solicitud VALUES (990,999999,'transicion',NULL,'matriculada','2026-07-04 08:00:00-06',NULL,NULL)$sql$),
            ('hist solicitud FK actor', '23503', 'fk_historial_solicitud_actor', $sql$INSERT INTO historial_solicitud VALUES (990,901,'transicion',NULL,'matriculada','2026-07-04 08:00:00-06',NULL,999999)$sql$),
            ('excepcion PK', '23505', 'pk_excepcion_requisito', $sql$INSERT INTO excepcion_requisito VALUES (900,901,1,1,'2026-07-04 08:00:00-06','Motivo')$sql$),
            ('excepcion FK solicitud', '23503', 'fk_excepcion_solicitud', $sql$INSERT INTO excepcion_requisito VALUES (990,999999,1,1,'2026-07-04 08:00:00-06','Motivo')$sql$),
            ('excepcion FK requisito', '23503', 'fk_excepcion_requisito', $sql$INSERT INTO excepcion_requisito VALUES (990,901,999999,1,'2026-07-04 08:00:00-06','Motivo')$sql$),
            ('excepcion FK autorizador', '23503', 'fk_excepcion_autorizador', $sql$INSERT INTO excepcion_requisito VALUES (990,901,1,999999,'2026-07-04 08:00:00-06','Motivo')$sql$),
            ('excepcion motivo blanco', '23514', 'ck_excepcion_motivo_no_vacio', $sql$INSERT INTO excepcion_requisito VALUES (990,901,1,1,'2026-07-04 08:00:00-06','  ')$sql$),
            ('correccion PK', '23505', 'pk_historial_correccion_calificacion', $sql$INSERT INTO historial_correccion_calificacion VALUES (900,901,NULL,'85',NULL,NULL,'2026-12-16 08:00:00-06','Motivo',1)$sql$),
            ('correccion sin cambio', '23514', 'ck_correccion_cambio_real', $sql$INSERT INTO historial_correccion_calificacion VALUES (990,901,'85','85',NULL,NULL,'2026-12-16 08:00:00-06','Motivo',1)$sql$),
            ('correccion calificacion blanca', '23514', 'ck_correccion_calificaciones_no_vacias', $sql$INSERT INTO historial_correccion_calificacion VALUES (990,901,'85','  ',NULL,NULL,'2026-12-16 08:00:00-06','Motivo',1)$sql$),
            ('correccion resultado invalido', '23514', 'ck_correccion_resultados', $sql$INSERT INTO historial_correccion_calificacion VALUES (990,901,'85','86','desconocido',NULL,'2026-12-16 08:00:00-06','Motivo',1)$sql$),
            ('correccion motivo blanco', '23514', 'ck_correccion_motivo_no_vacio', $sql$INSERT INTO historial_correccion_calificacion VALUES (990,901,'85','86',NULL,NULL,'2026-12-16 08:00:00-06','  ',1)$sql$),
            ('correccion FK solicitud', '23503', 'fk_correccion_solicitud', $sql$INSERT INTO historial_correccion_calificacion VALUES (990,999999,'85','86',NULL,NULL,'2026-12-16 08:00:00-06','Motivo',1)$sql$),
            ('correccion FK autorizador', '23503', 'fk_correccion_autorizador', $sql$INSERT INTO historial_correccion_calificacion VALUES (990,901,'85','86',NULL,NULL,'2026-12-16 08:00:00-06','Motivo',999999)$sql$),
            ('UPDATE grupo capacidad', '23514', 'ck_grupo_capacidad', $sql$UPDATE grupo SET capacidad=-1 WHERE id_grupo=20$sql$),
            ('UPDATE bloque sin espacio', '23514', 'ck_bloque_espacio_presencial', $sql$UPDATE bloque_horario SET id_espacio=NULL WHERE id_bloque=902$sql$),
            ('UPDATE grupo docente segundo responsable', '23505', 'uq_grupo_docente_responsable', $sql$UPDATE grupo_docente SET rol='responsable' WHERE id_grupo=12 AND id_docente=2$sql$),
            ('UPDATE reconocimiento doble origen', '23514', 'ck_reconocimiento_origen_exclusivo', $sql$UPDATE reconocimiento_academico SET referencia_curso_reconocido='EXT-999' WHERE id_reconocimiento=900$sql$),
            ('UPDATE solicitud razon vacia', '23514', 'ck_solicitud_razon', $sql$UPDATE solicitud_matricula SET razon_rechazo_espera=NULL WHERE id_solicitud=902$sql$),
            ('UPDATE traslado mismo origen destino', '23514', 'ck_traslado_versiones_distintas', $sql$UPDATE traslado_plan SET id_version_destino=id_version_origen WHERE id_traslado=900$sql$),
            ('UPDATE historial cambio inexistente', '23514', 'ck_historial_oferta_forma', $sql$UPDATE historial_oferta SET cupo_nuevo=cupo_anterior WHERE id_cambio=901$sql$),
            ('UPDATE correccion sin cambio', '23514', 'ck_correccion_cambio_real', $sql$UPDATE historial_correccion_calificacion SET calificacion_nueva=calificacion_anterior, resultado_nuevo=resultado_anterior WHERE id_correccion=900$sql$),
            ('DELETE docente referenciado', '23503', 'fk_grupo_docente_docente', $sql$DELETE FROM docente WHERE id_docente=2$sql$),
            ('UPDATE PK docente referenciado', '23503', 'fk_grupo_docente_docente', $sql$UPDATE docente SET id_docente=30 WHERE id_docente=2$sql$),
            ('DELETE admision con traslado', '23503', 'fk_traslado_admision', $sql$DELETE FROM admision WHERE id_admision=5$sql$),
            ('DELETE requisito con excepcion', '23503', 'fk_excepcion_requisito', $sql$DELETE FROM requisito_curso WHERE id_requisito=(SELECT id_requisito FROM excepcion_requisito WHERE id_excepcion=900)$sql$),
            ('DELETE participacion con reconocimiento', '23503', 'fk_reconocimiento_participacion', $sql$DELETE FROM participacion_plan WHERE codigo_curso='UH-BDAT1' AND id_version_plan=102$sql$)
        ) AS casos(prueba, estado_esperado, origen_esperado, sentencia)
    LOOP
        BEGIN
            EXECUTE r.sentencia;
            RAISE EXCEPTION 'fallo: operacion invalida aceptada (%).', r.prueba;
        EXCEPTION WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                v_sqlstate = RETURNED_SQLSTATE,
                v_restriccion = CONSTRAINT_NAME,
                v_columna = COLUMN_NAME,
                v_detalle = MESSAGE_TEXT;
            IF v_sqlstate IS DISTINCT FROM r.estado_esperado THEN
                RAISE EXCEPTION
                    '%: SQLSTATE % (esperado %). Mensaje: %',
                    r.prueba, v_sqlstate, r.estado_esperado, v_detalle;
            END IF;
            IF r.estado_esperado = '23502' THEN
                IF v_columna IS DISTINCT FROM r.origen_esperado THEN
                    RAISE EXCEPTION '%: columna % (esperada %)',
                        r.prueba, v_columna, r.origen_esperado;
                END IF;
            ELSIF v_restriccion IS DISTINCT FROM r.origen_esperado THEN
                RAISE EXCEPTION '%: restriccion % (esperada %)',
                    r.prueba, v_restriccion, r.origen_esperado;
            END IF;
            v_exitos := v_exitos + 1;
        END;
    END LOOP;

    v_despues := ARRAY[
        (SELECT COUNT(*) FROM grupo),
        (SELECT COUNT(*) FROM bloque_horario),
        (SELECT COUNT(*) FROM solicitud_matricula),
        (SELECT COUNT(*) FROM traslado_plan),
        (SELECT COUNT(*) FROM reconocimiento_academico),
        (SELECT COUNT(*) FROM grupo_docente),
        (SELECT COUNT(*) FROM historial_oferta),
        (SELECT COUNT(*) FROM historial_solicitud),
        (SELECT COUNT(*) FROM excepcion_requisito),
        (SELECT COUNT(*) FROM historial_correccion_calificacion)
    ];
    IF v_antes IS DISTINCT FROM v_despues THEN
        RAISE EXCEPTION 'los rechazos dejaron cambios de cantidad de registros';
    END IF;

    -- Lectura posterior: UPDATE fallidos tampoco deben alterar los valores
    -- vigentes, aunque la cantidad de registros permanezca sin cambios.
    IF NOT EXISTS (
        SELECT 1 FROM grupo
        WHERE id_grupo = 20 AND capacidad = 1 AND estado_oferta = 'cancelada'
    ) OR NOT EXISTS (
        SELECT 1 FROM bloque_horario
        WHERE id_bloque = 902 AND es_presencial AND id_espacio = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM reconocimiento_academico
        WHERE id_reconocimiento = 900
          AND referencia_curso_reconocido IS NULL
          AND codigo_curso_reconocido = 'UH-BDAT1'
    ) OR NOT EXISTS (
        SELECT 1 FROM solicitud_matricula
        WHERE id_solicitud = 902 AND estado = 'rechazada'
          AND razon_rechazo_espera = 'Oferta cerrada y cupo cero'
    ) OR NOT EXISTS (
        SELECT 1 FROM historial_oferta
        WHERE id_cambio = 901 AND cupo_anterior = 0 AND cupo_nuevo = 1
    ) OR NOT EXISTS (
        SELECT 1 FROM historial_correccion_calificacion
        WHERE id_correccion = 900 AND calificacion_anterior = '80'
          AND calificacion_nueva = '85'
          AND resultado_anterior = 'incompleto'
          AND resultado_nuevo = 'aprobado'
    ) THEN
        RAISE EXCEPTION 'se modificaron datos tras un rechazo esperado';
    END IF;

    RAISE NOTICE '% casos negativos y UPDATE/DELETE referenciales conformes', v_exitos;
END;
$validacion$;

-- 4. El ROLLBACK restaura exactamente la semilla; no deja objetos
--    ni registros de pruebas, ni transacciones abiertas.
ROLLBACK;
