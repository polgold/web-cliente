#!/usr/bin/env bash
# Prepara la carpeta actual para una web nueva: handoff, brief, plan, reglas para
# Claude, .gitignore y el hook que frena el cierre si el handoff quedó atrás.
# Nunca pisa un archivo que ya exista.
#
#   nueva-web.sh "Nombre del cliente"
set -euo pipefail

cliente="${1:-}"
if [ -z "$cliente" ]; then
  echo 'Uso: nueva-web.sh "Nombre del cliente"' >&2
  exit 2
fi

BASE="$(cd "$(dirname "$0")/.." && pwd)/templates"
fecha="$(date +%d/%m/%Y)"

# Copia una plantilla reemplazando {{CLIENTE}} y {{FECHA}}. Va por python porque el
# nombre puede traer caracteres que sed interpreta («Aparts & Suites»).
copiar() {
  local origen="$BASE/$1" destino="$2"
  if [ -e "$destino" ]; then
    echo "  = $destino ya existe, no lo toco"
    return 0
  fi
  mkdir -p "$(dirname "$destino")"
  CLIENTE="$cliente" FECHA="$fecha" python3 -I -c '
import os, sys
texto = open(sys.argv[1], encoding="utf8").read()
texto = texto.replace("{{CLIENTE}}", os.environ["CLIENTE"]).replace("{{FECHA}}", os.environ["FECHA"])
open(sys.argv[2], "w", encoding="utf8").write(texto)
' "$origen" "$destino"
  echo "  ✓ $destino"
}

echo "→ Preparando la carpeta para $cliente"
copiar CLAUDE.md CLAUDE.md
copiar HANDOFF.md HANDOFF.md
copiar BRIEF.md BRIEF.md
copiar docs/PLAN.md docs/PLAN.md
copiar docs/TIPOGRAFIA.md docs/TIPOGRAFIA.md
copiar material/LEEME.md material/LEEME.md
copiar env.example .env.example
copiar claude/settings.json .claude/settings.json
copiar claude/hooks/handoff-check.sh .claude/hooks/handoff-check.sh
chmod +x .claude/hooks/handoff-check.sh

# .gitignore: si ya hay uno, se suman solo las líneas que falten.
if [ -e .gitignore ]; then
  while IFS= read -r linea; do
    grep -qxF -- "$linea" .gitignore || printf '%s\n' "$linea" >> .gitignore
  done < "$BASE/gitignore"
  echo "  ✓ .gitignore (completado)"
else
  cp "$BASE/gitignore" .gitignore
  echo "  ✓ .gitignore"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "  = ya es un repo de git"
else
  git init -q -b main
  echo "  ✓ repo de git local (main)"
fi
