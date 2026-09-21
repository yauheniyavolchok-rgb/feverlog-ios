# Architecture

This directory holds two kinds of document, and it's worth being clear
about which is which:

- **[`offline-first.md`](offline-first.md)** and **[`components.md`](components.md)**
  are the project's original planning notes, written before implementation
  started. They're kept as-is for historical context and design rationale
  (`offline-first.md` in particular explains *why* the app is offline-first
  at all — a real constraint, not just a technical preference).
  `components.md` is an early feature brainstorm; not everything in it was
  built, and some of it was deliberately deferred or reshaped. For what
  actually exists today, see [`ROADMAP.md`](../../ROADMAP.md), which tracks
  real, shipped status phase by phase.
- **This file** is the current, accurate summary of the app's core
  architectural invariants — the decisions that constrain how every
  feature gets built, not what any one feature does.

## The invariants

### SwiftData is the local source of truth

Every screen reads from SwiftData. Supabase is a sync transport, never a
direct UI read source — there is no code path where a view queries
Supabase for something to display. This is what makes guest mode (no
account, no network) fully functional rather than a crippled demo mode:
the app was never designed around "online" as the default state.

Enforced by: every repository in `FeverLog/Services/Repositories/` reads
and writes through a SwiftData `ModelContext`; nothing in `FeverLog/Screens/`
imports the Supabase SDK directly.

### Local writes complete before sync

A write is not "pending" from the user's perspective until sync catches
up — it's already saved. Every repository write commits to SwiftData
first and *then* enqueues a `SyncQueueItem`
(`FeverLog/Services/Supabase/SyncQueueTrigger.swift`). If the device is
offline, or Supabase isn't configured at all, the write already succeeded;
only the upload is deferred. See `docs/architecture/offline-first.md` for
why this matters in practice, not just in principle.

### The medication safety engine is a separate, dependency-free package

`FeverLogEngine` (a local Swift package, not an app-target folder) cannot
import SwiftUI, SwiftData, Supabase, or UIKit. Dose and safety-threshold
arithmetic is pure, deterministic, `Decimal`-based, and independently
tested (`cd FeverLogEngine && swift test`) — the same input always
produces the same output, and that output is a typed status (eight
explicit states — normal, missing weight, missing rule, interval warning,
approaching maximum, unusual dose, maximum exceeded, invalid input), never
a bare boolean and never a value the engine invented for a limit that
wasn't actually configured for that medication. This is not a diagnostic
tool and does not provide medical advice; that boundary is a design
constraint, not a disclaimer bolted on afterward.

### Household sync is offline-first end to end

Every write enqueues locally; a background `SyncCoordinator` drains the
queue with bounded exponential backoff
(`FeverLog/Services/Supabase/SyncRetryPolicy.swift`); incoming Realtime
changes go through the same deterministic conflict resolver
(`ConflictResolver.swift` — later `updatedAt` wins, ties broken by the
greater `id`) before the UI ever sees them, so the app never has to
reason about two different code paths for "data I wrote" versus "data
that arrived from sync." See [Supabase setup](../../README.md#supabase-setup-household-sync)
in the README and the Phase 9 entry in [`ROADMAP.md`](../../ROADMAP.md)
for the full design.

### Records are soft-deleted, never physically removed by application code

Every syncable model conforms to `SyncableRecord`
(`FeverLog/Models/SyncableRecord.swift`): `deletedAt` is a tombstone, not
a row removal. This is what makes sync convergence tractable — a device
that was offline when something was deleted needs to *see* the deletion
arrive as a change, not have the record silently vanish with no signal
that anything happened.

## Where to look for more detail

- Phase-by-phase "what actually shipped, with file references":
  [`ROADMAP.md`](../../ROADMAP.md)
- Build/test/lint setup and code conventions: [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- Supabase/RLS/sync setup instructions: [`README.md`](../../README.md#supabase-setup-household-sync)
