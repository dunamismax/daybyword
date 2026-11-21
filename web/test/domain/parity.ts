// The shared fixtures (tests/fixtures/, docs/decisions.md E33) computed by the
// TypeScript domain module, exactly as Swift's FixtureTests compute them, so
// the same inputs give the same outputs in both runtimes. Browser-safe: the
// Node tests (domain.test.ts) and the browser page (test/browser/) both use
// it, each loading the files its own way.
import {
  addDays,
  BookRegistry,
  BookRegistryError,
  bookName,
  canonBooks,
  CivilDateError,
  civilDateText,
  dayOfYear,
  daysBetween,
  daysInMonth,
  isLeapYear,
  isPlanID,
  isWholeChapter,
  namingConventions,
  ordinal,
  parseCivilDate,
  parseReading,
  planWorkload,
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
  WordCountsError,
  workload,
  type BookName,
  type NamingConvention,
} from "#lib/domain/index.ts";

export interface Resources {
  registry: BookRegistry;
  english: Versification;
  counts: WordCounts;
}

export interface FixtureCase {
  input: unknown;
  output?: unknown;
}

export interface FixtureFile {
  fixture: string;
  version: number;
  about: string;
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
] as const;
export type DomainFixture = (typeof domainFixtures)[number];

type Compute = (input: never) => unknown;

/** Leaves out undefined fields, as Swift's encoder leaves out nil ones. */
function present<T extends object>(value: T): T {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined)) as T;
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
    file.cases.forEach((testCase, index) => {
      report.cases += 1;
      let actual: unknown;
      try {
        actual = (compute[name] as (input: unknown) => unknown)(testCase.input);
      } catch (error) {
        actual = { thrown: String(error) };
      }
      if (canonicalJSON(actual) !== canonicalJSON(testCase.output)) {
        report.failures.push(
          `${name} case ${index} (${JSON.stringify(testCase.input).slice(0, 60)}): expected ${canonicalJSON(testCase.output).slice(0, 300)}, got ${canonicalJSON(actual).slice(0, 300)}`,
        );
      }
    });
  }
  return report;
}
