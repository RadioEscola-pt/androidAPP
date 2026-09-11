# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

Two Android projects live here, and only one is under development:

- `/` — the **legacy native Android app** (Java/Gradle, `app/`). Frozen; kept for its signing
  key and release history. Its `app/build.gradle` reads `versionCode 109` / `1.0.9`, but **the
  live Play listing is at versionCode 111** — two releases were published without the bump
  landing here, so this tree is not the record of what is on Play. Trust the Play Console.
- `flutter_app/` — the **Flutter rewrite** that replaces it. All work happens here.

## Commands

Run everything from `flutter_app/`:

```bash
flutter test                                        # full suite (105 tests)
flutter test test/services/spaced_repetition_test.dart   # one file
flutter test --plain-name "session size is empty for an empty bank"  # one test
flutter analyze                                     # lints; expected to be clean
flutter run                                         # device/emulator
flutter build apk --debug
```

Verify an app-identity change against the built artifact, not the Gradle file — a stale
`namespace` or leftover Kotlin package path fails quietly:

```bash
aapt2 dump packagename build/app/outputs/flutter-apk/app-debug.apk
```

## Architecture

This app is a **port of the `hamradiostudy` website**, not an independent product. That single
fact explains most of the design, and breaking it is the main risk in any change here.

**Content is generated, never authored.** `assets/content/` (1036 questions) and
`assets/images/cat{n}/` are build output of `bun run content:build --mobile=<this dir>`, run
from the hamradiostudy repo; `content:check --mobile=<dir>` verifies the bundle is current
without writing. Hand-editing them makes that check fail. To change a question, change the
website's `content/questions/` and regenerate.

The emitter is `lib/content/mobile.ts` there, and it exists because the app cannot fetch at
runtime what the site fetches per request: explanations are compiled from
`content/notes/cat{n}/{id}.mdx` and inlined as `explanationHtml`, images are copied into the
bundle with their paths rewritten, and relative links are made absolute. It renames `materia`
to `topic` and turns `unavailable: true` into an omitted `url`, because those are the app's
names — `lib/models/question.dart` is the other half of that contract and nothing fails loudly
when the two disagree.

A category is written whole or not at all: a note that will not compile, or an image missing
from `public/`, skips the whole category and fails the build. This matters because
`explanationHtml` defaults to `''`, so a partial write produces questions that look fine and
have quietly lost their explanation.

`exam_config.json` carries the exam rules (duration, pass mark, wrong-answer penalty) so they
are read rather than redeclared here.

**Progress is a shared document.** `lib/models/progress.dart` mirrors `lib/types/progress.ts`
on the website, stored under the same key (`hamradio_progress`) in the same JSON shape, so a
document written on either surface reads cleanly on the other. Two invariants keep that true:

- **Unknown fields survive round trips.** Anything this app does not model (the site's
  gamification, whatever it adds next) is retained as raw JSON and written back untouched.
- `progressVersion` is bumped **in lockstep** with the website's `PROGRESS_VERSION`.

**Two algorithms are behaviour-identical ports**, and are covered by golden fixtures generated
from the TypeScript (`test/fixtures/{sm2,selector}_reference.json`):

- `services/spaced_repetition.dart` ← `lib/spaced-repetition/sm2.ts` (SM-2 scheduling)
- `services/question_selector.dart` ← `lib/spaced-repetition/question-selector.ts`
  (priority tiers: due now → new → due soon → weak → later)

If a change makes those fixtures fail, the port has drifted from the website — fix the port,
don't re-record the fixture, unless the website's own algorithm changed.

**State flow** is Riverpod + go_router. `ProgressNotifier` (`providers/progress_providers.dart`)
is the only writer; every mutation is a **read-modify-write against the store**, not against an
in-memory snapshot, because two writes racing on a stale copy silently drop one. Storage returns
what it wrote and that becomes the new state, so screen and disk cannot disagree.
`providers/question_providers.dart` owns the `Category` enum whose `id` (`"1"`, `"2"`, `"3"`)
builds the `cat{n}_{id}` progress keys shared with the site.

Routes: `/`, `/dashboard`, `/bookmarks`, and `/study/:category`, `/review/:category`,
`/exam/:category`.

## App identity and signing

The Flutter app ships as an **update to the existing Play listing**, not a new app.

**Application ID — `com.andradator.escoladeradioamador`.** Set in
`flutter_app/android/app/build.gradle.kts` (`namespace` and `applicationId`) and matched across
`ios/`, `macos/`, `linux/`, `windows/`. Identical to the legacy `app/build.gradle` on purpose.
Changing it orphans the listing and every install.

**Release signing — `key.jks` at the repo root.** Play only accepts updates signed with the key
that signed the published build. `key.jks` is that key — it signed `app/release/app-release.aab`:

```
SHA256: 28:FE:54:77:CF:26:43:00:93:21:33:16:5A:23:D9:8C:0E:92:B2:D7:93:04:66:52:30:42:64:5A:D0:BE:2A:C1
```

Check a build matches with
`unzip -p <build>.aab 'META-INF/*.RSA' | keytool -printcert | grep SHA256`.

`key.jks` is gitignored (with `*.keystore` and `key.properties`) and has never been committed.
There is no backup: losing it means never updating the published app again.

> **One thing still blocks a publishable release.** `build.gradle.kts` signs release with the
> debug key (the `TODO` in `buildTypes.release`). Wiring it up means a gitignored
> `key.properties` holding the passwords and `storeFile=../../key.jks`, read by the Gradle
> config.
>
> Versioning is handled: `pubspec.yaml` is at `version: 2.0.0+112` — a major bump because the
> Flutter app replaces the native one wholesale, and versionCode **112** clears the published
> **111**. Re-check the Play Console before each build rather than trusting `app/build.gradle`;
> this repo has already fallen behind the listing once.

## Gotchas

- `pubspec.yaml`'s `name: radio_escola` is the **Dart package name**, unrelated to the application
  ID. It is deliberately not `radioescola`: that spelling is the website URL and appears ~1,500
  times in `assets/content/*.json`, so an underscore-free package name would collide with content
  in every grep. Only `test/` imports it (`package:radio_escola/...`) — `lib/` uses relative
  imports throughout — so renaming it again is ~15 lines, not a refactor.
- The **desktop product names are a separate thing** and still read `escola_radio_amador`: the
  Linux/Windows binary and window title, `macos/Runner/Configs/AppInfo.xcconfig`'s `PRODUCT_NAME`,
  and `windows/runner/Runner.rc`. Those are user-visible on desktop; the Dart package name is not.
  Changing one does not change the other.
- `radioescola.pt` throughout `assets/content/*.json` and `lib/` is the **website URL** — content,
  not an identifier. Never sweep it into an app-ID rename.
- The Kotlin source path must track the package:
  `android/app/src/main/kotlin/com/andradator/escoladeradioamador/MainActivity.kt`.
- UI strings are **Portuguese** (`'Outra vez'`, `'Difícil'`, `'Bom'`, `'Fácil'`). Match that.
