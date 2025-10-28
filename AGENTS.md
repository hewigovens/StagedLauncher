# Repository Guidelines

## Project Structure & Module Organization
- `StagedLauncher/` — app source code.
  - `View/` SwiftUI views (e.g., `ContentView.swift`).
  - `ViewModel/` view models (e.g., `ContentViewModel.swift`).
  - `Model/`, `Service/` app logic (e.g., `NotificationService.swift`).
  - `Coordinators/` navigation/setup.
  - `Assets/Assets.xcassets` images and app icons.
  - `Misc/` shared utilities (`Logger.swift`, `Constants.swift`).
  - `Protocol/` shared protocols (`ErrorPresentable.swift`).
- `StagedLauncher.xcodeproj/` — Xcode project.
- `docs/` — website and screenshots.

## Build, Test, and Development Commands
- Open in Xcode: `open StagedLauncher.xcodeproj`
- Debug build: `xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher -configuration Debug build`
- Release build: `xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher -configuration Release -derivedDataPath build`
- Run built app: `open build/Build/Products/Debug/StagedLauncher.app`
- Tests (when added): `xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher test -destination 'platform=macOS'`

## Coding Style & Naming Conventions
- Swift 5; 4‑space indentation; one type per file; add a trailing newline.
- Names: `PascalCase` types, `camelCase` members. Suffixes: `View`, `ViewModel`, `Service`, `Coordinator`.
- Keep files in the matching folder (e.g., new views → `View/`).
- Use `// MARK:` sections and prefer small, focused types. Avoid gratuitous reformatting.

## Testing Guidelines
- Framework: XCTest. Place tests under `StagedLauncherTests/` (or `Tests/StagedLauncherTests/`).
- Naming: mirror type under test (e.g., `ManagedAppStoreTests.swift`).
- Aim for logic in `Service/` and `ViewModel/` to be unit‑tested; UI tests optional.

## Commit & Pull Request Guidelines
- Commit messages: imperative mood, present tense (e.g., `Add NotificationService`, `Remove Sparkle for MAS`). Keep subject ≤72 chars; add body for rationale.
- Prefer a scope in the subject when helpful: `View:`, `Service:`, `Docs:`.
- PRs: include a clear description, linked issues, and screenshots for UI changes. Note any entitlement or user‑facing changes.

## Security & Configuration Tips
- Changes to `StagedLauncher.entitlements` require review. Do not commit signing identities or secrets.
- Follow App Sandbox best practices; minimize capabilities. Validate login‑item behavior.

## Agent‑Specific Instructions
- Keep patches small and targeted. Do not rename or reorganize folders without discussion.
- Match existing patterns and suffixes; update `docs/` if behavior changes.
- Validate with `xcodebuild` locally; avoid introducing new tooling without consensus.

