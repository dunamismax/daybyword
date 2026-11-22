// Copy buttons: <button data-copy="Mark 4:1–20" data-copied="Copied"
// data-failed="Selected; copy it with your keyboard">. The messages come from
// the page, not this script (docs/web.md). Without JavaScript, or when the
// browser refuses the clipboard, the reference stays selectable.
// One listener for the page, so buttons Today inserts later work too.
document.addEventListener("click", async (event) => {
  const button = event.target instanceof Element ? event.target.closest("button[data-copy]") : null;
  if (button) {
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      button.textContent = button.dataset.copied;
    } catch {
      const reference = button
        .closest("article, section, li")
        ?.querySelector('.reference [aria-hidden="true"]');
      if (reference) {
        const range = document.createRange();
        range.selectNodeContents(reference);
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
      }
      button.textContent = button.dataset.failed;
    }
  }
});
