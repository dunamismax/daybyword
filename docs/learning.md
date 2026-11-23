# Learning after launch

How Day by Word learns what readers need without analytics (BUILD.md
P18.9, D12, D25). There is no tracking of any kind, so everything here
comes from what readers choose to say and what Apple reports in aggregate.
What is learned becomes items in BUILD.md (or docs/roadmap.md), never a
dashboard.

## The sources

1. **Support mail** to support@daybyword.com (D28): questions, problems,
   and readings that look wrong (`/support`).
2. **"Share what you think"**, the opt-in questions on `/support#feedback`,
   linked from Settings on the web and in the app: which plan a reader
   follows and how they chose it, what makes it hard to start or keep
   going, what they would change, and how they read. A reader answers by
   mail, only if they want to; nothing is sent unless they send it, and
   the server keeps nothing (D10, D39).
3. **What Apple provides** in App Store Connect: downloads, crashes from
   readers who share them with developers, ratings and reviews. Day by
   Word adds no SDK or analytics of its own (D12). Ratings are never asked
   for on Today (AGENTS.md §3).
4. **The beta** (P18.3, D36): TestFlight feedback from readers the owner
   invites.

## The routine

- **Each week:** read the support inbox. Answer each message plainly
  (docs/editorial.md, "Readers' reports of errors"). A reading that looks
  wrong is checked and, if confirmed, corrected as a new plan version.
- **Anonymize before anything enters the repository** (AGENTS.md §6): no
  name, address, or story; a report becomes the plan, the reading, and the
  problem, and a suggestion becomes what was asked for, in our words.
- **Each quarter:** write a short note, `docs/learning/YYYY-Qn.md`, with
  what readers asked for, what was hard, what broke, and what Apple's
  figures show (counts only), and turn each finding into an item in
  BUILD.md or docs/roadmap.md, naming the note. A finding that would mean
  tracking readers, ranking them, or adding pressure is recorded and set
  aside (AGENTS.md §3).

## What is never done

No analytics, session recording, A/B tests, or measuring time in the app
(D12). No survey inside the app that interrupts reading, no prompt to rate
the app, and no mail beyond answering what a reader wrote: Day by Word
sends no email of its own (D9).
