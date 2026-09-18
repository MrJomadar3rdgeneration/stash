# Security and privacy

Stash is not a password manager. It records content placed on the macOS clipboard while capture is enabled. Local AES-GCM encryption protects history files at rest; the key is held in the user's Keychain. The app decrypts history into its memory and can restore it to the system clipboard.

Known boundaries:

- Apps can copy secrets without confidential markers. Excluding the source app helps, but source attribution uses the foreground app and can be wrong during rapid switching or background automation.
- Encryption does not protect an unlocked user session from malicious software, screen capture, process-memory access, or an authorized Keychain reader.
- Apple Universal Clipboard and backups are independent of Stash. Stash has no network client, telemetry, or cloud service.
- File clips store references, not copies of original files. Deleted history is not guaranteed to be securely erased from SSDs or backups.
- Large and pinned histories can consume substantial memory and disk space.

Do not post actual secrets or clipboard records in public bug reports. For vulnerabilities, use [GitHub's private reporting form](https://github.com/MrJomadar3rdgeneration/stash/security/advisories/new), enabled for this repository. If that feature is unavailable, ask the maintainer for a private reporting channel without posting exploit details or private data.

There has not been an independent security audit. A successful test run is not a security certification.
