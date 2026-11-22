/// <reference no-default-lib="true"/>
/// <reference lib="esnext" />
/// <reference lib="webworker" />
// Day by Word offline (BUILD.md P8.11; docs/decisions.md E53): the site's
// own files are kept for each release, and pages are fetched from the
// network first and kept for when there is none, so Today, Progress and
// Settings open offline. The reader's record is never here: it is in
// IndexedDB, and the compute endpoints (POST) pass straight through.
import { self } from "$app/service-worker";
import { version } from "$app/env";
import { immutable, assets } from "$app/manifest";

const cache = `day-by-word-${version}`;
// The site has no base path, so a file's address is its path from the root.
const files: string[] = [...immutable, ...assets].map((asset) => `/${asset.path}`);
/** The pages a reader opens offline. */
const pages = ["/today", "/progress", "/settings"];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(cache).then((open) => open.addAll([...files, ...pages])));
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
        throw error;
      }
    })(),
  );
});
