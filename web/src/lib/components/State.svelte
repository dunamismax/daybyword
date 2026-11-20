<script lang="ts">
  // What a page shows when it has nothing yet, is waiting, is offline, or met
  // an error.
  import { page } from "$app/state";
  import { text } from "#lib/strings.ts";

  type State =
    | { kind: "empty"; title: string; message: string }
    | { kind: "loading" }
    | { kind: "offline" }
    | { kind: "error"; message: string };
  let { state }: { state: State } = $props();
</script>

{#if state.kind === "empty"}
  <div class="p-m text-center">
    <p class="mt-0 mb-xs text-reference-list font-reference-list text-text">{state.title}</p>
    <p class="mt-0 mb-xs text-text-muted">{state.message}</p>
  </div>
{:else if state.kind === "loading"}
  <div class="p-m text-center" role="status">
    <p class="mt-0 mb-xs text-text-muted">{text("component.loading")}</p>
  </div>
{:else if state.kind === "offline"}
  <div class="p-m text-center" role="status">
    <p class="mt-0 mb-xs text-reference-list font-reference-list text-text">
      {text("component.offline-title")}
    </p>
    <p class="mt-0 mb-xs text-text-muted">{text("component.offline-message")}</p>
  </div>
{:else}
  <div class="p-m text-center" role="alert">
    <p class="mt-0 mb-xs text-reference-list font-reference-list text-text">
      {text("component.error-title")}
    </p>
    <p class="mt-0 mb-xs text-danger">{state.message}</p>
    <a class="button button-secondary" href={page.url.pathname + page.url.search}>
      {text("component.try-again")}
    </a>
  </div>
{/if}
