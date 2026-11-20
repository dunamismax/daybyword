// Runs every shared domain case in the browser (docs/engine.md, "Parity"):
// the scripture files and fixtures are bundled as text, and the result is
// left on <body data-result> for scripts/domain-browser.ts to read.
import { BookRegistry, Versification, WordCounts } from "#lib/domain/index.ts";
import books from "../../../catalog/scripture/books.json?raw";
import englishText from "../../../catalog/scripture/versification/english.tsv?raw";
import wordsText from "../../../catalog/scripture/words/web.tsv?raw";
import {
  checkParity,
  domainFixtures,
  type DomainFixture,
  type FixtureFile,
} from "../domain/parity.ts";

const files = import.meta.glob<string>("../../../tests/fixtures/*.json", {
  query: "?raw",
  import: "default",
  eager: true,
});

function run(): { cases: number; failures: string[]; userAgent: string } {
  try {
    const registry = new BookRegistry(books);
    const english = new Versification("english", englishText);
    english.check(registry);
    const counts = new WordCounts(wordsText, english);
    const fixtures = Object.fromEntries(
      domainFixtures.map((name) => {
        const text = files[`../../../tests/fixtures/${name}.json`];
        if (text === undefined) throw new Error(`no fixture ${name}`);
        return [name, JSON.parse(text) as FixtureFile];
      }),
    ) as Record<DomainFixture, FixtureFile>;
    return {
      ...checkParity({ registry, english, counts }, fixtures),
      userAgent: navigator.userAgent,
    };
  } catch (error) {
    return { cases: 0, failures: [`threw: ${String(error)}`], userAgent: navigator.userAgent };
  }
}

const report = run();
const result = document.getElementById("result");
if (result) {
  result.textContent =
    report.failures.length === 0
      ? `${report.cases} cases passed`
      : `${report.failures.length} of ${report.cases} cases failed:\n${report.failures.join("\n")}`;
}
document.body.dataset["result"] = JSON.stringify(report);
