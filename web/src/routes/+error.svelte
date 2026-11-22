<script lang="ts">
  // An unknown address gets the site's own "Page not found" page, in the
  // layout, with status 404; any other error (a 500, such as the catalog's
  // database out of reach) says so plainly and that nothing is lost
  // (BUILD.md P16.8). src/error.html covers an error this page cannot show.
  import { page } from "$app/state";
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";

  let notFound = $derived(page.status === 404);
  let title = $derived(text(notFound ? "not-found.title" : "component.error-title"));
</script>

<svelte:head>
  <title>{pageTitle(title)}</title>
</svelte:head>

<h1>{title}</h1>
{#if notFound}
  <p>{text("not-found.message")}</p>
{:else}
  <p>{text("component.error-message")}</p>
{/if}
<p><a href="/today">{text("site.go-to-today")}</a></p>
