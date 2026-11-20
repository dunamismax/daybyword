// Number rules shared with Swift's ReadingEngine (docs/engine.md, "Numbers").

/**
 * Rounds to the nearest whole number, halves away from zero: Swift's
 * `rounded()`. `Math.round` rounds halves up, which differs for negatives.
 */
export function roundHalfAwayFromZero(value: number): number {
  const rounded = Math.round(Math.abs(value));
  return value < 0 ? -rounded : rounded;
}

/**
 * Reads whole-number text as Swift's `Int(String)` does in the data files: an
 * optional `+` or `-`, then ASCII digits only. Anything else is undefined, and
 * so is a number past JavaScript's safe integers (2^53), which no data file
 * comes near; Swift would accept up to 2^63.
 */
export function parseSwiftInt(text: string): number | undefined {
  if (!/^[+-]?[0-9]+$/.test(text)) return undefined;
  const value = Number(text);
  return Number.isSafeInteger(value) ? value : undefined;
}
