<script lang="ts">
  // Support (BUILD.md P16.2). The address is support@daybyword.com (D28);
  // what is kept matches docs/web.md and docs/deploy.md (the browser keeps
  // the record, the server keeps nothing and logs no address). Every word
  // is the string table's.
  import { pageTitle } from "#lib/sections.ts";
  import { text } from "#lib/strings.ts";

  const address = text("support.address");
  const reportLink = `mailto:${address}?subject=${encodeURIComponent(text("support.report"))}`;
  const questions = [
    ["support.q-text", "support.a-text"],
    ["support.q-translation", "support.a-translation"],
    ["support.q-account", "support.a-account"],
    ["support.q-away", "support.a-away"],
    ["support.q-move", "support.a-move"],
    ["support.q-offline", "support.a-offline"],
    ["support.q-free", "support.a-free"],
    ["support.q-church", "site.independence"],
  ] as const;
</script>

<svelte:head>
  <title>{pageTitle(text("support.title"))}</title>
</svelte:head>

<h1>{text("support.title")}</h1>
<p class="mb-xs">{text("support.intro")}</p>
<p class="mt-0 mb-l text-reference-list font-semibold">
  <a href="mailto:{address}">{address}</a>
</p>

<div class="flex flex-col gap-m">
  <section class="card" aria-labelledby="support-report">
    <h2 class="mt-0 mb-xs text-body" id="support-report">{text("support.report")}</h2>
    <p class="mt-0">{text("support.report-intro")}</p>
    <ul class="mt-0 list-disc pl-l">
      <li>{text("support.report-plan")}</li>
      <li>{text("support.report-reading")}</li>
      <li>{text("support.report-what")}</li>
    </ul>
    <p class="mb-0"><a href={reportLink}>{text("support.report-write")}</a></p>
  </section>

  <section class="card" aria-labelledby="support-kept">
    <h2 class="mt-0 mb-xs text-body" id="support-kept">{text("support.kept")}</h2>
    <p class="mt-0">{text("support.kept-record")}</p>
    <p>{text("support.kept-logs")}</p>
    <p>{text("support.kept-none")}</p>
    <p>{text("support.kept-mail")}</p>
    <ul class="m-0 flex list-none flex-wrap gap-x-m gap-y-xxs p-0">
      <li><a href="/privacy">{text("settings.privacy")}</a></li>
      <li><a href="/terms">{text("settings.terms")}</a></li>
    </ul>
  </section>

  <section aria-labelledby="support-questions">
    <h2 class="mt-0 mb-s text-reference-list font-reference-list" id="support-questions">
      {text("support.questions")}
    </h2>
    {#each questions as [question, answer] (question)}
      <h3 class="mt-m mb-xxs text-body">{text(question)}</h3>
      <p class="mt-0">{text(answer)}</p>
    {/each}
  </section>
</div>
