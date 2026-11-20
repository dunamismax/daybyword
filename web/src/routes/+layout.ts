// No page loads SvelteKit's client runtime yet (docs/decisions.md E38): its
// route announcer writes an inline style the strict CSP refuses. Settings and
// the copy buttons use the small same-origin modules in static/assets/.
// Everything renders on the server per request, so the security headers
// apply to every page.
export const csr = false;
export const prerender = false;
