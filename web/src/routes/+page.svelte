<script lang="ts">
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
</script>

<svelte:head>
  <title>{pageTitle()}</title>
</svelte:head>

<h1>{text("site.name")}</h1>
<p class="mt-0 mb-l text-reference-list font-reference-list">{text("site.tagline")}</p>
<p>{text("site.line")}</p>
<p><a class="button button-primary" href="/today">{text("site.go-to-today")}</a></p>
