<script lang="ts">
  // The layout every page shares (BUILD.md P2.8): the skip link, the header
  // with the wordmark and the sections, the old-browser notice, the page,
  // and the footer with the independence statement. A page names its section
  // in its load data, and the header marks it.
  import type { Snippet } from "svelte";
  import { page } from "$app/state";
  import BrowserNotice from "#lib/components/BrowserNotice.svelte";
  import SiteHeader from "#lib/components/SiteHeader.svelte";
  import type { Section } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
  import "../app.css";

  let { children }: { children: Snippet } = $props();
  let section = $derived(page.data["section"] as Section | undefined);
</script>

<a
  class="absolute -top-40 left-m z-10 rounded-control bg-accent px-m py-xs font-semibold text-on-accent focus:top-xs"
  href="#content"
>
  {text("site.skip-to-content")}
</a>
<SiteHeader current={section} />
<BrowserNotice />
<main id="content" class="page pt-xl pb-xxl focus:outline-none" tabindex="-1">
  {@render children()}
</main>
<footer class="border-t border-line text-caption text-text-muted">
  <div class="page pt-l pb-xl">
    <p class="mt-0 mb-xs">{text("site.independence")}</p>
    <p class="mt-0 mb-xs">{text("site.in-development")}</p>
  </div>
</footer>
