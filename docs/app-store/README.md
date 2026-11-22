# The App Store package

Everything App Store Connect asks for version 1.0 of Day by Word (BUILD.md
P16.7), in the words to paste, with the reasons for each answer. The US
storefront comes first (D16). Keep it true to the shipped app: when a
feature changes, change this file in the same commit.

What is still open is listed at the end.

## The listing

| Field | Value | Limit |
|---|---|---|
| Name | Day by Word | 30 |
| Subtitle | Your Bible reading companion | 30 (28 used) |
| Primary category | Reference | |
| Secondary category | Lifestyle | |
| Price | Free; no in-app purchases (D11) | |
| Support URL | https://daybyword.com/support | |
| Marketing URL | https://daybyword.com | |
| Privacy Policy URL | https://daybyword.com/privacy (once P16.3 is approved and published) | |
| Copyright | 2026, the owner's name as the App Store shows the seller (D33) | |
| Sign-in required | No | |

**Promotional text** (170 characters, can change without a new version):

> Find your plan. Read your Bible. Keep your place. Choose a reading plan,
> see today's reading at a glance, and keep a quiet record of what you've
> read.

**Keywords** (100 characters; words already in the name and subtitle are
left out, since the App Store reads those too):

> plan,scripture,daily,year,gospels,psalms,proverbs,new testament,checklist,paper,print,offline

**Description** (4,000 characters):

> Day by Word helps you choose a Bible reading plan, know what to read
> today, and keep a record of your reading, while you read in your own
> Bible: on paper, in an app, or as audio. Day by Word shows references,
> never the text.
>
> CHOOSE WITH CONFIDENCE
> Answer a few practical questions (what you hope to read, how long a
> reading can take, how many days a week) and see a few plans that fit,
> each with its reasons, a sample week, and an honest workload. Every plan
> says what it covers, how long its readings take, and what it does not do.
>
> EIGHT PLANS TO BEGIN WITH
> Gospels at your pace, the Story of Scripture, Paul's letters, A psalm a
> day, Proverbs through the month, the New Testament in a year (five days a
> week), and the Bible in a year (every day, or five days a week). Every
> reference in every plan is checked, and coverage is computed, never
> written by hand.
>
> TODAY, AT A GLANCE
> Today shows the next reading in each of your plans, large enough to read
> from across a desk. Open it in YouVersion or Bible.com, copy the
> reference, or mark it read. Undo is always one more tap away.
>
> COMING BACK IS NORMAL
> Missed a few days? You're welcomed back and choose how to go on: carry on
> from the next reading, spread what's left, or move your finish date. You
> see what each choice does before anything changes.
>
> YOUR BIBLE, ON PAPER TOO
> Physical Bible mode says where each reading is in print. Share a week as a
> checklist to print, in large print if you like, or add the next four
> weeks to your calendar.
>
> QUIET AND PRIVATE
> No account, no ads, no tracking. Your plans and record stay on your
> device, and you can export or delete them at any time. Reminders come only
> when you ask for them, and a missed day is simply a day.
>
> ON YOUR HOME SCREEN AND WITH SIRI
> Widgets show today's reading and mark it read. Ask Siri what your reading
> is today, or mark it read from Shortcuts.
>
> Day by Word is independent and not affiliated with any church or
> denomination.

## App privacy

**The privacy label: Data Not Collected.** The app makes no network
requests of its own (it opens Bible.com, YouVersion and daybyword.com in
other apps only when the reader asks), so nothing the reader does leaves
the device through Day by Word. **Tracking: No.** Check this answer against
Apple's current App Privacy Details guidance before each submission, and
change it in the same commit as any code that sends data anywhere.

**The privacy manifests** (`apple/App/Resources/PrivacyInfo.xcprivacy`,
`apple/Widgets/PrivacyInfo.xcprivacy`) declare no tracking, no tracking
domains and no collected data. The one required-reason API in the code is
UserDefaults: the reader's settings, read only by the app (CA92.1), and the
App Group shared with its own widget (1C8F.1). A search of the app, the
widget and the Swift packages on 2026-11-22 found no other required-reason
API (file timestamps, system boot time, disk space, active keyboards).

## Age rating

Every question in the age-rating questionnaire is answered **None** or
**No**: the app has no violence, sexual content, profanity, drugs,
gambling, horror, or medical information, no user-generated content, no
messaging, no unrestricted web access (links open in Safari or another app,
not inside Day by Word), and no in-app purchases. The expected rating is
the lowest the App Store offers (4+).

## Export compliance

`ITSAppUsesNonExemptEncryption` is `false` in `apple/App/Info.plist`: the
app makes no network connections and uses no encryption of its own, so App
Store Connect asks no export questions (docs/release.md).

## Content rights

The app contains no third-party content: its plans are Day by Word's own
(catalog/SOURCES.md, `daybyword-original`), and it shows references, never
Bible text (D13). It links to Bible.com and YouVersion without showing
their content. Answer **No** to "Does your app contain, show, or access
third-party content?".

## Notes for App Review

> Day by Word needs no account and no sign-in. To try it: open Plans,
> choose any plan (for example "Gospels at your pace"), tap Start this
> plan, then Start. Today then shows the first reading, with Mark read,
> Copy reference and (if you choose YouVersion under Settings › How you
> read) Open in YouVersion. Undo appears after a mark.
>
> By design Day by Word never shows Bible text: readers read in their own
> Bible, on paper or in another app, and confirm what they read. The
> widgets and the Siri and Shortcuts actions
> ("What's my reading today in Day by Word?") use the same plan. Reminders
> ask for notification permission only when the reader turns one on in
> Settings.
>
> The app collects no data and makes no network requests of its own. There
> are no in-app purchases. Support: https://daybyword.com/support.

## Screenshots

App Store Connect needs the 6.9-inch iPhone and the 13-inch iPad sizes.
They are to be made by a UI test in light and dark, with a plan started so
Today, a plan's page, Progress and a week show real readings, never empty
states (P16.7, still open).

## Still open

- **Screenshots**: the UI test that makes them (above).
- **The privacy policy URL**: daybyword.com/privacy exists once the owner
  approves `docs/legal/privacy.md` (P16.3).
- **The copyright line** and the seller's name are the owner's, entered in
  App Store Connect.
