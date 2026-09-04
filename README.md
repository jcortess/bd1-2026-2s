# IC-4301 · Bases de Datos I

Repositorio de materiales, actividades y proyectos del curso **IC-4301 Bases de Datos I**, correspondiente al **II semestre de 2026**.

El curso estudia los fundamentos del diseño y uso de bases de datos. Los conceptos se presentan de forma independiente del producto; **PostgreSQL** se utiliza como sistema gestor de referencia para ejemplos, laboratorios y demostraciones prácticas.

## Objetivos del repositorio

Este repositorio permite:

- Centralizar las presentaciones y recursos de cada semana.
- Conservar ejemplos y actividades realizadas durante las clases.
- Publicar las instrucciones generales de los proyectos.
- Mantener separados los enunciados asignados a cada grupo.
- Facilitar el acceso a material complementario y referencias.
- Registrar cambios y correcciones de manera transparente.

## Contenidos principales del curso

Durante el curso se abordarán progresivamente temas como:

- Bases de datos, sistemas gestores y sistemas de bases de datos.
- Modelos de datos, esquemas e instancias.
- Arquitectura y funciones de un SGBD.
- Análisis de necesidades de información y reglas de negocio.
- Modelado conceptual mediante diagramas entidad-relación.
- Notaciones de Chen y crow's foot.
- Transformación del modelo conceptual al modelo relacional.
- Relaciones, atributos, dominios y restricciones.
- Claves primarias, candidatas y foráneas.
- Dependencias funcionales y normalización.
- Lenguaje SQL.
- Integridad, transacciones, concurrencia y seguridad.
- Introducción al diseño físico y la optimización.

La profundidad y el orden de los temas se ajustarán al programa oficial y al avance del grupo.

## Organización propuesta

```text
.
├── README.md
├── clases/
│   ├── semana-01/
│   ├── semana-02/
│   ├── semana-03/
│   └── ...
├── actividades/
├── ejemplos/
├── laboratorios/
├── proyecto-01/
│   ├── instrucciones/
│   └── casos/
│       ├── grupo-01-clinica/
│       ├── grupo-02-taller/
│       ├── grupo-03-matricula/
│       └── ...
├── proyecto-02/
├── recursos/
└── bibliografia/
    └── README.md
```

La estructura puede evolucionar durante el semestre. Cada carpeta semanal podrá contener la presentación, ejemplos, actividades y archivos auxiliares utilizados en clase.

## Presentaciones

Las presentaciones del curso se desarrollan principalmente con [Slidev](https://sli.dev/), lo que permite mantener el contenido en Markdown e incorporar diagramas, fragmentos de código y actividades.

Cuando una semana contenga su propio proyecto de Slidev, deben seguirse las instrucciones incluidas en esa carpeta. De forma general, se necesitarán **Node.js** y un administrador de paquetes compatible con el proyecto.

Ejemplo de ejecución:

```bash
npm install
npm run dev
```

Los comandos concretos pueden variar según la configuración de cada presentación.

## Entorno práctico

Para las demostraciones y laboratorios se utilizarán principalmente:

- PostgreSQL.
- Docker o un entorno local equivalente.
- Una terminal con acceso a `psql`.
- Un editor de texto o entorno de desarrollo.

PostgreSQL funciona como herramienta práctica del curso, pero los conceptos de modelado y diseño no deben justificarse únicamente por el comportamiento particular de este producto.

## Uso de herramientas de inteligencia artificial

Las herramientas de inteligencia artificial pueden utilizarse como apoyo cuando la actividad lo permita. Su uso no sustituye el análisis ni constituye una justificación técnica.

Quien incorpore una propuesta generada por una herramienta es responsable de:

- Verificar su coherencia con el caso.
- Identificar errores o supuestos no respaldados.
- Documentar los prompts relevantes cuando sea solicitado.
- Explicar y modificar el resultado durante una revisión o defensa.
- Distinguir claramente entre una sugerencia de la herramienta y una decisión propia.

## Indicaciones para estudiantes

- Consulte siempre las instrucciones oficiales publicadas para cada actividad.
- No asuma que todos los detalles del negocio están expresados explícitamente.
- Documente las ambigüedades antes de establecer supuestos.
- Mantenga coherencia entre las reglas, diagramas, relaciones y diccionario de datos.
- No copie el modelo de otro caso: cada dominio contiene restricciones diferentes.
- Durante una defensa, cualquier integrante puede ser consultado sobre cualquier parte del trabajo.

Las fechas de entrega, medios de envío, ponderaciones y cambios oficiales se comunicarán mediante los canales institucionales del curso. Ante una diferencia, la comunicación oficial más reciente tendrá prioridad sobre este repositorio.

## Bibliografía

La bibliografía oficial y las referencias complementarias se identificarán en `bibliografia/README.md` o en el material de cada semana.

> Los libros, artículos y otros materiales protegidos por derechos de autor no deben incorporarse al repositorio salvo que su licencia permita expresamente su redistribución. El repositorio debe conservar únicamente referencias bibliográficas, enlaces autorizados y materiales de elaboración propia.

## Uso del material

Este repositorio tiene fines académicos. Los enunciados, presentaciones, actividades y soluciones de referencia elaborados para el curso no deben redistribuirse ni utilizarse como sustituto de la participación en las clases sin autorización.

Los componentes de terceros conservan sus respectivas licencias y condiciones de uso.

## Docente

**Jonatan Cortés**  
IC-4301 · Bases de Datos I  
II semestre de 2026

---

> Este repositorio se encuentra en construcción y será actualizado conforme avance el curso.
