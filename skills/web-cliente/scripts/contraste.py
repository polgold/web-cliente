#!/usr/bin/env python3
"""Mide el contraste entre dos colores según WCAG.

  contraste.py "#texto" "#fondo"            texto normal: pide 4.5:1
  contraste.py "#texto" "#fondo" --grande   títulos grandes: pide 3:1

Sale con 1 si no alcanza.
"""
import argparse
import re
import sys


def canal(valor):
    valor /= 255
    return valor / 12.92 if valor <= 0.03928 else ((valor + 0.055) / 1.055) ** 2.4


def luminancia(color):
    crudo = color.lstrip("#")
    if len(crudo) == 3:
        crudo = "".join(c * 2 for c in crudo)
    if not re.fullmatch(r"[0-9a-fA-F]{6}", crudo):
        sys.exit(f"«{color}» no es un color válido. Usá el formato #rrggbb.")
    r, g, b = (canal(int(crudo[i:i + 2], 16)) for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def main():
    p = argparse.ArgumentParser(description="Contraste WCAG entre dos colores")
    p.add_argument("texto")
    p.add_argument("fondo")
    p.add_argument("--grande", action="store_true", help="Texto grande: alcanza con 3:1")
    args = p.parse_args()

    claro, oscuro = sorted((luminancia(args.texto), luminancia(args.fondo)), reverse=True)
    relacion = (claro + 0.05) / (oscuro + 0.05)
    minimo = 3 if args.grande else 4.5
    if relacion >= minimo:
        print(f"✓ {relacion:.2f}:1 (pide {minimo}:1)")
        return
    print(f"✗ {relacion:.2f}:1 (pide {minimo}:1)")
    sys.exit(1)


if __name__ == "__main__":
    main()
