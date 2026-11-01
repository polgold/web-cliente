#!/usr/bin/env bash
# Saca capturas de página completa a 1440 y a 375 px.
#
#   capturas.sh http://localhost:3000 capturas/home
#   capturas.sh design-demos/tipografias.html capturas/tipografias
#
# Deja capturas/home-1440.png y capturas/home-375.png. La primera vez baja el
# navegador (unos 150 MB).
set -euo pipefail

PLAYWRIGHT="playwright@1.64.1"

if [ "$#" -ne 2 ]; then
  echo "Uso: capturas.sh <url o archivo.html> <prefijo de salida>" >&2
  exit 2
fi

objetivo=$1
salida=$2
case "$objetivo" in
  http://*|https://*|file://*) ;;
  *)
    [ -e "$objetivo" ] || { echo "No existe: $objetivo" >&2; exit 1; }
    objetivo="file://$(cd "$(dirname "$objetivo")" && pwd)/$(basename "$objetivo")"
    ;;
esac
mkdir -p "$(dirname "$salida")"

# Si ya está el navegador, no hace nada. Su salida solo importa cuando falla.
if ! registro=$(npx -y "$PLAYWRIGHT" install chromium 2>&1); then
  printf '%s\n' "$registro" >&2
  exit 1
fi

capturar() {
  if ! registro=$(npx -y "$PLAYWRIGHT" screenshot --browser chromium --full-page --wait-for-timeout 1500 \
    --viewport-size="$1,$2" "$objetivo" "$salida-$1.png" 2>&1); then
    printf '%s\n' "$registro" >&2
    exit 1
  fi
  echo "  ✓ $salida-$1.png"
}

capturar 1440 900
capturar 375 812
