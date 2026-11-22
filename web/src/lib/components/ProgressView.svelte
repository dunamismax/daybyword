<script lang="ts">
  // Progress (docs/product.md, Progress; BUILD.md P8.12), rendered on the
  // server from the journal the browser sent and inserted by
  // /assets/reading.js: the seven days ending today, each in words and a
  // symbol, with the reading days in a row only when the reader asked (D17),
  // the books explored in any plan with their verses and chapters read
  // (P11.1, P11.4), and each plan's readings by state, never a score, grouped
  // with its history (P11.5).
  import type { ProgressPage } from "#lib/server/reading.ts";
  import { text } from "#lib/strings.ts";

  let { progress }: { progress: ProgressPage } = $props();

  // The archive (P11.5): plans being read first, then paused, finished and
  // stopped ones, each under its own heading.
  const groups = [
    { key: "reading", heading: "progress.group-reading" },
    { key: "paused", heading: "progress.group-paused" },
    { key: "finished", heading: "progress.group-finished" },
    { key: "stopped", heading: "progress.group-stopped" },
  ] as const;
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
  {#if progress.inARow}
    <p class="mt-xs mb-0 text-caption">{progress.inARow}</p>
  {/if}
</section>
{#if progress.books.length > 0}
  <section class="card mb-m" aria-labelledby="books-explored">
    <h2 class="mt-0 mb-s text-reference-list" id="books-explored">{text("progress.books")}</h2>
    <ul class="m-0 list-none p-0">
      {#each progress.books as book (book.name)}
        <li class="mb-xs">
          <span class="font-semibold">{book.name}</span>
          <span class="block text-text-muted">{book.detail}</span>
        </li>
      {/each}
    </ul>
    <p class="mb-0 text-caption text-text-muted">{text("progress.books-note")}</p>
  </section>
{/if}
{#each groups as group (group.key)}
  {@const plans = progress.plans.filter((plan) => plan.group === group.key)}
  {#if plans.length > 0}
    <h2 class="mt-l mb-s text-reference-list">{text(group.heading)}</h2>
    {#each plans as plan (plan.enrollment)}
      <section class="card mb-m" aria-label={plan.plan}>
        <h3 class="mt-0 mb-s text-reference-list">{plan.plan}</h3>
        {#if plan.ended}<p class="text-text-muted">{text("progress.stopped")}</p>{/if}
        <p class="my-xxs">{plan.counts}</p>
        {#if plan.others}<p class="my-xxs text-text-muted">{plan.others}</p>{/if}
        {#if plan.finished}<p class="my-xxs text-text-muted">{text("today.finished")}</p>{/if}
        {#if plan.next}<p class="my-xxs">{plan.next}</p>{/if}
        {#if plan.finish}<p class="mb-0 text-text-muted">{plan.finish}</p>{/if}
        <details class="mt-s" data-history={plan.enrollment}>
          <summary class="min-h-11 cursor-pointer py-xxs font-semibold text-accent">
            {text("history.title")}
          </summary>
          {#if !plan.ended}
            <label class="mt-xs flex flex-col gap-xxs">
              <span>{text("history.date")}</span>
              <input
                class="min-h-11"
                type="date"
                min={plan.start}
                max={plan.today}
                value={plan.today}
                data-history-date
              />
            </label>
            <p class="mt-xxs text-caption text-text-muted">{text("history.date-note")}</p>
          {/if}
          <h4 class="mt-m mb-xs">{text("history.readings")}</h4>
          <ol class="m-0 list-none p-0">
            {#each plan.readings as reading (`${reading.assignment}@${reading.appointed ?? ""}`)}
              <li
                class="flex flex-wrap items-center justify-between gap-xs border-t border-line py-xs"
              >
                <span>
                  <span class="block text-label text-text-muted">{reading.label}</span>
                  <span class="block font-semibold">{reading.reference}</span>
                  <span class="block text-text-muted">{reading.state}</span>
                </span>
                {#if !plan.ended}
                  <span class="flex flex-wrap gap-xs">
                    {#if reading.markable}
                      <button
                        type="button"
                        class="button button-secondary"
                        data-mark="completed"
                        data-enrollment={plan.enrollment}
                        data-assignment={reading.assignment}
                        data-appointed={reading.appointed}
                      >
                        {text("today.mark-read")}
                      </button>
                    {/if}
                    {#if reading.undo}
                      <button
                        type="button"
                        class="button button-secondary"
                        data-undo={reading.undo}
                        data-enrollment={plan.enrollment}
                      >
                        {text("component.undo")}
                      </button>
                    {/if}
                  </span>
                {/if}
              </li>
            {/each}
          </ol>
          <h4 class="mt-m mb-xs">{text("history.changes")}</h4>
          <ol class="m-0 list-none p-0">
            {#each plan.changes as change, index (index)}
              <li class="border-t border-line py-xs">{change}</li>
            {/each}
          </ol>
          <h4 class="mt-m mb-xs">{text("history.this-plan")}</h4>
          <div class="flex flex-wrap gap-xs">
            {#if plan.actions.pause}
              <button
                type="button"
                class="button button-secondary"
                data-action="pause"
                data-enrollment={plan.enrollment}
              >
                {text("history.pause")}
              </button>
            {/if}
            {#if plan.actions.resume}
              <button
                type="button"
                class="button button-secondary"
                data-action="resume"
                data-enrollment={plan.enrollment}
              >
                {text("history.resume")}
              </button>
            {/if}
            {#if plan.actions.end}
              <button
                type="button"
                class="button button-secondary"
                data-action="end"
                data-confirm={text("history.end-confirm")}
                data-enrollment={plan.enrollment}
              >
                {text("history.end")}
              </button>
            {/if}
            {#if plan.actions.restore}
              <button
                type="button"
                class="button button-secondary"
                data-undo={plan.actions.restore}
                data-enrollment={plan.enrollment}
              >
                {text("history.restore")}
              </button>
            {/if}
          </div>
          {#if plan.actions.pause}
            <p class="mb-0 text-caption text-text-muted">{text("history.pause-note")}</p>
          {/if}
          {#if plan.actions.calendar}
            <button
              type="button"
              class="button button-secondary mt-s"
              data-calendar={plan.enrollment}
              data-filename="{plan.plan}.ics"
            >
              {text("calendar.add")}
            </button>
            <p class="mb-0 text-caption text-text-muted">{text("calendar.note")}</p>
          {/if}
        </details>
      </section>
    {/each}
  {/if}
{/each}
