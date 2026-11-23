# Accessibility

What Day by Word checks for accessibility (WCAG 2.2 AA, docs/design.md),
how, and what has not been checked yet. The public statement is
`/accessibility` (BUILD.md P16.6); keep it and this file true together.

## Checked on every run

**The app: Apple's accessibility audit** (`AccessibilityAuditTests`, in
`make tour-app` and so in `make check-full`). With a plan started and a reading marked, it runs
`performAccessibilityAudit` on Today (empty, with a reading, and marked),
Plans, a plan's page, starting a plan, Progress, History, Settings and a
week, in light, in dark, in light at the largest accessibility text size
(AX5), and in dark with Bold Text and Increase Contrast on (Debug launch
arguments `-boldText YES -increaseContrast YES`, which set the scene's
traits as the settings would), and saves each screen when given
`DBW_SCREENSHOTS`. The audit checks that every element has a description VoiceOver can speak, traits
that match it, a large enough hit region, contrast, text that grows with
Dynamic Type, and text that is not cut short.

An issue fails the test only when two audits a moment apart both find
it: the contrast check samples pixels and, on a busy machine, can catch a
screen still settling. It passes every issue except these, each checked
by hand:

| Exempted | Why |
|---|---|
| Contrast and Dynamic Type on the navigation bar's buttons (Done, Cancel, Start) | The system draws them on glass and sizes them; the audit samples the glass |
| Contrast on text that reaches under the tab bar, and contrast the audit names no element for while the tab bar shows | The audit samples it through the bar's blur (on History's long list it cannot even say which element); the same text passes once scrolled into view |
| Contrast on a label of one glyph (Progress's day letters, ✓, ○ and –) | Single glyphs the audit samples unreliably (it passed and failed the same letter on two runs); their colors are 6.3:1 (light) and 7.2:1 (dark) by the tokens |
| Dynamic Type at the standard text size | The audit flags text that does grow (Copy reference, More, the reminder rows); the AX5 pass audits Dynamic Type itself, and its screenshots show the text grown |
| Text clipped by the screen's own edge | Text that continues below the screen, to be scrolled to; text clipped within the screen still fails |
| Text the audit cannot match to an element, on a plan's page and Progress | The sample week says each reference in words ("Matthew, chapters 1 to 3"), not as shown ("Matthew 1–3"), and Progress's recent days say each day ("Monday, March 1, read"), not its letter and symbol |

What the audit found and the app now does (2026-11-22): Form headers and
footers use Morning's `textMuted` (the system's secondary label was about
3.4:1 on Morning's background); a reminder row's time likewise; menu
pickers in Settings and the start sheet open their choices on their own
screen at the accessibility sizes (a menu cut "A physical Bible" to
"A ph…l Bible"); the start sheet's title is "Start this plan", with the
plan's name in the form; and each of Progress's recent days is a full
column at least 44 points tall for VoiceOver's focus.

**The web: the tour** (`make tour-web`, in Firefox, Chrome and Safari). On
every page: the landmarks a screen reader jumps between (banner,
navigation, one main, contentinfo), one first-level heading and no skipped
heading levels, `lang="en"`; text at 200% (the root font size doubled, as
text-only zoom does) at the desktop and the narrowest width with nothing
scrolling sideways or clipped; and the keyboard walk (every control reached
with Tab and showing its focus outline). In Chrome, from the browser's own
accessibility tree, a name for every link, button and field and every
image named or hidden; and with more contrast asked for (Chrome's media
emulation), the high-contrast colors in light and dark; and in forced
colors, an edge on every button and the current section underlined. 400%
zoom is the 320 px width, toured in Chrome. `make check`
also validates every page's HTML (`links.test.ts`) and checks every color pair's contrast in both
appearances (`make tokens`' check). Reduce Transparency changes only the
system's own bars: the app draws no translucent material of its own.

## Not checked yet

- **A person listening with a screen reader**: VoiceOver on an iPhone and
  an iPad, VoiceOver with Safari on a Mac, and NVDA on Windows. The
  Simulator has no VoiceOver, and letting an agent drive the Mac's
  VoiceOver is the owner's setting (BUILD.md P17.1b).
- Forced colors in a real Windows contrast theme (Chrome's emulation is
  what has run), and Safari on iOS with its own text-size setting.
