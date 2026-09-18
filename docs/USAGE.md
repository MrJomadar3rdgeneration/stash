# Using Stash

[Back to the README](../README.md)

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


The app skips clipboard content marked confidential or transient, plus content copied while an excluded app is in front. Several password managers are excluded by default. 

| Data | Location |
| --- | --- |
| Encrypted clips, metadata, and pin state | `~/Library/Application Support/Stash/*.stash` |
| Encryption key | Your login Keychain; service `com.stash.clipboard.vault` |
| Preferences | macOS UserDefaults domain `com.stash.clipboard`, managed under `~/Library/Preferences/` |
| Runtime resources | Inside `Stash.app` |

Stash has no network client or cloud sync. Apple Universal Clipboard and your backup software operate independently. Encryption protects history files at rest, not an unlocked session from malicious software, screenshots, process-memory inspection, or an authorized Keychain reader. Deleting a file is not guaranteed secure erasure from SSDs or backups. Read [SECURITY.md](../SECURITY.md).

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

Stash checks for clipboard changes about every **0.5 seconds**, or **1 second in Low Power Mode**, with timer tolerance to combine wake-ups. Polling stops while paused, asleep, or in an inactive login session. It holds no keep-awake assertion. Large images, long text, frequent copying, and large histories require more work; history is decoded into RAM. See [ENERGY.md](../ENERGY.md) for measurement details and limits.

