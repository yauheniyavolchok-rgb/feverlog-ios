# Contributing to FeverLog

Thanks for taking a look at FeverLog. This document covers how to build and
test the project locally, the conventions the codebase follows, and how to
submit a change.

## Building and testing

See the README's [Getting started](README.md#getting-started) section for
the one-time XcodeGen setup. In short:

```bash
brew install xcodegen   # one-time
xcodegen generate
open FeverLog.xcodeproj
```

Every change should pass all three of these before you open a PR — they're
exactly what CI runs (`.github/workflows/ci.yml`):

```bash
# Build + full test suite (unit tests via Swift Testing, UI tests via XCTest)
xcodebuild build -project FeverLog.xcodeproj -scheme FeverLog \
  -destination "platform=iOS Simulator,name=iPhone 16"
xcodebuild test -project FeverLog.xcodeproj -scheme FeverLog \
  -destination "platform=iOS Simulator,name=iPhone 16"

# Lint (see .swiftlint.yml for the exact rule set)
swiftlint lint --strict

# The medication safety engine is a standalone Swift package — test it
# independently too
cd FeverLogEngine && swift test
```

You do not need Supabase credentials to build, run, or test the app —
guest mode works fully offline out of the box. See
[Supabase setup](README.md#supabase-setup-household-sync) if you're working
on the household sync feature specifically.

## Code conventions

These aren't arbitrary style preferences — most of them exist because a
past bug or design discussion led here. When in doubt, match what's already
in the file you're editing.

- **Swift 6 strict concurrency is on project-wide** (`SWIFT_STRICT_CONCURRENCY:
  complete` in `project.yml`). Code must be data-race-safe at compile time,
  not just "probably fine."
- **No force unwraps, force casts, or force tries** — `.swiftlint.yml` makes
  all three build errors, not warnings. If a value is genuinely guaranteed
  non-nil by an invariant the type system can't see, prefer a `guard let ...
  else { return }` / explicit error over `!`.
- **SwiftData is the local source of truth.** UI code reads from SwiftData,
  never from Supabase directly. If you're touching sync code, local writes
  must complete before anything is enqueued for upload — see
  `docs/architecture/offline-first.md`.
- **The medication safety engine (`FeverLogEngine`) stays a pure Swift
  package.** It cannot import SwiftUI, SwiftData, Supabase, or UIKit — that
  boundary is what keeps the dose/safety arithmetic independently testable
  and reusable. If you find yourself wanting to import one of those there,
  the logic probably belongs in the app target instead, with the pure
  calculation staying in the engine.
- **User-facing strings go through `L10n`**, never raw string literals in
  views — add the key to `Localizable.xcstrings` and a typed accessor in
  `L10n.swift` (or one of the `L10n+*.swift` extension files, split out
  purely to stay under SwiftLint's type-body-length limit).
- **Every domain model needing sync conforms to `SyncableRecord`**
  (`id`, `createdAt`, `updatedAt`, `deletedAt`, `lastSyncedAt`,
  `syncVersion`). Records are soft-deleted, never physically removed by
  application code.

### The `TODO(Phase X, topic): ...` convention

SwiftLint's `todo` rule is deliberately disabled in this repo — plain
`// TODO` comments are how open, tracked follow-up work is recorded, not
something to be flagged and removed. When you leave one, follow the
existing format so it's greppable and self-explanatory out of context:

```swift
// TODO(Phase 11, migration plan): Add migration plans when the schema
// changes after the first release.
// Completion: a versioned migration strategy and migration tests exist
// before the first schema-changing release.
// Release blocker: yes for any release that changes the persisted schema
// without migration coverage.
```

`Completion:` states what "done" looks like concretely enough that someone
else could verify it. `Release blocker:` states whether shipping without
resolving it is acceptable, and under what condition.

## Translations

Six of the app's seven languages (Ukrainian, Russian, Dutch, Spanish,
German, Polish) are machine-drafted and marked `needs_review` in
`Localizable.xcstrings` — only English has been reviewed by a fluent
speaker. If you're a native or fluent speaker of any of these, reviewing
and correcting those entries (Xcode's String Catalog editor shows the
`needs_review` state directly) is one of the most useful contributions you
can make without touching Swift at all.

## Commit messages and PRs

- Commit messages should explain *why*, not narrate *what* the diff does —
  the diff already shows what changed.
- Keep PRs scoped to one logical change. A bug fix doesn't need to carry an
  unrelated refactor along with it.
- If your change touches a screen or user-visible flow, mention in the PR
  description how you verified it (simulator run, specific test added,
  etc.) — this project treats "compiles" and "passes tests" as necessary,
  not sufficient, for calling a feature done.

## Reporting issues

Use the bug report / feature request templates when opening an issue —
they ask for the information that's actually needed to act on it (repro
steps, device/OS, expected vs. actual behavior).
