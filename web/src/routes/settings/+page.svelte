<script lang="ts">
  // The first choice of each setting is checked as the page is sent;
  // /assets/settings.js then restores the reader's choice from this browser's
  // storage, applies each new one at once, and keeps it only here. Without
  // JavaScript the defaults show and nothing is saved.
  import ReferenceBlock from "#lib/components/ReferenceBlock.svelte";
  import { pageTitle } from "#lib/sections.ts";
  import { settings, type Setting } from "#lib/settings.ts";
  import { text, type StringKey } from "#lib/strings.ts";

  let { data }: { data: { version: string } } = $props();

  const groups: { setting: Setting; legend: StringKey; note: StringKey }[] = [
    {
      setting: settings[0] as Setting,
      legend: "settings.appearance",
      note: "settings.appearance-note",
    },
    {
      setting: settings[1] as Setting,
      legend: "settings.reference-size",
      note: "settings.reference-size-note",
    },
  ];
</script>

<svelte:head>
  <title>{pageTitle(text("section.settings"))}</title>
</svelte:head>

<h1 class="mb-l">{text("section.settings")}</h1>
<form id="settings">
  {#each groups as group (group.setting.name)}
    <fieldset class="card min-w-0">
      <legend class="float-left mb-s w-full font-semibold">{text(group.legend)}</legend>
      <div class="clear-both flex flex-wrap gap-xs">
        {#each group.setting.values as value, index (value)}
          {@const id = `${group.setting.name}-${value}`}
          <label
            class="inline-flex min-h-11 cursor-pointer items-center gap-xs rounded-control bg-surface-soft px-m has-checked:bg-accent-tint has-checked:font-semibold"
            for={id}
          >
            <input
              class="m-0 accent-accent"
              type="radio"
              {id}
              name={group.setting.name}
              {value}
              checked={index === 0}
            />
            {text(`${group.legend}-${value}` as StringKey)}
          </label>
        {/each}
      </div>
      {#if group.setting.name === "reference-size"}
        <ReferenceBlock
          reference={{
            display: text("settings.sample-reference"),
            spoken: text("settings.sample-reference-spoken"),
          }}
        />
      {/if}
      <p class="text-caption text-text-muted">{text(group.note)}</p>
    </fieldset>
  {/each}
  <p class="text-caption text-text-muted">{text("settings.kept-in-this-browser")}</p>
</form>
<section class="card" aria-labelledby="about">
  <h2 class="mt-0 mb-s text-reference-list" id="about">{text("settings.about")}</h2>
  <p>{text("site.independence")}</p>
  <p class="text-caption text-text-muted">{data.version}</p>
</section>
