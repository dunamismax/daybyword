<script lang="ts">
  // A reference set large enough to read from across a desk. The visible text
  // is hidden from screen readers, which read the spoken form instead.
  import type { Reference } from "#lib/reference.ts";
  import Unbroken from "./Unbroken.svelte";

  let { reference, heading = 2 }: { reference: Reference; heading?: 1 | 2 } = $props();
</script>

<svelte:element this={heading === 1 ? "h1" : "h2"} class="reference">
  <span aria-hidden="true"><Unbroken display={reference.display} /></span><span class="sr-only">
    {reference.spoken}
  </span>
</svelte:element>
