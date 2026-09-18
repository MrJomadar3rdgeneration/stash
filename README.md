<p align="center">
  <img src="docs/stash-icon.png" width="96" height="96" alt="Stash icon">
</p>
<h1 align="center">Stash</h1>
<p align="center"><strong>Your clipboard, with a memory.</strong></p>
<p align="center">Copy something. Find it later. Keep moving.</p>
<p align="center">
  <a href="https://github.com/MrJomadar3rdgeneration/stash/releases/latest">Download for Mac</a> ·
  <a href="#install-with-homebrew">Homebrew</a> ·
  <a href="docs/USAGE.md">User guide</a> ·
  <a href="https://github.com/MrJomadar3rdgeneration/stash/issues">Report a bug</a>
</p>
<p align="center">
  <a href="https://github.com/MrJomadar3rdgeneration/stash/actions/workflows/ci.yml"><img src="https://github.com/MrJomadar3rdgeneration/stash/actions/workflows/ci.yml/badge.svg" alt="macOS build and checks"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-181c1e" alt="macOS 14 or later">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-a0dfc0" alt="MIT license"></a>
</p>

Stash is a native macOS clipboard manager that remembers what you copy and makes it easy to find again. Save a useful link, recover a paragraph, or keep a reply template close at hand—all from a quiet menu-bar app, with your history encrypted on your Mac.


![Stash showing clipboard history, format filters, and a text preview](docs/stash-overview.png)
*The real Stash interface, shown with fictional sample clips.*

## A little less searching, a little more flow

| Feature | What it does |
| --- | --- |
| Automatic history | Remembers new copies from the macOS system clipboard while Stash is running. |
| Instant search | Filters your history as you type, with case- and accent-insensitive matching. |
| More than text | Saves plain text, HTML/RTF, links, PNG/TIFF images, and file references. |
| Keyboard access | Opens with a customizable global shortcut; navigate and copy without the mouse. |
| Pins and editing | Keeps favorite snippets through automatic cleanup and lets you edit saved text. |
| Local privacy | Encrypts history with AES-GCM and keeps the encryption key in your login Keychain. |
| Everyday controls | Pause capture, exclude apps, delete individual clips, or clear history. |
| Ready after login | Starts quietly when you sign into your Mac, if you enable Launch at login. |

## Download and install

### Download the app

**[Download Stash for Apple Silicon](https://github.com/MrJomadar3rdgeneration/stash/releases/download/v0.3.0/Stash-0.3.0-arm64.zip)** · [All releases](https://github.com/MrJomadar3rdgeneration/stash/releases)

1. Download and unzip the app. The download supports **Apple Silicon Macs (M1 or later), macOS 14+**.
2. Move **Stash.app** into **Applications**. Quit an older copy before replacing it.
3. Open Stash, then enable **Settings → Launch at login** if you want it available after every restart.

**First launch:** the download is ad-hoc signed, not Developer ID signed or notarized. macOS may require your approval before opening it. If it is blocked, review the app in **System Settings → Privacy & Security** and use **Open Anyway**. Complete any Stash Keychain prompt yourself.


### Install with Homebrew

With [Homebrew](https://brew.sh) installed:

```sh
brew install --cask MrJomadar3rdgeneration/tap/stash-clipboard
```

This uses [our Homebrew tap](https://github.com/MrJomadar3rdgeneration/homebrew-tap), verifies the download checksum, and places **Stash.app** in **Applications** by default. The same architecture and first-launch requirements apply.

Use the complete command above: the unrelated [`stash` cask](https://formulae.brew.sh/cask/stash) in Homebrew installs a network tool.

Already installed manually? Quit Stash and move the existing app to a backup folder if Homebrew reports a conflict, then retry. Your history stays in Library.

## From copy to found in seconds

1. **Copy as usual.** Stash saves new clipboard content while it runs in the menu bar.
2. **Open with ⌘⇧V.** Type a word, or choose a format from the sidebar.
3. **Press Return to copy.** Switch to your destination app and press **⌘V**.

![Searching for design instantly filters Stash to matching clips](docs/stash-search.png)
*Search across text, links, file paths, source-app names, and format labels. Images do not have OCR search.*

Pin the snippets you use often. Edit a saved text or link clip without pasting and copying it again; edits are saved as plain text. The whole sidebar row is clickable, so switching between **All clips**, **Pinned**, and format filters feels natural.

Prefer fewer steps? Enable **Paste directly into the previous app** in Settings and grant Accessibility access. Stash can then send ⌘V after restoring a clip. Basic capture, search, and copying do not need Accessibility. Some apps or protected fields may require manual paste.

### Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| **⌘⇧V** | Open or hide history; customizable in Settings |
| **↑ / ↓** | Select a result |
| **Return** | Copy the selected clip, or paste if direct paste is enabled |
| **⇧Return** | Use the plain-text representation |
| **⌘P** | Pin or unpin the selected clip |
| **⌘⌫** | Delete the selected clip |
| **Escape** | Hide history |
| **⌘,** | Open Settings |
| **⌘Q** | Quit Stash |

History actions apply while the history window is focused, outside Settings or the editor. Closing the red window button leaves capture running; **Quit Stash** stops it.

See the **[user guide](docs/USAGE.md)** for shortcut customization, direct paste, app exclusions, retention settings, and troubleshooting.

## Your history stays on your Mac

Stash has no network client or cloud sync. Saved clips and metadata are encrypted in `~/Library/Application Support/Stash/`; the key stays in your login Keychain. Preferences use the `com.stash.clipboard` domain.

The app skips content marked confidential or transient and copies from excluded foreground apps. Several password managers are excluded by default. Unmarked secrets can still be captured, especially from browser extensions, so use a password manager for passwords and tokens instead of pinning them in Stash.

By default, Stash keeps **1,000 clips for 30 days**, with a **250 MB payload budget** for automatic cleanup. Pins are exempt. Individual snapshots over **20 MB** are skipped. File clips retain references to the original files, so moving or deleting those files can affect later pastes.

Encryption protects stored files; it does not protect an unlocked session from malicious software. Backups and Apple Universal Clipboard operate independently. Read the [privacy details](docs/USAGE.md#privacy-and-storage) and [security policy](SECURITY.md).

## Designed to stay out of the way

Stash checks for changes every 0.5 seconds, or every second in Low Power Mode. Monitoring pauses during system/display sleep, inactive login sessions, and manual capture pause. It does not keep your Mac awake.

One short local idle observation showed about **35 MB of memory** and **0.0% displayed CPU** at the tool's precision. That is not a battery-life benchmark: frequent copying, large images, and long histories use more resources. [Measurement details](ENERGY.md).

Polling can miss very rapid clipboard overwrites. File promises and some app-specific formats cannot be reliably replayed. The [user guide](docs/USAGE.md#troubleshooting) covers these cases and other common issues.

## Updates and removal

For Homebrew installations, quit Stash and run:

```sh
brew upgrade --cask MrJomadar3rdgeneration/tap/stash-clipboard
```

For manual installations, download the next release, quit Stash, and replace the app in Applications. There is no in-app automatic updater. Keep your history and its original Keychain key together; reinstalling the app cannot replace a missing key.

To uninstall, disable **Launch at login**, quit Stash, then move the app to Trash—or run `brew uninstall --cask stash-clipboard` if installed with Homebrew. History remains in Library unless you explicitly clear it. Deletion has no undo, and backups may retain earlier copies.

## Build from source

You need **Swift 6+**, Xcode 16+ or compatible Apple Command Line Tools, and macOS 14+.

```sh
git clone https://github.com/MrJomadar3rdgeneration/stash.git
cd stash
swift run StashChecks
./scripts/build.sh
```

The app is created at `build/Stash.app`, ready to move into Applications. The script builds for your Mac's architecture and signs locally. No third-party package dependencies are downloaded.

The **12 automated checks** cover encryption, tamper rejection, retention, pins, search, and production capture/replay for text, HTML, RTF, links, images, and multiple files. Clipboard checks use isolated named pasteboards and leave your general clipboard untouched. GitHub CI also builds and packages the app.

For the sample interface shown above, quit the normal app and run `open build/Stash.app --args --demo`. Demo mode does not read your vault or capture clipboard changes; clicking Copy still changes the system clipboard. Quit demo mode before reopening normally.

## Contribute

Bug reports, thoughtful improvements, and compatibility testing are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md). Use fictional clipboard content in reports and screenshots; never upload your history or credentials. Report security issues through [private vulnerability reporting](https://github.com/MrJomadar3rdgeneration/stash/security/advisories/new).

[Changelog](CHANGELOG.md) · [Validation results](VALIDATION.md) · [Release checklist](RELEASE_CHECKLIST.md)

## License

[MIT](LICENSE) · Copyright © 2026 Stash contributors.
