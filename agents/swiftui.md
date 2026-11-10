# SwiftUI Guide

Load this file before changing views, view models, or the Xcode project.

## Layout

`StagedLauncher/` is a synchronized folder in `StagedLauncher.xcodeproj`, so adding, moving, or deleting a file needs no project edit.

| Folder | Holds |
| --- | --- |
| `View/` | SwiftUI views (`ContentView`, `EmptyStateView`, `SettingsView`) |
| `ViewModel/` | view models (`ContentViewModel`) |
| `Model/` | `ManagedApp` and its store |
| `Service/` | launching, login items, menu bar, notifications |
| `Coordinators/` | long-lived object wiring and the launch session |
| `Misc/`, `Protocol/` | constants, logging, shared protocols |
| `Assets/Assets.xcassets` | images and app icons |

- One type per file, named after the type, in the matching folder. Suffixes: `View`, `ViewModel`, `Service`, `Coordinator`.
- Four-space indentation, `// MARK:` sections, trailing newline. No gratuitous reformatting.
- User-facing strings go through `String(localized:)` or SwiftUI text literals.

## Project file

`StagedLauncher.xcodeproj/project.xcproj` is the checked-in JSON project format and needs Xcode 27 or later. Edit it in Xcode or by hand, then keep it canonical:

```bash
xcrun xcprojformatter --update StagedLauncher.xcodeproj
```

`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` each appear once, in the target's `build-settings`.

## Pitfalls

- **Main window lifetime.** The app has a single `Window` scene, which SwiftUI quits when closed. `AppDelegate.applicationShouldTerminateAfterLastWindowClosed` returns `false` so pending launches still fire. Keep it.
- **Detail column root.** Keep the `List` as the root of the `NavigationSplitView` detail, and show the empty state as an overlay. A non-scrolling root is sized to its content, which leaves the `safeAreaInset` footer floating mid-window.
- **Menu bar mode.** `showMenuBarIcon` switches the activation policy to `.accessory`; changing it deactivates the app, so reactivate afterwards.
- **Bookmarks.** App references are security-scoped bookmarks tied to the bundle identifier that created them. A build with another bundle identifier cannot resolve them.
