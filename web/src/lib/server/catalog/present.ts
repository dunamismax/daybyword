// What the plan pages show, worked out on the server from the served
// catalog: a plan's facts are the compiler's, its workload and its sample
// week the domain module's (docs/engine.md), and its words the string
// table's. Nothing here restates a reading rule.
import {
  civilDate,
  civilDateText,
  comingDays,
  foldJournal,
  makeEventID,
  parseReading,
  ReferenceFormatter,
  weekday,
  workload,
  type Behavior,
} from "#lib/domain/index.ts";
import { referenceOf, type Reference } from "#lib/reference.ts";
import {
  listText,
  minutesRangeText,
  text,
  workloadRangeText,
  type StringKey,
} from "#lib/strings.ts";
import type { CatalogPlan, ServedCatalog } from "./read.ts";

const weekdays = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
] as const;

/** A plan in the list. */
export interface PlanSummary {
  readonly id: string;
  readonly href: string;
  readonly title: string;
  readonly kind: string;
  readonly summary: string;
  /** A typical reading's workload, in words. */
  readonly workload: string;
  readonly readings: string;
}

/** One line of a sample week; a rest day has no reference. */
export interface SampleDay {
  readonly label: string;
  readonly reference?: Reference;
}

export interface PlanPage extends PlanSummary {
  readonly creator: string;
  readonly suits: string;
  readonly paced: string;
  readonly workloads: readonly { readonly label: string; readonly text: string }[];
  readonly sample: readonly SampleDay[];
  readonly sampleNote: string;
  readonly covers: readonly string[];
  readonly how: string;
  readonly behaviors: readonly { readonly name: string; readonly about: string }[];
  readonly instructions: string;
  readonly limitations: string;
  readonly source: string;
  readonly review: string;
}

const count = (value: number) => new Intl.NumberFormat("en").format(value);

function readingsText(readings: number): string {
  return readings === 1
    ? text("plan.readings-one")
    : text("plan.readings-other", { count: count(readings) });
}

export function planSummary(entry: CatalogPlan): PlanSummary {
  return {
    id: entry.id,
    href: `/plans/${entry.id}`,
    title: entry.title,
    kind: text(entry.plan.schedule === "sequence" ? "plan.kind-sequence" : "plan.kind-calendar"),
    summary: entry.summary,
    workload: workloadRangeText(workload(entry.facts.wordsMedian).minutes),
    readings: readingsText(entry.plan.assignments.length),
  };
}

/** The plans as the list shows them: the shortest first, then by title. */
export function planList(catalog: ServedCatalog): PlanSummary[] {
  return [...catalog.plans]
    .sort(
      (a, b) =>
        a.plan.assignments.length - b.plan.assignments.length ||
        a.title.localeCompare(b.title, "en"),
    )
    .map(planSummary);
}

// A Monday that is also the first of a month, so one start serves both
// kinds of sample: a week from a Monday, and a month's first seven days.
const sampleStart = civilDate(2001, 1, 1);

/**
 * A plan's sample week: the engine's days ahead for a reader who starts on
 * `sampleStart` with the plan's own pace, on the first of its reading days
 * of the week.
 */
export function sampleWeek(catalog: ServedCatalog, entry: CatalogPlan): SampleDay[] {
  const { plan } = entry;
  const zeros = new Array<number>(10).fill(0);
  const journal = foldJournal(
    [
      {
        id: makeEventID(1, zeros),
        kind: "enrolled",
        enrollment: makeEventID(0, zeros),
        at: "2001-01-01T00:00:00Z",
        zone: "UTC",
        device: "sample",
        plan: plan.id,
        version: plan.version,
        behavior: plan.behaviors[0],
        start: civilDateText(sampleStart),
        readingDays: weekdays.slice(0, plan.readingDays).map((_, index) => index + 1),
      },
    ],
    [plan],
  );
  const enrollment = journal.enrollments[0];
  if (!enrollment) return [];
  const formatter = new ReferenceFormatter(catalog.registry, catalog.versification);
  const readings = new Map(
    plan.assignments.map((assignment) => [assignment.id, assignment.reading]),
  );
  return comingDays(enrollment, sampleStart, 7).map((day) => {
    const label =
      plan.schedule === "sequence"
        ? text(`weekday.${weekdays[weekday(day.date) - 1] ?? "monday"}`)
        : text("plan.sample-day", { day: String(day.date.day) });
    const reading = day.readings[0] && readings.get(day.readings[0].assignment);
    return reading ? { label, reference: referenceOf(reading, formatter) } : { label };
  });
}

const behaviorKeys: Record<Behavior, [StringKey, StringKey]> = {
  pace: ["plan.behavior-pace", "plan.behavior-pace-about"],
  "finish-date": ["plan.behavior-finish-date", "plan.behavior-finish-date-about"],
  calendar: ["plan.behavior-calendar", "plan.behavior-calendar-about"],
};

function covers(catalog: ServedCatalog, entry: CatalogPlan): string[] {
  const { facts } = entry;
  const formatter = new ReferenceFormatter(catalog.registry, catalog.versification);
  const names = entry.books.map((id) => {
    const book = catalog.registry.book(id);
    return book ? book.commonName.name : id;
  });
  const verses = count(facts.uniqueVerses);
  const canon = catalog.registry.canon(entry.canon);
  const lines: string[] = [];
  if (entry.coverage === "whole-bible") {
    lines.push(
      text("plan.covers-whole-bible", {
        label: canon?.label ?? "",
        canon: text(`canon.${entry.canon}` as StringKey),
        verses,
      }),
    );
  } else {
    lines.push(
      text(entry.coverage === "books" ? "plan.covers-books" : "plan.covers-selection", {
        books: listText(names),
        verses,
      }),
    );
  }
  if (facts.repeats === "") {
    lines.push(text("plan.covers-no-repeats"));
  } else {
    const passages = facts.repeats
      .split("; ")
      .map((passage) => formatter.reading(parseReading(passage, catalog.versification)));
    lines.push(text("plan.covers-repeats", { passages: listText(passages) }));
  }
  if (entry.coverage !== "whole-bible") lines.push(text("plan.completion-note"));
  return lines;
}

export function planPage(catalog: ServedCatalog, entry: CatalogPlan): PlanPage {
  const { plan, facts } = entry;
  const minutes = (words: number) => minutesRangeText(workload(words).minutes);
  return {
    ...planSummary(entry),
    creator: text("plan.by", { creator: entry.creator }),
    suits: entry.suits,
    paced:
      plan.readingDays === 7
        ? text("plan.paced-every-day")
        : plan.readingDays === 1
          ? text("plan.paced-one")
          : text("plan.paced-other", { days: String(plan.readingDays) }),
    workloads: [
      { label: text("plan.workload-typical"), text: minutes(facts.wordsMedian) },
      { label: text("plan.workload-lightest"), text: minutes(facts.wordsMinimum) },
      { label: text("plan.workload-heaviest"), text: minutes(facts.wordsMaximum) },
    ],
    sample: sampleWeek(catalog, entry),
    sampleNote: text(
      plan.schedule === "sequence" ? "plan.sample-sequence" : "plan.sample-calendar",
    ),
    covers: covers(catalog, entry),
    how: text(plan.schedule === "sequence" ? "plan.how-sequence" : "plan.how-calendar"),
    behaviors: plan.behaviors.map((behavior) => ({
      name: text(behaviorKeys[behavior][0]),
      about: text(behaviorKeys[behavior][1]),
    })),
    instructions: entry.instructions,
    limitations: entry.limitations,
    source: entry.source,
    review: text(`plan.review-${entry.review}` as StringKey),
  };
}
