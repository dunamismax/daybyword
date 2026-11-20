<script lang="ts">
  import SectionPage from "#lib/components/SectionPage.svelte";
  import State from "#lib/components/State.svelte";
  import { text } from "#lib/strings.ts";
</script>

<SectionPage title={text("section.plans")}>
  <State
    state={{
      kind: "empty",
      title: text("plans.empty-title"),
      message: text("plans.empty-message"),
    }}
  />
</SectionPage>
