-- Archivo : 03_consultas.sql
-- Propósito: consultas de negocio del proceso de cobro
-- Requiere: 01_esquema, 02_datos y 04_rutinas (usa fn_saldo_evento y
--           fn_estado_pago_evento)
-- Los resultados esperados corresponden a los datos de 02_datos.sql.

-- ---------------------------------------------------------------------
-- Q1 · Estado de cuenta por evento                       (JOIN de 6 tablas)
-- Pregunta: ¿cuánto se ha aprobado y pagado de cada evento, quién es el
--           cliente y en qué situación de cobro está?
-- Resultado esperado (4 filas):
--   E1 Ana Rojas Mora        boda        Cerrado    2 610 000  2 610 000          0  Pagado
--   E2 Café del Valle S.A.   empresarial Confirmado 1 110 000    500 000    610 000  Parcial
--   E3 Luis Vargas Solís     familiar    Confirmado   660 000          0    660 000  Adelanto pendiente
--   E4 Carlos Méndez Arias   comunitario Cancelado    200 000          0    200 000  Pendiente
-- ---------------------------------------------------------------------
SELECT e.id_evento,
       COALESCE(pe.nombre_completo, cl.razon_social)          AS cliente,
       e.tipo_evento,
       e.fecha_inicio,
       e.estado_evento,
       COALESCE(SUM(c.monto) FILTER (WHERE c.estado_cargo = 'Aprobado'), 0)
                                                            AS total_aprobado,
       COALESCE(SUM(c.monto) FILTER (WHERE c.estado_cargo = 'Aprobado'), 0)
         - fn_saldo_evento(e.id_evento)                     AS total_pagado,
       fn_saldo_evento(e.id_evento)                         AS saldo,
       fn_estado_pago_evento(e.id_evento)                   AS estado_pago
  FROM evento e
  JOIN propuesta  pr ON pr.id_propuesta = e.id_propuesta
  JOIN solicitud  s  ON s.id_solicitud  = pr.id_solicitud
  JOIN cliente    cl ON cl.id_cliente   = s.id_cliente
  LEFT JOIN persona pe ON pe.id_persona = cl.id_persona
  LEFT JOIN cargo   c  ON c.id_evento   = e.id_evento
 GROUP BY e.id_evento, pe.nombre_completo, cl.razon_social
 ORDER BY e.id_evento;


-- ---------------------------------------------------------------------
-- Q2 · Clientes con saldo pendiente              (GROUP BY + HAVING + JOIN)
-- Pregunta: ¿qué clientes responsables deben dinero, cuánto y en cuántos
--           cargos? (RN-18: cada cargo tiene un responsable)
-- Resultado esperado (3 filas, de mayor a menor deuda):
--   Luis Vargas Solís     1 cargo   660 000
--   Café del Valle S.A.   2 cargos  610 000
--   Carlos Méndez Arias   1 cargo   200 000
--   (Ana Rojas Mora no aparece: sus cargos suman 0 pendiente y HAVING
--    la excluye)
-- ---------------------------------------------------------------------
SELECT cl.id_cliente,
       COALESCE(pe.nombre_completo, cl.razon_social)   AS cliente_responsable,
       COUNT(*) FILTER (WHERE sc.pendiente > 0)        AS cargos_con_saldo,
       SUM(sc.pendiente)                               AS saldo_pendiente
  FROM (SELECT c.id_cargo,
               c.id_cliente_responsable,
               c.monto - COALESCE(SUM(ap.monto_aplicado), 0) AS pendiente
          FROM cargo c
          LEFT JOIN aplicacion_pago ap ON ap.id_cargo = c.id_cargo
         WHERE c.estado_cargo = 'Aprobado'
         GROUP BY c.id_cargo) sc
  JOIN cliente cl      ON cl.id_cliente = sc.id_cliente_responsable
  LEFT JOIN persona pe ON pe.id_persona = cl.id_persona
 GROUP BY cl.id_cliente, pe.nombre_completo, cl.razon_social
HAVING SUM(sc.pendiente) > 0
 ORDER BY saldo_pendiente DESC;


-- ---------------------------------------------------------------------
-- Q3 · Recaudación por medio de pago                         (agregación)
-- Pregunta: ¿por qué medios pagan los clientes y cuánto entra por cada
--           uno? Sirve para conciliar con el banco.
-- Resultado esperado (4 filas, de mayor a menor monto):
--   Transferencia  2 pagos  1 adelanto  1 800 000  promedio 900 000
--   Efectivo       1 pago   0 adelantos   610 000
--   SINPE Móvil    1 pago   1 adelanto    500 000
--   Tarjeta        1 pago   0 adelantos   200 000
-- ---------------------------------------------------------------------
SELECT p.medio_pago,
       COUNT(*)                                    AS cantidad_pagos,
       COUNT(*) FILTER (WHERE p.es_adelanto)       AS adelantos,
       SUM(p.monto)                                AS total_recaudado,
       ROUND(AVG(p.monto), 2)                      AS pago_promedio
  FROM pago p
 GROUP BY p.medio_pago
 ORDER BY total_recaudado DESC;


-- ---------------------------------------------------------------------
-- Q4 · Simulación del reparto de un pago     (solución basada en conjuntos)
-- Pregunta: si el cliente del evento 2 paga 400 000, ¿a qué cargos se
--           aplicaría y cuánto a cada uno? Es la alternativa sin cursor de
--           sp_aplicar_pago (ver 04_rutinas.sql, C3): aplica del cargo más
--           antiguo al más reciente usando una suma acumulada.
-- Resultado esperado (2 filas):
--   cargo 6  pendiente 260 000  se aplicaría 260 000
--   cargo 7  pendiente 350 000  se aplicaría 140 000
-- ---------------------------------------------------------------------
WITH parametros AS (
    SELECT 2 AS id_evento, 400000.00::NUMERIC(12,2) AS monto_pago
),
pendientes AS (
    SELECT c.id_cargo,
           c.descripcion,
           c.fecha_cargo,
           c.monto - COALESCE(SUM(ap.monto_aplicado), 0) AS pendiente
      FROM cargo c
      JOIN parametros pa ON pa.id_evento = c.id_evento
      LEFT JOIN aplicacion_pago ap ON ap.id_cargo = c.id_cargo
     WHERE c.estado_cargo = 'Aprobado'
     GROUP BY c.id_cargo
    HAVING c.monto - COALESCE(SUM(ap.monto_aplicado), 0) > 0
),
acumulado AS (
    SELECT pe.*,
           SUM(pe.pendiente) OVER (ORDER BY pe.fecha_cargo, pe.id_cargo) AS acumulado
      FROM pendientes pe
)
SELECT a.id_cargo,
       a.descripcion,
       a.pendiente,
       LEAST(a.pendiente, pa.monto_pago - (a.acumulado - a.pendiente)) AS se_aplicaria
  FROM acumulado a
 CROSS JOIN parametros pa
 WHERE a.acumulado - a.pendiente < pa.monto_pago
 ORDER BY a.fecha_cargo, a.id_cargo;
