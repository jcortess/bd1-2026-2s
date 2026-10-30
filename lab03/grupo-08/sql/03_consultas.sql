-- =====================================================================
-- 03_consultas.sql
-- Consultas de negocio sobre los datos de 02_datos.sql
-- Los resultados esperados asumen una base vacía donde se ejecutó
-- 01_esquema.sql y 02_datos.sql una sola vez (los IDs identity empiezan en 1).
-- =====================================================================

-- ---------------------------------------------------------------------
-- C1. JOIN: listado de solicitudes con el cliente que las hizo
-- Pregunta de negocio: ¿qué solicitudes existen, de quién son y qué
-- nivel de servicio pidieron, de la más antigua a la más reciente?
-- Resultado esperado: 7 filas, en este orden por fecha:
--   4 | Distribuidora Tica S.A. | 2026-09-20 | ECONOMICO
--   1 | María Fernández Solano  | 2026-10-01 | ESTANDAR
--   3 | Carlos Jiménez Rojas    | 2026-10-05 | ECONOMICO
--   5 | Distribuidora Tica S.A. | 2026-10-10 | EXPRESS
--   7 | Café Montaña S.R.L.     | 2026-10-12 | ESTANDAR
--   2 | María Fernández Solano  | 2026-10-15 | EXPRESS
--   6 | Distribuidora Tica S.A. | 2026-10-28 | MISMO_DIA
-- ---------------------------------------------------------------------
SELECT s.id_solicitud,
       c.nombre_razon_social AS cliente,
       s.fecha,
       s.nivel_servicio,
       s.destino
FROM solicitud s
JOIN cliente c ON c.tipo_id   = s.tipo_id
              AND c.numero_id = s.numero_id
ORDER BY s.fecha, s.id_solicitud;

-- ---------------------------------------------------------------------
-- C2. LEFT JOIN + COUNT: solicitudes por cliente, incluyendo los que no tienen
-- Pregunta de negocio: ¿cuántas solicitudes ha hecho cada cliente
-- registrado, aunque sea ninguna?
-- Resultado esperado: 6 filas:
--   Distribuidora Tica S.A. = 3
--   María Fernández Solano  = 2
--   Café Montaña S.R.L.     = 1
--   Carlos Jiménez Rojas    = 1
--   Ana Lucía Pérez Gómez   = 0
--   John Smith              = 0
-- Nota: con INNER JOIN los dos clientes con 0 desaparecerían.
-- ---------------------------------------------------------------------
SELECT c.tipo_id,
       c.numero_id,
       c.nombre_razon_social,
       COUNT(s.id_solicitud) AS total_solicitudes
FROM cliente c
LEFT JOIN solicitud s ON s.tipo_id   = c.tipo_id
                     AND s.numero_id = c.numero_id
GROUP BY c.tipo_id, c.numero_id, c.nombre_razon_social
ORDER BY total_solicitudes DESC, c.nombre_razon_social;

-- ---------------------------------------------------------------------
-- C3. GROUP BY + HAVING: clientes recurrentes y cuántas solicitudes urgentes
-- Pregunta de negocio: ¿qué clientes han pedido más de una vez y cuántas
-- de esas solicitudes fueron urgentes (EXPRESS o MISMO_DIA)?
-- Resultado esperado: 2 filas:
--   Distribuidora Tica S.A. | total = 3 | urgentes = 2
--   María Fernández Solano  | total = 2 | urgentes = 1
-- (Carlos y Café Montaña tienen 1 solicitud y quedan fuera por el HAVING.)
-- ---------------------------------------------------------------------
SELECT c.nombre_razon_social,
       COUNT(*) AS total_solicitudes,
       COUNT(*) FILTER (WHERE s.nivel_servicio IN ('EXPRESS', 'MISMO_DIA')) AS urgentes
FROM cliente c
JOIN solicitud s ON s.tipo_id   = c.tipo_id
                AND s.numero_id = c.numero_id
GROUP BY c.tipo_id, c.numero_id, c.nombre_razon_social
HAVING COUNT(*) > 1
ORDER BY total_solicitudes DESC;

-- ---------------------------------------------------------------------
-- C4. LEFT JOIN anti-join: clientes sin dirección habitual
-- Pregunta de negocio: ¿a qué clientes les falta registrar una dirección?
-- Resultado esperado: 3 filas:
--   Ana Lucía Pérez Gómez, Carlos Jiménez Rojas, John Smith
-- ---------------------------------------------------------------------
SELECT c.tipo_id, c.numero_id, c.nombre_razon_social
FROM cliente c
LEFT JOIN direccion_habitual d ON d.tipo_id   = c.tipo_id
                              AND d.numero_id = c.numero_id
WHERE d.num_direccion IS NULL
ORDER BY c.nombre_razon_social;

-- ---------------------------------------------------------------------
-- C5. JOIN de cuatro tablas: contactos autorizados para enviar y cómo localizarlos
-- Pregunta de negocio: ¿a quién se puede contactar, y por qué medio, para
-- autorizar un envío en nombre de cada cliente?
-- Resultado esperado: 3 filas:
--   Café Montaña S.R.L.     | Sofía Araya León  | WHATSAPP | 8888-0007
--   Distribuidora Tica S.A. | Laura Mora Campos | CORREO   | laura.mora@distribuidoratica.example
--   Distribuidora Tica S.A. | Laura Mora Campos | TELEFONO | 8888-0005
-- (Pedro Vargas y Rosa Solano no tienen la facultad SOLICITAR_SERVICIOS.)
-- ---------------------------------------------------------------------
SELECT cl.nombre_razon_social AS cliente,
       co.nombre              AS contacto,
       m.tipo_medio,
       m.valor
FROM contacto co
JOIN cliente cl           ON cl.tipo_id   = co.tipo_id
                         AND cl.numero_id = co.numero_id
JOIN facultad_contacto f  ON f.id_contacto = co.id_contacto
JOIN medio_contacto_contacto m ON m.id_contacto = co.id_contacto
WHERE f.facultad = 'SOLICITAR_SERVICIOS'
ORDER BY cl.nombre_razon_social, co.nombre, m.tipo_medio;

-- ---------------------------------------------------------------------
-- C6. Filtro por rango de fechas: recolecciones previstas en una semana
-- Pregunta de negocio: ¿qué recolecciones están previstas entre el
-- 10 y el 16 de octubre de 2026 (hora de Costa Rica)?
-- Resultado esperado: 3 filas, por hora de inicio:
--   5 | Distribuidora Tica S.A. | 2026-10-11 07:00 | EXPRESS
--   7 | Café Montaña S.R.L.     | 2026-10-13 08:00 | ESTANDAR
--   2 | María Fernández Solano  | 2026-10-16 09:00 | EXPRESS
-- ---------------------------------------------------------------------
SELECT s.id_solicitud,
       c.nombre_razon_social AS cliente,
       s.periodo_previsto_inicio,
       s.nivel_servicio
FROM solicitud s
JOIN cliente c ON c.tipo_id   = s.tipo_id
              AND c.numero_id = s.numero_id
WHERE s.periodo_previsto_inicio >= '2026-10-10 00:00:00-06'
  AND s.periodo_previsto_inicio <  '2026-10-17 00:00:00-06'
ORDER BY s.periodo_previsto_inicio;