<script lang="ts">
  // Progress (docs/product.md, Progress; BUILD.md P8.12), rendered on the
  // server from the journal the browser sent and inserted by
  // /assets/reading.js: the seven days ending today, each in words and a
  // symbol, the books explored in any plan (P11.1), and each plan's readings
  // by state, never a score.
  import type { ProgressPage } from "#lib/server/reading.ts";
  import { text } from "#lib/strings.ts";

  let { progress }: { progress: ProgressPage } = $props();
</script>

<p class="text-text-muted">{text("progress.describes")}</p>
<section class="card mb-m" aria-labelledby="recent-days">
  <h2 class="mt-0 mb-s text-reference-list" id="recent-days">{text("progress.recent-days")}</h2>
  <ol class="m-0 grid list-none grid-cols-7 gap-xxs p-0">
    {#each progress.days as day (day.label)}
      <li class="flex flex-col items-center" aria-label={day.label}>
        <span class="text-caption text-text-muted" aria-hidden="true">{day.initial}</span>
        <span
          class={day.symbol === "✓" ? "text-label text-accent" : "text-label text-text-muted"}
          aria-hidden="true"
        >
          {day.symbol}
        </span>
      </li>
    {/each}
  </ol>
  <p class="mb-0 text-caption text-text-muted">{text("progress.key")}</p>
</section>
{#if progress.books}
  <section class="card mb-m" aria-labelledby="books-explored">
    <h2 class="mt-0 mb-s text-reference-list" id="books-explored">{text("progress.books")}</h2>
    <p class="my-xxs">{progress.books}</p>
    <p class="mb-0 text-caption text-text-muted">{text("progress.books-note")}</p>
  </section>
{/if}
{#each progress.plans as plan (plan.enrollment)}
  <section class="card mb-m" aria-label={plan.plan}>
    <h2 class="mt-0 mb-s text-reference-list">{plan.plan}</h2>
    {#if plan.ended}<p class="text-text-muted">{text("progress.stopped")}</p>{/if}
    <p class="my-xxs">{plan.counts}</p>
    {#if plan.others}<p class="my-xxs text-text-muted">{plan.others}</p>{/if}
    {#if plan.finished}<p class="my-xxs text-text-muted">{text("today.finished")}</p>{/if}
    {#if plan.next}<p class="my-xxs">{plan.next}</p>{/if}
    {#if plan.finish}<p class="mb-0 text-text-muted">{plan.finish}</p>{/if}
  </section>
{/each}
