#!/usr/bin/env bash
# Instala /web-cliente y las 5 skills que usa, en las versiones de skills.lock.
#
#   ./install.sh               no toca las skills que ya tengas con el mismo nombre
#   ./install.sh --reemplazar  las reemplaza y guarda una copia de las anteriores
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
MARCA=".instalado-por-web-cliente"
RESPALDO="$CLAUDE_DIR/skills-respaldo-web-cliente-$(date +%Y%m%d-%H%M%S)"

reemplazar=0
case "${1:-}" in
  --reemplazar) reemplazar=1 ;;
  "") ;;
  *) echo "Uso: ./install.sh [--reemplazar]" >&2; exit 2 ;;
esac

command -v git >/dev/null || { echo "Falta git. Instalalo y volvé a correr esto." >&2; exit 1; }

temporales=()
limpiar() { [ "${#temporales[@]}" -eq 0 ] || rm -rf "${temporales[@]}"; }
trap limpiar EXIT

echo "→ Instalando en $SKILLS_DIR"
mkdir -p "$SKILLS_DIR"
saltadas=()

# Devuelve 0 si hay que instalar `nombre`. Una skill sin marca no es nuestra:
# solo se toca con --reemplazar, y antes se guarda una copia.
hay_que_instalar() {
  local nombre=$1 version=$2 destino="$SKILLS_DIR/$1"
  if [ ! -e "$destino" ]; then return 0; fi
  if [ -f "$destino/$MARCA" ]; then
    [ "$(cat "$destino/$MARCA")" = "$version" ] && { echo "  = $nombre ya está en esta versión"; return 1; }
    return 0
  fi
  if [ "$reemplazar" -eq 1 ]; then
    mkdir -p "$RESPALDO"
    mv "$destino" "$RESPALDO/$nombre"
    echo "  ↪ $nombre anterior guardada en $RESPALDO"
    return 0
  fi
  echo "  ! $nombre: ya tenías una propia, la dejo como está"
  saltadas+=("$nombre")
  return 1
}

# Copia `origen` a la carpeta de skills y deja la marca con la versión.
instalar_carpeta() {
  local nombre=$1 version=$2 origen=$3 destino="$SKILLS_DIR/$1" nuevo="$SKILLS_DIR/.nuevo-$1"
  if ! grep -q "^name: *$nombre *$" "$origen/SKILL.md" 2>/dev/null; then
    echo "  ✗ $nombre: el contenido bajado no es la skill esperada" >&2
    exit 1
  fi
  rm -rf "$nuevo"
  cp -R "$origen" "$nuevo"
  printf '%s\n' "$version" > "$nuevo/$MARCA"
  rm -rf "$destino"
  mv "$nuevo" "$destino"
  echo "  ✓ $nombre"
}

while read -r nombre repo commit carpeta _licencia; do
  case "$nombre" in ""|\#*) continue ;; esac
  version="$repo@$commit"
  hay_que_instalar "$nombre" "$version" || continue

  tmp=$(mktemp -d)
  temporales+=("$tmp")
  git -C "$tmp" init -q
  git -C "$tmp" remote add origin "https://github.com/$repo"
  git -C "$tmp" fetch -q --depth 1 --filter=blob:none origin "$commit"
  if [ "$carpeta" != "." ]; then
    git -C "$tmp" sparse-checkout set --no-cone "/$carpeta/"
  fi
  git -C "$tmp" -c advice.detachedHead=false checkout -q FETCH_HEAD
  rm -rf "$tmp/.git"
  instalar_carpeta "$nombre" "$version" "$tmp/$carpeta"
done < "$REPO_DIR/skills.lock"

version_propia="local@$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo sin-git)-$(find "$REPO_DIR/skills/web-cliente" -type f -exec cat {} + | cksum | cut -d' ' -f1)"
if hay_que_instalar web-cliente "$version_propia"; then
  instalar_carpeta web-cliente "$version_propia" "$REPO_DIR/skills/web-cliente"
  chmod +x "$SKILLS_DIR/web-cliente/scripts/"*
fi

if [ "${#saltadas[@]}" -gt 0 ]; then
  echo
  echo "Dejé las que ya tenías: ${saltadas[*]}."
  echo "El pipeline se probó con las versiones de skills.lock. Para usar esas: ./install.sh --reemplazar"
fi

echo
bash "$SKILLS_DIR/web-cliente/scripts/doctor.sh" || true

cat <<FIN

Listo. Para arrancar una web, abrí Claude Code en una carpeta nueva:

  mkdir mi-cliente && cd mi-cliente && claude

y escribí:

  /web-cliente Panadería La Espiga, Los Cocos

Si Claude Code ya estaba abierto, reinicialo para que vea las skills nuevas.
FIN
