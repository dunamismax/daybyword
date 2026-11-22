// Settings: restores the reader's choices into the form and keeps each new
// choice in this browser's own storage, applying it at once. theme.js applies
// them on every other page. Nothing is sent to the server.
const form = document.getElementById("settings");

const settings = [
  { name: "appearance", key: "dbw.appearance", attribute: "data-theme", fallback: "automatic" },
  {
    name: "reference-size",
    key: "dbw.reference-size",
    attribute: "data-reference-size",
    fallback: "standard",
  },
  // Read by reading.js for Today; nothing to apply to the page.
  { name: "way-to-read", key: "dbw.way-to-read", fallback: "physicalBible" },
  { name: "translation", key: "dbw.translation", fallback: "0" },
  { name: "book-names", key: "dbw.book-names", fallback: "common" },
];

function apply(setting, value) {
  if (!setting.attribute) {
    return;
  }
  if (value === setting.fallback) {
    document.documentElement.removeAttribute(setting.attribute);
  } else {
    document.documentElement.setAttribute(setting.attribute, value);
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
    const select = form.querySelector(`select[name="${setting.name}"]`);
    if (select && saved !== null) {
      select.value = saved;
    }
  }

  form.addEventListener("change", (event) => {
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

  form.addEventListener("submit", (event) => event.preventDefault());
}
