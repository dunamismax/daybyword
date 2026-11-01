# Research findings

These are the research findings that shaped BUILD.md, moved here on
2026-11-01 (D39) so that BUILD.md holds only the plan. They keep their
numbers, so "Research finding 5" still resolves. They were checked on
2026-10-30 unless noted; re-verify anything you depend on and record what
you checked.

1. **The category** (Apple's search API, US App Store; product pages).
   [ReadingPlan](https://pricejh.com/readingplan/) (James Price; App Store
   4.7 from 199 ratings, first released 2009-11-04) is the nearest existing
   product: a catalog, flexible start dates and pace, and links into Bible
   websites or native Bible apps. Its page does not mention catch-up,
   widgets, reminders, or sync. [Sola](https://apps.apple.com/us/app/sola-bible-reading-plans/id1487787716)
   (4.8 from 40) offers custom plans balanced by word counts, hosted shared
   plans, "Reschedule Missed Readings", supporter purchases, email sign-in,
   and a privacy label that lists name, email, user ID, and purchase
   history (used for analytics) and crash data; iCloud sync is planned, not
   shipped. The [YouVersion Bible App](https://apps.apple.com/us/app/id282935706)
   (4.9 from 13,860,459) has "Catch Me Up", which moves today's reading to
   the day after the last completed day
   ([The Sweet Setup](https://thesweetsetup.com/use-catch-feature-youversions-reading-plans/)).
   Other entries: Read Scripture (4.8 from 1,770), Through the Word (4.8
   from 5,033), One Year Bible Plan + Audio (4.9 from 3,180), Yearly (4.7
   from 357), My Bible Tracker (4.6 from 131), and three new trackers
   released in September 2026. Full Bible apps with plans include Olive Tree
   (4.8 from 324,587), Blue Letter Bible (4.9 from 360,859), Logos (4.9 from
   176,945), and Bible Gateway (3.7 from 10,118). P2.2 deepens this with
   hands-on use.
2. **Name and domains.** **daybyword.com** was registered on 2026-10-30 at
   09:58 UTC through Cloudflare (it expires 2027-10-30) and uses Cloudflare
   nameservers. It had no A or MX records on 2026-10-30 and did not answer
   HTTPS. **daybyword.org belongs to another party** (registered
   2025-01-05, with different Cloudflare nameservers) and serves
   "DayByWord – Your Bible Reading Plan and Daily Guide": its own 2026
   plan, built-in plans, custom plans, a monthly calendar, PDF and Excel
   export, and English and Chinese editions. It quotes the Recovery
   Version, gives a Gmail address and an X account (@DayByWord), and its
   footer says "2026 DayByWord. All rights reserved." Searches of the US App
   Store for "day by word" and "daybyword" found no app of that name. The
   owner has chosen to keep the name without a trademark search (D2).
3. **The repository.** `dunamismax/daybyword` was created on 2026-10-30 at
   10:14 UTC. It is **public** and was empty. `origin` pushes to both
   GitHub and the Codeberg mirror, `codeberg.org/dunamismax/daybyword`,
   which was created the same day (D32, P0.5).
4. **Bible destinations.** YouVersion's `youversion://bible?reference=JHN.3.16`
   scheme is undocumented and may change
   ([a 2013 write-up](https://ben.prose.sh/2013-12-18-youversion-bible-url-scheme)),
   so prefer bible.com web links, which open the app where it is installed.
   Confirm their format, their translation ids, and their range support on
   a device in P8.5. For after launch (P19): Olive Tree documents
   `olivetree://bible/<book>.<chapter>.<verse>` with numeric book ids
   ([OliveTreeUrlExample](https://github.com/OliveTreeBible/OliveTreeUrlExample));
   Logos uses ref.ly links, which open in Logos where it is installed and on
   the web otherwise ([Logos Links Guide](https://support.logos.com/hc/en-us/articles/46165718176397-Logos-Links-Guide));
   an Accordance `accord://` link reportedly brings the app forward without
   navigating to the passage
   ([forum](https://forums.accordancebible.com/topic/7166-custom-url-scheme/));
   Bible Gateway, ESV.org, and Blue Letter Bible take passages in their web
   URLs, but their formats were not checked here. Destinations differ in
   range support (some open only a chapter), so every adapter must state
   what it can open.
5. **Scripture data.** Book ids follow USFM's three-letter codes, which
   cover the deuterocanonical books. Versification differs between
   traditions (English/KJV, Hebrew, Greek, Latin), and Psalm numbering
   differs between the Hebrew and the Greek and Latin traditions for most
   of Psalms 9–147. [STEPBible-Data](https://github.com/STEPBible/STEPBible-Data)
   publishes TVTMS, a mapping of versification traditions, under CC BY 4.0
   with attribution. Older Tyndale House pages list non-commercial terms,
   so confirm the licence of the exact file used (P3.2). For counting words
   internally (never displayed, D13): the **Berean Standard Bible** was
   dedicated to the public domain on 2023-04-30
   ([berean.bible terms](https://berean.bible/terms.htm)); the **World
   English Bible** is public domain ([eBible.org](https://ebible.org));
   the KJV is public domain in the US but under Crown rights in the UK.
6. **Reading time.** Brysbaert's 2019 meta-analysis (*Journal of Memory and
   Language* 109; 190 studies) puts the adult English silent reading rate
   at about **238 words a minute for non-fiction**, and oral reading at
   about **183**. The KJV runs to roughly 780,000 words (P3.6 recomputes
   this from the cleared counting text), so a whole Bible in a year is
   about 2,150 words a day: roughly 9 minutes read silently, or 12 read
   aloud. These are estimates. Reflection, reading aloud, and listening
   change them substantially, and the app says so.
7. **Prayer books and lectionaries** (from the founding brief's research,
   checked by its author on 2026-10-30, with the sources it cites).
   "1612" in early notes most likely means the **1662** Book of Common
   Prayer; a specific 1612 printing would need separate identification.
   "The new one" is ambiguous: The Episcopal Church uses the **1979** book
   ([TEC](https://www.episcopalchurch.org/who-we-are/how-we-worship/book-of-common-prayer/)),
   the Anglican Church in North America publishes the **2019** book
   ([ACNA](https://bcp2019.anglicanchurch.net/)), and England's Common
   Worship is another family again. Daily Office readings differ from the
   readings appointed for Sundays and Holy Communion: The Episcopal Church
   adopted the Revised Common Lectionary for Sundays in 2007 and kept its
   Daily Office Lectionary ([TEC Lectionary](https://www.episcopalchurch.org/worship-prayer/lectionary/)).
   IVP's 1662 International Edition keeps the original Daily Office table,
   while later English printings may carry the 1871 replacement and the
   1922 alternative tables; its own appendix uses the 1961 revision
   ([IVP FAQ](https://www.ivpress.com/pages/content/book-of-common-prayer-international-edition-free-resources-faq)).
   A generic "1662 plan" could therefore give a reader an unexpected
   schedule, so every edition gets its own exact label. The 1979 Daily
   Office Lectionary runs a two-year cycle, with Year One beginning on the
   First Sunday of Advent before odd-numbered years (BCP 1979 p. 934;
   confirm from the page in P6.4).
8. **Rights** (from the founding brief, with its sources; a research
   assessment, not legal clearance). Episcopal News Service recorded the
   1979 book's release into the public domain
   ([ENS, 1979-11-01](https://digitalarchives.episcopalarchives.org/cgi-bin/ENS/ENSpress_release.pl?pr_number=79331)).
   For the 1662 book, the Church of England identifies Crown rights with
   Cambridge as the Crown's patentee
   ([CofE BCP](https://www.churchofengland.org/prayer-and-worship/worship-texts-and-resources/book-common-prayer);
   [CofE copyright](https://www.churchofengland.org/copyright)), so review
   the exact source, intended use, and territories. Anglican House's
   current policy requires permission for apps, free ones included, and
   approves new apps only for substantially different content
   ([permissions](https://anglicanhousepublishers.org/permissions/)). An
   older copyright page is more permissive
   ([2019 copyright page](https://bcp2019.anglicanchurch.net/wp-content/uploads/2019/08/02-Copyright-Page.pdf)),
   so the 2019 book's status is unresolved. The Consultation on Common Texts
   claims the RCL's table of citations and requires permission outside its
   stated exceptions ([CCT](https://www.commontexts.org/rcl/permissions/)).
   YouVersion cannot authorize republication of partner plans
   ([YouVersion](https://help.youversion.com/l/en/article/o8t2xmy9q2-copyright)).
   **M'Cheyne's** Calendar for Daily Readings is dated by its introductory
   letter of 30 December 1842 (St. Peter's, Dundee). Its chart appears in
   Andrew Bonar's *Memoir and Remains* and in *The Works of the Late Rev.
   Robert Murray M'Cheyne* (New York: Robert Carter, 1848–1850), both
   candidate public-domain printings. Modern reprints' typesetting is not
   ours to take: transcribe from a public-domain printing (P10.8). Under US
   law individual facts are not protected, but a selection and arrangement
   with minimal creativity can be (*Feist v. Rural*, 1991). That is why
   every plan, even one made only of references, gets a permissions record.
9. **Apple platforms.** Apple's App Store data for 2026-06-07 (as
   [MacRumors](https://macrumors.com/2026/06/09/ios-26-adoption-stats-wwdc/)
   reported it) put iOS 26 on 86% of iPhones introduced in the last four
   years and 79% of all iPhones. iOS 27 shipped in September 2026. An app
   may have only 64 pending local notification requests at once (an Apple
   engineer on the [Developer Forums](https://developer.apple.com/forums/thread/811171)),
   so reminders must be scheduled in a rolling window. Interactive widgets
   and App Intents (iOS 17 and later) let "Mark read" run from a widget or
   a notification without opening the app. App Review requires in-app
   account deletion wherever accounts can be created (Guideline 5.1.1(v))
   and a privacy manifest; confirm both against the current guidelines in
   P16.7.
10. **The web.** Web Push works for Home Screen web apps on iOS and iPadOS
    16.4 and later and in Android browsers. This is from general knowledge
    and is confirmed in P15.3, so the installable web app can serve Android
    readers until D6 opens.
11. **Privacy law.** Data revealing religious or philosophical beliefs is
    special-category data under the GDPR and the UK GDPR (Article 9), and
    the usual basis for processing it is explicit consent: freely given,
    specific, opt-in, confirmed in a clear statement, separate from other
    consents, and withdrawable
    ([ICO](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-are-the-conditions-for-processing/)).
    Bible reading plans and tradition preferences can reveal religious
    belief, so any reading data held on the server is treated this way
    (D10). Confirm with counsel before commercial release (P16.3).
12. **Swift on the server and elsewhere** (for D5). [Hummingbird
    2](https://hummingbird.codes/news/hummingbird-2) is a rewrite built on
    structured concurrency (its release candidate was announced on
    2024-09-11). The [Vapor 5 roadmap](https://www.infoq.com/news/2024/09/swift-vapor-5-roadmap)
    plans a new HTTP server based on Hummingbird, and no tagged Vapor 5
    release was found as of 2026-10-30, so Vapor 4 remains Vapor's
    production line. Swift.org announced a nightly preview of the Swift SDK
    for Android in October 2025
    ([Swift.org](https://swift.org/blog/nightly-swift-sdk-for-android/)),
    which could one day run `ReadingEngine` on Android (D6). Confirm current
    versions when building (P1.4).
13. **Local toolchain** (this Mac, 2026-10-30): macOS 27.2 on Apple silicon;
    **Xcode 27.2** (27B52) with **Swift 6.4.2**; XcodeGen 2.46.0 (Homebrew);
    mise 2026.10.18; Ruby 4.0.9 and Node 26.12.1 are installed but not used
    by this project. Simulators include iPhone 17, iPhone 17 Pro Max, iPhone
    17e, iPhone Air, and iPad Pro 13-inch (M5).
14. **The owner's server.** The owner's Ubuntu server (`ubuntu-vm`, reached
    over Tailscale) already serves several sites behind a shared Caddy.
    Prayerbook Atlas's public `docs/deploy.md` records its conventions:
    `/srv/www/<domain>` with releases, a shared `storage/`, and an
    environment file; a system user per site; services under systemd; a
    shared deploy lock (`/usr/local/sbin/with-deploy-lock`); ports
    4311–4315 already taken; site files in `/etc/caddy/sites/`; and nightly
    backups carried off the server by the `ubuntu-vm-backup` repository.
    prayerbookatlas.com resolved to 71.215.196.157 on 2026-10-30. Day by
    Word fits beside them by those conventions, and its own scripts are
    written fresh (D22).
