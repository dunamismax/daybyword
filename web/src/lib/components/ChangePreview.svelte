<script lang="ts">
  // Shows exactly what a change will do before anything changes. The form
  // does nothing until the reader confirms.
  import { text } from "#lib/strings.ts";

  let {
    title,
    explanation,
    changes,
    confirm,
  }: {
    title: string;
    explanation: string;
    changes: { what: string; before: string; after: string }[];
    confirm: string;
  } = $props();
</script>

<section class="card" aria-labelledby="change-preview-title">
  <h2 class="mt-0 mb-xs text-plan-title" id="change-preview-title">{title}</h2>
  <p>{explanation}</p>
  <dl class="mt-m mb-0">
    {#each changes as change (change.what)}
      <div>
        <dt class="text-label font-label text-text-muted">{change.what}</dt>
        <dd class="mt-0 mb-s ml-0">
          <span class="sr-only">{text("component.change-from")} </span>{change.before}
          <span aria-hidden="true">→</span><span class="sr-only">
            {text("component.change-to")}
          </span>
          {change.after}
        </dd>
      </div>
    {/each}
  </dl>
  <form method="post" class="actions mt-m flex flex-wrap gap-xs">
    <button type="submit" class="button button-primary">{confirm}</button>
    <a class="button button-secondary" href="./">{text("component.cancel")}</a>
  </form>
</section>
