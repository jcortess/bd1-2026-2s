# Evidencia real de ejecución

Salidas capturadas de Docker y `psql`, sin sustituir resultados por expectativas.
La línea `Comando:` y `Exit code:` es metadato del capturador; las líneas
intermedias proceden del proceso indicado. Las fechas del servidor se muestran
en UTC; la fecha local del trabajo es 2026-10-30 (America/Costa_Rica).

| Archivo | Contenido |
|---|---|
| `00_entorno.txt` | Rama, commit inicial y contexto observado |
| `01_docker_original.txt` | Compose original levantado |
| `02_inicializacion_original.txt` | PostgreSQL 16.15, schema y seed originales |
| `03_publicas_original.txt` | Seis verificaciones con filas inválidas |
| `04_consultas_original.txt` | SQL y resultados de las 12 consultas heredadas |
| `05_auditoria_original.txt` | Restricciones, tipos, datos, requisitos y casos sintéticos originales |
| `06_sondeos_original.sql` / `.txt` | Redondeo de notas, rango sin protección y requisitos sin constancia actual |
| `07_mensajes_decodificados.txt` | Decodificación textual de los tres bloques base64 heredados |
| `08_reinicio_limpio.txt` | Eliminación del contenedor y volumen del reto tras capturar el original |
| `09_docker_corregido.txt` | Nuevo volumen y contenedor saludable |
| `10_inicializacion_corregida.txt` | Inicialización limpia de schema y seed corregidos |
| `11_publicas_corregidas.txt` | Resultados públicos esperados, archivo original sin cambios |
| `12_consultas_corregidas.txt` | SQL y resultados de los 12 reportes corregidos |
| `13_auditoria_corregida.txt` | Esquema, tipos, datos y trazabilidad tras saneamiento |
| `14-final-pruebas_ejecutadas.sql` | Vistas de los SELECT reales, 97 aserciones, rollback |
| `14-final-pruebas_adicionales.txt` | 97 aserciones aprobadas y salida 0 |
| `15_revision_academica.txt` | Casos para revisión administrativa, sin inventar expedientes |
| `16_revision_final.txt` | Git, hashes, alcance de archivos, registro IA y estado persistente |
| `originales/01_schema.sql`, `02_seed.sql`, `03_queries.sql` | Copias tomadas antes de corregir; corresponden al commit inicial |

El SQL generado y los originales se conservan para reproducir el análisis.
El esquema original reinicia `public`: para examinarlo separadamente se debe
usar otra base de desarrollo, no la base corregida que se quiere conservar.

## Repetir las comprobaciones corregidas

Desde `operacion-platano/`, en PowerShell, con Docker Desktop iniciado:

```powershell
docker compose up -d --wait
docker compose cp tests/pruebas_publicas.sql db:/tmp/pruebas_publicas.sql
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d platano -f /tmp/pruebas_publicas.sql
docker compose cp database/03_queries.sql db:/tmp/queries.sql
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d platano -f /tmp/queries.sql
./tests/ejecutar_pruebas.ps1 -Prefijo revision
docker compose cp entregables/revision_academica.sql db:/tmp/revision_academica.sql
docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d platano -f /tmp/revision_academica.sql
```

El ejecutor propio aborta si falla una aserción y guarda dos archivos con el
prefijo elegido. Las vistas y casos de prueba son temporales y terminan con
`rollback`; los INSERT de prueba especifican IDs y no avanzan secuencias.
El generador está pensado para los 12 SELECT simples de este reto; no es un
analizador general de SQL. Las aserciones de resultados iniciales esperan el
seed corregido entregado, antes de agregar datos manualmente.

Para repetir la **instalación desde cero** del reto, el siguiente comando
elimina su volumen de datos de desarrollo; los archivos SQL del repositorio
se conservan. Este es el reinicio que se usó en las evidencias 08–10:

```powershell
docker compose down --volumes
docker compose up -d --wait
```

`up` sobre un volumen ya existente no vuelve a ejecutar los scripts de inicio.
La prueba pública 10 es informativa: debe seguir mostrando IND-1001 sin grupos.
