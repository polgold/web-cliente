# web-cliente

Un comando para [Claude Code](https://claude.com/claude-code) que hace el sitio de un cliente desde cero: del brief a la web publicada. Escribís `/web-cliente`, le contás de qué se trata y Claude lo arma paso a paso. Vos elegís el diseño y la letra.

El resultado es un sitio en Next.js, hecho a medida, publicado en Vercel.

## Qué hace

| Paso | Qué pasa | ¿Te frena para elegir? |
|---|---|---|
| 0. Brief | Te pregunta lo que falte: cliente, páginas, material, dominio | Te hace preguntas |
| 1. Direcciones | Arma 3 diseños bien distintos, con capturas | **Sí** |
| 1b. Tipografías | Te muestra 4 opciones con el texto real del cliente | **Sí** |
| 2. Sistema de diseño | Paleta con contraste verificado, escalas y tokens | No |
| 3. Construcción | El sitio en Next.js | No |
| 4. Pulido | Microinteracciones y estados | No |
| 5. Auditoría | Accesibilidad, celular, peso, errores | No |
| 6. SEO | Metadata, datos estructurados, sitemap, `llms.txt` | No |
| 7. Publicación | Repo en GitHub y proyecto en Vercel | **Sí**: confirma antes de crear nada |

### Tipografías: para que no parezca hecho con IA

La letra es lo primero que delata a un sitio generado, así que acá se elige:

- **Catálogo de 20 opciones** pensadas por rubro, ninguna de las típicas. Varias son de fundiciones nacidas en Argentina, como Omnibus-Type y HT Fonts.
- **Muestra para comparar:** una página con el texto y los colores del cliente, donde lo único que cambia es la letra. Le podés pasar el link al cliente.
- **Lista de 39 fuentes a evitar** (Inter, Geist, Poppins, Playfair, Space Grotesk y compañía). Si el cliente quiere una igual, se usa: Claude avisa una vez y lo respeta.
- **Control automático:** antes de terminar, revisa que el código use la letra elegida y no la que trae Next por defecto.

También podés nombrar cualquier fuente de Google Fonts o traer archivos propios.

## Qué necesitás

- **Claude Code** con una cuenta paga. En una prueba con un sitio de 3 páginas, sin fotos y sin idas y vueltas, el trabajo de Claude llevó unos 10 minutos y unos 270.000 tokens nuevos. Un proyecto real, con correcciones, consume bastante más.
- **Mac.** Es donde está probado. En Linux debería andar, y en Windows hace falta WSL, pero ninguno de los dos se probó.
- **Node 20 o más, pnpm, Python 3 y git.**
- **Para publicar:** cuentas de GitHub y Vercel, con sus programas (`gh` y `vercel`). Vercel Hobby es solo para uso personal y no comercial: para el sitio de un cliente hace falta un plan pago.

No hace falta tenerlo todo antes: el instalador te dice qué falta y con qué comando se instala.

## Instalación

```bash
git clone https://github.com/polgold/web-cliente.git
cd web-cliente
./install.sh
```

Instala `/web-cliente` y las 5 skills que usa en `~/.claude/skills`. No agrega nada más, y si ya tenés una skill con el mismo nombre, la deja como está y te avisa. Para usar igual las versiones probadas, `./install.sh --reemplazar` las cambia y guarda una copia de las anteriores.

Si Claude Code estaba abierto, reinicialo.

## Uso

Abrí Claude Code en una carpeta nueva:

```bash
mkdir la-espiga && cd la-espiga && claude
```

Y escribí qué querés hacer:

```
/web-cliente Panadería La Espiga, Villa Ejemplo, Córdoba
```

Claude prepara la carpeta y arranca con el brief. Si ya tenés los datos, completá `BRIEF.md` y no te los vuelve a preguntar. Lo que mande el cliente (fotos, logo, textos) va en `material/`, que no se sube al repo.

### Retomar otro día

Abrí Claude Code en la misma carpeta y volvé a escribir `/web-cliente`. Toda la información queda en `HANDOFF.md`: qué se hizo, qué se decidió y qué falta. Se actualiza solo a medida que se trabaja.

### Cambios sobre un sitio terminado

Usá `/impeccable` directo. `/web-cliente` es para hacerlo desde cero.

## Lo que queda en la carpeta del proyecto

| Archivo | Para qué |
|---|---|
| `HANDOFF.md` | Estado vivo del proyecto. Lo primero que se lee en cada sesión |
| `BRIEF.md` | Lo que pidió el cliente |
| `CLAUDE.md` | Reglas para Claude: handoff, claves, qué preguntar antes de actuar |
| `docs/PLAN.md` | Alcance, fases y costo mensual de cada servicio |
| `docs/TIPOGRAFIA.md` | La letra elegida y quién la eligió |
| `direction-approved.md` | La dirección visual elegida |
| `design-demos/` | Las 3 direcciones y la muestra de tipografías |
| `material/` | Lo que manda el cliente. No va al repo |
| `.env` | Claves. No va al repo |

## Adaptarlo a tu gusto

Todo lo de la casa está en `skills/web-cliente`. Cambiá lo que quieras y volvé a correr `./install.sh`.

- **Criterio de diseño:** por defecto usa una sola sans con carácter y evita serif con itálicas. Está en «Reglas para todo el pipeline», en `SKILL.md`.
- **Idioma:** los textos salen en español rioplatense, salvo que el cliente pida otra cosa. También está en esas reglas.
- **Catálogo de tipografías:** `references/tipografias.json`. Corré `tipografias.py verificar` después de tocarlo.

## Actualizar y desinstalar

```bash
git pull && ./install.sh   # actualizar
./uninstall.sh             # sacar lo que instaló; lo demás queda
```

Las skills de terceros están fijadas a un commit en `skills.lock`, así todos usan la misma versión. Si la cambiás, probala con `tests/smoke.sh --con-build`, que corre en un HOME vacío y no toca tu instalación.

## Si algo falla

| Qué pasa | Qué hacer |
|---|---|
| `/web-cliente` no aparece | Reiniciá Claude Code. Fijate que exista `~/.claude/skills/web-cliente/SKILL.md` |
| Falta un programa | `bash ~/.claude/skills/web-cliente/scripts/doctor.sh` te dice cuál y cómo instalarlo |
| Las capturas tardan la primera vez | Es normal: baja un navegador de unos 150 MB |
| `gh` o `vercel` piden login | `gh auth login` y `vercel login`. Lo hacés vos, en tu terminal |

## Créditos

Este repo es la receta. El trabajo pesado lo hacen estas skills, que se bajan de su repo original, sin copias:

| Skill | Autor | Licencia |
|---|---|---|
| [huashu-design](https://github.com/alchaincyf/huashu-design) | alchaincyf | MIT |
| [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | nextlevelbuilder | MIT |
| [design-taste-frontend](https://github.com/Leonxlnx/taste-skill) | Leonxlnx | MIT |
| [emil-design-eng](https://github.com/emilkowalski/skill) | Emil Kowalski | MIT |
| [impeccable](https://github.com/pbakaus/impeccable) | Paul Bakaus | Apache 2.0 |

Lo propio de este repo tiene licencia [MIT](LICENSE). Las tipografías del catálogo son de Google Fonts, cada una con su licencia libre.
