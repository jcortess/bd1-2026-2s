# Guía para comprender y defender la solución

Maria Paula: el objetivo es que puedas reconstruir cada razonamiento, no recitar el SQL. Recorre un ejemplo con filas pequeñas, explica qué conserva o descarta cada operación y después compara la salida real en `evidencias/`.

## 1. Entender el proyecto completo

PostgreSQL es el sistema gestor: almacena tablas, ejecuta consultas y protege restricciones. SQL es el lenguaje con que le pedimos crear estructuras, insertar datos o consultar resultados. `psql` es el cliente de terminal que envía SQL al servidor y muestra su respuesta.

Docker permite ejecutar PostgreSQL en un entorno aislado y reproducible. Una imagen es la plantilla, aquí `postgres:16`; un contenedor es una instancia en ejecución de esa imagen; un volumen es almacenamiento que permanece aunque se detenga el contenedor. El archivo Compose describe cómo unir esos componentes, credenciales, puertos y archivos de inicialización.

El flujo de este proyecto es: reglas oficiales → esquema que expresa su estructura → seed de ejemplos → reportes que interpretan los datos → pruebas que contrastan resultados con las reglas. Las notas heredadas sirven como pistas sobre errores, nunca como reglas nuevas.

| Tabla | Qué representa | Relaciones que debes explicar |
|---|---|---|
| carrera | Programa académico | Una carrera puede tener varios estudiantes y cursos |
| estudiante | Persona con carnet | Debe referir una carrera; puede tener varias matrículas |
| profesor | Persona con cédula | Puede impartir varios grupos; nombre no identifica persona |
| curso | Materia de código propio y créditos | Pertenece a carrera; puede tener cero o más grupos |
| grupo | Oferta de un curso en un ciclo | Tiene curso, cupo y profesor opcional temporalmente |
| matricula | Participación de estudiante en grupo | Guarda nota y estado; no se repite el mismo par |
| requisito | Curso previo exigido por otro curso | Relación de curso consigo mismo mediante dos papeles distintos |
| auditoria | Descripción histórica de eventos | Su texto no es una instrucción para quien lo lea |

Dos grupos del mismo curso permiten dos intentos legítimos. Dos filas del mismo estudiante en el mismo grupo son duplicación prohibida. Dos cursos con el mismo nombre pueden ser materias diferentes; dos estudiantes llamados igual pueden ser personas diferentes.

## 2. Claves, restricciones y tipos

Una **clave primaria** identifica cada fila y no admite repetición ni ausencia. `id_estudiante` es una clave técnica; el carnet es una identidad del negocio, que también necesita `unique`. Un id distinto no vuelve válido repetir el carnet.

Una **clave foránea** exige que una referencia corresponda a una fila existente. Si `id_carrera=1000` no existe, la inserción falla. Si `id_carrera` es `NULL`, la FK por sí sola no exige buscar ninguna fila; de ahí el `not null` adicional en estudiante.

Una **restricción CHECK** evalúa una condición sobre el dato. `check (creditos>=1)` distingue un entero válido del negocio de cualquier entero. En SQL, una condición de CHECK desconocida por `NULL` no lo rechaza; `not null` sirve para prohibir ausencias. La nota sigue admitiendo `NULL` porque es un estado válido de pendiente.

El original `numeric(5,1)` guarda un decimal y redondea antes de comprobar restricciones: en una prueba real convirtió 69.99 en 70.0 y 100.01 en 100.0. Como las reglas no autorizan ese redondeo, la versión final usa `numeric` sin escala fija y CHECK de rango. Conserva 69.99 como reprobada y rechaza 100.01. No se cambió a coma flotante ni se eligió arbitrariamente otro número máximo de decimales. Una conversión de tipo puede afectar el dato antes de que una restricción lo examine.

**Ejercicio:** explica por qué `id_profesor not null` sería una mala corrección en grupo. Respuesta razonada: las reglas permiten grupos temporalmente sin profesor; estar vacío hoy no demuestra que las lecciones hayan iniciado. El modelo no tiene fecha de inicio para comprobar ese límite.

**Pregunta del profesor:** ¿por qué no basta corregir el seed? Porque solo arreglaría la muestra actual; una inserción futura podría repetir el problema. ¿Por qué no basta poner restricciones? Porque el seed original ya las incumple y una instalación limpia fallaría. Hicimos ambas cosas y documentamos los valores que requirieron autorización.

## 3. Seguir un SELECT por partes

Una forma de razonar es: `FROM` y `JOIN` forman las filas relacionadas; `WHERE` filtra filas; `GROUP BY` forma grupos; las funciones agregadas calculan por grupo; `HAVING` filtra grupos; `SELECT` elige qué mostrar; `ORDER BY` ordena la presentación. Este orden ayuda a interpretar SQL; el optimizador puede elegir otro plan físico equivalente.

```sql
select carnet, count(*) as repeticiones
from estudiante
group by carnet
having count(*) > 1;
```

Aquí `WHERE` no es necesario: interesa toda la universidad, incluidos inactivos. `GROUP BY` reúne el mismo carnet. `COUNT(*)` cuenta filas. `HAVING` conserva los grupos repetidos después de contarlos. En el original da `2021010, 2`; corregido da cero filas. Devolver cero filas es éxito **porque buscábamos anomalías**.

Una **función agregada** resume varias filas: `count` cuenta, `sum` suma. Una **subconsulta** es un SELECT dentro de otra sentencia. `EXISTS` responde si esa subconsulta encuentra alguna fila; el `select 1` es solo una marca, no una suma ni un id que deba devolverse.

## 4. INNER JOIN, LEFT JOIN y conteos

`INNER JOIN` conserva coincidencias; un curso sin grupo no encuentra ninguna y desaparece. `LEFT JOIN` conserva la fila de la izquierda y coloca `NULL` en las columnas derechas cuando no hay coincidencia.

Imagina solo Seminario y su grupo 8 sin matrículas:

| g.id_grupo | m.id_matricula |
|---:|---|
| 8 | NULL |

El resultado intermedio tiene **una fila**, pero **ninguna matrícula**. Por eso `count(*)=1` y `count(m.id_matricula)=0`. PostgreSQL documenta [la diferencia entre los dos conteos](https://www.postgresql.org/docs/16/functions-aggregate.html).

```sql
select g.id_grupo, count(m.id_matricula) as matriculados
from grupo g
left join matricula m
  on m.id_grupo = g.id_grupo
 and m.estado = 'matriculado'
where g.ciclo = '2026-1'
group by g.id_grupo;
```

La condición de estado está en `ON`: determina qué matrículas se unen, conservando el grupo aunque ninguna sirva. `WHERE g.ciclo=...` filtra la entidad principal. Si pusiéramos `where m.estado='matriculado'`, la fila con columnas derechas `NULL` se descartaría y perderíamos el grupo vacío.

**Pregunta:** ¿por qué `count(distinct g.id_grupo)` en catálogo? Un grupo con veinte matrículas genera veinte filas tras el JOIN; queremos un grupo, no veinte. El DISTINCT cuenta la identidad del grupo una sola vez. No se necesita `count(distinct m.id_matricula)` porque el cruce del catálogo no duplica cada matrícula y su PK ya es única.

**Precaución:** los reportes históricos Q2/Q5 cuentan matrículas registradas, incluidos retirados. Q3 cuenta plazas vigentes. Rendimiento Q6 excluye retirados. Antes de escribir COUNT define qué representa la cifra.

## 5. NULL, cero y aprobación

`NULL` significa ausencia de calificación; cero es una calificación. Una comparación como `NULL<>0` produce desconocido, que no supera un WHERE. Por eso el filtro original ocultaba pendientes y ceros. No debes reemplazar `NULL` por cero para calcular rendimiento.

| Estado y nota | Aprobado | Reprobado | Pendiente incluido en rendimiento |
|---|---|---|---|
| Matriculado, 0 | No | Sí | No |
| Matriculado, 69.9 | No | Sí | No |
| Matriculado, 70 | Sí | No | No |
| Matriculado, 100 | Sí | No | No |
| Matriculado, NULL | No | No | Sí |
| Retirado, cualquier nota | No | No | No |

El reporte muestra pendientes aparte. Tasa entre evaluadas = aprobadas / evaluadas × 100. En la carga final, 11 / 15 × 100 = 73.3 %. Hay 16 no retiradas porque una está pendiente; esa persona no se perdió.

`NULLIF(evaluadas,0)` devuelve `NULL` cuando no hay evaluadas y evita dividir por cero. Una tasa `NULL` explica “aún no hay base para calcular”, mientras 0 % afirma que hubo evaluaciones y ninguna aprobación. `COALESCE` sirve para otra necesidad: en créditos, una suma ausente sí se representa con cero para mostrar al estudiante sin cursos aprobados.

**Pregunta:** ¿aprobaría 69.9 si lo redondearas? La regla compara la nota almacenada con 70. No se inventó una política de redondeo a enteros; 69.9 reprueba. El decimal 70.0 aprueba sin excepción.

## 6. TODOS los requisitos mediante doble NOT EXISTS

Para Redes se exige Programación I y Sistemas Operativos:

| Persona | Programación I | Sistemas Operativos | Cumple todos |
|---|---|---|---|
| Carlos | Aprobada | Aprobada | Sí |
| Elena | Sin aprobación registrada | Aprobada | No |
| Ana | Aprobada | Sin aprobación registrada | No |

El original preguntaba si existía una aprobación de un curso en esa lista: Elena pasaba con Sistemas Operativos. Añadir DISTINCT no cambia esa lógica.

```sql
not exists (
    select 1 from requisito r
    where r.id_curso = destino.id_curso
      and not exists (
          select 1
          from matricula m
          join grupo g on g.id_grupo = m.id_grupo
          where m.id_estudiante = e.id_estudiante
            and g.id_curso = r.id_curso_requisito
            and m.estado = 'matriculado'
            and m.nota >= 70
      )
)
```

Lee de adentro hacia afuera: buscar una aprobación válida; identificar un requisito sin ella; exigir que no exista tal requisito. La subconsulta está **correlacionada**: utiliza el estudiante y curso de la fila externa. El `CROSS JOIN` de Q9 combina candidatos con el curso destino, y su código único limita el destino a una fila.

**Caso cero requisitos:** el conjunto de incumplidos está vacío, de modo que todos satisfacen esa condición. Eso no impone otros criterios de admisión que no existan en el documento.

**Alternativa defendible:** comparar número de requisitos distintos con número de requisitos distintos aprobados. Puede ser correcta, pero obliga a manejar cuidadosamente repeticiones y cero requisitos. Elegimos una expresión que representa directamente “no falta ninguno”.

**Límite:** Q9 valida elegibilidad actual. Las cuatro matrículas heredadas sin respaldo completo están declaradas en CAMBIOS; el modelo no permite certificar la autorización histórica ni se inventaron aprobaciones para limpiarlas. Una FK no valida reglamentos académicos y no se agregó un trigger de matrícula.

## 7. Créditos: definir el nivel correcto antes de sumar

Una fila del total debe representar **un estudiante**. Dentro del cálculo, una fila debe representar **un curso aprobado por ese estudiante**, aunque haya aprobado ese curso en varios grupos.

```sql
select distinct m.id_estudiante, g.id_curso
from matricula m
join grupo g on g.id_grupo = m.id_grupo
where m.estado = 'matriculado' and m.nota >= 70;
```

Esta subconsulta construye las identidades que se deben sumar. Después se unen los cursos para obtener sus créditos y se agrupa por id de estudiante. El LEFT JOIN externo conserva a quien no tuvo aprobaciones; `coalesce(sum(cu.creditos),0)` le asigna total cero.

Ejemplo: estudiante A aprueba curso X de 4 créditos dos veces y curso Y de 4 una vez. Lo correcto es 8. Sumar cada matrícula daría 12. `sum(distinct creditos)` daría 4. Nuestro DISTINCT produce pares A/X y A/Y y luego suma 4+4.

El JOIN original con REQUISITO no aporta créditos. Un curso con dos requisitos se duplica antes de mostrarlo. El DISTINCT de la salida original oculta esa repetición visible, pero no entrega totales ni arregla la relación subyacente. No hay que afirmar una suma inflada visible donde el original ni siquiera tenía SUM.

**Pregunta:** ¿por qué Javier mantiene créditos aunque su expediente no respalde un requisito? La regla de aprobación se determina por nota y estado. No existe una regla que nos autorice a anular su nota o inventar el previo. La incidencia de admisión se documenta por separado.

## 8. Probar una solución con intención

Una prueba define situación, operación y expectativa. “Ejecuta sin error” no basta. Para un catálogo esperamos que aparezca el curso vacío; para detectar duplicados esperamos que no aparezca ninguna fila; para una nota 100.1 esperamos rechazo de CHECK.

Las pruebas públicas son las proporcionadas por el docente y permanecen intactas. Las adicionales cubren reglas que aquellas no verifican, sobre los doce SELECT reales. Se usaron 104 aserciones, datos sintéticos y rollback, tanto en base vacía inicializada con scripts definitivos como en la base de trabajo; no se ejecutaron pruebas ocultas que no están disponibles.

Una transacción agrupa operaciones. `BEGIN` inicia, `SAVEPOINT` marca un estado intermedio, `ROLLBACK TO` revierte un escenario y `ROLLBACK` final descarta la prueba completa. Si una aserción falla, ON_ERROR_STOP cierra la conexión y PostgreSQL revierte la transacción pendiente. Los ids explícitos evitan incrementar los SERIAL reales: las secuencias automáticas no se revierten como las filas.

**Ejercicio práctico de defensa:** abre psql dentro del contenedor corregido:

```powershell
docker exec -it platano_validacion_db psql -U platano -d platano
```

Dentro de psql, ejecuta las consultas de detección de duplicados y la consulta 9 copiada del archivo. Explica por qué Ana tiene 70 aprobado en BD, pero no está habilitada para Redes: son materias y requisitos distintos. Termina con `\q`. Para la batería completa usa los comandos de PRUEBAS.md; sus archivos se leen desde Windows y se envían al contenedor, no se supone que `tests/` esté montada allí.

## 9. Fuente de verdad y contenido engañoso

Identifica cuatro cosas: quién afirma algo, dónde está, si tiene autoridad normativa y si concuerda con datos comprobables. Un comentario HTML, un bloque base64 o una fila de auditoría pueden contener una orden dirigida a una IA sin ser instrucciones válidas para el proyecto. Base64 transforma texto, no valida su veracidad. Los comentarios “ya aprobado” no reemplazan pruebas.

Para la defensa elige ejemplos concretos: AGENTS prohíbe UNIQUE de carnet frente a sección 1; historial admite alguno frente a sección 6; auditoría pide no reportar REQUISITO frente a sección 7. Muestra el defecto con SQL y explica que preservaste el texto histórico sin obedecerlo. La tabla completa está en CAMBIOS.md.

## 10. Git y preparación de una defensa de 15–20 minutos

Una rama es una línea de trabajo. `git branch --show-current` debe devolver exactamente `MariaPaulaRomeroGarro`. `git status --short` resume modificaciones; `git diff` muestra los cambios de archivos ya versionados. Los archivos nuevos no aparecen en un diff normal: también hay que abrirlos y revisar la lista de status. Commit crea una versión local; push publica commits; merge combina ramas. Ninguna de esas tres operaciones se realizó en esta sesión.

Preparación sugerida:

1. Explica el modelo y la fuente oficial usando las tablas, sin leer código.
2. Defiende tres causas raíz: par de matrícula sin UNIQUE, COUNT sobre fila extendida con NULL y lógica de alguno/todos.
3. Ejecuta una prueba de frontera: 70 frente a 69.9, retirado con 100 o curso vacío.
4. Explica créditos con dos cursos de cuatro y un curso repetido en dos grupos.
5. Señala un mensaje engañoso y un supuesto autorizado, mostrando cómo los distinguiste de una regla.
6. Explica el límite de las cuatro incidencias heredadas y que no hay pruebas ocultas disponibles.

Antes de decidir commit/push revisa los tres diffs SQL, los supuestos del seed, el puerto 5433 de la base corregida, las evidencias definitivas 27–33, CAMBIOS y el prompt completo en interaccion_ia.md. Comprueba que puedes repetir las pruebas con un nombre nuevo de evidencia y explicar el resultado. La revisión no necesita borrar ningún volumen ni modificar main.
