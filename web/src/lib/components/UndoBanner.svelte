<script lang="ts">
  // A quiet confirmation with Undo, announced politely to screen readers.
  import { text } from "#lib/strings.ts";

  let { message }: { message: string } = $props();
</script>

<div
  class="mb-m flex items-center justify-between gap-s rounded-control border border-line bg-surface py-xxs pr-xxs pl-l"
  role="status"
>
  <span>{message}</span>
  <form method="post" class="m-0">
    <button
      type="submit"
      class="min-h-11 cursor-pointer border-0 bg-transparent px-xs font-semibold text-accent"
    >
      {text("component.undo")}
    </button>
  </form>
</div>
