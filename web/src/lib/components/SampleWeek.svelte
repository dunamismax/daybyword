<script lang="ts">
  // A plan's sample week: the first few readings and their references.
  import type { Reference } from "#lib/reference.ts";
  import { text } from "#lib/strings.ts";
  import Unbroken from "./Unbroken.svelte";

  let { readings }: { readings: { label: string; reference: Reference }[] } = $props();
</script>

<section class="card" aria-labelledby="sample-week">
  <h3 class="mt-0 mb-xs text-body" id="sample-week">{text("component.sample-week")}</h3>
  <ol class="m-0 list-none p-0">
    {#each readings as reading (reading.label)}
      <li class="flex justify-between gap-s py-xxs text-label">
        <span class="text-text-muted">{reading.label}</span>
        <span class="font-semibold">
          <span aria-hidden="true"><Unbroken display={reading.reference.display} /></span><span
            class="sr-only"
          >
            {reading.reference.spoken}
          </span>
        </span>
      </li>
    {/each}
  </ol>
</section>
