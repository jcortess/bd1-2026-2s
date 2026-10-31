-- =====================================================================
-- IC-4301 Bases de Datos I · Laboratorio 3 · Grupo 7 · Eventos Nexo
-- Archivo : 05_pruebas.sql
-- Propósito: pruebas de integridad y de rutinas (B3 y C2)
-- Requiere: 01_esquema → 02_datos → 04_rutinas → 03_consultas
--
-- Cómo funciona
--   * Todo el archivo corre dentro de una transacción que termina en
--     ROLLBACK: las pruebas no dejan cambios y se pueden repetir.
--   * Cada prueba es un bloque DO. Las que deben fallar capturan el error
--     esperado con EXCEPTION, así el script nunca se detiene. Si una
--     sentencia inválida fuera aceptada, el bloque la deshace y registra
--     la prueba como FALLA.
--   * Cada bloque guarda precondición, resultado esperado, resultado
--     observado (SQLSTATE, restricción y mensaje del motor) y conclusión
--     en la tabla temporal resultado_prueba, que se muestra al final.
--
--   Válidas   : T01 T02 T03 T04
--   Inválidas : T05 T06 T07 T08 T09 T10 T11
-- =====================================================================

BEGIN;

CREATE TEMPORARY TABLE resultado_prueba (
    id_prueba     VARCHAR(4)  PRIMARY KEY,
    tipo          VARCHAR(8)  NOT NULL,      -- Válida / Inválida
    descripcion   TEXT        NOT NULL,
    precondicion  TEXT        NOT NULL,
    esperado      TEXT        NOT NULL,
    observado     TEXT        NOT NULL,
    conclusion    VARCHAR(5)  NOT NULL       -- PASA / FALLA
);


-- =====================================================================
-- PRUEBAS QUE DEBEN FUNCIONAR
-- =====================================================================

-- ---------------------------------------------------------------------
-- T01 · Cliente organización válido (RN-05, ck_cliente_arco_exclusivo)
-- Sentencia: INSERT de un cliente Organización sin id_persona
-- ---------------------------------------------------------------------
DO $$
DECLARE v_id INTEGER;
BEGIN
    INSERT INTO cliente (tipo_cliente, identificacion_juridica, razon_social)
    VALUES ('Organización', '3-101-999999', 'Asociación Cultural Norte')
    RETURNING id_cliente INTO v_id;

    INSERT INTO resultado_prueba VALUES ('T01', 'Válida',
        'Registrar un cliente organización con cédula jurídica y razón social',
        'La cédula jurídica 3-101-999999 no existe',
        'Se inserta; id_persona queda nulo',
        format('Insertado id_cliente=%s, id_persona=%s', v_id,
               COALESCE((SELECT id_persona::TEXT FROM cliente WHERE id_cliente = v_id), 'NULL')),
        'PASA');
EXCEPTION WHEN OTHERS THEN
    INSERT INTO resultado_prueba VALUES ('T01', 'Válida',
        'Registrar un cliente organización', '—', 'Se inserta',
        format('Error inesperado %s: %s', SQLSTATE, SQLERRM), 'FALLA');
END $$;

-- ---------------------------------------------------------------------
-- T02 · Pago en efectivo sin referencia y reparto con cursor
--       (ck_pago_referencia, sp_aplicar_pago)
-- Sentencias: INSERT INTO pago (... 'Efectivo', NULL ...);
--             CALL sp_aplicar_pago(id)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_id_pago   INTEGER;
    v_aplicado  NUMERIC(12,2);
    v_saldo     NUMERIC(12,2);
BEGIN
    INSERT INTO pago (id_evento, fecha_pago, monto, medio_pago, referencia, es_adelanto)
    VALUES (3, '2026-10-28', 50000.00, 'Efectivo', NULL, TRUE)
    RETURNING id_pago INTO v_id_pago;

    CALL sp_aplicar_pago(v_id_pago);

    SELECT SUM(monto_aplicado) INTO v_aplicado FROM aplicacion_pago WHERE id_pago = v_id_pago;
    v_saldo := fn_saldo_evento(3);

    INSERT INTO resultado_prueba VALUES ('T02', 'Válida',
        'Registrar un adelanto en efectivo sin referencia y aplicarlo con el cursor',
        'Evento 3 con saldo 660 000 y sin pagos',
        'Se inserta; se aplican 50 000 al cargo 8; saldo 610 000',
        format('Pago %s, aplicado %s, saldo %s', v_id_pago, v_aplicado, v_saldo),
        CASE WHEN v_aplicado = 50000 AND v_saldo = 610000 THEN 'PASA' ELSE 'FALLA' END);
EXCEPTION WHEN OTHERS THEN
    INSERT INTO resultado_prueba VALUES ('T02', 'Válida',
        'Adelanto en efectivo sin referencia', '—', 'Se inserta',
        format('Error inesperado %s: %s', SQLSTATE, SQLERRM), 'FALLA');
END $$;

-- ---------------------------------------------------------------------
-- T03 · Procedimiento: pago que cubre dos cargos (caso exitoso de C2)
-- Sentencia: CALL sp_registrar_pago(2, 400000, 'SINPE Móvil', 'SP-20001')
-- El reparto debe coincidir con la simulación por conjuntos de Q4.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_id_pago  INTEGER;
    v_c6       NUMERIC(12,2);
    v_c7       NUMERIC(12,2);
    v_saldo    NUMERIC(12,2);
BEGIN
    CALL sp_registrar_pago(2, 400000.00, 'SINPE Móvil', 'SP-20001', FALSE, '2026-10-28', v_id_pago);

    SELECT monto_aplicado INTO v_c6 FROM aplicacion_pago WHERE id_pago = v_id_pago AND id_cargo = 6;
    SELECT monto_aplicado INTO v_c7 FROM aplicacion_pago WHERE id_pago = v_id_pago AND id_cargo = 7;
    v_saldo := fn_saldo_evento(2);

    INSERT INTO resultado_prueba VALUES ('T03', 'Válida',
        'Registrar un pago de 400 000 que se reparte entre dos cargos',
        'Evento 2 con saldo 610 000: cargo 6 debe 260 000 y cargo 7 debe 350 000',
        'Cargo 6 recibe 260 000, cargo 7 recibe 140 000; saldo 210 000 (igual que Q4)',
        format('Pago %s: cargo 6=%s, cargo 7=%s, saldo %s, estado %s',
               v_id_pago, v_c6, v_c7, v_saldo, fn_estado_pago_evento(2)),
        CASE WHEN v_c6 = 260000 AND v_c7 = 140000 AND v_saldo = 210000
             THEN 'PASA' ELSE 'FALLA' END);
EXCEPTION WHEN OTHERS THEN
    INSERT INTO resultado_prueba VALUES ('T03', 'Válida',
        'Pago que cubre dos cargos', '—', 'Se registra',
        format('Error inesperado %s: %s', SQLSTATE, SQLERRM), 'FALLA');
END $$;

-- ---------------------------------------------------------------------
-- T04 · Procedimiento: pago de una penalización de un evento cancelado
-- Sentencia: CALL sp_registrar_pago(4, 200000, 'Transferencia', 'TR-60001')
-- Un evento cancelado sí admite pagos (no adelantos): debe quedar Pagado.
-- ---------------------------------------------------------------------
DO $$
DECLARE v_id_pago INTEGER;
BEGIN
    CALL sp_registrar_pago(4, 200000.00, 'Transferencia', 'TR-60001', FALSE, '2026-10-28', v_id_pago);

    INSERT INTO resultado_prueba VALUES ('T04', 'Válida',
        'Pagar la penalización de un evento cancelado',
        'Evento 4 Cancelado con una penalización aprobada de 200 000 sin pagar',
        'Se registra; saldo 0; estado Pagado',
        format('Pago %s, saldo %s, estado %s', v_id_pago, fn_saldo_evento(4), fn_estado_pago_evento(4)),
        CASE WHEN fn_saldo_evento(4) = 0 AND fn_estado_pago_evento(4) = 'Pagado'
             THEN 'PASA' ELSE 'FALLA' END);
EXCEPTION WHEN OTHERS THEN
    INSERT INTO resultado_prueba VALUES ('T04', 'Válida',
        'Pagar penalización de evento cancelado', '—', 'Se registra',
        format('Error inesperado %s: %s', SQLSTATE, SQLERRM), 'FALLA');
END $$;


-- =====================================================================
-- PRUEBAS QUE DEBEN SER RECHAZADAS
-- Patrón: si la sentencia se acepta, se lanza el código P0099 para
-- deshacerla y registrar FALLA; si el motor la rechaza con el error
-- esperado, se registra PASA con lo que informó PostgreSQL.
-- =====================================================================

-- ---------------------------------------------------------------------
-- T05 · UNICIDAD: comprobante repetido (uq_pago_medio_referencia, RN-19)
-- Sentencia: INSERT de un pago SINPE Móvil con la referencia SP-10001
-- ---------------------------------------------------------------------
DO $$
DECLARE v_restr TEXT; v_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO pago (id_evento, fecha_pago, monto, medio_pago, referencia)
        VALUES (2, '2026-10-28', 10000.00, 'SINPE Móvil', 'SP-10001');
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS v_restr = CONSTRAINT_NAME, v_msg = MESSAGE_TEXT;
            INSERT INTO resultado_prueba VALUES ('T05', 'Inválida',
                'Registrar dos veces el mismo comprobante de pago',
                'Ya existe el pago 1 con SINPE Móvil SP-10001',
                'Rechazo 23505 por uq_pago_medio_referencia',
                format('%s · %s · %s', SQLSTATE, v_restr, v_msg), 'PASA');
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T05', 'Inválida', 'Comprobante repetido', '—',
                'Rechazo 23505', 'La sentencia fue aceptada', 'FALLA');
    END;
END $$;

-- ---------------------------------------------------------------------
-- T06 · REFERENCIA: cargo de un evento inexistente (fk_cargo_evento)
-- Sentencia: INSERT de un cargo con id_evento = 999
-- ---------------------------------------------------------------------
DO $$
DECLARE v_restr TEXT; v_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO cargo (id_evento, tipo_cargo, descripcion, monto, fecha_cargo,
                           justificacion, id_cliente_responsable)
        VALUES (999, 'Penalización', 'Cargo huérfano', 1000.00, '2026-10-28',
                'Prueba', 1);
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN foreign_key_violation THEN
            GET STACKED DIAGNOSTICS v_restr = CONSTRAINT_NAME, v_msg = MESSAGE_TEXT;
            INSERT INTO resultado_prueba VALUES ('T06', 'Inválida',
                'Registrar un cargo para un evento que no existe',
                'No existe el evento 999',
                'Rechazo 23503 por fk_cargo_evento',
                format('%s · %s · %s', SQLSTATE, v_restr, v_msg), 'PASA');
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T06', 'Inválida', 'Cargo huérfano', '—',
                'Rechazo 23503', 'La sentencia fue aceptada', 'FALLA');
    END;
END $$;

-- ---------------------------------------------------------------------
-- T07 · REFERENCIA COMPUESTA: aplicar un pago a un cargo de otro evento
--       (fk_aplicacion_pago_cargo, RN-19 «solo cargos del mismo evento»)
-- Sentencia: aplicar el pago 1 (evento 1) al cargo 6 (evento 2)
-- ---------------------------------------------------------------------
DO $$
DECLARE v_restr TEXT; v_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO aplicacion_pago (id_pago, id_cargo, id_evento, monto_aplicado)
        VALUES (1, 6, 1, 1000.00);
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN foreign_key_violation THEN
            GET STACKED DIAGNOSTICS v_restr = CONSTRAINT_NAME, v_msg = MESSAGE_TEXT;
            INSERT INTO resultado_prueba VALUES ('T07', 'Inválida',
                'Aplicar el pago de un evento al cargo de otro evento',
                'Pago 1 es del evento 1; cargo 6 es del evento 2',
                'Rechazo 23503 por fk_aplicacion_pago_cargo (par cargo-evento inexistente)',
                format('%s · %s · %s', SQLSTATE, v_restr, v_msg), 'PASA');
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T07', 'Inválida', 'Pago a cargo de otro evento', '—',
                'Rechazo 23503', 'La sentencia fue aceptada', 'FALLA');
    END;
END $$;

-- ---------------------------------------------------------------------
-- T08 · ESTADO / ARCO EXCLUSIVO: cliente Persona con datos de organización
--       (ck_cliente_arco_exclusivo, RN-05)
-- Sentencia: INSERT de un cliente Persona con razón social
-- ---------------------------------------------------------------------
DO $$
DECLARE v_restr TEXT; v_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO cliente (tipo_cliente, id_persona, razon_social)
        VALUES ('Persona', 7, 'Solano Eventos S.A.');
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS v_restr = CONSTRAINT_NAME, v_msg = MESSAGE_TEXT;
            INSERT INTO resultado_prueba VALUES ('T08', 'Inválida',
                'Registrar un cliente que es persona y organización a la vez',
                'La persona 7 existe y no es cliente',
                'Rechazo 23514 por ck_cliente_arco_exclusivo',
                format('%s · %s · %s', SQLSTATE, v_restr, v_msg), 'PASA');
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T08', 'Inválida', 'Cliente persona y organización', '—',
                'Rechazo 23514', 'La sentencia fue aceptada', 'FALLA');
    END;
END $$;

-- ---------------------------------------------------------------------
-- T09 · OBLIGATORIEDAD: pago sin medio de pago (NOT NULL, RN-19)
-- Sentencia: INSERT de un pago sin medio_pago
-- ---------------------------------------------------------------------
DO $$
DECLARE v_col TEXT; v_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO pago (id_evento, fecha_pago, monto)
        VALUES (2, '2026-10-28', 10000.00);
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN not_null_violation THEN
            GET STACKED DIAGNOSTICS v_col = COLUMN_NAME, v_msg = MESSAGE_TEXT;
            INSERT INTO resultado_prueba VALUES ('T09', 'Inválida',
                'Registrar un pago sin indicar el medio de pago',
                'El evento 2 existe',
                'Rechazo 23502 en la columna medio_pago',
                format('%s · columna %s · %s', SQLSTATE, v_col, v_msg), 'PASA');
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T09', 'Inválida', 'Pago sin medio', '—',
                'Rechazo 23502', 'La sentencia fue aceptada', 'FALLA');
    END;
END $$;

-- ---------------------------------------------------------------------
-- T10 · PROCEDIMIENTO (caso rechazado de C2): pago mayor que el saldo
--       (validación V3 de sp_registrar_pago, RN-19)
-- Sentencia: CALL sp_registrar_pago(3, 1000000, 'Transferencia', 'TR-70001')
-- Además se verifica que no quedó ningún pago a medias.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_msg         TEXT;
    v_pagos_antes INTEGER;
    v_pagos_desp  INTEGER;
    v_id_pago     INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pagos_antes FROM pago WHERE id_evento = 3;
    BEGIN
        CALL sp_registrar_pago(3, 1000000.00, 'Transferencia', 'TR-70001', FALSE, '2026-10-28', v_id_pago);
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN raise_exception THEN
            GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
            SELECT COUNT(*) INTO v_pagos_desp FROM pago WHERE id_evento = 3;
            INSERT INTO resultado_prueba VALUES ('T10', 'Inválida',
                'Registrar un pago que excede el saldo del evento',
                'Evento 3 con saldo 610 000 (después de T02)',
                'Rechazo P0001 con mensaje claro; no se inserta ningún pago',
                format('%s · %s · pagos antes=%s, después=%s',
                       SQLSTATE, v_msg, v_pagos_antes, v_pagos_desp),
                CASE WHEN v_pagos_antes = v_pagos_desp THEN 'PASA' ELSE 'FALLA' END);
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T10', 'Inválida', 'Pago mayor que el saldo', '—',
                'Rechazo P0001', 'La operación fue aceptada', 'FALLA');
    END;
END $$;

-- ---------------------------------------------------------------------
-- T11 · REGLA DE ORIGEN: penalización sin justificación
--       (ck_cargo_origen, RN-18 «toda penalización tiene justificación»)
-- Sentencia: INSERT de un cargo Penalización con justificacion nula
-- ---------------------------------------------------------------------
DO $$
DECLARE v_restr TEXT; v_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO cargo (id_evento, tipo_cargo, descripcion, monto, fecha_cargo,
                           justificacion, id_cliente_responsable)
        VALUES (2, 'Penalización', 'Limpieza adicional', 25000.00, '2026-10-28',
                NULL, 3);
        RAISE EXCEPTION 'aceptada' USING ERRCODE = 'P0099';
    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS v_restr = CONSTRAINT_NAME, v_msg = MESSAGE_TEXT;
            INSERT INTO resultado_prueba VALUES ('T11', 'Inválida',
                'Registrar una penalización sin justificación',
                'El evento 2 y el cliente 3 existen',
                'Rechazo 23514 por ck_cargo_origen',
                format('%s · %s · %s', SQLSTATE, v_restr, v_msg), 'PASA');
        WHEN SQLSTATE 'P0099' THEN
            INSERT INTO resultado_prueba VALUES ('T11', 'Inválida', 'Penalización sin justificación', '—',
                'Rechazo 23514', 'La sentencia fue aceptada', 'FALLA');
    END;
END $$;


-- =====================================================================
-- RESULTADOS
-- =====================================================================
SELECT id_prueba, tipo, descripcion, precondicion, esperado, observado, conclusion
  FROM resultado_prueba
 ORDER BY id_prueba;

SELECT tipo,
       COUNT(*)                                     AS pruebas,
       COUNT(*) FILTER (WHERE conclusion = 'PASA')  AS pasan,
       COUNT(*) FILTER (WHERE conclusion = 'FALLA') AS fallan
  FROM resultado_prueba
 GROUP BY tipo
 ORDER BY tipo DESC;

-- Se deshacen todos los cambios de las pruebas (la base queda como
-- después de 02_datos.sql) y desaparece la tabla temporal.
ROLLBACK;
