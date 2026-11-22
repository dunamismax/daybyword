/// <reference no-default-lib="true"/>
/// <reference lib="esnext" />
/// <reference lib="webworker" />
// Day by Word offline (BUILD.md P8.11, P15.2; docs/decisions.md E53): the
// site's own files are kept for each release, and pages are fetched from
// the network first and kept for when there is none, so the home page,
// Today, Plans, Progress and Settings open offline, and every plan page the
// reader has opened. A page not kept shows the offline page instead of the
// browser's error. The reader's record is never here: it is in IndexedDB,
// and the compute endpoints (POST, /api/) pass straight through, so nothing
// one reader did is kept where another could be shown it.
import { self } from "$app/service-worker";
import { version } from "$app/env";
import { immutable, assets } from "$app/manifest";

const cache = `day-by-word-${version}`;
// The site has no base path, so a file's address is its path from the root.
const files: string[] = [...immutable, ...assets].map((asset) => `/${asset.path}`);
/** The pages a reader opens offline, kept with each release. */
const pages = ["/", "/today", "/plans", "/progress", "/settings", "/offline"];

/**
 * Keeps the release's files and pages, and the build's own files those
 * pages link to (/_app/…, such as the stylesheet). With no page loading
 * SvelteKit's client (E38) the build lists none of them, so they are read
 * from the pages themselves: without this, a page kept for offline would
 * open unstyled until the reader had visited once more online (P15.2).
 */
async function keepRelease(): Promise<void> {
  const open = await caches.open(cache);
  await open.addAll([...files, ...pages]);
  const linked = new Set<string>();
  for (const page of pages) {
    const html = await (await open.match(page))?.text();
    for (const match of html?.matchAll(/(?:href|src)="(\/_app\/[^"]+)"/g) ?? []) {
      if (match[1]) linked.add(match[1]);
    }
  }
  await open.addAll([...linked]);
}

self.addEventListener("install", (event) => {
  event.waitUntil(keepRelease());
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((key) => key !== cache).map((key) => caches.delete(key))),
      ),
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== "GET" || url.origin !== self.location.origin) return;
  if (url.pathname.startsWith("/api/")) return;

  event.respondWith(
    (async () => {
      const open = await caches.open(cache);
      if (files.includes(url.pathname)) {
        const kept = await open.match(url.pathname);
        if (kept) return kept;
      }
      try {
        const response = await fetch(request);
        // A page or file kept for offline, unless it asks not to be (a
        // page with a query, such as a test's ?today=, is kept under its
        // path alone).
        if (
          response.status === 200 &&
          !response.headers.get("cache-control")?.includes("no-store")
        ) {
          void open.put(url.search ? url.pathname : request, response.clone());
        }
        return response;
      } catch (error) {
        const kept = (await open.match(request)) ?? (await open.match(url.pathname));
        if (kept) return kept;
        // A page this browser never kept: say so, rather than the browser's error.
        if (request.mode === "navigate") {
          const offline = await open.match("/offline");
          if (offline) return offline;
        }
        throw error;
      }
    })(),
  );
});
