# Image brief and delivery

Day by Word's images and icons are directed by the owner (D19). The owner
requested creation and registration of this initial batch on 2026-11-01;
this is a specific exception to the earlier owner-supplied-file workflow.
Future image work follows D19 unless the owner requests otherwise. Each
entry gives
where the image is used, its sizes and format, and a prompt the owner can
use or adapt. The style follows the Morning direction (docs/design.md):
light, open, calm, one warm dawn accent (`#B9531A` light, `#F4A26A` dark) on
neutral grounds, no text in the image unless stated, and nothing that
belongs to one church tradition (no denominational symbols).

Finished files are in `design/images/` with the names below. Status:
**delivered**, including the optional twelve launch-plan covers. See
`design/images/README.md` for dimensions, plan-name mappings, platform
copies, and integration status. Exact production prompts are in
`design/images/prompts.json`.

## 1. App icon — needed first

- **Blocks:** the first TestFlight upload (BUILD.md P1.12); App Store
  Connect rejects builds without an icon.
- **File:** `design/images/app-icon.png`, 1024 × 1024 px, PNG, square, no
  transparency, no rounded corners (iOS applies the mask). If possible also
  dark and tinted variants (`app-icon-dark.png`, `app-icon-tinted.png`) for
  iOS's icon appearances.
- **Delivered:** all three, registered in the app's `AppIcon` set. The
  dark foreground has transparency for the system background; the primary
  icon is opaque and the tinted icon is grayscale.
- **Prompt:** "A simple, calm app icon for a Bible reading companion called
  Day by Word. A soft dawn horizon or a single warm sunrise glow in burnt
  orange (#B9531A to #F4A26A) on an off-white ground, suggesting a new day
  and an open page. Minimal, flat, no text, no cross or church symbol, no
  people, legible at 60 px."

## 2. Wordmark and site mark

- **Used in:** the web header beside "Day by Word", the favicon, and the
  installable web app (P2.8, P15.1, P16.8).
- **Files:** `design/images/mark.svg` (square, works at 16–64 px, single
  color so it can follow light and dark), plus `favicon-32.png`,
  `apple-touch-icon.png` (180 × 180), and `web-app-512.png` (512 × 512,
  maskable safe zone) exported from it.
- **Delivered:** the SVG follows the transparent raster mark's contour and
  uses `currentColor`. The favicon and touch icon use the opaque app icon
  for contrast on any browser background. The maskable icon has additional
  padding; a 192 px version is supplied too. A separate typeset wordmark is
  unnecessary: the header keeps its accessible system-font name.
- **Prompt:** "The app icon's sunrise reduced to a single-color mark that
  stays clear at 16 px."

## 3. Plan images (optional, one per launch plan)

- **Used in:** the top of each plan page and its sharing preview (P9.4,
  P9.9). Plans work without them; a page shows nothing in their place.
- **Files:** `design/images/plans/<plan-id>.jpg`, 1600 × 900 px (16:9),
  JPEG, under 300 KB.
- **Delivered:** twelve covers, one for each plan in BUILD.md D14. File
  slugs are provisional until P4.2 establishes catalog IDs. These are
  decorative illustrations; they convey no source, endorsement, review,
  coverage, or release claim.
- **Prompt (adapt per plan):** "A quiet, abstract morning scene in soft
  light with a warm dawn accent, evoking [the plan's theme, for example
  'the four Gospels as one journey']. No text, no people's faces, no
  depictions of Christ or saints, no denominational symbols."

## 4. Social sharing image

- **Used in:** link previews for daybyword.com's home page (P9.9, P16.1).
- **File:** `design/images/share.png`, 1200 × 630 px.
- **Delivered:** the sunrise/page mark with the name and exact product
  line set on the left, checked for wording and legibility.
- **Prompt:** "The app icon's dawn on an off-white ground, with room on the
  left for the words 'Day by Word' and 'Find your plan. Read your Bible.
  Keep your place.', which agents set in type."
