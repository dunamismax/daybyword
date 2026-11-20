// The web's interface text, by key (docs/decisions.md E15, E25), ported from
// the Swift server's Strings.swift and pinned by tests/fixtures/strings.json.
// Pages and components never write interface words themselves; they ask for
// a key, so adding a language means adding a table. English only for now.

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

  "section.today": "Today",
  "section.plans": "Plans",
  "section.progress": "Progress",
  "section.settings": "Settings",

  "today.empty-title": "Your next reading will appear here.",
  "plans.empty-title": "Plans will appear here.",
  "plans.empty-message": "You'll be able to choose a reading plan here.",
  "plan.title": "Plan",
  "plan.empty-title": "This plan's page will appear here.",
  "plan.empty-message": "Plan pages arrive with the catalog.",
  "week.title": "Week",
  "week.empty-title": "This plan's week will appear here.",
  "week.empty-message": "Weeks arrive with the catalog.",
  "progress.empty-title": "Your reading record will appear here.",
  "progress.empty-message": "It describes what you've read, and nothing more.",
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
  "settings.kept-in-this-browser":
    "These choices are kept in this browser only. They are never sent to daybyword.com.",
  "settings.about": "About",
  "settings.version": "Version {version}",
  "settings.development-version": "Development build",
  "not-found.title": "Page not found",
  "not-found.message":
    "There's no page at this address. It may have moved, or the link may be mistyped.",

  "component.copy-reference": "Copy reference",
  "component.copied": "Copied",
  "component.copy-failed": "Selected; copy it with your keyboard",
  "component.workload-one": "About 1 minute. Estimates vary.",
  "component.workload-other": "About {minutes} minutes. Estimates vary.",
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
  "component.error-title": "Something went wrong",
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

/** "About 12 minutes. Estimates vary." Estimates always say they are estimates. */
export function workloadText(minutes: number): string {
  return minutes === 1
    ? text("component.workload-one")
    : text("component.workload-other", { minutes: String(minutes) });
}
