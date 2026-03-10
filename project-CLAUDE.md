# YoloDL

Native macOS SwiftUI GUI wrapper for the `yle-dl` command-line tool. Targets non-technical Finnish users who want to download Yle Areena content without the terminal.

## Tech Stack

- **Language:** Swift, **Framework:** SwiftUI
- **Minimum target:** macOS 14 Sonoma
- **Distribution:** Self-hosted (no App Store, no notarization), GPLv3
- **CLI tools:** `yle-dl`, `ffmpeg`, `ffprobe` (Homebrew in dev; bundled in release)
- **Git:** Private repo over SSH on VPS (`~/git/yle-dl-gui.git`)

## Architecture

- `DownloadManager` — `ObservableObject` managing download state, injected at App struct level via `.environmentObject()`
- `LogManager` — `ObservableObject` with size-capped buffer (1 MB), stdout + stderr capture
- `ErrorParser` — struct with pattern → message mapping for yle-dl errors
- `EpisodeMetadata` — separate file, decoded from yle-dl JSON output
- `ContentView` — main UI; `LogWindow` and `DebugWindow` — separate `Window` scenes

## Key Conventions

- App Sandbox is disabled (required for `Process` to find Homebrew binaries)
- `yle-dl` requires explicit `--ffmpeg`, `--ffprobe`, and `--destdir` arguments
- Binary paths (`/opt/homebrew/bin/`) are temporary dev shortcuts; release uses `Bundle.main.resourcePath`
- Commit to Git after each task or small group of tasks with descriptive messages
- Follow Apple Human Interface Guidelines for UI decisions
- Follow Swift/SwiftUI best practices ("the SwiftUI way")

## Current Status

- **Version:** v0.09
- **Completed:** Phases 1–3, plus Phase 4 tasks 16, 17, 27, 35
- **In progress:** Phase 4 remainder (tasks 42–47)
- **Next:** Code hygiene tasks 37–41, 49–50, then Phase 5
- See `YoloDL-design-plan-2-4.md` in project root for full task list and build order

## Commands

- **Build:** Cmd+B in Xcode (or `xcodebuild` from CLI)
- **Run:** Cmd+R in Xcode
