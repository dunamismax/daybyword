# Privacy policy: draft

*Draft for the owner's approval (BUILD.md P16.3, with P16.4's statement of
cookies and browser storage). Not published. Once approved, it becomes
daybyword.com/privacy, linked from every page's footer, Support, and
Settings in the app and on the web; its date is the day it is published.
Every statement below was checked against the code and the server on
2026-11-22; the questions for the owner are at the end.*

---

**Effective:** the date of publication

## The short version

Day by Word keeps your reading record on your phone or in your browser,
not on our server. There are no accounts, analytics, advertising, or
tracking, and nothing about you is sold or shared.

## Who runs Day by Word

Day by Word is an independent Bible reading companion, not affiliated with
any church or denomination. You can write to support@daybyword.com.

## What stays with you

**In the app.** The plans you start, what you mark, your reminders, and
your settings are stored on your iPhone or iPad. The app's widgets and its
Siri and Shortcuts actions read the same record on the device. Reminders
are scheduled by iOS on the device. The record is part of your device's own
backups (iCloud or a computer) if you make them. The app itself makes no
network requests: it opens a link only when you ask it to (for example
"Open in YouVersion", "Help and support", or a plan's link you share).

**On the web.** The plans you start and what you mark are stored in your
browser (its IndexedDB), and your settings in its local storage. They stay
in that browser on that device. The list of each item is under "Cookies and
browser storage" below.

**Export and deletion.** Settings can export your reading record as a file,
and can delete your plans and reading record from the device or the
browser. Removing the app, or clearing the site's data in your browser,
removes everything, settings included. Nothing is kept anywhere else, so
nothing else needs deleting.

## What reaches daybyword.com, and what it keeps

- **Pages.** Your browser asks daybyword.com for pages and the site's own
  files, as with any website. Nothing on a page is loaded from another
  site.
- **Working out Today and Progress.** To show Today and Progress, and to
  record a new mark, your browser sends your reading record (the plans you
  started and what you marked, with their dates), with the settings that
  shape the page (book names, the way you read, your translation, and
  whether to show reading days in a row), to daybyword.com. The server
  works out the answer in memory and keeps nothing: none of it is written
  to a database, a file, or a log.
- **The server's log.** For each request the server notes the method (such
  as GET), the sort of page it was for (such as "a plan's page", never
  which plan), the answer's status, and how long it took. It does not note
  your IP address, the address you opened, its query, what you sent, or any
  cookie. The log is kept in the server's system journal for at most 30
  days. The web server in front of the site writes no access log.
- **The database** holds only the public plan catalog.
- **Backups** of the server contain the database, and so only the catalog.

## Email

Mail to support@daybyword.com is forwarded by Cloudflare Email Routing to
the inbox of the person who runs Day by Word. It is used only to answer
you and to put right what you report. Anything from a message that is
needed in Day by Word's public repository (for example, a reading error)
is anonymized first. *[Owner: name the inbox's provider, and how long mail
is kept.]*

## Services you choose to open

- **YouVersion and Bible.com.** "Open in YouVersion" opens Bible.com, or the
  YouVersion app if you have it, at the passage. That service receives the
  request under its own privacy policy. Day by Word sends it nothing else.
- **Calendars, sharing, and printing.** A calendar file, a shared plan
  link, an exported record, or a printed week goes only where you send it.
- **Apple.** The App Store and TestFlight deliver the app. If you have
  agreed to share them with developers, Apple provides crash reports and
  aggregate figures about the app; Day by Word adds no analytics of its own.
- **DNS.** Cloudflare answers DNS queries for daybyword.com. It does not
  carry your connection, which goes straight to Day by Word's server.

## Cookies and browser storage

Day by Word sets **no cookies**. On the web it uses the browser storage
below, all first-party (set and read only by daybyword.com), and each is
needed for something you use. None is used for analytics or advertising.

| Where | Name | What it holds | Why |
|---|---|---|---|
| IndexedDB | `day-by-word`, store `events` | Your reading record: the plans you started and what you marked, with dates | Your record lives in your browser, not on a server |
| IndexedDB | `day-by-word`, store `pending` | Marks made without a connection | Sent when you are back online (offline use) |
| Local storage | `dbw.appearance` | Light, dark, or automatic | Your appearance setting |
| Local storage | `dbw.reference-size` | The size of references | Your text size setting |
| Local storage | `dbw.way-to-read` | A paper Bible, YouVersion and Bible.com, or another app | Your way to read |
| Local storage | `dbw.translation` | The translation YouVersion and Bible.com open | Your translation setting |
| Local storage | `dbw.book-names` | The book-name convention | Your book names setting |
| Local storage | `dbw.streak` | Whether to show reading days in a row | Your Progress setting |
| Local storage | `dbw.today-ahead` | Today's cards for the next seven days (plan names and references) | Today opens without a connection |
| Session storage | `dbw.last-action` | The id of the last thing you did in this tab | Today can offer Undo; gone when the tab closes |
| Cache storage | `day-by-word-` and the release | The site's own files and public pages | Pages open offline; replaced with each release, and holds no reading record |
| Service worker | `/service-worker.js` | — | Keeps the cache above and sends offline marks |

Clearing the site's data in your browser removes all of it, as does
**Delete everything in this browser** in Settings (which removes the
record, the offline marks, Today's kept cards, and Undo's note).

## Children

Day by Word collects no personal information from anyone, children
included.

## Changes

If this policy changes, this page shows the new version and its date.

---

## Questions for the owner before publishing

1. The inbox provider support mail is forwarded to, and how long mail is
   kept.
2. Whether to name the operator (your name, as the App Store's seller under
   D33) or say "the person who runs Day by Word", as drafted.
3. Any jurisdiction-specific wording you want (for example a contact for
   data-protection requests). The draft makes no legal claims beyond what
   the code and the server do.
