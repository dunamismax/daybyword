// Book and plan identifiers (docs/engine.md, "Identifiers"), as Swift's
// BookID and PlanID check them.

/** A USFM 3.0 book id: three capital ASCII letters and digits, at least one a letter. */
export type BookID = string;

/** A plan id: 1 to 64 lowercase ASCII letters and digits, in words joined by single hyphens. */
export type PlanID = string;

const bookPattern = /^[A-Z0-9]{3}$/;

/** Whether the text is shaped like a USFM book id. Whether it is registered is the registry's question. */
export function isBookID(text: string): text is BookID {
  return bookPattern.test(text) && /[A-Z]/.test(text);
}

const planPattern = /^[a-z0-9]+(-[a-z0-9]+)*$/;

/** Whether the text is a plan id (docs/urls.md). */
export function isPlanID(text: string): text is PlanID {
  return text.length >= 1 && text.length <= 64 && planPattern.test(text);
}
