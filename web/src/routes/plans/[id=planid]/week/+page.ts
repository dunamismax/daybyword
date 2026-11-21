// A plan's week from a start date, a placeholder until printable weeks are
// built (Phase 13). The start is for display only, and kept only when it
// is a date written YYYY-MM-DD (docs/urls.md).
import { startDate } from "#lib/reference.ts";

export const load = ({ params, url }: { params: { id: string }; url: URL }) => ({
  section: "plans" as const,
  id: params.id,
  start: startDate(url.searchParams.get("start")),
});
