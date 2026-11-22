// Choosing a plan (docs/engine.md, "Choosing a plan"; BUILD.md P9.2, P9.3):
// the goals the catalog groups its plans by, and recommendations from a
// reader's answers by fixed rules, as Swift's Choosing gives them. Never
// popularity, never anything the reader did not say, and never AI (D12,
// D23).
import type { ScheduleKind } from "./plan.ts";
import { workload } from "./workload.ts";

/** What a reader may hope to read, in the order the plan list shows them. */
export const goals = [
  "begin",
  "whole-bible",
  "new-testament",
  "gospels",
  "psalms-proverbs",
] as const;
export type Goal = (typeof goals)[number];

export function isGoal(value: unknown): value is Goal {
  return typeof value === "string" && (goals as readonly string[]).includes(value);
}

/** How long a reading may take: about 5 minutes, about 10, or 15 or more. */
export const times = ["short", "medium", "long"] as const;
export type Time = (typeof times)[number];

export function isTime(value: unknown): value is Time {
  return typeof value === "string" && (times as readonly string[]).includes(value);
}

// The most minutes a typical reading may take to fit (none for long), and the
// minutes each answer stands for.
const limits: Record<Time, number | undefined> = { short: 5, medium: 10, long: undefined };
const targets: Record<Time, number> = { short: 5, medium: 10, long: 15 };

/** The reader's answers; an absent one is "not sure". */
export interface Answers {
  hope?: Goal;
  time?: Time;
  /** The days a week the reader expects to read, 1 to 7. */
  days?: number;
}

/** A plan as the catalog gives it. */
export interface Candidate {
  plan: string;
  goals: readonly Goal[];
  schedule: ScheduleKind;
  /** The reading days a week the plan is paced for. */
  readingDays: number;
  readings: number;
  /** The words of its typical (middle) reading. */
  typicalWords: number;
}

/** One recommended plan with the facts the reader sees as its reasons. */
export interface Recommendation {
  plan: string;
  /** The reader's goal, or begin when they gave none and the plan is in it. */
  goal?: Goal;
  /** The typical reading's minutes, `[low, high]`. */
  minutes: [number, number];
  fitsTime?: boolean;
  readerDays?: number;
  fitsDays?: boolean;
  /** A sequence's readings a week: the fewer of the reader's days and the plan's. */
  perWeek?: number;
  /** The weeks a sequence takes at those; absent for a day-of-month plan. */
  weeks?: number;
}

/** The plans to recommend, from the candidates in the catalog's order: at most three, best first. */
export function recommend(candidates: readonly Candidate[], answers: Answers): Recommendation[] {
  const { hope, time, days } = answers;
  if (days !== undefined && !(Number.isInteger(days) && days >= 1 && days <= 7)) {
    throw new RangeError("a week has 1 to 7 reading days");
  }
  const ranked = candidates
    .map((candidate, order) => ({ candidate, order }))
    .filter(({ candidate }) => hope === undefined || candidate.goals.includes(hope))
    .map(({ candidate, order }) => {
      const minutes = workload(candidate.typicalWords).minutes;
      const limit = time === undefined ? undefined : limits[time];
      const fitsTime = time === undefined ? undefined : limit === undefined || minutes[0] <= limit;
      const fitsDays = days === undefined ? undefined : candidate.readingDays <= days;
      const key = [
        (fitsTime === false ? 1 : 0) + (fitsDays === false ? 1 : 0),
        hope === undefined && !candidate.goals.includes("begin") ? 1 : 0,
        days === undefined ? 0 : Math.abs(candidate.readingDays - days),
        time === undefined ? 0 : Math.abs(minutes[0] - targets[time]),
        order,
      ];
      return { candidate, minutes, fitsTime, fitsDays, key };
    });
  ranked.sort((a, b) => {
    for (let i = 0; i < a.key.length; i += 1) {
      const difference = (a.key[i] ?? 0) - (b.key[i] ?? 0);
      if (difference !== 0) return difference;
    }
    return 0;
  });
  return ranked.slice(0, 3).map(({ candidate, minutes, fitsTime, fitsDays }) => {
    const perWeek = Math.min(days ?? candidate.readingDays, candidate.readingDays);
    const goal = hope ?? (candidate.goals.includes("begin") ? "begin" : undefined);
    const recommendation: Recommendation = { plan: candidate.plan, minutes };
    if (goal !== undefined) recommendation.goal = goal;
    if (fitsTime !== undefined) recommendation.fitsTime = fitsTime;
    if (days !== undefined) recommendation.readerDays = days;
    if (fitsDays !== undefined) recommendation.fitsDays = fitsDays;
    if (candidate.schedule === "sequence") {
      recommendation.perWeek = perWeek;
      recommendation.weeks = Math.ceil(candidate.readings / perWeek);
    }
    return recommendation;
  });
}
