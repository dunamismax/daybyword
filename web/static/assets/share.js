// Share buttons (BUILD.md P15.4): <button data-share="/plans/psalm-a-day"
// data-share-title="A psalm a day" data-copied="Link copied"
// data-failed="Selected; copy it with your keyboard"
// data-link-label="This plan's link" hidden>. A button starts hidden, so a
// page without JavaScript never shows one that does nothing; the address bar
// holds the link either way. Where the browser can share (the Web Share API:
// phones, and some desktops), the button opens the system's share sheet;
// elsewhere it copies the link, and if the clipboard is refused, it shows the
// link beside it, selected for the keyboard. The messages come from the page,
// not this script (docs/web.md).
for (const button of document.querySelectorAll("button[data-share]")) {
  button.hidden = false;
  button.addEventListener("click", async () => {
    const url = new URL(button.dataset.share, location.href).href;
    const data = { title: button.dataset.shareTitle, url };
    if (navigator.share && (navigator.canShare?.(data) ?? true)) {
      try {
        await navigator.share(data);
        return;
      } catch (error) {
        // The reader closed the share sheet: nothing more to do. Any other
        // refusal falls through to copying the link.
        if (error instanceof DOMException && error.name === "AbortError") return;
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      button.textContent = button.dataset.copied;
    } catch {
      let field = button.parentElement.querySelector("input[data-share-link]");
      if (!field) {
        field = document.createElement("input");
        field.type = "text";
        field.readOnly = true;
        field.value = url;
        field.dataset.shareLink = "";
        field.setAttribute("aria-label", button.dataset.linkLabel);
        // As wide as the link, never wider than the page. Classes the site's
        // pages already use, so the stylesheet has them.
        field.size = url.length;
        field.className =
          "min-h-11 max-w-full rounded-control border border-line bg-background px-s text-text";
        button.after(field);
      }
      field.focus();
      field.select();
      button.textContent = button.dataset.failed;
    }
  });
}
