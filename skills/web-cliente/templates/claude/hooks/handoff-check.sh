#!/usr/bin/env bash
# Stop hook: si hay archivos del proyecto más nuevos que HANDOFF.md, frena el
# cierre del turno una vez para que se actualice el handoff.

input=$(cat)
if printf '%s' "$input" | grep -Eq '"stop_hook_active": *true'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

if [ ! -f HANDOFF.md ]; then
  echo '{"decision":"block","reason":"Falta HANDOFF.md. Crealo con el estado del proyecto antes de terminar."}'
  exit 0
fi

changed=$(find . \( -name .git -o -name node_modules -o -name .next -o -name .vercel -o -name .turbo -o -name test-results -o -name playwright-report -o -name capturas \) -prune \
  -o -type f -newer HANDOFF.md -not -name .DS_Store -not -name next-env.d.ts -not -name '*.tsbuildinfo' -print -quit | tr -d '"\\')

if [ -n "$changed" ]; then
  printf '{"decision":"block","reason":"%s es más nuevo que HANDOFF.md. Actualizá HANDOFF.md (estado, pendientes y Registro) antes de terminar."}\n' "$changed"
fi
exit 0
