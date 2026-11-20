<script lang="ts">
  // The plain notice for browsers the web app does not support (D30). It
  // starts hidden; /assets/support.js shows it when a modern feature is
  // missing, /assets/unsupported.js when the browser cannot run modules at
  // all, and the noscript copy covers JavaScript turned off. Pages still read
  // without JavaScript.
  import { text } from "#lib/strings.ts";
</script>

<div class="border-y border-line bg-accent-tint text-text" id="browser-notice" role="note" hidden>
  <p class="page my-0 py-s">{text("site.browser-too-old")}</p>
</div>
<noscript>
  <div class="border-y border-line bg-accent-tint text-text">
    <p class="page my-0 py-s">{text("site.browser-needs-javascript")}</p>
  </div>
</noscript>
