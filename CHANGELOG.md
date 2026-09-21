# Changelog

All notable changes to this project are documented here, grouped by the
phase they shipped in — see [ROADMAP.md](ROADMAP.md) for the full
per-phase writeup this summarizes. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project
hasn't cut dated releases yet, so entries are grouped by development phase
rather than by version/date.

## [Unreleased] — Phase 11: Release Hardening, Docs, Open-Source Repo Setup

### Added
- `CONTRIBUTING.md`, this changelog, and `docs/architecture/README.md`.
- A versioned SwiftData migration plan (`ModelContainerFactory.SchemaV1`/
  `MigrationPlan`), closing a standing `TODO` since Phase 2.
- `PrivacyInfo.xcprivacy` manifest, declaring the app's one required-reason
  API use (`UserDefaults`) and zero data collection/tracking.
- GitHub issue and pull request templates.

### Changed
- Fever-spike insights are disabled pending real pediatric-guideline-based
  thresholds from a recognized authority — the underlying calculation
  (`ChildFeverInsightsProvider`) remains in the codebase and tested, but is
  no longer surfaced in `ChildProfileScreen`. See ROADMAP.md's Phase 7
  entry.

### Verified
- CI workflow's Xcode/simulator version pins investigated against GitHub's
  current `macos-15` runner image manifest — still valid, and a deliberate
  choice (minimum Xcode with Swift 6 support), not staleness. No change
  made.
- Debug-only code (`UITestSupport` and everything behind `#if DEBUG`) is
  completely absent from Release builds, confirmed via symbol-table
  inspection of a real Release build.

## Phase 10 — Settings, Accessibility, Localization, Widgets, Performance

### Added
- Settings screens: Household (rename, member list), Children
  (add/edit/soft-delete), Medication Library (searchable reference
  browser), Units (default weight unit), About, Privacy.
- In-app language switching (English, Ukrainian, Russian, Dutch, Spanish,
  German, Polish), device-local and independent of household sync.
- A performance measurement harness (`PerformanceTests.swift`): cold
  launch time and Timeline scroll cost under a seeded 300-entry dataset.
- `ROADMAP.md`, populated with the full phased delivery plan.

### Fixed
- `Typography`'s fonts did not scale with Dynamic Type despite a doc
  comment claiming they did; replaced with a `UIFontMetrics`-based scaling
  helper.
- Form validation errors were silent to VoiceOver; added
  `.announcesAccessibilityErrors(_:)`.

### Deferred
- **Widgets** — explicitly out of scope for this phase. No WidgetKit
  extension, App Group, or timeline provider exists. See ROADMAP.md for
  what a future implementation would require.

## Phase 9 — Supabase Auth and Household Sync

### Added
- Anonymous auth by default on first launch, with identity linking
  (Apple/Google/Email) preserving the same user and household — no
  account-upgrade data migration.
- Automatic personal household creation, RLS policies derived uniformly
  through `auth.uid() → household_members → household → child`.
- Offline-first sync engine: local write → `SyncQueueItem` → bounded
  exponential backoff upload, Realtime-driven download, deterministic
  last-write-wins conflict resolution.
- Household sharing via a 6-character invite code (permanent accounts
  only).

## Phase 8 — Charts and Local Notifications

### Added
- Temperature, medication timeline, and symptom frequency charts
  (Swift Charts), each with per-mark VoiceOver accessibility labels and a
  selectable time range.
- Landscape orientation support, scoped to the Charts screen only.
- Local notification reminders (medication/temperature/hydration/custom),
  device-local.

## Phase 7 — Symptoms, Notes, Deterministic Insights

### Added
- Structured symptom entries (fixed category set) and free-text notes.
- Deterministic, non-diagnostic fever-history insights
  (`ChildFeverInsightsProvider`) — later disabled in Phase 11, see above.

## Phase 6 — Medication Logging and Safety UX

### Added
- Medication search over the bundled reference database, live dose
  calculation as the parent enters a volume, and a required confirmation
  step before saving a dose the safety engine flags as unusual or over a
  configured maximum.

## Phase 5 — Medication Library and Deterministic Safety Engine

### Added
- `FeverLogEngine`: a standalone, dependency-free Swift package for dose
  and safety arithmetic (`Decimal`-based, never `Double`), with a bundled,
  versioned medication reference database and an eight-state typed safety
  status (never a bare pass/fail boolean).

## Phase 4 — Temperature Logging and Timeline

### Added
- Temperature entry (value, unit, measurement method, timestamp, note)
  with a presentation-only status classifier, always paired with a text
  label alongside color.
- Timeline: all record types grouped by local calendar day, with
  swipe-to-edit/duplicate/delete.

## Phase 3 — Onboarding, Guest Mode, Child Profiles

### Added
- Three-page skippable onboarding; no account or network access required
  to start using the app.
- Automatic local guest household on first launch.
- Child profile creation (name, birthday, avatar, optional weight).

## Phase 2 — Local Data Model, Persistence, Sync Metadata

### Added
- Core SwiftData models (`Household`, `Child`, `TemperatureLog`,
  `MedicationLog`, `SymptomEntry`, `NoteEntry`, `WeightHistory`,
  `Reminder`, `SyncQueueItem`) and the `SyncableRecord` shape every
  syncable model conforms to, designed up front so Phase 9's sync engine
  could be added later without reshaping the models.

## Phase 1 — Design System and App Shell

### Added
- Semantic design tokens (`ColorPalette`, `Typography`, `Spacing`,
  corner-radius/shadow tokens) and four appearance modes, including a
  low-contrast "Calm Night" mode.
- Four-tab app shell (Home, Timeline, Charts, Settings), each with
  independent navigation state.

## Phase 0 — Project Foundation

### Added
- XcodeGen-generated project (no committed `.xcodeproj`), Swift 6 with
  strict concurrency project-wide, and the `FeverLogEngine` local package
  boundary.
