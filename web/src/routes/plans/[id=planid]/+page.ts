// A plan's page, a placeholder until plan pages are built (P9.4).
export const load = ({ params }: { params: { id: string } }) => ({
  section: "plans" as const,
  id: params.id,
});
