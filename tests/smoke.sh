#!/usr/bin/env bash
# Prueba el repo de punta a punta en un HOME vacío. No toca tu ~/.claude.
#
#   tests/smoke.sh               instalador, plantillas, hook y tipografías
#   tests/smoke.sh --con-build   además crea un Next.js, lo compila y saca capturas
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PRUEBA=$(mktemp -d)
trap 'rm -rf "$PRUEBA"' EXIT
export HOME="$PRUEBA/home"
unset CLAUDE_CONFIG_DIR
mkdir -p "$HOME"
S="$HOME/.claude/skills"
WC="$S/web-cliente/scripts"
fallas=0

ok() { printf '  ✓ %s\n' "$1"; }
mal() { printf '  ✗ %s\n' "$1"; fallas=$((fallas + 1)); }
prueba() { # descripción, comando...
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else mal "$d"; fi
}
no() { ! "$@"; }

echo "Instalación"
prueba "install.sh termina bien en un HOME vacío" bash "$REPO/install.sh"
for s in web-cliente huashu-design ui-ux-pro-max design-taste-frontend emil-design-eng impeccable; do
  prueba "$s instalada" test -f "$S/$s/SKILL.md"
done
prueba "no instala web-rebuilder ni agentes ni MCP" bash -c "[ ! -e '$S/web-rebuilder' ] && [ ! -e '$HOME/.claude/agents' ] && [ ! -e '$HOME/.claude.json' ]"
prueba "volver a instalar no rompe nada" bash "$REPO/install.sh"

echo "Respeta lo que ya estaba"
rm "$S/emil-design-eng/.instalado-por-web-cliente"
echo "mía" >> "$S/emil-design-eng/SKILL.md"
bash "$REPO/install.sh" >/dev/null 2>&1
prueba "no pisa una skill propia" grep -q "^mía$" "$S/emil-design-eng/SKILL.md"
bash "$REPO/install.sh" --reemplazar >/dev/null 2>&1
prueba "--reemplazar la cambia" no grep -q "^mía$" "$S/emil-design-eng/SKILL.md"
prueba "--reemplazar guarda la anterior" bash -c "grep -q '^mía$' '$HOME'/.claude/skills-respaldo-web-cliente-*/emil-design-eng/SKILL.md"

echo "Requisitos"
prueba "doctor pasa con todo instalado" bash "$WC/doctor.sh"
mv "$S/impeccable" "$PRUEBA/impeccable"
prueba "doctor avisa si falta una skill" no bash "$WC/doctor.sh"
mv "$PRUEBA/impeccable" "$S/impeccable"

echo "Skills de terceros"
prueba "ui-ux-pro-max responde" python3 "$S/ui-ux-pro-max/scripts/search.py" "bakery" --design-system
prueba "impeccable responde" bash -c "cd '$PRUEBA' && '$S/impeccable/scripts/impeccable' context"

echo "Proyecto nuevo"
P="$PRUEBA/Panadería La Espiga & Cía"
mkdir -p "$P"
cd "$P" || exit 1
prueba "nueva-web.sh crea el proyecto" bash "$WC/nueva-web.sh" "Panadería La Espiga & Cía"
for f in CLAUDE.md HANDOFF.md BRIEF.md docs/PLAN.md docs/TIPOGRAFIA.md .gitignore .env.example .claude/settings.json; do
  prueba "$f creado" test -f "$f"
done
prueba "el nombre con & queda bien" grep -q "Panadería La Espiga & Cía" HANDOFF.md
prueba "no quedan variables sin reemplazar" no grep -rq "{{" CLAUDE.md HANDOFF.md BRIEF.md docs
echo "nota mía" >> BRIEF.md
bash "$WC/nueva-web.sh" "Otro" >/dev/null 2>&1
prueba "correrlo de nuevo no pisa nada" grep -q "nota mía" BRIEF.md
touch .env material/foto.jpg
prueba "git ignora .env" git check-ignore -q .env
prueba "git ignora el material" git check-ignore -q material/foto.jpg
prueba "git no ignora .env.example" no git check-ignore -q .env.example

echo "Hook del handoff"
H=.claude/hooks/handoff-check.sh
hook() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$P" bash "$H"; }
sleep 1; touch BRIEF.md; sleep 1; touch nuevo.txt
prueba "frena si hay archivos más nuevos" bash -c "printf '{}' | CLAUDE_PROJECT_DIR='$P' bash '$H' | grep -q block"
prueba "frena una sola vez" bash -c "[ -z \"\$(printf '{\"stop_hook_active\":true}' | CLAUDE_PROJECT_DIR='$P' bash '$H')\" ]"
sleep 1; touch HANDOFF.md
prueba "no frena con el handoff al día" bash -c "[ -z \"\$(printf '{}' | CLAUDE_PROJECT_DIR='$P' bash '$H')\" ]"
rm nuevo.txt

echo "Tipografías"
T="$WC/tipografias.py"
prueba "el catálogo coincide con Google Fonts" python3 "$T" verificar
ids=$(python3 "$T" lista | grep -E '^[a-z]' | awk '{print $1}')
todas=1
for i in $ids; do python3 "$T" codigo "$i" >/dev/null 2>&1 || todas=0; done
prueba "todas las opciones generan código" test "$todas" -eq 1
prueba "arma la muestra" python3 "$T" muestra --ids archivo-ancha,bitter-honesta,young-artesanal,rosario-calida --extra "Fraunces|Hanken Grotesk" \
  --cliente "La Espiga" --titulo "Pan de masa madre" --bajada "Horneado acá" --parrafo "Todos los días." --boton "Pedí" --dato "\$ 4.500"
prueba "la muestra trae las 5 opciones" bash -c "[ \"\$(grep -c 'class=\"op\"' design-demos/tipografias.html)\" = 5 ]"
prueba "rechaza una familia que no existe" no python3 "$T" codigo --titulo-familia "Fuente Inventada" --texto-familia "Hanken Grotesk"

mkdir -p app
printf 'import { Geist } from "next/font/google";\n' > app/layout.tsx
prueba "chequear detecta Geist" no python3 "$T" chequear .
rm app/layout.tsx
mkdir -p .claude/skills/otra
printf 'import { Inter } from "next/font/google";\n' > .claude/skills/otra/x.tsx
prueba "chequear no revisa .claude" python3 "$T" chequear .
prueba "git ignora skills dentro del proyecto" git check-ignore -q .claude/skills/otra/x.tsx
rm -rf .claude/skills
printf 'import { Young_Serif, Familjen_Grotesk } from "next/font/google";\n' > app/layout.tsx
prueba "chequear detecta una fuente que no se eligió" no python3 "$T" chequear .
printf '\n**Elegida:** Young Serif + Familjen Grotesk\n' >> docs/TIPOGRAFIA.md
prueba "chequear pasa con la elegida" python3 "$T" chequear .
printf 'import { Playfair_Display } from "next/font/google";\n' > app/layout.tsx
printf '\nPlayfair Display\nExcepción: Playfair Display, es la marca del cliente\n' >> docs/TIPOGRAFIA.md
prueba "chequear respeta una excepción anotada" python3 "$T" chequear .
rm -rf app design-demos

echo "Contraste"
prueba "aprueba un par con contraste" python3 "$WC/contraste.py" "#000000" "#ffffff"
prueba "rechaza un par sin contraste" no python3 "$WC/contraste.py" "#999999" "#aaaaaa"
prueba "--grande pide menos" python3 "$WC/contraste.py" "#767676" "#ffffff" --grande

echo "Sitio publicado"
SITIO="$PRUEBA/sitio"
mkdir -p "$SITIO"
puerto=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
(cd "$SITIO" && exec python3 -m http.server "$puerto" --bind 127.0.0.1 >/dev/null 2>&1) &
servidor=$!
sleep 1
U="http://127.0.0.1:$puerto"
printf '<link rel="canonical" href="https://ejemplo.com/">' > "$SITIO/index.html"
printf '<urlset><url><loc>https://ejemplo.com/</loc></url></urlset>' > "$SITIO/sitemap.xml"
printf 'User-agent: *\nAllow: /\n' > "$SITIO/robots.txt"
prueba "verificar-url aprueba un sitio bien armado" bash "$WC/verificar-url.sh" "$U"
printf '<urlset><url><loc>http://localhost:3000/</loc></url></urlset>' > "$SITIO/sitemap.xml"
prueba "verificar-url detecta localhost" no bash "$WC/verificar-url.sh" "$U"
printf '<urlset><url><loc>https://ejemplo.com/</loc></url></urlset>' > "$SITIO/sitemap.xml"
printf '<link rel="canonical" href="https://ejemplo.com/"><meta name="robots" content="noindex">' > "$SITIO/index.html"
prueba "verificar-url detecta noindex" no bash "$WC/verificar-url.sh" "$U"
printf '<link rel="canonical" href="https://ejemplo.com/">' > "$SITIO/index.html"
printf 'User-agent: *\nDisallow: /\n' > "$SITIO/robots.txt"
prueba "verificar-url detecta robots que bloquea" no bash "$WC/verificar-url.sh" "$U"
rm "$SITIO/index.html"
prueba "verificar-url detecta una portada caída" no bash "$WC/verificar-url.sh" "$U/no-existe"
kill "$servidor" 2>/dev/null
wait "$servidor" 2>/dev/null

if [ "${1:-}" = "--con-build" ]; then
  echo "Next.js"
  prueba "next-scaffold.sh crea el proyecto" bash "$WC/next-scaffold.sh"
  prueba "no pisa CLAUDE.md" grep -q "Panadería La Espiga" CLAUDE.md
  prueba "el nombre del paquete queda limpio" grep -q '"name": "panaderia-la-espiga-cia"' package.json
  prueba "deja .env para desarrollar" test -f .env
  prueba "saca el favicon de Next" test ! -e app/favicon.ico
  prueba "chequear detecta el Geist del scaffold" no python3 "$T" chequear .
  cat > app/fonts.ts <<'F'
import { Bitter, Hanken_Grotesk } from "next/font/google";
export const fontTitulo = Bitter({ subsets: ["latin"], variable: "--font-titulo", display: "swap" });
export const fontTexto = Hanken_Grotesk({ subsets: ["latin"], variable: "--font-texto", display: "swap" });
F
  cat > app/layout.tsx <<'F'
import "./globals.css";
import { fontTitulo, fontTexto } from "./fonts";
export default function L({ children }: { children: React.ReactNode }) {
  return <html lang="es" className={`${fontTitulo.variable} ${fontTexto.variable}`}><body>{children}</body></html>;
}
F
  printf '\nBitter + Hanken Grotesk\n' >> docs/TIPOGRAFIA.md
  sed -i.bak '/font-geist/d' app/globals.css && rm -f app/globals.css.bak
  prueba "chequear pasa con la fuente aplicada" python3 "$T" chequear .
  prueba "pnpm build compila" pnpm build
  python3 "$T" muestra --ids archivo-ancha,bitter-honesta --cliente X --titulo "Pan" --bajada "Rico" --parrafo "Sí" --boton "Pedí" --dato "1" >/dev/null
  prueba "capturas.sh saca las dos capturas" bash "$WC/capturas.sh" design-demos/tipografias.html capturas/t
  prueba "captura a 1440" test -s capturas/t-1440.png
  prueba "captura a 375" test -s capturas/t-375.png
fi

cd "$PRUEBA" || exit 1
echo "Desinstalación"
mkdir -p "$S/una-mia" && echo x > "$S/una-mia/SKILL.md"
prueba "uninstall.sh termina bien" bash "$REPO/uninstall.sh"
prueba "saca lo que instaló" test ! -e "$S/web-cliente"
prueba "deja lo demás" test -e "$S/una-mia/SKILL.md"

echo
if [ "$fallas" -gt 0 ]; then
  echo "Fallaron $fallas pruebas."
  exit 1
fi
echo "Todo en orden."
