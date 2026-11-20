<script lang="ts">
  // "About 12 minutes. Estimates vary." Estimates always say they are estimates.
  import { workloadText } from "#lib/strings.ts";

  let { minutes }: { minutes: number } = $props();
</script>

<p class="m-0 text-caption text-text-muted">{workloadText(minutes)}</p>
