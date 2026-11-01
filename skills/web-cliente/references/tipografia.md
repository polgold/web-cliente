# Tipografía: cómo no hacer un sitio con cara de IA

La letra es lo primero que delata a un sitio generado. No alcanza con cambiar de
fuente: también cuenta cómo se usa.

## Cómo elegir las opciones que le mostrás al usuario

Corré `tipografias.py lista` y elegí 4 opciones del catálogo:

- **Que le queden al rubro y a la dirección elegida.** Pensá en un objeto del mundo
  del cliente (el cartel del local, un menú, un diario del pueblo), no en un adjetivo.
- **Que sean distintas entre sí.** Cuatro grotescas parecidas no son una elección.
  Mezclá al menos una sans de una sola familia (el criterio de la casa) y una con
  otro carácter.
- **Que se lean.** El texto corrido tiene que leerse cómodo a 16 px en un celular.
  Si el público es mayor o el rubro es salud, incluí `atkinson-accesible`.
- **Que no se repitan entre proyectos.** Si ya usaste una en el último sitio, buscá otra.

Si la dirección elegida usa una fuente que le gustó al usuario, sumala como opción con
`--extra`. Si está en la lista a evitar, avisalo una vez y respetá lo que decida.

## Lo que delata a un sitio generado

Evitá esto aunque la fuente sea buena:

- Una palabra del título en serif itálica dentro de un título en sans.
- Una etiquetita en mayúsculas con mucho espaciado arriba de cada título.
- Texto con degradé.
- Todo en peso 400 y 600, sin contraste de verdad entre títulos y texto.
- `tracking-tight` en todos lados, incluso en letra chica.
- Títulos del mismo tamaño en todas las secciones.
- Números y precios en monoespaciada cuando el sitio no es técnico.
- Cuatro familias en una misma página. Con una o dos alcanza.

## Lo que da carácter

- **Contraste de escala:** un título que se anima a ser grande, junto a un texto
  tranquilo. En `app/globals.css`, la escala tiene que notarse a simple vista.
- **Contraste de peso o de ancho:** las familias con eje de ancho (`Archivo`,
  `Encode Sans`) hacen jerarquía sin sumar otra fuente.
- **Detalles de español:** comillas «», rayas de diálogo y signos de apertura ¿ ¡ que
  se vean bien. Títulos con `text-wrap: balance` y sin cortar palabras: `hyphens: auto`
  solo en texto corrido de columnas angostas, con `lang="es"`.

## Fuera del catálogo

- **Otra de Google Fonts:** cualquiera sirve. `tipografias.py muestra --extra "Título|Texto"`
  y `tipografias.py codigo --titulo-familia X --texto-familia Y` validan que exista y
  que tenga caracteres latinos.
- **Archivos propios o de marca:** van en `app/fonts/` con `next/font/local`. Antes,
  confirmá que la licencia permita usarlas en la web y anotalo en `docs/TIPOGRAFIA.md`.
- **Fontshare y otras fuentes gratis:** bajá los archivos y usá `next/font/local`.
  Revisá la licencia de cada una.
