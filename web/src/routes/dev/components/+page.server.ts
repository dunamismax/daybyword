// Every shared component with sample content, for checking them in a browser.
// Served only in development: `vite dev`, or the built server with
// DBW_ENV=development. The content is invented for layout.
import { error } from "@sveltejs/kit";
import { dev } from "$app/env";
import { DBW_ENV } from "$app/env/private";

export const load = () => {
  if (!dev && DBW_ENV !== "development") error(404);
  return {};
};
