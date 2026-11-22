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
  "site.support": "Support",
  "site.sources": "Sources and permissions",
  "site.criteria": "How plans are chosen",
  "site.accessibility": "Accessibility",
  "site.about-label": "About Day by Word",

  "home.about":
    "Day by Word helps you choose a Bible reading plan, see what to read today, and keep a record of what you've read. You read in your own Bible: on paper, in an app, or as audio. Day by Word shows the references, never the text.",
  "home.choose": "Choose a plan",
  "home.how": "How it works",
  "home.find": "Find your plan",
  "home.find-about":
    "Answer a few practical questions, or look through every plan. Each one says what it covers, how long a reading takes, and what it does not do.",
  "home.read": "Read your Bible",
  "home.read-about":
    "Open today's reading in your own Bible. Copy the reference, or open it in YouVersion or Bible.com.",
  "home.keep": "Keep your place",
  "home.keep-about":
    "Mark what you read, and undo a mark if you need to. After time away, you're welcomed back and choose how to go on.",
  "home.plans": "The plans",
  "home.plans-about": "Every plan in Day by Word today:",
  "home.plans-all": "Every plan, with help choosing",
  "home.private": "Yours, and private",
  "home.private-about":
    "No account, no ads, and no tracking. On the web, your plans and what you mark stay in this browser.",

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
  "plan.share": "Share this plan",
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
  "week.large-print": "Large print",
  "week.tick-note": "Tick each reading as you read it.",
  "week.link": "A week's checklist to print",
  "calendar.add": "Add the next four weeks to a calendar",
  "calendar.note": "The calendar keeps these dates. If your plan moves, add the weeks again.",
  "calendar.description": "{label}. Read it in your own Bible, then mark it read in Day by Word.",
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
    "The books you've marked a reading in, in any plan. Each verse counts once, and a chapter read in part is not counted as read.",
  "progress.key": "✓ read · ○ a reading day · – a rest day",
  "progress.verses-all": "All {total} verses",
  "progress.verses-of": "{read} of {total} verses",
  "progress.chapters-whole-one": "1 chapter read in full",
  "progress.chapters-whole": "{count} chapters read in full",
  "progress.chapters-part-one": "1 chapter in part",
  "progress.chapters-part": "{count} chapters in part",
  "progress.group-reading": "Reading now",
  "progress.group-paused": "Paused",
  "progress.group-finished": "Finished",
  "progress.group-stopped": "Stopped",
  "history.title": "History",
  "history.date": "Read on",
  "history.date-note": "Mark read keeps the reading on this date.",
  "history.readings": "Readings",
  "history.reading": "Reading {position}",
  "history.read-on": "Read on {date}",
  "history.part-on": "Part read on {date}",
  "history.skipped-on": "Skipped on {date}",
  "history.unread": "Not yet read",
  "history.changes": "Changes",
  "history.started": "Started the plan from {date}.",
  "history.marked-part": "Marked {reference} part read on {date}.",
  "history.marked-skipped": "Skipped {reference} on {date}.",
  "history.took-back": "Took back: {change}",
  "history.changed": "Changed {what} from {date}.",
  "history.what-reading-days": "the reading days",
  "history.what-behavior": "the schedule",
  "history.what-finish": "the finish date",
  "history.what-limit": "the most readings a day",
  "history.what-reminder": "the reminder",
  "history.what-start": "the start date",
  "history.paused": "Paused from {date}.",
  "history.resumed": "Resumed on {date}.",
  "history.returned": "Answered the welcome back on {date}: {choice}.",
  "history.ended": "Stopped following the plan on {date}.",
  "history.this-plan": "This plan",
  "history.pause": "Pause this plan",
  "history.resume": "Resume this plan",
  "history.end": "Stop following this plan",
  "history.end-confirm":
    "Stop following this plan? Its record is kept, and you can follow it again from Progress.",
  "history.restore": "Follow this plan again",
  "history.pause-note":
    "Pausing stops its reminders and keeps your place; nothing is moved or marked.",
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
  "settings.support": "Help and support",
  "plan.sources-link": "Sources and permissions",

  "sources.title": "Sources and permissions",
  "sources.description":
    "Where each plan in Day by Word comes from, why Day by Word may offer it, and the sources of its chapter and verse counts and reading times.",
  "sources.intro":
    "Every plan in Day by Word has a recorded basis for use, and every source it relies on is listed here. Day by Word never shows Bible text: these sources give it counts and names, not words.",
  "sources.plans": "The plans",
  "sources.data": "References and reading times",
  "sources.data-intro":
    "Every reference in every plan is checked against these counts, and reading times are estimated from them.",
  "sources.kjv":
    "The number of chapters in each book and of verses in each chapter, the English numbering every reference is checked against. Only these counts are used, never the text.",
  "sources.web":
    "The number of words in each verse, from which reading times are estimated, and a second check of the chapter and verse counts. The World English Bible is in the public domain; only its counts are used.",
  "sources.stepbible":
    "A third, independent check of the chapter and verse counts, from its tables of how Bibles number their verses.",
  "sources.credit": "Credit:",
  "sources.stepbible-credit": "STEP Bible",
  "sources.cc-by": "Used under the Creative Commons Attribution 4.0 International licence.",
  "sources.books": "Book names and orders",
  "sources.books-intro":
    "Book names, abbreviations and orders were checked against these works, which are cited, not copied:",
  "sources.more": "Every source is recorded, with its evidence, in Day by Word's catalog.",

  "accessibility.title": "Accessibility",
  "accessibility.description":
    "Day by Word aims to meet WCAG 2.2 at level AA: what has been tested, what has not yet, and how to report a barrier.",
  "accessibility.aim":
    "Day by Word aims to meet the Web Content Accessibility Guidelines (WCAG) 2.2 at level AA, on the web and in the app, for every reader, whatever their sight, hearing, movement or way of reading.",
  "accessibility.tested": "What has been tested",
  "accessibility.tested-keyboard":
    "Every page can be used with a keyboard alone: each control is reached with Tab, with a visible outline, a link to skip to the content comes first, and after you mark a reading, focus stays with that plan.",
  "accessibility.tested-widths":
    "Every page is checked at phone widths down to 320 pixels without scrolling sideways, in light and dark.",
  "accessibility.tested-contrast":
    "Every pairing of text and background meets WCAG AA contrast, in light and dark, checked each time the colors change.",
  "accessibility.tested-words":
    'A reading\'s state is always in words or a symbol, never color alone, and references are written out for screen readers ("Mark, chapter 4, verses 1 to 20").',
  "accessibility.tested-app":
    "In the app, Today, Plans, Progress, a plan's page, its week and Settings are checked at the largest accessibility text size.",
  "accessibility.gaps": "Not yet tested",
  "accessibility.gap-screen-readers":
    "A full pass with screen readers: VoiceOver on every screen of the app, and VoiceOver and NVDA on the web.",
  "accessibility.gap-text":
    "The app's other screens (starting a plan, History, and Today with readings) at the largest text size.",
  "accessibility.gap-zoom":
    "The web at 400% zoom, and with forced colors (such as Windows contrast themes).",
  "accessibility.gap-settings":
    "The app with Bold Text, Reduce Transparency and Increase Contrast turned on.",
  "accessibility.gaps-note":
    "These checks are planned before version 1.0, and this page will say when they are done.",
  "accessibility.report": "Report a barrier",
  "accessibility.report-about":
    "If something in Day by Word is hard or impossible for you to use, please write to support@daybyword.com: say what you were trying to do, on which page or screen, and with what device, browser, or assistive technology.",
  "accessibility.report-write": "Report a barrier",

  "criteria.title": "How Day by Word chooses its plans",
  "criteria.description":
    "The standard every plan in Day by Word meets: checked references, exact coverage, a realistic workload, clear instructions, a recorded basis, stated limitations, and review.",
  "criteria.intro":
    "Day by Word offers a small number of reading plans and tries to tell you plainly what each one is. A plan is in the catalog only if it meets all of these.",
  "criteria.checked": "Every reference is checked.",
  "criteria.checked-about":
    "Each reading is checked against the chapters and verses of the Bible before the plan is published. A plan with a reference that does not exist is not published.",
  "criteria.coverage": "Coverage is stated exactly.",
  "criteria.coverage-about":
    "Each plan says whether it reads the whole Bible, whole books, or passages chosen from some books. These claims are computed from the plan's own readings, never written by hand: a plan that says it reads the whole Bible reads every verse, and its page shows any verses it repeats and anything it leaves out. Finishing a plan is not the same as reading the whole Bible, and Day by Word never treats it as if it were.",
  "criteria.workload": "The workload is realistic.",
  "criteria.workload-about":
    "Each plan shows roughly how long its readings take, from the lightest to the heaviest, counted from the number of words and typical reading speeds. These are estimates: reading slowly, reading aloud, stopping to reflect, or listening all change them.",
  "criteria.instructions": "The instructions are clear.",
  "criteria.instructions-about":
    "Each plan says how to follow it, which days it expects you to read, and what happens if you miss a day.",
  "criteria.basis": "Day by Word can show why it may offer the plan.",
  "criteria.basis-about":
    "Each plan has a recorded basis for use, listed on the sources page. Day by Word's own plans are labeled as original. A plan from another source is offered only with that source's permission or when it is in the public domain, and it is credited as the source asks.",
  "criteria.limitations": "Limitations are stated beside advantages.",
  "criteria.limitations-about":
    "Each plan's page says whom it suits and what it does not do, so you can choose with the whole picture.",
  "criteria.reviewed": "Each plan has been reviewed.",
  "criteria.reviewed-about":
    "Before it is published, each plan is checked against these criteria and against its own rules, and its description is checked for plain, neutral wording. The review level is shown on the plan's page.",
  "criteria.not":
    "Day by Word does not rank plans by popularity, does not recommend plans with artificial intelligence, and does not interpret Scripture or tell you what to believe.",
  "criteria.mistake": "If you find a mistake in a plan, please tell us through the support page.",

  "support.title": "Support",
  "support.description":
    "How to reach Day by Word, report a reading that looks wrong, and what is kept about you.",
  "support.intro": "For a question, a problem, or a reading that looks wrong, write to:",
  "support.address": "support@daybyword.com",
  "support.report": "A reading that looks wrong",
  "support.report-intro":
    "If a reading's reference doesn't match its plan, a passage seems to be left out, or a reading's time looks far off, please say so. It helps to include:",
  "support.report-plan": "the plan's name, as its page gives it;",
  "support.report-reading": "which reading: its number (such as Reading 12) or its date;",
  "support.report-what": "what looks wrong, and what you expected.",
  "support.report-write": "Write about a reading",
  "support.kept": "What is kept about you",
  "support.kept-record":
    "Your plans and what you mark are kept in your browser (in the app, on your device), not on Day by Word's server. To show Today and Progress, your browser sends your record to daybyword.com, which works out the page and keeps nothing.",
  "support.kept-logs":
    "The server notes each request's kind, the sort of page it was for (a plan's page, never which plan), its answer, and how long it took. It never notes the address you opened, what you sent, or where you are.",
  "support.kept-none": "There are no accounts, analytics, advertising, or tracking.",
  "support.kept-mail":
    "Mail to support@daybyword.com is forwarded to the inbox of the person who runs Day by Word, and is used only to answer you and to put right what you report.",
  "support.questions": "Questions people ask",
  "support.q-text": "Does Day by Word show the Bible text?",
  "support.a-text":
    "No. It shows each reading's references, and you read them in your own Bible: on paper, in an app, or as audio.",
  "support.q-translation": "Which translation should I use?",
  "support.a-translation":
    "Whichever you read. If you open readings in YouVersion or Bible.com, choose its translation in Settings.",
  "support.q-account": "Do I need an account?",
  "support.a-account":
    "No. Day by Word has no accounts. On the web, your plans and what you mark stay in this browser; in the app, on your device.",
  "support.q-away": "What if I don't read for a few days?",
  "support.a-away":
    "Nothing is lost. When you come back, you're welcomed back and choose how to go on, and nothing changes until you choose.",
  "support.q-move": "Can I take my record to another browser or device?",
  "support.a-move":
    "Day by Word doesn't sync between browsers or devices. Settings can export your reading record as a file, so you keep a copy.",
  "support.q-offline": "Does it work offline?",
  "support.a-offline":
    "Once you've opened it with a connection, Today, Plans, Progress and Settings open without one, and readings you mark offline are saved when you're back online.",
  "support.q-free": "Is Day by Word free?",
  "support.a-free": "Yes, and it has no ads.",
  "support.q-church": "Who makes Day by Word?",
  "settings.version": "Version {version}",
  "settings.development-version": "Development build",
  "not-found.title": "Page not found",
  "not-found.message":
    "There's no page at this address. It may have moved, or the link may be mistyped.",

  "component.copy-reference": "Copy reference",
  "component.copied": "Copied",
  "component.copy-failed": "Selected; copy it with your keyboard",
  "component.link-copied": "Link copied",
  "component.share-link-label": "Link to share",
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
  "offline.message":
    "This page isn't kept on this device yet. Today, Plans, Progress and Settings open without a connection, and so do the plan pages you've opened before.",
  "component.error-title": "Something went wrong",
  "component.error-message":
    "Day by Word couldn't show this page just now. Please try again in a moment. Your plans and what you've marked are kept in your browser, and nothing is lost.",
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
