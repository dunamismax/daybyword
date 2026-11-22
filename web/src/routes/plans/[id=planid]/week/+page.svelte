<script lang="ts">
  // A week's checklist to print: the plan, seven days with their readings
  // and a box to tick, and the plan's source note (BUILD.md P8.10b). The
  // start date is chosen with a plain form, so it works without JavaScript;
  // the print button appears only when /assets/print.js can run it, and
  // the browser's own Print works either way. The print stylesheet keeps
  // the checklist and drops the site's navigation (app.css). Large print
  // (P13.1) is a box in the same form.
  import SourceNote from "#lib/components/SourceNote.svelte";
  import Unbroken from "#lib/components/Unbroken.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import type { WeekPage } from "#lib/server/catalog/present.ts";
  import { text } from "#lib/strings.ts";

  let { data }: { data: { week: WeekPage; large: boolean } } = $props();
  let week = $derived(data.week);
</script>

<svelte:head>
  <title>{pageTitle(text("week.title"))}</title>
</svelte:head>

<p class="no-print"><a href="/plans/{week.id}">{week.title}</a></p>
<h1 class="mb-xs">{text("week.title")}</h1>

<form class="no-print card flex flex-wrap items-end gap-s" method="get">
  <label class="flex flex-col gap-xxs text-label">
    {text("week.start-label")}
    <input
      class="min-h-11 rounded-control border border-line bg-background px-s text-text"
      type="date"
      name="start"
      value={week.start ?? ""}
    />
  </label>
  <label class="flex min-h-11 items-center gap-xs text-label">
    <input type="checkbox" name="size" value="large" checked={data.large} />
    {text("week.large-print")}
  </label>
  <button class="button button-secondary" type="submit">{text("week.show")}</button>
  <button class="button button-primary" type="button" data-print hidden>
    {text("week.print")}
  </button>
</form>

<section class={["card checklist", data.large && "checklist-large"]} aria-labelledby="week-plan">
  <h2 class="mt-0 mb-xxs text-body" id="week-plan">{week.title}</h2>
  <p class="mt-0 mb-xs text-caption text-text-muted">{week.label}</p>
  <p class="mt-0 mb-m text-label">{week.note}</p>
  <h3 class="sr-only">{text("week.checklist")}</h3>
  <ol class="m-0 list-none p-0">
    {#each week.days as day (day.label)}
      {#if day.references.length === 0}
        <li class="flex flex-wrap items-center gap-s border-t border-line py-s text-label">
          <span class="tick invisible" aria-hidden="true"></span>
          <span class="min-w-32 text-text-muted sm:w-48 sm:shrink-0">{day.label}</span>
          <span class="text-text-muted">{text("plan.rest-day")}</span>
        </li>
      {/if}
      {#each day.references as reference, index (reference.display)}
        <li
          class={[
            "flex flex-wrap items-center gap-s py-s text-label",
            index === 0 && "border-t border-line",
          ]}
        >
          <span class="tick" aria-hidden="true"></span>
          <span class="min-w-32 text-text-muted sm:w-48 sm:shrink-0">
            {index === 0 ? day.label : ""}
          </span>
          <span class="font-semibold">
            <span aria-hidden="true"><Unbroken display={reference.display} /></span><span
              class="sr-only"
            >
              {reference.spoken}
            </span>
          </span>
        </li>
      {/each}
    {/each}
  </ol>
  <p class="mt-s mb-s text-caption text-text-muted">{text("week.tick-note")}</p>
  <SourceNote note={week.source} />
</section>
