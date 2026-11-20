// The production build (vite build, then node server.ts) against the routes
// the Swift server answered (tests/fixtures/routes.json), with the
// differences docs/decisions.md E38 records; run by make smoke-web after the
// build (DBW_TEST_BUILD=1), never by the unit tests.
import { spawn, type ChildProcess } from "node:child_process";
import { readFileSync } from "node:fs";
import { createServer } from "node:net";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

interface RouteCase {
  input: { path: string; environment?: string };
  output: {
    status: number;
    contentType?: string;
    cacheControl?: string;
    title?: string;
    heading?: string;
    current?: string;
  };
}

const fixture = JSON.parse(
  readFileSync(new URL("../../../tests/fixtures/routes.json", import.meta.url), "utf8"),
) as { cases: RouteCase[]; headers: Record<string, string> };

/** What the SvelteKit site answers differently from the Swift server, and why (E38). */
type Difference = { [K in keyof RouteCase["output"]]?: RouteCase["output"][K] | undefined } & {
  location?: string;
};
const differences: Record<string, Difference> = {
  // No trailing slash (docs/urls.md): a permanent redirect, not a second address.
  "/today/": { status: 308, location: "/today" },
  // The stylesheets are now one fingerprinted file under /_app/immutable/.
  "/assets/site.css": {
    status: 404,
    contentType: "text/html; charset=utf-8",
    heading: "Page not found",
  },
  "/assets/tokens.css": {
    status: 404,
    contentType: "text/html; charset=utf-8",
    heading: "Page not found",
  },
  "/favicon.ico": { status: 200, contentType: "image/x-icon" },
  // The app's and the browser's calls get JSON, never the HTML page.
  "/api/v1/plans": {
    status: 404,
    contentType: "application/json",
    title: undefined,
    heading: undefined,
  },
};

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

async function start(environment: "development" | "production"): Promise<Running> {
  const port = await freePort();
  const log: string[] = [];
  const child = spawn(process.execPath, ["server.ts"], {
    cwd: new URL("../../", import.meta.url),
    env: { ...process.env, HOST: "127.0.0.1", PORT: String(port), DBW_ENV: environment },
  });
  child.stdout?.on("data", (chunk: Buffer) => log.push(...chunk.toString().split("\n")));
  child.stderr?.on("data", (chunk: Buffer) => log.push(...chunk.toString().split("\n")));
  const base = `http://127.0.0.1:${port}`;
  for (let i = 0; ; i += 1) {
    if (
      await fetch(`${base}/up`).then(
        (r) => r.ok,
        () => false,
      )
    )
      break;
    if (i > 100) throw new Error(`the server did not start:\n${log.join("\n")}`);
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  return { base, process: child, log };
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

let development: Running;
let production: Running;

beforeAll(async () => {
  [development, production] = await Promise.all([start("development"), start("production")]);
});

afterAll(() => {
  development.process.kill();
  production.process.kill();
});

describe("the production server", () => {
  for (const testCase of fixture.cases) {
    const { path, environment } = testCase.input;
    const changed = differences[path];
    const expected = { ...testCase.output, ...changed };
    it(`answers ${path}${environment ? ` (${environment})` : ""} as the Swift server did${changed ? ", with E38's difference" : ""}`, async () => {
      const server = environment === "production" ? production : development;
      const response = await fetch(`${server.base}${path}`, { redirect: "manual" });
      expect(response.status).toBe(expected.status);
      if (changed?.location) {
        const location = new URL(response.headers.get("location") ?? "", `${server.base}${path}`);
        expect(location.pathname).toBe(changed.location);
        return;
      }
      if (expected.contentType) {
        expect(response.headers.get("content-type")).toBe(expected.contentType);
      }
      if (expected.cacheControl) {
        expect(response.headers.get("cache-control")).toBe(expected.cacheControl);
      }
      const body = await response.text();
      if (expected.title) expect(title(body)).toBe(expected.title);
      if (expected.heading) expect(heading(body)).toBe(expected.heading);
      expect(current(body)).toBe(expected.current);
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
    for (const path of ["/", "/today", "/plans", "/progress", "/settings", "/plans/a/week"]) {
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
    const html = await (await fetch(`${production.base}/settings`)).text();
    expect(html).toContain("Development build");
    for (const name of ["appearance", "reference-size"]) expect(html).toContain(`name="${name}"`);
  });

  it("logs the method, route pattern, status and time, never the address", async () => {
    await fetch(`${production.base}/plans/psalm-a-day/week?start=2027-01-04`);
    await new Promise((resolve) => setTimeout(resolve, 50));
    const lines = production.log.filter((line) => line.startsWith("request "));
    expect(lines).toContainEqual(
      expect.stringMatching(
        /^request method=GET route=\/plans\/\[id=planid\]\/week status=200 ms=\d+$/,
      ),
    );
    expect(production.log.join("\n")).not.toMatch(/psalm-a-day|2027-01-04|start=/);
  });
});
