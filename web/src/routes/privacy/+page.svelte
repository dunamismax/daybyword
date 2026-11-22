<script lang="ts">
  // The privacy policy (BUILD.md P16.3) and its statement of cookies and
  // browser storage (P16.4). Every word is the table's; the storage names
  // are the code's own (#lib/storage.ts).
  import { pageTitle } from "#lib/sections.ts";
  import { storedItems } from "#lib/storage.ts";
  import { text, type StringKey } from "#lib/strings.ts";

  const stays: [StringKey, StringKey][] = [
    ["privacy.app", "privacy.app-text"],
    ["privacy.web", "privacy.web-text"],
    ["privacy.deletion", "privacy.deletion-text"],
  ];
  const reaches: [StringKey, StringKey][] = [
    ["privacy.pages", "privacy.pages-text"],
    ["privacy.compute", "privacy.compute-text"],
    ["privacy.log", "privacy.log-text"],
    ["privacy.database", "privacy.database-text"],
    ["privacy.backups", "privacy.backups-text"],
  ];
  const services: [StringKey, StringKey][] = [
    ["privacy.youversion", "privacy.youversion-text"],
    ["privacy.sharing", "privacy.sharing-text"],
    ["privacy.apple", "privacy.apple-text"],
    ["privacy.dns", "privacy.dns-text"],
  ];
</script>

<svelte:head>
  <title>{pageTitle(text("privacy.title"))}</title>
</svelte:head>

<h1>{text("privacy.title")}</h1>
<p class="mt-0 mb-l text-caption text-text-muted">{text("privacy.effective")}</p>

<div class="flex flex-col gap-m">
  <section class="card" aria-labelledby="privacy-short">
    <h2 class="mt-0 mb-xs text-body" id="privacy-short">{text("privacy.short")}</h2>
    <p class="my-0">{text("privacy.short-text")}</p>
  </section>

  <section class="card" aria-labelledby="privacy-who">
    <h2 class="mt-0 mb-xs text-body" id="privacy-who">{text("privacy.who")}</h2>
    <p class="my-0">{text("privacy.who-text")}</p>
  </section>

  <section class="card" aria-labelledby="privacy-stays">
    <h2 class="mt-0 mb-xs text-body" id="privacy-stays">{text("privacy.stays")}</h2>
    {#each stays as [lead, body] (lead)}
      <p class="mt-0 mb-s last:mb-0"><strong>{text(lead)}</strong> {text(body)}</p>
    {/each}
  </section>

  <section class="card" aria-labelledby="privacy-reaches">
    <h2 class="mt-0 mb-xs text-body" id="privacy-reaches">{text("privacy.reaches")}</h2>
    <ul class="my-0 list-disc pl-l">
      {#each reaches as [lead, body] (lead)}
        <li class="mb-xs"><strong>{text(lead)}</strong> {text(body)}</li>
      {/each}
    </ul>
  </section>

  <section class="card" aria-labelledby="privacy-email">
    <h2 class="mt-0 mb-xs text-body" id="privacy-email">{text("privacy.email")}</h2>
    <p class="my-0">{text("privacy.email-text")}</p>
  </section>

  <section class="card" aria-labelledby="privacy-services">
    <h2 class="mt-0 mb-xs text-body" id="privacy-services">{text("privacy.services")}</h2>
    <ul class="my-0 list-disc pl-l">
      {#each services as [lead, body] (lead)}
        <li class="mb-xs"><strong>{text(lead)}</strong> {text(body)}</li>
      {/each}
    </ul>
  </section>

  <section class="card" aria-labelledby="privacy-storage" id="storage">
    <h2 class="mt-0 mb-xs text-body" id="privacy-storage">{text("privacy.storage")}</h2>
    <p class="mt-0">{text("privacy.storage-intro")}</p>
    <ul class="mt-0 mb-s list-none p-0" aria-label={text("privacy.storage-caption")}>
      {#each storedItems as item (item.name)}
        <li class="border-t border-line py-xs">
          <dl class="m-0 grid grid-cols-[minmax(0,max-content)_minmax(0,1fr)] gap-x-s gap-y-xxs">
            <dt class="text-text-muted">{text("privacy.storage-name")}</dt>
            <dd class="m-0"><code class="break-all">{item.name}</code></dd>
            <dt class="text-text-muted">{text("privacy.storage-where")}</dt>
            <dd class="m-0">{text(item.where)}</dd>
            <dt class="text-text-muted">{text("privacy.storage-holds")}</dt>
            <dd class="m-0">{text(item.holds)}</dd>
            <dt class="text-text-muted">{text("privacy.storage-why")}</dt>
            <dd class="m-0">{text(item.why)}</dd>
          </dl>
        </li>
      {/each}
    </ul>
    <p class="mb-0">{text("privacy.storage-after")}</p>
  </section>

  <section class="card" aria-labelledby="privacy-children">
    <h2 class="mt-0 mb-xs text-body" id="privacy-children">{text("privacy.children")}</h2>
    <p class="my-0">{text("privacy.children-text")}</p>
  </section>

  <section class="card" aria-labelledby="privacy-changes">
    <h2 class="mt-0 mb-xs text-body" id="privacy-changes">{text("privacy.changes")}</h2>
    <p class="my-0">{text("privacy.changes-text")}</p>
  </section>
</div>
