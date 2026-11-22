// The web app's manifest (BUILD.md P15.1), so a reader can add Day by Word
// to a phone's home screen or install it from the browser. Its colors are
// Morning's (design/tokens.json) and its icons the owner's own files, as
// design/images/manifest.json lists them (D19): nothing here is drawn or
// chosen apart from the design. It opens on Today, the reader's page.
import tokens from "../../../../design/tokens.json";
import images from "../../../../design/images/manifest.json";

interface Asset {
  file: string;
  width?: number;
  copies?: string[];
}

const webCopies = "web/static";

/** A delivered icon's path on the site, or a failure naming the file. */
function icon(file: string): { src: string; sizes: string; type: string; purpose: string } {
  const asset = (images.assets as Asset[]).find((entry) => entry.file === file);
  const copy = asset?.copies?.find((path) => path.startsWith(`${webCopies}/`));
  if (!asset?.width || !copy)
    throw new Error(`design/images/manifest.json has no web copy of ${file}`);
  // The mark sits well inside the maskable safe zone on an opaque square.
  return {
    src: copy.slice(webCopies.length),
    sizes: `${asset.width}x${asset.width}`,
    type: "image/png",
    purpose: "any maskable",
  };
}

export const GET = () => {
  const manifest = {
    name: "Day by Word",
    short_name: "Day by Word",
    description: "Your Bible reading companion. Find your plan. Read your Bible. Keep your place.",
    lang: "en",
    dir: "ltr",
    id: "/today",
    start_url: "/today",
    scope: "/",
    display: "standalone",
    background_color: tokens.color.background.light,
    theme_color: tokens.color.background.light,
    icons: [icon("web-app-192.png"), icon("web-app-512.png")],
  };
  return new Response(JSON.stringify(manifest, null, 2), {
    headers: { "content-type": "application/manifest+json; charset=utf-8" },
  });
};
