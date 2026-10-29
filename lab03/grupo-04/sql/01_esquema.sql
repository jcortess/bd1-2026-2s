-- IC-4301 | Laboratorio 3 | Grupo 04 | Alquileres El Roble
-- Objetivo: PostgreSQL 17, base vacia, usuario propietario sin superusuario.
-- Fuente: documentacion/diseno-fisico-y-trazabilidad.md, DF-01 a DF-04.
-- Una ejecucion por base limpia. No elimina ni reutiliza tablas existentes.
-- Ejecutar con detencion ante errores; instrucciones en ejecucion-esquema.md.

BEGIN;

CREATE TABLE public.persona (
    id_persona bigint NOT NULL,
    tipo_identificacion text NOT NULL,
    identificacion text NOT NULL,
    nombre text NOT NULL,
    CONSTRAINT pk_persona PRIMARY KEY (id_persona),
    CONSTRAINT uq_persona_documento UNIQUE (tipo_identificacion, identificacion),
    CONSTRAINT ck_persona_tipo_no_vacio CHECK (btrim(tipo_identificacion) <> ''),
    CONSTRAINT ck_persona_identificacion_no_vacia CHECK (btrim(identificacion) <> ''),
    CONSTRAINT ck_persona_nombre_no_vacio CHECK (btrim(nombre) <> '')
);

CREATE TABLE public.cliente (
    id_cliente bigint NOT NULL,
    tipo_cliente text NOT NULL,
    id_persona bigint,
    identificacion_organizacion text,
    razon_social text,
    direccion text NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_persona UNIQUE (id_persona),
    CONSTRAINT uq_cliente_identificacion_org UNIQUE (identificacion_organizacion),
    CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona)
        REFERENCES public.persona (id_persona)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_cliente_tipo CHECK (tipo_cliente IN ('Física', 'Organización')),
    CONSTRAINT ck_cliente_datos_por_tipo CHECK (
        (tipo_cliente = 'Física'
            AND id_persona IS NOT NULL
            AND identificacion_organizacion IS NULL
            AND razon_social IS NULL)
        OR
        (tipo_cliente = 'Organización'
            AND id_persona IS NULL
            AND identificacion_organizacion IS NOT NULL
            AND razon_social IS NOT NULL)
    ),
    CONSTRAINT ck_cliente_identificacion_org_no_vacia CHECK (
        identificacion_organizacion IS NULL OR btrim(identificacion_organizacion) <> ''
    ),
    CONSTRAINT ck_cliente_razon_social_no_vacia CHECK (
        razon_social IS NULL OR btrim(razon_social) <> ''
    ),
    CONSTRAINT ck_cliente_direccion_no_vacia CHECK (btrim(direccion) <> '')
);

CREATE TABLE public.facultad (
    id_facultad bigint NOT NULL,
    nombre text NOT NULL,
    CONSTRAINT pk_facultad PRIMARY KEY (id_facultad),
    CONSTRAINT uq_facultad_nombre UNIQUE (nombre),
    CONSTRAINT ck_facultad_nombre_no_vacio CHECK (btrim(nombre) <> '')
);

CREATE TABLE public.autorizacion (
    id_autorizacion bigint NOT NULL,
    id_cliente bigint NOT NULL,
    id_persona bigint NOT NULL,
    inicio_vigencia timestamp with time zone NOT NULL,
    fin_vigencia timestamp with time zone,
    CONSTRAINT pk_autorizacion PRIMARY KEY (id_autorizacion),
    CONSTRAINT fk_autorizacion_cliente FOREIGN KEY (id_cliente)
        REFERENCES public.cliente (id_cliente)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_autorizacion_persona FOREIGN KEY (id_persona)
        REFERENCES public.persona (id_persona)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_autorizacion_periodo CHECK (
        fin_vigencia IS NULL OR fin_vigencia > inicio_vigencia
    )
);

CREATE TABLE public.autorizacion_facultad (
    id_autorizacion bigint NOT NULL,
    id_facultad bigint NOT NULL,
    CONSTRAINT pk_autorizacion_facultad PRIMARY KEY (id_autorizacion, id_facultad),
    CONSTRAINT fk_aut_fac_autorizacion FOREIGN KEY (id_autorizacion)
        REFERENCES public.autorizacion (id_autorizacion)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_aut_fac_facultad FOREIGN KEY (id_facultad)
        REFERENCES public.facultad (id_facultad)
        ON DELETE RESTRICT ON UPDATE RESTRICT
);

COMMENT ON TABLE public.persona IS
    'Identidad de personas reutilizada por clientes fisicos y autorizaciones.';
COMMENT ON TABLE public.cliente IS
    'Cliente fisico u organizacion; conserva campos condicionales de AS-01.';
COMMENT ON TABLE public.facultad IS
    'Catalogo administrable de acciones concedibles, conforme a AS-03.';
COMMENT ON TABLE public.autorizacion IS
    'Otorgamiento con vigencia. Tipo organizacion y minimo de facultades requieren validacion procedimental pendiente.';
COMMENT ON TABLE public.autorizacion_facultad IS
    'Facultades de un otorgamiento; la pareja es unica, no cada componente.';
COMMENT ON COLUMN public.autorizacion.fin_vigencia IS
    'Limite excluido segun DL-01; NULL significa sin fin establecido.';

-- No se agregan DEFAULT, autoincrementos, indices adicionales ni triggers.
-- No se impone UNIQUE(id_cliente, id_persona) ni se prohiben traslapes.
-- La FK no valida cliente organizacion ni exige filas hijas: limite DL-05.
-- Las funciones futuras aplicaran inicio incluido y fin excluido al consultar.

COMMIT;
