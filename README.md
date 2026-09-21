# FeverLog

A home-brewed, local-first iOS app for tracking a child's fever, temperature
history, and medication doses — with a deterministic, offline-capable
medication safety engine and optional household sync. Built for free
distribution in Dr.Baby clinics.

> **Status:** Phases 0-9 complete (project foundation through Supabase auth
> and household sync). See [ROADMAP.md](ROADMAP.md) for the phased
> delivery plan.

## Requirements

- Xcode 16 or later
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting started

This repository does not commit the generated `.xcodeproj` — it's generated
from [`project.yml`](project.yml) via XcodeGen so the project file never
drifts or produces noisy merge conflicts.

```bash
brew install xcodegen   # one-time
xcodegen generate
open FeverLog.xcodeproj
```

Then build and run the `FeverLog` scheme on an iOS Simulator.

Guest mode requires no configuration, no account, and no network access —
everything works fully offline. Supabase credentials are only needed for
optional household synchronization (Phase 9) — see below.

## Supabase setup (household sync)

Household sync is entirely optional. A fresh clone with no Supabase
configuration builds, runs, and works fully offline in guest mode — every
`SUPABASE_URL`/`SUPABASE_ANON_KEY` lookup is nil-checked and every sync
operation no-ops when unconfigured (see `SupabaseConfig.isConfigured`).

### 1. Create a Supabase project

Create a free project at [supabase.com](https://supabase.com). Note its
project URL and anon/public API key (Project Settings → API). The anon key
is safe to embed in the client — every table is protected by Row Level
Security (RLS), not by keeping the key secret.

In Authentication → Providers, enable **Anonymous Sign-Ins** (the app
signs in anonymously on first launch, with no login screen). Enable **Apple**
and/or **Google** and **Email** providers if you want identity linking to
work end-to-end.

### 2. Apply the schema

The schema, RLS policies, and household-lifecycle RPCs live in
[`supabase/migrations`](supabase/migrations). Apply them with the
[Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
brew install supabase/tap/supabase   # one-time
supabase link --project-ref <your-project-ref>
supabase db push
```

Or paste the migration file's contents into the Supabase Dashboard's SQL
Editor and run it once. Either way it's idempotent-safe to re-run (uses
`create or replace function`, `if not exists`-style guards) except for the
initial `create table` statements, which only work once against a clean
database.

The migration also adds every synchronized table to the `supabase_realtime`
publication, which is required for the app's Realtime subscriptions to
receive change events.

### 3. Configure the app

Copy the xcconfig template and fill in your project's values:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Edit `Config/Secrets.xcconfig` — **never commit this file** (already
gitignored). Note the workaround for xcconfig treating `//` as a comment
marker, documented inline in the template.

`xcodegen generate` picks these up via `Config/Base.xcconfig` and injects
them into Info.plist as `SupabaseURL`/`SupabaseAnonKey`, read at runtime by
`SupabaseConfig`.

### Design notes

- **Anonymous-first, no login screen.** Every install gets a real,
  authenticated (anonymous) Supabase user and a personal household on
  first successful connection — see `AuthService` and
  `HouseholdSyncCoordinator`. Linking Apple/Google/Email preserves the same
  `auth.uid()`; there is no "guest → account migration" data move.
- **Local id == remote id** for every entity except a *joined* household,
  where the local device's own household row's `remoteHouseholdID` points
  at the household it joined (see `HouseholdSyncCoordinator.joinHousehold`).
- **Conflict resolution** is last-write-wins by `updated_at` (a
  client-supplied timestamp — see the migration file's header comment for
  the documented clock-skew tradeoff), with a lexicographically-greater-id
  tie-break, enforced both client-side (`ConflictResolver`) and
  server-side (`reject_stale_write` trigger) as defense in depth.
- **RLS** is entirely household-membership-based via two
  `SECURITY DEFINER` helper functions (`is_household_member`,
  `is_child_accessible`) that avoid policy recursion. See the migration
  file for the full policy set and its own inline commentary.
- QR-code invitations are deferred (see the TODO in the migration file);
  the six-character code flow (`create_household_invite` /
  `redeem_household_invite`) is the supported v1 sharing mechanism.

## Running tests

```bash
xcodegen generate
xcodebuild test -project FeverLog.xcodeproj -scheme FeverLog \
  -destination "platform=iOS Simulator,name=iPhone 16"

# Medication safety engine (pure Swift package, independently testable)
cd FeverLogEngine && swift test
```

## Project structure

```
FeverLog/
├── App/            — app entry point
├── Models/         — SwiftData models
├── Views/           
├── Screens/
├── Components/
├── Services/       — repositories, settings storage, sync
├── Theme/          — design tokens, appearance modes
├── Assets.xcassets
├── Resources/
├── Utilities/
├── Extensions/
├── Database/       — bundled reference data (medication library, etc.)
├── Preview/        — SwiftUI preview support / sample data
├── Localization/   — String Catalog + typed L10n keys
└── Widgets/

FeverLogEngine/     — pure Swift package: deterministic dose/safety math.
                       No SwiftUI, SwiftData, Supabase, or UIKit imports.

FeverLogTests/       — unit tests
FeverLogUITests/     — UI tests
docs/                — architecture decisions, design system, case studies
supabase/migrations/ — SQL schema, RLS policies, household-lifecycle RPCs
Config/              — xcconfig files (Base.xcconfig tracked, Secrets.xcconfig gitignored)
```

## Architecture

See [`docs/architecture`](docs/architecture) (populated starting Phase 11)
for the full write-up. The short version:

- **SwiftData is the local source of truth.** All UI reads come from
  SwiftData. Supabase is a sync transport, never a direct UI read source.
- **Local writes complete before sync.** The app never requires network
  access to record data.
- **The medication safety engine is a pure, dependency-free Swift module**
  with deterministic, unit-tested dose and safety calculations. It is not a
  diagnostic tool and does not provide medical advice.
- **Household sync is offline-first.** Every write commits to SwiftData
  first and enqueues a `SyncQueueItem`; a background sync cycle
  (`SyncCoordinator`) uploads pending items with bounded exponential
  backoff, and Realtime events are imported into SwiftData through the
  same deterministic conflict resolver before the UI ever sees them. See
  [Supabase setup](#supabase-setup-household-sync) above for the full
  design notes.

## Performance

`FeverLogUITests/PerformanceTests.swift` measures the two things most
likely to regress silently: cold launch time and Timeline scroll cost
under a realistic data volume.

```bash
xcodebuild test -project FeverLog.xcodeproj -scheme FeverLog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FeverLogUITests/PerformanceTests
```

- **`testColdLaunch`** — `XCTApplicationLaunchMetric()` around a fresh
  launch with an empty store, so the result reflects fixed startup cost
  (SwiftData container setup, initial view construction) rather than data
  volume.
- **`testTimelineScrollWithLargeDataset`** — `XCTCPUMetric()` and
  `XCTMemoryMetric()` around a scroll gesture through a seeded child with
  300 temperature readings (`--uitest-seed-large-dataset`, handled in
  `UITestSupport`, DEBUG-only). An empty Timeline scrolling fast tells you
  nothing about whether the day-grouping or row rendering is efficient —
  this does.

**Reading results:** open the test's `.xcresult` in Xcode (Report
Navigator, or `open <path>.xcresult` from the "Test session results" line
`xcodebuild` prints) and select the test to see the metric charts and raw
per-iteration values.

**Baselines are intentionally not committed.** Xcode's baseline mechanism
(right-click a metric → Set Baseline) records expected values keyed to the
specific Mac/simulator/OS combination it was captured on — a baseline from
one machine will spuriously fail on another. If you want local pass/fail
gating, set your own baseline after establishing what "normal" looks like
on your machine; treat these tests as a way to *observe and compare*
metrics over time (e.g. before/after a change you suspect affects
performance), not as CI gates, unless CI runs on fixed, dedicated
hardware.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
