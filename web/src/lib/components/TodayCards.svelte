<script lang="ts">
  // Today's cards (docs/product.md, Today; BUILD.md P8.10c), rendered on the
  // server from the journal the browser sent and inserted by
  // /assets/reading.js, which runs the buttons from their data attributes.
  // Every word is the string table's or the catalog's.
  import type { TodayCard } from "#lib/server/reading.ts";
  import { text } from "#lib/strings.ts";
  import CopyButton from "./CopyButton.svelte";
  import ReferenceBlock from "./ReferenceBlock.svelte";

  let { cards }: { cards: readonly TodayCard[] } = $props();
</script>

{#each cards as card (card.enrollment)}
  <article class="card mb-m">
    {#if card.readings.length > 0}
      {#each card.readings as reading (reading.assignment)}
        <p class="mb-0 text-label text-text-muted">{reading.label}</p>
        <ReferenceBlock reference={reading.reference} />
        {#each reading.print ?? [] as line (line)}
          <p class="my-0 text-text-muted" aria-hidden="true">{line}</p>
        {/each}
        <div class="actions mt-s flex flex-wrap gap-xs">
          <button
            type="button"
            class="button button-primary"
            data-mark="completed"
            data-enrollment={card.enrollment}
            data-assignment={reading.assignment}
            data-appointed={reading.appointed}
          >
            {text("today.mark-read")}
          </button>
          {#if reading.open}
            <a class="button button-secondary" href={reading.open.href} rel="noopener noreferrer">
              {text("today.open-youversion")}
            </a>
          {/if}
          <CopyButton reference={reading.reference} />
          <button
            type="button"
            class="button button-secondary"
            data-mark="partlyCompleted"
            data-enrollment={card.enrollment}
            data-assignment={reading.assignment}
            data-appointed={reading.appointed}
          >
            {text("today.mark-part")}
          </button>
          <button
            type="button"
            class="button button-secondary"
            data-mark="skipped"
            data-confirm={text("today.skip-confirm")}
            data-enrollment={card.enrollment}
            data-assignment={reading.assignment}
            data-appointed={reading.appointed}
          >
            {text("today.skip")}
          </button>
        </div>
        {#if reading.open?.note}
          <p class="mb-0 text-caption text-text-muted">{reading.open.note}</p>
        {/if}
        {#if reading.chooseTranslation}
          <p class="mb-0 text-caption">
            <a href="/settings">{text("today.choose-translation")}</a>
          </p>
        {/if}
      {/each}
    {:else}
      <p class="mb-0 text-label text-text-muted">{card.plan}</p>
      <p class="mt-xxs text-reference-list font-semibold">{card.message}</p>
    {/if}
    {#if card.lastMark}
      <div class="mt-s flex items-center justify-between gap-s">
        <span class="text-text-muted">{card.lastMark.message}</span>
        <button
          type="button"
          class="min-h-11 cursor-pointer border-0 bg-transparent px-xs font-semibold text-accent"
          data-undo={card.lastMark.event}
          data-enrollment={card.enrollment}
        >
          {text("component.undo")}
        </button>
      </div>
    {/if}
    {#if card.note}
      <p class="mb-0 text-caption text-text-muted">{card.note}</p>
    {/if}
  </article>
{/each}
