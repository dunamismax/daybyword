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
  import { siteOrigin, type Share } from "#lib/site.ts";
  import { text } from "#lib/strings.ts";
  import "../app.css";
  // The browser's own bar takes Morning's page color (P15.1).
  import tokens from "../../../design/tokens.json";

  let { children }: { children: Snippet } = $props();
  let section = $derived(page.data["section"] as Section | undefined);
  // A public page's description and link preview (BUILD.md P9.9).
  let share = $derived(page.data["share"] as Share | undefined);
</script>

<svelte:head>
  <meta
    name="theme-color"
    media="(prefers-color-scheme: light)"
    content={tokens.color.background.light}
  />
  <meta
    name="theme-color"
    media="(prefers-color-scheme: dark)"
    content={tokens.color.background.dark}
  />
  {#if share}
    <meta name="description" content={share.description} />
    <meta property="og:type" content="website" />
    <meta property="og:site_name" content={text("site.name")} />
    <meta property="og:title" content={share.title} />
    <meta property="og:description" content={share.description} />
    <meta property="og:url" content="{siteOrigin}{share.path}" />
    <meta property="og:image" content="{siteOrigin}{share.image.path}" />
    <meta property="og:image:width" content={String(share.image.width)} />
    <meta property="og:image:height" content={String(share.image.height)} />
  {/if}
</svelte:head>

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
    <nav aria-label={text("site.about-label")}>
      <ul class="m-0 flex list-none flex-wrap gap-x-m gap-y-xxs p-0">
        <li><a href="/support">{text("site.support")}</a></li>
        <li><a href="/sources">{text("site.sources")}</a></li>
        <li><a href="/criteria">{text("site.criteria")}</a></li>
        <li><a href="/accessibility">{text("site.accessibility")}</a></li>
      </ul>
    </nav>
  </div>
</footer>
