// Shows the unsupported-browser notice (D30) when a feature the web app
// relies on is missing. The notice's text is in the page; this only unhides
// it. Browsers that cannot run modules at all get unsupported.js instead.
const supported =
  typeof structuredClone === 'function' &&
  typeof Array.prototype.findLast === 'function' &&
  typeof Object.groupBy === 'function' &&
  CSS.supports('selector(:has(a))') &&
  CSS.supports('container-type: inline-size');

if (!supported) {
  document.getElementById('browser-notice')?.removeAttribute('hidden');
}
