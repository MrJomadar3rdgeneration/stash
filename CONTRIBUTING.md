# Contributing

Stash is a native macOS utility. Keep changes focused and describe the user-visible problem, the fix, and the checks you ran.

## Setup

Use macOS 14.5+ and Swift 6+ (Xcode 16+ or compatible Command Line Tools).

```sh
swift run StashChecks
./scripts/build.sh
open build/Stash.app --args --demo
```

The app uses SwiftUI, AppKit, CryptoKit, Keychain, Carbon hotkeys, and ServiceManagement. There are no third-party dependencies. `StashCore` holds format capture/replay, encrypted record encoding, search, and retention rules. `Stash` owns UI, monitoring, and local persistence.

Checks use isolated named pasteboards, never the general clipboard. Add meaningful regression checks for behavior changes. Use demo mode for screenshots and UI checks so real clipboard history is not exposed. Demo copy buttons still change the system clipboard when clicked.

Never commit local vault records, Keychain exports, signing credentials, or screenshots containing personal history. Avoid changing clipboard privacy defaults without explicitly describing the tradeoff.

Before updating your installed copy, quit Stash, build and check the new bundle, retain a backup, then replace the app in Applications. Ad-hoc builds can trigger a Keychain reapproval prompt. Never delete or replace the vault key to suppress the prompt.

## UX and compatibility testing

Test changes with fictional clipboard content in at least two unrelated apps, such as a browser and a text editor. Cover keyboard navigation, a normal window appearing above Stash, closing and reopening the window, and the affected clipboard formats. If a change touches startup, verify both manual launch and Launch at login. Mention the macOS version and Mac architecture in the pull request.

CI artifacts are development builds for testing. They are not signed, notarized, or intended as user-facing downloads.
