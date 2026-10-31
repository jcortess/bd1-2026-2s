-- ==================================
-- Labotario 3 - Dilan Andrey Sibaja Ugalde
-- 01_esquema - definicion del esquema fisico (Postgress)
--proceso de negocio: registro de una finca por un productor
--version de PostgreSQL utilizada: 18
-- ==================================
-- Ejecutar sobre una base de datos vacia. No depende de objetos
-- creados manualmente; crea todo lo necesario desde cero.
BEGIN;
--Productores y metodos de contacto
CREATE TABLE productores (
    productor_id VARCHAR(14) PRIMARY KEY CHECK (productor_id ~ '^productor-[0-9]{4}$'),
    nombre VARCHAR (80) NOT NULL,
    fecha_de_afiliacion VARCHAR(10) NOT NULL CHECK (
        fecha_de_afiliacion ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
    ),
    condicion VARCHAR (8) NOT NULL CHECK (condicion IN ('activo', 'inactivo'))
);
CREATE TABLE telefonos_productor(
    productor_id VARCHAR(14) NOT NULL,
    telefono VARCHAR(9) NOT NULL UNIQUE CHECK (telefono ~ '^[0-9]{4}-[0-9]{4}$'),
    PRIMARY KEY (productor_id, telefono),
    FOREIGN KEY (productor_id) REFERENCES productores (productor_id)
);
CREATE TABLE correos_productor(
    productor_id VARCHAR(14) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL CHECK (
        correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
    PRIMARY KEY (productor_id, correo),
    FOREIGN KEY (productor_id) REFERENCES productores (productor_id)
);
--persona responsable y metodos de contacto
CREATE TABLE personas_responsables(
    responsable_id VARCHAR(16) PRIMARY KEY CHECK (responsable_id ~ '^responsable-[0-9]{4}$'),
    nombre VARCHAR (80) NOT NULL
);
CREATE TABLE telefonos_persona_responsable(
    responsable_id VARCHAR(16) NOT NULL,
    telefono VARCHAR(9) UNIQUE NOT NULL CHECK (telefono ~ '^[0-9]{4}-[0-9]{4}$'),
    PRIMARY KEY (responsable_id, telefono),
    FOREIGN KEY (responsable_id) REFERENCES personas_responsables (responsable_id)
);
CREATE TABLE correos_persona_responsable(
    correo VARCHAR(100) UNIQUE NOT NULL CHECK (
        correo ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
    responsable_id VARCHAR(16) NOT NULL,
    PRIMARY KEY (responsable_id, correo),
    FOREIGN KEY (responsable_id) REFERENCES personas_responsables (responsable_id)
);
--finca
CREATE TABLE fincas (
    finca_id VARCHAR(10) NOT NULL CHECK (finca_id ~ '^finca-[0-9]{4}$'),
    productor_id VARCHAR(14) NOT NULL,
    responsable_id VARCHAR(16) NULL,
    PRIMARY KEY (productor_id, finca_id),
    FOREIGN KEY (productor_id) REFERENCES productores (productor_id),
    FOREIGN KEY (responsable_id) REFERENCES personas_responsables (responsable_id),
    provincia VARCHAR(12) NOT NULL CHECK (
        provincia IN (
            'San Jose',
            'Alajuela',
            'Heredia',
            'Cartago',
            'Puntarenas',
            'Guanacaste',
            'Limon'
        )
    ),
    canton VARCHAR(20) NOT NULL CHECK (
        canton IN (
            --esta lista fue generada por claude (aviso escrito por Dilan Sibaja)
            -- San José (20)
            'San José',
            'Escazú',
            'Desamparados',
            'Puriscal',
            'Tarrazú',
            'Aserrí',
            'Mora',
            'Goicoechea',
            'Santa Ana',
            'Alajuelita',
            'Vázquez de Coronado',
            'Acosta',
            'Tibás',
            'Moravia',
            'Montes de Oca',
            'Turrubares',
            'Dota',
            'Curridabat',
            'Pérez Zeledón',
            'León Cortés Castro',
            -- Alajuela (16)
            'Alajuela',
            'San Ramón',
            'Grecia',
            'San Mateo',
            'Atenas',
            'Naranjo',
            'Palmares',
            'Poás',
            'Orotina',
            'San Carlos',
            'Zarcero',
            'Sarchí',
            'Upala',
            'Los Chiles',
            'Guatuso',
            'Río Cuarto',
            -- Cartago (8)
            'Cartago',
            'Paraíso',
            'La Unión',
            'Jiménez',
            'Turrialba',
            'Alvarado',
            'Oreamuno',
            'El Guarco',
            -- Heredia (10)
            'Heredia',
            'Barva',
            'Santo Domingo',
            'Santa Bárbara',
            'San Rafael',
            'San Isidro',
            'Belén',
            'Flores',
            'San Pablo',
            'Sarapiquí',
            -- Guanacaste (11)
            'Liberia',
            'Nicoya',
            'Santa Cruz',
            'Bagaces',
            'Carrillo',
            'Cañas',
            'Abangares',
            'Tilarán',
            'Nandayure',
            'La Cruz',
            'Hojancha',
            -- Puntarenas (13)
            'Puntarenas',
            'Esparza',
            'Buenos Aires',
            'Montes de Oro',
            'Osa',
            'Quepos',
            'Golfito',
            'Coto Brus',
            'Parrita',
            'Corredores',
            'Garabito',
            'Monteverde',
            'Puerto Jiménez',
            -- Limón (6)
            'Limón',
            'Pococí',
            'Siquirres',
            'Talamanca',
            'Matina',
            'Guácimo'
        )
    ),
    distrito VARCHAR(50) NOT NULL,
    indicacion_especifica VARCHAR(200) NOT NULL,
    area_aproximada VARCHAR(90) NOT NULL CHECK (area_aproximada ~ '^[0-9]+(\.[0-9]+)? m²$')
);
--historial y registros
CREATE TABLE historiales_responsable(
    historial_responsables_id VARCHAR(15) NOT NULL CHECK(
        historial_responsables_id ~ '^historialR-[0-9]{4}$'
    ),
    productor_id VARCHAR(14) NOT NULL,
    finca_id VARCHAR(10) NOT NULL,
    UNIQUE (productor_id, finca_id),
    FOREIGN KEY (productor_id, finca_id) REFERENCES fincas (productor_id, finca_id),
    PRIMARY KEY (
        historial_responsables_id,
        productor_id,
        finca_id
    )
);
--registro en historial
CREATE TABLE registro_en_historial (
    historial_responsables_id VARCHAR(15) NOT NULL,
    productor_id VARCHAR(14) NOT NULL,
    finca_id VARCHAR(10) NOT NULL,
    responsable_id VARCHAR(16) NOT NULL,
    FOREIGN KEY (
        historial_responsables_id,
        productor_id,
        finca_id
    ) REFERENCES historiales_responsable (
        historial_responsables_id,
        productor_id,
        finca_id
    ),
    FOREIGN KEY (responsable_id) REFERENCES personas_responsables (responsable_id),
    PRIMARY KEY (
        historial_responsables_id,
        productor_id,
        finca_id,
        responsable_id
    ),
    fecha_de_ingreso_como_responsable VARCHAR(10) NOT NULL CHECK (
        fecha_de_ingreso_como_responsable ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
    ),
    fecha_de_salida_como_responsable VARCHAR(10) NULL CHECK (
        fecha_de_salida_como_responsable ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
    )
);
COMMIT;