# DownloadManager @Observable Migration — Code Review

## DownloadManager.swift

### Remove `import Combine` and update class declaration

| Before | After |
|--------|-------|
| `import Combine` | *(removed)* |
| `@MainActor class DownloadManager: ObservableObject {` | `@MainActor @Observable class DownloadManager {` |

### Remove `@Published` from all properties

| Before | After |
|--------|-------|
| `@Published var sourceUrl: String = ""` | `var sourceUrl: String = ""` |
| `@Published private(set) var downloadIsActive: Bool = false` | `private(set) var downloadIsActive: Bool = false` |
| `@Published private(set) var downloadIsFinished: Bool = false` | `private(set) var downloadIsFinished: Bool = false` |
| `@Published private(set) var totalDuration: Int = 0` | `private(set) var totalDuration: Int = 0` |
| `@Published private(set) var downloadProgress: Double = 0` | `private(set) var downloadProgress: Double = 0` |
| `@Published var alertToShow: AlertMessage? = nil` | `var alertToShow: AlertMessage? = nil` |
| `@Published var appState: AppState = .ready` | `var appState: AppState = .ready` |

---

## YoloDLApp.swift

### `downloadManager` property

| Before | After |
|--------|-------|
| `@StateObject private var downloadManager = DownloadManager()` | `@State private var downloadManager = DownloadManager()` |

### Environment injection (both occurrences)

| Before | After |
|--------|-------|
| `.environmentObject(downloadManager)` | `.environment(downloadManager)` |

---

## ContentView.swift

### `downloader` property

| Before | After |
|--------|-------|
| `@EnvironmentObject private var downloader: DownloadManager` | `@Environment(DownloadManager.self) private var downloader` |

### `@Bindable` local var added at top of `body`

`$downloader.sourceUrl` (used by TextField) requires `@Bindable` when the source is `@Environment` + `@Observable`.

| Before | After |
|--------|-------|
| `var body: some View {` | `var body: some View {` |
| *(nothing)* | `    @Bindable var downloader = downloader` |

---

## DebugWindow.swift

### `downloadManager` property

| Before | After |
|--------|-------|
| `@EnvironmentObject var downloadManager: DownloadManager` | `@Environment(DownloadManager.self) var downloadManager` |

---

## DownloadManager+Debug.swift

No changes required — extension only calls methods and accesses properties, no ObservableObject-specific APIs.
