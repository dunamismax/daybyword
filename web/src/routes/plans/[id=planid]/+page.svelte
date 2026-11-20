<script lang="ts">
  import State from "#lib/components/State.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
</script>

<svelte:head>
  <title>{pageTitle(text("plan.title"))}</title>
</svelte:head>

<p><a href="/plans">{text("section.plans")}</a></p>
<h1 class="mb-l">{text("plan.title")}</h1>
<div class="card">
  <State
    state={{ kind: "empty", title: text("plan.empty-title"), message: text("plan.empty-message") }}
  />
</div>
