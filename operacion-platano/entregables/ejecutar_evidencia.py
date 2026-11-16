"""Guarda salida real; solo escribe dentro de entregables/evidencias.

Uso desde operacion-platano:
python entregables/ejecutar_evidencia.py archivo.txt -- docker ...
python entregables/ejecutar_evidencia.py archivo.txt --sql tests/archivo.sql -- docker ... psql ... -f -
"""
import argparse
from datetime import datetime
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('evidencia')
    parser.add_argument('--sql')
    # Separación explícita permite que --sql se interprete antes del comando.
    argv = sys.argv[1:]
    pos = argv.index('--')
    args = parser.parse_args(argv[:pos])
    command = argv[pos + 1:]
    target = (ROOT / 'entregables' / 'evidencias' / args.evidencia).resolve()
    target.relative_to(ROOT / 'entregables' / 'evidencias')
    if target.exists():
        parser.error('La evidencia ya existe; usa otro nombre para conservarla.')
    source = (ROOT / args.sql).read_bytes() if args.sql else None
    result = subprocess.run(command, cwd=ROOT, input=source,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            env={**os.environ, 'PYTHONIOENCODING': 'utf-8'})
    output = result.stdout.decode('utf-8', errors='replace')
    header = f"Fecha local: {datetime.now().astimezone().isoformat()}\nComando: {subprocess.list2cmdline(command)}\n"
    if args.sql:
        header += f"Entrada SQL: {args.sql}\n"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(header + '\n' + output + f'\nEXIT_CODE={result.returncode}\n', encoding='utf-8')
    sys.stdout.buffer.write(output.encode('utf-8'))
    print(f'\nEvidencia: {target.relative_to(ROOT)}; EXIT_CODE={result.returncode}')
    return result.returncode

if __name__ == '__main__':
    raise SystemExit(main())
