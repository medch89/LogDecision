# Architecture Guide

A reference for building new features or projects following the same architecture, updated to use Swift Structured Concurrency (async/await).

---

## Project Layout

Every feature lives in two targets:

```
CoreFramework/<Feature>/
├── Domain/          ← models, protocols, action enums
├── API/             ← remote loaders, mappers
├── Presentation/    ← ViewModels, formatters, observers
└── Persistence/     ← local clients, local loaders

iOSApp/<Feature>/
├── UI/              ← SwiftUI Views, Stores
│   └── Store/
└── Composers/       ← composition root (dependency injection wiring)
```

**Hard rules:**
- No UI framework imports inside `CoreFramework` (no SwiftUI, no UIKit).
- No business logic inside `iOSApp` Views or Stores.
- Features must not import each other — only `Shared/` is a cross-feature dependency.

---

## 1. Domain Layer

### Models

Immutable value types, always `Equatable`. All properties are `let`.

```swift
public struct FeatureName: Equatable, Sendable {
    public let id: String
    public let title: String
    public let createdAt: Date

    public init(id: String, title: String, createdAt: Date) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}
```

- Conform to `Sendable` so models cross actor boundaries safely.
- Nest related sub-types inside the parent struct when they only exist in that context:

```swift
public struct FeatureName: Equatable, Sendable {
    public struct Creator: Equatable, Sendable {
        public let id: String
        public let name: String
    }
    public let id: String
    public let creator: Creator
}
```

### Loader Protocols

One protocol per data source. Use `async throws` — no completion callbacks.

```swift
public protocol FeatureNameLoader: Sendable {
    func load() async throws -> FeatureName
}

// With parameters:
public protocol FeatureNameLoader: Sendable {
    func load(page: Int) async throws -> [FeatureName]
    func load(id: String) async throws -> FeatureName
}
```

Parameters that vary per call go on `load(...)`, not the initializer.

### Action Enums

Every user or system event is an `enum` case with associated values. Must be `Equatable`.

```swift
public enum FeatureNameAction: Equatable {
    case loaded(FeatureName)
    case tapItem(FeatureName)
    case back
}
```

Use the shared typealias:

```swift
// Shared/Helpers/ActionObserver.swift
public typealias ActionHandler<Action> = (Action) -> Void
```

---

## 2. API Layer

### Remote Loader

`final class`, injects `baseURL: URL` and `client: HTTPClient`. Errors are a nested `enum`.

```swift
public final class RemoteFeatureNameLoader: FeatureNameLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let baseURL: URL
    private let client: HTTPClient

    public init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }

    public func load() async throws -> FeatureName {
        let (data, response) = try await client.data(for: makeRequest())
        return try FeatureNameMapper.map(data, from: response)
    }

    private func makeRequest() -> URLRequest {
        var components = URLComponents(string: baseURL.absoluteString)!
        components.path = "/api/feature-name"
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
```

**Never** use string interpolation to build URLs. Always use `URLComponents`.

### HTTP Client Protocol

```swift
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
}
```

### Mappers

`enum` with a single `static func map(...)`. All decoding types are `private`. The `.local` computed property converts the raw JSON struct to the domain model.

```swift
public enum FeatureNameMapper {
    private struct Root: Decodable {
        let id: String
        let title: String
        let created_at: Date        // snake_case matches JSON

        // Use CodingKeys only when key names differ significantly
        // enum CodingKeys: String, CodingKey { case createdAt = "created_at" }

        var local: FeatureName {
            FeatureName(id: id, title: title, createdAt: created_at)
        }
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> FeatureName {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeatureNameLoader.Error.invalidData
        }
        return root.local
    }
}
```

**Tolerant array decoding** — when individual items in a list may fail, use `ThrowableModel` so one bad item doesn't break the whole list:

```swift
// Shared/Helpers/ThrowableModel.swift
struct ThrowableModel<T: Decodable>: Decodable {
    let result: Result<T, Error>
    init(from decoder: Decoder) throws {
        result = Result(catching: { try T(from: decoder) })
    }
}

// Inside a mapper Root:
private struct Root: Decodable {
    let items: [ThrowableModel<RemoteItem>]
    var local: [FeatureName] {
        items.compactMap { try? $0.result.get().local }
    }
}
```

---

## 3. Persistence Layer

Abstract every platform storage behind a protocol so it is testable without the real store.

```swift
// Protocol lives in CoreFramework/Feature/Persistence/
public protocol DefaultsClient: Sendable {
    func set(_ value: Bool, forKey key: String)
    func fetch(forKey key: String) -> Bool?
}

// Implementation lives in CoreFramework/Feature/Persistence/ or iOSApp/
public final class UserDefaultsClient: DefaultsClient {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func fetch(forKey key: String) -> Bool? {
        defaults.object(forKey: key) == nil ? nil : defaults.bool(forKey: key)
    }
}
```

Local loaders follow the same `async throws` protocol shape as remote loaders.

---

## 4. Presentation Layer

### ViewModel

`@MainActor final class`. Owns async Tasks. Communicates state outward via `Observer<T>` callbacks, NOT `@Published` or `ObservableObject`. Never imports SwiftUI.

```swift
@MainActor
public final class FeatureNameViewModel {
    // Observer<T> callbacks — wired by the Composer, not the View
    public var onLoadingStarted: Observer<Void>?
    public var onLoaded: Observer<FeatureName>?
    public var onLoadingFailed: Observer<Void>?

    private let loader: FeatureNameLoader
    private let actionHandler: ActionHandler<FeatureNameAction>
    private var loadTask: Task<Void, Never>?
    private var appeared = false

    public init(
        loader: FeatureNameLoader,
        actionHandler: @escaping ActionHandler<FeatureNameAction>
    ) {
        self.loader = loader
        self.actionHandler = actionHandler
    }

    public func onAppear() {
        guard !appeared else { return }
        appeared = true
        load()
    }

    public func retry() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        onLoadingStarted?(())
        loadTask = Task {
            do {
                let result = try await loader.load()
                guard !Task.isCancelled else { return }
                onLoaded?(result)
                actionHandler(.loaded(result))
            } catch {
                guard !Task.isCancelled else { return }
                onLoadingFailed?(())
            }
        }
    }

    deinit {
        loadTask?.cancel()
    }
}
```

**Rules:**
- Mark with `@MainActor` — this replaces `MainQueueDispatchDecorator`.
- Expose state changes as `Observer<T>` callbacks (`onLoaded`, `onLoadingStarted`, `onLoadingFailed`). The Composer wires these to Store mutations — the ViewModel never knows about the View or Store.
- Do NOT use `ObservableObject` or `@Published` — the ViewModel is not observed by the View.
- Store `Task` references so they can be cancelled (e.g., on deinit or re-load).
- Always check `Task.isCancelled` after an `await` before calling callbacks.
- Guard idempotent lifecycle calls with an `appeared: Bool` flag.
- Localize all user-facing strings via `String.localise(key:)`.
- Route all events (analytics, navigation) through `actionHandler`.

### Pagination

```swift
private var currentPage = 0

public func loadMore() {
    currentPage += 1
    loadTask = Task {
        do {
            let newItems = try await loader.load(page: currentPage)
            guard !Task.isCancelled else { return }
            items.append(contentsOf: newItems)
        } catch {
            currentPage -= 1   // roll back on failure
        }
    }
}
```

---

## 5. iOS UI Layer

### Store (for views with injected sub-views)

Always use a Store. It holds the composed child Views that the Composer assigns in response to ViewModel callbacks. Use `@Observable` (iOS 17+), **not** `ObservableObject`.

```swift
import Observation

// Store holds composed View instances — never raw data models
@Observable
final class FeatureNameStore<Content: View> {
    var content: Content?
    var loadingView: FeatureNameLoadingView?
    var retryView: FeatureNameRetryView?
}
```

The Composer writes to the Store. The View only reads. No `@Published` needed — `@Observable` tracks all `var` properties automatically.

### View

`struct`, pure layout. Holds Store and ViewModel as plain `let` properties — no `@ObservedObject`, no property wrappers. Contains **no presentation logic** — no `if viewModel.isLoading`, no conditional rendering based on state. The only conditional rendering allowed is reading ready-made View slots from the Store (which the Composer already decided to populate or leave nil).

```swift
public struct FeatureNameView<Content: View>: View {
    // @Observable Store — SwiftUI tracks it automatically, no @ObservedObject needed
    private let store: FeatureNameStore<Content>
    // ViewModel is NOT observed — plain let, used only to forward lifecycle events
    private let viewModel: FeatureNameViewModel

    init(store: FeatureNameStore<Content>, viewModel: FeatureNameViewModel) {
        self.store = store
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            store.content
            store.loadingView
            store.retryView
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
```

**Why this pattern works:**
- The View is a dumb renderer — it never decides *what* to show.
- The Composer wires `viewModel.onLoaded = { store.content = contentView }` etc.
- Presentation logic (loading → content → error) lives entirely in the Composer, making it testable without a UI.

### Colors and Fonts

Never hardcode values in a View. Always use per-feature enums:

```swift
// FeatureNameColors.swift
enum FeatureNameColor {
    static let primaryText   = Color("FeatureName/PrimaryText")
    static let background    = Color("FeatureName/Background")
}

// FeatureNameFonts.swift
enum FeatureNameFont {
    static let title   = Font.system(size: 18, weight: .semibold)
    static let caption = Font.system(size: 13, weight: .regular)
}
```

Usage:

```swift
Text(item.title)
    .foregroundStyle(FeatureNameColor.primaryText)
    .font(FeatureNameFont.title)
```

---

## 6. Composition Root

Composers are `enum` (never `class` or `struct`) with only `static` factory methods. This is the **single place** where all presentation logic lives — it decides what the View shows for each state transition.

```swift
public enum FeatureNameUIComposer {
    public static func compose<Content: View>(
        loader: FeatureNameLoader,
        actionHandler: @escaping ActionHandler<FeatureNameAction>,
        content: @escaping (FeatureName) -> Content
    ) -> FeatureNameView<Content> {
        let store = FeatureNameStore<Content>()
        let viewModel = FeatureNameViewModel(
            loader: loader,
            actionHandler: actionHandler
        )

        // Wire ViewModel callbacks → Store mutations. This IS the presentation logic.
        viewModel.onLoadingStarted = { [weak store] in
            store?.loadingView = FeatureNameLoadingView()
            store?.retryView   = nil
            store?.content     = nil
        }
        viewModel.onLoaded = { [weak store] item in
            store?.content     = content(item)
            store?.loadingView = nil
            store?.retryView   = nil
        }
        viewModel.onLoadingFailed = { [weak store, weak viewModel] in
            store?.loadingView = nil
            store?.retryView   = FeatureNameRetryView(onRetry: { viewModel?.retry() })
        }

        return FeatureNameView(store: store, viewModel: viewModel)
    }
}
```

**Rules:**
- `@MainActor` on ViewModels eliminates the need for `MainQueueDispatchDecorator` — do not add it.
- Wire ViewModel `Observer<T>` callbacks → Store mutations **only** inside the Composer.
- The Composer decides what child view to assign for each state (loading, success, failure). The View just renders Store slots.
- Pass child-view factory closures as parameters when composing nested features.

---

## 7. Caching via Decorator

Add caching by wrapping a loader — never mutate the loader itself.

```swift
public actor InMemoryFeatureNameDecorator: FeatureNameLoader {
    private let decoratee: FeatureNameLoader
    private var cache: FeatureName?

    public init(decoratee: FeatureNameLoader) {
        self.decoratee = decoratee
    }

    public func load() async throws -> FeatureName {
        if let cache { return cache }
        let result = try await decoratee.load()
        cache = result
        return result
    }
}
```

Use `actor` (not `class`) for decorators that hold mutable state accessed from concurrent contexts.

---

## 8. Naming Conventions

| Type | Naming Pattern | Example |
|------|---------------|---------|
| Domain model | `FeatureName` | `Creator`, `FeedPost` |
| Loader protocol | `FeatureNameLoader` | `CreatorDetailsLoader` |
| Remote implementation | `RemoteFeatureNameLoader` | `RemoteFeedPostLoader` |
| Mapper | `FeatureNameMapper` | `FeedPostMapper` |
| Action enum | `FeatureNameAction` | `FeedPostAction` |
| ViewModel | `FeatureNameViewModel` | `FeedViewModel` |
| Store (sub-view holder) | `FeatureNameStore` | `StreamTeaserStore` |
| View | `FeatureNameView` | `StreamTeaserView` |
| Composer | `FeatureNameUIComposer` | `StreamTeaserUIComposer` |
| In-memory decorator | `InMemoryFeatureNameDecorator` | `InMemoryFeedPostProductDecorator` |
| Local loader | `LocalFeatureNameLoader` | `LocalFeedPostHintLoader` |
| Colors | `FeatureNameColor` | `StreamTeaserColor` |
| Fonts | `FeatureNameFont` | `StreamTeaserFont` |

---

## 9. Concurrency Rules

**Task cancellation checklist:**
1. Store the `Task` in a property.
2. Cancel it before starting a new load (`loadTask?.cancel()`).
3. Check `Task.isCancelled` after every `await` before mutating state.
4. Cancel in `deinit`.

**Structured concurrency for parallel loads:**

```swift
private func loadAll() {
    loadTask = Task {
        async let items  = loader.loadItems()
        async let config = loader.loadConfig()
        do {
            let (resolvedItems, resolvedConfig) = try await (items, config)
            guard !Task.isCancelled else { return }
            self.items  = resolvedItems
            self.config = resolvedConfig
        } catch {
            errorMessage = String.localise(key: "feature.general.error")
        }
    }
}
```

---

## 10. What Never to Do

- **No Combine or RxSwift** — use `async/await` and `Observer<T>` callbacks.
- **No `ObservableObject` or `@Published` in ViewModels** — ViewModels communicate via `Observer<T>` callbacks.
- **No `@ObservedObject` in Views** — Views hold ViewModel as plain `let`; `@Observable` Stores are tracked automatically.
- **No presentation logic in Views** — no `if viewModel.isLoading`, no conditional rendering based on state; all such logic belongs in the Composer.
- **No `DispatchQueue.main` calls** — mark ViewModels `@MainActor` instead.
- **No `MainQueueDispatchDecorator`** — `@MainActor` on ViewModel makes it unnecessary.
- **No completion callbacks on loader protocols** — all async is `async throws`.
- **No cross-feature imports in Domain** — only `Shared/` is a valid dependency.
- **No SwiftUI or UIKit in `CoreFramework`** — Domain, API, and Presentation are platform-agnostic.
- **No business logic inside a View or Store** — it belongs in the ViewModel (loaded/failed logic) and Composer (what to display).
- **No direct `UserDefaults` or `URLSession` usage** — always go through the protocol wrappers.
- **No hardcoded colors or fonts inline** — always use per-feature `FeatureNameColor` / `FeatureNameFont` enums.
- **No URL construction via string interpolation** — always use `URLComponents`.
- **No data models stored in a Store** — Stores hold composed Views only.
- **No force-unwrapping** — use `guard let` or `try?` with explicit error handling.

---

## 11. Checklist for a New Feature

```
Domain
 [ ] FeatureName.swift              — Equatable, Sendable value type
 [ ] FeatureNameLoader.swift        — async throws protocol
 [ ] FeatureNameAction.swift        — Equatable enum with all events

API (if needed)
 [ ] RemoteFeatureNameLoader.swift  — injects baseURL + HTTPClient
 [ ] FeatureNameMapper.swift        — private Root struct, static map()

Persistence (if needed)
 [ ] LocalFeatureNameLoader.swift   — implements loader protocol from local store

Presentation
 [ ] FeatureNameViewModel.swift     — @MainActor, Observer<T> callbacks, Task management (NO ObservableObject)

UI
 [ ] FeatureNameView.swift          — struct, plain let store + let viewModel, no presentation logic
 [ ] FeatureNameStore.swift         — @Observable final class, holds composed View slots
 [ ] FeatureNameColor.swift
 [ ] FeatureNameFont.swift

Composition
 [ ] FeatureNameUIComposer.swift    — enum, static compose(), wires everything

Tests
 [ ] FeatureNameLoaderTests.swift   — test RemoteLoader with mock HTTPClient
 [ ] FeatureNameViewModelTests.swift
 [ ] FeatureNameMapperTests.swift
```
