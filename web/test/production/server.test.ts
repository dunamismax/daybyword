// The production build (vite build, then node server.ts) against the site's
// address contract (tests/fixtures/routes.json, docs/urls.md) and the checks
// the Swift server's tests made before PM.20 retired it: the shell every page
// shares, Settings, the configuration, the gallery's components, and that
// pages write no interface words of their own. Run by make smoke-web after
// the build (DBW_TEST_BUILD=1), never by the unit tests.
import { spawn, type ChildProcess } from "node:child_process";
import { readFileSync } from "node:fs";
import { createServer } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  BookRegistry,
  parseReading,
  ReferenceFormatter,
  Versification,
} from "#lib/domain/index.ts";
import { settings } from "#lib/settings.ts";
import { englishStrings } from "#lib/strings.ts";

interface RouteCase {
  input: { path: string; environment?: string };
  output: {
    status: number;
    contentType?: string;
    cacheControl?: string;
    /** Where a redirect leads. */
    location?: string;
    title?: string;
    heading?: string;
    current?: string;
  };
}

const fixture = JSON.parse(
  readFileSync(new URL("../../../tests/fixtures/routes.json", import.meta.url), "utf8"),
) as { cases: RouteCase[]; headers: Record<string, string> };

async function freePort(): Promise<number> {
  const server = createServer();
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  await new Promise((resolve) => server.close(resolve));
  if (address === null || typeof address === "string") throw new Error("no port");
  return address.port;
}

interface Running {
  base: string;
  process: ChildProcess;
  log: string[];
}

function launch(environment: Record<string, string>, port: number): Running {
  const log: string[] = [];
  const child = spawn(process.execPath, ["server.ts"], {
    cwd: new URL("../../", import.meta.url),
    env: { ...process.env, HOST: "127.0.0.1", PORT: String(port), ...environment },
  });
  child.stdout?.on("data", (chunk: Buffer) => log.push(...chunk.toString().split("\n")));
  child.stderr?.on("data", (chunk: Buffer) => log.push(...chunk.toString().split("\n")));
  return { base: `http://127.0.0.1:${port}`, process: child, log };
}

async function start(environment: Record<string, string>): Promise<Running> {
  const running = launch(environment, await freePort());
  for (let i = 0; ; i += 1) {
    if (
      await fetch(`${running.base}/up`).then(
        (r) => r.ok,
        () => false,
      )
    )
      break;
    if (i > 100) throw new Error(`the server did not start:\n${running.log.join("\n")}`);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  return running;
}

async function page(server: Running, path: string): Promise<string> {
  return (await fetch(`${server.base}${path}`)).text();
}

function title(html: string): string | undefined {
  return /<title>([^<]*)<\/title>/.exec(html)?.[1]?.replaceAll("&amp;", "&");
}

function heading(html: string): string | undefined {
  return /<h1[^>]*>([\s\S]*?)<\/h1>/.exec(html)?.[1]?.replace(/<[^>]+>/g, "");
}

function current(html: string): string | undefined {
  return /<a[^>]*aria-current="page"[^>]*>([^<]*)<\/a>/.exec(html)?.[1];
}

/**
 * The words a page shows: the text between tags, and the attributes a reader
 * meets (labels, titles, and the copy button's messages).
 */
function readerText(html: string): string[] {
  const plain = html
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<svg[\s\S]*?<\/svg>/g, "")
    // A reference keeps its chapter and verses together in a span; read it whole.
    .replace(/<span class="whitespace-nowrap">([^<]*)<\/span>/g, "$1");
  const found = [
    ...[...plain.matchAll(/>([^<]+)</g)].map((match) => match[1] ?? ""),
    ...[...plain.matchAll(/(?:aria-label|title|alt|data-copied|data-failed)="([^"]*)"/g)].map(
      (match) => match[1] ?? "",
    ),
  ];
  return found
    .flatMap((piece) => piece.split(" · "))
    .map((piece) =>
      piece
        .replaceAll("&#39;", "'")
        .replaceAll("&quot;", '"')
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&amp;", "&")
        .trim(),
    )
    .filter((piece) => piece !== "");
}

/** Whether a piece of page text is one of the table's values, a placeholder standing for any text. */
function isFromTheTable(piece: string): boolean {
  return Object.values(englishStrings).some((value) =>
    new RegExp(
      `^${value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/\\\{[a-z]+\\\}/g, ".+")}$`,
    ).test(piece),
  );
}

interface ReleasePlan {
  id: string;
  title: string;
  creator: string;
  summary: string;
  suits: string;
  limitations: string;
  instructions: string;
  source: string;
  assignments: { reading: string }[];
}

let release: { plans: ReleasePlan[]; scripture: { name: string; content: string }[] } | undefined;

/** The release catalog the server was given (scripts/with-catalog.sh). */
function releaseCatalog() {
  release ??= JSON.parse(
    readFileSync(
      process.env["DBW_CATALOG_EXPORT"] ??
        new URL("../../../build/catalog/catalog-export.json", import.meta.url),
      "utf8",
    ),
  ) as NonNullable<typeof release>;
  return release;
}

/** Every plan's own words, and each of its readings as a reader sees it. */
function catalogText(): Set<string> {
  const catalog = releaseCatalog();
  const resource = (name: string) =>
    catalog.scripture.find((found) => found.name === name)?.content ?? "";
  const english = new Versification("english", resource("versification/english.tsv"));
  const formatter = new ReferenceFormatter(new BookRegistry(resource("books.json")), english);
  const found = new Set<string>();
  for (const plan of catalog.plans) {
    for (const field of [
      plan.title,
      plan.summary,
      plan.suits,
      plan.limitations,
      plan.instructions,
      plan.source,
    ]) {
      found.add(field);
    }
    for (const assignment of plan.assignments) {
      found.add(formatter.reading(parseReading(assignment.reading, english)));
    }
  }
  return found;
}

let development: Running;
let production: Running;
let deployed: Running;
const commit = "A333B3F0123456789ABCDEF";

beforeAll(async () => {
  [development, production, deployed] = await Promise.all([
    start({ DBW_ENV: "development" }),
    start({ DBW_ENV: "production" }),
    start({ DBW_ENV: "production", DBW_COMMIT: commit }),
  ]);
});

afterAll(() => {
  for (const server of [development, production, deployed]) server.process.kill();
});

describe("the production server", () => {
  for (const testCase of fixture.cases) {
    const { path, environment } = testCase.input;
    const expected = testCase.output;
    it(`answers ${path}${environment ? ` (${environment})` : ""} as docs/urls.md says`, async () => {
      const server = environment === "production" ? production : development;
      const response = await fetch(`${server.base}${path}`, { redirect: "manual" });
      expect(response.status).toBe(expected.status);
      if (expected.location) {
        const location = new URL(response.headers.get("location") ?? "", `${server.base}${path}`);
        expect(location.pathname).toBe(expected.location);
        return;
      }
      if (expected.contentType) {
        expect(response.headers.get("content-type")).toBe(expected.contentType);
      }
      if (expected.cacheControl) {
        expect(response.headers.get("cache-control")).toBe(expected.cacheControl);
      }
      const body = await response.text();
      const html = response.headers.get("content-type")?.startsWith("text/html") === true;
      expect(html ? title(body) : undefined).toBe(expected.title);
      expect(html ? heading(body) : undefined).toBe(expected.heading);
      expect(html ? current(body) : undefined).toBe(expected.current);
    });
  }

  it("sends the security headers on every response, and a strict policy", async () => {
    for (const path of [
      "/",
      "/settings",
      "/up",
      "/assets/theme.js",
      "/no-such-page",
      "/api/v1/x",
    ]) {
      const response = await fetch(`${production.base}${path}`);
      for (const [name, value] of Object.entries(fixture.headers)) {
        if (name === "content-security-policy") continue;
        expect(response.headers.get(name), `${name} on ${path}`).toBe(value);
      }
      const policy = response.headers.get("content-security-policy") ?? "";
      expect(policy, path).not.toMatch(/unsafe-|\*|https?:/);
      for (const directive of fixture.headers["content-security-policy"]?.split("; ") ?? []) {
        expect(policy, `${directive} on ${path}`).toContain(directive);
      }
      expect(response.headers.get("x-dbw-route"), path).toBeNull();
    }
  });

  it("loads nothing from another host, and no script but the site's own files", async () => {
    for (const path of [
      "/",
      "/today",
      "/plans",
      "/progress",
      "/settings",
      "/plans/gospels-at-your-pace",
      "/plans/gospels-at-your-pace/week",
    ]) {
      const html = await (await fetch(`${production.base}${path}`)).text();
      expect(html, path).not.toMatch(/(src|href)="(https?:)?\/\//);
      expect(html, path).not.toMatch(/<script(?![^>]*\bsrc=)[^>]*>/);
      expect(html, path).not.toMatch(/\sstyle="/);
    }
  });

  it("caches fingerprinted files for a year, the site's files for an hour, and pages never unchecked", async () => {
    const html = await (await fetch(`${production.base}/`)).text();
    const sheet = /href="\.?(\/_app\/immutable\/assets\/[^"]+\.css)"/.exec(html)?.[1];
    expect(sheet).toBeDefined();
    const css = await fetch(`${production.base}${sheet}`);
    expect(css.headers.get("cache-control")).toBe("public,max-age=31536000,immutable");
    const asset = await fetch(`${production.base}/assets/images/mark.svg`);
    expect(asset.headers.get("cache-control")).toBe("public, max-age=3600");
    const page = await fetch(`${production.base}/today`);
    expect(page.headers.get("cache-control")).toBe("no-cache");
  });

  it("shows the deployed commit in Settings only when one is given", async () => {
    expect(await page(production, "/settings")).toContain("Development build");
    const html = await page(deployed, "/settings");
    expect(html).toContain(`Version ${commit.toLowerCase().slice(0, 12)}`);
    expect(html).not.toContain("Development build");
  });

  it("refuses to start with settings it cannot use", async () => {
    for (const environment of [{ DBW_ENV: "staging" }, { DBW_COMMIT: "main" }]) {
      const server = launch(environment, await freePort());
      const code = await new Promise<number | null>((resolve) => {
        const timer = setTimeout(() => {
          server.process.kill();
          resolve(null);
        }, 5000);
        server.process.on("exit", (exitCode) => {
          clearTimeout(timer);
          resolve(exitCode);
        });
      });
      expect(code, JSON.stringify(environment)).not.toBe(0);
      expect(code, `${JSON.stringify(environment)} kept running`).not.toBeNull();
      expect(server.log.join("\n")).toMatch(/DBW_(ENV|COMMIT) must be/);
    }
  });

  it("logs the method, route pattern, status and time, never the address", async () => {
    await fetch(`${production.base}/plans/gospels-at-your-pace/week?start=2027-01-04`);
    await new Promise((resolve) => setTimeout(resolve, 50));
    const lines = production.log.filter((line) => line.startsWith("request "));
    expect(lines).toContainEqual(
      expect.stringMatching(
        /^request method=GET route=\/plans\/\[id=planid\]\/week status=200 ms=\d+$/,
      ),
    );
    expect(production.log.join("\n")).not.toMatch(/gospels-at-your-pace|2027-01-04|start=/);
  });
});

describe("the shell every page shares", () => {
  for (const path of [
    "/",
    "/today",
    "/plans/gospels-at-your-pace",
    "/plans/gospels-at-your-pace/week",
    "/settings",
    "/no-such-page",
  ]) {
    it(`wraps ${path}`, async () => {
      const html = await page(production, path);
      expect(html.startsWith("<!doctype html>")).toBe(true);
      expect(html).toContain('<meta name="robots" content="noindex" />');
      // The skip link is the first thing in the page, before the header.
      const body = html.slice(html.indexOf("<body"));
      expect(/<a [^>]*>/.exec(body)?.[0]).toContain('href="#content"');
      expect(body).toContain('<main id="content"');
      expect(body.split("<main").length).toBe(2);
      expect(body).toContain('<nav aria-label="Sections">');
      expect(body.split("aria-current").length).toBeLessThanOrEqual(2);
      expect(body).toContain("not affiliated with any church or denomination");
      // The old-browser notice starts hidden, with a copy for JavaScript turned off (D30).
      expect(html).toContain('<script type="module" src="/assets/support.js"></script>');
      expect(html).toContain('<script nomodule defer src="/assets/unsupported.js"></script>');
      expect(body).toMatch(/id="browser-notice" role="note" hidden(="")?>/);
      expect(body).toContain("<noscript>");
    });
  }

  it("keeps a plan's pages in the Plans section", async () => {
    for (const path of ["/plans/gospels-at-your-pace", "/plans/gospels-at-your-pace/week"]) {
      expect(current(await page(production, path)), path).toBe("Plans");
    }
  });
});

describe("Settings", () => {
  it("offers each setting's values, with its default checked", async () => {
    const html = await page(production, "/settings");
    for (const setting of settings) {
      for (const value of setting.values) {
        const input = new RegExp(`<input[^>]*name="${setting.name}" value="${value}"[^>]*>`).exec(
          html,
        )?.[0];
        expect(input, `${setting.name} ${value}`).toBeDefined();
        expect(input?.includes(" checked"), `${setting.name} ${value}`).toBe(
          value === setting.fallback,
        );
      }
    }
    expect(html).toMatch(/<legend[^>]*>Appearance<\/legend>/);
    expect(html).toContain("never sent to daybyword.com");
  });
});

describe("the component gallery", () => {
  it("is read in words: spoken references, and a status's word beside its symbol", async () => {
    const html = await page(development, "/dev/components");
    expect(html.replace(/<!--[\s\S]*?-->/g, "")).toContain(
      '<span aria-hidden="true">Mark <span class="whitespace-nowrap">4:1–20</span></span>' +
        '<span class="sr-only">Mark, chapter 4, verses 1 to 20</span>',
    );
    const statuses = [
      englishStrings["component.status-read"],
      englishStrings["component.status-partly-read"],
      englishStrings["component.status-skipped"],
      englishStrings["component.status-unread"],
    ];
    expect(new Set(statuses).size).toBe(statuses.length);
    for (const status of statuses) expect(html, status).toContain(status);
    expect(html).toMatch(/About \d+ minutes?\. Estimates vary\./);
  });
});

describe("the interface text", () => {
  // No page writes interface words of its own: every word a reader sees comes
  // from the string table, so adding a language is adding a table (E25). The
  // gallery is excluded; its content is invented for layout.
  // A plan's own words (its title, summary and the rest of its page) and its
  // references come from the catalog, so those are allowed as they stand.
  for (const path of [
    "/",
    "/today",
    "/plans",
    "/plans/gospels-at-your-pace",
    "/plans/bible-in-a-year",
    "/plans/proverbs-through-the-month",
    "/plans/gospels-at-your-pace/week",
    "/progress",
    "/settings",
    "/no-such-page",
  ]) {
    it(`on ${path} comes only from the string table and the catalog`, async () => {
      const fromTheCatalog = catalogText();
      const pieces = readerText(await page(deployed, path));
      expect(pieces.length).toBeGreaterThan(0);
      for (const piece of pieces) {
        expect(fromTheCatalog.has(piece) || isFromTheTable(piece), piece).toBe(true);
      }
    });
  }

  it("shows every plan in the catalog, each with its page", async () => {
    const list = await page(deployed, "/plans");
    expect(releaseCatalog().plans.length).toBeGreaterThan(0);
    for (const plan of releaseCatalog().plans) {
      expect(list, plan.id).toContain(`href="/plans/${plan.id}"`);
      const html = await page(deployed, `/plans/${plan.id}`);
      expect(heading(html)).toBe(plan.title);
      for (const field of [plan.summary, plan.suits, plan.limitations, plan.instructions]) {
        expect(readerText(html), `${plan.id}: ${field}`).toContain(field);
      }
      expect(html, plan.id).toMatch(/Estimates vary/);
      // A plan's page shows references and never passages of Scripture (D13).
      expect(html).not.toMatch(/<blockquote|<q[ >]/);
    }
  });
});
