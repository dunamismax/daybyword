<script lang="ts">
  // Sources and permissions (BUILD.md P16.5): each plan's source, review and
  // permissions from the catalog; the data behind its references and
  // reading times from catalog/SOURCES.md, with every credit a source's
  // basis asks for; and what the book registry was checked against. Each
  // plan has an anchor, which its page links to.
  import { pageTitle } from "#lib/sections.ts";
  import type { SourcesPage } from "#lib/server/catalog/present.ts";
  import { text } from "#lib/strings.ts";

  let { data }: { data: { sources?: SourcesPage } } = $props();
  let sources = $derived(data.sources);
</script>

<svelte:head>
  <title>{pageTitle(text("sources.title"))}</title>
</svelte:head>

<h1>{text("sources.title")}</h1>
<p class="mt-0 mb-l">{text("sources.intro")}</p>

{#if sources}
  <section class="mb-xl" aria-labelledby="sources-plans">
    <h2 class="mt-0 mb-s text-reference-list font-reference-list" id="sources-plans">
      {text("sources.plans")}
    </h2>
    <div class="flex flex-col gap-m">
      {#each sources.plans as plan (plan.id)}
        <section class="card" id={plan.id} aria-labelledby="{plan.id}-title">
          <h3 class="mt-0 mb-xs text-body" id="{plan.id}-title">
            <a href={plan.href}>{plan.title}</a>
          </h3>
          <p class="mt-0 mb-xs">{plan.source}</p>
          <p class="mt-0 mb-xs text-caption text-text-muted">
            <strong class="text-text">{text("plan.review-label")}</strong>
            {plan.review}
          </p>
          <p class="m-0 text-caption text-text-muted">
            <strong class="text-text">{text("plan.permissions-label")}</strong>
            {plan.permissions}
          </p>
        </section>
      {/each}
    </div>
  </section>

  <section class="mb-xl" aria-labelledby="sources-data">
    <h2 class="mt-0 mb-xs text-reference-list font-reference-list" id="sources-data">
      {text("sources.data")}
    </h2>
    <p class="mt-0">{text("sources.data-intro")}</p>
    <div class="flex flex-col gap-m">
      {#each sources.data as source (source.id)}
        <section class="card" aria-labelledby="{source.id}-title">
          <h3 class="mt-0 mb-xs text-body" id="{source.id}-title">{source.title}</h3>
          <p class="m-0">{source.about}</p>
          {#if source.credit}
            <p class="mt-xs mb-0 text-caption text-text-muted">
              <strong class="text-text">{text("sources.credit")}</strong>
              <a href={source.credit.href} rel="noopener noreferrer">{source.credit.text}</a>
            </p>
            <p class="m-0 text-caption text-text-muted">{source.credit.licence}</p>
          {/if}
        </section>
      {/each}
    </div>
  </section>

  {#if sources.books.length > 0}
    <section class="mb-l" aria-labelledby="sources-books">
      <h2 class="mt-0 mb-xs text-reference-list font-reference-list" id="sources-books">
        {text("sources.books")}
      </h2>
      <p class="mt-0">{text("sources.books-intro")}</p>
      <ul class="m-0 list-none p-0">
        {#each sources.books as book (book.title)}
          <li class="border-t border-line py-xs">
            <span class="block">{book.title}</span>
            <span class="block text-caption text-text-muted">{book.publisher}</span>
          </li>
        {/each}
      </ul>
    </section>
  {/if}
{/if}

<p class="text-caption text-text-muted">{text("sources.more")}</p>
