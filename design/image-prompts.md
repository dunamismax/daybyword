# Images the owner supplies

Day by Word's images and icons come from the owner (D19). Agents never draw,
redraw, or generate them; they describe what is needed here, the owner makes
the files, and agents resize, export, and register them. Each entry gives
where the image is used, its sizes and format, and a prompt the owner can
use or adapt. The style follows the Morning direction (docs/design.md):
light, open, calm, one warm dawn accent (`#B9531A` light, `#F4A26A` dark) on
neutral grounds, no text in the image unless stated, and nothing that
belongs to one church tradition (no denominational symbols).

Put finished files in `design/images/` with the names below. Status: all
**wanted**.

## 1. App icon — needed first

- **Blocks:** the first TestFlight upload (BUILD.md P1.12); App Store
  Connect rejects builds without an icon.
- **File:** `design/images/app-icon.png`, 1024 × 1024 px, PNG, square, no
  transparency, no rounded corners (iOS applies the mask). If possible also
  dark and tinted variants (`app-icon-dark.png`, `app-icon-tinted.png`) for
  iOS's icon appearances.
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
- **Prompt:** "The app icon's sunrise reduced to a single-color mark that
  stays clear at 16 px."

## 3. Plan images (optional, one per launch plan)

- **Used in:** the top of each plan page and its sharing preview (P9.4,
  P9.9). Plans work without them; a page shows nothing in their place.
- **Files:** `design/images/plans/<plan-id>.jpg`, 1600 × 900 px (16:9),
  JPEG, under 300 KB.
- **Prompt (adapt per plan):** "A quiet, abstract morning scene in soft
  light with a warm dawn accent, evoking [the plan's theme, for example
  'the four Gospels as one journey']. No text, no people's faces, no
  depictions of Christ or saints, no denominational symbols."

## 4. Social sharing image

- **Used in:** link previews for daybyword.com's home page (P9.9, P16.1).
- **File:** `design/images/share.png`, 1200 × 630 px.
- **Prompt:** "The app icon's dawn on an off-white ground, with room on the
  left for the words 'Day by Word' and 'Find your plan. Read your Bible.
  Keep your place.', which agents set in type."
