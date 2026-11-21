<script lang="ts">
  import PlanCard from "#lib/components/PlanCard.svelte";
  import State from "#lib/components/State.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import type { PlanSummary } from "#lib/server/catalog/present.ts";
  import { text } from "#lib/strings.ts";

  let { data }: { data: { plans: PlanSummary[] } } = $props();
</script>

<svelte:head>
  <title>{pageTitle(text("section.plans"))}</title>
</svelte:head>

<h1 class="mb-l">{text("section.plans")}</h1>
{#if data.plans.length === 0}
  <div class="card">
    <State
      state={{
        kind: "empty",
        title: text("plans.empty-title"),
        message: text("plans.empty-message"),
      }}
    />
  </div>
{:else}
  <ul class="m-0 flex list-none flex-col gap-m p-0">
    {#each data.plans as plan (plan.id)}
      <li>
        <PlanCard
          title={plan.title}
          kind={plan.kind}
          summary={plan.summary}
          workload={plan.workload}
          schedule={plan.readings}
          href={plan.href}
        />
      </li>
    {/each}
  </ul>
{/if}
