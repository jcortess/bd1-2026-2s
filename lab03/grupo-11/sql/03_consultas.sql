-- ==================================
-- Labotario 3 - Dilan Andrey Sibaja Ugalde
-- 03_consultas - consultas entre tablas
--proceso de negocio: registro de una finca por un productor
--version de PostgreSQL utilizada: 18
-- ==================================
--=======================
--Consulta 1 (c01)
--permite saber responsables de una finca durante un periodo
--devuelve los responsables durante el periodo 01/01/2022 a 31/12/2023
--combina 2 tablas
--========================
SELECT r.responsable_id,
      r.nombre,
      reg.fecha_de_ingreso_como_responsable,
      reg.fecha_de_salida_como_responsable
FROM registro_en_historial reg
      JOIN personas_responsables r ON r.responsable_id = reg.responsable_id
WHERE reg.productor_id = 'productor-0001'
      AND reg.finca_id = 'finca-0001'
      AND TO_DATE(
            reg.fecha_de_ingreso_como_responsable,
            'DD/MM/YYYY'
      ) <= TO_DATE('31/12/2023', 'DD/MM/YYYY')
      AND (
            reg.fecha_de_salida_como_responsable IS NULL
            OR TO_DATE(
                  reg.fecha_de_salida_como_responsable,
                  'DD/MM/YYYY'
            ) >= TO_DATE('01/01/2022', 'DD/MM/YYYY')
      )
ORDER BY TO_DATE(
            reg.fecha_de_ingreso_como_responsable,
            'DD/MM/YYYY'
      );
--se espera que esto devuelva al responsable: (responsable_0001,María Fernández Solís,15/03/2021,NULL), porque sigue activa en la finca y fue responsable durante ese periodo.
--=======================
--Consulta 2 (c02)
--permite conocer todas las fincas que pertenecen a un productor dado
--========================
SELECT finca_id,
      responsable_id,
      provincia,
      canton,
      distrito,
      indicacion_especifica,
      area_aproximada
FROM fincas
WHERE productor_id = 'productor-0001'
ORDER BY finca_id;
--se espera que esto devuelva las fincas: (productor-0001,finca-0001) y (productor-0001,finca-0002) en ese orden
--=======================
--Consulta 3 (c03)
--permite conocer de cuantas fincas a sido responsable una persona dada
--========================
SELECT r.responsable_id,
      r.nombre,
      COUNT(DISTINCT (reg.productor_id, reg.finca_id)) AS total_fincas
FROM personas_responsables r
      LEFT JOIN registro_en_historial reg ON reg.responsable_id = r.responsable_id
WHERE r.responsable_id = 'responsable-0001'
GROUP BY r.responsable_id,
      r.nombre;
--se espera que devuelva: (responsable-0001,María Fernández Solís,2)
--consulta temporal para la prueba de productores
SELECT *
FROM productores