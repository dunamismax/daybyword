// Runs only in browsers that cannot load modules (a nomodule script), so it
// is written in the oldest JavaScript: it shows the unsupported-browser
// notice that the page already holds (D30).
(function () {
  var notice = document.getElementById('browser-notice');
  if (notice) {
    notice.removeAttribute('hidden');
  }
})();
