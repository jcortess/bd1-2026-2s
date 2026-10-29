-- ==================================
-- Labotario 3 - Dilan Andrey Sibaja Ugalde
-- 05_pruebas - pruebas de la base de datos
--proceso de negocio: registro de una finca por un productor
--version de PostgreSQL utilizada: 18
-- ==================================
-- se usan savepoints para deshacer las pruebas fallidas
-- se prueba que la unicidad funcione correctamente, que no se acepten datos con formato equivocado, y que los datos no salgan de su limite
BEGIN;
-- ==========================
-- prueba 1 (id:p01)
-- se prueba el registro de un nuevo productor, completamente diferente al resto, y que puede existir sin correo ni telefono
-- sentencia ejecutada: Insert de un nuevo productor con id unico,nombre, sin telefono ni correo
-- resultado esperado: se podra insertar al nuevo productor sin problema, pues no viola ninguna regla
-- resultado observado: se ejecuta con normalidad
SAVEPOINT point01;
INSERT INTO productores (
        productor_id,
        nombre,
        fecha_de_afiliacion,
        condicion
    )
VALUES (
        'productor-0003',
        'Ricardo Rojas Rodriguez',
        '10/27/2026',
        'activo'
    );
RELEASE SAVEPOINT point01;
-- ==========================
-- prueba 2 (id:p02)
-- se prueba el registro de una nueva finca, que viola la regla de elegir un canton de costa rica (muestra un nombre no valorado)
-- sentencia ejecutada: Insert de una nueva finca asociada al productor-0003, cuyo canton pone "Rojolandia"
-- resultado esperado: se espera que se rechace el insert pues viola el check de canton
-- resultado observado: error por violar el check
SAVEPOINT point02;
INSERT INTO fincas (
        productor_id,
        finca_id,
        responsable_id,
        provincia,
        canton,
        distrito,
        indicacion_especifica,
        area_aproximada
    )
VALUES (
        'productor-0003',
        'finca-0001',
        NULL,
        'Rojolandia',
        'San Carlos',
        'Quesada',
        '50 metros norte del teatro',
        '800 m²'
    );
ROLLBACK TO SAVEPOINT point02;
-- ==========================
-- prueba 3 (id:p03)
-- se prueba el registro de la misma finca, pero ahora el canton corresponde a Alajuela
-- sentencia ejecutada: Insert de una nueva finca asociada al productor-0003, cuyo canton ahora es valido
-- resultado esperado: se espera que se agregue sin problema, pues ya no incumple ninguna regla
-- resultado observado: se ejecuta con normalidad
SAVEPOINT point03;
INSERT INTO fincas (
        productor_id,
        finca_id,
        responsable_id,
        provincia,
        canton,
        distrito,
        indicacion_especifica,
        area_aproximada
    )
VALUES (
        'productor-0003',
        'finca-0001',
        NULL,
        'Alajuela',
        'San Carlos',
        'Quesada',
        '50 metros norte del teatro',
        '800 m²'
    );
RELEASE SAVEPOINT point03;
-- ==========================
-- prueba 4 (id:p04)
-- se prueba el registro de una persona_responsable sin nombre
-- sentencia ejecutada: Insert de una nueva persona responsable que viola el NOT NULL del nombre
-- resultado esperado: se espera que lo rechace, pues viola el NOT NULL del nombre
-- resultado observado: error por violar NOT NULL
SAVEPOINT point04;
INSERT INTO personas_responsables (responsable_id, nombre)
VALUES ('responsable-0001', NULL);
ROLLBACK TO SAVEPOINT point04;
-- ==========================
-- prueba 5 (id:p05)
-- se prueba el registro de un correo repetido en responsable-0002 de responsable-0001
-- sentencia ejecutada: Insert de un nuevo correo que viola la unicidad del correo
-- resultado esperado: se espera que lo rechace, pues  viola la unicidad del correo
-- resultado observado: error por violar UNIQUE
SAVEPOINT point05;
INSERT INTO correos_persona_responsable (responsable_id, correo)
VALUES ('responsable-0002', 'maria.fernandez@gmail.com');
ROLLBACK TO SAVEPOINT point05;
-- ==========================
-- prueba 6 (id:p06)
-- se prueba el registro de un correo unico en responsable-0002
-- sentencia ejecutada: Insert de un nuevo correo valido
-- resultado esperado: se espera que no haya problema, pues no viola la unicidad de los correos
-- resultado observado: se ejecuta con normalidad
SAVEPOINT point06;
INSERT INTO correos_persona_responsable (responsable_id, correo)
VALUES ('responsable-0002', 'vargasVargas@hotmail.com');
RELEASE SAVEPOINT point06;