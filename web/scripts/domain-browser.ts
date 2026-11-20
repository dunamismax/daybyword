// Runs the shared domain cases in a real browser (docs/engine.md, "Parity";
// BUILD.md PM.15): builds test/browser/ with Vite, serves it on a loopback
// port, opens it in headless Firefox through geckodriver, and reads the
// result the page leaves on <body data-result>.
//
//   node scripts/domain-browser.ts          (make test-domain-browser)
//
// Needs Firefox and geckodriver (README.md prerequisites); DBW_GECKODRIVER
// names another geckodriver. A few W3C WebDriver commands over fetch.
import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { createServer, type Server } from "node:http";
import type { AddressInfo } from "node:net";
import { extname, join, normalize } from "node:path";
import { build } from "vite";

const root = new URL("../", import.meta.url).pathname;
const out = join(root, "build/parity-browser");

function fail(message: string): never {
  console.error(`domain-browser: ${message}`);
  process.exit(1);
}

async function freePort(): Promise<number> {
  const server = createServer();
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address() as AddressInfo;
  await new Promise((resolve) => server.close(resolve));
  return port;
}

const types: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
};

async function serve(): Promise<Server> {
  const server = createServer((request, response) => {
    const path = normalize(new URL(request.url ?? "/", "http://localhost").pathname);
    const file = join(out, path === "/" ? "index.html" : path);
    if (!file.startsWith(out)) {
      response.writeHead(404).end();
      return;
    }
    readFile(file).then(
      (body) => {
        response.writeHead(200, {
          "content-type": types[extname(file)] ?? "application/octet-stream",
        });
        response.end(body);
      },
      () => response.writeHead(404).end(),
    );
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  return server;
}

async function webdriver(base: string, method: string, path: string, body?: unknown) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: { "content-type": "application/json" },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const answer = (await response.json()) as { value: unknown };
  if (!response.ok) fail(`WebDriver ${method} ${path}: ${JSON.stringify(answer.value)}`);
  return answer.value;
}

await build({ configFile: join(root, "test/browser/vite.config.ts") });
const server = await serve();
const page = `http://127.0.0.1:${(server.address() as AddressInfo).port}/`;

const driverPort = await freePort();
const driver = spawn(
  process.env["DBW_GECKODRIVER"] ?? "geckodriver",
  ["--host", "127.0.0.1", "--port", String(driverPort)],
  { stdio: "ignore" },
);
driver.on("error", (error) => fail(`could not start geckodriver: ${error.message}`));
const base = `http://127.0.0.1:${driverPort}`;
let session: string | undefined;

try {
  for (let i = 0; ; i += 1) {
    const ready = await fetch(`${base}/status`).then(
      (r) => r.ok,
      () => false,
    );
    if (ready) break;
    if (i > 100) fail("geckodriver did not answer");
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  const created = (await webdriver(base, "POST", "/session", {
    capabilities: {
      alwaysMatch: { browserName: "firefox", "moz:firefoxOptions": { args: ["-headless"] } },
    },
  })) as { sessionId: string; capabilities: { browserName: string; browserVersion: string } };
  session = created.sessionId;
  await webdriver(base, "POST", `/session/${session}/url`, { url: page });

  let result: string | null = null;
  for (let i = 0; result === null; i += 1) {
    if (i > 300) fail("the page left no result");
    result = (await webdriver(base, "POST", `/session/${session}/execute/sync`, {
      script: "return document.body.dataset.result ?? null",
      args: [],
    })) as string | null;
    if (result === null) await new Promise((resolve) => setTimeout(resolve, 100));
  }
  const report = JSON.parse(result) as { cases: number; failures: string[] };
  const browser = `${created.capabilities.browserName} ${created.capabilities.browserVersion}`;
  if (report.failures.length > 0 || report.cases === 0) {
    for (const failure of report.failures) console.error(`  ${failure}`);
    fail(`${report.failures.length} of ${report.cases} shared cases failed in ${browser}`);
  }
  console.log(`domain-browser: all ${report.cases} shared cases pass in ${browser}`);
} finally {
  if (session) await webdriver(base, "DELETE", `/session/${session}`).catch(() => undefined);
  driver.kill();
  server.close();
}
