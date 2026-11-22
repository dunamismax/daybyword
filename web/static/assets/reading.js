// The reader's journal in this browser (BUILD.md P8.10c; docs/decisions.md
// E52). Every event the reader makes is kept here, in IndexedDB, and
// nowhere else. To show Today or to make a new event, this script sends the
// journal to daybyword.com's compute endpoints, which answer with the domain
// module and keep nothing; it never works out a reading rule itself. The
// words it shows come from the page's data attributes, never from here.

const database = "day-by-word";
const store = "events";

/** Opens the journal's database, creating its one store the first time. */
function open() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(database, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(store, { keyPath: "id" });
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

/** Runs `work` in a transaction on the events store and resolves when it commits. */
async function transact(mode, work) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(store, mode);
    const result = work(transaction.objectStore(store));
    transaction.oncomplete = () => {
      db.close();
      resolve(result.result ?? result);
    };
    transaction.onerror = () => reject(transaction.error);
  });
}

/** Every event, in id order (journal order). */
async function events() {
  const all = await transact("readonly", (events) => events.getAll());
  return all.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
}

/** Adds events; one already kept, by id, is left as it is. */
function keep(added) {
  return transact("readwrite", (events) => {
    for (const event of added) events.put(event);
    return {};
  });
}

/** The reader's own date, `YYYY-MM-DD`, resolved here once (E7); `?today=` pins it for tests (E14). */
function today() {
  const pinned = new URLSearchParams(location.search).get("today");
  if (pinned && /^\d{4}-\d{2}-\d{2}$/.test(pinned)) return pinned;
  const now = new Date();
  const two = (n) => String(n).padStart(2, "0");
  return `${now.getFullYear()}-${two(now.getMonth() + 1)}-${two(now.getDate())}`;
}

/** Posts JSON to a compute endpoint and returns its JSON answer. */
async function post(path, body) {
  const response = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`${path} answered ${response.status}`);
  return response.json();
}

/** Asks for the events an action makes, and keeps them. */
async function act(action) {
  const answer = await post("/api/v1/events", {
    events: await events(),
    today: today(),
    zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    action,
  });
  await keep(answer.events);
}

function show(element, message) {
  if (!element) return;
  element.textContent = message;
  element.hidden = !message;
}

// MARK: Today

const todayView = document.getElementById("today");
const todayProblem = document.querySelector("[data-today-problem]");

async function showToday() {
  const journal = await events();
  if (journal.length === 0) return;
  const answer = await post("/api/v1/today", { events: journal, today: today() });
  if (answer.html) todayView.innerHTML = answer.html;
}

if (todayView) {
  showToday().catch(() => show(todayProblem, todayView.dataset.notSaved));

  todayView.addEventListener("click", async (event) => {
    const button = event.target instanceof Element ? event.target.closest("button") : null;
    if (!button || (!button.dataset.mark && !button.dataset.undo)) return;
    if (button.dataset.confirm && !window.confirm(button.dataset.confirm)) return;
    button.disabled = true;
    try {
      if (button.dataset.undo) {
        await act({
          kind: "undo",
          enrollment: button.dataset.enrollment,
          target: button.dataset.undo,
        });
      } else {
        await act({
          kind: "mark",
          mark: button.dataset.mark,
          enrollment: button.dataset.enrollment,
          assignment: Number(button.dataset.assignment),
          ...(button.dataset.appointed ? { appointed: button.dataset.appointed } : {}),
        });
      }
      show(todayProblem, "");
      await showToday();
    } catch {
      button.disabled = false;
      show(todayProblem, todayView.dataset.notSaved);
    }
  });
}

// MARK: Starting a plan

const startForm = document.getElementById("start-plan");

if (startForm) {
  const start = startForm.querySelector('input[name="start"]');
  if (start && !start.value) start.value = today();
  const finishDate = startForm.querySelector("[data-finish-date]");
  const behaviorChosen = () =>
    startForm.querySelector('input[name="behavior"]:checked')?.value ??
    startForm.querySelector('input[name="behavior"]')?.value;
  const showFinish = () => {
    if (finishDate) finishDate.hidden = behaviorChosen() !== "finish-date";
  };
  showFinish();
  startForm.addEventListener("change", showFinish);

  startForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const problem = startForm.querySelector("[data-start-problem]");
    const behavior = behaviorChosen();
    const readingDays = [...startForm.querySelectorAll('input[name="day"]:checked')].map((day) =>
      Number(day.value),
    );
    const action = {
      kind: "enroll",
      plan: startForm.dataset.plan,
      behavior,
      start: start?.value || today(),
      readingDays,
    };
    if (behavior === "finish-date") {
      action.finish = startForm.querySelector('input[name="finish"]').value;
      action.limit = Number(startForm.querySelector('input[name="limit"]').value);
    }
    try {
      await act(action);
      location.href = "/today";
    } catch {
      show(problem, startForm.dataset.notStarted);
    }
  });
}

// MARK: Your data

const yourData = document.getElementById("your-data-section");

if (yourData) {
  const status = yourData.querySelector("[data-data-status]");

  yourData.querySelector("[data-export]")?.addEventListener("click", async () => {
    // The same file the app exports: every event in its wire form.
    const file = {
      events: await events(),
      exported: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
      format: "day-by-word-journal",
      version: 1,
    };
    const blob = new Blob([JSON.stringify(file, null, 2)], { type: "application/json" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = "Day by Word reading record.json";
    link.click();
    URL.revokeObjectURL(link.href);
  });

  yourData.querySelector("[data-delete-everything]")?.addEventListener("click", async () => {
    if (!window.confirm(yourData.dataset.deleteConfirm)) return;
    await transact("readwrite", (events) => events.clear());
    show(status, yourData.dataset.deleted);
  });
}
