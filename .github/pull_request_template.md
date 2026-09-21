## What this changes and why

<!-- Explain the reasoning, not just a restatement of the diff. -->

## How this was tested

<!--
e.g. "Added a unit test covering X"; "Ran the UI test suite locally";
"Verified manually in the simulator: steps I took". See CONTRIBUTING.md —
this project treats "compiles" and "passes tests" as necessary but not
sufficient for calling a change done.
-->

## Checklist

- [ ] `xcodebuild build` and `xcodebuild test` pass locally (or `swift test`
      in `FeverLogEngine/`, if that's the only thing touched)
- [ ] `swiftlint lint --strict` passes
- [ ] New user-facing strings go through `L10n` / `Localizable.xcstrings`,
      not raw literals
- [ ] If this touches a synced model, `SyncableRecord` fields are handled
      correctly (soft delete, `updatedAt` bump, etc.)
