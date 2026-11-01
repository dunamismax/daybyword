# Morning artwork

The owner requested this initial artwork batch on 2026-11-01 (BUILD.md
D19, P2.3). These are the canonical finished files. They follow the
Morning palette and avoid Bible text, religious figures, denominational
symbols, and publisher branding. No source scans, publisher artwork, or
third-party image references were used. The work does not imply any
publisher's endorsement or permission to publish a plan.

The exact production specifications are in [prompts.json](prompts.json).
[manifest.json](manifest.json) records each file's dimensions, size,
checksum, purpose, and runtime copies. The repository's LICENSE applies;
these files are not a license for a plan schedule or other source material.

## Identity

| File | Format and size | Use |
|---|---|---|
| [app-icon.png](app-icon.png) | Opaque PNG, 1024 × 1024 | Primary iOS icon; no pre-applied corner mask |
| [app-icon-dark.png](app-icon-dark.png) | Transparent PNG, 1024 × 1024 | Dawn foreground on the system's dark icon background |
| [app-icon-tinted.png](app-icon-tinted.png) | Grayscale PNG, 1024 × 1024 | System-tinted iOS appearance |
| [mark.svg](mark.svg) | Single-color SVG, square viewBox | Header mark, using `currentColor` |
| [mark.png](mark.png) | Transparent black PNG, 1024 × 1024 | Raster source for the mark's contour |
| [favicon-32.png](favicon-32.png) | Opaque PNG, 32 × 32 | Browser tab |
| [favicon.ico](favicon.ico) | ICO, 16 and 32 px | Browser fallback at `/favicon.ico` |
| [apple-touch-icon.png](apple-touch-icon.png) | Opaque PNG, 180 × 180 | Apple web shortcut |
| [web-app-192.png](web-app-192.png) | Opaque PNG, 192 × 192 | Installable web app |
| [web-app-512.png](web-app-512.png) | Opaque PNG, 512 × 512 | Installable web app, with maskable safe-zone padding |
| [share.png](share.png) | Opaque PNG, 1200 × 630 | Homepage social preview |

The sunrise and open-page silhouette are one identity. The SVG is a
contour trace of the raster mark, with no embedded image or external
resource. Inline SVG inherits `currentColor`; an SVG loaded through an
`img` element does not inherit the surrounding page's color. Use the
inline mark or a CSS mask when it must follow the appearance. Keep the
visible header name as accessible system-font text rather than an image.

The share image contains only the name and the product line: “Find your
plan. Read your Bible. Keep your place.” It contains no product screenshot
or claim that unfinished features are available.

## Plan covers

Every cover is a 1600 × 900 JPEG under 300,000 bytes. These are decorative,
not historical illustrations or depictions of biblical events. Use empty
alternative text beside a visible plan title. A title must remain real
text and must not rely on an illustration to identify the plan.

File slugs are provisional until catalog IDs are established in P4.2.
Map them deliberately when the catalog lands; do not silently infer IDs
from a plan title. Artwork availability never opens a plan's rights or
editorial gate.

| File | Planned plan | Motif |
|---|---|---|
| [gospels-at-your-pace.jpg](plans/gospels-at-your-pace.jpg) | Gospels at your pace | Four paths toward dawn |
| [bible-in-a-year.jpg](plans/bible-in-a-year.jpg) | The Bible in a year | Layered landscape |
| [bible-in-a-year-five-days.jpg](plans/bible-in-a-year-five-days.jpg) | The Bible in a year, five days a week | Five spaced stepping forms |
| [new-testament-in-a-year-five-days.jpg](plans/new-testament-in-a-year-five-days.jpg) | The New Testament in a year, five days a week | Five opening page forms |
| [story-of-scripture.jpg](plans/story-of-scripture.jpg) | The Story of Scripture | One winding line through a landscape |
| [psalm-a-day.jpg](plans/psalm-a-day.jpg) | A psalm a day | Quiet morning water |
| [proverbs-through-the-month.jpg](plans/proverbs-through-the-month.jpg) | Proverbs through the month | Pale branches with one warm leaf |
| [pauls-letters.jpg](plans/pauls-letters.jpg) | Paul's letters | Unmarked folded paper toward morning light |
| [deuterocanonical-books.jpg](plans/deuterocanonical-books.jpg) | The deuterocanonical books | Upright page forms of equal visual weight |
| [mcheyne-1842.jpg](plans/mcheyne-1842.jpg) | M'Cheyne's Calendar for Daily Readings (1842) | Four paired ribbons |
| [daily-office-1979.jpg](plans/daily-office-1979.jpg) | The 1979 Daily Office Lectionary | Morning and evening horizons |
| [table-of-lessons-1662.jpg](plans/table-of-lessons-1662.jpg) | The 1662 Table of Lessons and monthly Psalter | A recurring path |

## Platform copies and remaining integration

- The three app icons are registered in
  `apple/App/Resources/Brand.xcassets/AppIcon.appiconset`. The app target in
  `apple/project.yml` selects `AppIcon`; Xcode generates the required sizes.
- Ready-to-serve web copies are under `Server/Public/assets/images/`,
  with the same names and `plans/` subdirectory. Only the web variants,
  sharing image, and plan covers are copied there. The fallback favicon is
  also served from `Server/Public/favicon.ico`.
- P2.8 will place the mark in the web header; P9.4 and P9.9 will use the
  covers and sharing metadata; P15.1 and P16.8 will wire the web manifest
  and favicon links. Those features remain unchecked. No plan-page or
  installability claim follows from the files being present.
- Replace a canonical file first, then its copies listed in the manifest;
  update its checksum and verify the asset catalog or web consumer.

## Export details

Raster exports preserve aspect ratio and use a centered crop only to
meet the exact output dimensions. Plan JPEGs use quality 86 and 4:2:0
sampling. Metadata is stripped. The tinted icon is exported as neutral
grayscale. The SVG retains the mark's contour and uses no raster embed.
The maskable web icon reduces the full app artwork to 410 × 410 and centers
it in a 512 × 512 square, keeping the meaningful motif inside the central
80% circle.

For manual image export work only, ImageMagick and Potrace are available
through Homebrew (`brew install imagemagick potrace`). They are not app,
server, or `make check` dependencies. Normal builds use the committed files.
