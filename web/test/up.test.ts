import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import type { APIContext } from "astro";
import { GET } from "../src/pages/up";

interface RouteCase {
  input: { path: string };
  output: { status: number; contentType?: string; cacheControl?: string };
}

const fixtures = JSON.parse(
  readFileSync(new URL("../../tests/fixtures/routes.json", import.meta.url), "utf8"),
) as { cases: RouteCase[] };

describe("/up", () => {
  const expected = fixtures.cases.find((c) => c.input.path === "/up")?.output;

  it("matches the captured Swift server fixture", async () => {
    expect(expected).toBeDefined();
    const response = await GET({} as APIContext);
    expect(response.status).toBe(expected?.status);
    expect(response.headers.get("content-type")).toBe(expected?.contentType);
    expect(response.headers.get("cache-control")).toBe(expected?.cacheControl);
    expect(await response.text()).toBe("OK\n");
  });
});
