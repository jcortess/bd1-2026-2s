"""Revisión de archivos y Git sin hacer commit, staging ni cambios de rama."""
import ast
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent

def git(*args):
    return subprocess.check_output(['git', *args], cwd=REPO)

def main():
    branch = git('branch', '--show-current').decode().strip()
    assert branch == 'MariaPaulaRomeroGarro', branch
    print('OK rama:', branch)
    git('diff', '--check')
    changed = git('diff', '--name-only', 'HEAD').decode().splitlines()
    allowed = {f'operacion-platano/database/{name}' for name in
               ('01_schema.sql', '02_seed.sql', '03_queries.sql')}
    assert set(changed) == allowed, changed
    print('OK tres archivos existentes modificados:', ', '.join(changed))
    untracked = git('ls-files', '--others', '--exclude-standard').decode().splitlines()
    assert all(path.startswith('operacion-platano/') for path in untracked), untracked
    print('OK todos los archivos nuevos dentro de operacion-platano/')
    for name in ('01_schema.sql', '02_seed.sql', '03_queries.sql'):
        original = (ROOT / 'entregables/evidencias/original' / name).read_bytes()
        blob = git('show', f'HEAD:operacion-platano/database/{name}')
        assert original.replace(b'\r\n', b'\n') == blob.replace(b'\r\n', b'\n'), name
    print('OK copias originales coinciden con HEAD (normalizando CRLF/LF)')
    originals = ['AGENTS.md', 'README.md', 'docker-compose.yml', 'docs/reglas_negocio.md',
                 'docs/notas_migracion.md', 'docs/historial_cambios.md',
                 'entregables/INSTRUCCIONES.md', 'tests/pruebas_publicas.sql']
    git('diff', '--exit-code', 'HEAD', '--', *['operacion-platano/'+p for p in originals])
    print('OK reglas, instrucciones, documentos originales, Compose y pruebas públicas intactos')
    for path in (ROOT / 'entregables').glob('*.py'):
        ast.parse(path.read_text(encoding='utf-8'), filename=str(path))
    print('OK sintaxis de todos los ejecutores Python (sin generar __pycache__)')
    expected = ['entregables/CAMBIOS.md','entregables/PRUEBAS.md',
                'entregables/GUIA_DEFENSA.md','interaccion_ia.md',
                'tests/pruebas_adicionales.sql','tests/estado_final.sql']
    assert all((ROOT / p).is_file() for p in expected)
    print('OK documentación, registro IA y pruebas adicionales presentes')
    result = (ROOT / 'entregables/evidencias/27_adicionales_limpio_final.txt').read_text(encoding='utf-8')
    assert result.count('NOTICE:  OK: ') == 104
    assert 'EXIT_CODE=0' in result and 'FALLO' not in result
    assert result.rstrip().endswith('EXIT_CODE=0') and '\nROLLBACK\n' in result
    print('OK evidencia final: 104 aserciones, rollback y código cero')
    print('Sin staging, commit, checkout, merge, push ni Pull Request.')

if __name__ == '__main__':
    main()
