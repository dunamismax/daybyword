<script lang="ts">
  // A plan in a list: what it is, what it covers, and its workload.
  let {
    title,
    kind,
    summary,
    workload,
    schedule,
    href,
  }: {
    title: string;
    kind: string;
    summary: string;
    /** "About 9–11 minutes. Estimates vary." */
    workload: string;
    schedule: string;
    href: string;
  } = $props();
</script>

<article class="card">
  <p class="m-0 text-label font-label text-text-muted">{kind}</p>
  <h2 class="my-xxs text-[1.375rem]"><a class="text-text no-underline" {href}>{title}</a></h2>
  <p class="mt-0 mb-xxs">{summary}</p>
  <p class="m-0 text-caption text-text-muted">{schedule} · {workload}</p>
</article>
