# Release readiness

## Current target: public source beta, not a general-release binary

The repository can be shared as an early source beta after local checks complete. It must not be described as universally compatible, independently security-audited, or a notarized production release.

Before uploading source:

- [x] MIT license selected by the owner.
- [x] Include build, privacy, contribution, and bug-report documentation.
- [x] Ignore vault files, local builds, environment files, and signing credentials.
- [x] CI checks production capture/replay code on isolated pasteboards.
- [x] Archive `.app` bundles before uploading CI artifacts to preserve permissions.
- [x] Run the local checks and record results in VALIDATION.md.
- [x] Reporter confirmed the menu-bar icon is visible after updating.
- [x] Prepare the public source repository at `MrJomadar3rdgeneration/stash` under MIT.

Before recommending a binary release to non-developers:

- [ ] Verify supported macOS versions (minimum target 14) on real machines.
- [ ] Test Apple Silicon and Intel; build scripts currently target the builder's architecture.
- [ ] Verify Chrome, Safari, Firefox, TextEdit, screenshots, Finder multi-file copies, and excluded apps in real sessions.
- [ ] Test sleep/wake, Low Power Mode, login startup, shortcut conflicts, direct paste, and both granted/denied permissions.
- [ ] Exercise large histories and error paths: full disk, locked Keychain, damaged vault records.
- [ ] Configure Developer ID signing, hardened runtime, notarization, and stable update signing.
- [ ] If automatic updates are desired, configure a trusted update feed and signed releases. None exists today.
- [ ] Run GitHub CI, enable private vulnerability reporting, and agree who maintains releases.

Never include the user's history, Keychain, local preferences, or personal screenshots in a release or bug report.
