// The reader's journal in this browser (BUILD.md P8.10c; docs/decisions.md
// E52). Every event the reader makes is kept here, in IndexedDB, and
// nowhere else. To show Today or to make a new event, this script sends the
// journal to daybyword.com's compute endpoints, which answer with the domain
// module and keep nothing; it never works out a reading rule itself. The
// words it shows come from the page's data attributes, never from here.

const database = "day-by-word";
const store = "events";

/** Marks made offline, waiting to be sent (P8.11, E53). */
const pendingStore = "pending";

/** Opens the journal's database, creating its stores the first time. */
function open() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(database, 2);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(store)) db.createObjectStore(store, { keyPath: "id" });
      if (!db.objectStoreNames.contains(pendingStore)) {
        db.createObjectStore(pendingStore, { keyPath: "id" });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

/** Runs `work` in a transaction on a store (the events, unless named) and resolves when it commits. */
async function transact(mode, work, name = store) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(name, mode);
    const result = work(transaction.objectStore(name));
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
  // The last thing done in this tab, so Today can offer to take it back
  // (the app's Undo banner); it lasts only as long as the tab.
  try {
    sessionStorage.setItem("dbw.last-action", answer.events.at(-1)?.id ?? "");
  } catch {
    // Without session storage, Undo is offered for today's marks only.
  }
}

// MARK: Offline (P8.11, E53)

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js", { type: "module" }).catch(() => {
    // No offline copy of the site in this browser; everything else works.
  });
}

const two = (byte) => byte.toString(16).padStart(2, "0");

/**
 * A new event id made here, for a mark made offline: a UUIDv7 laid out as
 * the domain module's makeEventID lays it out (the server refuses any other
 * shape), later than every event of its plan.
 */
function newEventID(enrollment, journal) {
  const ms = (id) => Number.parseInt(id.slice(0, 8) + id.slice(9, 13), 16);
  const latest = journal
    .filter((event) => event.enrollment === enrollment)
    .reduce((most, event) => Math.max(most, ms(event.id)), ms(enrollment));
  const time = Math.max(Date.now(), latest + 1)
    .toString(16)
    .padStart(12, "0");
  const r = [...crypto.getRandomValues(new Uint8Array(10))];
  const tail = r.slice(3).map(two).join("");
  return [
    time.slice(0, 8),
    time.slice(8),
    two(0x70 | (r[0] & 0x0f)) + two(r[1]),
    two(0x80 | (r[2] & 0x3f)) + tail.slice(0, 2),
    tail.slice(2),
  ].join("-");
}

/** Keeps today's cards and the coming days' for when there is no connection. */
function keepAhead(answer) {
  try {
    const days = { [today()]: answer.html };
    for (const day of answer.ahead ?? []) days[day.date] = day.html;
    localStorage.setItem("dbw.today-ahead", JSON.stringify(days));
  } catch {
    // Without storage there is no offline copy of Today.
  }
}

/** The cards kept for a date, if any. */
function keptFor(date) {
  try {
    return JSON.parse(localStorage.getItem("dbw.today-ahead") ?? "{}")[date];
  } catch {
    return undefined;
  }
}

/** Sends the marks made offline, oldest first, and keeps what comes back. */
async function sendPending() {
  const pending = await transact("readonly", (s) => s.getAll(), pendingStore);
  for (const item of pending.sort((a, b) => (a.id < b.id ? -1 : 1))) {
    const answer = await post("/api/v1/events", {
      events: await events(),
      today: today(),
      zone: item.zone,
      action: { ...item.action, id: item.id, date: item.date },
    });
    await keep(answer.events);
    await transact("readwrite", (s) => s.delete(item.id), pendingStore);
    try {
      sessionStorage.setItem("dbw.last-action", item.id);
    } catch {
      // Undo is then offered for today's marks only.
    }
  }
  return pending.length;
}

function show(element, message) {
  if (!element) return;
  element.textContent = message;
  element.hidden = !message;
}

/**
 * Keeps keyboard focus in the reader's place when a view's buttons are
 * replaced (BUILD.md P15.4). The view's HTML is new after every action, so
 * the button pressed is gone and focus would fall back to the top of the
 * page. If that button had focus, the first of `wanted` (selectors, tried
 * in order) for the same plan and reading takes it instead: Undo after Mark
 * read, Mark read after Undo; failing those, the plan's first button.
 */
function keepFocus(view, pressed, wanted) {
  if (!pressed.focused || pressed.button.isConnected) return;
  const plan = `[data-enrollment="${CSS.escape(pressed.button.dataset.enrollment ?? "")}"]`;
  const { assignment, appointed } = pressed.button.dataset;
  const reading = assignment
    ? `[data-assignment="${CSS.escape(assignment)}"]` +
      (appointed ? `[data-appointed="${CSS.escape(appointed)}"]` : "")
    : "";
  const tries = [...wanted.flatMap((selector) => [selector + plan + reading, selector + plan])];
  for (const selector of [...tries, "button" + plan]) {
    const found = view.querySelector(selector);
    if (found instanceof HTMLElement && !found.hidden && !found.disabled) {
      found.focus();
      return;
    }
  }
}

/** Where focus belongs after an action from `button` (keepFocus). */
function pressedNow(button) {
  return { button, focused: document.activeElement === button };
}

// MARK: Today

const todayView = document.getElementById("today");
const todayProblem = document.querySelector("[data-today-problem]");
const offlineNotice = document.querySelector("[data-today-offline]");

/** A setting from this browser's storage (settings.js keeps them), or nothing. */
function setting(key) {
  try {
    return localStorage.getItem(key) ?? undefined;
  } catch {
    return undefined;
  }
}

/** Today from the server, or, without a connection, the cards kept for today. */
async function showToday() {
  try {
    await showTodayOnline();
    if (offlineNotice) offlineNotice.hidden = true;
  } catch (error) {
    const kept = keptFor(today());
    if (!kept) throw error;
    todayView.innerHTML = kept;
    if (offlineNotice) offlineNotice.hidden = false;
  }
}

async function showTodayOnline() {
  const journal = await events();
  if (journal.length === 0) return;
  const answer = await post("/api/v1/today", {
    events: journal,
    today: today(),
    names: setting("dbw.book-names"),
    way: setting("dbw.way-to-read"),
    translation: setting("dbw.translation"),
    lastAction: (() => {
      try {
        return sessionStorage.getItem("dbw.last-action") || undefined;
      } catch {
        return undefined;
      }
    })(),
  });
  if (answer.html) todayView.innerHTML = answer.html;
  keepAhead(answer);
}

if (todayView) {
  sendPending()
    .catch(() => 0)
    .then(() => showToday())
    .catch(() => show(todayProblem, todayView.dataset.notSaved));
  addEventListener("online", () => {
    sendPending()
      .then(() => showToday())
      .catch(() => {});
  });

  // A page left open past midnight, or brought back after a day away or a
  // flight, shows the new day's readings (P17.4): when the reader returns
  // to the tab, and at midnight for a page left showing.
  let shownFor = today();
  const showIfTheDayTurned = () => {
    if (today() === shownFor) return;
    shownFor = today();
    showToday().catch(() => {});
  };
  addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") showIfTheDayTurned();
  });
  addEventListener("focus", showIfTheDayTurned);
  const atMidnight = () => {
    const now = new Date();
    const next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 5);
    setTimeout(() => {
      showIfTheDayTurned();
      atMidnight();
    }, next.getTime() - now.getTime());
  };
  atMidnight();

  todayView.addEventListener("click", async (event) => {
    const button = event.target instanceof Element ? event.target.closest("button") : null;
    if (!button || (!button.dataset.mark && !button.dataset.undo && !button.dataset.return)) {
      return;
    }
    if (button.dataset.confirm && !window.confirm(button.dataset.confirm)) return;
    const pressed = pressedNow(button);
    button.disabled = true;
    try {
      if (button.dataset.return) {
        // A welcome's choice, previewed on the card and confirmed here.
        await act({
          kind: "return",
          enrollment: button.dataset.enrollment,
          choice: button.dataset.return,
        });
      } else if (button.dataset.undo) {
        await act({
          kind: "undo",
          enrollment: button.dataset.enrollment,
          target: button.dataset.undo,
        });
      } else {
        // "Log an earlier day" sends the date the reader chose beside it.
        const earlier = button.hasAttribute("data-earlier-for")
          ? button.parentElement?.querySelector("input[data-earlier]")?.value
          : undefined;
        if (button.hasAttribute("data-earlier-for") && !earlier) {
          button.disabled = false;
          return;
        }
        await act({
          kind: "mark",
          mark: button.dataset.mark,
          enrollment: button.dataset.enrollment,
          assignment: Number(button.dataset.assignment),
          ...(button.dataset.appointed ? { appointed: button.dataset.appointed } : {}),
          ...(earlier ? { date: earlier } : {}),
        });
      }
      show(todayProblem, "");
      await showToday();
      keepFocus(
        todayView,
        pressed,
        button.dataset.mark && !button.hasAttribute("data-earlier-for")
          ? ["button[data-undo]"]
          : ['button[data-mark="completed"]:not([data-earlier-for])'],
      );
    } catch (error) {
      // Without a connection, a mark is kept here with the id and date it
      // was made with, and sent when the browser is back online; the card
      // says so (an undo or a welcome's answer waits for a connection).
      // fetch fails with a TypeError when the network does; an answer the
      // server refuses is not kept.
      if (button.dataset.mark && (error instanceof TypeError || !navigator.onLine)) {
        const journal = await events();
        const earlier = button.hasAttribute("data-earlier-for")
          ? button.parentElement?.querySelector("input[data-earlier]")?.value
          : undefined;
        await transact(
          "readwrite",
          (s) =>
            s.put({
              id: newEventID(button.dataset.enrollment, journal),
              date: earlier || today(),
              zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
              action: {
                kind: "mark",
                mark: button.dataset.mark,
                enrollment: button.dataset.enrollment,
                assignment: Number(button.dataset.assignment),
                ...(button.dataset.appointed ? { appointed: button.dataset.appointed } : {}),
              },
            }),
          pendingStore,
        );
        for (const sibling of button.closest("article")?.querySelectorAll("button") ?? []) {
          sibling.disabled = true;
        }
        if (offlineNotice) offlineNotice.hidden = false;
        return;
      }
      button.disabled = false;
      show(todayProblem, todayView.dataset.notSaved);
    }
  });
}

// MARK: Progress

const progressView = document.getElementById("progress");

/** Shows Progress for the record in this browser, keeping open any History the reader opened. */
async function showProgress() {
  const journal = await events();
  if (journal.length === 0) return;
  const open = [...progressView.querySelectorAll("details[data-history][open]")].map(
    (details) => details.dataset.history,
  );
  const answer = await post("/api/v1/progress", {
    events: journal,
    today: today(),
    names: setting("dbw.book-names"),
    streak: setting("dbw.streak"),
  });
  if (!answer.html) return;
  progressView.innerHTML = answer.html;
  for (const details of progressView.querySelectorAll("details[data-history]")) {
    if (open.includes(details.dataset.history)) details.open = true;
  }
}

if (progressView) {
  showProgress().catch(() => {
    // Progress stays as sent; Today says when something cannot be reached.
  });

  // History (P11.5): mark a reading read on the date chosen above it, take
  // back a reading's last mark, or pause, resume, stop following or follow
  // again the plan itself. These need a connection.
  progressView.addEventListener("click", async (event) => {
    const button = event.target instanceof Element ? event.target.closest("button") : null;
    if (button?.dataset.calendar) {
      await saveCalendar(button);
      return;
    }
    if (!button || (!button.dataset.mark && !button.dataset.undo && !button.dataset.action)) {
      return;
    }
    if (button.dataset.confirm && !window.confirm(button.dataset.confirm)) return;
    const pressed = pressedNow(button);
    button.disabled = true;
    try {
      if (button.dataset.action) {
        // Pause, resume or stop following the plan, from today.
        await act({ kind: button.dataset.action, enrollment: button.dataset.enrollment });
      } else if (button.dataset.undo) {
        await act({
          kind: "undo",
          enrollment: button.dataset.enrollment,
          target: button.dataset.undo,
        });
      } else {
        const date = button.closest("details")?.querySelector("input[data-history-date]")?.value;
        await act({
          kind: "mark",
          mark: button.dataset.mark,
          enrollment: button.dataset.enrollment,
          assignment: Number(button.dataset.assignment),
          ...(button.dataset.appointed ? { appointed: button.dataset.appointed } : {}),
          ...(date ? { date } : {}),
        });
      }
      await showProgress();
      keepFocus(
        progressView,
        pressed,
        button.dataset.action
          ? ["button[data-action]", "button[data-undo]"]
          : button.dataset.mark
            ? ["button[data-undo]"]
            : ["button[data-mark]", "button[data-action]"],
      );
    } catch {
      button.disabled = false;
    }
  });
}

/**
 * The next four weeks of a plan as a calendar file (P13.4): the engine's
 * days ahead from the server, saved as a download. Nothing is kept there.
 */
async function saveCalendar(button) {
  button.disabled = true;
  try {
    const response = await fetch("/api/v1/calendar", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        events: await events(),
        today: today(),
        enrollment: button.dataset.calendar,
        names: setting("dbw.book-names"),
      }),
    });
    if (!response.ok) throw new Error(`/api/v1/calendar answered ${response.status}`);
    const url = URL.createObjectURL(await response.blob());
    const link = document.createElement("a");
    link.href = url;
    link.download = button.dataset.filename || "day-by-word.ics";
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  } catch {
    // Nothing is saved without a connection; the button can be tried again.
  } finally {
    button.disabled = false;
  }
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

  /** The start action the form describes now. */
  const startAction = () => {
    const behavior = behaviorChosen();
    const action = {
      kind: "enroll",
      plan: startForm.dataset.plan,
      behavior,
      start: start?.value || today(),
      readingDays: [...startForm.querySelectorAll('input[name="day"]:checked')].map((day) =>
        Number(day.value),
      ),
    };
    if (behavior === "finish-date") {
      action.finish = startForm.querySelector('input[name="finish"]').value;
      action.limit = Number(startForm.querySelector('input[name="limit"]').value);
    }
    return action;
  };

  // A finish date's load, from the engine on the server, before starting.
  const preview = startForm.querySelector("[data-finish-preview]");
  const useLater = startForm.querySelector("[data-use-later]");
  let later;
  const showPreview = async () => {
    const action = startAction();
    if (action.behavior !== "finish-date" || !action.finish || action.readingDays.length === 0) {
      show(preview, "");
      if (useLater) useLater.hidden = true;
      return;
    }
    try {
      const answer = await post("/api/v1/preview", {
        events: await events(),
        today: today(),
        action,
      });
      show(preview, answer.text ?? "");
      later = answer.later;
      if (useLater) useLater.hidden = !later;
    } catch {
      show(preview, "");
      if (useLater) useLater.hidden = true;
    }
  };
  useLater?.addEventListener("click", () => {
    if (later) startForm.querySelector('input[name="finish"]').value = later;
    showPreview();
  });
  startForm.addEventListener("change", () => {
    showFinish();
    showPreview();
  });

  startForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const problem = startForm.querySelector("[data-start-problem]");
    try {
      await act(startAction());
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
    await transact("readwrite", (pending) => pending.clear(), pendingStore);
    try {
      localStorage.removeItem("dbw.today-ahead");
      sessionStorage.removeItem("dbw.last-action");
    } catch {
      // Nothing kept there.
    }
    show(status, yourData.dataset.deleted);
  });
}
