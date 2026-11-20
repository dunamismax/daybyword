<script lang="ts">
  // A section's page: its title and its content in a card.
  import type { Snippet } from "svelte";
  import { pageTitle } from "#lib/sections.ts";

  let { title, children }: { title: string; children: Snippet } = $props();
</script>

<svelte:head>
  <title>{pageTitle(title)}</title>
</svelte:head>

<h1 class="mb-l">{title}</h1>
<div class="card">{@render children()}</div>
