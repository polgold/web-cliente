#!/usr/bin/env python3
"""Tipografías de /web-cliente: catálogo, muestras para elegir, código y control.

  tipografias.py lista [--evitar]
  tipografias.py muestra --ids a,b,c,d --cliente X --titulo X --bajada X --parrafo X
                         --boton X --dato X [--fondo #..] [--tinta #..] [--acento #..]
                         [--extra "Título|Texto"] [--salida design-demos/tipografias.html]
  tipografias.py codigo <id>
  tipografias.py codigo --titulo-familia X --texto-familia Y [--peso-titulo 700] [--ancho-titulo 125]
  tipografias.py chequear [carpeta]
  tipografias.py verificar

Solo usa la biblioteca estándar de Python.
"""
import argparse
import html
import json
import re
import sys
import urllib.request
from pathlib import Path

CATALOGO = Path(__file__).resolve().parent.parent / "references" / "tipografias.json"
CSS_GOOGLE = "https://fonts.googleapis.com/css2"
METADATA_GOOGLE = "https://fonts.google.com/metadata/fonts"
EXTENSIONES = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".css", ".scss", ".html"}
NO_REVISAR = {".claude", "node_modules", ".next", ".git", ".vercel", "design-demos", "archive", "material"}


def catalogo():
    return json.loads(CATALOGO.read_text(encoding="utf8"))


_metadata = None


def metadata_google():
    """Datos de todas las familias de Google Fonts. Se piden una sola vez por corrida."""
    global _metadata
    if _metadata is None:
        pedido = urllib.request.Request(METADATA_GOOGLE, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(pedido, timeout=60) as r:
            crudo = r.read().decode("utf8")
        lista = json.loads(crudo[crudo.index("{"):])["familyMetadataList"]
        _metadata = {f["family"]: f for f in lista}
    return _metadata


def info_desde_google(familia):
    f = metadata_google().get(familia)
    if not f:
        sys.exit(f"«{familia}» no existe en Google Fonts. Revisá el nombre, o usá next/font/local si son archivos propios.")
    if "latin" not in f["subsets"]:
        sys.exit(f"«{familia}» no tiene caracteres latinos: no sirve para un sitio en español.")
    ejes = {a["tag"]: (int(a["min"]), int(a["max"])) for a in f.get("axes") or []}
    info = {"next": familia.replace(" ", "_"), "por": ", ".join(f["designers"]), "categoria": f["category"], "argentina": False}
    if "wght" in ejes:
        info["wght"] = list(ejes["wght"])
    else:
        info["pesos"] = sorted({int(k[:3]) for k in f["fonts"] if k.isdigit()})
    if "wdth" in ejes:
        info["wdth"] = list(ejes["wdth"])
    return info


def info_familia(cat, familia):
    return cat["familias"].get(familia) or info_desde_google(familia)


def avisar_si_evitar(cat, familia):
    for e in cat["evitar"]:
        if e["familia"] == familia:
            print(f"Aviso: {familia} está en la lista a evitar. {e['motivo']}.", file=sys.stderr)


def buscar_opcion(cat, id_):
    for op in cat["opciones"]:
        if op["id"] == id_:
            return op
    sys.exit(f"No existe la opción «{id_}». Mirá las disponibles con: tipografias.py lista")


def opcion_libre(cat, titulo, texto, peso_titulo=None, ancho_titulo=None):
    """Arma una opción con familias que no están en el catálogo."""
    for familia in {titulo, texto}:
        avisar_si_evitar(cat, familia)
    return {
        "id": "elegida",
        "nombre": titulo if titulo == texto else f"{titulo} + {texto}",
        "titulo": {"familia": titulo, "peso": peso_titulo or peso_cercano(info_familia(cat, titulo), 700), "ancho": ancho_titulo, "tracking": "-0.01em"},
        "texto": {"familia": texto, "peso": peso_cercano(info_familia(cat, texto), 400), "ancho": None},
        "caracter": "A pedido",
        "rubros": "",
        "notas": "",
    }


def peso_cercano(info, deseado):
    if "wght" in info:
        return max(info["wght"][0], min(info["wght"][1], deseado))
    return min(info["pesos"], key=lambda p: abs(p - deseado))


# ---- lista ------------------------------------------------------------------


def cmd_lista(args):
    cat = catalogo()
    if args.evitar:
        print("Fuentes a evitar, salvo que sean la marca del cliente o el usuario las pida:\n")
        for e in cat["evitar"]:
            print(f"  {e['familia']:<22} {e['motivo']}")
        return
    for op in cat["opciones"]:
        origen = ""
        familias = {op["titulo"]["familia"], op["texto"]["familia"]}
        if any(cat["familias"][f].get("argentina") for f in familias):
            origen = "  [fundición nacida en Argentina]"
        print(f"{op['id']}{origen}")
        print(f"  {op['caracter']}. Título: {op['titulo']['familia']} {op['titulo']['peso']}. Texto: {op['texto']['familia']} {op['texto']['peso']}.")
        print(f"  Para: {op['rubros']}.")
        print(f"  {op['notas']}\n")


# ---- muestra ----------------------------------------------------------------


def url_familia(familia, info):
    nombre = familia.replace(" ", "+")
    if "wght" in info and "wdth" in info:
        return f"{CSS_GOOGLE}?family={nombre}:wdth,wght@{info['wdth'][0]}..{info['wdth'][1]},{info['wght'][0]}..{info['wght'][1]}&display=swap"
    if "wght" in info:
        return f"{CSS_GOOGLE}?family={nombre}:wght@{info['wght'][0]}..{info['wght'][1]}&display=swap"
    return f"{CSS_GOOGLE}?family={nombre}:wght@{';'.join(str(p) for p in info['pesos'])}&display=swap"


def luminancia(color):
    color = color.lstrip("#")
    if len(color) == 3:
        color = "".join(c * 2 for c in color)
    canales = [int(color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    r, g, b = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in canales]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contraste(a, b):
    la, lb = sorted((luminancia(a), luminancia(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def estilo(parte):
    reglas = [f"font-family:'{parte['familia']}',sans-serif", f"font-weight:{parte['peso']}"]
    if parte.get("ancho"):
        reglas.append(f"font-stretch:{parte['ancho']}%")
    if parte.get("tracking"):
        reglas.append(f"letter-spacing:{parte['tracking']}")
    return ";".join(reglas)


def cmd_muestra(args):
    cat = catalogo()
    opciones = [buscar_opcion(cat, i.strip()) for i in args.ids.split(",") if i.strip()]
    for extra in args.extra or []:
        titulo, _, texto = extra.partition("|")
        opciones.append(opcion_libre(cat, titulo.strip(), (texto or titulo).strip()))
    if not opciones:
        sys.exit("Pasá al menos una opción con --ids o --extra.")

    familias = {}
    for op in opciones:
        for parte in (op["titulo"], op["texto"]):
            familias[parte["familia"]] = info_familia(cat, parte["familia"])
    enlaces = "\n".join(f'<link rel="stylesheet" href="{html.escape(url_familia(f, i))}">' for f, i in familias.items())

    sobre_acento = max((args.fondo, args.tinta), key=lambda c: contraste(c, args.acento))
    e = html.escape
    secciones = []
    for letra, op in zip("ABCDEFGHIJ", opciones):
        ficha = f"Título: {op['titulo']['familia']} {op['titulo']['peso']}"
        ficha += f" · Texto: {op['texto']['familia']} {op['texto']['peso']}"
        secciones.append(f"""<section class="op">
  <div class="rot"><b>{letra}</b><span class="nom">{e(op['caracter'])}</span><span class="fic">{e(ficha)}</span></div>
  <h2 style="{e(estilo(op['titulo']))}">{e(args.titulo)}</h2>
  <div style="{e(estilo(op['texto']))}">
    <p class="baj">{e(args.bajada)}</p>
    <p class="par">{e(args.parrafo)}</p>
    <div class="fila"><a class="bot" href="#" style="font-family:inherit">{e(args.boton)}</a><span class="dat">{e(args.dato)}</span></div>
    <p class="gli">Año, niño, acción, ¿cuándo? ¡Sí! Información útil. 0123456789</p>
  </div>
</section>""")

    pagina = f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex">
<title>Tipografías · {e(args.cliente)}</title>
{enlaces}
<style>
:root{{--fondo:{e(args.fondo)};--tinta:{e(args.tinta)};--acento:{e(args.acento)};--sobre-acento:{e(sobre_acento)}}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--fondo);color:var(--tinta);font:16px/1.5 system-ui,-apple-system,sans-serif}}
header{{padding:32px clamp(16px,6vw,96px) 24px;font-size:15px}}
header strong{{display:block;font-size:20px;font-weight:600}}
.op{{padding:clamp(32px,6vw,88px) clamp(16px,6vw,96px);border-top:1px solid color-mix(in srgb,var(--tinta) 20%,transparent)}}
.rot{{display:flex;flex-wrap:wrap;align-items:baseline;gap:4px 14px;margin-bottom:clamp(20px,3vw,40px);font:400 14px/1.4 system-ui,-apple-system,sans-serif}}
.rot b{{font-size:22px;font-weight:700}}
.rot .nom{{font-weight:600;font-size:15px}}
.rot .fic{{opacity:.75}}
h2{{margin:0;font-size:clamp(2.25rem,7.5vw,5.75rem);line-height:1.04;overflow-wrap:break-word;text-wrap:balance;max-width:20ch}}
.baj{{margin:.8em 0 0;font-size:clamp(1.15rem,2.1vw,1.5rem);line-height:1.35;max-width:40ch}}
.par{{margin:1.25em 0 0;font-size:17px;line-height:1.6;max-width:62ch}}
.fila{{display:flex;flex-wrap:wrap;align-items:center;gap:14px 26px;margin-top:26px}}
.bot{{display:inline-block;padding:14px 24px;background:var(--acento);color:var(--sobre-acento);border-radius:4px;font-size:16px;font-weight:600;text-decoration:none}}
.dat{{font-size:17px}}
.gli{{margin:22px 0 0;font-size:15px;opacity:.75}}
</style>
</head>
<body>
<header><strong>Tipografías para {e(args.cliente)}</strong>Mismo texto y mismos colores en todas. Solo cambia la letra.</header>
{chr(10).join(secciones)}
</body>
</html>
"""
    salida = Path(args.salida)
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(pagina, encoding="utf8")
    print(f"Muestra lista: {salida}")
    for letra, op in zip("ABCDEFGHIJ", opciones):
        print(f"  {letra}. {op['id']}: {op['caracter']}")


# ---- codigo -----------------------------------------------------------------


def instancia(const, familia, info, variable, parte, otros_pesos):
    lineas = [f"export const {const} = {info['next']}({{", '  subsets: ["latin"],']
    if "wght" not in info:
        pedidos = sorted(({parte["peso"]} | {p for p in otros_pesos if p in info["pesos"]}))
        lineas.append(f"  weight: [{', '.join(json.dumps(str(p)) for p in pedidos)}],")
    if "wdth" in info:
        lineas.append('  axes: ["wdth"],')
    lineas += [f'  variable: "{variable}",', '  display: "swap",', "});"]
    return "\n".join(lineas)


def cmd_codigo(args):
    cat = catalogo()
    if args.id:
        op = buscar_opcion(cat, args.id)
    elif args.titulo_familia:
        op = opcion_libre(cat, args.titulo_familia, args.texto_familia or args.titulo_familia, args.peso_titulo, args.ancho_titulo)
    else:
        sys.exit("Pasá un id del catálogo, o --titulo-familia y --texto-familia.")

    t, x = op["titulo"], op["texto"]
    info_t, info_x = info_familia(cat, t["familia"]), info_familia(cat, x["familia"])
    misma = t["familia"] == x["familia"]

    if misma:
        imports = info_x["next"]
        cuerpo = instancia("fontTexto", x["familia"], info_x, "--font-texto", x, {400, 500, 600, 700, t["peso"]})
        clases = "fontTexto.variable"
        var_titulo = "var(--font-texto)"
    else:
        imports = f"{info_t['next']}, {info_x['next']}"
        cuerpo = instancia("fontTitulo", t["familia"], info_t, "--font-titulo", t, {t["peso"]})
        cuerpo += "\n\n" + instancia("fontTexto", x["familia"], info_x, "--font-texto", x, {400, 500, 600, 700})
        clases = "fontTitulo.variable, fontTexto.variable"
        var_titulo = "var(--font-titulo)"

    titulo_css = [f"font-family: var(--font-display);", f"font-weight: {t['peso']};"]
    if t.get("ancho"):
        titulo_css.append(f"font-stretch: {t['ancho']}%;")
    if t.get("tracking"):
        titulo_css.append(f"letter-spacing: {t['tracking']};")
    titulo_css = "\n    ".join(titulo_css)

    usa_clases = "fontTexto.variable" if misma else "`${fontTitulo.variable} ${fontTexto.variable}`"
    print(f"""// app/fonts.ts
import {{ {imports} }} from "next/font/google";

{cuerpo}

// app/layout.tsx: reemplazá las fuentes del scaffold (Geist) por estas
import {{ {clases.replace('.variable', '')} }} from "./fonts";
// <html lang="es" className={{{usa_clases}}}>

/* app/globals.css */
@theme inline {{
  --font-sans: var(--font-texto);
  --font-display: {var_titulo};
}}

@layer base {{
  body {{ font-family: var(--font-texto); }}
  h1, h2, h3 {{
    {titulo_css}
  }}
}}""")


# ---- chequear ---------------------------------------------------------------

IMPORT_GOOGLE = re.compile(r"import\s*\{([^}]*)\}\s*from\s*[\"']next/font/google[\"']", re.S)
LINEA_FUENTE = re.compile(r"font-family|fontFamily|fonts\.googleapis|--font-", re.I)


def excepciones_y_elegidas(raiz):
    doc = raiz / "docs" / "TIPOGRAFIA.md"
    if not doc.exists():
        return None, ""
    texto = doc.read_text(encoding="utf8")
    excepciones = "\n".join(l for l in texto.splitlines() if l.lower().startswith(("excepción:", "excepciones:")))
    return texto, excepciones


def cmd_chequear(args):
    cat = catalogo()
    raiz = Path(args.carpeta).resolve()
    doc, excepciones = excepciones_y_elegidas(raiz)
    evitar = {e["familia"]: e["motivo"] for e in cat["evitar"]}
    problemas = []
    importadas = set()

    for archivo in sorted(raiz.rglob("*")):
        if not archivo.is_file() or archivo.suffix not in EXTENSIONES:
            continue
        if NO_REVISAR & set(archivo.relative_to(raiz).parts):
            continue
        texto = archivo.read_text(encoding="utf8", errors="ignore")
        rel = archivo.relative_to(raiz)
        encontradas = set()
        for bloque in IMPORT_GOOGLE.findall(texto):
            for nombre in bloque.split(","):
                nombre = nombre.split(" as ")[0].strip().replace("_", " ")
                if nombre:
                    encontradas.add(nombre)
                    importadas.add(nombre)
        for linea in texto.splitlines():
            if LINEA_FUENTE.search(linea):
                limpia = linea.replace("+", " ")
                for familia in evitar:
                    if re.search(rf"(?<![\w-]){re.escape(familia)}(?![\w-])", limpia):
                        encontradas.add(familia)
        for familia in sorted(encontradas & set(evitar)):
            if familia not in excepciones:
                problemas.append(f"{rel}: usa {familia}. {evitar[familia]}.")

    if doc is None:
        problemas.append("Falta docs/TIPOGRAFIA.md: no quedó registrada la elección.")
    else:
        for familia in sorted(importadas):
            if familia not in doc:
                problemas.append(f"{familia} está en el código pero no en docs/TIPOGRAFIA.md: no es la que se eligió.")

    if importadas:
        print("Fuentes en el código: " + ", ".join(sorted(importadas)))
    if problemas:
        print("\nHay que corregir esto:")
        for p in problemas:
            print(f"  ✗ {p}")
        print("\nSi el cliente la pidió de verdad, anotalo en docs/TIPOGRAFIA.md con una línea «Excepción: Familia, motivo».")
        sys.exit(1)
    print("Tipografía en orden.")


# ---- verificar --------------------------------------------------------------


def cmd_verificar(_args):
    cat = catalogo()
    errores = []
    for familia in cat["familias"]:
        f = metadata_google().get(familia)
        if not f:
            errores.append(f"{familia}: ya no está en Google Fonts")
        elif "latin" not in f["subsets"]:
            errores.append(f"{familia}: sin caracteres latinos")
    evitar = {e["familia"] for e in cat["evitar"]}
    for op in cat["opciones"]:
        for parte in (op["titulo"], op["texto"]):
            info = cat["familias"].get(parte["familia"])
            if parte["familia"] in evitar:
                errores.append(f"{op['id']}: {parte['familia']} está en la lista a evitar")
            elif not info:
                errores.append(f"{op['id']}: {parte['familia']} no está en familias")
            elif "wght" in info and not info["wght"][0] <= parte["peso"] <= info["wght"][1]:
                errores.append(f"{op['id']}: {parte['familia']} no llega a peso {parte['peso']}")
            elif "pesos" in info and parte["peso"] not in info["pesos"]:
                errores.append(f"{op['id']}: {parte['familia']} no tiene peso {parte['peso']}")
    if errores:
        for x in errores:
            print(f"  ✗ {x}")
        sys.exit(1)
    print(f"Catálogo en orden: {len(cat['opciones'])} opciones, {len(cat['familias'])} familias.")


def main():
    p = argparse.ArgumentParser(description="Tipografías de /web-cliente")
    sub = p.add_subparsers(dest="comando", required=True)

    s = sub.add_parser("lista", help="Muestra el catálogo")
    s.add_argument("--evitar", action="store_true", help="Muestra las fuentes a evitar")
    s.set_defaults(fn=cmd_lista)

    s = sub.add_parser("muestra", help="Arma la página para comparar opciones")
    s.add_argument("--ids", default="")
    s.add_argument("--extra", action="append", help="Otra opción: 'Familia título|Familia texto'")
    for campo in ("cliente", "titulo", "bajada", "parrafo", "boton", "dato"):
        s.add_argument(f"--{campo}", required=True)
    s.add_argument("--fondo", default="#f6f4ee")
    s.add_argument("--tinta", default="#1c1c1a")
    s.add_argument("--acento", default="#1c1c1a")
    s.add_argument("--salida", default="design-demos/tipografias.html")
    s.set_defaults(fn=cmd_muestra)

    s = sub.add_parser("codigo", help="Imprime el código para aplicar una opción en Next.js")
    s.add_argument("id", nargs="?")
    s.add_argument("--titulo-familia")
    s.add_argument("--texto-familia")
    s.add_argument("--peso-titulo", type=int)
    s.add_argument("--ancho-titulo", type=int)
    s.set_defaults(fn=cmd_codigo)

    s = sub.add_parser("chequear", help="Revisa que el proyecto use la tipografía elegida")
    s.add_argument("carpeta", nargs="?", default=".")
    s.set_defaults(fn=cmd_chequear)

    s = sub.add_parser("verificar", help="Compara el catálogo con Google Fonts")
    s.set_defaults(fn=cmd_verificar)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
