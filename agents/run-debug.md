# Run & Debug Guide

Load this file to build, launch, or drive the app, or to capture screenshots.

## Building

```bash
xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher -configuration Debug build
```

CI runs the same Debug build on the `xcode-27` runner with `CODE_SIGNING_ALLOWED=NO`.

## Running

A build with the real bundle identifier shares the installed app's sandbox container, so launching it has side effects:

- It starts a launch session: every enabled app opens after its delay.
- With "Quit after all apps have launched" on, it then quits itself.
- With "Show in menu bar instead of Dock" on, it has no Dock icon.

Quit any running instance first, and tell the user before launching against their data.

For an empty, isolated instance, build under another bundle identifier into the scratchpad:

```bash
xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher -configuration Debug \
  -derivedDataPath "$SCRATCH/dd" PRODUCT_BUNDLE_IDENTIFIER=dev.hewig.StagedLauncher.verify build
open -n "$SCRATCH/dd/Build/Products/Debug/Staged Launcher.app"
```

It starts with no apps and default settings. Afterwards quit it and remove `~/Library/Containers/dev.hewig.StagedLauncher.verify`.

Both builds are named `Staged Launcher`; target one by PID (`pgrep -f "<derived data path>/.*Staged Launcher"`), never by name.

## Driving the window

- Resize, activate, and close through System Events by PID; this needs Accessibility permission for the terminal. Refer to `window 1` inline in each statement; a stored window reference goes stale.
- Find the window ID with `CGWindowListCopyWindowInfo` filtered by owner PID.
- Never send synthetic clicks at screen coordinates while the user is active.

## Screenshots

Capture only the app's window, never a screen region, which picks up the user's other windows:

```bash
screencapture -x -o -l <windowID> out.png
```

Activate the app first, or the capture shows the dimmed inactive state. Review every image before using it.

README and website screenshots live in `docs/assets/`:

| File | Shows | Size |
| --- | --- | --- |
| `main_window.png` | main window with the real app list, a 900×450 pt window | 1800×900 |
| `running_apps_window.jpg` | the Add from Running Apps sheet | 1280×800 |
| `notifications.png` | launch notifications | 754×568 |

`main_window.png` needs the real bundle identifier, because the isolated build cannot resolve the app list's bookmarks. Launch, capture, and quit within the shortest configured delay so no staged launch fires. When a capture's size or content changes, update the `width`, `height`, and `alt` attributes in `docs/index.html`.
