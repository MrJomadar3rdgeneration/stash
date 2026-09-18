# Local validation — 2026-09-18

- Release app built and ad-hoc signed successfully on this Apple Silicon Mac with the installed Swift 6.4 Command Line Tools / macOS 27 SDK.
- Eight automated checks passed in a debug executable. Pasteboard checks used an isolated named pasteboard, not the general clipboard.
- Native window visually inspected at 1040 × 680; sidebar, history, preview, and footer render without clipping.
- Demo search for “design” returned the two matching clips; Down selected the next result and updated the preview.
- Inline editor and Settings controls opened successfully.
- Normal app startup unlocked its Keychain-backed vault.
- A test snippet copied using TextEdit automation was captured. The foreground app was Finder during automation, demonstrating the documented source-attribution limitation.
- ⌘⇧V opened history from another app.
- The captured clip survived quitting and restarting Stash.
- Return restored the saved clip successfully and displayed copy confirmation.

Not yet verified: direct paste with Accessibility, login launch, minimum macOS 14 runtime, browser-by-browser format compatibility, file promises, large-history performance, shortcut collision recovery through UI, distribution signing/notarization, or the GitHub CI runner.

## 0.2.0 follow-up

- Updated release built, signed, and passed all eight checks in the release executable.
- Installed app verified at `/Applications/Stash.app`; original development `.app` moved out of the build folder.
- User approved the macOS Keychain prompt; the installed app loaded all three existing clips and their pinned state.
- Settings showed version 0.2.0 and Launch at login enabled after registration through ServiceManagement.
- The close-window action left the process running. The window now uses `.normal` rather than `.floating` ordering.
- Idle sampling: six post-baseline `top` samples over approximately 31 seconds displayed 0.0% CPU and ~35 MB memory with three small clips. See ENERGY.md for scope and caveats.
- Login registration was verified without rebooting or logging the user out. A full login cycle and sleep/Low Power Mode transitions still need real-session verification. No whole-battery discharge benchmark was performed.
- Direct paste, distribution signing, notarization, automatic updates, and the broader compatibility matrix remain as previously noted; no promise of universal compatibility or unattended future maintenance.


## 0.3.0 readiness review

- The owner reported successful reboot/login startup and background capture without manually opening Stash.
- macOS Menu Bar settings were inspected: Stash was already allowed. Version 0.3.0 explicitly recreates a visible status item with a stable identity and correctly sized template icon. The owner confirmed that the icon is now visible.
- Installed update unlocked the existing vault after the owner approved Keychain access; six clips and two pins remained intact.
- Native UI checks clicked blank portions of sidebar rows, not text/icons: right-side Pinned, left-edge Links, right-side Images and Files, and left-edge All clips all changed the active filter correctly.
- Twelve checks passed against shared production capture/replay code. Added real PNG round trips, RTF/HTML previews, plain-text replay, link classification, second-item confidential markers, excluded sources, oversized records, and preserving the clipboard after invalid replay requests.
- MIT license was selected by the owner. Added contribution/security documents, a privacy-aware issue template, credential/history ignore rules, explicit release gates, and ZIP packaging for CI bundles.
- A pattern scan of the publishable source files found no matching private-key, GitHub-token, AWS-key, or API-key patterns. Runtime history and Keychain data remain outside the repository. This is a limited pattern scan, not proof against every possible secret.
- No GitHub repository was created, no remote configured, and no files uploaded. CI has not been exercised on GitHub.

Final shortcut UI verification passed: accessibility activation opened the recorder, Escape cancelled while retaining the existing combination, and the restored global hotkey reopened history. Login launch remained enabled and the installed app was capturing new clips.

Readiness: ready to share as a documented source beta. A generally recommended binary release still requires the compatibility and signing/notarization gates in RELEASE_CHECKLIST.md.
