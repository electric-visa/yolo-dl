# Code Review — YoloDL (during Phase 6)

Reviewed: 2026-03-14
Scope: Full codebase (19 Swift files)

---

## 1. Backend Logic — Overlaps and Redundancies

### 1.1 Duplicate alert-showing mechanism in ContentView

`ContentView` has two parallel ways to show alerts:

- **`showAlert` binding** (lines 33–38) — a manual `Binding<Bool>` that reads/writes `downloader.alertToShow`.
- **`isShowingAlert` computed property** on `DownloadManager` (lines 41–44) — does the exact same thing.

`isShowingAlert` is defined on the model but never used by any view. Meanwhile `ContentView` creates its own `showAlert` binding that duplicates the logic. One of these should be removed — likely `isShowingAlert` on DownloadManager, since the view-layer binding is the one actually in use.

### 1.2 AlertMessage vs InputValidationError — overlapping error models

Two separate types serve the same purpose (presenting errors to the user):

- **`AlertMessage`** — a generic `Identifiable` struct with `title` and `text`.
- **`InputValidationError`** — an `Identifiable` enum with `title` and `message` properties.

`handleError()` converts `InputValidationError` into `AlertMessage` on every call. These could be unified: `InputValidationError` could conform to a protocol that `AlertMessage` also conforms to, or `AlertMessage` could be dropped in favor of using SwiftUI's `alert(item:)` with `InputValidationError` directly. The current dual system makes it easy to accidentally create alerts in inconsistent ways.

### 1.3 Error handling spread across multiple sites

Errors are surfaced to the user in at least four different patterns:

1. `handleError(.someCase)` — sets `appState` and `alertToShow` via `InputValidationError`.
2. Direct assignment: `self.alertToShow = AlertMessage(title:text:)` — used in `fetchMetadata()` and `launchProcess()`.
3. `errorParser.parseErrors()` — returns an optional `String`, which is then wrapped into `AlertMessage`.
4. `validateInputs()` — calls `handleError()` internally, returns `Bool`.

Consolidating all error presentation through a single path (e.g., always going through `handleError` or a unified `showError()` method) would reduce the risk of inconsistencies (e.g., forgetting to set `appState = .error`).

### 1.4 downloadIsActive set in two places

In `startDownloadProcess()` (line 315), `downloadIsActive = true` is set before calling `launchProcess()`. But `launchProcess()` also sets `downloadIsActive = true` (line 229). The assignment in `startDownloadProcess` is redundant.

### 1.5 Termination handling inconsistency between download and recording

- `startDownloadProcess()` termination: calls `resetDownloadState()` → sets `downloadIsActive = false`, then sets `appState = .finished`, then calls `clearPendingState()`.
- `startRecording()` termination: directly sets `downloadIsActive = false` and `appState = .finished`, but does **not** call `clearPendingState()`.

This is likely fine since recording doesn't use pending state, but the asymmetry suggests a cleanup path could be missed if recording ever starts using metadata.

---

## 2. Property Naming

### 2.1 `downloadIsActive` / `downloadIsFinished` — semantically misleading for recordings

These names imply download-only semantics, but they're also used when recording. Consider more general names like `taskIsActive` / `taskIsFinished`, or `isActive` / `isFinished`. The same applies to `downloadProgress` (could be `progress`), `downloadIsCancelled` (could be `isCancelled`), and `activeDownload` (could be `activeProcess`).

### 2.2 `DownloadMode` struct vs `DownloadModeView` file name

The struct is named `DownloadMode` but the file is `DownloadModeView.swift`. The counterpart is `RecordModeView` (both file and struct). These should be consistent — either both `*Mode` or both `*ModeView`.

### 2.3 `sourceURL` is a `String`, not a `URL`

Naming it `sourceURL` suggests it's a `URL` type. Since it's a `String`, consider `sourceURLString` or `sourceAddress` to avoid confusion, or convert it to an actual `URL` with validation.

### 2.4 `pendingFileNamingPattern` vs `pendingDownloadLocation`

`pendingFileNamingPattern` stores a naming template string while `pendingDownloadLocation` stores a directory path. The "pending" prefix groups them logically, but a struct like `PendingDownload` with `.location`, `.namingPattern`, `.metadata`, `.duplicatePath` would be cleaner and allow a single optional (`pendingDownload: PendingDownload?`) instead of four separate properties that must be kept in sync.

### 2.5 `progressBarAnimationSpeed` defined in ContentView

This constant lives in `ContentView` (line 20) and is only passed to `ProgressBarView`. It should live on `ProgressBarView` alongside `progressBarFinishedSpeed`, or `ProgressBarView` should own both as defaults.

---

## 3. Code Readability

### 3.1 DownloadManager is doing too much

At ~400 lines, `DownloadManager` handles: input validation, metadata fetching, process launching, progress parsing, download state, recording state, alert management, pending state management, cancellation, and simulation support. Consider splitting into focused extensions or extracting responsibilities:

- `DownloadManager+Metadata.swift` — `fetchMetadata()`, `parseProgressFromStderr()`
- `DownloadManager+Process.swift` — `launchProcess()`, `startDownloadProcess()`, `startRecording()`
- Keep the core state properties and lifecycle methods in the main file.

### 3.2 Inconsistent indentation in downloadFiles()

Lines 187–190 have incorrect indentation — the `if` body and `return` are not indented relative to the `if`:

```swift
if !isVOD && appMode == .download {
showLiveContentAlert = true
return
}
```

### 3.3 Comments that restate the code

Many comments describe what the next line does rather than *why*:

- `// Default AppState` above `var appState: AppState = .ready`
- `// Initialize alert message` above `var alertToShow: AlertMessage? = nil`
- `// Declaring & initializing logger` above `let logger: LogManager`
- `// Function to clear the log array.` above `func clearLog()`

These add visual noise without adding information. Reserve comments for non-obvious intent or business logic explanations.

### 3.4 `withCheckedContinuation` in fetchMetadata()

Using `withCheckedContinuation` to bridge `Process` termination handlers works, but the pattern is fragile — if a code path exits without calling `continuation.resume`, the app hangs silently. Consider using `withCheckedThrowingContinuation` and auditing all exit paths, or using an `AsyncStream`-based approach.

---

## 4. Code Modularity

### 4.1 ContentView owns too much state

`ContentView` manages: `appMode`, `recordSource`, `selectedChannel`, `streamURL`, `downloadLocation`, `namingPreset`, `currentError`, plus handles the download button action, folder selection, and three different alert/dialog presentations. Consider:

- Moving `chooseFolder()` and `handleDownloadButton()` out of the view (e.g., into DownloadManager or a dedicated coordinator).
- Moving `downloadLocation` and `namingPreset` into DownloadManager so they don't need to be passed through function arguments.

### 4.2 Record mode state scattered across ContentView

`recordSource`, `selectedChannel`, and `streamURL` live in `ContentView` and are passed to `RecordModeView` via bindings. If these were grouped into a small `@Observable` model or moved into `DownloadManager`, the live-content-alert handler (lines 155–159) wouldn't need to reach into ContentView state to set `appMode`, `recordSource`, and `streamURL`.

### 4.3 Binary paths should be configurable

The hardcoded `/opt/homebrew/bin/` paths (lines 19–21) are marked as temporary, but they're `let` constants with no mechanism for override. A `BinaryPaths` struct or a computed property that checks `Bundle.main.resourcePath` first would make the eventual release transition smoother.

### 4.4 ProgressBarView has many overlapping overlays

`ProgressBarView` stacks six layers (base rectangle + five overlays). Each overlay has its own `Rectangle`, `LinearGradient`, `.frame(height: 30)`, and opacity toggle. Consider extracting a helper method like `gradientBar(colors:opacity:)` to reduce repetition, and using a `ZStack` instead of nested `.overlay` modifiers for clarity.

---

## 5. Swift / SwiftUI Best Practices

### 5.1 `@State private var currentError` is unused

`ContentView` declares `@State private var currentError: InputValidationError? = nil` (line 22) but never reads or writes it. Remove it.

### 5.2 `import Foundation` in files that don't need it

`AlertTypes.swift`, `AppMode.swift`, `RecordSource.swift`, and `TVChannel.swift` import `Foundation` but use no Foundation types. Pure Swift enums/structs don't need this import.

### 5.3 Button action wrapping async in Task

```swift
Button("Download") {
    Task {
        await handleDownloadButton()
    }
}
```

This works but loses structured concurrency. The `Task` is unstructured and its lifetime isn't tied to the view. If the view disappears mid-download, the task continues. Consider using `.task` modifier with a trigger value, or storing the task for cancellation.

### 5.4 NSOpenPanel usage

`chooseFolder()` uses `NSOpenPanel.runModal()` which blocks the main thread. On modern macOS, prefer the async `NSOpenPanel.begin()` or use `.fileImporter()` modifier for a pure SwiftUI approach.

### 5.5 Live content confirmation dialog has no message body

The `.confirmationDialog("Live stream detected", ...)` (lines 150–163) has no `message:` parameter, unlike the duplicate confirmation dialog which has one. Adding a brief explanation (e.g., "This content appears to be a live stream. Would you like to switch to Record mode?") would help users understand what happened.

### 5.6 String interpolation in status text

```swift
Text("\(downloader.appState.statusText)")
```

The `\()` interpolation is unnecessary — `Text(downloader.appState.statusText)` is equivalent and cleaner.

---

## 6. Apple Human Interface Guidelines

### 6.1 No window size constraints on main window

`ContentView` has no `.frame(minWidth:minHeight:)` or `.frame(idealWidth:idealHeight:)`. Users can resize the window to unusable dimensions. macOS apps should define minimum window sizes.

### 6.2 Button placement

The "Download"/"Stop" button and "Choose folder" button are stacked vertically at the bottom with no visual hierarchy. Per HIG, the primary action button should be visually prominent (e.g., `.buttonStyle(.borderedProminent)`) and secondary actions should be visually subordinate.

### 6.3 "Choose folder" label

HIG recommends action-specific labels. "Choose folder" could be more descriptive: "Choose Download Folder" or "Select Destination". Also consider using a standard folder icon alongside the text.

### 6.4 Status text lacks visual distinction

`Text("\(downloader.appState.statusText)")` is plain text with no styling. Consider using `.foregroundStyle(.secondary)` and a smaller font to distinguish it from interactive content, or placing it in a proper status bar area.

### 6.5 No keyboard shortcuts

Common macOS actions lack keyboard shortcuts:
- Download/Record: no shortcut (could be Cmd+D or Cmd+R)
- Choose folder: no shortcut (could be Cmd+O or Cmd+Shift+O)
- Stop: no shortcut (could be Cmd+. or Esc)

### 6.6 No menu bar integration

The app has no custom menu items. Standard macOS apps should have menu bar entries that mirror primary window actions, especially for non-technical users who may look for "File > Open" or "File > Download" patterns.

---

## 7. Summary of Priority Items

| Priority | Issue | Files |
|----------|-------|-------|
| High | Consolidate error handling into single path | DownloadManager.swift |
| High | Remove unused `currentError` state | ContentView.swift |
| High | Remove unused `isShowingAlert` property | DownloadManager.swift |
| Medium | Rename download-centric properties to be mode-agnostic | DownloadManager.swift |
| Medium | Fix struct/file naming inconsistency (`DownloadMode` vs `DownloadModeView`) | DownloadModeView.swift |
| Medium | Group pending state into a struct | DownloadManager.swift |
| Medium | Add `.buttonStyle(.borderedProminent)` to primary action | ContentView.swift |
| Medium | Add minimum window size | ContentView.swift or YoloDLApp.swift |
| Medium | Add message body to live content confirmation dialog | ContentView.swift |
| Low | Remove unnecessary `import Foundation` | Multiple files |
| Low | Remove redundant `downloadIsActive = true` in `startDownloadProcess()` | DownloadManager.swift |
| Low | Clean up comments that restate code | Multiple files |
| Low | Fix indentation in `downloadFiles()` | DownloadManager.swift |
| Low | Consider `.fileImporter()` instead of `NSOpenPanel` | ContentView.swift |
