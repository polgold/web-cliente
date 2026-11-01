#!/usr/bin/env bash
# Chequea lo que hace falta para correr /web-cliente. No instala nada.
#
#   doctor.sh             lo necesario para construir (GitHub y Vercel solo avisan)
#   doctor.sh --publicar  también exige lo necesario para publicar
#
# Sale con 1 si falta algo necesario.
set -u

publicar=0
[ "${1:-}" = "--publicar" ] && publicar=1

SKILLS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
falta=0
avisos=0
case "$(uname -s)" in
  Darwin) mac=1 ;;
  *) mac=0 ;;
esac

bien() { printf '  ✓ %s\n' "$1"; }
aviso() { printf '  ! %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; avisos=$((avisos + 1)); }
mal() { printf '  ✗ %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; falta=$((falta + 1)); }

como() { # $1 = comando para Mac, $2 = comando para Linux
  if [ "$mac" -eq 1 ]; then printf '%s' "$1"; else printf '%s' "$2"; fi
}

echo "Para construir:"

if command -v git >/dev/null; then bien "git $(git --version | awk '{print $3}')"
else mal "Falta git" "$(como 'xcode-select --install' 'sudo apt install git')"; fi

if command -v node >/dev/null; then
  mayor=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
  if [ "$mayor" -ge 20 ]; then bien "node $(node -v)"
  else mal "node $(node -v) es viejo: Next.js 16 pide 20 o más" "$(como 'brew install node' 'Instalalo desde https://nodejs.org')"; fi
else mal "Falta node" "$(como 'brew install node' 'Instalalo desde https://nodejs.org')"; fi

if command -v pnpm >/dev/null; then bien "pnpm $(pnpm -v 2>/dev/null)"
else mal "Falta pnpm" "npm install -g pnpm"; fi

if command -v python3 >/dev/null; then bien "$(python3 --version 2>&1)"
else mal "Falta python3" "$(como 'brew install python' 'sudo apt install python3')"; fi

for s in huashu-design ui-ux-pro-max design-taste-frontend emil-design-eng impeccable; do
  if [ ! -f "$SKILLS_ROOT/$s/SKILL.md" ]; then
    mal "Falta la skill $s" "Corré install.sh del repo web-cliente"
  fi
done
[ "$falta" -eq 0 ] && bien "las 5 skills del pipeline"

navegador=""
for d in "${PLAYWRIGHT_BROWSERS_PATH:-}" "$HOME/Library/Caches/ms-playwright" "$HOME/.cache/ms-playwright"; do
  ls "$d" 2>/dev/null | grep -q '^chromium' && navegador=1
done
if [ -n "$navegador" ]; then bien "navegador para las capturas"
else aviso "Todavía no está el navegador para las capturas: se baja solo la primera vez (unos 150 MB)"; fi

echo
echo "Para publicar:"
falta_antes=$falta
marcar() { if [ "$publicar" -eq 1 ]; then mal "$@"; else aviso "$@"; fi; }

if command -v gh >/dev/null; then
  if gh auth status >/dev/null 2>&1; then bien "GitHub: $(gh api user --jq .login 2>/dev/null || echo conectado)"
  else marcar "GitHub CLI sin sesión" "gh auth login"; fi
else marcar "Falta GitHub CLI" "$(como 'brew install gh' 'Ver https://cli.github.com')"; fi

if ! command -v vercel >/dev/null; then
  marcar "Falta Vercel CLI" "npm install -g vercel"
elif [ "$publicar" -eq 1 ] && ! cuenta=$(vercel whoami </dev/null 2>/dev/null); then
  marcar "Vercel CLI sin sesión" "vercel login"
else
  bien "vercel $(vercel --version 2>/dev/null | tail -1)${cuenta:+: $(printf '%s' "$cuenta" | tail -1)}"
fi

echo
if [ "$falta" -gt 0 ]; then
  echo "Falta instalar $falta cosa(s). Con los comandos de arriba se resuelve."
  exit 1
fi
if [ "$avisos" -gt 0 ] && [ "$falta_antes" -eq 0 ]; then
  echo "Se puede arrancar. Los avisos (!) no frenan el trabajo por ahora."
else
  echo "Todo en orden."
fi
exit 0
