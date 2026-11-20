<script lang="ts">
  // A plan in a list: what it is, what it covers, and its workload.
  import { workloadText } from "#lib/strings.ts";

  let {
    title,
    kind,
    summary,
    minutes,
    schedule,
    href,
  }: {
    title: string;
    kind: string;
    summary: string;
    minutes: number;
    schedule: string;
    href: string;
  } = $props();
</script>

<article class="card">
  <p class="m-0 text-label font-label text-text-muted">{kind}</p>
  <h3 class="my-xxs text-[1.375rem]"><a class="text-text no-underline" {href}>{title}</a></h3>
  <p class="mt-0 mb-xxs">{summary}</p>
  <p class="m-0 text-caption text-text-muted">{workloadText(minutes)} · {schedule}</p>
</article>
