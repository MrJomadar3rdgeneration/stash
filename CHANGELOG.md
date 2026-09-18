# Changelog

## 0.3.0 — 2026-09-18

- Sidebar navigation and utility actions have full-width rectangular click targets.
- Menu-bar item has explicit visibility, a stable saved identity, template icon sizing, and a restore action in Settings.
- Shortcut recording temporarily suspends the old hotkey, restores it on cancellation, and accepts unchanged combinations.
- Live capture/replay uses shared code covered by integration checks for HTML, RTF, links, PNGs, and multiple files.
- Invalid replay requests preserve the current clipboard.
- Added MIT license, contribution/security guidance, issue template, release gates, and archived CI artifacts.

## 0.2.0 — 2026-09-18

- History uses normal window ordering instead of staying above other applications.
- Login-item launches do not open the history window. Manual launch and the hotkey still do.
- Closing the window explicitly leaves the menu-bar capture process running.
- Login settings reflect the actual macOS service state and expose required approval instead of showing a false success.
- Energy improvements: timer coalescing, reduced polling in Low Power Mode, suspension during pause/sleep/inactive sessions, and fewer unnecessary UI updates.
- Installed in Applications; encrypted data remains under Library/Application Support/Stash.

## 0.1.0 — 2026-09-18

Initial native local clipboard history app with rich format preservation, search, pins, inline text editing, encrypted storage, exclusions, and custom global shortcuts.
