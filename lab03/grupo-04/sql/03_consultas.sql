-- Resultados esperados sobre 02_datos.sql, ANTES de pruebas.
BEGIN;
-- Q-01: Que otorgamientos estan vigentes, para quien y para que organizacion?
-- Esperado (id_autorizacion,id_cliente,nombre): (1,2,Bruno Prueba), (2,2,Carla Prueba),
--           (5,3,Bruno Prueba), (6,2,Bruno Prueba).
WITH parametros AS (SELECT TIMESTAMPTZ '2026-10-29 10:00:00-06' AS fecha)
SELECT a.id_autorizacion,c.id_cliente,c.razon_social,p.nombre,
       a.inicio_vigencia,a.fin_vigencia
FROM public.autorizacion a
JOIN public.cliente c USING (id_cliente)
JOIN public.persona p ON p.id_persona=a.id_persona
CROSS JOIN parametros r
WHERE c.tipo_cliente='Organización' AND a.inicio_vigencia<=r.fecha
  AND (a.fin_vigencia IS NULL OR r.fecha<a.fin_vigencia)
ORDER BY a.id_autorizacion;
-- Q-02: Cuantas personas distintas tienen autorizacion vigente por organizacion?
-- Incluye organizaciones sin autorizaciones. Esperado (cliente,total): (2,2),(3,1),(4,0).
WITH parametros AS (SELECT TIMESTAMPTZ '2026-10-29 10:00:00-06' AS fecha)
SELECT c.id_cliente,c.razon_social,count(DISTINCT a.id_persona) AS personas_vigentes
FROM public.cliente c CROSS JOIN parametros r
LEFT JOIN public.autorizacion a ON a.id_cliente=c.id_cliente
 AND a.inicio_vigencia<=r.fecha AND (a.fin_vigencia IS NULL OR r.fecha<a.fin_vigencia)
WHERE c.tipo_cliente='Organización'
GROUP BY c.id_cliente,c.razon_social ORDER BY c.id_cliente;
-- Q-03: Que autorizaciones actualmente vigentes vencen en [noviembre, enero)?
-- Esperado IDs 1,5,6; las abiertas y las futuras no se incluyen.
WITH parametros AS (
 SELECT TIMESTAMPTZ '2026-10-29 10:00:00-06' AS fecha,
        TIMESTAMPTZ '2026-11-01 00:00:00-06' AS desde,
        TIMESTAMPTZ '2027-01-01 00:00:00-06' AS hasta
)
SELECT a.id_autorizacion,a.id_cliente,a.id_persona,a.fin_vigencia
FROM public.autorizacion a CROSS JOIN parametros r
WHERE a.inicio_vigencia<=r.fecha AND a.fin_vigencia>r.fecha
 AND a.fin_vigencia>=r.desde AND a.fin_vigencia<r.hasta
ORDER BY a.id_autorizacion;
-- Q-04 / C3: reutilizacion temporal. Esperado: futura=1, vencida=1, vigente=4.
CALL public.sp_preparar_resumen(TIMESTAMPTZ '2026-10-29 10:00:00-06');
SELECT estado,count(*) AS otorgamientos FROM pg_temp.resumen_autorizaciones
GROUP BY estado ORDER BY estado;
-- Alternativa basada en conjuntos: misma clasificacion, sin tabla temporal.
-- Para este reporte aislado la CTE es mas sencilla; la temporal es didactica
-- y permite reutilizar la clasificacion en varios reportes de una transaccion.
WITH clasificacion AS (
 SELECT CASE WHEN TIMESTAMPTZ '2026-10-29 10:00:00-06'<inicio_vigencia THEN 'futura'
             WHEN fin_vigencia IS NOT NULL AND TIMESTAMPTZ '2026-10-29 10:00:00-06'>=fin_vigencia THEN 'vencida'
             ELSE 'vigente' END AS estado
 FROM public.autorizacion
)
SELECT estado,count(*) AS otorgamientos FROM clasificacion GROUP BY estado ORDER BY estado;
COMMIT;
