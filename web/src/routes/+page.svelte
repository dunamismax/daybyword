<script lang="ts">
  // The home page (BUILD.md P16.1): what Day by Word is, how it works, the
  // plans actually in the catalog, privacy and the independence statement,
  // and the way into Today. Every word is the string table's or the
  // catalog's.
  import { pageTitle } from "#lib/sections.ts";
  import type { PlanSummary } from "#lib/server/catalog/present.ts";
  import { text } from "#lib/strings.ts";

  let { data }: { data: { plans: readonly PlanSummary[] } } = $props();
  const steps = [
    ["home.find", "home.find-about"],
    ["home.read", "home.read-about"],
    ["home.keep", "home.keep-about"],
  ] as const;
</script>

<svelte:head>
  <title>{pageTitle()}</title>
</svelte:head>

<h1>{text("site.name")}</h1>
<p class="mt-0 mb-l text-reference-list font-reference-list">{text("site.tagline")}</p>
<p class="mb-xs font-semibold">{text("site.line")}</p>
<p class="mt-0">{text("home.about")}</p>
<p class="flex flex-wrap gap-s">
  <a class="button button-primary" href="/today">{text("site.go-to-today")}</a>
  <a class="button button-secondary" href="/plans">{text("home.choose")}</a>
</p>

<section class="mt-xl" aria-labelledby="home-how">
  <h2 class="mt-0 mb-s text-reference-list font-reference-list" id="home-how">
    {text("home.how")}
  </h2>
  <div class="grid gap-m sm:grid-cols-3">
    {#each steps as [title, about] (title)}
      <section class="card" aria-labelledby={title}>
        <h3 class="mt-0 mb-xs text-body" id={title}>{text(title)}</h3>
        <p class="m-0">{text(about)}</p>
      </section>
    {/each}
  </div>
</section>

{#if data.plans.length > 0}
  <section class="mt-xl" aria-labelledby="home-plans">
    <h2 class="mt-0 mb-xs text-reference-list font-reference-list" id="home-plans">
      {text("home.plans")}
    </h2>
    <p class="mt-0">{text("home.plans-about")}</p>
    <ul class="m-0 list-none p-0">
      {#each data.plans as plan (plan.id)}
        <li
          class="flex flex-wrap items-baseline justify-between gap-x-s border-t border-line py-xs"
        >
          <a href={plan.href}>{plan.title}</a>
          <span class="text-caption text-text-muted">{plan.kind} · {plan.readings}</span>
        </li>
      {/each}
    </ul>
    <p><a href="/plans">{text("home.plans-all")}</a></p>
  </section>
{/if}

<section class="mt-xl" aria-labelledby="home-private">
  <h2 class="mt-0 mb-xs text-reference-list font-reference-list" id="home-private">
    {text("home.private")}
  </h2>
  <p class="mt-0">{text("home.private-about")}</p>
  <p class="mb-0">{text("site.independence")}</p>
</section>
