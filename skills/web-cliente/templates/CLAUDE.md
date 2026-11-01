# {{CLIENTE}}

Web de {{CLIENTE}}. Se construye con `/web-cliente`.

## Handoff

- Al arrancar cualquier sesión, leé `HANDOFF.md` antes que nada.
- **Cada vez que hagamos algo** (una tarea, un cambio, una decisión, algo que mandó el cliente, un deploy), actualizá `HANDOFF.md` en ese momento, antes de contarlo. No lo dejes para el cierre de la sesión.
- Corregí el estado y los pendientes en su lugar y sumá una línea fechada a «Registro». Lo resuelto sale de los pendientes.
- Un hook de `Stop` frena el cierre del turno si hay archivos más nuevos que `HANDOFF.md`. Solo ve archivos: las decisiones y lo que pasa afuera del repo (Vercel, DNS, mails) los tenés que anotar igual.

## Next.js

@AGENTS.md

## Claves

- Las claves de las cuentas del cliente (mail, redes, reservas) van solo en `.env`, que git ignora. No las copies a otros archivos, commits, memoria ni variables de Vercel.
- Las API keys que usa el sitio van en `.env` y en las variables de entorno de Vercel. El prefijo `NEXT_PUBLIC_` publica el valor: usalo solo con datos que puedan ser públicos.
- Si hace falta entrar a una cuenta del cliente, entra una persona, no Claude.

## Material del cliente

`material/` tiene lo que manda el cliente tal como llega, y no va al repo. Al sitio pasan solo las fotos elegidas y optimizadas, a `public/img/`.

## Antes de actuar afuera

Frená y preguntá antes de crear un repo, un proyecto, una base de datos o una cuenta, de comprar un dominio y de cualquier cosa que tenga costo o se publique.
