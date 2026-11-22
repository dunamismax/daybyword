// The link check (BUILD.md P16.9, docs/decisions.md E61), on the production
// build with the release catalog: from the home page and every page in the
// address contract (tests/fixtures/routes.json), every same-site link and
// every file a page names must answer, a redirect must lead to a page that
// does, every file a page loads must be the site's own (links to other
// sites stay allowed), and every page must be valid HTML. Run by make
// smoke-web (DBW_TEST_BUILD=1), never by the unit tests.
import { spawn, type ChildProcess } from "node:child_process";
import { readFileSync } from "node:fs";
import { createServer } from "node:net";
import { HtmlValidate } from "html-validate";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

const routes = JSON.parse(
  readFileSync(new URL("../../../tests/fixtures/routes.json", import.meta.url), "utf8"),
) as {
  cases: {
    input: { path: string; environment?: string };
    output: { status: number; contentType?: string };
  }[];
};
/**
 * The contract's answer for a path in production: its production case where
 * it has one (the component gallery is development's only), else its own.
 */
const answer = (path: string) =>
  routes.cases.find(
    (found) => found.input.path === path && found.input.environment === "production",
  ) ??
  routes.cases.find((found) => found.input.path === path && found.input.environment === undefined);

let server: ChildProcess;
let base = "";

beforeAll(async () => {
  const probe = createServer();
  await new Promise<void>((resolve) => probe.listen(0, "127.0.0.1", resolve));
  const address = probe.address();
  await new Promise((resolve) => probe.close(resolve));
  if (address === null || typeof address === "string") throw new Error("no port");
  base = `http://127.0.0.1:${address.port}`;
  server = spawn(process.execPath, ["server.ts"], {
    cwd: new URL("../../", import.meta.url),
    env: { ...process.env, HOST: "127.0.0.1", PORT: String(address.port), DBW_ENV: "production" },
    stdio: "ignore",
  });
  for (let i = 0; ; i += 1) {
    if (
      await fetch(`${base}/up`).then(
        (response) => response.ok,
        () => false,
      )
    )
      break;
    if (i > 100) throw new Error("the server did not start");
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
});

afterAll(() => {
  server.kill();
});

/** The tags whose `src`, `href` or `srcset` the browser loads with the page. */
const loading = /<(script|link|img|source|iframe|embed|object|video|audio|track)\b[^>]*>/g;
const loadedFrom = /\s(?:src|href|srcset|data)="([^"]*)"/g;

describe("the link check (P16.9)", () => {
  it("finds every same-site link answering, every loaded file the site's own, and every page valid HTML", async () => {
    const validator = new HtmlValidate({ extends: ["html-validate:standard"] });
    const pages = [...new Set(routes.cases.map((found) => found.input.path))].filter((path) =>
      answer(path)?.output.contentType?.startsWith("text/html"),
    );
    const queue = ["/", ...pages];
    const seen = new Set<string>();
    const problems: string[] = [];
    let validated = 0;

    while (queue.length > 0) {
      const path = queue.shift() ?? "/";
      if (seen.has(path)) continue;
      seen.add(path);
      const response = await fetch(`${base}${path}`, { redirect: "manual" });
      if (response.status >= 300 && response.status < 400) {
        const location = new URL(response.headers.get("location") ?? "", `${base}${path}`);
        if (location.origin === base) queue.push(location.pathname + location.search);
        else problems.push(`${path}: redirects off the site, to ${location.href}`);
        continue;
      }
      // Addresses the contract gives another status (the 404 page) are
      // validated; any other address must answer.
      const expected = answer(path)?.output.status ?? 200;
      if (response.status !== expected) {
        problems.push(`${path}: answered ${response.status}`);
        continue;
      }
      if (!response.headers.get("content-type")?.startsWith("text/html")) continue;

      const html = await response.text();
      const report = await validator.validateString(html, path);
      validated += 1;
      for (const result of report.results) {
        for (const message of result.messages) {
          problems.push(
            `${path}:${message.line}:${message.column}: ${message.ruleId}: ${message.message}`,
          );
        }
      }
      // Every file the page loads is the site's own, and answers.
      for (const [tag] of html.matchAll(loading)) {
        for (const [, value] of tag.matchAll(loadedFrom)) {
          for (const file of (value ?? "")
            .split(",")
            .map((part) => part.trim().split(/\s+/)[0] ?? "")) {
            if (file === "") continue;
            if (!file.startsWith("/") || file.startsWith("//")) {
              problems.push(`${path}: loads ${file} from another host`);
            } else {
              queue.push(file);
            }
          }
        }
      }
      // Every same-site link answers; links to other sites and mail are allowed.
      for (const [, href] of html.matchAll(/<a\b[^>]*\shref="([^"]*)"/g)) {
        const link = (href ?? "").replaceAll("&amp;", "&");
        if (link.startsWith("/") && !link.startsWith("//")) queue.push(link.split("#")[0] || "/");
        else if (!/^(https:\/\/|mailto:|#)/.test(link)) problems.push(`${path}: a link to ${link}`);
      }
    }

    expect(problems).toEqual([]);
    // The crawl reached the pages it should: every plan's page among them.
    expect(validated).toBeGreaterThan(20);
    expect(seen).toContain("/sources");
    expect([...seen].filter((path) => /^\/plans\/[a-z0-9-]+$/.test(path)).length).toBeGreaterThan(
      5,
    );
  }, 120_000);
});
