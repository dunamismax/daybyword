<script lang="ts">
  import SectionPage from "#lib/components/SectionPage.svelte";
  import State from "#lib/components/State.svelte";
  import { text } from "#lib/strings.ts";
</script>

<SectionPage title={text("section.today")}>
  <State state={{ kind: "empty", title: text("today.empty-title"), message: text("site.line") }} />
</SectionPage>
