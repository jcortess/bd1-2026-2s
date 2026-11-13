param(
    [string]$Base = 'platano',
    [string]$Prefijo = 'final'
)

# Ejecutar desde cualquier carpeta. No reinicia ni modifica la base permanente.
# Construye vistas temporales con las 12 consultas REALES de 03_queries.sql;
# así las pruebas no validan una copia independiente de los reportes.
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$encodingUtf8 = [Text.UTF8Encoding]::new($false)
$OutputEncoding = $encodingUtf8
[Console]::OutputEncoding = $encodingUtf8
if ($Prefijo -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Prefijo inválido' }
if ($Base -notmatch '^[a-zA-Z0-9_]+$') { throw 'Base inválida' }

$source = [IO.File]::ReadAllText((Join-Path $projectPath 'database/03_queries.sql'))
# Estos reportes son SELECT simples, sin bloques ni punto y coma en literales.
$source = [regex]::Replace($source, '(?m)--[^\r\n]*', '')
$queries = @($source.Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($queries.Count -ne 12) { throw 'Se esperaban exactamente 12 reportes' }
$parts = @('\set ON_ERROR_STOP on', '\pset pager off', 'begin;')
for ($index = 0; $index -lt $queries.Count; $index++) {
    if ($queries[$index] -notmatch '^select\b') { throw 'Reporte no reconocido' }
    $parts += "create temp view prueba_consulta_$($index + 1) as $($queries[$index]);"
}
$parts += [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'pruebas_adicionales.sql'))
$parts += 'rollback;'
$generatedPath = Join-Path $projectPath "entregables/evidencias/$Prefijo-pruebas_ejecutadas.sql"
$resultPath = Join-Path $projectPath "entregables/evidencias/$Prefijo-pruebas_adicionales.txt"
[IO.File]::WriteAllText($generatedPath, ($parts -join "`n") + "`n", $encodingUtf8)

Push-Location $projectPath
try {
    & docker compose cp $generatedPath 'db:/tmp/platano-pruebas.sql'
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo copiar el script de pruebas' }
    $command = "docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d $Base -f /tmp/platano-pruebas.sql"
    # Windows PowerShell trata los NOTICE de psql en stderr como ErrorRecord.
    # Se conservan como texto y se determina el éxito por el código del proceso.
    $ErrorActionPreference = 'Continue'
    $lines = @(& docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U platano -d $Base -f /tmp/platano-pruebas.sql 2>&1 |
        ForEach-Object { $_.ToString() })
    $resultCode = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    [IO.File]::WriteAllText($resultPath,
        ((@("Comando: $command") + $lines + @("Exit code: $resultCode")) -join "`n") + "`n", $encodingUtf8)
    $lines | Write-Output
    if ($resultCode -ne 0) { throw "Fallaron las pruebas. Ver $resultPath" }
} finally {
    Pop-Location
}
