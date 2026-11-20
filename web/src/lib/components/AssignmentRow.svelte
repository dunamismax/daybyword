<script lang="ts">
  // One reading in a list: its label, its reference, and its status in words
  // and a symbol, never in color alone.
  import type { Reference } from "#lib/reference.ts";
  import { text } from "#lib/strings.ts";
  import Unbroken from "./Unbroken.svelte";

  type Status = "read" | "partlyRead" | "skipped" | "unread";
  let { label, reference, status }: { label: string; reference: Reference; status: Status } =
    $props();

  const shown = {
    read: { symbol: "✓", label: text("component.status-read") },
    partlyRead: { symbol: "◐", label: text("component.status-partly-read") },
    skipped: { symbol: "↷", label: text("component.status-skipped") },
    unread: { symbol: "○", label: text("component.status-unread") },
  } as const;
</script>

<li class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-s py-xs" data-status={status}>
  <span class="col-start-1 text-caption text-text-muted">{label}</span>
  <span class="col-start-1 text-reference-list font-reference-list">
    <span aria-hidden="true"><Unbroken display={reference.display} /></span><span class="sr-only">
      {reference.spoken}
    </span>
  </span>
  <span
    class={[
      "col-start-2 row-span-2 row-start-1 self-center text-label font-label",
      status === "read" ? "text-text" : "text-text-muted",
    ]}
  >
    <span aria-hidden="true">{shown[status].symbol}</span>
    {shown[status].label}
  </span>
</li>
