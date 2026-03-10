# YoloDL — Design Plan & Progress

**Last updated:** 9 March 2026 — v0.09 (Phase 4 in progress — Tasks 16, 17, 27, 35 complete)

---

## Overview

A native macOS application providing a user-friendly graphical interface for the yle-dl command-line tool. The app targets non-technical users who want to download content from Yle Areena without using the terminal.

---

## Progress vs. Original Plan

### Completed

| Feature | Version | Notes |
|---------|---------|-------|
| URL input field | 0.01 | |
| Download button | 0.01 | Calls yle-dl via Process |
| File location chooser dialog | 0.01 | NSOpenPanel, folder-only |
| Version display | 0.01 | Constant in ContentView |
| Per-episode download progress bar | 0.04 | Parses ffmpeg time= output, uses metadata for total duration |
| Progress bar shimmer animation | 0.04 | Linear repeating animation, visible only during download |
| Progress bar completion color snap | 0.04 | Blue → green with configurable fade duration |
| Basic error alerts | 0.04 | Empty URL, no folder selected |
| Simulation button for testing | 0.04 | Timer-based progress simulation |
| DownloadManager extraction | 0.06 | ObservableObject, lifted to App struct level |
| Status display | 0.07 | AppState enum with statusText, displayed in HStack |
| Remember last download location | 0.07 | @AppStorage("lastFolder") in ContentView |
| Cancel button | 0.07 | Download/Stop toggle button |
| Log capture | 0.08 | LogManager with size-capped buffer, stdout + stderr |
| Parsed readable error messages | 0.09 | ErrorParser with pattern → message mapping |
| Log window | 0.09 | Separate Window scene, accessible from Window menu |

### Not Yet Started

| Feature | Priority | Complexity |
|---------|----------|------------|
| Duplicate file detection | High | Medium |
| Live stream handling | Medium | Medium |
| Settings / presets (quality, format, naming) | Medium | Medium |
| Overall progress bar (multi-episode) | Medium | Medium |
| Advanced options panel (behind toggle) | Medium | Medium |
| Multilingual UI (Finnish + English) | Low | Medium |
| Update checker (JSON version endpoint) | Low | Medium |
| Bundling yle-dl + ffmpeg (PyInstaller) | Low | High |
| DMG distribution package | Low | High |

---

## Technology & Platform

- **Framework:** SwiftUI
- **Platform:** macOS only, minimum macOS 14 Sonoma
- **Distribution:** Self-hosted free download (not App Store), no notarization
- **Hosting:** Self-hosted Git repo over SSH, static download page, JSON version check endpoint
- **Source code:** Private repository

## Bundling & Dependencies

- yle-dl compiled into a standalone binary using PyInstaller, bundled in `Contents/Resources`
- Static ffmpeg binary also bundled in `Contents/Resources`
- Users need no external tools installed (no Python, pip, Homebrew, or CLI knowledge)
- Distribution as a `.dmg` with drag-to-Applications install
- Download page should include instructions for first launch (right-click → Open to bypass Gatekeeper)

## UI Languages

- Finnish and English at launch
- Language toggle in the UI

## Update Mechanism

- App checks a JSON file on the project site for the latest version number
- If a newer version is available, show an alert with a link to the download page
- Users download and install updates manually

## Error Handling

- Parse yle-dl's stderr into readable, actionable error messages (e.g. "This content is geo-restricted", "URL not recognized")
- Log window for raw log display, accessible from Window menu
- Pattern → message mapping for common yle-dl errors built into `ErrorParser`

## UI Features

### Main Interface

- URL input field
- Download button (disabled during active download)
- Cancel button (visible only during active download, implemented as Download/Stop toggle)
- File location chooser dialog
- Status display (Ready / Preparing / Fetching metadata / Downloading / Finished / Cancelled / Error)
- Per-episode download progress bar
- Overall progress bar for multi-episode downloads

### File Naming

- Preset selector (default: first option):
  1. `Series - S01E01 - Episode Title` (default)
  2. `Series - Episode Title`
  3. `Series S01E01`
  4. Custom `--output-template` string
- All presets map to yle-dl's `--output-template` parameter

### Settings / Presets

- Quality presets (maps to yle-dl parameters)
- Format selection (maps to yle-dl parameters)
- File naming convention (see above)
- Potentially stored in a config file for persistence across sessions

### Advanced Options (behind a toggle, with disclaimer)

- Resume incomplete downloads
- Audio-only download
- Subtitle language selection
- Custom `--output-template` input field
- Rate limiting
- Custom yle-dl flags (raw text field)
- Disclaimer: these options are for advanced users and malformed input is the user's responsibility

## Design Principles

- Simple and intuitive, following Apple Human Interface Guidelines
- Minimal technical knowledge required from the user
- Advanced features available but hidden by default
- yle-dl's default video quality (best available) used unless overridden via custom flags

## Development Approach

- This is a hobby project focused on learning SwiftUI, Xcode, and related tools
- Build incrementally: start with URL input, download button, and raw log output
- Layer on progress bars, presets, and advanced options one at a time
- Get something functional first, polish later

---

## To-Do List

Tasks are grouped by area. Within each group, items are roughly in priority order. "Frontend" means SwiftUI views and UI logic. "Backend" means process management, file operations, data handling.

### Code Review Fixes ✅ Complete

These address issues found in the v0.04 code review (7 March 2026). Completed in Phase 1.

| # | Task | Area | Complexity |
|---|------|------|------------|
| ~~1~~ | ~~Move `fetchMetadata()` off the main thread — currently blocks UI with `waitUntilExit()`~~ | ~~Backend~~ | ~~Medium~~ |
| ~~2~~ | ~~Clean up `readabilityHandler` — set to `nil` in termination handler to prevent retain cycle~~ | ~~Backend~~ | ~~Low~~ |
| ~~3~~ | ~~Extract hardcoded binary paths (yle-dl, ffmpeg, ffprobe) into constants~~ | ~~Backend~~ | ~~Low~~ |
| ~~4~~ | ~~Separate progress animation speed from completion color fade speed~~ | ~~Frontend~~ | ~~Low~~ |
| ~~5~~ | ~~Disable Download button and URL field while download is active~~ | ~~Frontend~~ | ~~Low~~ |
| ~~6~~ | ~~Handle failed metadata fetch gracefully — don't proceed with `totalDuration = 0`~~ | ~~Backend~~ | ~~Low~~ |
| ~~7~~ | ~~Wrap Simulate Download button in `#if DEBUG`~~ | ~~Frontend~~ | ~~Low~~ |
| ~~8~~ | ~~Clean up code formatting inconsistencies (indentation, spacing)~~ | ~~Both~~ | ~~Low~~ |

### Code Structure & Readability

Refactoring to keep the codebase manageable as features are added.

| # | Task | Area | Complexity |
|---|------|------|------------|
| ~~9~~ | ~~Extract download logic into a `DownloadManager` class (ObservableObject)~~ | ~~Backend~~ | ~~Medium~~ |
| ~~10~~ | ~~Break `downloadFiles()` into smaller single-purpose functions: validate inputs, fetch metadata, configure process, start download~~ | ~~Backend~~ | ~~Medium~~ |
| 11 | Group related `@State` variables with clear comments | Frontend | Low |
| ~~12~~ | ~~Move `EpisodeMetadata` and `DownloadError` into separate files as app grows~~ | ~~Both~~ | ~~Low~~ | ⚠️ Partially done — `EpisodeMetadata` is in its own file. `DownloadError` was never created; error handling is handled by `InputValidationError` and `AlertMessage` instead |
| ~~35~~ | ~~Move debug functions (`simulateDownload`, `simulateMetadataFailure`) from `DownloadManager` to `DebugWindow`~~ | ~~Both~~ | ~~Low~~ | ✅ Done — `#if DEBUG` extension in `DebugWindow.swift`, helper methods `resetForSimulation()` and `setDownloadProgress(to:)` in `DownloadManager`, timer leak fix |
| 37 | Move `AlertMessage` to its own file (`AlertMessage.swift`) — currently shares `AlertTypes.swift` with `InputValidationError` | Frontend | Low |
| 38 | Move `#if DEBUG` `DownloadManager` extension to `DownloadManager+Debug.swift` — debug extensions on a type should not live in another type's file | Backend | Low |
| 39 | Extract Download/Stop button action into a `handleDownloadButton()` method in `ContentView` — button logic should not live inline in `body` | Frontend | Low |
| 40 | Change `downloadActiveColors` and `downloadFinishedColors` in `ContentView` from computed `var` to `let` constants — they never change and currently allocate a new array on every render | Frontend | Low |
| 41 | Remove duplicate `progressBarFinishedSpeed` constant from `ContentView` — the authoritative value lives in `DownloadManager`; the `ContentView` copy appears unused | Both | Low |
| 49 | Migrate `DownloadManager` and `LogManager` from `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` to the `@Observable` macro + `@MainActor` — the modern replacement available since macOS 14, which is our minimum target | Backend | High |
| 50 | Rename `duration_seconds` to `durationSeconds` in `EpisodeMetadata` and add a `CodingKeys` enum to map it to the JSON key — Swift naming conventions require camelCase | Backend | Low |

### New Features — Backend

| # | Task | Complexity | Notes |
|---|------|------------|-------|
| ~~13~~ | ~~Remember last download location using `@AppStorage` / `UserDefaults`~~ | ~~Low~~ | ✅ Done — `@AppStorage("lastFolder")` in ContentView |
| 14 | Duplicate file detection — check download directory for existing files with the same name before starting; prompt user to overwrite or skip | Medium | Requires predicting yle-dl's output filename from metadata |
| ~~15~~ | ~~Download cancellation — store active `Process` reference, call `process.terminate()`~~ | ~~Low~~ | ✅ Done — `activeDownload` property + `cancelDownload()` with `downloadIsCancelled` flag |
| ~~16~~ | ~~Capture stdout + stderr into a log buffer for display~~ | ~~Medium~~ | ✅ Done — `LogManager` class with `LogEntry` struct, size-capped buffer (1 MB), stdout + stderr handlers in `DownloadManager`, debug window log readout |
| ~~17~~ | ~~Parse yle-dl error patterns into readable user messages~~ | ~~Medium~~ | ✅ Done — `ErrorParser` struct with `ErrorPattern` type, wired into both `fetchMetadata()` and the download stderr handler. Expand patterns as new failure modes are discovered |
| 18 | Live stream detection — inspect metadata to determine if URL is a live stream; handle indefinite `totalDuration` | Medium | Needs investigation: check yle-dl metadata output for live indicators |
| 19 | Live stream progress display — when `totalDuration` is indefinite, show elapsed time and data size instead of percentage | Medium | Depends on task #18 |
| 20 | Settings / presets system — quality, format, naming convention presets mapped to yle-dl parameters | Medium | May use a config file or `UserDefaults` |
| 21 | Overall series progress — track completed episodes vs total count for multi-episode downloads | Medium | Count-based, not time-based |
| 22 | Update checker — fetch JSON from project site, compare versions, show alert with download link | Medium | |
| 23 | Bundle yle-dl binary (PyInstaller) + static ffmpeg into app `Contents/Resources` | High | |
| 24 | Create DMG for distribution | High | |
| 42 | Replace all `DispatchQueue.main.async` and `DispatchQueue.main.asyncAfter` usage in `DownloadManager` with Swift Concurrency — `Task { @MainActor in }` and `Task.sleep(for:)` respectively | Backend | Medium |
| 43 | Fix `downloadIsCancelled` data race — the flag is written on the main thread and read from a background termination handler without protection; adding `@MainActor` to `DownloadManager` resolves this | Backend | Medium |
| 44 | Fix `fetchMetadata()` blocking the cooperative thread pool — `waitUntilExit()` inside an `async` function holds a thread hostage; replace with `withCheckedContinuation` + `terminationHandler` | Backend | Medium |
| 45 | Surface errors from silent `catch { print(error) }` blocks in `DownloadManager` — at minimum log them via `LogManager`; ideally show a user-facing alert | Backend | Low |

### New Features — Frontend

| # | Task | Complexity | Notes |
|---|------|------------|-------|
| ~~25~~ | ~~Status display — text label showing current app state (Ready / Fetching metadata / Downloading / Complete / Error)~~ | ~~Low~~ | ✅ Done — `AppState` enum with `.statusText` computed property, displayed in HStack with app title |
| ~~26~~ | ~~Cancel button — visible only during active download~~ | ~~Low~~ | ✅ Done — Download/Stop toggle button using ternary operator |
| ~~27~~ | ~~Log window — separate window for raw log display, accessible from Window menu~~ | ~~Medium~~ | ✅ Done — `LogWindow.swift` with full UI; `Window("Log Window", id: "logWindow")` scene declared in `YoloDLApp`; macOS automatically adds named Window scenes to the Window menu |
| 28 | Duplicate file overwrite prompt — confirmation dialog when existing file detected | Low | Depends on task #14 |
| 29 | File naming presets UI — Picker with mapped --output-template values | Low | |
| 30 | Settings / presets UI — quality and format selectors | Medium | Depends on task #20 |
| 31 | Live stream indicator — show different progress UI when downloading a live stream | Low | Depends on task #18 |
| 32 | Overall series progress bar | Low | Depends on task #21 |
| 33 | Advanced options panel with toggle and disclaimer | Medium | |
| 34 | Multilingual UI — Finnish + English, language toggle | Medium | |
| 36 | Arrange Download/Stop and Choose Folder buttons horizontally | Low | UI polish |
| 46 | Replace deprecated `Alert(title:message:)` API in `ContentView` with modern SwiftUI alert view builder syntax | Frontend | Low |
| 47 | Replace joined `Text` in `LogWindow` with `LazyVStack` + `ForEach` — the current approach concatenates all log entries into one giant `Text` view, which gets slower as the log grows and prevents SwiftUI from recycling off-screen rows | Frontend | Low |
| 48 | Replace `GeometryReader` in the progress bar with `containerRelativeFrame()` — `GeometryReader` is the legacy approach; `containerRelativeFrame()` is the modern API for sizing a view relative to its container | Frontend | Low |

### Suggested Build Order

A rough sequence that respects dependencies and builds on each previous step.

**~~Phase 1 — Clean up (code review fixes)~~** ✅ Complete
~~Tasks 1–8. Get the existing code solid before adding anything new.~~

**~~Phase 2 — Architecture~~** ✅ Complete
~~Tasks 9–12. Extract DownloadManager, break up functions, improve readability. This makes everything after it easier.~~

**~~Phase 3 — Core UX improvements~~** ✅ Complete
~~Tasks 13, 15, 25, 26. Remember last folder, download cancellation with Download/Stop toggle, AppState enum with status display.~~

**~~Phase 3.5 — Debug window~~** ✅ Complete
~~Moved debug controls into separate `DebugWindow.swift` with its own `Window` scene. `DownloadManager` lifted to App struct level with `.environmentObject()`. Debug window auto-opens via `openWindow(id:)` in `#if DEBUG`.~~

**Phase 4 — Error handling & logging** (in progress)
~~Task 16:~~ `LogManager.swift` with `LogEntry` struct (Identifiable, timestamped, source-labeled) and `LogManager` class (ObservableObject, size-capped buffer at 1 MB). Stdout + stderr handlers wired into `DownloadManager`. `LogManager` injected at App struct level via `.environmentObject()`. ~~Task 35:~~ Debug functions moved to `#if DEBUG` extension in `DebugWindow.swift` with helper methods in `DownloadManager`. Timer leak fix. ~~Task 17:~~ `ErrorParser` struct with `ErrorPattern` type, wired into both metadata fetch and download stderr handler. ~~Task 27:~~ `LogWindow.swift` with `LazyVStack` log display, entry counter, Copy Log and Clear Log buttons; `Window` scene declared in `YoloDLApp`. Remaining: Tasks 42, 43, 44, 45, 46, 47.

**Phase 5 — File management**
Tasks 14, 28, 29. Duplicate detection, overwrite prompts, naming presets. Makes downloads more robust. Also: Task 48 (replace `GeometryReader` with `containerRelativeFrame()`).

**Phase 6 — Live streams & multi-episode**
Tasks 18, 19, 31, 21, 32. Handle edge cases for live and series content.

**Phase 7 — Settings & advanced options**
Tasks 20, 30, 33. Presets system and advanced panel.

**Phase 8 — Polish & distribution**
Tasks 34, 22, 23, 24. Localization, update checker, bundling, DMG.

---

### Code hygiene tasks (slot in between phases as convenient)

These are small, self-contained fixes from the v0.09 code review (9 March 2026). None are blockers, but they improve code quality and should be cleared before the codebase grows further.

| # | Task | Area | Phase suggestion |
|---|------|------|-----------------|
| 37 | Move `AlertMessage` to its own file | Frontend | Before Phase 5 |
| 38 | Move `#if DEBUG` extension to `DownloadManager+Debug.swift` | Backend | Before Phase 5 |
| 39 | Extract `handleDownloadButton()` method in `ContentView` | Frontend | Before Phase 5 |
| 40 | `downloadActiveColors` / `downloadFinishedColors`: `var` → `let` | Frontend | Before Phase 5 |
| 41 | Remove duplicate `progressBarFinishedSpeed` from `ContentView` | Both | Before Phase 5 |
| 50 | Rename `duration_seconds` → `durationSeconds` + `CodingKeys` | Backend | Before Phase 5 |

**Task 49 — `@Observable` migration** is listed here for visibility, but it is a larger architectural change that touches every file. Recommended timing: after Phase 4 is complete and before Phase 5 begins, as a dedicated refactor session.
