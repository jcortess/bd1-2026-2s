-- =====================================================================
-- 04_consultas.sql
-- Proyecto final IC-4301 - Grupo 08: Envíos Conecta
-- Consultas de estado actual, historia y agregados de los procesos.
-- Requiere: 01_esquema.sql, 02_datos.sql y 03_rutinas.sql.
-- Los filtros usan datos de 02_datos.sql; se cambian para consultar
-- otros envíos, paquetes o salidas.
-- =====================================================================


-- =====================================================================
-- PARTE 1. CONSULTAS DE LOS PROCESOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- C1. Estado actual de cada paquete (G08-P03, AC-G08-P03-01, CAM-003)
-- Último evento vigente: mayor momento, luego momento de registro, luego
-- id del evento. Un evento corregido no cuenta: cuenta su corrección.
-- ---------------------------------------------------------------------
SELECT DISTINCT ON (e.numero_guia, e.num_paquete)
       e.numero_guia,
       e.num_paquete,
       e.situacion,
       e.tipo_evento,
       e.momento,
       COALESCE(s.nombre, e.descripcion_ubicacion)            AS ubicacion,
       CASE WHEN s.id_sede IS NOT NULL AND e.descripcion_ubicacion IS NOT NULL
            THEN e.descripcion_ubicacion END                  AS detalle_ubicacion,
       p.nombre                                               AS responsable,
       e.id_evento
FROM evento_seguimiento e
JOIN personal p   ON p.id_personal = e.id_personal
LEFT JOIN sede s  ON s.id_sede = e.id_sede
WHERE NOT EXISTS (SELECT 1 FROM evento_seguimiento c
                  WHERE c.id_evento_corregido = e.id_evento)
ORDER BY e.numero_guia, e.num_paquete,
         e.momento DESC, e.momento_registro DESC, e.id_evento DESC;

-- ---------------------------------------------------------------------
-- C2. Historial completo de un paquete con sus correcciones
-- (G08-P03-V, AC-G08-P03-03). Los eventos corregidos se conservan.
-- ---------------------------------------------------------------------
SELECT e.id_evento,
       e.momento,
       e.momento_registro,
       e.tipo_evento,
       e.situacion,
       e.condicion,
       COALESCE(s.nombre, e.descripcion_ubicacion)  AS ubicacion,
       p.nombre                                     AS responsable_o_autor,
       e.id_salida,
       e.id_evento_corregido                        AS corrige_a,
       e.motivo_correccion,
       EXISTS (SELECT 1 FROM evento_seguimiento c
               WHERE c.id_evento_corregido = e.id_evento) AS fue_corregido
FROM evento_seguimiento e
JOIN personal p  ON p.id_personal = e.id_personal
LEFT JOIN sede s ON s.id_sede = e.id_sede
WHERE e.numero_guia = 'EC-2026-000102'
  AND e.num_paquete = 1
ORDER BY e.momento, e.momento_registro, e.id_evento;

-- ---------------------------------------------------------------------
-- C3. Incidencias con el resultado de cada paquete afectado
-- (AC-G08-P03-02, RN-18, CAM-021)
-- ---------------------------------------------------------------------
SELECT i.id_incidencia,
       i.tipo,
       i.fecha,
       i.estado,
       p.nombre               AS responsable_atencion,
       ip.numero_guia,
       ip.num_paquete,
       ip.resultado,
       count(*) FILTER (WHERE ip.resultado = 'PENDIENTE')
           OVER (PARTITION BY i.id_incidencia) AS pendientes_de_la_incidencia
FROM incidencia i
JOIN personal p            ON p.id_personal = i.id_personal
JOIN incidencia_paquete ip ON ip.id_incidencia = i.id_incidencia
ORDER BY i.id_incidencia, ip.numero_guia, ip.num_paquete;

-- ---------------------------------------------------------------------
-- C4. Manifiesto de una salida (AC-G08-P02-01)
-- Peso y volumen usados: medición aplicada o, si no hay, lo declarado (S-07).
-- ---------------------------------------------------------------------
SELECT sp.id_salida,
       sp.numero_guia,
       sp.num_paquete,
       pq.descripcion,
       COALESCE(m.peso, pq.peso_declarado)                     AS peso_kg,
       round(COALESCE(m.largo, pq.largo_declarado)
           * COALESCE(m.ancho, pq.ancho_declarado)
           * COALESCE(m.alto,  pq.alto_declarado) / 1000000, 6) AS volumen_m3,
       CASE WHEN m.num_medicion IS NULL THEN 'DECLARADO'
            ELSE 'MEDICION ' || m.num_medicion END             AS valores_usados,
       sp.momento_registro
FROM salida_paquete sp
JOIN paquete pq
  ON pq.numero_guia = sp.numero_guia AND pq.num_paquete = sp.num_paquete
LEFT JOIN medicion m
  ON m.numero_guia = pq.numero_guia
 AND m.num_paquete = pq.num_paquete
 AND m.num_medicion = pq.num_medicion_aplicada
WHERE sp.id_salida = 1
ORDER BY sp.numero_guia, sp.num_paquete;

-- C4b. Carga de cada salida frente a la capacidad de su vehículo vigente
-- (AC-G08-P02-02, CAM-025)
WITH carga AS (
    SELECT sp.id_salida,
           count(*)                                          AS paquetes,
           sum(COALESCE(m.peso, pq.peso_declarado))          AS peso_kg,
           sum(COALESCE(m.largo, pq.largo_declarado)
             * COALESCE(m.ancho, pq.ancho_declarado)
             * COALESCE(m.alto,  pq.alto_declarado) / 1000000) AS volumen_m3
    FROM salida_paquete sp
    JOIN paquete pq
      ON pq.numero_guia = sp.numero_guia AND pq.num_paquete = sp.num_paquete
    LEFT JOIN medicion m
      ON m.numero_guia = pq.numero_guia
     AND m.num_paquete = pq.num_paquete
     AND m.num_medicion = pq.num_medicion_aplicada
    GROUP BY sp.id_salida
)
SELECT s.id_salida,
       r.nombre                    AS ruta,
       s.fecha,
       s.estado,
       v.placa,
       c.paquetes,
       c.peso_kg,
       v.capacidad_peso            AS capacidad_kg,
       round(c.volumen_m3, 6)      AS volumen_m3,
       v.capacidad_volumen         AS capacidad_m3
FROM salida_ruta s
JOIN ruta r       ON r.id_ruta = s.id_ruta
LEFT JOIN carga c ON c.id_salida = s.id_salida
LEFT JOIN asignacion a
       ON a.id_salida = s.id_salida AND a.vigente AND a.funcion_ejercida = 'CONDUCTOR'
LEFT JOIN vehiculo v ON v.id_interno = a.id_vehiculo
ORDER BY s.id_salida;

-- ---------------------------------------------------------------------
-- C5. Asignaciones de una salida, vigentes y sustituidas
-- (AC-G08-P02-03, RN-23, CAM-015, CAM-027)
-- ---------------------------------------------------------------------
SELECT a.id_asignacion,
       p.nombre                    AS persona,
       a.funcion_ejercida,
       v.placa,
       a.inicio,
       a.fin,
       a.vigente,
       a.id_asignacion_sustituida  AS sustituye_a,
       a.motivo_cambio,
       a.momento_registro
FROM asignacion a
JOIN personal p ON p.id_personal = a.id_personal
JOIN vehiculo v ON v.id_interno = a.id_vehiculo
WHERE a.id_salida = 1
ORDER BY a.id_asignacion;

-- ---------------------------------------------------------------------
-- C6. Envíos con sus paquetes: contexto conservado, declarado frente a
-- medido y resultado de la revisión (AC-G08-P01-01 a 04)
-- ---------------------------------------------------------------------
SELECT e.numero_guia,
       e.id_solicitud,
       cl.nombre_razon_social                                AS pagador,
       rem.nombre                                            AS remitente,
       des.nombre                                            AS destinatario,
       e.destino_provincia || ', ' || e.destino_canton       AS destino_usado,
       e.precio_cotizado,
       e.cotiz_peso,
       e.cotiz_volumen,
       pq.num_paquete,
       pq.politica_contenido,
       pq.peso_declarado,
       m.peso                                                AS peso_medido_aplicado,
       pq.revision_resultado,
       pq.revision_razon
FROM envio e
JOIN cliente cl       ON cl.tipo_id = e.tipo_id_pagador AND cl.numero_id = e.numero_id_pagador
JOIN participante rem ON rem.id_participante = e.id_participante_remitente
JOIN participante des ON des.id_participante = e.id_participante_destinatario
JOIN paquete pq       ON pq.numero_guia = e.numero_guia
LEFT JOIN medicion m
       ON m.numero_guia = pq.numero_guia
      AND m.num_paquete = pq.num_paquete
      AND m.num_medicion = pq.num_medicion_aplicada
ORDER BY e.numero_guia, pq.num_paquete;

-- ---------------------------------------------------------------------
-- C7. Solicitudes con devoluciones (RN-19, CAM-020)
-- ---------------------------------------------------------------------
SELECT so.id_solicitud,
       cl.nombre_razon_social     AS cliente,
       d.numero_guia,
       dp.num_paquete,
       pq.descripcion,
       d.id_devolucion,
       d.fecha                    AS fecha_devolucion,
       d.motivo,
       dp.id_entrega,
       en.fecha_hora              AS fecha_entrega_rechazada
FROM devolucion d
JOIN devolucion_paquete dp ON dp.id_devolucion = d.id_devolucion
JOIN paquete pq            ON pq.numero_guia = dp.numero_guia AND pq.num_paquete = dp.num_paquete
JOIN envio e               ON e.numero_guia = d.numero_guia
JOIN solicitud so          ON so.id_solicitud = e.id_solicitud
JOIN cliente cl            ON cl.tipo_id = so.tipo_id AND cl.numero_id = so.numero_id
JOIN entrega en            ON en.id_entrega = dp.id_entrega
ORDER BY so.id_solicitud, d.numero_guia, dp.num_paquete;

-- ---------------------------------------------------------------------
-- C8. Paquetes con contenido prohibido y quién los envía (RN-11, CAM-006)
-- "Prohibido" es la política de la empresa para el paquete; no es una lista legal.
-- Medios de contacto: los del participante o, si es un cliente vinculado,
-- los de su cliente.
-- ---------------------------------------------------------------------
SELECT pq.numero_guia,
       pq.num_paquete,
       pq.descripcion,
       pq.revision_resultado,
       pq.revision_razon,
       rem.tipo_identificacion,
       rem.identificacion,
       rem.nombre                  AS remitente,
       COALESCE(
           (SELECT string_agg(m.tipo_medio || ': ' || m.valor, '; ' ORDER BY m.tipo_medio, m.valor)
            FROM medio_contacto_participante m
            WHERE m.id_participante = rem.id_participante),
           (SELECT string_agg(m.tipo_medio || ': ' || m.valor, '; ' ORDER BY m.tipo_medio, m.valor)
            FROM medio_contacto_cliente m
            WHERE m.tipo_id = rem.tipo_id AND m.numero_id = rem.numero_id)
       )                           AS medios_de_contacto,
       cl.nombre_razon_social      AS pagador
FROM paquete pq
JOIN envio e          ON e.numero_guia = pq.numero_guia
JOIN participante rem ON rem.id_participante = e.id_participante_remitente
JOIN cliente cl       ON cl.tipo_id = e.tipo_id_pagador AND cl.numero_id = e.numero_id_pagador
WHERE pq.politica_contenido = 'PROHIBIDO'
ORDER BY pq.numero_guia, pq.num_paquete;


-- =====================================================================
-- PARTE 2. CONSULTAS REUTILIZADAS DE LAB03 (03_consultas.sql, sin cambios)
-- Con 02_datos.sql de esta entrega dan los mismos resultados que en Lab03.
-- =====================================================================

-- L1. Solicitudes con el cliente que las hizo. Esperado: 7 filas por fecha.
SELECT s.id_solicitud,
       c.nombre_razon_social AS cliente,
       s.fecha,
       s.nivel_servicio,
       s.destino
FROM solicitud s
JOIN cliente c ON c.tipo_id   = s.tipo_id
              AND c.numero_id = s.numero_id
ORDER BY s.fecha, s.id_solicitud;

-- L2. Solicitudes por cliente, incluidos los que no tienen. Esperado: 6 filas
-- (Distribuidora 3, María 2, Café Montaña 1, Carlos 1, Ana Lucía 0, John 0).
SELECT c.tipo_id,
       c.numero_id,
       c.nombre_razon_social,
       COUNT(s.id_solicitud) AS total_solicitudes
FROM cliente c
LEFT JOIN solicitud s ON s.tipo_id   = c.tipo_id
                     AND s.numero_id = c.numero_id
GROUP BY c.tipo_id, c.numero_id, c.nombre_razon_social
ORDER BY total_solicitudes DESC, c.nombre_razon_social;

-- L3. Clientes recurrentes y solicitudes urgentes. Esperado: Distribuidora 3/2, María 2/1.
SELECT c.nombre_razon_social,
       COUNT(*) AS total_solicitudes,
       COUNT(*) FILTER (WHERE s.nivel_servicio IN ('EXPRESS', 'MISMO_DIA')) AS urgentes
FROM cliente c
JOIN solicitud s ON s.tipo_id   = c.tipo_id
                AND s.numero_id = c.numero_id
GROUP BY c.tipo_id, c.numero_id, c.nombre_razon_social
HAVING COUNT(*) > 1
ORDER BY total_solicitudes DESC;

-- L4. Clientes sin dirección habitual. Esperado: Ana Lucía, Carlos, John.
SELECT c.tipo_id, c.numero_id, c.nombre_razon_social
FROM cliente c
LEFT JOIN direccion_habitual d ON d.tipo_id   = c.tipo_id
                              AND d.numero_id = c.numero_id
WHERE d.num_direccion IS NULL
ORDER BY c.nombre_razon_social;

-- L5. Contactos con facultad SOLICITAR_SERVICIOS y sus medios. Esperado: 3 filas.
SELECT cl.nombre_razon_social AS cliente,
       co.nombre              AS contacto,
       m.tipo_medio,
       m.valor
FROM contacto co
JOIN cliente cl                ON cl.tipo_id   = co.tipo_id
                              AND cl.numero_id = co.numero_id
JOIN facultad_contacto f       ON f.id_contacto = co.id_contacto
JOIN medio_contacto_contacto m ON m.id_contacto = co.id_contacto
WHERE f.facultad = 'SOLICITAR_SERVICIOS'
ORDER BY cl.nombre_razon_social, co.nombre, m.tipo_medio;

-- L6. Recolecciones previstas entre el 10 y el 16 de octubre de 2026.
-- Esperado: solicitudes 5, 7 y 2.
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