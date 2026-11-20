<script lang="ts">
  // The root layout: the stylesheet and the page. PM.16 ports the Morning
  // shell (header, sections, footer) from the Swift server into it.
  import type { Snippet } from "svelte";
  import "../app.css";

  let { children }: { children: Snippet } = $props();
</script>

{@render children()}
