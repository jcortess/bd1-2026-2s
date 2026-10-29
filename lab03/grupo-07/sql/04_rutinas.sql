-- Archivo : 04_rutinas.sql
-- Propósito: programación almacenada del proceso de cobro
--
--   C1  fn_saldo_evento(id_evento)          función con parámetros y cálculo
--   C1  fn_estado_pago_evento(id_evento)    función con decisión de negocio
--   C2  sp_registrar_pago(...)              procedimiento con validación
--   C3  sp_aplicar_pago(id_pago)            cursor explícito
--
-- Las restricciones declarativas del esquema siguen activas: las rutinas
-- validan solo lo que un CHECK, UNIQUE o FK no puede expresar (reglas que
-- comparan varias filas, como «lo aplicado no excede el saldo»).
-- CREATE OR REPLACE permite volver a ejecutar este archivo sin errores.

-- C1.a  fn_saldo_evento
-- Regla   : RN-19 «el saldo se calcula». Solo cuentan los cargos Aprobado
--           (RN-18); a cada uno se le resta lo que ya se le aplicó.
-- Entrada : p_id_evento  identificador del evento
-- Retorno : NUMERIC(12,2) saldo pendiente (0 si está al día)
-- Error   : si el evento no existe (para no confundirlo con «saldo 0»)
-- Ejemplo : SELECT fn_saldo_evento(2);   -- 610000.00
CREATE OR REPLACE FUNCTION fn_saldo_evento(p_id_evento INTEGER)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_total_aprobado  NUMERIC(12,2);
    v_total_aplicado  NUMERIC(12,2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN
        RAISE EXCEPTION 'El evento % no existe.', p_id_evento
            USING ERRCODE = 'no_data_found';
    END IF;

    SELECT COALESCE(SUM(c.monto), 0)
      INTO v_total_aprobado
      FROM cargo c
     WHERE c.id_evento = p_id_evento
       AND c.estado_cargo = 'Aprobado';

    SELECT COALESCE(SUM(ap.monto_aplicado), 0)
      INTO v_total_aplicado
      FROM aplicacion_pago ap
      JOIN cargo c ON c.id_cargo = ap.id_cargo
     WHERE c.id_evento = p_id_evento
       AND c.estado_cargo = 'Aprobado';

    RETURN v_total_aprobado - v_total_aplicado;
END;
$$;
-- ---------------------------------------------------------------------
-- C1.b  fn_estado_pago_evento
-- Regla   : clasifica la situación de cobro de un evento para que la
--           coordinación sepa a quién cobrar. Decisión de negocio:
--             1. Sin cargos aprobados  → 'Sin cargos aprobados'
--             2. Saldo en cero         → 'Pagado'
--             3. Evento no cancelado y adelantos pagados < adelanto
--                requerido (RN-19)     → 'Adelanto pendiente'
--             4. No se ha pagado nada  → 'Pendiente'
--             5. En otro caso          → 'Parcial'
--           Un evento cancelado ya no exige adelanto: solo se cobra lo que
--           quede aprobado (por ejemplo, una penalización).
-- Entrada : p_id_evento
-- Retorno : VARCHAR con uno de los cinco estados
-- Ejemplo : SELECT fn_estado_pago_evento(3);   -- 'Adelanto pendiente'
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_estado_pago_evento(p_id_evento INTEGER)
RETURNS VARCHAR(25)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_estado_evento    VARCHAR(15);
    v_adelanto_req     NUMERIC(12,2);
    v_adelanto_pagado  NUMERIC(12,2);
    v_total_aprobado   NUMERIC(12,2);
    v_saldo            NUMERIC(12,2);
BEGIN
    SELECT estado_evento, monto_adelanto_requerido
      INTO v_estado_evento, v_adelanto_req
      FROM evento
     WHERE id_evento = p_id_evento;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El evento % no existe.', p_id_evento
            USING ERRCODE = 'no_data_found';
    END IF;

    SELECT COALESCE(SUM(monto), 0) INTO v_adelanto_pagado
      FROM pago
     WHERE id_evento = p_id_evento AND es_adelanto;

    SELECT COALESCE(SUM(monto), 0) INTO v_total_aprobado
      FROM cargo
     WHERE id_evento = p_id_evento AND estado_cargo = 'Aprobado';

    v_saldo := fn_saldo_evento(p_id_evento);

    IF v_total_aprobado = 0 THEN
        RETURN 'Sin cargos aprobados';
    ELSIF v_saldo = 0 THEN
        RETURN 'Pagado';
    ELSIF v_estado_evento <> 'Cancelado' AND v_adelanto_pagado < v_adelanto_req THEN
        RETURN 'Adelanto pendiente';
    ELSIF v_saldo = v_total_aprobado THEN
        RETURN 'Pendiente';
    ELSE
        RETURN 'Parcial';
    END IF;
END;
$$;
-- ---------------------------------------------------------------------
-- C3  sp_aplicar_pago  (técnica: CURSOR EXPLÍCITO)
-- Regla   : RN-19 «un pago puede cubrir varios cargos». Reparte el monto
--           de un pago entre los cargos aprobados del mismo evento que
--           aún tienen saldo, del más antiguo al más reciente, sin
--           exceder lo pendiente de cada cargo.
-- Entrada : p_id_pago  pago ya registrado
-- Efecto  : inserta (o acumula) filas en APLICACION_PAGO
-- Error   : si el pago no existe o si queda dinero sin aplicar
--
-- Por qué un cursor: el reparto es secuencial; lo que se aplica a cada
-- cargo depende de cuánto quedó después del cargo anterior, y el recorrido
-- se detiene apenas se acaba el dinero. El cursor explícito con parámetro
-- deja ese orden y ese corte a la vista y permite validar fila por fila.
--
-- Alternativa basada en conjuntos (equivalente; la consulta Q4 de
-- 03_consultas.sql la usa para simular un reparto). Con una suma acumulada
-- se calcula en una sola sentencia cuánto toca a cada cargo:
--
--   INSERT INTO aplicacion_pago (id_pago, id_cargo, id_evento, monto_aplicado)
--   SELECT :id_pago, id_cargo, id_evento,
--          LEAST(pendiente, :monto - (acumulado - pendiente))
--     FROM (SELECT c.id_cargo, c.id_evento,
--                  c.monto - COALESCE(SUM(ap.monto_aplicado), 0) AS pendiente,
--                  SUM(c.monto - COALESCE(SUM(ap.monto_aplicado), 0))
--                      OVER (ORDER BY c.fecha_cargo, c.id_cargo) AS acumulado
--             FROM cargo c LEFT JOIN aplicacion_pago ap ON ap.id_cargo = c.id_cargo
--            WHERE c.id_evento = :id_evento AND c.estado_cargo = 'Aprobado'
--            GROUP BY c.id_cargo) t
--    WHERE pendiente > 0 AND acumulado - pendiente < :monto;
--
-- Discusión: la versión por conjuntos es más corta y, con muchos cargos,
-- más eficiente. Para este proceso un evento tiene pocos cargos, así que
-- el rendimiento no decide; el cursor se eligió porque hace explícita la
-- regla de reparto (orden, tope por cargo y parada) y es más fácil de
-- explicar y de modificar si la empresa cambia el criterio de prioridad.
-- Ambas versiones producen el mismo resultado (prueba T03 vs. consulta Q4).
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_aplicar_pago(p_id_pago INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_evento  INTEGER;
    v_restante   NUMERIC(12,2);
    v_aplicar    NUMERIC(12,2);
    r_cargo      RECORD;

    -- Cargos aprobados del evento con su saldo pendiente, del más antiguo
    cur_cargos_pendientes CURSOR (p_evento INTEGER) FOR
        SELECT c.id_cargo,
               c.monto - COALESCE((SELECT SUM(ap.monto_aplicado)
                                     FROM aplicacion_pago ap
                                    WHERE ap.id_cargo = c.id_cargo), 0) AS pendiente
          FROM cargo c
         WHERE c.id_evento = p_evento
           AND c.estado_cargo = 'Aprobado'
         ORDER BY c.fecha_cargo, c.id_cargo;
BEGIN
    -- Monto del pago que todavía no se ha aplicado
    SELECT p.id_evento,
           p.monto - COALESCE((SELECT SUM(ap.monto_aplicado)
                                 FROM aplicacion_pago ap
                                WHERE ap.id_pago = p.id_pago), 0)
      INTO v_id_evento, v_restante
      FROM pago p
     WHERE p.id_pago = p_id_pago;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El pago % no existe.', p_id_pago
            USING ERRCODE = 'no_data_found';
    END IF;

    OPEN cur_cargos_pendientes(v_id_evento);
    LOOP
        FETCH cur_cargos_pendientes INTO r_cargo;
        EXIT WHEN NOT FOUND OR v_restante = 0;
        CONTINUE WHEN r_cargo.pendiente <= 0;          -- cargo ya cubierto

        v_aplicar := LEAST(v_restante, r_cargo.pendiente);

        INSERT INTO aplicacion_pago (id_pago, id_cargo, id_evento, monto_aplicado)
        VALUES (p_id_pago, r_cargo.id_cargo, v_id_evento, v_aplicar)
        ON CONFLICT (id_pago, id_cargo)
        DO UPDATE SET monto_aplicado = aplicacion_pago.monto_aplicado
                                     + EXCLUDED.monto_aplicado;

        v_restante := v_restante - v_aplicar;
    END LOOP;
    CLOSE cur_cargos_pendientes;

    -- Protección: no debe quedar dinero sin aplicar (deshace toda la operación)
    IF v_restante > 0 THEN
        RAISE EXCEPTION 'El pago % tiene % sin aplicar: supera los cargos pendientes del evento %.',
                        p_id_pago, v_restante, v_id_evento
            USING ERRCODE = 'check_violation';
    END IF;
END;
$$;
-- ---------------------------------------------------------------------
-- C2  sp_registrar_pago
-- Operación: registrar un pago o adelanto del cliente y aplicarlo a los
--            cargos pendientes del evento (PAGO + APLICACION_PAGO).
-- Entradas : p_id_evento, p_monto, p_medio_pago,
--            p_referencia   (opcional; obligatoria salvo Efectivo: CHECK)
--            p_es_adelanto  (por defecto FALSE)
--            p_fecha_pago   (por defecto la fecha actual)
-- Salida   : p_id_pago (INOUT) identificador del pago creado
-- Valida ANTES de modificar (RAISE EXCEPTION con el motivo):
--   V1  el evento existe;
--   V2  el evento tiene saldo pendiente;
--   V3  el monto no excede el saldo pendiente (RN-19, regla NR del P1);
--   V4  un adelanto solo se registra si el evento no está Cerrado ni
--       Cancelado.
-- Lo que ya cubre el esquema (monto > 0, medio permitido, referencia
-- obligatoria, referencia única) NO se repite aquí: lo rechaza el motor.
-- Concurrencia: bloquea la fila del evento (FOR UPDATE) para que dos pagos
-- simultáneos del mismo evento no calculen el saldo al mismo tiempo.
-- Ejemplo  : CALL sp_registrar_pago(2, 400000, 'SINPE Móvil', 'SP-20001');
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    p_id_evento    INTEGER,
    p_monto        NUMERIC(12,2),
    p_medio_pago   VARCHAR(15),
    p_referencia   VARCHAR(40) DEFAULT NULL,
    p_es_adelanto  BOOLEAN     DEFAULT FALSE,
    p_fecha_pago   DATE        DEFAULT CURRENT_DATE,
    INOUT p_id_pago INTEGER    DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_evento  VARCHAR(15);
    v_saldo          NUMERIC(12,2);
BEGIN
    -- V1: el evento existe (y se bloquea su fila)
    SELECT estado_evento INTO v_estado_evento
      FROM evento
     WHERE id_evento = p_id_evento
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pago rechazado: el evento % no existe.', p_id_evento
            USING ERRCODE = 'no_data_found';
    END IF;

    v_saldo := fn_saldo_evento(p_id_evento);

    -- V2: hay algo que cobrar
    IF v_saldo = 0 THEN
        RAISE EXCEPTION 'Pago rechazado: el evento % no tiene saldo pendiente.', p_id_evento
            USING HINT = 'Solo se aplican pagos a cargos aprobados con saldo.';
    END IF;

    -- V3: no se paga más de lo que se debe
    IF p_monto > v_saldo THEN
        RAISE EXCEPTION 'Pago rechazado: el monto % excede el saldo pendiente % del evento %.',
                        p_monto, v_saldo, p_id_evento
            USING HINT = 'Registre un monto menor o igual al saldo.';
    END IF;

    -- V4: un adelanto es previo a la realización del evento
    IF p_es_adelanto AND v_estado_evento IN ('Cerrado', 'Cancelado') THEN
        RAISE EXCEPTION 'Pago rechazado: no se registran adelantos para un evento %.',
                        lower(v_estado_evento);
    END IF;

    INSERT INTO pago (id_evento, fecha_pago, monto, medio_pago, referencia, es_adelanto)
    VALUES (p_id_evento, p_fecha_pago, p_monto, p_medio_pago, p_referencia, p_es_adelanto)
    RETURNING id_pago INTO p_id_pago;

    CALL sp_aplicar_pago(p_id_pago);

    RAISE NOTICE 'Pago % registrado para el evento %. Saldo restante: %.',
                 p_id_pago, p_id_evento, fn_saldo_evento(p_id_evento);
END;
$$;
