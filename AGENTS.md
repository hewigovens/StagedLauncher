# Staged Launcher

macOS utility that launches the user's apps a set delay after login instead of all at once. Swift 5 and SwiftUI, sandboxed, macOS 14.6+.

## Start Here

This file defines repository constraints for any coding agent. Load only the focused guide the task needs.

Within the authorized scope, choose the approach from the code and evidence. Resolve routine implementation choices yourself; ask when missing information changes the intended behavior, scope, or permission.

| Task | Load |
| --- | --- |
| source layout, views, view models, project file | [SwiftUI](agents/swiftui.md) |
| build, run or drive the app, capture screenshots | [Run & Debug](agents/run-debug.md) |
| version bump, notarize, GitHub release, Homebrew tap | [Release](agents/release.md) |

## Task Authority

- Investigation and diagnosis are read-only unless the user also asks for implementation. Report the cause, evidence, and smallest viable fix.
- Code review is findings-only by default. Fix only when asked.
- Implementation does not authorize commit, bookmark movement, push, pull-request or release actions. Publication needs a separate request and the [Release](agents/release.md) guide.
- Report evidence as separate claims: build, tests, real UI behavior, signing and notarization. One does not imply the next. Name the command behind each claim and list what was skipped or blocked.

## Feature Loop

Order: understand → implement → focused validation → cleanup → revalidate → prove → describe.

A task is not done without proof matched to what changed, shown or linked in the final report. A build proves only that it compiles.

- **Behavior or bug fix:** the failing scenario now passing, reproduced in the running app or a test.
- **User-visible UI:** a screenshot of the running app; see [Run & Debug](agents/run-debug.md#screenshots).
- **Documentation:** the diff plus link and command checks.

Keep proof files outside source, in the session scratchpad.

Before saying done, re-read the whole diff twice: delete what the change left dead, reuse helpers and patterns nearby code already has, and cut comments that restate code. Re-run the affected validation after cleanup edits.

### Inner loop

```bash
xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher -configuration Debug build
```

There is no test target yet. When one is added, tests go under `StagedLauncherTests/`, named after the type under test, and cover logic in `Service/` and `ViewModel/`.

## User-Facing Docs

Feature work does not update `README.md` or `docs/` (website and screenshots). Those are refreshed in one pass at release; see [Release](agents/release.md). An explicit documentation request authorizes edits to the requested docs.

Update `agents/*.md` in a feature change only when the contributor contract changed. A guide step that misled you is a contract bug: fix it in the same change.

## Principles

1. **First principles** - Understand the problem and the existing behavior before coding.
2. **Behavior belongs to types** - Prefer extensions and computed properties over free helper functions.
3. **Comments explain the why** - Default to no comment. Comment only a non-obvious reason or constraint.
4. **Test behavior, essentials only** - Bug fixes add the regression test that would have caught them once a test target exists. Do not add tests that mirror constants or wiring.
5. **Small patches** - Keep changes targeted. Do not rename or reorganize folders, or add tooling, without discussion.

## Version Control

This repo uses **Jujutsu (jj)** colocated with git. Use `jj` for history; do not use `git commit`, `git add`, `git push`, or `git stash`.

- Describe a finished change with `jj describe`. Subjects are imperative and at most 72 characters, with a scope when helpful (`View:`, `Service:`, `Docs:`); add a body for rationale.
- For work that should not disturb this checkout, use a sibling workspace: `jj workspace add --name <topic> -r 'main@origin' ../<topic>`.
- `jj st`, `jj log`, `jj diff` and `jj describe` snapshot the working copy. Do not run two in parallel in one workspace; use `jj --ignore-working-copy` for reads that must not snapshot.
- Do not add AI attribution to commits or PRs unless the user asks.
- PRs include a description, linked issues, and screenshots for UI changes. Note any entitlement or user-facing change.

## Security

- Changes to `StagedLauncher.entitlements` require review. Keep sandbox capabilities minimal.
- Never commit signing identities, credentials, or `ExportOptions.plist`.
- Validate login-item behavior after touching `LoginItemService` or `LoginItemHelper`.
