# Releasing the app

How a build of the Day by Word app gets from `main` to TestFlight, and later
to the App Store. The web is deployed separately (`docs/deploy.md`).

## What is needed once

- **Xcode signed in to the owner's Apple Developer account** (D33, BUILD.md
  P0.6): team `D9QMP3LP8H`, an individual membership. Automatic signing
  creates and renews the certificates, identifiers, and profiles; nothing
  signing-related is ever committed.
- **`apple/Config/Secrets.xcconfig`**, gitignored, with
  `DEVELOPMENT_TEAM = D9QMP3LP8H`. Copy `Secrets.example.xcconfig` to make
  it.
- **The App Store Connect record** for bundle ID `com.daybyword.app` (D1):
  name *Day by Word*, primary language English (U.S.), SKU `daybyword`.
- **An app icon** (D19). The owner's requested 2026-11-01 artwork batch is
  registered as `AppIcon` in `apple/App/Resources/Brand.xcassets`, with
  light, dark, and grayscale tinted appearances. The 1024 px originals
  are in `design/images/`; this removes the missing-icon blocker, but does
  not establish that a build has been uploaded or processed.

## Each build

```sh
make check        # the gate, as for every commit
make archive      # a signed Release archive, numbered by commit count
make testflight   # export and upload to App Store Connect
```

`make archive` refuses to run with uncommitted changes, compiles the catalog
in release mode (`make catalog RELEASE=1`, which refuses uncleared sources
once P4.3 lands), regenerates the project, and archives the `DayByWord`
scheme for `generic/platform=iOS` with `-allowProvisioningUpdates`. The build
number (`CURRENT_PROJECT_VERSION`) is `git rev-list --count HEAD`, which only
grows because `main` is never force-pushed. The marketing version
(`MARKETING_VERSION`, in `apple/Config/Base.xcconfig`) changes by hand at
each release.

`make testflight` exports the archive with `apple/Config/ExportOptions.plist`
(method `app-store-connect`, destination `upload`) using the Apple ID Xcode
is signed in with. App Store Connect processes the build and emails the
owner; the build then appears for internal testers in TestFlight.

Logs are in `build/logs/` (`archive.log`, `testflight.log`).

## Before every upload

- The privacy manifest, `apple/App/Resources/PrivacyInfo.xcprivacy`, is
  accurate: no tracking, no collected data while the app is used without an
  account, and a reason for every required-reason API the code uses.
- `ITSAppUsesNonExemptEncryption` is `false` in `apple/App/Info.plist`: the
  app uses only the encryption built into the operating system (HTTPS), which
  is exempt.
- The build is from a commit on `main` that has been pushed.

## Record

Record each TestFlight milestone (first upload, first external build, each
App Store submission) as a dated note under its BUILD.md item.
