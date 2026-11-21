// A plan version as the scheduling rules see it (docs/engine.md, "Plans and
// assignments"), as Swift's PlanVersion has it: what a reader can enroll in
// and mark, without the plan page's prose.
import type { PlanID } from "./ids.ts";
import type { Reading } from "./passage.ts";

/** `sequence`: numbered readings in order. `day-of-month`: a reading for each day, 1 to 31. */
export type ScheduleKind = "sequence" | "day-of-month";

/** The three schedule behaviors. */
export type Behavior = "pace" | "finish-date" | "calendar";

export const scheduleKinds: readonly ScheduleKind[] = ["sequence", "day-of-month"];
export const behaviors: readonly Behavior[] = ["pace", "finish-date", "calendar"];

/** The behaviors a reader may choose for a plan on a schedule. */
export function permittedBehaviors(schedule: ScheduleKind): readonly Behavior[] {
  return schedule === "sequence" ? ["pace", "finish-date"] : ["calendar"];
}

/** One reading in the schedule. Its id is how the journal records it. */
export interface PlanAssignment {
  readonly id: number;
  readonly reading: Reading;
}

export interface PlanVersion {
  readonly id: PlanID;
  readonly version: number;
  readonly schedule: ScheduleKind;
  /** The behaviors this plan permits. */
  readonly behaviors: readonly Behavior[];
  /** The reading days a week the plan is paced for, 1 to 7. */
  readonly readingDays: number;
  /** In the order they are read. */
  readonly assignments: readonly PlanAssignment[];
}

/** Each assignment's position in reading order, from 1, by its id. */
export function assignmentPositions(plan: PlanVersion): Map<number, number> {
  const positions = new Map<number, number>();
  plan.assignments.forEach((assignment, index) => {
    if (!positions.has(assignment.id)) positions.set(assignment.id, index + 1);
  });
  return positions;
}
