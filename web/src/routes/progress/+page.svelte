<script lang="ts">
  // Progress on the web (BUILD.md P8.12). The page is sent with the empty
  // state; /assets/reading.js sends this browser's journal to
  // /api/v1/progress and shows the record that comes back. Nothing is
  // stored on the server.
  import State from "#lib/components/State.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
</script>

<svelte:head>
  <title>{pageTitle(text("section.progress"))}</title>
</svelte:head>

<h1 class="mb-l">{text("section.progress")}</h1>
<div id="progress" aria-live="polite">
  <div class="card">
    <State
      state={{
        kind: "empty",
        title: text("progress.empty-title"),
        message: text("progress.empty-message"),
      }}
    />
  </div>
</div>
