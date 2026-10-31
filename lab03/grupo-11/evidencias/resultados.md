# Grupo 11 Dilan Sibaja, resultados

# Consultas

## Consulta 1 - responsables de una finca durante un periodo

(para finca-0001 del productor-0001)

| responsable_id | nombre | fecha_de_ingreso | fecha_de_salida |
|---|---|---|---|
| responsable-0001 | María Fernández Solís | 15/03/2021 | null |

## Consulta 2 - todas las fincas de un productor

(fincas del productor-0001)

| finca_id | responsable_id | provincia | canton | distrito | indicacion_especifica | area_aproximada |
|---|---|---|---|---|---|---|
| finca-0001 | responsable-0001 | Alajuela | San Carlos | Quesada | 200 metros norte de la iglesia católica | 1500 m² |
| finca-0002 | responsable-0002 | Heredia | Sarapiqui | Puerto Viejo | Camino a La Chiripa, 3 km al este de la escuela | 25000 m² |

## Consulta 3 - total de fincas de las que un responsable estuvo a cargo alguna vez

(fincas que estuvieron a cargo de responsable-0001 alguna vez)

| responsable_id | nombre | total_fincas |
|---|---|---|
| responsable-0001 | María Fernández Solís | 2 |

# Pruebas de integridad

| ID | Esperado | Observado | Conclusion |
|---|---|---|---|
| p01 | exito | se agrego una fila | un productor con datos unicos se ingresa correctamente |
| p02 | error por violar check de provincia | 'new row violates check constraint for "fincas_provincia_check' | se impide el ingreso de una finca con provincia invalida  |
| p03 | exito | se agrego una fila | una finca con datos validos se ingresa correctamente |
| p04 | error por violar nor null de nombre |  'null value in "nombre" violates not-null constraint | se impide el ingreso de responsables sin nombre |
| p05 | error por violar unicidad de los correos de responsables | 'duplicate key value violates unique constraint' | se impide el ingreso de correos repetidos para responsables |
| p06 | exito | se agrego una fila | un correo unico se ingresa correctamente |
