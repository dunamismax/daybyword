<script lang="ts">
  import SectionPage from "#lib/components/SectionPage.svelte";
  import State from "#lib/components/State.svelte";
  import { text } from "#lib/strings.ts";
</script>

<SectionPage title={text("section.progress")}>
  <State
    state={{
      kind: "empty",
      title: text("progress.empty-title"),
      message: text("progress.empty-message"),
    }}
  />
</SectionPage>
