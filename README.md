<p align="center"><img src="docs/stash-icon.png" width="96" height="96" alt="Stash icon"></p>

# Stash

**A quiet, keyboard-first clipboard manager for your Mac.**

Stash remembers what you copy, helps you find it again, and keeps your history encrypted on your Mac. Built with SwiftUI and AppKit, with no account, analytics, cloud service, or third-party dependencies.

> **Early source beta · v0.3.0**
> Tested locally on Apple Silicon. The app targets macOS 14+, but the full macOS, hardware, and destination-app compatibility matrix is not yet verified. There is no notarized public binary or automatic updater yet. See [release readiness](RELEASE_CHECKLIST.md).

## Features

- **Automatic history:** capture text, links, rich HTML/RTF, PNG/TIFF images, and file references from the system clipboard.
- **Keyboard-first access:** a customizable global shortcut, instant search, and arrow-key navigation.
- **Useful organization:** format filters, previews, permanent pins, individual deletion, and clear-history controls.
- **Editable snippets:** edit saved text directly; edited clips are saved as plain text.
- **Local privacy:** AES-GCM encrypted history, a Keychain-held key, app exclusions, confidential-content filtering, and capture pause.
- **Mac integration:** a menu-bar icon, quiet launch at login, and optional direct paste to the previous app.

## Requirements

| Requirement | Details |
| --- | --- |
| Operating system | macOS 14 or later |
| Build tools | Swift 6 or later; Xcode 16+ or compatible Apple Command Line Tools |
| Architecture | Builds for the current Mac; the script does not produce a universal binary |
| Dependencies | Apple frameworks only; no external package downloads |

The current local build has been checked on Apple Silicon. Intel and older supported macOS versions still need real-machine verification.

## Install from source

1. Install compatible Apple development tools. Check that `swift --version` reports Swift 6 or later. If Command Line Tools are missing, run `xcode-select --install` and follow Apple's installer.
2. Download this repository using **Code → Download ZIP**, or clone it:

   ```sh
   git clone https://github.com/MrJomadar3rdgeneration/stash.git
   cd stash
   ```

3. Run the checks and build the app:

   ```sh
   swift run StashChecks
   ./scripts/build.sh
   ```

4. In Finder, open the repository's `build` folder and move **Stash.app** to **Applications**. Quit any older copy first. Keep a backup when replacing an existing installation.
5. Open **Applications → Stash**. Keep only one copy running. Enable login launch and grant optional permissions only after installing it in its final location.

The build is locally **ad-hoc signed**, not Developer ID signed or notarized. CI artifacts are development builds too. Do not treat them as vetted consumer releases or disable macOS security protections to run an unknown download.

## Your first clip

1. Leave Stash running in the menu bar.
2. In another app, copy some harmless text or a link with **⌘C**.
3. Press **⌘⇧V**, or click Stash's overlapping-squares icon in the top-right menu bar.
4. Type a word in the search field. Use **↑ / ↓** to select a result.
5. Press **Return** or click **Copy clip**.
6. Switch to your destination app and press **⌘V**.

By default, Stash restores the clip to your clipboard. It does **not** automatically type or paste into another app. Existing clipboard content from before launch is not imported; capture starts with subsequent changes.

### Search and organize

- **All clips** shows your history. **Pinned** shows saved favorites. **Text / Links / Images / Files** filter by format. The entire sidebar row is clickable.
- Search matches all entered words, ignoring case and accents, across saved text, file paths, source-app names, and format labels. Images do not have OCR search.
- Click the pin button or press **⌘P** to keep a clip permanently. Pins survive automatic retention cleanup.
- Use **Edit** on a text or link clip, make changes, then **Save changes**. This replaces its rich-format representations with plain text.
- Delete one clip with its trash button or **⌘⌫**. Individual deletion has no undo.
- The **…** menu above the list can clear unpinned history or delete everything, including pins. These actions ask for confirmation and cannot be undone. They do not clear the macOS system clipboard.

### Customize the shortcut

Open **Settings → Open history**, click the shortcut button, and press your preferred combination. Include **⌘**, **⌃**, or **⌥** with a key. Press **Escape** to cancel recording and keep the previous shortcut. If another app owns the combination, choose a different one.

### Optional direct paste

Turn on **Settings → Paste directly into the previous app**, then use **Allow Accessibility…** to grant Stash access in macOS **Privacy & Security → Accessibility**.

With this enabled, Return restores the clip, activates the previously used app, and sends **⌘V**. Without permission, Stash falls back to copying and shows a message. Protected fields and some applications may reject simulated paste; manual **⌘V** remains the fallback. Accessibility is not required for basic capture/search/copy. Stash itself does not request Screen Recording permission.

### Launch at login and background behavior

Enable **Settings → Launch at login**. Stash then starts quietly after you sign into macOS, including after restarting your Mac. It does not run before login or open the history window automatically at login.

- Closing the **red window button** leaves menu-bar capture running.
- **Pause capture** stops polling without deleting saved history; click **Resume capture** to continue.
- Right-click the menu-bar icon for Open, Pause/Resume, and Quit.
- **Quit Stash** stops the app until the next manual launch or login.
- The history window has normal window ordering; other apps can appear in front of it.

## Keyboard shortcuts

These history actions apply while the main history window is focused, outside Settings or the inline editor.

| Shortcut | Action |
| --- | --- |
| **⌘⇧V** (customizable) | Open/hide history from any app |
| **↑ / ↓** | Select the previous/next result |
| **Return** | Copy the selection, or paste if direct paste is enabled |
| **⇧Return** | Copy/paste the plain-text representation |
| **⌘P** | Pin/unpin the selected clip |
| **⌘⌫** | Delete the selected clip |
| **Escape** | Hide history |
| **⌘,** | Open Settings |
| **⌘Q** | Quit Stash |

## Privacy and storage

**Stash is not a password manager. Do not pin passwords, API keys, or recovery codes.**

The app skips clipboard content marked confidential or transient, plus content copied while an excluded app is in front. Several password managers are excluded by default. In **Settings → Privacy**, add one application bundle identifier per line, such as `com.example.MyApp`. Find an app's identifier in its bundle's `Contents/Info.plist` under `CFBundleIdentifier`.

Exclusions apply to future copies; delete previously captured content separately. Browser extensions can copy unmarked secrets under the browser's identity. Exclude the whole browser when that risk is unacceptable. Foreground-app attribution can be inaccurate during rapid switching or background automation.

| Data | Location |
| --- | --- |
| Encrypted clips, metadata, and pin state | `~/Library/Application Support/Stash/*.stash` |
| Encryption key | Your login Keychain; service `com.stash.clipboard.vault` |
| Preferences | macOS UserDefaults domain `com.stash.clipboard`, managed under `~/Library/Preferences/` |
| Runtime resources | Inside `Stash.app` |

Stash has no network client or cloud sync. Apple Universal Clipboard and your backup software operate independently. Encryption protects history files at rest, not an unlocked session from malicious software, screenshots, process-memory inspection, or an authorized Keychain reader. Deleting a file is not guaranteed secure erasure from SSDs or backups. Read [SECURITY.md](SECURITY.md).

### Retention and capacity

Defaults are **30 days** and **1,000 clips**. Settings support 500–10,000 clips, several age limits, or no age limit. Automatic cleanup removes unpinned history when age, count, or the **250 MB payload budget** is exceeded. Reducing limits applies immediately.

Pins are exempt and can exceed those limits. A single snapshot larger than **20 MB** is skipped. Disk usage may exceed the payload budget because encrypted JSON uses base64 and metadata. Identical copies are refreshed to the top, preserving the existing pin and original source metadata.

File clips store references, not archived file contents. Moving or deleting the original file can break a later paste. Lazy file-promise providers cannot be saved and are skipped. Private app-specific formats may not replay outside their source app.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| Menu-bar icon missing | Open Stash from Applications or use the shortcut. Choose **Settings → Restore menu-bar icon**. On macOS versions offering it, enable Stash under **System Settings → Menu Bar → Allow in the Menu Bar**. A crowded menu bar can still hide items. |
| Nothing new appears | Check that capture is not paused and the source app is not excluded. Copy new content in another app. Capture also needs the local vault to be unlocked. |
| Keychain prompt after an update | Confirm that the prompt is for your installed Stash. Local ad-hoc signing can require reapproval after executable changes. Complete the prompt yourself. Never delete or replace the key to bypass it. |
| “Vault unavailable” or empty history during unlock | Finish the Keychain prompt. If access was denied or an error persists, resolve the Keychain issue and restart Stash. Existing encrypted history is preserved. |
| Shortcut unavailable | Record a different combination. Quit duplicate copies of Stash and check other apps' shortcut settings. |
| Direct paste fails | Check Accessibility for the installed app, or use normal Copy followed by manual **⌘V**. Rebuilt binaries may need renewed permission. |
| Copies missed during sleep or pause | Monitoring is suspended during system/display sleep and inactive login sessions. Resuming skips changes made while suspended. Polling can also miss rapid overwrites or be delayed by App Nap. |
| History fails to save/delete | Check the displayed error and available disk space. Save failures pause capture. Undecryptable records are preserved and reported. No recovery/export UI is available yet. |

If you file a bug, use fictional content and redact screenshots. Never upload clipboard history, Keychain exports, or credentials.

## Battery and memory

Idle resource use should be evaluated against your workload. One local 31-second observation with three small clips showed approximately **35 MB RAM** and **0.0% displayed CPU** at the sampling tool's precision. This does not mean zero power use or establish a battery-per-hour percentage.

Stash checks for clipboard changes about every **0.5 seconds**, or **1 second in Low Power Mode**, with timer tolerance to combine wake-ups. Polling stops while paused, asleep, or in an inactive login session. It holds no keep-awake assertion. Large images, long text, frequent copying, and large histories require more work; history is decoded into RAM. See [ENERGY.md](ENERGY.md) for measurement details and limits.

## Development and verification

```sh
swift run StashChecks
./scripts/build.sh
```

The twelve checks exercise authenticated encryption, tamper/wrong-key rejection, retention, pins, search, fingerprints, and the actual production capture/replay path for HTML, RTF, links, PNG images, and multiple files. They also check plain-text replay, confidential content in later pasteboard items, exclusions, size limits, and preserving the clipboard after invalid replay requests. All clipboard checks use **isolated named pasteboards**, never your general clipboard.

For fictional UI preview data, quit the normal app and run:

```sh
open build/Stash.app --args --demo
```

Demo mode does not read your vault or monitor the clipboard. Its copy buttons still change the system clipboard if clicked. Quit demo mode before opening normally.

The GitHub workflow builds, runs checks, and archives the app while preserving bundle metadata. Local validation is documented in [VALIDATION.md](VALIDATION.md); broader release gates are in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). Passing checks does not guarantee compatibility with every app or macOS version.

## Updating, contributing, and removing Stash

There is no automatic updater. For a local update, quit Stash, build and verify the new version, back up your current app, and replace it in Applications. Keep your vault and its original Keychain key together; reinstalling the app does not replace a missing key.

To stop using Stash, first turn off **Launch at login**, then quit and move the app to Trash. History stays in Library unless you explicitly clear/delete it. If removing your saved data too, clear history from the app and review the data locations above; backups can retain previous copies.

Contributions are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and the [changelog](CHANGELOG.md). Signed/notarized releases, older-system/Intel testing, and a trusted update channel remain future work; no unattended maintenance service is installed.

## License

[MIT License](LICENSE) · Copyright © 2026 Stash contributors.
