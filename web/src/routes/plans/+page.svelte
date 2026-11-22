<script lang="ts">
  // Plans (docs/product.md, "Plans"): a few practical questions, the plans to
  // consider for the answers with their reasons, then every plan by goal. The
  // form works with no script: the server answers its POST with this page.
  import PlanCard from "#lib/components/PlanCard.svelte";
  import State from "#lib/components/State.svelte";
  import { goals, times } from "#lib/domain/choosing.ts";
  import { pageTitle } from "#lib/sections.ts";
  import type { PlanGroup, PlanSuggestion, PlanSummary } from "#lib/server/catalog/present.ts";
  import { text, type StringKey } from "#lib/strings.ts";

  let {
    data,
    form,
  }: {
    data: { plans: PlanSummary[]; groups: PlanGroup[] };
    form?: {
      answers: { hope: string; time: string; days: string };
      suggestions: PlanSuggestion[];
    } | null;
  } = $props();

  const answers = $derived(form?.answers ?? { hope: "", time: "", days: "" });
  // The days a week the picker offers, as the action reads them, in order.
  const dayChoices: [string, StringKey][] = [
    ["", "choose.not-sure"],
    ["7", "choose.days-every"],
    ["5", "choose.days-five"],
    ["3", "choose.days-few"],
  ];
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
  <section aria-labelledby="choose-title" class="mb-l">
    <h2 id="choose-title" class="mt-0 mb-s text-reference-list">{text("choose.title")}</h2>
    <p>{text("choose.intro")}</p>
    <form method="POST" action="#suggestions" class="flex flex-col gap-m">
      <fieldset class="card m-0 min-w-0">
        <legend class="float-left mb-s w-full font-semibold">{text("choose.hope")}</legend>
        <div class="clear-both flex flex-wrap gap-xs">
          {#each ["", ...goals] as goal (goal)}
            <label
              class="inline-flex min-h-11 cursor-pointer items-center gap-xs rounded-control bg-surface-soft px-m has-checked:bg-accent-tint has-checked:font-semibold"
            >
              <input
                class="m-0 accent-accent"
                type="radio"
                name="hope"
                value={goal}
                checked={answers.hope === goal}
              />
              {goal === "" ? text("choose.not-sure") : text(`goal.${goal}` as StringKey)}
            </label>
          {/each}
        </div>
      </fieldset>
      <fieldset class="card m-0 min-w-0">
        <legend class="float-left mb-s w-full font-semibold">{text("choose.time")}</legend>
        <div class="clear-both flex flex-wrap gap-xs">
          {#each ["", ...times] as time (time)}
            <label
              class="inline-flex min-h-11 cursor-pointer items-center gap-xs rounded-control bg-surface-soft px-m has-checked:bg-accent-tint has-checked:font-semibold"
            >
              <input
                class="m-0 accent-accent"
                type="radio"
                name="time"
                value={time}
                checked={answers.time === time}
              />
              {time === "" ? text("choose.not-sure") : text(`choose.time-${time}` as StringKey)}
            </label>
          {/each}
        </div>
      </fieldset>
      <fieldset class="card m-0 min-w-0">
        <legend class="float-left mb-s w-full font-semibold">{text("choose.days")}</legend>
        <div class="clear-both flex flex-wrap gap-xs">
          {#each dayChoices as [days, label] (days)}
            <label
              class="inline-flex min-h-11 cursor-pointer items-center gap-xs rounded-control bg-surface-soft px-m has-checked:bg-accent-tint has-checked:font-semibold"
            >
              <input
                class="m-0 accent-accent"
                type="radio"
                name="days"
                value={days}
                checked={answers.days === days}
              />
              {text(label)}
            </label>
          {/each}
        </div>
      </fieldset>
      <div class="actions flex flex-wrap gap-xs">
        <button type="submit" class="button button-primary">{text("choose.submit")}</button>
      </div>
    </form>
  </section>

  {#if form}
    <section aria-labelledby="suggestions-title" class="mb-l" id="suggestions">
      <h2 id="suggestions-title" class="mt-0 mb-s text-reference-list">{text("choose.results")}</h2>
      <ul class="m-0 flex list-none flex-col gap-m p-0">
        {#each form.suggestions as plan (plan.id)}
          <li>
            <article class="card">
              <p class="m-0 text-label font-label text-text-muted">{plan.kind}</p>
              <h3 class="my-xxs text-[1.375rem]">
                <a class="text-text no-underline" href={plan.href}>{plan.title}</a>
              </h3>
              <p class="mt-0 mb-xs">{plan.summary}</p>
              <ul class="m-0 flex flex-col gap-xxs pl-m">
                {#each plan.reasons as reason (reason)}
                  <li>{reason}</li>
                {/each}
              </ul>
            </article>
          </li>
        {/each}
      </ul>
      <p class="text-caption text-text-muted">{text("choose.results-note")}</p>
    </section>
  {/if}

  <h2 class="mt-0 mb-s text-reference-list">{text("plans.every-plan")}</h2>
  {#if data.groups.length === 0}
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
            level={3}
          />
        </li>
      {/each}
    </ul>
  {:else}
    {#each data.groups as group (group.goal)}
      <section aria-labelledby="goal-{group.goal}" class="mb-l">
        <h3 id="goal-{group.goal}" class="mt-0 mb-s text-body font-semibold text-text-muted">
          {group.label}
        </h3>
        <ul class="m-0 flex list-none flex-col gap-m p-0">
          {#each group.plans as plan (plan.id)}
            <li>
              <PlanCard
                title={plan.title}
                kind={plan.kind}
                summary={plan.summary}
                workload={plan.workload}
                schedule={plan.readings}
                href={plan.href}
                level={4}
              />
            </li>
          {/each}
        </ul>
      </section>
    {/each}
  {/if}
{/if}
