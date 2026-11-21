import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import type { RequestEvent } from "@sveltejs/kit";
import { GET } from "../src/routes/up/+server.ts";

interface RouteCase {
  input: { path: string };
  output: { status: number; contentType?: string; cacheControl?: string };
}

const fixtures = JSON.parse(
  readFileSync(new URL("../../tests/fixtures/routes.json", import.meta.url), "utf8"),
) as { cases: RouteCase[] };

describe("/up", () => {
  const expected = fixtures.cases.find((c) => c.input.path === "/up")?.output;

  it("answers as the address contract says", async () => {
    expect(expected).toBeDefined();
    const response = await GET({} as RequestEvent);
    expect(response.status).toBe(expected?.status);
    expect(response.headers.get("content-type")).toBe(expected?.contentType);
    expect(response.headers.get("cache-control")).toBe(expected?.cacheControl);
    expect(await response.text()).toBe("OK\n");
  });
});
