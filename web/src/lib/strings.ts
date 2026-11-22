// The web's interface text, by key (docs/decisions.md E15, E25). Pages and
// components never write interface words themselves; they ask for a key, so
// adding a language means adding a table, and a test of the production
// server refuses a page that shows words from anywhere else. English only
// for now.

const english = {
  "site.name": "Day by Word",
  "site.tagline": "Your Bible reading companion.",
  "site.line": "Find your plan. Read your Bible. Keep your place.",
  "site.independence":
    "Day by Word is independent and not affiliated with any church or denomination.",
  "site.in-development": "Day by Word is in development.",
  "site.page-title": "{page} · Day by Word",
  "site.skip-to-content": "Skip to content",
  "site.sections-label": "Sections",
  "site.browser-too-old":
    "This browser is too old for Day by Word's web app. Pages still work for reading, but marking readings needs a recent version of Safari, Chrome, Firefox, or Edge.",
  "site.browser-needs-javascript":
    "Day by Word's web app needs JavaScript. Pages still work for reading without it.",
  "site.go-to-today": "Go to Today",

  "section.today": "Today",
  "section.plans": "Plans",
  "section.progress": "Progress",
  "section.settings": "Settings",

  "today.empty-title": "Your next reading will appear here.",
  "today.choose-plan": "Choose a plan",
  "today.not-saved": "That wasn't saved. Check your connection and try again.",
  "today.upcoming": "This plan starts on {date}.",
  "today.done": "That's today's reading.",
  "today.open": "Nothing more is scheduled today.",
  "today.rest": "Today is a rest day in this plan.",
  "today.paused": "This plan is paused.",
  "today.finished": "You've reached the end of this plan.",
  "today.label-reading": "{plan} — Reading {position}",
  "today.label-day": "{plan} — Day {day}",
  "today.short-month":
    "This month has {days} days, so this plan has no reading for day {list} this month.",
  "today.mark-read": "Mark read",
  "today.open-youversion": "Open in YouVersion",
  "today.opens-at": "Opens at {chapter}, where this reading begins.",
  "today.choose-translation": "Choose a translation to open readings in YouVersion",
  "print.chapter": "{book} · chapter {chapter}",
  "print.chapters": "{book} · chapters {chapter}–{last}",
  "print.across": "{book} · chapter {chapter}, verse {verse} to chapter {last}, verse {final}",
  "print.verse": "{book} · chapter {chapter} · verse {verse}",
  "print.verses": "{book} · chapter {chapter} · verses {verse}–{last}",
  "print.book-verse": "{book} · verse {verse}",
  "print.book-verses": "{book} · verses {verse}–{last}",
  "today.mark-part": "Mark part read",
  "today.skip": "Skip",
  "today.skip-confirm": "Skip this reading? It won't count as read.",
  "today.marked-read": "Marked {reference} read.",
  "today.marked-read-on": "Marked {reference} read on {date}.",
  "today.undone": "Undone.",
  "today.redo": "Redo",
  "today.earlier": "Log an earlier day",
  "today.earlier-date": "Read on",
  "today.earlier-log": "Log",
  "today.earlier-note": "The reading is kept on the day you read it, not today.",
  "today.marked-part": "Marked {reference} part read.",
  "today.marked-skipped": "Skipped {reference}. It won't count as read.",
  "celebration.returned": "You've picked up where you left off.",
  "celebration.finished-book": "You've read all of {book}.",
  "celebration.finished-plan": "You've finished {plan}.",
  "celebration.kept-rhythm": "You've read on each of your reading days this week.",
  "welcome.title": "Welcome back. Here's where you left off.",
  "welcome.continue": "Continue from where I left off",
  "welcome.spread": "Spread the readings over the days ahead",
  "welcome.move-finish": "Move my finish date",
  "welcome.rejoin": "Rejoin today's readings",
  "welcome.next": "Your next reading will be {reference}.",
  "welcome.nothing": "Nothing is rescheduled.",
  "welcome.finish-at-pace": "At one reading each reading day, you'd finish on {date}.",
  "welcome.spread-one": "1 reading a day until {date}.",
  "welcome.spread-other": "Up to {most} readings a day until {date}.",
  "welcome.finish-moves": "Your finish date moves to {date}.",
  "welcome.rejoin-today": "Today's reading is {reference}. Earlier readings stay in your history.",
  "welcome.rejoin-plain": "Earlier readings stay in your history.",
  "welcome.nothing-changes-yet": "Nothing changes until you choose.",
  "start.title": "Start this plan",
  "start.on": "Start on",
  "start.join-today": "You'll begin with today's reading, and each date keeps its own.",
  "start.schedule": "Schedule",
  "start.finish": "Finish by",
  "start.limit": "At most this many readings a day",
  "start.days": "Reading days",
  "start.days-rest": "Other days are rest days.",
  "start.days-calendar":
    "Each date still has its reading. Your reading days only say which days you plan to read.",
  "start.kept": "Your plan and what you mark are kept in this browser only.",
  "start.load-range": "{least} to {most} readings a day, on {days} reading days.",
  "start.load-one": "1 reading a day, on {days} reading days.",
  "start.load-same": "{most} readings a day, on {days} reading days.",
  "start.heaviest": "{minutes} on the heaviest day. Estimates vary.",
  "start.too-many":
    "To finish by {finish} you'd read up to {most} readings a day. At {limit} a day you'd finish on {later}.",
  "start.use-later": "Finish on the later date instead",
  "start.submit": "Start",
  "start.not-started":
    "The plan could not be started. Check the dates and your connection, and try again.",
  "plans.empty-title": "Plans will appear here.",
  "plans.empty-message": "You'll be able to choose a reading plan here.",
  "plans.every-plan": "Every plan",
  "plans.description":
    "Day by Word's reading plans, with a few practical questions to help you choose one.",
  "goal.begin": "A place to begin",
  "goal.whole-bible": "The whole Bible",
  "goal.new-testament": "The New Testament",
  "goal.gospels": "The Gospels",
  "goal.psalms-proverbs": "The Psalms and Proverbs",
  "choose.title": "Help me choose",
  "choose.intro": "Answer what you can. Not sure is always an answer.",
  "choose.hope": "What do you hope to read?",
  "choose.time": "How long can a reading take?",
  "choose.days": "How many days a week do you expect to read?",
  "choose.not-sure": "Not sure",
  "choose.time-short": "About 5 minutes",
  "choose.time-medium": "About 10 minutes",
  "choose.time-long": "15 minutes or more",
  "choose.days-every": "Every day",
  "choose.days-five": "Five days a week",
  "choose.days-few": "A few days a week",
  "choose.submit": "Show plans to consider",
  "choose.results": "Plans to consider",
  "choose.results-note":
    "Chosen by a few fixed rules from what you said, never by popularity. Estimates vary with the reader and the translation.",
  "choose.reason-begin": "A plan for beginning, or returning to, a reading habit.",
  "choose.reason-whole-bible": "A plan for reading the whole Bible.",
  "choose.reason-new-testament": "A plan for reading in the New Testament.",
  "choose.reason-gospels": "A plan for reading the Gospels.",
  "choose.reason-psalms-proverbs": "A plan for reading the Psalms or Proverbs.",
  "choose.said-short": "about 5 minutes",
  "choose.said-medium": "about 10 minutes",
  "choose.said-long": "15 minutes or more",
  "choose.minutes-one": "about 1 minute",
  "choose.minutes-other": "about {minutes} minutes",
  "choose.minutes-range": "about {low} to {high} minutes",
  "choose.reason-time": "A typical reading takes {minutes}.",
  "choose.reason-time-fits": "You said {said}. A typical reading takes {minutes}.",
  "choose.reason-time-longer": "A typical reading takes {minutes}, longer than you said.",
  "choose.reason-paced-same": "It's paced for {days}, as you said.",
  "choose.reason-paced-fewer":
    "It's paced for {days}, fewer than you said; the others are rest days.",
  "choose.reason-paced-more": "It's paced for {days}, more than you said.",
  "choose.paced-every-day": "every day",
  "choose.paced-one": "1 reading day a week",
  "choose.paced-other": "{days} reading days a week",
  "choose.reason-weeks-one": "At {per} a week it takes 1 week.",
  "choose.reason-weeks-other": "At {per} a week it takes about {weeks} weeks.",
  "choose.per-one": "1 reading",
  "choose.per-other": "{count} readings",
  "choose.reason-calendar": "It has a reading for each date of the month.",
  "plan.title": "Plan",
  "plan.by": "By {creator}",
  "plan.readings-one": "1 reading",
  "plan.readings-other": "{count} readings",
  "plan.kind-sequence": "Read in order",
  "plan.kind-calendar": "By the date",
  "plan.suits": "Who it suits",
  "plan.workload": "How long it takes",
  "plan.workload-typical": "A typical reading",
  "plan.workload-lightest": "The lightest reading",
  "plan.workload-heaviest": "The heaviest reading",
  "plan.paced-one": "It is paced for 1 reading day a week. You choose your own days.",
  "plan.paced-other": "It is paced for {days} reading days a week. You choose your own days.",
  "plan.paced-every-day": "It is paced for every day of the week. You choose your own days.",
  "plan.sample-sequence":
    "Its first week, begun on a Monday. Your own week depends on the day you start and the days you choose.",
  "plan.sample-calendar": "The first seven days of a month. Each date has its own reading.",
  "plan.sample-day": "Day {day}",
  "plan.rest-day": "Rest day",
  "plan.covers": "What it covers",
  "plan.covers-whole-bible": "Every verse of the {label} of the {canon} canon: {verses} verses.",
  "plan.covers-books": "Every verse of {books}: {verses} verses.",
  "plan.covers-selection":
    "Passages from {books}: {verses} verses. It does not read these books whole.",
  "plan.covers-repeats": "It reads these verses more than once: {passages}.",
  "plan.covers-no-repeats": "No verse is read twice.",
  "plan.completion-note":
    "Finishing a plan is not the same as reading the whole Bible, unless its readings cover it.",
  "plan.how": "How it works",
  "plan.how-sequence": "Its readings are numbered and read in order.",
  "plan.how-calendar": "Each day of the month has its own reading.",
  "plan.behavior-pace": "Continue at my pace",
  "plan.behavior-pace-about":
    "Read the next reading whenever you read. If you miss a day, nothing is lost: your next reading waits for you, and your finish date moves.",
  "plan.behavior-finish-date": "Work toward a finish date",
  "plan.behavior-finish-date-about":
    "Choose when you'd like to finish. If you miss days, Day by Word can spread the unread readings over the days ahead, up to a limit you set, or move your finish date. You'll see the change before it happens.",
  "plan.behavior-calendar": "Follow the calendar",
  "plan.behavior-calendar-about":
    "Read the readings appointed for each date. Today's readings stay on today, as the calendar sets them. Readings from earlier dates stay in your history, and you can read them whenever you like.",
  "plan.limitations": "What it does not do",
  "plan.review-checked": "Checked automatically: every reference and claim.",
  "plan.review-reviewed":
    "Reviewed: checked against its own rules and Day by Word's criteria for plans.",
  "plan.review-expert": "Reviewed by a reader who uses its source.",
  "plan.review-label": "Review.",
  "plan.length-sequence": "{readings}: about {weeks} weeks at {per} a week.",
  "plan.length-sequence-week": "{readings}: 1 week at {per} a week.",
  "plan.length-calendar": "A reading for each day of the month, begun again each month.",
  "plan.permissions-label": "Permissions.",
  "plan.rights-daybyword-original":
    "Day by Word's own plan: free to follow, to print for your own use, and to share by its link.",
  "plan.rights-recorded": "Its permissions are recorded with its source.",
  "list.and": "{first} and {last}",
  "list.comma": "{first}, {rest}",
  "list.comma-and": "{first}, and {last}",
  "canon.protestant": "Protestant",
  "canon.catholic": "Catholic",
  "weekday.monday": "Monday",
  "weekday.tuesday": "Tuesday",
  "weekday.wednesday": "Wednesday",
  "weekday.thursday": "Thursday",
  "weekday.friday": "Friday",
  "weekday.saturday": "Saturday",
  "weekday.sunday": "Sunday",
  "reference.chapter": "{book}, chapter {chapter}",
  "reference.chapters": "{book}, chapters {chapter} to {last}",
  "reference.verse": "{book}, chapter {chapter}, verse {verse}",
  "reference.verses": "{book}, chapter {chapter}, verses {verse} to {last}",
  "reference.across": "{book}, chapter {chapter}, verse {verse}, to chapter {last}, verse {final}",
  "reference.book-verse": "{book}, verse {verse}",
  "reference.book-verses": "{book}, verses {verse} to {last}",
  "reference.psalm": "Psalm {chapter}",
  "reference.psalms": "Psalms {chapter} to {last}",
  "reference.then": "{first}; then {next}",
  "week.title": "Week",
  "week.checklist": "A week's checklist",
  "week.from-start-sequence":
    "The plan's first week, begun on {date}, on the days it is paced for. Your own days may differ.",
  "week.from-start-calendar": "The readings appointed for seven days from {date}.",
  "week.start-label": "Start on",
  "week.show": "Show this week",
  "week.print": "Print this checklist",
  "week.tick-note": "Tick each reading as you read it.",
  "week.link": "A week's checklist to print",
  "date.january": "{weekday} {day} January",
  "date.february": "{weekday} {day} February",
  "date.march": "{weekday} {day} March",
  "date.april": "{weekday} {day} April",
  "date.may": "{weekday} {day} May",
  "date.june": "{weekday} {day} June",
  "date.july": "{weekday} {day} July",
  "date.august": "{weekday} {day} August",
  "date.september": "{weekday} {day} September",
  "date.october": "{weekday} {day} October",
  "date.november": "{weekday} {day} November",
  "date.december": "{weekday} {day} December",
  "progress.empty-title": "Your reading record will appear here.",
  "progress.empty-message": "It describes what you've read, and nothing more.",
  "progress.describes": "This describes what you've marked, and nothing more.",
  "progress.recent-days": "Recent days",
  "progress.books": "Books explored",
  "progress.books-note":
    "The books you've marked a reading in, in any plan. Reading in a book is not reading all of it.",
  "progress.key": "✓ read · ○ a reading day · – a rest day",
  "progress.in-a-row-one": "1 reading day in a row",
  "progress.in-a-row": "{count} reading days in a row",
  "progress.day-read": "{date}, read",
  "progress.day-unread": "{date}, not read",
  "progress.day-rest": "{date}, rest day",
  "progress.read-of": "{read} of {total} readings read",
  "progress.read-of-one": "{read} of 1 reading read",
  "progress.part-read": "{count} part read",
  "progress.skipped": "{count} skipped",
  "progress.stopped": "You stopped following this plan.",
  "progress.next": "Next: {reference}",
  "progress.finish-date": "Your finish date is {date}.",
  "settings.appearance": "Appearance",
  "settings.appearance-automatic": "Automatic",
  "settings.appearance-light": "Light",
  "settings.appearance-dark": "Dark",
  "settings.appearance-note": "Automatic follows your device.",
  "settings.reference-size": "Reference text size",
  "settings.reference-size-standard": "Standard",
  "settings.reference-size-larger": "Larger",
  "settings.reference-size-largest": "Largest",
  "settings.reference-size-note":
    "References on Today and in plans use this size, on top of your browser's text size.",
  "settings.sample-reference": "Mark 4:1–20",
  "settings.sample-reference-spoken": "Mark, chapter 4, verses 1 to 20",
  "settings.way-to-read": "How you read",
  "settings.way-to-read-physical-bible": "A physical Bible",
  "settings.way-to-read-you-version": "YouVersion or Bible.com",
  "settings.way-to-read-other-app": "Another app, with Copy reference",
  "settings.way-to-read-note":
    "With a physical Bible, Today says where each reading is in print. Day by Word never shows Bible text.",
  "settings.translation": "Translation for YouVersion and Bible.com",
  "settings.translation-none": "Not chosen",
  "settings.translation-option": "{name} ({abbreviation})",
  "settings.translation-note":
    "Readings open in the YouVersion app if it's installed, and on Bible.com if not. Links use the common English verse numbers, and a few translations number some chapters differently.",
  "settings.book-names": "Book names",
  "settings.book-names-common": "Common English: Song of Songs, Sirach",
  "settings.book-names-kjv": "King James: Song of Solomon, Ecclesiasticus",
  "settings.book-names-douay": "Douay-Rheims: Canticle of Canticles, Apocalypse",
  "settings.book-names-note": "References on Today use these names.",
  "settings.streak": "Reading days in a row",
  "settings.streak-off": "Don't show",
  "settings.streak-on": "Show on Progress",
  "settings.streak-note":
    "Counts the reading days you've read one after another. Rest days never break it, and it never appears in a reminder.",
  "settings.kept-in-this-browser":
    "These choices are kept in this browser only. They are never sent to daybyword.com.",
  "settings.your-data": "Your data",
  "settings.data-note":
    "Your plans and reading record are kept only in this browser. To work out today's reading, this browser sends them to daybyword.com, which keeps none of it and records nothing about them.",
  "settings.export": "Export my reading record",
  "settings.delete": "Delete everything in this browser",
  "settings.delete-confirm":
    "Delete your plans and reading record from this browser? This can't be undone.",
  "settings.deleted": "Your plans and reading record are deleted from this browser.",
  "settings.about": "About",
  "settings.version": "Version {version}",
  "settings.development-version": "Development build",
  "not-found.title": "Page not found",
  "not-found.message":
    "There's no page at this address. It may have moved, or the link may be mistyped.",

  "component.copy-reference": "Copy reference",
  "component.copied": "Copied",
  "component.copy-failed": "Selected; copy it with your keyboard",
  "component.workload-one": "About 1 minute. Estimates vary.",
  "component.workload-other": "About {minutes} minutes. Estimates vary.",
  "component.workload-range": "About {low}–{high} minutes. Estimates vary.",
  "component.minutes-one": "About 1 minute",
  "component.minutes-other": "About {minutes} minutes",
  "component.minutes-range": "About {low}–{high} minutes",
  "component.estimates-vary": "Estimates vary with the reader and the translation.",
  "component.status-read": "Read",
  "component.status-partly-read": "Part read",
  "component.status-skipped": "Skipped",
  "component.status-unread": "Not yet read",
  "component.source-label": "Source.",
  "component.sample-week": "A sample week",
  "component.change-from": "from",
  "component.change-to": "to",
  "component.cancel": "Cancel",
  "component.undo": "Undo",
  "component.loading": "Loading…",
  "component.offline-title": "You're offline",
  "component.offline-message": "Marks you make here are kept and sent when you're back online.",
  "component.error-title": "Something went wrong",
  "component.try-again": "Try again",
} as const;

export type StringKey = keyof typeof english;

/** Every key with its English text, for the string tests. */
export const englishStrings: Readonly<Record<StringKey, string>> = english;

/** The text for a key, with its `{name}` placeholders filled. */
export function text(key: StringKey, values: Record<string, string> = {}): string {
  let result: string = english[key];
  for (const [name, value] of Object.entries(values)) {
    result = result.replaceAll(`{${name}}`, value);
  }
  return result;
}

/** "About 9–11 minutes. Estimates vary.", or one number when both ends round the same. */
export function workloadRangeText(minutes: readonly [number, number]): string {
  const [low, high] = minutes;
  return low === high
    ? workloadText(low)
    : text("component.workload-range", { low: String(low), high: String(high) });
}

/** "About 9–11 minutes", for a list whose note says once that estimates vary. */
export function minutesRangeText(minutes: readonly [number, number]): string {
  const [low, high] = minutes;
  if (low !== high)
    return text("component.minutes-range", { low: String(low), high: String(high) });
  return low === 1
    ? text("component.minutes-one")
    : text("component.minutes-other", { minutes: String(low) });
}

/** "Matthew, Mark, Luke, and John": a list in words. */
export function listText(items: readonly string[]): string {
  if (items.length <= 1) return items[0] ?? "";
  const [first = "", last = ""] = items.slice(-2);
  if (items.length === 2) return text("list.and", { first, last });
  let result = text("list.comma-and", { first, last });
  for (const item of items.slice(0, -2).reverse()) {
    result = text("list.comma", { first: item, rest: result });
  }
  return result;
}

/** "About 12 minutes. Estimates vary." Estimates always say they are estimates. */
export function workloadText(minutes: number): string {
  return minutes === 1
    ? text("component.workload-one")
    : text("component.workload-other", { minutes: String(minutes) });
}
