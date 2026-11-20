<script lang="ts">
  import AssignmentRow from "#lib/components/AssignmentRow.svelte";
  import ChangePreview from "#lib/components/ChangePreview.svelte";
  import CopyButton from "#lib/components/CopyButton.svelte";
  import PlanCard from "#lib/components/PlanCard.svelte";
  import ReferenceBlock from "#lib/components/ReferenceBlock.svelte";
  import SampleWeek from "#lib/components/SampleWeek.svelte";
  import SourceNote from "#lib/components/SourceNote.svelte";
  import State from "#lib/components/State.svelte";
  import UndoBanner from "#lib/components/UndoBanner.svelte";
  import Workload from "#lib/components/Workload.svelte";
  import { pageTitle } from "#lib/sections.ts";

  const mark = { display: "Mark 4:1–20", spoken: "Mark, chapter 4, verses 1 to 20" };
</script>

<svelte:head>
  <title>{pageTitle("Components")}</title>
</svelte:head>

<h1 class="mb-l">Components</h1>
<article class="card">
  <p class="m-0 text-label font-label text-accent">Gospels at your pace · Reading 31</p>
  <ReferenceBlock reference={mark} />
  <Workload minutes={6} />
  <form method="post" class="actions mt-m flex flex-wrap gap-xs">
    <button type="submit" class="button button-primary">Mark read</button>
    <a class="button button-secondary" href="https://www.bible.com/">Open in YouVersion</a>
    <CopyButton reference={mark} />
  </form>
</article>
<section class="card" aria-label="Readings">
  <ul class="m-0 list-none p-0">
    <AssignmentRow label="Reading 31" reference={mark} status="unread" />
    <AssignmentRow
      label="Reading 30"
      reference={{ display: "Mark 3:20–35", spoken: "Mark, chapter 3, verses 20 to 35" }}
      status="read"
    />
    <AssignmentRow
      label="Reading 29"
      reference={{ display: "Mark 3:1–19", spoken: "Mark, chapter 3, verses 1 to 19" }}
      status="partlyRead"
    />
    <AssignmentRow
      label="Reading 28"
      reference={{ display: "Mark 2", spoken: "Mark, chapter 2" }}
      status="skipped"
    />
  </ul>
</section>
<PlanCard
  title="Gospels at your pace"
  kind="A Day by Word plan"
  summary="Matthew, Mark, Luke, and John in readings of about the same length."
  minutes={6}
  schedule="Continue at my pace"
  href="#plan"
/>
<SampleWeek
  readings={[
    { label: "Reading 1", reference: { display: "Matthew 1", spoken: "Matthew, chapter 1" } },
    { label: "Reading 2", reference: { display: "Matthew 2", spoken: "Matthew, chapter 2" } },
    {
      label: "Reading 3",
      reference: {
        display: "Matthew 3:1–4:11",
        spoken: "Matthew, chapter 3 verse 1 to chapter 4 verse 11",
      },
    },
  ]}
/>
<SourceNote
  note="An original Day by Word plan, built from verse counts and estimated reading time."
/>
<ChangePreview
  title="Welcome back"
  explanation="Here is what continuing from where you left off will do. Your history stays as it is."
  changes={[
    { what: "Next reading", before: "Mark 3:20–35", after: "Mark 4:1–20" },
    { what: "Projected finish", before: "2 March", after: "14 March" },
  ]}
  confirm="Continue"
/>
<UndoBanner message="Marked Mark 4:1–20 read." />
<div class="card">
  <State
    state={{
      kind: "empty",
      title: "No plan yet",
      message: "Choose a plan to see your first reading here.",
    }}
  />
</div>
<div class="card"><State state={{ kind: "loading" }} /></div>
<div class="card"><State state={{ kind: "offline" }} /></div>
<div class="card">
  <State state={{ kind: "error", message: "The plan could not be opened." }} />
</div>
