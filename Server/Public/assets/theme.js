// Applies the reader's appearance and reference size before the page paints,
// from this browser's own storage (settings.js writes them). A classic script
// in the head, so there is no flash of the wrong theme; it touches nothing
// else and sends nothing anywhere.
(function () {
  try {
    var root = document.documentElement;
    var appearance = localStorage.getItem('dbw.appearance');
    var size = localStorage.getItem('dbw.reference-size');
    if (appearance === 'light' || appearance === 'dark') {
      root.dataset.theme = appearance;
    }
    if (size === 'larger' || size === 'largest') {
      root.dataset.referenceSize = size;
    }
  } catch (error) {
    // Storage can be unavailable (private browsing); the defaults apply.
  }
})();
