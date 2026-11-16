"""Crea y verifica huellas de la entrega; excluye el propio manifiesto."""
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'entregables/evidencias/MANIFIESTO_SHA256.txt'

def main():
    files = [ROOT / 'interaccion_ia.md']
    for directory in ('database','tests','entregables'):
        files.extend(path for path in (ROOT / directory).rglob('*')
                     if path.is_file() and path != TARGET and '__pycache__' not in path.parts)
    files = sorted(set(files), key=lambda path: path.relative_to(ROOT).as_posix())
    entries = [(hashlib.sha256(path.read_bytes()).hexdigest(), path.relative_to(ROOT).as_posix()) for path in files]
    TARGET.write_text('# SHA-256 de archivos finales; rutas relativas a operacion-platano/.\n'
                      '# Excluye este manifiesto para evitar autorreferencia.\n'
                      + ''.join(f'{digest}  {name}\n' for digest,name in entries), encoding='utf-8')
    for digest,name in entries:
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == digest, name
    print(f'MANIFIESTO_SHA256.txt: {len(entries)} archivos calculados y verificados.')

if __name__ == '__main__':
    main()
