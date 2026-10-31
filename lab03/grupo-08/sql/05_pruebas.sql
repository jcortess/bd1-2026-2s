-- =====================================================================
-- 05_pruebas.sql
-- Laboratorio 3 - Bases de Datos I
-- Proceso: registro de clientes y solicitudes de servicio
--
-- Requiere ejecutar previamente: 01_esquema.sql -> 02_datos.sql -> 04_rutinas.sql
-- Ejecutar sobre una base recién creada (los resultados esperados de las
-- funciones dependen de los IDs generados por 02_datos.sql).
--
-- Contenido:
--   P01-P03  integridad: 3 operaciones válidas (se deshacen con ROLLBACK)
--   P04-P09  integridad: 6 operaciones que deben ser rechazadas
--   F01-F04  funciones
--   SP01-SP02 procedimiento almacenado
--
-- Las pruebas rechazadas usan bloques DO con EXCEPTION: el error se captura,
-- se verifica QUÉ restricción actuó y el script continúa con la siguiente.
-- =====================================================================


-- =====================================================================
-- PARTE A1. INTEGRIDAD - OPERACIONES VÁLIDAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- P01 - EXITOSA: registrar un cliente válido
-- Precondición: no existe el cliente (CEDULA_FISICA, 9-9999-9999).
-- Regla: tipo_id, tipo_cliente y condicion_contractual dentro de su dominio.
-- Esperado: INSERT exitoso y cliente encontrado.
-- Conclusión: el esquema acepta datos que cumplen todas las reglas.
-- ---------------------------------------------------------------------
BEGIN;

INSERT INTO cliente (tipo_id, numero_id, nombre_razon_social, tipo_cliente, condicion_contractual)
VALUES ('CEDULA_FISICA', '9-9999-9999', 'Cliente Prueba Uno', 'PERSONA_FISICA', 'SIN_CONTRATO');

SELECT CASE
    WHEN EXISTS (SELECT 1 FROM cliente
                 WHERE tipo_id = 'CEDULA_FISICA' AND numero_id = '9-9999-9999')
    THEN 'P01 APROBADA: cliente válido registrado'
    ELSE 'P01 ERROR: no se encontró el cliente'
END AS resultado;

ROLLBACK;

-- ---------------------------------------------------------------------
-- P02 - EXITOSA: registrar un medio de contacto para un cliente existente
-- Precondición: existe el cliente (CEDULA_FISICA, 1-1111-1111) (viene de 02).
-- Regla: la FK compuesta apunta a un cliente existente.
-- Esperado: INSERT exitoso.
-- Conclusión: las tablas dependientes aceptan referencias válidas.
-- ---------------------------------------------------------------------
BEGIN;

INSERT INTO medio_contacto_cliente (tipo_id, numero_id, tipo_medio, valor)
VALUES ('CEDULA_FISICA', '1-1111-1111', 'TELEFONO', '8888-9911');

SELECT CASE
    WHEN EXISTS (SELECT 1 FROM medio_contacto_cliente
                 WHERE tipo_id = 'CEDULA_FISICA' AND numero_id = '1-1111-1111'
                   AND tipo_medio = 'TELEFONO' AND valor = '8888-9911')
    THEN 'P02 APROBADA: medio de contacto registrado'
    ELSE 'P02 ERROR: no se encontró el medio de contacto'
END AS resultado;

ROLLBACK;

-- ---------------------------------------------------------------------
-- P03 - EXITOSA: participante que no es cliente
-- Precondición: ninguna.
-- Regla: tipo_id y numero_id pueden ser NULL a la vez (ck_participante_cliente_completo).
-- Esperado: INSERT exitoso.
-- Conclusión: la relación participante-cliente es opcional (0..1), como en el modelo.
-- ---------------------------------------------------------------------
BEGIN;

INSERT INTO participante (identificacion, nombre, tipo_id, numero_id)
VALUES ('9-8888-8888', 'Participante de Prueba', NULL, NULL);

SELECT CASE
    WHEN EXISTS (SELECT 1 FROM participante
                 WHERE identificacion = '9-8888-8888'
                   AND tipo_id IS NULL AND numero_id IS NULL)
    THEN 'P03 APROBADA: participante independiente registrado'
    ELSE 'P03 ERROR: no se encontró el participante'
END AS resultado;

ROLLBACK;


-- =====================================================================
-- PARTE A2. INTEGRIDAD - OPERACIONES QUE DEBEN SER RECHAZADAS
-- Cada bloque verifica el NOMBRE de la restricción que actuó.
-- =====================================================================

-- ---------------------------------------------------------------------
-- P04 - RECHAZADA: tipo de identificación fuera del dominio
-- Precondición: ninguna.
-- Regla: ck_cliente_tipo_id (CHECK de dominio).
-- Esperado: check_violation por ck_cliente_tipo_id.
-- Conclusión: el dominio de tipo_id lo protege la base de datos.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_constraint TEXT;
BEGIN
    BEGIN
        INSERT INTO cliente (tipo_id, numero_id, nombre_razon_social, tipo_cliente, condicion_contractual)
        VALUES ('ID_INVALIDA', '9-7777-7777', 'Cliente Inválido', 'PERSONA_FISICA', 'SIN_CONTRATO');

        RAISE EXCEPTION 'P04 ERROR: se aceptó un tipo de identificación inválido';
    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
            IF v_constraint = 'ck_cliente_tipo_id' THEN
                RAISE NOTICE 'P04 APROBADA: rechazado por %', v_constraint;
            ELSE
                RAISE EXCEPTION 'P04 ERROR: rechazado por otra restricción (%)', v_constraint;
            END IF;
    END;
END;
$$;

-- ---------------------------------------------------------------------
-- P05 - RECHAZADA: solicitud para un cliente inexistente
-- Precondición: no existe el cliente (DIMEX, 999999999999).
-- Regla: fk_solicitud_cliente (integridad referencial).
-- Esperado: foreign_key_violation por fk_solicitud_cliente.
-- Conclusión: no pueden existir solicitudes huérfanas.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_constraint TEXT;
BEGIN
    BEGIN
        INSERT INTO solicitud (
            tipo_id, numero_id, fecha,
            lugar_recoleccion_provincia, lugar_recoleccion_canton,
            lugar_recoleccion_distrito, lugar_recoleccion_otras_senas,
            periodo_previsto_inicio, periodo_previsto_fin,
            destino, nivel_servicio, observaciones)
        VALUES (
            'DIMEX', '999999999999', DATE '2026-10-29',
            'SAN_JOSE', 'San José', 'Carmen', 'Dirección de prueba',
            TIMESTAMPTZ '2026-10-30 08:00:00-06', TIMESTAMPTZ '2026-10-30 10:00:00-06',
            'Destino de prueba', 'ESTANDAR', 'Prueba de clave foránea');

        RAISE EXCEPTION 'P05 ERROR: se aceptó una solicitud para un cliente inexistente';
    EXCEPTION
        WHEN foreign_key_violation THEN
            GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
            IF v_constraint = 'fk_solicitud_cliente' THEN
                RAISE NOTICE 'P05 APROBADA: rechazado por %', v_constraint;
            ELSE
                RAISE EXCEPTION 'P05 ERROR: rechazado por otra restricción (%)', v_constraint;
            END IF;
    END;
END;
$$;

-- ---------------------------------------------------------------------
-- P06 - RECHAZADA: período que termina antes de comenzar
-- Precondición: existe el cliente (CEDULA_FISICA, 1-1111-1111).
-- Regla: ck_solicitud_periodo (coherencia entre columnas).
-- Esperado: check_violation por ck_solicitud_periodo.
-- Conclusión: la coherencia entre inicio y fin la garantiza el esquema.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_constraint TEXT;
BEGIN
    BEGIN
        INSERT INTO solicitud (
            tipo_id, numero_id, fecha,
            lugar_recoleccion_provincia, lugar_recoleccion_canton,
            lugar_recoleccion_distrito, lugar_recoleccion_otras_senas,
            periodo_previsto_inicio, periodo_previsto_fin,
            destino, nivel_servicio, observaciones)
        VALUES (
            'CEDULA_FISICA', '1-1111-1111', DATE '2026-10-29',
            'SAN_JOSE', 'San José', 'Carmen', 'Dirección de prueba',
            TIMESTAMPTZ '2026-10-30 12:00:00-06', TIMESTAMPTZ '2026-10-30 10:00:00-06',
            'Destino de prueba', 'ESTANDAR', 'Prueba de período inválido');

        RAISE EXCEPTION 'P06 ERROR: se aceptó un período inválido';
    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
            IF v_constraint = 'ck_solicitud_periodo' THEN
                RAISE NOTICE 'P06 APROBADA: rechazado por %', v_constraint;
            ELSE
                RAISE EXCEPTION 'P06 ERROR: rechazado por otra restricción (%)', v_constraint;
            END IF;
    END;
END;
$$;

-- ---------------------------------------------------------------------
-- P07 - RECHAZADA: cliente con identificación duplicada
-- Precondición: ya existe el cliente (CEDULA_FISICA, 1-1111-1111).
-- Regla: pk_cliente (unicidad de la clave primaria compuesta).
-- Esperado: unique_violation por pk_cliente.
-- Conclusión: una misma identificación no puede registrarse dos veces.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_constraint TEXT;
BEGIN
    BEGIN
        INSERT INTO cliente (tipo_id, numero_id, nombre_razon_social, tipo_cliente, condicion_contractual)
        VALUES ('CEDULA_FISICA', '1-1111-1111', 'Cliente Duplicado', 'PERSONA_FISICA', 'SIN_CONTRATO');

        RAISE EXCEPTION 'P07 ERROR: se aceptó un cliente duplicado';
    EXCEPTION
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
            IF v_constraint = 'pk_cliente' THEN
                RAISE NOTICE 'P07 APROBADA: rechazado por %', v_constraint;
            ELSE
                RAISE EXCEPTION 'P07 ERROR: rechazado por otra restricción (%)', v_constraint;
            END IF;
    END;
END;
$$;

-- ---------------------------------------------------------------------
-- P08 - RECHAZADA: cliente sin nombre (obligatoriedad)
-- Precondición: ninguna.
-- Regla: NOT NULL sobre nombre_razon_social.
-- Esperado: not_null_violation sobre la columna nombre_razon_social.
-- Conclusión: los atributos obligatorios del modelo no admiten NULL.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_columna TEXT;
BEGIN
    BEGIN
        INSERT INTO cliente (tipo_id, numero_id, nombre_razon_social, tipo_cliente, condicion_contractual)
        VALUES ('CEDULA_FISICA', '9-6666-6666', NULL, 'PERSONA_FISICA', 'SIN_CONTRATO');

        RAISE EXCEPTION 'P08 ERROR: se aceptó un cliente sin nombre';
    EXCEPTION
        WHEN not_null_violation THEN
            GET STACKED DIAGNOSTICS v_columna = COLUMN_NAME;
            IF v_columna = 'nombre_razon_social' THEN
                RAISE NOTICE 'P08 APROBADA: rechazado por NOT NULL en %', v_columna;
            ELSE
                RAISE EXCEPTION 'P08 ERROR: rechazado por otra columna (%)', v_columna;
            END IF;
    END;
END;
$$;

-- ---------------------------------------------------------------------
-- P09 - RECHAZADA: borrar un cliente que tiene solicitudes
-- Precondición: Carlos Jiménez (CEDULA_FISICA, 2-2222-2222) tiene 1 solicitud.
-- Regla: fk_solicitud_cliente con ON DELETE RESTRICT.
-- Esperado: foreign_key_violation por fk_solicitud_cliente.
-- Conclusión: no se pierde el historial de solicitudes al borrar un cliente.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_constraint TEXT;
BEGIN
    BEGIN
        DELETE FROM cliente
        WHERE tipo_id = 'CEDULA_FISICA' AND numero_id = '2-2222-2222';

        RAISE EXCEPTION 'P09 ERROR: se borró un cliente con solicitudes';
    EXCEPTION
        WHEN foreign_key_violation THEN
            GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
            IF v_constraint = 'fk_solicitud_cliente' THEN
                RAISE NOTICE 'P09 APROBADA: rechazado por %', v_constraint;
            ELSE
                RAISE EXCEPTION 'P09 ERROR: rechazado por otra restricción (%)', v_constraint;
            END IF;
    END;
END;
$$;


-- =====================================================================
-- PARTE B. PRUEBAS DE FUNCIONES
-- =====================================================================

-- F01 - Solicitudes de un cliente. Esperado: 3 filas (solicitudes 4, 5 y 6).
SELECT * FROM fn_solicitudes_cliente('CEDULA_JURIDICA', '3-101-111111');

-- F02 - Prioridad de una solicitud. Esperado: CRITICA (MISMO_DIA).
SELECT 6 AS id_solicitud,
       fn_prioridad_solicitud(6) AS prioridad_obtenida,
       'CRITICA' AS prioridad_esperada,
       CASE WHEN fn_prioridad_solicitud(6) = 'CRITICA'
            THEN 'F02 APROBADA' ELSE 'F02 ERROR' END AS resultado;

-- F03 - Reporte con cursor explícito. Esperado: 7 filas
--       (1 NORMAL, 2 ALTA, 3 BAJA, 4 BAJA, 5 CRITICA, 6 CRITICA, 7 NORMAL).
SELECT * FROM fn_reporte_prioridades();

-- F04 - RECHAZADA: cliente inexistente en fn_solicitudes_cliente.
-- Esperado: excepción con el mensaje "El cliente (DIMEX, 999) no existe".
DO $$
BEGIN
    BEGIN
        PERFORM * FROM fn_solicitudes_cliente('DIMEX', '999');
        RAISE EXCEPTION 'F04 ERROR: la función aceptó un cliente inexistente';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'El cliente (%) no existe' THEN
                RAISE NOTICE 'F04 APROBADA: %', SQLERRM;
            ELSE
                RAISE;
            END IF;
    END;
END;
$$;


-- =====================================================================
-- PARTE C. PRUEBAS DEL PROCEDIMIENTO ALMACENADO
-- =====================================================================

-- ---------------------------------------------------------------------
-- SP01 - EXITOSA: registrar un contacto con facultad y medio
-- Precondición: Café Montaña S.R.L. es una organización.
-- Esperado: una fila con el contacto, AUTORIZAR_CARGOS y el correo.
-- Se usa transacción con ROLLBACK para no conservar datos de prueba.
-- ---------------------------------------------------------------------
BEGIN;

CALL sp_registrar_contacto(
    'CEDULA_JURIDICA', '3-102-222222',
    'Contacto Prueba Exitoso', 'AUTORIZAR_CARGOS',
    'CORREO', 'contacto.prueba@cafemontana.example');

SELECT c.id_contacto, c.nombre, fc.facultad, mc.tipo_medio, mc.valor
FROM contacto c
JOIN facultad_contacto fc ON fc.id_contacto = c.id_contacto
JOIN medio_contacto_contacto mc ON mc.id_contacto = c.id_contacto
WHERE c.nombre = 'Contacto Prueba Exitoso';

ROLLBACK;

-- ---------------------------------------------------------------------
-- SP02 - RECHAZADA: contacto para un cliente que no es organización
-- Precondición: Carlos Jiménez Rojas es PERSONA_FISICA.
-- Regla: RN-02 / S-02, validada dentro del procedimiento.
-- Esperado: excepción "No se puede registrar el contacto: ... no es una organización".
-- Conclusión: el procedimiento valida antes de modificar; no se guarda nada.
-- ---------------------------------------------------------------------
DO $$
BEGIN
    BEGIN
        CALL sp_registrar_contacto(
            'CEDULA_FISICA', '2-2222-2222',
            'Contacto Prueba Rechazado', 'SOLICITAR_SERVICIOS',
            'TELEFONO', '8888-0099');

        RAISE EXCEPTION 'SP02 ERROR: el procedimiento aceptó un contacto para una persona física';
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'No se puede registrar el contacto: el cliente%no es una organización%' THEN
                RAISE NOTICE 'SP02 APROBADA: %', SQLERRM;
            ELSE
                RAISE;
            END IF;
    END;
END;
$$;

-- Comprobación: el rechazo no dejó ningún contacto a medias. Esperado: 0.
SELECT COUNT(*) AS contactos_rechazados
FROM contacto
WHERE nombre = 'Contacto Prueba Rechazado';

-- =====================================================================
-- FIN DE LAS PRUEBAS
-- =====================================================================