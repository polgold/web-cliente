// Punto de partida para app/opengraph-image.tsx: la imagen que aparece al compartir el
// link, con la fuente elegida en docs/TIPOGRAFIA.md. Reemplazá lo que está en mayúsculas.
//
// ImageResponse tiene dos reglas que traban el build si no se cumplen: un div con más de
// un hijo necesita display: "flex", y las fuentes tienen que ser TTF u OTF (por eso se
// piden acá a Google Fonts, que entrega TTF cuando no ve un navegador moderno).
import { ImageResponse } from "next/og";

const FAMILIA = "FAMILIA DEL TÍTULO"; // por ejemplo, "Barlow Condensed"
const PESO = 700;
const TITULO = "EL TÍTULO DEL SITIO";
const BAJADA = "UNA LÍNEA QUE DIGA QUÉ HACE EL CLIENTE";
const FONDO = "#000000";
const TINTA = "#ffffff";

export const alt = TITULO;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

async function cargarFuente(familia: string, peso: number, texto: string) {
  const css = await fetch(
    `https://fonts.googleapis.com/css2?family=${familia.replace(/ /g, "+")}:wght@${peso}&text=${encodeURIComponent(texto)}`,
  ).then((r) => r.text());
  const url = css.match(/src: url\((.+?)\) format\('(opentype|truetype)'\)/)?.[1];
  if (!url) throw new Error(`Google Fonts no devolvió ${familia} ${peso}`);
  return fetch(url).then((r) => r.arrayBuffer());
}

export default async function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
          padding: 80,
          background: FONDO,
          color: TINTA,
          fontFamily: FAMILIA,
        }}
      >
        <div style={{ fontSize: 120, fontWeight: PESO, lineHeight: 1 }}>{TITULO}</div>
        <div style={{ fontSize: 40, marginTop: 24 }}>{BAJADA}</div>
      </div>
    ),
    {
      ...size,
      fonts: [
        {
          name: FAMILIA,
          data: await cargarFuente(FAMILIA, PESO, TITULO + BAJADA),
          weight: PESO,
          style: "normal",
        },
      ],
    },
  );
}
