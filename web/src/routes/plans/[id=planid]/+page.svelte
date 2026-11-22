<script lang="ts">
  // A plan's page: what it is, whom it suits, its workload, a sample week,
  // what it covers, how it works, what it does not do, and where it comes
  // from (BUILD.md P8.2, P9.4), with a way to share its link (P15.4). Its
  // facts are the compiler's.
  import SampleWeek from "#lib/components/SampleWeek.svelte";
  import ShareButton from "#lib/components/ShareButton.svelte";
  import SourceNote from "#lib/components/SourceNote.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import type { PlanPage } from "#lib/server/catalog/present.ts";
  import { text } from "#lib/strings.ts";

  let { data }: { data: { plan: PlanPage } } = $props();
  let plan = $derived(data.plan);
</script>

<svelte:head>
  <title>{pageTitle(plan.title)}</title>
</svelte:head>

<p><a href="/plans">{text("section.plans")}</a></p>
<h1 class="mb-xs">{plan.title}</h1>
<p class="mt-0 mb-m text-label text-text-muted">{plan.creator} · {plan.kind} · {plan.readings}</p>
<p class="mt-0 mb-l">{plan.summary}</p>

<div class="flex flex-col gap-m">
  <section class="card" aria-labelledby="plan-suits">
    <h2 class="mt-0 mb-xs text-body" id="plan-suits">{text("plan.suits")}</h2>
    <p class="m-0">{plan.suits}</p>
  </section>

  <section class="card" aria-labelledby="plan-workload">
    <h2 class="mt-0 mb-xs text-body" id="plan-workload">{text("plan.workload")}</h2>
    <dl class="m-0">
      {#each plan.workloads as workload (workload.label)}
        <div class="flex flex-wrap justify-between gap-x-s py-xxs">
          <dt class="text-text-muted">{workload.label}</dt>
          <dd class="m-0">{workload.text}</dd>
        </div>
      {/each}
    </dl>
    <p class="mt-xs mb-0 text-caption text-text-muted">{text("component.estimates-vary")}</p>
    <p class="m-0 text-caption text-text-muted">{plan.paced}</p>
    <p class="mt-xs mb-0">{plan.length}</p>
  </section>

  <SampleWeek readings={plan.sample} note={plan.sampleNote} />
  <p class="mb-0 flex flex-wrap items-center gap-s">
    <a class="button button-primary" href="/plans/{plan.id}/start">{text("start.title")}</a>
    <ShareButton path="/plans/{plan.id}" title={plan.title} label={text("plan.share")} />
  </p>
  <p class="mb-0"><a href="/plans/{plan.id}/week">{text("week.link")}</a></p>

  <section class="card" aria-labelledby="plan-covers">
    <h2 class="mt-0 mb-xs text-body" id="plan-covers">{text("plan.covers")}</h2>
    {#each plan.covers as line (line)}
      <p class="mt-0 mb-xxs">{line}</p>
    {/each}
  </section>

  <section class="card" aria-labelledby="plan-how">
    <h2 class="mt-0 mb-xs text-body" id="plan-how">{text("plan.how")}</h2>
    <p class="mt-0 mb-xxs">{plan.how}</p>
    <p class="mt-0 mb-xs">{plan.instructions}</p>
    <dl class="m-0">
      {#each plan.behaviors as behavior (behavior.name)}
        <dt class="mt-xs font-semibold">{behavior.name}</dt>
        <dd class="m-0 text-text-muted">{behavior.about}</dd>
      {/each}
    </dl>
  </section>

  <section class="card" aria-labelledby="plan-limitations">
    <h2 class="mt-0 mb-xs text-body" id="plan-limitations">{text("plan.limitations")}</h2>
    <p class="m-0">{plan.limitations}</p>
  </section>

  <section class="card">
    <SourceNote note={plan.source} />
    <p class="mt-xs mb-0 text-caption text-text-muted">
      <strong class="text-text">{text("plan.review-label")}</strong>
      {plan.review}
    </p>
    <p class="mt-xs mb-0 text-caption text-text-muted">
      <strong class="text-text">{text("plan.permissions-label")}</strong>
      {plan.permissions}
    </p>
  </section>
</div>
