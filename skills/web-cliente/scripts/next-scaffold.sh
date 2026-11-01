#!/usr/bin/env bash
# Crea el proyecto Next.js (App Router, TypeScript, Tailwind v4, pnpm) en la carpeta
# actual. create-next-app no arranca en una carpeta con archivos y acá ya están
# HANDOFF.md, CLAUDE.md y compañía, así que genera aparte y trae lo que falta,
# sin pisar nada.
set -euo pipefail

if [ -f package.json ]; then
  echo "Ya hay un package.json en esta carpeta: no hago nada."
  exit 0
fi

# «Panadería La Espiga & Cía» → panaderia-la-espiga-cia
slug=$(python3 -I -c '
import re, sys, unicodedata
s = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode().lower()
print(re.sub(r"[^a-z0-9]+", "-", s).strip("-") or "web")
' "$(basename "$PWD")")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "→ Generando Next.js"
(cd "$tmp" && pnpm dlx create-next-app@16 "$slug" --ts --tailwind --app --eslint --no-src-dir \
  --import-alias "@/*" --use-pnpm --yes --skip-install --disable-git >/dev/null)

origen="$tmp/$slug"
# Los íconos de ejemplo, el favicon de Next y el README genérico no le sirven a un
# sitio de cliente.
rm -f "$origen"/public/{file,globe,next,vercel,window}.svg "$origen/app/favicon.ico" "$origen/README.md"
# Nuestro .gitignore ya cubre lo de Next, y el suyo volvería a ignorar .env.example.
[ -e .gitignore ] && rm -f "$origen/.gitignore"

cp -Rn "$origen"/. . 2>/dev/null || true

if [ -f .env.example ] && [ ! -e .env ]; then
  cp .env.example .env
fi

echo "→ Instalando dependencias"
pnpm install --silent

echo "  ✓ Next.js listo. Falta reemplazar las fuentes del scaffold: tipografias.py codigo <id>"
