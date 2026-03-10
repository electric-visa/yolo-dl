---
paths:
  - "**/*.swift"
---

# Swift & SwiftUI Rules

- Target Swift 6.2+ with modern concurrency
- Prefer SwiftUI over UIKit/AppKit unless necessary
- Break types into separate files — no multiple structs/classes/enums in one file
- Use `@Observable` + `@MainActor` over `ObservableObject` / `@Published` (migration pending — task 49)
- Use `foregroundStyle()` not `foregroundColor()`
- Use `containerRelativeFrame()` over `GeometryReader` where possible
- Use modern SwiftUI alert syntax over deprecated `Alert(title:message:)`
- Properties: camelCase (rename `duration_seconds` → `durationSeconds` is pending — task 50)
- No third-party frameworks without asking first
