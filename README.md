# FeverLog

A home-brewed, local-first iOS app for tracking a child's fever, temperature
history, and medication doses — with a deterministic, offline-capable
medication safety engine and optional household sync. Built for free
distribution in Dr.Baby clinics.

> **Status:** Phases 0-4 complete (project foundation, design system, local
> data model, onboarding/guest mode, temperature logging & timeline). See
> [ROADMAP.md](ROADMAP.md) for the phased delivery plan.

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
everything works fully offline. Supabase credentials (see
[`.env.example`](.env.example)) are only needed for optional household
synchronization (Phase 9).

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
