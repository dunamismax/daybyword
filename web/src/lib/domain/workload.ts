// How long a reading takes, from its words, as Swift's Workload and
// PlanWorkload estimate it: about 238 words a minute read silently and 183
// aloud (Research finding 6). Estimates only, and the reader is told so.
import { roundHalfAwayFromZero } from "./numbers.ts";
import type { Reading } from "./passage.ts";
import type { WordCounts } from "./word-counts.ts";

export const silentWordsPerMinute = 238;
export const aloudWordsPerMinute = 183;

export interface Workload {
  words: number;
  silentMinutes: number;
  aloudMinutes: number;
  /** The range the reader sees, `[low, high]`, which may be one number twice. */
  minutes: [number, number];
}

/**
 * Whole minutes as the reader sees them: never less than one, to the nearest
 * minute below twenty, and to the nearest five from there.
 */
export function roundedMinutes(minutes: number): number {
  if (minutes < 20) return Math.max(1, roundHalfAwayFromZero(minutes));
  return roundHalfAwayFromZero(minutes / 5) * 5;
}

export function workload(words: number): Workload {
  if (!Number.isSafeInteger(words) || words < 0) {
    throw new RangeError("a word count is a whole number, never negative");
  }
  const silentMinutes = words / silentWordsPerMinute;
  const aloudMinutes = words / aloudWordsPerMinute;
  const low = roundedMinutes(silentMinutes);
  return {
    words,
    silentMinutes,
    aloudMinutes,
    minutes: [low, Math.max(low, roundedMinutes(aloudMinutes))],
  };
}

/** A plan's lightest, middle and heaviest readings, which the plan page shows. */
export interface PlanWorkload {
  minimum: Workload;
  /** The middle reading, or the mean of the two middle readings' words, rounded. */
  median: Workload;
  maximum: Workload;
}

/** Undefined for a plan with no readings. */
export function planWorkload(words: readonly number[]): PlanWorkload | undefined {
  if (words.length === 0) return undefined;
  const sorted = [...words].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  const at = (i: number) => sorted[i] ?? 0;
  const median =
    sorted.length % 2 === 0 ? roundHalfAwayFromZero((at(middle - 1) + at(middle)) / 2) : at(middle);
  return {
    minimum: workload(at(0)),
    median: workload(median),
    maximum: workload(at(sorted.length - 1)),
  };
}

/** Each reading's workload from the word counts, or undefined if there are none or a book is not counted. */
export function readingsWorkload(
  readings: readonly Reading[],
  counts: WordCounts,
): PlanWorkload | undefined {
  const words: number[] = [];
  for (const r of readings) {
    const count = counts.wordsInReading(r);
    if (count === undefined) return undefined;
    words.push(count);
  }
  return planWorkload(words);
}
