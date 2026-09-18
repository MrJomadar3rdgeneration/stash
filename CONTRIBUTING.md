# Contributing

Stash is an early macOS utility. Keep changes focused and describe the user-visible problem, the fix, and the checks you ran.

## Setup

Use macOS 14+ and Swift 6+ (Xcode 16+ or compatible Command Line Tools).

```sh
swift run StashChecks
./scripts/build.sh
open build/Stash.app --args --demo
```

The app uses SwiftUI, AppKit, CryptoKit, Keychain, Carbon hotkeys, and ServiceManagement. There are no third-party dependencies. `StashCore` holds format capture/replay, encrypted record encoding, search, and retention rules. `Stash` owns UI, monitoring, and local persistence.

Checks use isolated named pasteboards, never the general clipboard. Add meaningful regression checks for behavior changes. Use demo mode for screenshots and UI checks so real clipboard history is not exposed. Demo copy buttons still change the system clipboard when clicked.

Never commit local vault records, Keychain exports, signing credentials, or screenshots containing personal history. Avoid changing clipboard privacy defaults without explicitly describing the tradeoff.

Before updating your installed copy, quit Stash, build and check the new bundle, retain a backup, then replace the app in Applications. Ad-hoc builds can trigger a Keychain reapproval prompt. Never delete or replace the vault key to suppress the prompt.

See RELEASE_CHECKLIST.md for the remaining release gates. CI artifacts are development builds, not notarized releases.
