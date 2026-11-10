# Contributing to StagedLauncher

## Requirements

- Xcode 16.0 or later
- macOS 14.6+

## Development setup

1. Clone the repository or click "Open With Xcode"
2. Build and run the app

## Releasing

Releases are a notarized `Staged.Launcher.zip` attached to a GitHub release, plus a
cask bump in the Homebrew tap ([hewigovens/tap](https://github.com/hewigovens/tap),
checked out next to this repository as `../tap`). Tags are the bare version, e.g. `1.0.3`.

1. **Bump the version.** Set `MARKETING_VERSION` and increment `CURRENT_PROJECT_VERSION`
   for both configurations in `StagedLauncher.xcodeproj/project.pbxproj`. Commit it as
   `Bump version to X.Y.Z (N)` (or as a line in the commit that carries the changes) and
   push `main`. Wait for CI to pass.

2. **Build the notarized app.** Archive, then submit for Developer ID notarization.
   This needs the Developer ID certificate in the keychain and the team's account
   signed in to Xcode:

   ```bash
   xcodebuild -project StagedLauncher.xcodeproj -scheme StagedLauncher \
     -configuration Release -archivePath build/StagedLauncher.xcarchive archive
   xcodebuild -exportArchive -archivePath build/StagedLauncher.xcarchive \
     -exportOptionsPlist ExportOptions.plist -exportPath build/export \
     -allowProvisioningUpdates
   ```

   `ExportOptions.plist` (not checked in) sets `method` to `developer-id`,
   `destination` to `upload` and `signingStyle` to `automatic`. Notarization usually
   takes under a minute; then fetch the stapled app (retry until it succeeds) and
   check it:

   ```bash
   xcodebuild -exportNotarizedApp -archivePath build/StagedLauncher.xcarchive \
     -exportPath build/notarized
   cd build/notarized
   spctl -a -vv "Staged Launcher.app"        # source=Notarized Developer ID
   xcrun stapler validate "Staged Launcher.app"
   ```

   Xcode's Organizer does the same through Distribute App → Direct Distribution.

3. **Zip it.** The cask URL expects the asset name `Staged.Launcher.zip`:

   ```bash
   ditto -c -k --keepParent "Staged Launcher.app" Staged.Launcher.zip
   ```

4. **Publish the GitHub release.** This creates the tag on `main`:

   ```bash
   gh release create X.Y.Z Staged.Launcher.zip --target main --title X.Y.Z --notes-file notes.md
   ```

   Write the notes as user-facing bullets and end them with
   `**Full Changelog**: https://github.com/hewigovens/StagedLauncher/compare/PREVIOUS...X.Y.Z`.
   If a draft already exists, upload and publish it instead:

   ```bash
   gh release upload X.Y.Z Staged.Launcher.zip
   gh release edit X.Y.Z --draft=false
   ```

5. **Update the tap.** In `../tap/Casks/staged-launcher.rb`, set `version` and the
   `sha256` of the published asset:

   ```bash
   curl -sL https://github.com/hewigovens/StagedLauncher/releases/download/X.Y.Z/Staged.Launcher.zip | shasum -a 256
   ```

   The tap is a Jujutsu repository:

   ```bash
   cd ../tap
   jj commit -m "staged-launcher X.Y.Z (build N)"
   jj bookmark move main --to @-
   jj git push
   ```

6. **Verify the install.**

   ```bash
   brew update
   brew fetch --cask hewigovens/tap/staged-launcher   # checks the sha256
   brew upgrade --cask staged-launcher
   ```
