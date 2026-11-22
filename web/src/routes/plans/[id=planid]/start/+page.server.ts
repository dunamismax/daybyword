// Starting a plan on the web (BUILD.md P8.10c): the plan's behaviors,
// explained, and its paced reading days, from the served catalog.
// /assets/reading.js sends the form to /api/v1/events and keeps the new
// event in this browser; nothing is stored on the server.
import { error } from "@sveltejs/kit";
import { servedCatalog } from "#lib/server/catalog/read.ts";

export const load = async ({ params }: { params: { id: string } }) => {
  const catalog = await servedCatalog();
  const entry = catalog?.plans.find((plan) => plan.id === params.id);
  if (!catalog || !entry) error(404);
  return {
    section: "plans" as const,
    plan: {
      id: entry.id,
      title: entry.title,
      calendar: entry.plan.schedule === "day-of-month",
      behaviors: entry.plan.behaviors,
      // The days a plan is paced for, from Monday: five days are Monday to
      // Friday, seven every day (as the app's start flow chooses them).
      readingDays: Array.from({ length: entry.plan.readingDays }, (_, index) => index + 1),
    },
  };
};
