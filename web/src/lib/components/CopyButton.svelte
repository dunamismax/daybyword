<script lang="ts">
  // Copies the reference through /assets/copy.js, which takes its messages
  // from these attributes. If the browser refuses the clipboard, the reference
  // beside it is selected for the keyboard instead; without JavaScript it
  // stays selectable.
  import type { Reference } from "#lib/reference.ts";
  import { text } from "#lib/strings.ts";

  let { reference }: { reference: Reference } = $props();
</script>

<button
  type="button"
  class="button button-secondary"
  data-copy={reference.display}
  data-copied={text("component.copied")}
  data-failed={text("component.copy-failed")}
>
  {text("component.copy-reference")}
</button>
