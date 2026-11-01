# Design: Morning

The owner chose the **Morning** direction in the design session on
2026-11-01 (BUILD.md D18, P2.3), over Bookmark and Desk. Its mockups are in
`design/mockups/` (Today, a plan page, and Progress; phone and desktop;
light and dark), and its values are in `design/tokens.json`, from which the
app's color assets and the web's `tokens.css` are generated (P2.4). Change a
token there first, regenerate, and commit both (AGENTS.md §5).

## Character

Light and open: generous space, soft rounded cards, and the system sans
throughout. **One warm dawn accent** carries the primary action, today's
date, the next reading's plan label, and links; everything else is neutral.
Dark mode is a night sky with the dawn brightened. The aim is a quiet,
modern companion that gets out of the way: the reader should be able to see
the next reading, act, and leave in ten seconds (docs/product.md).

## Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `background` | `#FBFBFA` | `#0D1117` | the screen behind everything |
| `surface` | `#FFFFFF` | `#161B23` | cards and the tab bar |
| `surfaceSoft` | `#F1F2F5` | `#222935` | secondary buttons, chips, day cells |
| `line` | `#E7E8EC` | `#262D38` | hairline borders; never text |
| `text` | `#15171C` | `#F1F3F6` | body text and references |
| `textMuted` | `#596070` | `#A0A8B6` | labels, estimates, captions |
| `accent` | `#B9531A` | `#F4A26A` | the dawn accent |
| `onAccent` | `#FFFFFF` | `#1B0F06` | text on the accent |
| `accentTint` | `#FFF0E5` | `#2E2118` | the selected section, quiet celebrations |
| `danger` | `#B42318` | `#F97066` | error messages only |

Rules:

- **One accent, used sparingly.** On a screen, the accent marks the one
  thing to do next (Mark read on the next reading, Start this plan) and a
  few small signposts (today's date, the next reading's label, links). A
  second reading's Mark read is a `surfaceSoft` button.
- **Text on `accentTint` is `text`**, never `accent` (accent on tint is only
  4.4:1 in light mode).
- **Color never carries meaning alone.** Reading states always have words or
  symbols: ✓ Read, ◐ Part read, Skipped, – No reading.
- No raw colors in any view or stylesheet; `make check` enforces it (P2.4).

### Text pairs

Every pair a screen uses for text, and its WCAG contrast. The token tests
(P2.4) read this table and fail if any pair falls below 4.5:1 in either
appearance.

| Text | On | Light | Dark |
|---|---|---|---|
| `text` | `background` | 17.3 | 17.0 |
| `text` | `surface` | 17.9 | 15.5 |
| `text` | `surfaceSoft` | 16.0 | 13.1 |
| `text` | `accentTint` | 16.1 | 14.0 |
| `textMuted` | `background` | 6.1 | 7.9 |
| `textMuted` | `surface` | 6.3 | 7.2 |
| `textMuted` | `surfaceSoft` | 5.6 | 6.1 |
| `accent` | `background` | 4.7 | 9.2 |
| `accent` | `surface` | 4.9 | 8.4 |
| `onAccent` | `accent` | 4.9 | 9.1 |
| `danger` | `background` | 6.3 | 6.8 |
| `danger` | `surface` | 6.6 | 6.2 |

## Type

The interface and references use the **system sans** (SF Pro on Apple
platforms; `system-ui` on the web). No web font is loaded, so P2.5's
self-hosted book face is not needed for Morning.

| Style | Size (pt at default) | Weight | Scales with | Desktop web |
|---|---|---|---|---|
| reference (desk-glance) | 38 | semibold | Large Title | 72 px |
| referenceList | 21 | semibold | Title 2 | 22 px |
| screenTitle | 34 | bold | Large Title | 44 px |
| planTitle | 30 | bold | Title | 46 px |
| figure | 48 | bold | Large Title | 68 px |
| body | 17 | regular | Body | 17–19 px |
| label | 14 | semibold | Subheadline | 15–16 px |
| caption | 13 | regular | Footnote | 13–14 px |

References use slightly tightened tracking (−0.02 em) and a line height of
1.1. Every size scales: with Dynamic Type up to AX5 in the app, and in `rem`
on the web. At the largest sizes a reference wraps between book and chapter
rather than truncating.

## Shape and space

- Cards: corner radius 24 (28 on the desktop web), 1-point `line` border, no
  shadow.
- Buttons and the section switcher are pills (fully rounded), at least 44
  points tall; the primary button is 50–52.
- Spacing steps: 4, 8, 12, 16, 24, 32, 40.
- Content width on the web: at most 1120 px, with 40 px side padding on the
  desktop and 16 px on a phone.

## Navigation

- **iPhone:** a floating, rounded tab bar (Today, Plans, Progress); the
  selected tab sits on `accentTint`. Settings is a button at the top right.
- **Web:** a header with the wordmark and a pill-shaped section switcher
  (Today, Plans, Progress, Settings), the current one on `accentTint`; the
  footer carries the independence statement.

## Icons and images

The owner directs every image and icon (D19); prompts are kept in
`design/image-prompts.md`. On 2026-11-01 the owner requested the initial
artwork batch and its registration. The files, dimensions, and integration
status are listed in `design/images/README.md`. Future image work still
follows D19 unless the owner requests otherwise. Until a file arrives, its
place shows a dashed placeholder. Interface symbols in the app (tab icons,
Settings, Share) are
Apple's SF Symbols, which are system symbols rather than drawn artwork, and
they are used only on Apple platforms, as their licence requires; the web
uses words instead of symbols.

## Motion

Minimal: standard system transitions, and a short fade when a reading is
marked read. Nothing moves when Reduce Motion is on.
