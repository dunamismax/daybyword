// The production server (BUILD.md PM.16, docs/deploy.md): adapter-node's
// handler, wrapped so that every response, static files and errors included,
// carries the site's security headers (tests/fixtures/routes.json,
// "headers"), a cache policy, and one log line of metadata only:
// the method, the route pattern (never the address or its query), the status
// and the time taken (docs/decisions.md E17). HSTS is Caddy's.
//
//   node server.ts      after `vite build`; HOST (127.0.0.1) and PORT (3000)
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";

export const policy = [
  "default-src 'none'",
  "script-src 'self'",
  "style-src 'self'",
  "img-src 'self'",
  "font-src 'self'",
  "connect-src 'self'",
  "manifest-src 'self'",
  "worker-src 'self'",
  "form-action 'self'",
  "base-uri 'none'",
  "frame-ancestors 'none'",
].join("; ");

const securityHeaders: Record<string, string> = {
  "content-security-policy": policy,
  "permissions-policy": [
    "accelerometer=()",
    "browsing-topics=()",
    "camera=()",
    "display-capture=()",
    "geolocation=()",
    "gyroscope=()",
    "hid=()",
    "magnetometer=()",
    "microphone=()",
    "midi=()",
    "payment=()",
    "serial=()",
    "usb=()",
  ].join(", "),
  "x-content-type-options": "nosniff",
  // No referrer leaves for another site. Within this one a form's POST must
  // carry the page's origin for SvelteKit's check, which no-referrer would
  // replace with "null" (docs/decisions.md E54).
  "referrer-policy": "same-origin",
  "cross-origin-opener-policy": "same-origin",
  "cross-origin-resource-policy": "same-origin",
  "x-frame-options": "DENY",
};

const routeHeader = "x-dbw-route";

/** Static files the build fingerprints keep adapter-node's year; the site's other files an hour. */
const staticCache = "public, max-age=3600";

type Handler = (request: IncomingMessage, response: ServerResponse, next?: () => void) => void;

// The public address's scheme, for SvelteKit's check that a form is posted
// from this site (it assumes https unless a header says otherwise). This
// server listens on loopback only: on the host every request comes through
// Caddy, which sets X-Forwarded-Proto to https and replaces any a client
// sent; a request with none came straight to this plain-HTTP port (make
// serve-web, the tests), so its scheme is http. Set before the handler reads
// its environment.
const protocolHeader = "x-forwarded-proto";
process.env["PROTOCOL_HEADER"] = protocolHeader;

// build/handler.js exists only after `vite build`; imported by address, so
// the type checker does not read the build.
const { handler } = (await import(new URL("./build/handler.js", import.meta.url).href)) as {
  handler: Handler;
};

export function serve(request: IncomingMessage, response: ServerResponse): void {
  const start = performance.now();
  request.headers[protocolHeader] ??= "http";
  for (const [name, value] of Object.entries(securityHeaders)) response.setHeader(name, value);
  let route = "static";
  const writeHead = response.writeHead.bind(response) as (...args: unknown[]) => ServerResponse;
  response.writeHead = ((status: number, ...rest: unknown[]) => {
    const marked = response.getHeader(routeHeader);
    if (typeof marked === "string") {
      route = marked;
      response.removeHeader(routeHeader);
    }
    const given = rest.find((arg) => typeof arg === "object" && arg !== null) as
      Record<string, unknown> | undefined;
    if (!response.hasHeader("cache-control") && !given?.["cache-control"]) {
      response.setHeader(
        "cache-control",
        route === "static" && status < 300 ? staticCache : "no-cache",
      );
    }
    return writeHead(status, ...rest);
  }) as typeof response.writeHead;
  response.on("finish", () => {
    const ms = Math.round(performance.now() - start);
    console.log(
      `request method=${request.method} route=${route} status=${response.statusCode} ms=${ms}`,
    );
  });
  handler(request, response);
}

const host = process.env["HOST"] ?? "127.0.0.1";
const port = Number(process.env["PORT"] ?? "3000");
const server = createServer(serve);
server.listen(port, host, () => console.log(`listening on http://${host}:${port}`));
for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
