// Route parameter matchers (SvelteKit 3). A plan id in an address must be a
// plan id (docs/urls.md, docs/engine.md); anything else is not found.
import { defineParams } from "@sveltejs/kit/params";
import { isPlanID } from "#lib/domain/ids.ts";

export const params = defineParams({
  planid: (param: string) => (isPlanID(param) ? param : undefined),
});
