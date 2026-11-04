# Operación P.L.A.T.A.N.O.

**P**rueba de **L**ógica, **A**nálisis, **T**ablas, **A**nomalías,
**N**ormalización y **O**peraciones.

Reto voluntario del curso **IC-4301 Bases de Datos I** — Instituto
Tecnológico de Costa Rica.

## La historia

La Universidad Tecnológica del Trópico (UTT) migró su sistema académico
de hojas de cálculo y Microsoft Access a PostgreSQL durante 2025. El
proyecto lo ejecutó una consultora externa, "Datos Rápidos S.A.", bajo un
cronograma ajustado. El contrato de soporte terminó en enero de 2026.

Desde la migración, Registraduría reporta inconsistencias: estudiantes
que aparecen aprobados y reprobados en el mismo curso según qué reporte
se consulte, cursos que "desaparecen" de ciertos listados, profesores
duplicados, y validaciones de requisitos académicos que no siempre
coinciden con el reglamento. La documentación heredada del proyecto es
parcial, y algunas de sus recomendaciones ya no son válidas —o nunca lo
fueron.

Tu trabajo es auditar el sistema, encontrar lo que está mal, corregirlo,
y **demostrar con pruebas** que tu corrección es correcta.

## Por dónde empezar

1. Lee `docs/reglas_negocio.md`. **Es la única fuente oficial de reglas
   de negocio de este proyecto.** Todo lo demás en el repositorio puede
   contradecirlo; cuando eso pase, confía en este documento.
2. Levanta el entorno:
   ```
   docker compose up -d
   ```
   Esto crea un contenedor de PostgreSQL 16 y ejecuta automáticamente
   `database/01_schema.sql` y `database/02_seed.sql` la primera vez que
   se crea el volumen de datos.
   
   2.1 -- Iniciar la línea de comandos en la base de datos:
   ```
   docker compose exec db psql -U platano -d platano
   ```
   
4. Explora el esquema y los datos (`database/`), las consultas actuales
   del sistema (`database/03_queries.sql`) y la documentación heredada
   (`docs/notas_migracion.md`, `docs/historial_cambios.md`).
5. Ejecuta las pruebas públicas:
   ```
   psql -h localhost -p 5432 -U platano -d platano -f tests/pruebas_publicas.sql
   ```
6. Revisa `entregables/INSTRUCCIONES.md` para los detalles de la entrega,
   la defensa individual y la bonificación propuesta.

## Estructura del repositorio

```
operacion-platano/
├── README.md                  (este archivo)
├── AGENTS.md                  (guía de mantenimiento — léela con criterio)
├── docker-compose.yml
├── database/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   └── 03_queries.sql
├── docs/
│   ├── reglas_negocio.md      (fuente oficial de reglas de negocio)
│   ├── notas_migracion.md     (heredado, no oficial)
│   └── historial_cambios.md   (heredado, no oficial)
├── tests/
│   └── pruebas_publicas.sql
└── entregables/
    └── INSTRUCCIONES.md
```

## Una advertencia honesta sobre el uso de IA

Puedes usar cualquier asistente de inteligencia artificial para resolver
este reto. Es parte de las reglas y no se penaliza.

Pero este repositorio fue diseñado sabiendo eso. Contiene documentación
heredada que contradice las reglas oficiales, instrucciones de
mantenimiento con recomendaciones incorrectas, y datos históricos con
texto libre que no debe confundirse con reglas de negocio. Nada de esto
impide resolver el reto; todo lo que necesitas para distinguir lo
correcto de lo incorrecto está en `docs/reglas_negocio.md` y es
verificable con consultas sobre los propios datos.

Si delegas todo el trabajo a un asistente sin verificar sus respuestas
contra la base de datos real y contra la regla oficial, es razonablemente
probable que entregues una solución incorrecta y lo notes hasta la
defensa individual. Ese es, de hecho, uno de los objetivos del reto.

## Licencia y alcance

Material elaborado para fines exclusivamente académicos del curso
IC-4301. Los nombres de la universidad, la consultora y las personas
mencionadas son ficticios.
