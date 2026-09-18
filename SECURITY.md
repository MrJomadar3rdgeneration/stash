# Security and privacy

Stash records content placed on the macOS clipboard while capture is enabled. Local AES-GCM encryption protects history files at rest; the key is held in the user's Keychain. The app decrypts history into its memory and can restore it to the system clipboard.

Known boundaries:

- Apple Universal Clipboard and backups are independent of Stash. Stash has no network client, telemetry, or cloud service.
- File clips store references, not copies of original files.

For vulnerabilities, use [GitHub's private reporting form](https://github.com/MrJomadar3rdgeneration/stash/security/advisories/new), enabled for this repository. If that feature is unavailable, ask the maintainer for a private reporting channel without posting exploit details or private data.

