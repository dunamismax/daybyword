<script lang="ts">
  // How Day by Word chooses its plans (BUILD.md P16.5).
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";

  const criteria = [
    ["criteria.checked", "criteria.checked-about"],
    ["criteria.coverage", "criteria.coverage-about"],
    ["criteria.workload", "criteria.workload-about"],
    ["criteria.instructions", "criteria.instructions-about"],
    ["criteria.basis", "criteria.basis-about"],
    ["criteria.limitations", "criteria.limitations-about"],
    ["criteria.reviewed", "criteria.reviewed-about"],
  ] as const;
</script>

<svelte:head>
  <title>{pageTitle(text("criteria.title"))}</title>
</svelte:head>

<h1>{text("criteria.title")}</h1>
<p class="mt-0 mb-l">{text("criteria.intro")}</p>
<div class="flex flex-col gap-m">
  {#each criteria as [title, about] (title)}
    <section class="card" aria-labelledby={title}>
      <h2 class="mt-0 mb-xs text-body" id={title}>{text(title)}</h2>
      <p class="m-0">{text(about)}</p>
    </section>
  {/each}
</div>
<p class="mt-l">{text("criteria.not")}</p>
<p>{text("site.independence")}</p>
<p>
  <a href="/support">{text("criteria.mistake")}</a>
</p>
<p><a href="/sources">{text("site.sources")}</a></p>
