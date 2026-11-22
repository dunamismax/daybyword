<script lang="ts">
  // Shares a page's link through /assets/share.js (BUILD.md P15.4): the
  // system's share sheet where the browser has one, or the link copied, or
  // shown selected when the clipboard is refused. The button starts hidden
  // and the script shows it, so a page without JavaScript never offers one
  // that does nothing. Its messages are these attributes.
  import { text } from "#lib/strings.ts";

  let { path, title, label }: { path: string; title: string; label: string } = $props();
</script>

<button
  type="button"
  class="button button-secondary"
  data-share={path}
  data-share-title={title}
  data-copied={text("component.link-copied")}
  data-failed={text("component.copy-failed")}
  data-link-label={text("component.share-link-label")}
  hidden
>
  {label}
</button>
