"""Exporta mensajes visibles de esta sesión; excluye instrucciones internas y herramientas.

python entregables/registrar_interaccion.py RUTA_SESION_JSONL [--final entregables/RESPUESTA_FINAL.md]
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROMPT = Path(r'C:\Users\rmari\.codex\attachments\bd77d327-fabb-4916-a6d3-26e8b4c2a94f\Pasted text.txt')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sesion', type=Path)
    parser.add_argument('--final', type=Path)
    args = parser.parse_args()
    rows = []
    for line in args.sesion.read_text(encoding='utf-8').splitlines():
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue  # El registro puede estar recibiendo su última línea.
    meta = next(row['payload'] for row in rows if row['type'] == 'session_meta')
    if Path(meta['cwd']).resolve() != ROOT.parent.resolve():
        raise SystemExit('La sesión no corresponde a este repositorio.')
    # read_bytes evita normalizar los saltos del prompt original.
    prompt = PROMPT.read_bytes().decode('utf-8')
    output = ['# Interacción con IA — Maria Paula\n\n',
              'Sesión del 4 de noviembre de 2026 (America/Costa_Rica). '
              'Solo mensajes visibles de esta sesión; salidas de ejecución en entregables/evidencias/. '
              'No se incluyen instrucciones internas ni razonamiento privado.\n\n',
              '## Prompt completo adjunto (sin modificar)\n\n', prompt, '\n\n',
              '## Mensajes de la sesión en orden\n\n']
    count = 0
    for row in rows:
        if row['type'] != 'response_item':
            continue
        payload = row['payload']
        if payload.get('type') == 'function_call' and payload.get('name', '').endswith('request_user_input_async'):
            params = json.loads(payload.get('arguments', '{}'))
            body = '\n\n'.join(question['title'] + '\n\n' + '\n'.join('- '+option for option in question.get('options', []))
                                for question in params.get('questions', []))
            if body:
                count += 1
                output.append(f"### {count}. Asistente — pregunta de aclaración real\n\n{body}\n\n")
            continue
        if payload.get('type') != 'message' or payload.get('role') not in ('assistant', 'user'):
            continue
        parts = [part.get('text', '') for part in payload.get('content', [])
                 if part.get('type') in ('input_text', 'output_text', 'text')]
        body = '\n'.join(parts)
        if not body or body.startswith(('<environment_context>', '<external_codex_apps_open_page>')):
            continue
        count += 1
        role = 'Asistente' if payload['role'] == 'assistant' else 'Maria Paula'
        output.append(f"### {count}. {role} — {row.get('timestamp', '')}\n\n{body}\n\n")
    if args.final:
        final = (ROOT / args.final).resolve()
        final.relative_to(ROOT)
        output.append('## Respuesta final preparada para esta interacción\n\n' + final.read_text(encoding='utf-8') + '\n\n')
    output.append('<!-- Agregar las próximas interacciones debajo, conservando prompts y respuestas reales. -->\n')
    (ROOT / 'interaccion_ia.md').write_bytes(''.join(output).encode('utf-8'))
    assert prompt in (ROOT / 'interaccion_ia.md').read_bytes().decode('utf-8')
    print(f'interaccion_ia.md: prompt completo preservado; {count} mensajes visibles registrados.')

if __name__ == '__main__':
    main()
