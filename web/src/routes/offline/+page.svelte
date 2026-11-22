<script lang="ts">
  // Offline (BUILD.md P15.2): shown in place of a page this browser has not
  // kept, when there is no connection. The service worker keeps this page
  // with each release, so it never needs the network itself.
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
</script>

<svelte:head>
  <title>{pageTitle(text("component.offline-title"))}</title>
</svelte:head>

<h1>{text("component.offline-title")}</h1>
<p>{text("offline.message")}</p>
<p class="text-text-muted">{text("component.offline-message")}</p>
<p><a class="button button-primary" href="/today">{text("site.go-to-today")}</a></p>
