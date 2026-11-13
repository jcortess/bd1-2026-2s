# Pruebas ejecutadas

Solo se ejecutaron las pruebas de pruebas_publicas.sql, en este documento se encuentra un resumen del resultado de cada prueba
Aclaracion: estas pruebas se ejecutaron con los esquemas y datos originales antes de cualquier correccion o normalizacion, y despues se volvieron a ejecutar con los esquemas y datos corregidos

## Prueba 1 (carnets duplicados en ESTUDIANTE)

output con los datos originales:

![output prueba 1](capturas_antes_de_correcciones/output_prueba1_original.png)

output con datos corregidos:

![output corregido prueba 1](capturas_despues_de_correcciones/output_prueba1_corregida.png)

## Prueba 2 (cédulas duplicadas en PROFESOR)

output con los datos originales:

![output prueba 2](capturas_antes_de_correcciones/output_prueba2_original.png)

output con datos corregidos:

![output corregido prueba 2](capturas_despues_de_correcciones/output_prueba2_corregida.png)

## Prueba 3 (matrículas duplicadas, mismo estudiante y grupo)

output con los datos originales:

![output prueba 3](capturas_antes_de_correcciones/output_prueba3_original.png)

output con datos corregidos:

![output corregido prueba 3](capturas_despues_de_correcciones/output_prueba3_corregida.png)

## Prueba 4 (cursos con menos de 1 crédito)

output con los datos originales:

![output prueba 4](capturas_antes_de_correcciones/output_prueba4_original.png)

output con datos corregidos:

![output corregido prueba 4](capturas_despues_de_correcciones/output_prueba4_corregida.png)

## Prueba 5 (notas fuera del rango 0-100)

Nota: en los datos originales no hay una nota menor a 0 o mayor a 100, a pesar de que el esquema original lo permite (visto en Cambios.md). Por lo tanto, se realizo el siguiente UPDATE para forzar este caso:

![update temporal para la prueba](capturas_antes_de_correcciones/modificacion_temporal_prueba.png)

output con el caso de nota negativa:

![output prueba 5](capturas_antes_de_correcciones/output_prueba5_original.png)

output con datos corregidos:

![output corregido prueba 5](capturas_despues_de_correcciones/output_prueba5_corregida.png)

## Prueba 6 (cursos que son requisito de sí mismos)

output con los datos originales:

![output prueba 6](capturas_antes_de_correcciones/output_prueba6_original.png)

output con datos corregidos:

![output corregido prueba 6](capturas_despues_de_correcciones/output_prueba6_corregida.png)

## Prueba 7 (estudiantes sin carrera asignada)

output con los datos originales:

![output prueba 7](capturas_antes_de_correcciones/output_prueba7_original.png)

output con datos corregidos:

![output corregido prueba 7](capturas_despues_de_correcciones/output_prueba7_corregida.png)

## Prueba 8 (existencia de las 8 tablas del modelo)

Nota: se modifico esta consulta para que incluyera a la tabla 'registro', que fue resultado de la normalizacion aplicada a 'auditoria', documentada en Cambios.md

output con los datos originales:

![output prueba 8](capturas_antes_de_correcciones/output_prueba8_original.png)

output con datos corregidos:

![output corregido prueba 8](capturas_despues_de_correcciones/output_prueba8_corregida.png)

## Prueba 9 (aprobación en el umbral exacto)

output con los datos originales:

![output prueba 9](capturas_antes_de_correcciones/output_prueba9_original.png)

output con datos corregidos:

![output corregido prueba 9](capturas_despues_de_correcciones/output_prueba9_corregida.png)

## Prueba 10 (cursos sin ningún grupo registrado)

output con los datos originales:

![output prueba 10](capturas_antes_de_correcciones/output_prueba10_original.png)

output con datos corregidos:

![output corregido prueba 10](capturas_despues_de_correcciones/output_prueba10_corregida.png)
