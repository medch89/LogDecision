## What does this PR do?

<!-- One paragraph: the problem and the solution. Link to the ticket/issue if applicable. -->

## Type of change

- [ ] 🆕 New feature
- [ ] 🐛 Bug fix
- [ ] ♻️ Refactor - Tech debt (no behaviour change)
- [ ] 🧹 Chore / tooling / config
- [ ] 📝 Docs only

## How to test

<!-- Steps the reviewer should follow to verify the change locally. -->

1. 
2. 

---

## Architecture checklist

> Tick every item that applies. Leave unchecked items blank (don't delete them) so reviewers can spot gaps quickly.

### Domain layer
- [ ] Model is an immutable value type (`struct`) — all properties `let`, conforms to `Equatable` **and** `Sendable`
- [ ] Loader protocol uses `async throws` — no completion callbacks, no Combine
- [ ] Action enum is `Equatable`; every user/system event has a case

### API layer
- [ ] `RemoteLoader` injects `baseURL: URL` and `client: HTTPClient`
- [ ] URLs built with `URLComponents` — no string interpolation
- [ ] Mapper is an `enum` with a single `static func map(...)`, all decoding types `private`

### Persistence layer
- [ ] Storage is behind a protocol (e.g. `DefaultsClient`) — no direct `UserDefaults` / `URLSession` usage
- [ ] Local loaders use `async throws` (same shape as remote loaders)

### Presentation layer
- [ ] ViewModel is `@MainActor final class`
- [ ] ViewModel uses `Observer<T>` callbacks (`onLoaded`, `onLoadingStarted`, `onLoadingFailed`) — **no** `ObservableObject` / `@Published`
- [ ] `Task` references stored and cancelled in `deinit` (and before re-load)
- [ ] `Task.isCancelled` checked after every `await` before calling callbacks
- [ ] Idempotent lifecycle calls guarded with `appeared: Bool` flag
- [ ] All user-facing strings use `String.localise(key:)`
- [ ] All analytics / navigation events routed through `actionHandler`

### UI layer
- [ ] View is a `struct` with plain `let` properties for Store and ViewModel — no property wrappers
- [ ] View contains **no** presentation logic (`if viewModel.isLoading` etc.) — only renders Store slots
- [ ] Store is `@Observable final class` — **not** `ObservableObject`
- [ ] Store holds composed Views only — no data models
- [ ] Colors use `FeatureNameColor` enum — no hardcoded values
- [ ] Fonts use `FeatureNameFont` enum — no hardcoded values

### Composition root
- [ ] Composer is an `enum` with only `static` factory methods
- [ ] All ViewModel `Observer<T>` → Store mutation wiring is in the Composer only

### Cross-cutting
- [ ] No SwiftUI / UIKit imports inside `CoreFramework`
- [ ] No business logic inside a View or Store
- [ ] No cross-feature imports — only `Shared/` as a cross-feature dependency
- [ ] No Combine, RxSwift, or completion callbacks anywhere
- [ ] No force-unwraps — `guard let` / `try?` with explicit handling used instead

---

## Tests added / updated

- [ ] Unit tests for isolated components
- [ ] Integration test for expected behaviour when components integrated
- [ ] No new code is untested

## Screenshots / recordings

<!-- For UI changes, attach before/after screenshots or a screen recording. Delete this section for non-UI PRs. -->

| Before | After |
|--------|-------|
|        |       |
