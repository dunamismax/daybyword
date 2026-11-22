<script lang="ts">
  // Starting a plan (docs/product.md, "Starting a plan"): the start date, or
  // today's reading for a calendar plan; the behavior, explained; and the
  // reading days. /assets/reading.js sets the start to the reader's own
  // today, sends the form to /api/v1/events, keeps the new event in this
  // browser and opens Today. The web has no reminders at 1.0.
  import type { Behavior } from "#lib/domain/index.ts";
  import { pageTitle } from "#lib/sections.ts";
  import { text, type StringKey } from "#lib/strings.ts";

  let {
    data,
  }: {
    data: {
      plan: {
        id: string;
        title: string;
        calendar: boolean;
        behaviors: readonly Behavior[];
        readingDays: readonly number[];
      };
    };
  } = $props();

  const weekdays = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
  ] as const;
</script>

<svelte:head>
  <title>{pageTitle(text("start.title"))}</title>
</svelte:head>

<p><a href="/plans/{data.plan.id}">{data.plan.title}</a></p>
<h1 class="mb-l">{text("start.title")}</h1>
<form
  id="start-plan"
  class="flex flex-col gap-m"
  data-plan={data.plan.id}
  data-not-started={text("start.not-started")}
>
  <p class="mt-0 text-reference-list font-semibold">{data.plan.title}</p>
  {#if data.plan.calendar}
    <p class="card m-0">{text("start.join-today")}</p>
  {:else}
    <label class="card m-0 flex flex-col gap-xs">
      <span class="font-semibold">{text("start.on")}</span>
      <input class="min-h-11" type="date" name="start" required />
    </label>
  {/if}
  {#if data.plan.behaviors.length > 1}
    <fieldset class="card m-0 min-w-0">
      <legend class="float-left mb-s w-full font-semibold">{text("start.schedule")}</legend>
      {#each data.plan.behaviors as behavior, index (behavior)}
        <label class="clear-both flex min-h-11 items-start gap-xs py-xxs">
          <input
            class="mt-xxs accent-accent"
            type="radio"
            name="behavior"
            value={behavior}
            checked={index === 0}
          />
          <span>
            <span class="font-semibold">{text(`plan.behavior-${behavior}` as StringKey)}</span><br
            /><span class="text-caption text-text-muted">
              {text(`plan.behavior-${behavior}-about` as StringKey)}
            </span>
          </span>
        </label>
      {/each}
      <div class="flex flex-col gap-s" data-finish-date>
        <label class="flex flex-col gap-xs">
          <span class="font-semibold">{text("start.finish")}</span>
          <input class="min-h-11" type="date" name="finish" />
        </label>
        <label class="flex flex-col gap-xs">
          <span class="font-semibold">{text("start.limit")}</span>
          <input class="min-h-11 w-24" type="number" name="limit" min="1" max="10" value="2" />
        </label>
      </div>
    </fieldset>
  {:else}
    <input type="hidden" name="behavior" value={data.plan.behaviors[0]} />
  {/if}
  <fieldset class="card m-0 min-w-0">
    <legend class="float-left mb-s w-full font-semibold">{text("start.days")}</legend>
    <div class="clear-both flex flex-wrap gap-xs">
      {#each weekdays as weekday, index (weekday)}
        <label
          class="inline-flex min-h-11 cursor-pointer items-center gap-xs rounded-control bg-surface-soft px-m has-checked:bg-accent-tint has-checked:font-semibold"
        >
          <input
            class="m-0 accent-accent"
            type="checkbox"
            name="day"
            value={index + 1}
            checked={data.plan.readingDays.includes(index + 1)}
          />
          {text(`weekday.${weekday}`)}
        </label>
      {/each}
    </div>
    <p class="text-caption text-text-muted">
      {text(data.plan.calendar ? "start.days-calendar" : "start.days-rest")}
    </p>
  </fieldset>
  <p class="m-0 text-caption text-text-muted">{text("start.kept")}</p>
  <p class="m-0 text-danger" role="alert" data-start-problem hidden></p>
  <div class="actions flex flex-wrap gap-xs">
    <button type="submit" class="button button-primary">{text("start.submit")}</button>
  </div>
</form>
