// Print buttons: <button data-print hidden>. A button starts hidden, so a
// page without JavaScript never shows one that does nothing; the browser's
// own Print command works either way (BUILD.md P8.10b).
for (const button of document.querySelectorAll("button[data-print]")) {
  button.hidden = false;
  button.addEventListener("click", () => window.print());
}
