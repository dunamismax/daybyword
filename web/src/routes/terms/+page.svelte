<script lang="ts">
  // The terms of use (BUILD.md P16.3). Every word is the table's.
  import { pageTitle } from "#lib/sections.ts";
  import { text, type StringKey } from "#lib/strings.ts";

  // Apple's standard Licensed Application End User License Agreement.
  const appleEula = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
  const sections: [StringKey, StringKey][] = [
    ["terms.what", "terms.what-text"],
    ["terms.bible", "terms.bible-text"],
    ["terms.advice", "terms.advice-text"],
    ["terms.accuracy", "terms.accuracy-text"],
    ["terms.record", "terms.record-text"],
    ["terms.content", "terms.content-text"],
    ["terms.changes", "terms.changes-text"],
    ["terms.warranty", "terms.warranty-text"],
  ];
</script>

<svelte:head>
  <title>{pageTitle(text("terms.title"))}</title>
</svelte:head>

<h1>{text("terms.title")}</h1>
<p class="mt-0 mb-l text-caption text-text-muted">{text("terms.effective")}</p>

<div class="flex flex-col gap-m">
  {#each sections as [heading, body] (heading)}
    <section class="card" aria-labelledby={heading.replace(".", "-")}>
      <h2 class="mt-0 mb-xs text-body" id={heading.replace(".", "-")}>{text(heading)}</h2>
      <p class="my-0">{text(body)}</p>
      {#if heading === "terms.accuracy"}
        <p class="mt-xs mb-0"><a href="/support">{text("site.support")}</a></p>
      {/if}
    </section>
  {/each}

  <section class="card" aria-labelledby="terms-app">
    <h2 class="mt-0 mb-xs text-body" id="terms-app">{text("terms.app")}</h2>
    <p class="mt-0">{text("terms.app-text")}</p>
    <p class="mb-0"><a href={appleEula}>{text("terms.app-link")}</a></p>
  </section>

  <section class="card" aria-labelledby="terms-contact">
    <h2 class="mt-0 mb-xs text-body" id="terms-contact">{text("terms.contact")}</h2>
    <p class="my-0">
      <a href="mailto:{text('support.address')}">{text("support.address")}</a>
    </p>
  </section>
</div>
