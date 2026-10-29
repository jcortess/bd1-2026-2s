-- IC-4301 | Laboratorio 3 | Grupo 04 | Alquileres El Roble
-- Script de consultas requeridas y sus resultados esperados (03_consultas.sql)

-- -----------------------------------------------------------------------------
-- Consulta 1: Listar todos los clientes (Físicos u Organizaciones) con su identificación
-- Razón de ser: Permite visualizar de forma unificada la información de contacto de los clientes.
-- -----------------------------------------------------------------------------
SELECT 
    c.id_cliente,
    c.tipo_cliente,
    COALESCE(p.nombre, c.razon_social) AS nombre_o_razon_social,
    COALESCE(p.identificacion, c.identificacion_organizacion) AS identificacion_documento,
    c.direccion
FROM cliente c
LEFT JOIN persona p ON c.id_persona = p.id_persona
ORDER BY c.id_cliente;

/* Resultado esperado Consulta 1:
 id_cliente | tipo_cliente |   nombre_o_razon_social    | identificacion_documento |        direccion        
------------+--------------+----------------------------+--------------------------+-------------------------
          1 | Física       | Carlos Hidalgo             | 101110222                | Ciudad Quesada, Alajuela
          2 | Organización | Constructora El Roble S.A. | 3-101-123456             | Santa Clara, San Carlos
(2 rows)
*/


-- -----------------------------------------------------------------------------
-- Consulta 2: Listar autorizaciones activas/vigentes con el detalle del cliente y la persona autorizada
-- Razón de ser: Validar quiénes tienen permiso vigente para actuar en nombre de un cliente.
-- -----------------------------------------------------------------------------
SELECT 
    a.id_autorizacion,
    COALESCE(p_cli.nombre, c.razon_social) AS cliente,
    p_aut.nombre AS persona_autorizada,
    a.inicio_vigencia,
    a.fin_vigencia
FROM autorizacion a
JOIN cliente c ON a.id_cliente = c.id_cliente
LEFT JOIN persona p_cli ON c.id_persona = p_cli.id_persona
JOIN persona p_aut ON a.id_persona = p_aut.id_persona
WHERE a.inicio_vigencia <= CURRENT_TIMESTAMP
  AND (a.fin_vigencia IS NULL OR a.fin_vigencia > CURRENT_TIMESTAMP)
ORDER BY a.id_autorizacion;

/* Resultado esperado Consulta 2:
 id_autorizacion |          cliente           | persona_autorizada |     inicio_vigencia     |      fin_vigencia       
-----------------+----------------------------+--------------------+-------------------------+-------------------------
               1 | Constructora El Roble S.A. | Felipe Salazar     | 2026-01-01 08:00:00-06  | 2026-12-31 18:00:00-06
               2 | Carlos Hidalgo             | Santiago Víquez    | 2026-06-01 08:00:00-06  | 
(2 rows)
*/


-- -----------------------------------------------------------------------------
-- Consulta 3: Obtener las facultades otorgadas por cada autorización
-- Razón de ser: Verificar qué permisos específicos tiene asignada cada persona autorizada.
-- -----------------------------------------------------------------------------
SELECT 
    a.id_autorizacion,
    p_aut.nombre AS persona_autorizada,
    f.nombre AS facultad_otorgada
FROM autorizacion a
JOIN persona p_aut ON a.id_persona = p_aut.id_persona
JOIN autorizacion_facultad af ON a.id_autorizacion = af.id_autorizacion
JOIN facultad f ON af.id_facultad = f.id_facultad
ORDER BY a.id_autorizacion, f.id_facultad;

/* Resultado esperado Consulta 3:
 id_autorizacion | persona_autorizada |        facultad_otorgada        
-----------------+--------------------+---------------------------------
               1 | Felipe Salazar     | Firmar Contratos de Arrendamiento
               1 | Felipe Salazar     | Retirar Maquinaria y Equipo
               2 | Santiago Víquez    | Retirar Maquinaria y Equipo
(3 rows)
*/