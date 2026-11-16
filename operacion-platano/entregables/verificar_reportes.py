"""Prueba los doce SELECT reales con casos independientes y rollback.

python entregables/verificar_reportes.py --contenedor platano_db --base platano --evidencia 20_adicionales.txt
"""
import argparse
from datetime import datetime
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contenedor', default='platano_db')
    parser.add_argument('--base', default='platano')
    parser.add_argument('--evidencia', required=True)
    parser.add_argument('--pruebas', default='tests/pruebas_adicionales.sql')
    parser.add_argument('--consultas', default='database/03_queries.sql')
    args = parser.parse_args()
    raw = (ROOT / args.consultas).read_text(encoding='utf-8')
    clean = re.sub(r'--[^\n]*', '', raw)
    queries = [part.strip() for part in clean.split(';') if part.strip()]
    if len(queries) != 12 or not all(re.match(r'select\b', q, re.I) for q in queries):
        raise SystemExit('Se esperaban exactamente doce SELECT; revisar extractor antes de ejecutar.')
    sql = '\\set ON_ERROR_STOP on\n\\pset pager off\nbegin;\n'
    sql += '\n'.join(f'create temporary view reporte_{n} as {query};' for n, query in enumerate(queries, 1))
    sql += '\n' + (ROOT / args.pruebas).read_text(encoding='utf-8')
    sql += '\nrollback;\n'
    command = ['docker', 'exec', '-i', args.contenedor, 'psql', '-X', '-v', 'ON_ERROR_STOP=1',
               '-U', 'platano', '-d', args.base, '-f', '-']
    target = (ROOT / 'entregables/evidencias' / args.evidencia).resolve()
    target.relative_to(ROOT / 'entregables/evidencias')
    if target.exists():
        parser.error('La evidencia ya existe; usar un nombre nuevo.')
    result = subprocess.run(command, input=sql.encode('utf-8'), stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, cwd=ROOT)
    output = result.stdout.decode('utf-8', errors='replace')
    target.write_text(f'Fecha local: {datetime.now().astimezone().isoformat()}\n'
                      f'Comando: {subprocess.list2cmdline(command)}\n'
                      f'Entrada: doce SELECT reales de {args.consultas} + {args.pruebas}\n\n'
                      + output + f'\nEXIT_CODE={result.returncode}\n', encoding='utf-8')
    sys.stdout.buffer.write(output.encode('utf-8'))
    print(f'\nEvidencia: {target.relative_to(ROOT)}; EXIT_CODE={result.returncode}')
    return result.returncode

if __name__ == '__main__':
    raise SystemExit(main())
