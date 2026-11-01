# Competitors: what others offer

BUILD.md P2.2. This records what comparable apps offer, so that Day by
Word's answers in the feature map rest on evidence rather than memory. It
describes products factually and does not rank anyone's ministry or work.

**Method and its limits.** Checked on 2026-10-30 from Apple's public search
API (US App Store: ratings, prices, versions, dates) and each app's App
Store page (privacy label, in-app purchases, description, version notes).
Privacy labels are the developers' own declarations, which Apple does not
verify. **No app was used hands-on**: this session had no physical device,
and App Store apps cannot be installed in the iOS Simulator. Onboarding,
missed-day behavior in practice, widgets, and reminder quality therefore
remain to be confirmed on a device (BUILD.md P9.10, formerly P2.2b). Where a feature comes only from
a user review, it says so. Ratings change; re-check before quoting.

## Summary

| App | Seller | Rating (count) | Price | Privacy label | Plans | Missed days | Links out |
|---|---|---|---|---|---|---|---|
| ReadingPlan | James Price | 4.71 (199) | Free, no IAP | Data Not Collected | 5 built in, more to download; custom plans | not described | online Bible sites in a web view, or supported Bible apps |
| Sola – Bible reading plans | Samuel Jusaitis | 4.85 (40) | Free; supporter IAP $0.49–$9.99 | Linked: purchase history (analytics), name, email, user ID; not linked: crash data | custom plans by content, duration, and days; hosted shared plans | "Reschedule Missed Readings" screen | Mere Bible and Literal Word named in version notes |
| Bible (YouVersion) | Life.Church | 4.91 (13,861,744) | Free | Linked: email (marketing), search history, name, user content, user ID; not linked: device ID and product interaction (marketing, analytics) | "thousands", 100+ languages | "Catch Me Up" (Research finding 1; not on the listing) | built-in Bible |
| Read Scripture | Crazy Love Ministries | 4.83 (1,770) | Free | Data Not Collected | one year-long plan with BibleProject videos | mark a day unread; fast-forward by long press (version notes) | built-in text |
| Through the Word | Through the Word Inc. | 4.77 (5,035) | Free | **Used to track you: identifiers**; linked: email, user ID, device ID (analytics, marketing) | 19 "journeys"; group plans | not described | audio guide per chapter |
| One Year Bible Plan + Audio | Saulo Marchi | 4.89 (3,181) | Free; IAP $4.99–$19.99 | Not linked: device ID, product interaction, diagnostics | one one-year plan; streaks | not described | built-in text and audio |
| Yearly – Read the Bible in 1yr | Martyn Chamberlin | 4.66 (357) | Free; Premium $2.99/month or $29.99/year | Data Not Collected | M'Cheyne, OT & NT daily, straight through, ACNA 2019 Daily Office (version notes); streaks | start date can be changed; otherwise not described | YouVersion when installed (user reviews) |
| My Bible Tracker | Stine Johanne Wang Loehren | 4.63 (131) | Free | Data Not Collected | no timed plans: chapter checklists, several trackers, achievements | no schedule to fall behind | none |
| Bible Study App by Olive Tree | Gospel Technologies LLC | 4.84 (324,607) | Free; resources up to $79.99 | Linked: purchases, email, user ID, usage (marketing, analytics, personalization) | "dozens"; progress tracking; daily reminders | not described | built-in Bible |
| Logos Bible | Faithlife Corporation | 4.86 (176,972) | Free | not checked | reading plans inside a full Bible reader | not checked | built-in Bible |
| Blue Letter Bible | Blue Letter Bible | 4.87 (360,863) | Free | not checked | reading plans inside a full Bible reader | not checked | built-in Bible |
| Bible Gateway | HarperCollins Christian Publishing | 3.66 (10,117) | Free | not checked | reading plans inside a full Bible reader | not checked | built-in Bible |

New entrants in September 2026: "Bible Reading Plan: Pace" (Jinwan Kim,
released 2026-09-09) and "Shepherd: Track Bible Reading" (Sanghoon Im,
2026-09-04), each with no ratings yet.

## What this means for Day by Word

- **The nearest product is still ReadingPlan**: a catalog, any start date,
  pace or schedule, links out, and no data collected. It has been on the
  store since 2009-11-04 and was updated on 2026-10-13. Its listing does not
  describe catch-up, widgets, or sync. Day by Word's difference has to be
  real: guidance in choosing (P9), calendar-correct lectionaries (P6), the
  return flow (P5.8, P8.7), paper support (P13), and sync between the app
  and the web (P14).
- **"Data Not Collected" is common among small trackers** (ReadingPlan,
  Read Scripture, Yearly, My Bible Tracker). It is the baseline, not a
  distinction. Day by Word must match it for use without an account (P16.7)
  and stay as plain once accounts exist.
- **Larger apps collect more**: YouVersion, Olive Tree, and Sola link email
  and identifiers to the reader, and Through the Word declares tracking.
  Passkeys without email (D8) and no analytics (D12) remain a real
  difference.
- **Streaks and achievements are widespread** (One Year Bible Plan, Yearly,
  My Bible Tracker), and one reviewer of My Bible Tracker describes losing a
  streak at midnight. D17's opt-in streak against the reader's own rhythm,
  with no loss language, answers a felt problem.
- **Prayer-book readings already appear in a general app**: Yearly lists
  the ACNA 2019 Daily Office in its version notes. Day by Word's 2019 plan
  stays deferred until Anglican House permits it (D14, D38), and its launch
  difference is exact labeling and computed calendars for 1979 and 1662.
- **Paid tiers exist but are small** (Yearly Premium, Sola supporters, One
  Year Bible Plan purchases). D11's free core with voluntary donations is
  consistent with the category.
- **Being a tracker is not enough** (BUILD.md's feature map): two new
  trackers launched in September 2026 alone.

## Still to confirm on a device (P9.10)

Onboarding in each app; how each behaves after missed days (above all
YouVersion's "Catch Me Up", Sola's rescheduling, and ReadingPlan's pace
setting); links out to Bible apps, and whether any app marks a reading done
because a link was opened; widgets; the content and timing of reminders;
and prices inside the apps.

## The feature map

Moved from BUILD.md on 2026-11-01 (D39); phase numbers refer to BUILD.md
and `docs/roadmap.md`.

This map is drawn from App Store data (Apple's public search API, US store)
and the products' own pages, checked 2026-10-30 (Research finding 1), and
from each app's App Store listing (privacy label, purchases, description,
version notes), checked the same day (P2.2a, `docs/research/competitors.md`).
Ratings change, so re-check them before quoting. Rows marked † still rest
partly on general knowledge and are confirmed on a device in P9.10.

| Product | What it offers | Our answer (phase) |
|---|---|---|
| **ReadingPlan** (James Price; 4.7 from 199 ratings; since 2009) | A plan catalog, any start date, follow the schedule or go at your own pace, readings opened in online Bible sites or native Bible apps | The closest match to this concept. Our answer is guidance in choosing, calendar-correct lectionaries, the return flow, paper support, and web and app sync (P5, P6, P8, P9, P13, P14) |
| **YouVersion Bible App** (Life.Church; 4.9 from about 13.9 million ratings) † | A vast catalog that includes partner plans, a built-in Bible, "Catch Me Up" (which resets today to the day after the last completed reading), and plans with friends | Fewer, reviewed plans with workloads and limitations; three catch-up choices, each previewed; YouVersion as the first place to open a reading (P5.8, P8.5, P9, P10) |
| **Sola – Bible reading plans** (Samuel Jusaitis; 4.8 from 40) | Custom plans balanced by word count, editable pace, hosted shared plans, rescheduling of missed readings, links to Bible apps, and supporter in-app purchases. Sign-in is by email, and its privacy label lists name, email, user ID, and purchase history used for analytics | Catalog plans balanced by reading time, no sign-in needed, passkeys when syncing, and "Data Not Collected" for local use (P3.7, P10, P14, P16.7) |
| **Read Scripture** (Crazy Love Ministries; 4.8 from 1,770) | A whole-Bible plan with BibleProject videos; optional accounts sync progress; "Data Not Collected" | The videos stay the publisher's; a partnership inquiry (D38) |
| **Through the Word** (4.8 from 5,035) | Guided audio for every chapter, 19 "journeys", group plans, email sign-in; its privacy label declares tracking by identifiers | Audio services as places to open a reading (P19) |
| **One Year Bible Plan + Audio** (4.9 from 3,181) and **Yearly** (4.7 from 357) | One Year Bible Plan: one year plan with built-in text, audio, and streaks. Yearly: several year plans (M'Cheyne, Old and New Testament daily, straight through, and the ACNA 2019 Daily Office, per its version notes), streaks, and a $2.99 a month premium tier | A real choice of plans, including year plans in canonical, five-day, and balanced forms (P10) |
| **My Bible Tracker** (4.6 from 131) and similar trackers | Chapter checklists, several trackers, achievements, and no timed plans | Assignment states (completed, partial, skipped, unread), with coverage kept apart from completion (P5, P11) |
| **Olive Tree** (4.8 from 324,607), **Blue Letter Bible** (4.9 from 360,863), **Logos** (4.9 from 176,972), **Bible Gateway** (3.7 from 10,117) † | Reading plans inside a full Bible reader (confirmed for Olive Tree: "dozens" of plans, progress, daily reminders) | Destinations, not rivals: we open the passage there after 1.0 (P19) |
| **daybyword.org "DayByWord"** (web) | Its own 2026 plan, short built-in plans, custom plans by start date and chapters a day, a monthly calendar, PDF and Excel export, English and Chinese, and quotations from the Recovery Version | An unrelated site with the same name; the owner keeps the name (D2) |

New entrants in September 2026 ("Bible Reading Plan: Pace", "Shepherd: Track
Bible Reading", "Bible-ReadingPlan") show that the category is active.
Being a tracker rather than a Bible reader is not enough difference on its
own.

#### Where Day by Word aims to be unusually good

This is a product hypothesis, tested after launch through the beta, support
mail, and opt-in surveys (D12, D25), not a claim that competitors lack every
one of these features.

- **Choosing with confidence.** Every plan explains whom it suits, its
  actual workload, and what it covers, and recommendations come with
  reasons (P9).
- **Schedules that know their kind.** Sequential, deadline, and calendar
  plans each behave correctly, liturgical calendars included (P5, P6).
- **Returning as a normal part of reading.** The welcome-back choices are
  previewed and honest, and history is never rewritten (P5.8, P8.7).
- **Paper and digital as equals.** A physical Bible mode, printable weeks,
  widgets, and notification actions mean the app rarely needs opening (P8,
  P12, P13).
- **Trust.** Accurate readings, dependable reminders, clear permissions, a
  source note on every plan, and privacy by default (P4, P8.8, P16).
