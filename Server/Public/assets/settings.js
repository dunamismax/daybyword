// Settings: restores the reader's choices into the form and keeps each new
// choice in this browser's own storage, applying it at once. theme.js applies
// them on every other page. Nothing is sent to the server.
const form = document.getElementById('settings');

const settings = [
  { name: 'appearance', key: 'dbw.appearance', attribute: 'theme', fallback: 'automatic' },
  { name: 'reference-size', key: 'dbw.reference-size', attribute: 'referenceSize', fallback: 'standard' },
];

function apply(setting, value) {
  if (value === setting.fallback) {
    delete document.documentElement.dataset[setting.attribute];
  } else {
    document.documentElement.dataset[setting.attribute] = value;
  }
}

if (form) {
  for (const setting of settings) {
    let saved = null;
    try {
      saved = localStorage.getItem(setting.key);
    } catch {
      // Storage unavailable: the form shows the defaults.
    }
    const input = form.querySelector(`input[name="${setting.name}"][value="${saved}"]`);
    if (input) {
      input.checked = true;
    }
  }

  form.addEventListener('change', (event) => {
    const setting = settings.find((candidate) => candidate.name === event.target.name);
    if (!setting) {
      return;
    }
    apply(setting, event.target.value);
    try {
      if (event.target.value === setting.fallback) {
        localStorage.removeItem(setting.key);
      } else {
        localStorage.setItem(setting.key, event.target.value);
      }
    } catch {
      // Storage unavailable: the choice lasts for this page only.
    }
  });

  form.addEventListener('submit', (event) => event.preventDefault());
}
