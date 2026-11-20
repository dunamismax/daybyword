<script lang="ts">
  // A reference's display text with its chapter and verses kept on one line,
  // so "4:1–20" never breaks at the dash; copied text stays plain.
  import { splitReference } from "#lib/reference.ts";

  let { display }: { display: string } = $props();
  let parts = $derived(splitReference(display));
</script>

{parts.book}{#if parts.place}<span class="whitespace-nowrap">{parts.place}</span>{/if}
