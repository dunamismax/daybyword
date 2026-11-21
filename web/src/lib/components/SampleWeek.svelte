<script lang="ts">
  // A plan's sample week: each day's reading and its reference, with rest
  // days named as rest days.
  import type { Reference } from "#lib/reference.ts";
  import { text } from "#lib/strings.ts";
  import Unbroken from "./Unbroken.svelte";

  let {
    readings,
    note,
  }: { readings: readonly { label: string; reference?: Reference }[]; note?: string } = $props();
</script>

<section class="card" aria-labelledby="sample-week">
  <h2 class="mt-0 mb-xs text-body" id="sample-week">{text("component.sample-week")}</h2>
  <ol class="m-0 list-none p-0">
    {#each readings as reading (reading.label)}
      <li class="flex justify-between gap-s py-xxs text-label">
        <span class="text-text-muted">{reading.label}</span>
        {#if reading.reference}
          <span class="text-right font-semibold">
            <span aria-hidden="true"><Unbroken display={reading.reference.display} /></span><span
              class="sr-only"
            >
              {reading.reference.spoken}
            </span>
          </span>
        {:else}
          <span class="text-text-muted">{text("plan.rest-day")}</span>
        {/if}
      </li>
    {/each}
  </ol>
  {#if note}
    <p class="mt-xs mb-0 text-caption text-text-muted">{note}</p>
  {/if}
</section>
