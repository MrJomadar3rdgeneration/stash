# Changelog

## 0.3.0 — 2026-09-18

- Sidebar navigation and utility actions have full-width rectangular click targets.
- Menu-bar item has explicit visibility, a stable saved identity, template icon sizing, and a restore action in Settings.
- Shortcut recording temporarily suspends the old hotkey, restores it on cancellation, and accepts unchanged combinations.
- Live capture/replay uses shared code covered by integration checks for HTML, RTF, links, PNGs, and multiple files.
  
## 0.2.0 — 2026-09-18

- History uses normal window ordering instead of staying above other applications.
- Login-item launches do not open the history window. Manual launch and the hotkey still do.
- Closing the window explicitly leaves the menu-bar capture process running.
- Installed in Applications; encrypted data remains under Library/Application Support/Stash.

## 0.1.0 — 2026-09-18

Initial native local clipboard history app with rich format preservation, search, pins, inline text editing, encrypted storage, exclusions, and custom global shortcuts.
