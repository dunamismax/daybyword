// The shared fixtures (tests/fixtures/, docs/decisions.md E33) computed by the
// TypeScript domain module, exactly as Swift's FixtureTests compute them, so
// the same inputs give the same outputs in both runtimes. Browser-safe: the
// Node tests (domain.test.ts) and the browser page (test/browser/) both use
// it, each loading the files its own way.
import {
  type Answers,
  type Candidate,
  recommend,
  addDays,
  assignmentPositions,
  bibleLink,
  bibleTranslation,
  BookRegistry,
  BookRegistryError,
  bookName,
  celebrations,
  canonBooks,
  changeOf,
  coverage,
  coverageByBook,
  CivilDateError,
  civilDateText,
  comingDays,
  eventIDMilliseconds,
  foldJournal,
  isEventID,
  JournalError,
  makeEventID,
  dayOfYear,
  daysBetween,
  daysInMonth,
  isLeapYear,
  isPlanID,
  isWholeChapter,
  journalEventWire,
  namingConventions,
  ordinal,
  parseCivilDate,
  parseWallTime,
  parseReading,
  planWorkload,
  previewing,
  progressCounts,
  recentDays,
  recordSlots,
  reminders,
  streak,
  today,
  welcome,
  welcomeAnswer,
  readingText,
  readingVerseCount,
  ReferenceFormatError,
  ReferenceFormatter,
  spanCount,
  VerseSet,
  Versification,
  VersificationError,
  weekday,
  WordCounts,
  wallTimeText,
  WordCountsError,
  workload,
  type Behavior,
  type ChapterCoverage,
  type BookName,
  type NamingConvention,
  type CivilDate,
  type Enrollment,
  type PlanVersion,
  type WallTime,
  type ScheduleKind,
  type Slot,
} from "#lib/domain/index.ts";

export interface Resources {
  registry: BookRegistry;
  english: Versification;
  counts: WordCounts;
}

export interface FixtureCase {
  /** What the case shows, in the scheduling fixtures. */
  name?: string;
  input: unknown;
  output?: unknown;
}

/** An invented plan version in a scheduling fixture's `plans`. */
export interface FixturePlan {
  id: string;
  version: number;
  schedule: ScheduleKind;
  behaviors: Behavior[];
  readingDays: number;
  assignments: { id: number; reading: string }[];
}

export interface FixtureFile {
  fixture: string;
  version: number;
  about: string;
  /** The invented plans a scheduling fixture's cases enroll in. */
  plans?: FixturePlan[];
  cases: FixtureCase[];
}

/** The fixtures the domain module answers, and the Swift test that checks each. */
export const domainFixtures = [
  "references",
  "coverage",
  "workload",
  "plan-workload",
  "scripture",
  "plan-ids",
  "scripture-files",
  "civil-dates",
  "event-ids",
  "journal",
  "today",
  "returning",
  "changing",
  "progress",
  "celebrations",
  "reminders",
  "ahead",
  "bible-links",
  "recommendations",
] as const;
export type DomainFixture = (typeof domainFixtures)[number];

/** A fixture's answer for one input; the scheduling fixtures are also given the file's plans. */
type Compute = (input: never, plans: readonly PlanVersion[]) => unknown;

/** Leaves out undefined fields, as Swift's encoder leaves out nil ones. */
function present<T extends object>(value: T): { [K in keyof T]: Exclude<T[K], undefined> } {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as {
    [K in keyof T]: Exclude<T[K], undefined>;
  };
}

/** One fixture's answer for an input, which is whatever shape its file gives. */
export function answer(
  compute: Record<DomainFixture, Compute>,
  name: DomainFixture,
  input: unknown,
  plans: readonly PlanVersion[],
): unknown {
  return (compute[name] as unknown as (input: unknown, plans: readonly PlanVersion[]) => unknown)(
    input,
    plans,
  );
}

/** A fixture file's invented plans, as the engine takes them. */
export function fixturePlans(file: FixtureFile, resources: Resources): PlanVersion[] {
  return (file.plans ?? []).map((plan) => {
    const assignments = plan.assignments.map((assignment) => ({
      id: assignment.id,
      reading: parseReading(assignment.reading, resources.english),
    }));
    // Each reading's words from the counts, as the catalog would carry them.
    const words = new Map<number, number>();
    for (const assignment of assignments) {
      const count = resources.counts.wordsInReading(assignment.reading);
      if (count !== undefined) words.set(assignment.id, count);
    }
    return { ...plan, assignments, words };
  });
}

export function computers(resources: Resources): Record<DomainFixture, Compute> {
  const { registry, english, counts } = resources;
  return {
    references: (text: string) => {
      let r;
      try {
        r = parseReading(text, english);
      } catch (error) {
        if (error instanceof ReferenceFormatError) {
          return { error: error.kind, message: error.message };
        }
        throw error;
      }
      const words = counts.wordsInReading(r);
      const display: Record<string, { full: string; abbreviated: string }> = {};
      for (const convention of namingConventions) {
        const formatter = new ReferenceFormatter(registry, english, convention);
        display[convention] = {
          full: formatter.reading(r, "full"),
          abbreviated: formatter.reading(r, "abbreviated"),
        };
      }
      return present({
        text: readingText(r, english),
        passages: r.passages.map((p) => ({
          book: p.book,
          start: `${p.start.chapter}:${p.start.verse}`,
          end: `${p.end.chapter}:${p.end.verse}`,
        })),
        verses: readingVerseCount(r, english),
        words,
        minutes: words === undefined ? undefined : workload(words).minutes,
        display,
      });
    },

    coverage: (texts: string[]) => {
      const readings = texts.map((t) => parseReading(t, english));
      const passages = readings.flatMap((r) => r.passages);
      const covered = VerseSet.of(passages, english);
      const chapters = covered.chapters(english);
      return {
        verses: readings.reduce((sum, r) => sum + readingVerseCount(r, english), 0),
        uniqueVerses: covered.count,
        repeats: VerseSet.repeats(passages, english)
          .passages(english)
          .map((p) => readingText({ passages: [p] }, english)),
        wholeChapters: chapters.filter(isWholeChapter).length,
        partialChapters: chapters.filter((c) => !isWholeChapter(c)).length,
        books: Object.fromEntries([...covered.books].map((b) => [b, covered.countIn(b)])),
      };
    },

    workload: (words: number) => {
      const w = workload(words);
      return { silentMinutes: w.silentMinutes, aloudMinutes: w.aloudMinutes, minutes: w.minutes };
    },

    "plan-workload": (words: number[]) => {
      const w = planWorkload(words);
      return w
        ? { minimum: w.minimum.words, median: w.median.words, maximum: w.maximum.words }
        : {};
    },

    scripture: (scheme: string) => {
      if (scheme !== english.scheme) throw new Error(`no scheme ${scheme}`);
      const books = registry.books.map((book) => {
        const chapters = english.chapters(book.id);
        const names = Object.fromEntries(
          namingConventions.map((c: NamingConvention) => [c, bookName(book, c)]),
        ) as Record<NamingConvention, BookName>;
        return present({
          id: book.id,
          testament: book.testament,
          chapters: chapters && [chapters.first, chapters.last],
          verses: chapters && english.verseCount(book.id),
          words: counts.wordsOfBook(book.id),
          names,
        });
      });
      const canons = registry.canons.map((canon) => {
        const listed = canonBooks(canon);
        const numbered = listed.filter((b) => english.chapters(b) !== undefined);
        const words = listed.map((b) => counts.wordsOfBook(b));
        return present({
          id: canon.id,
          books: listed,
          orders: Object.fromEntries(canon.orders.map((o) => [o.id, o.books.length])),
          chapters: numbered.reduce((sum, b) => {
            const range = english.chapters(b);
            return sum + (range ? spanCount(range) : 0);
          }, 0),
          verses: numbered.reduce((sum, b) => sum + english.verseCount(b), 0),
          words: words.includes(undefined)
            ? undefined
            : words.reduce<number>((sum, w) => sum + (w ?? 0), 0),
        });
      });
      return { books, canons };
    },

    "plan-ids": (text: string) => isPlanID(text),

    "scripture-files": ({ file, text }: { file: string; text: string }) => {
      try {
        if (file === "registry") {
          const read = new BookRegistry(text);
          return { books: read.books.map((b) => b.id), canons: read.canons.map((c) => c.id) };
        }
        if (file === "versification") {
          const scheme = new Versification("english", text);
          const verses = scheme.books.reduce((sum, b) => sum + scheme.verseCount(b), 0);
          return { books: scheme.books, verses };
        }
        if (file !== "word-counts") throw new Error(`no file kind ${file}`);
        const read = new WordCounts(text, english);
        const words = read.books.reduce((sum, b) => sum + (read.wordsOfBook(b) ?? 0), 0);
        return { books: read.books, words };
      } catch (error) {
        if (error instanceof BookRegistryError && error.kind === "unreadable") {
          return { error: error.kind };
        }
        if (
          error instanceof BookRegistryError ||
          error instanceof VersificationError ||
          error instanceof WordCountsError
        ) {
          return { error: error.kind, message: error.message };
        }
        throw error;
      }
    },
    "civil-dates": (input: { text: string; add?: number; to?: string }) => {
      const kindOf = (error: unknown) => {
        if (error instanceof CivilDateError) return error;
        throw error;
      };
      let date;
      try {
        date = parseCivilDate(input.text);
      } catch (error) {
        const problem = kindOf(error);
        return { error: problem.kind, message: problem.message };
      }
      let sum, sumError, daysTo, toError;
      if (input.add !== undefined) {
        try {
          sum = civilDateText(addDays(date, input.add));
        } catch (error) {
          sumError = kindOf(error).kind;
        }
      }
      if (input.to !== undefined) {
        try {
          daysTo = daysBetween(date, parseCivilDate(input.to));
        } catch (error) {
          toError = kindOf(error).kind;
        }
      }
      return present({
        date: civilDateText(date),
        weekday: weekday(date),
        daysInMonth: daysInMonth(date.month, date.year),
        dayOfYear: dayOfYear(date),
        leapYear: isLeapYear(date.year),
        ordinal: ordinal(date),
        sum,
        sumError,
        daysTo,
        toError,
      });
    },

    "event-ids": (input: { text?: string; milliseconds?: number; random?: number[] }) => {
      if (input.text !== undefined) {
        const valid = isEventID(input.text);
        return present({
          valid,
          milliseconds: valid ? eventIDMilliseconds(input.text) : undefined,
        });
      }
      const id = makeEventID(input.milliseconds as number, input.random as number[]);
      return id === undefined ? {} : { id, milliseconds: eventIDMilliseconds(id) };
    },

    journal: (input: { events: unknown[]; on?: string[] }, plans: readonly PlanVersion[]) => {
      let journal;
      try {
        journal = foldJournal(input.events, plans);
      } catch (error) {
        if (error instanceof JournalError) return { error: error.kind, message: error.message };
        throw error;
      }
      const dates = (input.on ?? []).map(parseCivilDate);
      const inert = new Set(journal.inert.map((entry) => entry.event));
      const text = (date: Parameters<typeof civilDateText>[0] | undefined) =>
        date && civilDateText(date);
      return {
        events: journal.events.length,
        inert: journal.inert,
        undone: journal.events
          .map((event) => event.id)
          .filter((id) => !inert.has(id) && !journal.isActive(id)),
        enrollments: journal.enrollments.map((enrollment) =>
          present({
            id: enrollment.id,
            plan: enrollment.plan.id,
            version: enrollment.plan.version,
            start: civilDateText(enrollment.start),
            ended: text(enrollment.ended),
            slots: enrollment.settled.map((slot) =>
              present({
                assignment: slot.assignment,
                appointed: text(slot.appointed),
                state: slot.state,
                date: civilDateText(slot.date),
                event: slot.event,
                verses: slot.verses,
              }),
            ),
            paused: enrollment.pauses.map((pause) =>
              present({ from: civilDateText(pause.from), until: text(pause.until) }),
            ),
            on:
              dates.length === 0
                ? undefined
                : dates.map((date) => {
                    const arrangement = enrollment.arrangement(date);
                    return present({
                      date: civilDateText(date),
                      behavior: arrangement.behavior,
                      readingDays: arrangement.readingDays,
                      limit: arrangement.limit,
                      reminder: arrangement.reminder && wallTimeText(arrangement.reminder),
                      paused: enrollment.isPaused(date),
                    });
                  }),
          }),
        ),
      };
    },

    today: (input: { events: unknown[]; today: string }, plans: readonly PlanVersion[]) => {
      const journal = foldJournal(input.events, plans);
      const date = parseCivilDate(input.today);
      const text = (day: CivilDate | undefined) => day && civilDateText(day);
      return {
        enrollments: journal.enrollments.map((enrollment) => {
          const positions = assignmentPositions(enrollment.plan);
          const place = (slot: Slot) =>
            present({
              assignment: slot.assignment,
              position: positions.get(slot.assignment) ?? 0,
              appointed: text(slot.appointed),
            });
          const answer = today(enrollment, date);
          const { projection, schedule, calendar } = answer;
          return present({
            id: enrollment.id,
            status: answer.status,
            readingDay: answer.isReadingDay,
            readings: answer.readings.map(place),
            readToday: answer.readToday.map(place),
            next: answer.next && place(answer.next),
            projection:
              projection &&
              present({
                plan: text(projection.plan),
                recent: text(projection.recent),
                unbroken: text(projection.unbroken),
              }),
            schedule:
              schedule &&
              present({
                ...schedule,
                first: civilDateText(schedule.first),
                finish: civilDateText(schedule.finish),
                finishWithinLimit: text(schedule.finishWithinLimit),
              }),
            calendar: calendar && { ...calendar, appointment: place(calendar.appointment) },
          });
        }),
      };
    },

    returning: (input: { events: unknown[]; today: string }, plans: readonly PlanVersion[]) => {
      const journal = foldJournal(input.events, plans);
      const date = parseCivilDate(input.today);
      const text = (day: CivilDate | undefined) => day && civilDateText(day);
      return {
        enrollments: journal.enrollments.map((enrollment) => {
          const offered = welcome(enrollment, date);
          if (!offered) return { id: enrollment.id, welcome: false };
          const choices = offered.offers.map((offer) => {
            const previewed = previewing(journal, welcomeAnswer(offer, date), enrollment.id);
            const after = previewed?.enrollments.find((other) => other.id === enrollment.id);
            if (!previewed || !after) throw new Error("no preview");
            if (canonicalJSON(previewed.inert) !== canonicalJSON(journal.inert)) {
              throw new Error("the candidate event is inert");
            }
            const positions = assignmentPositions(after.plan);
            const answer = today(after, date);
            return present({
              choice: offer.choice,
              finish: text(offer.finish),
              remaining: offer.remaining,
              most: offer.most,
              preview: present({
                status: answer.status,
                readings: answer.readings.map((slot) => positions.get(slot.assignment) ?? 0),
                finish: text(answer.schedule?.finish ?? answer.projection?.plan),
                most: answer.schedule?.most,
                welcome: welcome(after, date) !== undefined,
              }),
            });
          });
          return present({
            id: enrollment.id,
            welcome: true,
            choices,
            spreadNeeds: offered.spreadNeeds,
          });
        }),
      };
    },

    changing: (
      input: {
        events: unknown[];
        today: string;
        change: {
          from: string;
          start?: string;
          readingDays?: number[];
          behavior?: Behavior;
          finish?: string;
          limit?: number;
          reminder?: string;
        };
      },
      plans: readonly PlanVersion[],
    ) => {
      const journal = foldJournal(input.events, plans);
      const date = parseCivilDate(input.today);
      const enrollment = journal.enrollments[0];
      if (!enrollment) throw new Error("no enrollment");
      const { change } = input;
      const body = changeOf(
        enrollment,
        present({
          from: parseCivilDate(change.from),
          start: change.start === undefined ? undefined : parseCivilDate(change.start),
          readingDays: change.readingDays,
          behavior: change.behavior,
          finish: change.finish === undefined ? undefined : parseCivilDate(change.finish),
          limit: change.limit,
          reminder:
            change.reminder === undefined || change.reminder === "off"
              ? change.reminder
              : parseWallTime(change.reminder),
        }),
      );
      const previewed = previewing(journal, body, enrollment.id);
      const candidate = previewed?.events.at(-1);
      const after = previewed?.enrollments[0];
      if (!previewed || !candidate || !after) throw new Error("no preview");
      const record = ["id", "enrollment", "at", "zone", "device"];
      const event = Object.fromEntries(
        Object.entries(journalEventWire(candidate)).filter(([name]) => !record.includes(name)),
      );
      const day = (of: Enrollment) => {
        const positions = assignmentPositions(of.plan);
        const answer = today(of, date);
        const finish = answer.schedule?.finish ?? answer.projection?.plan;
        const within = answer.schedule?.finishWithinLimit;
        return present({
          status: answer.status,
          readings: answer.readings.map((slot) => positions.get(slot.assignment) ?? 0),
          finish: finish && civilDateText(finish),
          most: answer.schedule?.most,
          finishWithinLimit: within && civilDateText(within),
          start: civilDateText(of.start),
          readingDay: answer.isReadingDay,
          settled: of.settled.length,
        });
      };
      return present({
        event,
        inert: previewed.inert.find((entry) => entry.event === candidate.id)?.reason,
        before: day(enrollment),
        after: day(after),
      });
    },

    progress: (input: { events: unknown[]; today: string }, plans: readonly PlanVersion[]) => {
      const journal = foldJournal(input.events, plans);
      const date = parseCivilDate(input.today);
      const covered = coverage(journal, english);
      const whole = (chapters: readonly ChapterCoverage[]) =>
        chapters.filter(isWholeChapter).length;
      return {
        enrollments: journal.enrollments.map((enrollment) => {
          const counts = progressCounts(enrollment, date);
          // History lists the slots the counts count (P11.5), as Swift's test checks.
          if (recordSlots(enrollment, date).length !== counts.total) {
            throw new Error(`recordSlots disagrees with the total for ${enrollment.id}`);
          }
          return { id: enrollment.id, ...counts };
        }),
        recent: recentDays(journal, date).map((day) => ({
          date: civilDateText(day.date),
          read: day.isRead,
          readingDay: day.isReadingDay,
        })),
        coverage: {
          verses: covered.verses.count,
          passages: covered.verses
            .passages(english)
            .map((passage) => readingText({ passages: [passage] }, english)),
          wholeChapters: whole(covered.chapters),
          partialChapters: covered.chapters.length - whole(covered.chapters),
          books: coverageByBook(covered, english),
        },
        streak: streak(journal, date),
      };
    },

    celebrations: (input: { events: unknown[]; today: string }, plans: readonly PlanVersion[]) => {
      const journal = foldJournal(input.events, plans);
      return {
        celebrations: celebrations(journal, parseCivilDate(input.today), english),
      };
    },

    reminders: (
      input: {
        events: unknown[];
        today: string;
        time: string;
        quiet?: { from: string; until: string };
        most?: number;
        window?: number;
        snoozes?: { enrollment: string; date: string; time: string }[];
      },
      plans: readonly PlanVersion[],
    ) => {
      const journal = foldJournal(input.events, plans);
      const time = (text: string): WallTime => {
        const parsed = parseWallTime(text);
        if (!parsed) throw new Error(`${text} is not a time`);
        return parsed;
      };
      const settings = present({
        quietHours: input.quiet && { from: time(input.quiet.from), until: time(input.quiet.until) },
        mostADay: input.most,
        window: input.window ?? 60,
        snoozes: (input.snoozes ?? []).map((snooze) => {
          if (!isEventID(snooze.enrollment)) throw new Error("not an enrollment id");
          return {
            enrollment: snooze.enrollment,
            at: { date: parseCivilDate(snooze.date), time: time(snooze.time) },
          };
        }),
      });
      const now = { date: parseCivilDate(input.today), time: time(input.time) };
      return {
        reminders: reminders(journal, now, settings).map((reminder) => {
          const plan = journal.enrollments.find((other) => other.id === reminder.enrollment)?.plan;
          const { slot } = reminder;
          return present({
            enrollment: reminder.enrollment,
            date: civilDateText(reminder.at.date),
            time: wallTimeText(reminder.at.time),
            assignment: slot?.assignment,
            position: slot && plan && assignmentPositions(plan).get(slot.assignment),
            appointed: slot?.appointed && civilDateText(slot.appointed),
            snooze: reminder.isSnooze ? true : undefined,
          });
        }),
      };
    },
    ahead: (
      input: { events: unknown[]; today: string; days: number },
      plans: readonly PlanVersion[],
    ) => {
      const journal = foldJournal(input.events, plans);
      const date = parseCivilDate(input.today);
      return {
        enrollments: journal.enrollments.map((enrollment) => {
          const positions = assignmentPositions(enrollment.plan);
          return {
            id: enrollment.id,
            days: comingDays(enrollment, date, input.days).map((day) => ({
              date: civilDateText(day.date),
              readingDay: day.isReadingDay,
              readings: day.readings.map((slot) =>
                present({
                  assignment: slot.assignment,
                  position: positions.get(slot.assignment) ?? 0,
                  appointed: slot.appointed && civilDateText(slot.appointed),
                }),
              ),
            })),
          };
        }),
      };
    },

    "bible-links": (input: { reading: string; translation: number }) => {
      const translation = bibleTranslation(input.translation);
      if (!translation) return { error: "unknownTranslation" };
      const link = bibleLink(parseReading(input.reading, english), translation, english);
      return present({
        url: link.address,
        whole: link.isWholeReading,
        opensAt: link.isWholeReading ? undefined : `${link.book} ${link.chapter}`,
        abbreviation: translation.abbreviation,
        name: translation.name,
      });
    },

    recommendations: (input: { answers: Answers; candidates: Candidate[] }) => ({
      recommendations: recommend(input.candidates, input.answers),
    }),
  };
}

/** JSON with sorted keys, so two values compare by content alone. */
export function canonicalJSON(value: unknown): string {
  return JSON.stringify(value, (_key, v: unknown) =>
    v && typeof v === "object" && !Array.isArray(v)
      ? Object.fromEntries(Object.entries(v).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)))
      : v,
  );
}

export interface ParityReport {
  cases: number;
  failures: string[];
}

/** Every case of every domain fixture, compared by content; the failures name the case. */
export function checkParity(
  resources: Resources,
  fixtures: Record<DomainFixture, FixtureFile>,
): ParityReport {
  const compute = computers(resources);
  const report: ParityReport = { cases: 0, failures: [] };
  for (const name of domainFixtures) {
    const file = fixtures[name];
    if (file.fixture !== name || file.cases.length === 0) {
      report.failures.push(`${name}: not the ${name} fixture, or it has no cases`);
      continue;
    }
    let plans: PlanVersion[];
    try {
      plans = fixturePlans(file, resources);
    } catch (error) {
      report.failures.push(`${name}: its plans could not be read: ${String(error)}`);
      continue;
    }
    file.cases.forEach((testCase, index) => {
      report.cases += 1;
      let actual: unknown;
      try {
        actual = answer(compute, name, testCase.input, plans);
      } catch (error) {
        actual = { thrown: String(error) };
      }
      if (canonicalJSON(actual) !== canonicalJSON(testCase.output)) {
        report.failures.push(
          `${name} case ${index} (${testCase.name ?? JSON.stringify(testCase.input).slice(0, 60)}): expected ${canonicalJSON(testCase.output).slice(0, 300)}, got ${canonicalJSON(actual).slice(0, 300)}`,
        );
      }
    });
  }
  return report;
}
