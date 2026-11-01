#!/usr/bin/env bash
# Revisa un sitio ya publicado antes de pasarle la URL a nadie: que cargue sin login,
# que el SEO no apunte a localhost y que los buscadores puedan indexarlo.
#
#   verificar-url.sh https://mi-sitio.com
#
# Sale con 1 si hay algo para corregir.
set -u

if [ "$#" -ne 1 ]; then
  echo "Uso: verificar-url.sh <url>" >&2
  exit 2
fi

url=${1%/}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fallas=0

bien() { printf '  ✓ %s\n' "$1"; }
mal() { printf '  ✗ %s\n' "$1"; fallas=$((fallas + 1)); }

# Baja una ruta y deja el cuerpo y las cabeceras en $tmp. Imprime el código HTTP.
bajar() {
  curl -sS -L --max-time 30 -D "$tmp/$1.headers" -o "$tmp/$1.body" -w '%{http_code}' "$url$2" 2>/dev/null
}

echo "Revisando $url"

codigo=$(bajar inicio /)
if [ "$codigo" = "200" ]; then
  bien "la portada carga sin login"
else
  mal "la portada da $codigo. Si es 401 o 403, desactivá la deployment protection de Vercel"
fi

for par in "sitemap:/sitemap.xml" "robots:/robots.txt"; do
  nombre=${par%%:*}
  ruta=${par#*:}
  codigo=$(bajar "$nombre" "$ruta")
  if [ "$codigo" = "200" ]; then bien "$ruta existe"; else mal "$ruta da $codigo"; fi
done

for nombre in inicio sitemap robots; do
  if grep -qE 'localhost|127\.0\.0\.1' "$tmp/$nombre.body" 2>/dev/null; then
    mal "$nombre apunta a localhost: cargá NEXT_PUBLIC_SITE_URL en Vercel y volvé a publicar"
  fi
done

if grep -qi 'rel="canonical"' "$tmp/inicio.body" 2>/dev/null; then
  bien "la portada tiene canónica"
else
  mal "la portada no tiene canónica"
fi

if grep -qiE '<meta[^>]+noindex' "$tmp/inicio.body" 2>/dev/null || grep -qi '^x-robots-tag:.*noindex' "$tmp/inicio.headers" 2>/dev/null; then
  mal "la portada tiene noindex: los buscadores no la van a mostrar"
else
  bien "los buscadores pueden indexarla"
fi

if grep -qiE '^disallow: */ *$' "$tmp/robots.body" 2>/dev/null; then
  mal "robots.txt bloquea todo el sitio"
fi

echo
if [ "$fallas" -gt 0 ]; then
  echo "Hay $fallas cosa(s) para corregir antes de pasar la URL."
  exit 1
fi
echo "Todo en orden."
