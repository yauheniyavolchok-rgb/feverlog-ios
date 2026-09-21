# Roadmap

FeverLog was built in 11 phases, each shipped as its own commit(s), tested
and linted before moving on. This document is the source of truth for what
exists, what's deliberately deferred, and what's still ahead — the README
points here for the phased delivery plan.

**Status at a glance:** Phases 0–9 complete. Phase 10 is wrapping up (one
feature — widgets — is explicitly deferred, documented below). Phase 11
has not started.

---

## Phase 0 — Project Foundation

**Status: complete.**

The project is generated from [`project.yml`](project.yml) via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) rather than committing a
`.xcodeproj` directly — the project file never drifts out of sync with the
source tree and never produces noisy merge conflicts. Three targets:
`FeverLog` (the app), `FeverLogTests` (unit tests, Swift Testing),
`FeverLogUITests` (UI tests, XCTest). Swift 6 with
`SWIFT_STRICT_CONCURRENCY: complete` from day one — every data race the
compiler can catch, it does.

`FeverLogEngine` is a separate local Swift package
([`FeverLogEngine/`](FeverLogEngine)) for the medication dose/safety math.
It cannot import SwiftUI, SwiftData, Supabase, or UIKit — enforced by
convention and by the fact that the package simply has no access to those
frameworks. This keeps the safety-critical arithmetic testable in
isolation and reusable if the app ever needs a second front end.

---

## Phase 1 — Design System and App Shell

**Status: complete.**

A small set of semantic design tokens in [`FeverLog/Theme/`](FeverLog/Theme),
consumed everywhere instead of raw `Color`/`Font` literals:

- `ColorPalette` — a `Sendable` struct of named colors (background, surface,
  text, accents, status colors for success/warning/danger, five temperature
  status colors, chart colors), resolved per appearance mode.
- `Typography` — semantic font tokens (`largeTemperature`, `screenTitle`,
  `sectionTitle`, `body`, `caption`), all Dynamic-Type-scalable (see the
  Phase 10 accessibility audit below for why that needed a fix).
- `Spacing`, `CornerRadiusToken`, `ShadowToken` — layout tokens.
- `AppearanceMode` (System/Light/Dark/Calm Night) via `ThemeManager`, an
  `@Observable` device-local preference. "Calm Night" is a custom
  low-contrast dark palette meant for checking a sick kid's temperature at
  3am without a full-brightness white screen.

The app shell is a four-tab `TabView` (Home, Timeline, Charts, Settings),
each tab its own `NavigationStack` with independent push state, coordinated
by `AppRouter` (`FeverLog/Views/AppRouter.swift`).

---

## Phase 2 — Local Data Model, Persistence, Sync Metadata

**Status: complete.**

SwiftData is the local source of truth for the entire app — every screen
reads from it directly; nothing reads from Supabase. The core models live
in [`FeverLog/Models/`](FeverLog/Models): `Household`, `HouseholdMember`,
`Child`, `TemperatureLog`, `MedicationLog`, `SymptomEntry`, `NoteEntry`,
`WeightHistory`, `Reminder`, `SyncQueueItem`.

Every syncable model conforms to `SyncableRecord`
(`FeverLog/Models/SyncableRecord.swift`): a stable `id: UUID`, `createdAt`,
`updatedAt` (must change on every mutation, soft-deletes included),
`deletedAt` (soft-delete tombstone — v1 never physically deletes a
record), `lastSyncedAt`, and `syncVersion`. This shape was designed in
Phase 2 specifically so Phase 9's sync engine could be added later without
touching the models again.

`ModelContainerFactory` (`FeverLog/Database/`) provides separate
production and in-memory container constructors, the latter used
throughout the unit test suite so tests never touch real device storage.

---

## Phase 3 — Onboarding, Guest Mode, Child Profiles

**Status: complete.**

Three-page onboarding (`FeverLog/Screens/Onboarding/`) — welcome, family
sharing, medication-safety disclaimer — skippable, completion tracked by
`OnboardingStateStore`. No account, no login, no network call required to
start using the app.

Every fresh install gets a local "guest household" automatically
(`HouseholdRepository.createGuestHouseholdIfNeeded()`), which becomes the
real synced household transparently in Phase 9 once/if the user links an
identity — no data migration step, because the household record never
changes identity, only its sync status.

Child profiles (`FeverLog/Screens/Children/ChildFormScreen.swift` and
`ChildProfileScreen.swift`): name, birthday, a picker of SF Symbol avatars
(`ChildAvatarOption`) × accent colors (`ChildAvatarColorOption`), optional
weight at creation. `ChildStore` (`@Observable`) holds the household and
child list in memory as the single shared reflection of SwiftData that
Home/Timeline/Charts/Settings all read from.

---

## Phase 4 — Temperature Logging and Timeline

**Status: complete.**

Temperature entry (`TemperatureEntryScreen`) records a value, unit,
measurement method (oral/rectal/axillary/ear/forehead/other), timestamp,
and optional note. `TemperatureClassifier` (`FeverLog/Theme/`) buckets a
Celsius reading into a presentation-only status — normal / elevated /
high / very high / critical — using integer tenths-of-a-degree comparison
to avoid floating-point boundary bugs. This classification is explicitly
**never** reused as a medication safety threshold; that logic lives
entirely and independently in `FeverLogEngine`.

Status is always shown as color **and** a text label together
(`TemperatureHeroCard`, `TemperatureLogRow`) — never color alone, so it
reads correctly for colorblind users and in VoiceOver.

The Timeline (`TimelineScreen`) groups all record types — temperature,
medication, symptoms, notes — by local calendar day, newest first, with
swipe-to-edit/duplicate/delete (`TimelineSwipeActions.swift`). Day
grouping is calendar-aware (uses the given `Calendar`'s time zone, not
UTC) and has direct unit test coverage for the local-midnight boundary
case.

---

## Phase 5 — Medication Library and Deterministic Safety Engine

**Status: complete.**

The medication reference database
(`FeverLogEngine/Sources/FeverLogEngine/Resources/medications.json`,
browsable in-app via Settings → Medication Library, added in Phase 10) is
versioned, per-entry `sourceIdentifier`/`sourceVersion`/`reviewStatus`
data — brand, active ingredient, concentration, form, strength, and
optional single-dose and daily-maximum rules. Any rule field left `nil`
means that limit is genuinely not configured; the engine is built to
never invent a value for a missing limit.

`DoseCalculator` does all arithmetic in `Decimal`, not `Double`, so
safety-boundary comparisons never shift from binary floating-point
rounding. `MedicationSafetyEngine` evaluates a proposed dose against the
matched rule and the rolling 24-hour dosing history
(`RollingWindow`/`DoseAdministration`) and returns one of eight typed
statuses (`normal`, `missingWeight`, `missingRule`, `intervalWarning`,
`approachingMaximum`, `unusualDose`, `maximumExceeded`, `invalidInput`) —
never a bare boolean, and never localized text; the app layer maps status
+ typed explanation codes to copy. `ActiveIngredientNormalizer` collapses
known cross-locale synonyms (acetaminophen/paracetamol) to one grouping
key for the rolling-window calculation, conservatively — unknown names are
left distinct rather than guessed at.

This is explicitly **not a diagnostic tool** and does not provide medical
advice — that disclaimer is shown in onboarding, in the medication entry
flow, and in Settings → About.

---

## Phase 6 — Medication Logging and Safety UX

**Status: complete.**

`MedicationSearchScreen` (brand/ingredient search over the bundled
database) → `MedicationDoseEntryScreen`, which live-calculates mg and
mg/kg as the parent types a volume, shows the safety engine's status
inline, and requires an explicit confirmation step
(`medicationEntry.confirm.*`) before saving a dose that the engine flags
as unusual or over a maximum — the app never silently blocks a parent
from logging what actually happened, it makes them confirm they mean it.

---

## Phase 7 — Symptoms, Notes, Deterministic Insights

**Status: complete.**

Symptom entries (`SymptomEntryScreen`) use a fixed category set
(`SymptomCategory`: breathing, digestive, pain, behavior, hydration,
sleep, skin, general) rather than free text, so charts and future
analysis have something structured to group on. Free-text notes
(`NoteEntryScreen`) exist alongside for anything that doesn't fit a
category.

`ChildFeverInsightsProvider` computes a small, deterministic,
**non-diagnostic** summary of recent temperature history — spike count,
total fever duration, longest fever-free interval, temperature change
over 4 hours — entirely from local records against a versioned,
explicit `FeverInsightsConfiguration` (fever threshold, episode-gap
window). Every field is reproducible from the same inputs; nothing is
predicted, inferred, or fetched from a network service. `nil` is used
explicitly to mean "insufficient data," never coerced to zero.

> **Open item carried from Phase 7:** the exact fever-spike threshold and
> episode-gap window need product/medical review before these insights
> ship to real users beyond internal testing — see the `TODO` in
> `FeverInsights.swift`. Release blocker if fever-spike insights are
> exposed publicly.

---

## Phase 8 — Charts and Local Notifications

**Status: complete.**

Three Swift Charts views (`FeverLog/Screens/Charts/`): temperature over
time, medication administration timeline, symptom frequency — each with a
selectable range (24h/3d/7d/14d) via `ChartTimeRange` and pure, unit-tested
aggregation in `ChartDataAggregator`. Temperature is rendered as
`PointMark`s only, deliberately never `LineMark` — connecting sparse,
manually-entered readings with a line would visually imply continuous
measurement that was never actually taken. Every mark carries a per-point
`accessibilityLabel` so VoiceOver users can navigate the chart one data
point at a time; Charts is the one screen that supports landscape
orientation (`OrientationManager`/`AppDelegate`) since the data reads
better wide.

Local notifications (`NotificationScheduler`, wrapped behind
`NotificationCenterScheduling` for testability without touching the real
notification system) back a Reminders feature
(`FeverLog/Screens/Reminders/`) for medication/temperature/hydration/custom
reminders — device-local in v1, not synchronized between household
members.

---

## Phase 9 — Supabase Auth and Household Sync

**Status: complete.** See [Supabase setup](README.md#supabase-setup-household-sync)
in the README for setup instructions.

This is the largest architectural phase. The design is **offline-first,
RLS-first, and identity-linking-first**, chosen specifically to avoid ever
needing a SQL data migration when a guest upgrades to a permanent account:

- **Anonymous auth by default.** First launch silently calls
  `supabase.auth.signInAnonymously()` — no login screen, no account
  required. The Supabase SDK persists the session in the iOS Keychain, so
  it survives app restarts, reboots, and updates (lost only if the app is
  deleted or the Keychain is cleared).
- **Identity linking, not account creation.** Choosing Apple/Google/Email
  in Settings → Account **links** the provider to the existing anonymous
  user — same `auth.uid()`, same household, same history. No new user, no
  migration.
- **Every household is created immediately**, one per anonymous user, via
  a `SECURITY DEFINER` Postgres function
  (`create_personal_household`, in
  [`supabase/migrations/20260920193305_init_schema.sql`](supabase/migrations/20260920193305_init_schema.sql))
  that's idempotent against re-invocation. Children belong to households
  from the moment they're created — there's no "temporary owner-only
  child" state to migrate out of later.
- **Row Level Security everywhere,** derived uniformly through
  `auth.uid() → household_members → household → child`. The same policies
  work identically for anonymous, Apple, Google, and Email-linked users —
  no separate RLS branch per auth method. Validated against a real local
  Postgres 16 instance (not just syntax-checked) with 13 representative
  access-case assertions covering household isolation, invite flows, and
  tombstone/conflict protection.
- **Offline-first sync engine** (`FeverLog/Services/Supabase/`):
  `SyncQueueItem` records (entity type, ID, operation, payload, status,
  retry count) are enqueued by every repository write alongside the local
  SwiftData commit — the local write always completes first and never
  requires network access. `SyncUploadProcessor` drains the queue with
  bounded exponential backoff (`SyncRetryPolicy`: 2s → 4s → 8s → …, capped
  at 300s, 6 max attempts). `RealtimeSyncSubscriber` +
  `SyncDownloadImporter` bring in remote changes through the same
  deterministic `ConflictResolver` (later `updatedAt` wins; exact ties
  broken by the lexicographically greater `id`) before the UI ever sees
  them.
- **Household sharing** requires a permanent (non-anonymous) account: the
  owner generates a 6-character hex invite code (deliberately excluding
  O/0/I/1/L to avoid ambiguity when read aloud or handwritten), the
  invitee redeems it via `HouseholdSyncCoordinator.joinHousehold(code:)`.
  No child or record ever moves between households — sharing only adds a
  `household_members` row.
- **QR-code invitations were explicitly left as a TODO** in the original
  Phase 9 scope, superseded by the plain-text invite code for v1; nothing
  further has been built there.

---

## Phase 10 — Settings, Accessibility, Localization, Widgets, Performance

**Status: in progress — widgets deferred (see below); final phase-wide
test/lint/commit pass still pending.**

### Settings screens

`FeverLog/Screens/SettingsScreen.swift` is the entry point to nine
sub-screens: Appearance (Phase 1), Household (rename, member/role list),
Children (list/add/edit/soft-delete), Medication Library (searchable,
read-only browser over the same database Phase 5 built, with a detail
view showing every configured dosing limit), Units (device-local default
weight unit, used to pre-fill new weight entries), Language, Reminders
(Phase 8), Account/Sync Status (Phase 9), About, and Privacy. About and
Privacy are static screens that describe what the app *actually* does —
written directly from the real sync/storage behavior above, not aspirational
copy.

### Localization

Seven languages: English (fully reviewed, the only one not marked
`needs_review`), Ukrainian, Russian, Dutch, Spanish, German, Polish.
Language selection is a device-local Settings preference
(`LanguageManager`), independent of the system language and never synced
between household members. It's implemented by reading each localized
string directly from the target language's compiled `.lproj` bundle
(`L10n.localized(_:)` / `L10nLocale.bundle`) rather than via
`String(localized:locale:)` — that API turned out to silently keep
returning a previously-resolved language for a key after the target
locale changed, confirmed by tracing actual returned values through the
device log; reading a specific bundle directly sidesteps whatever
memoization causes that. Only a "core" subset of ~100 high-traffic keys
(onboarding, navigation, home, settings, child form) has real translations
for all seven languages today; everything else falls back to English by
design — `L10n.localized(_:)` explicitly re-implements that fallback,
since direct bundle lookups don't provide it automatically the way
`String(localized:)` does.

### Accessibility

- **Dynamic Type:** `Typography`'s tokens were using
  `Font.system(size:weight:design:)`, which renders at a fixed point size
  and does **not** scale with the user's text-size setting, despite an
  existing doc comment claiming it did. Fixed with a `UIFontMetrics`-based
  scaling helper; verified visually by running the app in the simulator at
  the largest accessibility text size and confirming text actually grows.
- **VoiceOver validation errors:** form validation errors were plain
  `Text`, silent to a screen reader unless the user happened to swipe
  directly to them. `.announcesAccessibilityErrors(_:)`
  (`FeverLog/Utilities/AccessibilityAnnouncement.swift`) posts a VoiceOver
  announcement the instant an error appears, applied to every screen with
  error-message state.
- **Reduce Motion:** audited — all `withAnimation` call sites were already
  correctly gated behind `accessibilityReduceMotion`.
- **Color-blind safety:** audited — temperature status is always paired
  with a text label (see Phase 4), never conveyed by color alone.
- **Chart accessibility:** audited — already covered in Phase 8 via
  per-mark `accessibilityLabel`s.

### Performance measurement harness

`FeverLogUITests/PerformanceTests.swift` — cold launch time
(`XCTApplicationLaunchMetric`, measured against an empty store so the
result reflects fixed startup cost rather than data volume) and Timeline
scroll cost under a realistic data volume (`XCTCPUMetric`/`XCTMemoryMetric`
while scrolling a child seeded with 300 temperature readings via a new
DEBUG-only `--uitest-seed-large-dataset` launch argument). Full methodology,
including why baselines are deliberately *not* committed to the repo, is
in the README's [Performance](README.md#performance) section.

### Widgets — not implemented, deferred

**Status: explicitly deferred. No code exists for this.** There is an
empty, untracked `FeverLog/Widgets/` directory left over from earlier
scaffolding and nothing else — no WidgetKit extension target, no timeline
provider, no shared data model.

This was deferred rather than half-built because a widget isn't a small
addition on top of the existing app target — it requires:

- A separate WidgetKit extension target in `project.yml` (its own
  `Info.plist`, its own minimal SwiftUI view hierarchy — widgets can't
  reuse the main app's `NavigationStack`-based screens).
- An **App Group** entitlement shared between the main app and the
  extension, since a widget extension runs as a separate process and
  cannot read the main app's SwiftData store directly — it needs either a
  shared App Group container (SQLite/SwiftData store relocated there) or a
  small denormalized snapshot written by the main app for the widget to
  read.
- A deliberate choice of *what* to surface. Candidates that fit the app's
  non-diagnostic, privacy-conscious posture: "time since last reading,"
  "next medication eligible at," "today's reading count." Nothing that
  would put a raw temperature value or medication name on a lock screen
  where anyone glancing at the phone could see it without unlocking —
  that's a real design decision that needs to be made deliberately, not
  defaulted into.
- A `WidgetKit` `TimelineProvider` and reload-scheduling strategy (widgets
  don't get live updates — they need to be told when to refresh, which
  means every write path that affects widget-visible data would need to
  call `WidgetCenter.shared.reloadAllTimelines()`).

None of that exists yet. If/when this is picked up, it's a phase-sized
piece of work in its own right, not a Phase 10 add-on.

---

## Phase 11 — Release Hardening, Docs, Open-Source Repo Setup

**Status: not started.**

Not yet scoped in detail. Known candidates based on what earlier phases
left as open items:

- Resolve the Phase 7 fever-spike threshold/episode-gap TODO with
  product/medical review before fever insights are shown beyond internal
  testing (see Phase 7 above).
- A versioned SwiftData migration plan — there is currently no migration
  strategy for schema changes after the first release (see the `TODO` in
  `PersistenceController.swift`).
- Fill in `docs/architecture/README.md` (currently a stub) and expand
  `CHANGELOG.md` (currently empty).
- Broaden translation coverage for the six non-English languages beyond
  the current "core" key subset (see Phase 10 above), or get native-speaker
  review on what's already there — every non-English string is currently
  marked `needs_review` in `Localizable.xcstrings`.
- General open-source repo hygiene: issue/PR templates, a real
  `CHANGELOG.md`, and a decision on whether/how the Dr.Baby clinic
  distribution plan (QR code / download link, mentioned in `PLAN-mine.md`)
  affects the public repo.

---

## Ideas under consideration (not scoped, not committed)

Carried over from the project's original informal planning notes
(`PLAN-mine.md`) for visibility — none of these have been designed or
scheduled into a phase:

- Water intake and diaper-change logging (mentioned in early planning,
  never added to the phase plan).
- A medication-info compendium/scraper with per-country or WHO dosing
  guidance, with real update/versioning strategy — a significant scope
  and liability question on its own, given the app's current stance of
  using a small, manually-curated, versioned reference database instead.
- Sharing a read-only summary directly with a child's doctor.
- Distribution via Dr.Baby clinic (QR code / download link) — a
  distribution/business decision, not an engineering one, and orthogonal
  to the open-source repo itself.
