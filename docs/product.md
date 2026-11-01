# Product rules

This document turns BUILD.md's product principles into rules for every
screen of Day by Word, in the app and on the web. When a design or a piece
of code is unsure what to do, the answer should be here; if it is not, add
it. AGENTS.md §3 governs voice and conduct, and this document applies it.

Day by Word helps a reader choose a Bible reading plan, know what to read
today, and keep a trustworthy record of their reading, while they read in
their own Bible: paper, app, or audio. *Find your plan. Read your Bible.
Keep your place.*

## The reader we design for

A tired reader at six in the morning with a paper Bible open, who wants to
read Scripture and finds planning and consistency hard. They may have
missed a week. They may not know what a lectionary is. They should be able
to open Day by Word, see what to read, and close it again within ten
seconds. Success is twenty minutes in the Bible, not twenty minutes in the
app (principle 11).

## Navigation

There are three destinations, the same on iPhone, iPad, and the web, and a
secondary area for preferences.

| | iPhone | iPad | Web |
|---|---|---|---|
| **Today**, **Plans**, **Progress** | a tab bar, each tab with its own navigation stack | a sidebar (P12.6) | header navigation |
| **Settings** | a toolbar button on each tab's root | a toolbar button | a header link |

- The app opens to **Today**, unless it was opened from a link to
  somewhere else. When the system relaunches it after ending it in the
  background, the reader returns to the same tab and the same place within
  each tab; when the reader closes the app themselves, it starts on Today
  again (docs/decisions.md E24).
- Every destination has a stable address: `daybyword://` routes in the app
  and readable URLs on the web (`docs/urls.md`, P2.9). The two mirror each
  other, so a shared plan link opens the same plan in either.
- There is no feed, no inbox, no badge on a tab, and no red dot anywhere.

## Today

Today answers one question: *what do I read now?*

- **One card per active plan's next reading**, in the order the reader set.
  Each card has the plan's label ("Gospels at your pace — Reading 12"), the
  references set large (the *desk-glance* size, readable from across a
  desk), and three controls:
  - **Open in …** the reader's chosen Bible app or website (YouVersion and
    Bible.com at launch, D26); hidden in physical Bible mode.
  - **Copy reference**, everywhere, always.
  - **Mark read**: one deliberate tap. Undo is one more tap, offered right
    away in a quiet banner and always available in History.
- **Sessions.** A plan with morning and evening readings shows each as its
  own card, labeled with the session's own name ("Morning Prayer",
  "Evening Prayer"; M'Cheyne's "Family" and "Secret"). The day is complete
  when its sessions are.
- **Calendar plans** also say which tradition, edition, and rule produced
  today's readings ("1979 Book of Common Prayer · Daily Office, Year One ·
  Tuesday in the Third Week of Advent"), with a link to the source note.
- **Finished for today** says so plainly: "That's today's reading." No
  fanfare, no confetti, no "come back tomorrow!".
- **Rest days** are named as rest days in a five-day plan: "Today is a rest
  day in this plan." Nothing suggests catching up on a rest day unless the
  reader asks.
- **After a gap**, the return flow appears at the top of Today (below).
- **No plan yet**: a short welcome and the way into choosing a plan, with a
  search box for readers who already know their plan. Nothing else.

Today never shows Bible text (D13), statistics, a streak (D17 keeps the
streak on Progress), promotions, rating prompts, or tips.

### Marking honestly

- **Opening a link is not reading.** Day by Word never marks anything read
  because a link was opened, a reminder was tapped, or a screen was viewed.
  The reader confirms.
- The states are distinct, in words and symbols as well as color:
  **Read**, **Partly read**, **Skipped**, and **Not yet read**.
- **Mark part read** lets the reader say which verses, or simply "part of
  it".
- **Skip** is labeled as a scheduling decision, not a reading: "Skip this
  reading. It won't count as read."
- **Log an earlier day** records a reading on the date it happened, without
  pretending it happened today.
- Every one of these is an event in the journal, and every one can be
  undone. History is never rewritten (docs/decisions.md E3).

## Plans

Plans helps the reader choose with confidence and never leads with a wall of
plans (principle 1).

- **Recommendations first**, after a few practical questions: what the
  reader hopes to read, how much time feels realistic, which days they
  expect to read, and whether they want to follow a church calendar.
  Tradition and Bible edition are optional, and "Not sure" is always an
  answer. Every question can be skipped.
- **Three suitable plans**, each with a concrete reason tied to the
  reader's answers ("You said about 10 minutes on weekdays; this plan
  averages 9"), a sample week, and an honest workload, side by side. The
  rules are deterministic and documented (P9.2): never popularity, never AI
  (D23).
- **The catalog**, organized by goal (begin reading, the whole Bible, the
  New Testament, the Gospels, the Psalms, the church year, reading with a
  group), with filters and search.
- **The plan page** gives the exact title and edition, the creator or
  source, whom it suits, a sample week, the workload, what it covers
  (including repeats, optional passages, and omissions), the tradition and
  books in neutral words, limitations beside advantages, the source note,
  the review level, and the permissions in plain words.
- **My plans**: active, paused, and finished, each with its history.

Plan descriptions say what a plan is, whom it suits, its workload, what it
covers, and its limits. They never preach, never interpret Scripture, and
never claim divine authority ("God wants you to read this" is never
acceptable). A recommendation is practical.

### Starting a plan

Choosing to start shows, in order: the start date (or "Join today's
readings" for a calendar plan); the schedule behavior, explained; reading
days; sessions; how the reader reads (a physical Bible, YouVersion or
Bible.com, or another app with Copy reference); and an offer of a reminder.
Notification permission is asked for only after the reader chooses a
reminder, never at launch.

### The three schedule behaviors, in the reader's words

Each plan says which behaviors it allows. The app explains them like this:

- **Continue at my pace.** "Read the next reading whenever you read. If you
  miss a day, nothing is lost: your next reading waits for you, and your
  finish date moves." For numbered and sequential plans.
- **Work toward a finish date.** "Choose when you'd like to finish. If you
  miss days, Day by Word can spread the readings you missed over the days
  ahead, up to a limit you set, or move your finish date. You'll see the
  change before it happens." For flexible plans with a deadline.
- **Follow the calendar.** "Read the readings appointed for each date.
  Today's readings stay on today, as the calendar sets them. Readings you
  missed stay in your history, and you can read them whenever you like."
  For civil-date and church-calendar plans.

The rule that prevents the serious mistake: an ordinary sequence may move
after a holiday, but Easter readings stay at Easter. A calendar plan offers
a personal adaptation only where its permissions allow, and the app always
labels it as one.

## The return flow

Coming back is normal (principle 3).

- After a gap in the reader's own reading days, Today opens with a short
  welcome: "Welcome back. Here's where you left off." Never "You missed 5
  days!".
- It offers only the choices that apply to the plan's behavior:
  - **Continue from where I left off** (pace and finish-date plans).
  - **Spread the missed readings over the next days**, within a limit the
    reader sets (finish-date plans).
  - **Move my finish date** (finish-date plans).
  - **Rejoin today's readings** (calendar plans). Rejoining marks nothing as
    read; the missed readings stay in history.
- Each choice shows its effect before anything changes: "Your next reading
  will be Mark 5. Your finish date moves to 14 March." The reader confirms.
- Applying a choice is an event and can be undone. Nothing is deleted.
- Day by Word never counts down, never mentions how far behind the reader
  is unless they ask, and never sends a reminder about missed days.

## Progress

Progress describes activity. It cannot measure faithfulness, spiritual
maturity, or understanding, and nothing on it may suggest that it does.

- **Assignments completed** in each plan, **recent reading days** (a plain
  week strip, never a heat map), **books explored**, and **the next
  reading**.
- **Plan completion is kept apart from Bible coverage.** Finishing a
  lectionary year is not reading the whole Bible, and repeated passages
  never inflate coverage.
- **History** lists every reading's state and every change, with late
  logging and undo.
- **Quiet celebrations**, in words and never confetti: returning after a
  gap, finishing a book, finishing a plan, and keeping a rhythm the reader
  chose. Never a comparison with anyone else.
- **The streak** (D17) is off by default. When the reader turns it on, it
  counts against their own reading days (rest days never break it), is shown
  small, never appears in a notification, and is never described with loss
  ("Don't lose your streak!" is never acceptable).

## Settings

Reminders; the preferred way to read and translation; physical Bible mode;
book-name convention (D29); appearance (Automatic, Light, Dark) and
reference text size; backup and sync (optional, D8, D10); export of all
personal data and deletion of all data; sources and permissions; and about,
with the independence statement and the running version.

## Physical Bible mode

Paper Bibles are first-class (D26).

- References at the desk-glance size, with the book and chapter called out
  so the reader can find the place in print ("Mark · chapter 4 · verses
  1–20").
- An option to keep the screen awake while a reading is open.
- No "Open in …" link; Copy reference stays.
- Printable weekly checklists and large print (Phase 13), where the plan's
  permissions allow.

## Reminders and notifications

- Asked for only when the reader chooses a reminder. Turning reminders off
  never limits the app.
- Reminders are wall-clock times in the reader's time zone, per plan and
  session, on the reader's chosen days.
- Actions: **Mark read**, **Snooze**, and **Open**. A reminder stops once
  its session is marked read.
- The reader can hide passage details on the Lock Screen.
- Quiet hours and a maximum per day are respected.
- Notification text is plain and present-tense: "Gospels at your pace:
  Mark 4:1–20." Never urgency, never guilt, never the streak, and never a
  reminder about missed days.

## What each surface does

| Surface | Does | Never does |
|---|---|---|
| **App** | Everything, offline, without an account | Show Bible text, require sign-in, track |
| **Widget** (P8.9, P12.2) | Shows the next reading; **Mark read** from the widget; honors "hide passage details" | Show a streak, nag, or claim a reading happened that the reader did not confirm |
| **Notification** (P8.8) | Says what is next; **Mark read**, **Snooze**, **Open** | Mention missed days, streaks, or urgency |
| **Web** (daybyword.com) | Public plan pages anyone can read; the same Today, Plans, Progress, and Settings, with progress kept on the server only after explicit consent (D10); printable weeks | Load anything from another host, set a cookie that is not strictly necessary, or keep reading data without consent |

## Privacy by design

- No account is needed for anything in the app (D8). The web keeps a
  reader's progress only after an explicit, separate consent: "Keep my plans
  and progress on daybyword.com" (D10).
- Reading history and tradition preferences are sensitive and in some laws
  special-category data (Research finding 11). They are private by default,
  exportable, and deletable at any time, in the app and on the web.
- No analytics, advertising, tracking, or AI, ever (D12, D23). Nothing is
  sold or shared.
- Backup and offline status are always truthful: "Backed up 2 minutes ago",
  or "Backup unavailable offline".

## Tone

The voice is plain, warm, brief, and concrete (AGENTS.md §3). Use the
reader's words: *reading*, *plan*, *today*. Explain terms such as
*lectionary* and *Daily Office* when they appear. No flattery, no
exclamation-mark enthusiasm, no manipulative urgency, and no insider phrases
that belong to one tradition.

| Instead of | Write |
|---|---|
| You missed 5 days! | Welcome back. Here's where you left off. |
| Don't break your streak! | (nothing; the streak is never in a notification) |
| Great job!!! 🎉 | That's today's reading. |
| You're falling behind. | (nothing, unless the reader asks; then: "Your finish date is now 14 March.") |
| God wants you to read this today. | Today's reading in your plan. |
| Takes 9 minutes. | About 9 minutes. Estimates vary. |
| Read Mark 4 in YouVersion (and the app marks it read) | Open in YouVersion · Copy reference · Mark read |

Every tradition is described on its own terms, from its own sources, in
neutral language, and labeled precisely (the edition, the tradition, the
calendar rule). Day by Word speaks for no church, denomination, ministry,
or publisher. The footer and About carry the independence statement: "Day by
Word is independent and not affiliated with any church or denomination."
