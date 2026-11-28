
# Evidencia de instalación e integración — Jean Carlos

## Entorno

- PostgreSQL 16.
- Cliente psql 16.16.
- Sistema operativo Windows.
- Codificación de la base: UTF8.
- Esquema: huellas.

## Bases de validación

- huellas_g05_jeank_validacion.
- huellas_g05_final_pruebas.
- huellas_g05_secuencial.

Se utilizaron bases nuevas destinadas a pruebas,
sin eliminar bases preexistentes.

## Archivos de instalación

- `sql/09_instalar_bloque_paula.sql`.
- `sql/10_jeank_esquema.sql`.
- `sql/11_jeank_operaciones.sql`.
- `sql/12_jeank_datos.sql`.
- `sql/13_jeank_consultas.sql`.
- `sql/14_instalar_bloque_jeank.sql`.
- `sql/15_instalar_proyecto_completo.sql`.

## Reproducción

Desde PowerShell, ubicado en el directorio del grupo:

```powershell
$pg = "C:\Program Files\PostgreSQL\16\bin"
$base = "huellas_g05_validacion_nueva"

& "$pg\createdb.exe" -U postgres -T template0 -E UTF8 $base

& "$pg\psql.exe" -X -v ON_ERROR_STOP=1 -P pager=off -U postgres -d $base -f sql/15_instalar_proyecto_completo.sql
```

Debe utilizarse un nombre de base que no exista.

## Resultado comprobado

La instalación completa terminó correctamente.

La comprobación incorporada al instalador confirmó
la existencia de 28 tablas en el esquema huellas.

| Bloque | Relaciones |
|---|---|
| Jason | 9 |
| Paula | 10 |
| Jean Carlos | 9 |
| Total | 28 |

La relación adicional corresponde a
COMPATIBILIDAD_ANIMAL_HOGAR.

## Incidencias corregidas

### Permisos en comprobación diferida

Durante una formalización inicial, el COMMIT fue
rechazado por falta de permisos para ejecutar una
función interna de comprobación de adopciones.

La operación fallida no dejó una adopción parcial.

Se corrigió la función `_adopcion_diferida_jeank`
mediante SECURITY DEFINER y un search_path controlado.

La instalación posterior en una base nueva confirmó:

- prosecdef = true.
- search_path = pg_catalog, huellas, pg_temp.

La formalización posterior bajo el rol operativo
terminó correctamente.

### Consulta de control de adopciones

Se corrigió la referencia a la fecha de finalización
de estancia, utilizando `fecha_fin_real`.

La vista `v_control_adopciones_jeank` quedó operativa
y permitió comprobar los cierres consistentes.

### Consulta posterior al COMMIT

Se corrigió la configuración del search_path en
el guion de devolución para permitir las consultas
posteriores a la confirmación.

### Identificador de adopción de devolución

Se sustituyó el identificador fijo por una consulta
que recupera la adopción correspondiente al animal
y al ingreso esperado.

## Validación PJ-12

En la base huellas_g05_jeank_validacion se ejecutó
una reserva y una formalización bajo el rol operativo.

Se observó:

- Reserva 1.
- Adopción 1.
- Animal HS-01.
- Ingreso 1.
- Responsable adoptivo 101.
- Estado de integridad CONSISTENTE.

Las fechas de entrega, cierre del ingreso y cierre
de la reserva coincidieron.

## Consideraciones de integración

La referencia de ingreso a la adopción de origen
queda instalada desde el bloque de Jean Carlos.

No debe ejecutarse adicionalmente el archivo
`sql/integracion/01_adopcion_origen.sql` sobre una
instalación completa que ya contiene esa referencia.

## Conclusión

La instalación integrada fue comprobada en bases
nuevas y permitió ejecutar operaciones de reserva,
formalización, devolución y seguimiento.

Estado de PJ-12: SUPERADA.
