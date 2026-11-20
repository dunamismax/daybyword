<script lang="ts">
  // Where a plan comes from, in a sentence or two.
  import { text } from "#lib/strings.ts";

  let { note }: { note: string } = $props();
</script>

<p class="m-0 text-caption text-text-muted">
  <strong class="text-text">{text("component.source-label")}</strong>
  {note}
</p>
