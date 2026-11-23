// What the compute endpoints share: JSON bodies only, and refusals in JSON
// that are never cached. A request of another type is refused before it is
// read, so a cross-site form cannot reach these endpoints (E52).

/** A refusal: a status and a word for the browser's script. */
export function refused(status: number, error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

/** The request's JSON body, or the refusal to send. */
export async function readJSON(request: Request): Promise<unknown> {
  const type = request.headers.get("content-type") ?? "";
  if (!type.toLowerCase().startsWith("application/json")) return refused(415, "notJSON");
  try {
    return await request.json();
  } catch (error) {
    // A body over adapter-node's BODY_SIZE_LIMIT is refused while it is read.
    if ((error as { status?: unknown } | null)?.status === 413) return refused(413, "tooLarge");
    return refused(400, "notJSON");
  }
}
