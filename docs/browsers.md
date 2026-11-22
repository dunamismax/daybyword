# Browsers

Which browsers daybyword.com supports (D30), what the web app needs from
them, and what has been tested in each. Update the table under "What was
tested" whenever a browser test runs, with the version and the date.

## The support matrix (D30)

| Browser | Desktop | Phone and tablet | Supported versions |
|---|---|---|---|
| Safari | macOS | iOS and iPadOS | the current and previous major version |
| Chrome | macOS, Windows, Linux | Android | the current and previous major version |
| Firefox | macOS, Windows, Linux | Android | the current and previous major version |
| Edge | macOS, Windows | — | the current and previous major version |

The web app needs JavaScript. Older browsers get a plain notice and can still
read every page; nothing is polyfilled or transpiled for them.

## What the web app needs

- **JavaScript modules.** A browser that cannot load them runs
  `unsupported.js` (a `nomodule` script), which shows the notice.
- **The features `support.js` checks**: `structuredClone`,
  `Array.prototype.findLast`, `Object.groupBy`, the `:has()` selector and
  container queries. If any is missing, the notice shows. By MDN's
  compatibility tables the newest of these arrived in Chrome and Edge 117,
  Firefox 121 and Safari 17.4, far below D30's floor; those old versions
  have not been tested.
- **IndexedDB** for the reader's journal (E52), **a service worker** for
  offline (E53), and `localStorage` for settings and the week of Today kept
  offline.
- **A strict Content Security Policy** (E11): no inline scripts or styles,
  nothing from another host. Every page is checked for both
  (`web/test/production/`).

Without JavaScript the pages still read: plans, their weeks to print (a
plain form picks the start date) and the footer's statement. A `noscript`
notice says that the web app needs it.

### Features that depend on the browser

| Feature | Where the browser has it | Elsewhere |
|---|---|---|
| Share this plan (P15.4) | the Web Share API opens the system's share sheet | the link is copied; if the clipboard is refused, it is shown selected |
| Copy reference | the clipboard | the reference is selected for the keyboard |
| Install (P15.1) | Add to Home Screen on iOS and iPadOS Safari (tested); Chrome's and Edge's install (not yet tested, P15.1b) | the site in a tab works the same |
| Offline (P15.2) | the service worker keeps the pages and assets | pages need a connection |
| Print a week (P8.10b, P13.1) | the browser's own Print, and the page's Print button | — |

## What was tested

| Browser | Version | How | What | Date |
|---|---|---|---|---|
| Firefox (macOS) | 160.0.1 | the web tour, headless, through geckodriver (`make tour-web`) | every address in docs/urls.md at 1280 and 500 px in light and dark (headings, the current section, theme, no sideways scroll, the footer, the skip link first); Settings applied and kept; a week printed on Letter in ordinary and large print, every day whole on a page; Share, Mark read and Undo on Today, and History, pressed with Tab and Enter, with focus kept; every web flow at 1280 and 500 px; a Tab walk of every page, each control reached with its focus outline (505 checks) | 2026-11-22 |
| Chrome (macOS) | 157.0.8103.39 | the same tour, headless, through Chrome's DevTools protocol (`make tour-web`, E60) | everything the Firefox tour checks, at 1280 px and as a phone at 375 and 320 px, and every web flow at 1280 and 320 px; the same Tab walk (739 checks) | 2026-11-22 |
| Firefox (macOS) | 160 | the engine cases in the browser (`make test-domain-browser`) | every shared case in tests/fixtures/ through the TypeScript domain module | 2026-11-20 |
| Chromium (the Claude desktop app's browser pane) | the pane's | by hand | offline with the server stopped (P15.2); a Tab walk of every page, each control reached with a visible focus ring; Share's fallback at 375 px; Mark read and Undo by keyboard (P15.4) | 2026-11-22 |
| Safari (iOS 27, iPhone 18 Pro simulator) | iOS 27 | by hand | Add to Home Screen, the owner's icon, opening standalone on Today (P15.1a) | 2026-11-22 |

Not tested yet:

- **Safari through the tour** (P15.6b). Safari's driver (`safaridriver`,
  part of macOS) starts a session only once "Allow remote automation" is on
  in Safari's Developer settings, which needs the owner.
- **Edge**, which is not installed on the development Mac; it is checked
  by hand at each release (P15.6).
- **A phone's own share sheet** from the web (the Web Share API), and
  **Android** (installing, P15.1b).
- **A real phone's browser.** The tour's phone widths are Chrome's
  emulation of a phone's viewport, not a phone; Safari on iOS was seen only
  for installing (P15.1a).

## At each release

Run `make check-full` (the tour in Firefox and Chrome, and the engine
cases in Firefox), then check by hand in the browsers the tour does not
reach (Safari until P15.6b, Edge, and a phone), at a phone width and at the
desktop: the home page, Plans and a plan's page, starting
a plan, Today (Mark read, Undo, Copy reference), Progress, Settings, a
week printed, and the site offline. Record each in the table above.
