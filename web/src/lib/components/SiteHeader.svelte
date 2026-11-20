<script lang="ts">
  // The wordmark and the section switcher, a pill with the current section on
  // the accent tint. The current section carries aria-current="page", so it
  // is announced, not only colored. It wraps below the wordmark on narrow
  // screens and at large text sizes.
  import { sectionPath, sections, sectionTitle, type Section } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";
  import Mark from "./Mark.svelte";

  let { current }: { current?: Section | undefined } = $props();
</script>

<header>
  <div class="page flex flex-wrap items-center justify-between gap-x-l gap-y-s pt-m pb-xs">
    <a
      class="inline-flex min-h-11 items-center gap-s text-xl font-bold tracking-[-0.01em] text-text no-underline"
      href="/"
    >
      <Mark />
      <span>{text("site.name")}</span>
    </a>
    <nav aria-label={text("site.sections-label")}>
      <ul
        class="m-0 flex list-none flex-wrap gap-xxs rounded-card border border-line bg-surface p-xxs"
      >
        {#each sections as section (section)}
          <li>
            <a
              class={[
                "inline-flex min-h-11 items-center rounded-control px-m text-label no-underline",
                section === current
                  ? "bg-accent-tint font-semibold text-text"
                  : "text-text-muted hover:text-text",
              ]}
              href={sectionPath(section)}
              aria-current={section === current ? "page" : undefined}
            >
              {sectionTitle(section)}
            </a>
          </li>
        {/each}
      </ul>
    </nav>
  </div>
</header>
