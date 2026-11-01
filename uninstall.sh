#!/usr/bin/env bash
# Saca solo lo que instaló install.sh. Las skills que ya tenías no se tocan.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
MARCA=".instalado-por-web-cliente"

sacar() {
  if [ -f "$SKILLS_DIR/$1/$MARCA" ]; then
    rm -rf "${SKILLS_DIR:?}/$1"
    echo "  ✓ saqué $1"
  elif [ -e "$SKILLS_DIR/$1" ]; then
    echo "  = $1 no la instaló web-cliente, queda como está"
  fi
}

sacar web-cliente
while read -r nombre _resto; do
  case "$nombre" in ""|\#*) continue ;; esac
  sacar "$nombre"
done < "$REPO_DIR/skills.lock"
