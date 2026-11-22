<script lang="ts">
  // The accessibility statement (BUILD.md P16.6).
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";

  const address = text("support.address");
  const reportLink = `mailto:${address}?subject=${encodeURIComponent(text("accessibility.report"))}`;
  const tested = [
    "accessibility.tested-keyboard",
    "accessibility.tested-widths",
    "accessibility.tested-contrast",
    "accessibility.tested-forced",
    "accessibility.tested-words",
    "accessibility.tested-app",
    "accessibility.tested-settings",
    "accessibility.tested-structure",
  ] as const;
  const gaps = ["accessibility.gap-screen-readers"] as const;
</script>

<svelte:head>
  <title>{pageTitle(text("accessibility.title"))}</title>
</svelte:head>

<h1>{text("accessibility.title")}</h1>
<p class="mt-0 mb-l">{text("accessibility.aim")}</p>

<div class="flex flex-col gap-m">
  <section class="card" aria-labelledby="accessibility-tested">
    <h2 class="mt-0 mb-xs text-body" id="accessibility-tested">{text("accessibility.tested")}</h2>
    <ul class="my-0 list-disc pl-l">
      {#each tested as key (key)}
        <li class="mb-xs">{text(key)}</li>
      {/each}
    </ul>
  </section>

  <section class="card" aria-labelledby="accessibility-gaps">
    <h2 class="mt-0 mb-xs text-body" id="accessibility-gaps">{text("accessibility.gaps")}</h2>
    <ul class="mt-0 list-disc pl-l">
      {#each gaps as key (key)}
        <li class="mb-xs">{text(key)}</li>
      {/each}
    </ul>
    <p class="mb-0 text-caption text-text-muted">{text("accessibility.gaps-note")}</p>
  </section>

  <section class="card" aria-labelledby="accessibility-report">
    <h2 class="mt-0 mb-xs text-body" id="accessibility-report">{text("accessibility.report")}</h2>
    <p class="mt-0">{text("accessibility.report-about")}</p>
    <p class="mb-0"><a href={reportLink}>{text("accessibility.report-write")}</a></p>
  </section>
</div>
