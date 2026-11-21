<script lang="ts">
  import State from "#lib/components/State.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";

  let { data }: { data: { id: string; title: string } } = $props();
</script>

<svelte:head>
  <title>{pageTitle(text("week.title"))}</title>
</svelte:head>

<p><a href="/plans/{data.id}">{data.title}</a></p>
<h1 class="mb-l">{text("week.title")}</h1>
<div class="card">
  <State
    state={{ kind: "empty", title: text("week.empty-title"), message: text("week.empty-message") }}
  />
</div>
