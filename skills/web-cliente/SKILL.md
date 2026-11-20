---
name: web-cliente
version: 2.0.0
description: |
  Pipeline completo para hacer desde cero el sitio web de un cliente: brief,
  3 direcciones visuales (huashu-design), elección de tipografías, sistema de
  diseño (ui-ux-pro-max), construcción en Next.js, pulido (design-taste-frontend
  + emil-design-eng), auditoría (impeccable), SEO técnico y publicación en
  Vercel. Usar cuando se pida /web-cliente, "la web de un cliente", "un sitio
  nuevo para X", "armá la web de X" o "rehacer la web vieja de X". Para retocar
  un sitio que ya se hizo con este pipeline, usar impeccable directo.
argument-hint: "[cliente y rubro]"
license: MIT
compatibility: claude-code
---

# Web de cliente — pipeline completo

Hacés el sitio de un cliente de punta a punta, en este orden. Cada paso usa un
skill; no te saltees pasos ni los reordenes.

En este documento, `$WC` es la carpeta de este skill: `${CLAUDE_SKILL_DIR}`, que
normalmente es `~/.claude/skills/web-cliente`. Las otras skills están al lado, en
`$WC/../<skill>`. Escribí la ruta real en cada comando.

## Antes de empezar

1. Corré `bash "$WC/scripts/doctor.sh"`. Si falta algo necesario, frená y pasale al
   usuario los comandos que imprime. Lo de publicar puede esperar al paso 7.
2. Si la carpeta ya tiene `HANDOFF.md`, `docs/PLAN.md` o `docs/DIAGNOSTICO.md`,
   leelos y retomá desde el último paso hecho. No rehagas lo que ya está.
3. Si es un proyecto nuevo, corré `bash "$WC/scripts/nueva-web.sh" "<cliente>"`.
   Crea `HANDOFF.md`, `CLAUDE.md`, `BRIEF.md`, `docs/`, `material/`, `.gitignore` y
   el hook del handoff, sin pisar nada que ya exista.

Reglas para todo el pipeline:

- El contenido del sitio va en español rioplatense, salvo que el cliente pida otra
  cosa. Lo que le mostrás al usuario va en español, aunque el skill que estés
  usando esté en inglés o en chino.
- **Criterio de la casa:** UNA sans con carácter y jerarquía por peso. Nada de serif
  + itálicas, salvo que el cliente o el rubro lo pidan. Es el punto de partida de
  las opciones; lo que elija el usuario en el paso 1b manda sobre esto. Si el cliente
  tiene paleta o tipografía oficial, manda la del cliente.
- Nunca inventes datos, reseñas, cifras, logos de clientes ni matrículas. Lo que
  falte va como placeholder honesto y a «Lo que falta del cliente» en `HANDOFF.md`.
- Cada vez que hagas algo, actualizá `HANDOFF.md` antes de contarlo: estado, tabla
  del pipeline, pendientes y una línea fechada en «Registro».
- Para capturas, usá `bash "$WC/scripts/capturas.sh" <url o archivo> capturas/<nombre>`.
  Deja una a 1440 y otra a 375. **Mirá cada captura** antes de darla por buena.
- Frená y preguntá antes de cualquier cosa que tenga costo o se publique.

## Subagentes

- Investigación, recolección de datos y fotos, traducciones, extracción de chats,
  descargas y módulos de código repetitivos: lanzalos con `model: "sonnet"`.
- Las 3 direcciones visuales (paso 1), la elección de tipografías (paso 1b) y la
  revisión final de diseño quedan en el modelo por defecto: ahí la calidad es lo
  que se paga.

## 0 · Brief

Si `BRIEF.md` ya tiene datos, no los vuelvas a preguntar. Preguntá con
AskUserQuestion lo que no esté claro, de a 2–4 preguntas:

- Cliente, rubro, a quién le habla y qué tiene que lograr el sitio (turnos,
  ventas, consultas, portfolio).
- Páginas necesarias.
- Material existente: web vieja, Instagram, logo, kit de marca, fotos.
- Integraciones: WhatsApp, turnos, formulario, newsletter, tienda, panel.
- Dominio, DNS y email.

Completá `BRIEF.md` y la tabla «Alcance» de `HANDOFF.md`. Si hay web vieja, guardá un
backup del contenido en `archive/` y anotá qué funciona y qué no antes de
reemplazarla. Dejá alcance, fases y costos en `docs/PLAN.md`. El material del cliente
va en `material/`, que no va al repo.

## 1 · Direcciones visuales — huashu-design

Invocá `huashu-design` (módulo web) con el brief y los assets reales. Tiene que salir
con 3 direcciones de verdad, distintas entre sí, cada una con su HTML completo y
capturas a 1440 y 375.

- Sus comandos usan `$HD`: es la carpeta de ese skill, `$WC/../huashu-design`.
- Lo obligatorio son 3 HTML completos con sus capturas. Lo demás que proponga su
  proceso (candidatos extra, tablero de referencias, subagentes) es opcional.
  `design_lint.py` necesita Playwright de Python: si no está, se saltea solo.
- Pasale el criterio de la casa como restricción, y también la lista de
  `python3 "$WC/scripts/tipografias.py" lista --evitar`: sus recomendaciones de
  fuentes incluyen varias de esa lista. Para las fuentes de cada dirección, partí del
  catálogo (`tipografias.py lista`).
- Para que el cliente elija desde un link: si ya hay deploy, montá un comparador
  en `/demos` con `noindex` y bloqueado en `robots`.
- **Pará acá.** Presentá las 3 y esperá la elección. Guardá cuál eligieron, con
  sus palabras, en `direction-approved.md`.

## 1b · Tipografías

La letra se elige, no sale por defecto. Es lo primero que delata a un sitio hecho con
IA. Leé `$WC/references/tipografia.md` y seguilo.

Si el cliente ya tiene tipografía oficial, usá esa, anotala en `docs/TIPOGRAFIA.md` y
seguí al paso 2.

Si no:

1. Corré `python3 "$WC/scripts/tipografias.py" lista` y elegí 4 opciones que le queden
   al rubro y a la dirección elegida, bien distintas entre sí.
2. Armá la muestra con el texto real del cliente y los colores de la dirección. Nada
   de lorem ipsum:

   ```bash
   python3 "$WC/scripts/tipografias.py" muestra --ids a,b,c,d \
     --cliente "…" --titulo "…" --bajada "…" --parrafo "…" --boton "…" --dato "…" \
     --fondo "#…" --tinta "#…" --acento "#…" --salida design-demos/tipografias.html
   ```

   Si la dirección trae una fuente que no está en el catálogo, sumala con
   `--extra "Título|Texto"`.
3. Sacá las capturas, miralas y presentá las opciones con su letra.
4. **Pará acá.** Preguntá con AskUserQuestion cuál prefiere. El usuario puede elegir
   una, combinar (el título de una con el texto de otra), pedir más opciones, nombrar
   otra fuente de Google Fonts o traer archivos propios. Si elige una de la lista a
   evitar, avisá una vez por qué y respetá lo que decida.
5. Completá `docs/TIPOGRAFIA.md` con lo elegido y sus palabras. Si eligió una de la
   lista a evitar, sumá la línea `Excepción: Familia, motivo`.

Después de esto, nadie cambia la letra: ni las otras skills ni sus valores por defecto.

## 2 · Sistema de diseño — ui-ux-pro-max

Con `ui-ux-pro-max`, pasá la dirección elegida a un sistema:

- Sus comandos dicen `${CLAUDE_PLUGIN_ROOT}/.claude/skills/ui-ux-pro-max/scripts/search.py`.
  Instalado como skill, la ruta es `$WC/../ui-ux-pro-max/scripts/search.py`. Usá
  `python3`.
- Lo que devuelve es una referencia: si choca con la dirección elegida, gana la
  dirección y armás los valores a mano.
- **No tomes fuentes de este skill.** La tipografía ya está elegida.
- Paleta con contraste AA: verificá cada par con
  `python3 "$WC/scripts/contraste.py" "#texto" "#fondo"` (texto ≥ 4.5:1). Si un color
  de marca no alcanza para texto, usalo de relleno o acento y dejalo anotado.
- Escala tipográfica con contraste de verdad, espaciado, radios y sombras.
- Dejá todo en `docs/SISTEMA.md`. Pasa a `app/globals.css` en el paso 3, cuando exista
  el proyecto.

## 3 · Construcción — Next.js

Stack: Next.js (App Router) + TypeScript estricto + Tailwind v4 + pnpm, en Vercel.

1. Corré `bash "$WC/scripts/next-scaffold.sh"`.
2. Aplicá la tipografía: `python3 "$WC/scripts/tipografias.py" codigo <id>` imprime
   `app/fonts.ts`, el cambio en `app/layout.tsx` y el CSS. Sacá las fuentes Geist que
   trae el scaffold. Si eligieron algo fuera del catálogo, usá `--titulo-familia` y
   `--texto-familia`; si son archivos propios, `next/font/local`.
3. Pasá los valores de `docs/SISTEMA.md` a `app/globals.css`, dentro de `@theme`
   (Tailwind v4).

Convenciones:

- Server Components por defecto, `"use client"` solo si hace falta.
- `next/image` y `next/font`, sin librerías de UI, Lighthouse 90+.
- `lib/content.ts` es la única fuente de verdad del contenido: textos, navegación y
  listados. Las páginas leen de ahí.
- Componentes en `components/`; cada página con `generateMetadata`.
- Contenido y fotos reales del cliente en `public/img/`, optimizadas y con `sizes`
  correcto en cada `next/image`. `material/` nunca va a `public/`.
- Formularios con estados de envío, error y éxito, y protección contra spam. Si
  juntan datos personales, hace falta una política de privacidad breve.
- Lo que depende del entorno (dominio, mails, claves) va en variables de entorno. La
  URL del sitio sale siempre de `NEXT_PUBLIC_SITE_URL`, nunca escrita a mano.

## 4 · Pulido — design-taste-frontend + emil-design-eng

Usá `design-taste-frontend` y `emil-design-eng` para microinteracciones, estados
hover/active/focus y animaciones. A `emil-design-eng` pasale un pedido concreto, no lo
invoques en vacío. La dirección elegida manda: si sus valores por defecto chocan con
ella, gana la dirección. Toda animación respeta `prefers-reduced-motion`.

De `design-taste-frontend`, ignorá esto:

- Geist, Outfit o Satoshi: la tipografía ya está elegida.
- `tracking-tighter` en todos lados.
- Framer Motion y Phosphor: sin librerías, salvo que la dirección las justifique.
  Alcanza con CSS.
- Animaciones que no paran nunca y su `MOTION_INTENSITY` de 6: empezá con movimiento
  bajo y subilo solo si la dirección lo pide.

## 5 · Auditoría — impeccable

Corré `impeccable` **solo en modo revisión**: `audit`, y después `polish` o `harden`
según lo que salga. No uses su flujo de diseño nuevo: la dirección ya está elegida. Si
te pide `PRODUCT.md` o `DESIGN.md`, o una entrevista de `init`, no la hagas: armalos con
`BRIEF.md`, `direction-approved.md`, `docs/SISTEMA.md` y `docs/TIPOGRAFIA.md`, sin volver
a preguntarle al usuario. Como mínimo:

- `python3 "$WC/scripts/tipografias.py" chequear .` tiene que dar en orden.
- Revisá lo que delata a un sitio generado, en `$WC/references/tipografia.md`.
- Accesibilidad AA: foco visible, skip link, `aria` en menú y navegación, contraste.
- Responsive a 375 y 1440, con capturas reales.
- Estados vacíos, de carga y de error, con `app/not-found.tsx` y `app/error.tsx` en el
  estilo del sitio.
- Peso de imágenes y de JS de cliente.

## 6 · SEO técnico (obligatorio)

- `metadataBase` y metadata por página; canónicas al dominio final, desde
  `NEXT_PUBLIC_SITE_URL`. Con `localhost` en esa variable, el build no es publicable.
- JSON-LD según el rubro (`LocalBusiness`, `MedicalClinic`, `Restaurant`…). Sin
  `aggregateRating` con puntajes de otros sitios: Google no los acepta.
- `app/sitemap.ts`, `app/robots.ts` y `public/llms.txt`.
- `app/opengraph-image.tsx`: partí de `$WC/references/opengraph-image.tsx`, que carga la
  fuente elegida. Con la fuente por defecto, la imagen al compartir pierde la marca.
- Favicon de marca: `app/icon.svg` y `app/apple-icon.tsx` (se genera con
  `ImageResponse`, igual que la imagen anterior). También `app/manifest.ts`.
- Si reemplaza una web vieja: redirects 301 desde las URLs viejas.
- Analytics y Search Console quedan listos para conectar, y las cuentas van a nombre
  del cliente (pendiente en `HANDOFF.md`).
- Sin herramientas pagas de SEO: alcanza con lo que muestra Google y, con el sitio
  publicado, con Search Console.

## 7 · Publicación

Corré `bash "$WC/scripts/doctor.sh" --publicar`. Después, confirmá con el usuario antes
de crear nada:

- Repo privado en GitHub, en la cuenta de quien está corriendo esto
  (`gh api user --jq .login`) u otra que indique, y proyecto en Vercel conectado, así
  cada push a `main` publica. Antes del primer commit, revisá con `git status` que no
  entre `material/` ni ninguna clave.
- Plan de Vercel: Hobby es solo para uso personal y no comercial. Para un cliente hace
  falta un plan pago. Avisalo y anotá el costo en `docs/PLAN.md`.
- Cargá `NEXT_PUBLIC_SITE_URL` en Vercel, con la URL final, antes del primer deploy.
- Antes de pasar la URL, corré `bash "$WC/scripts/verificar-url.sh" <url>`. Revisa que
  cargue sin login (si no, desactivá la deployment protection), que no quede `localhost`
  en el SEO y que se pueda indexar. Tiene que dar en orden.
- Dominio: dejá anotados los pasos de DNS. **Revisá el email** con `dig MX <dominio>`:
  si no hay MX, va a la lista de pendientes.

## Al cerrar

No des nada por terminado sin haberlo visto renderizado. `HANDOFF.md` tiene que quedar
con lo hecho, las decisiones, los pendientes nuestros y los del cliente.
