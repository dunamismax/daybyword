// Event and enrollment ids (docs/engine.md, "The journal"), as Swift's
// EventID has them: UUIDv7 (RFC 9562) in lowercase with hyphens. The first 48
// bits are Unix milliseconds, so ids sort, as text, by the time they were
// made; journal order is that order.

/** A UUIDv7 in lowercase with hyphens, such as `0195a7c2-3f10-7abc-8def-0123456789ab`. */
export type EventID = string;

const pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

/** Whether the text has a UUIDv7's shape, version and variant. */
export function isEventID(text: string): text is EventID {
  return pattern.test(text);
}

/** The Unix milliseconds an id was made at: its first 48 bits. */
export function eventIDMilliseconds(id: EventID): number {
  return Number.parseInt(id.slice(0, 8) + id.slice(9, 13), 16);
}

const hex = (byte: number) => byte.toString(16).padStart(2, "0");

/**
 * An id from a millisecond count and ten random bytes, which the client
 * supplies so the engine stays pure. Undefined unless the count is a whole
 * number from 0 up to, not including, 2^48 and there are ten bytes (whole
 * numbers 0 to 255).
 */
export function makeEventID(milliseconds: number, random: readonly number[]): EventID | undefined {
  if (!Number.isInteger(milliseconds) || milliseconds < 0 || milliseconds >= 2 ** 48) {
    return undefined;
  }
  if (random.length !== 10) return undefined;
  if (!random.every((byte) => Number.isInteger(byte) && byte >= 0 && byte <= 255)) return undefined;
  const r = random as readonly [number, number, number, ...number[]];
  const time = milliseconds.toString(16).padStart(12, "0");
  const tail = r.slice(3).map(hex).join("");
  return [
    time.slice(0, 8),
    time.slice(8),
    hex(0x70 | (r[0] & 0x0f)) + hex(r[1]),
    hex(0x80 | (r[2] & 0x3f)) + tail.slice(0, 2),
    tail.slice(2),
  ].join("-");
}
