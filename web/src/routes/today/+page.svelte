<script lang="ts">
  // Today on the web (BUILD.md P8.10c). The page is sent with the welcome
  // for a reader with no plan; /assets/reading.js reads this browser's
  // journal and, when it holds a plan, sends it to /api/v1/today and shows
  // the cards that come back. Nothing is stored on the server.
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
</script>

<svelte:head>
  <title>{pageTitle(text("section.today"))}</title>
</svelte:head>

<h1 class="mb-l">{text("section.today")}</h1>
<div class="card mb-m" role="status" data-today-offline hidden>
  <p class="mt-0 font-semibold">{text("component.offline-title")}</p>
  <p class="mb-0 text-text-muted">{text("component.offline-message")}</p>
</div>
<div
  id="today"
  aria-live="polite"
  data-loading={text("component.loading")}
  data-not-saved={text("today.not-saved")}
>
  <div class="card" data-today-empty>
    <p class="mt-0 text-reference-list font-semibold">{text("today.empty-title")}</p>
    <p class="text-text-muted">{text("site.line")}</p>
    <p class="mb-0">
      <a class="button button-primary" href="/plans">{text("today.choose-plan")}</a>
    </p>
  </div>
</div>
<p class="text-danger" role="alert" data-today-problem hidden></p>
