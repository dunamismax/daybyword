// Plans: a few practical questions and the plans to consider for the answers
// (BUILD.md P9.1, P9.2), then every plan grouped by goal (P9.3), read from
// PostgreSQL and rendered on the server (docs/web.md). The answers travel in
// a form's body, never the address, and are not kept: the page is worked out
// from them once and forgotten. With no database there are no plans.
import { isGoal, isTime, type Answers } from "#lib/domain/index.ts";
import { planGroups, planList, planSuggestions } from "#lib/server/catalog/present.ts";
import { servedCatalog } from "#lib/server/catalog/read.ts";
import { siteImage, type Share } from "#lib/server/share.ts";
import { text } from "#lib/strings.ts";

/** The days a week the picker offers; anything else is "not sure". */
const dayAnswers = ["7", "5", "3"];

export const load = async () => {
  const catalog = await servedCatalog();
  const share: Share = {
    title: text("section.plans"),
    description: text("plans.description"),
    path: "/plans",
    image: siteImage(),
  };
  return {
    section: "plans" as const,
    plans: catalog ? planList(catalog) : [],
    groups: catalog ? planGroups(catalog) : [],
    share,
  };
};

export const actions = {
  default: async ({ request }: { request: Request }) => {
    const form = await request.formData();
    const hope = form.get("hope");
    const time = form.get("time");
    const days = form.get("days");
    const answers: Answers = {};
    if (isGoal(hope)) answers.hope = hope;
    if (isTime(time)) answers.time = time;
    if (typeof days === "string" && dayAnswers.includes(days)) answers.days = Number(days);
    const catalog = await servedCatalog();
    return {
      answers: {
        hope: answers.hope ?? "",
        time: answers.time ?? "",
        days: answers.days === undefined ? "" : String(answers.days),
      },
      suggestions: catalog ? planSuggestions(catalog, answers) : [],
    };
  },
};
