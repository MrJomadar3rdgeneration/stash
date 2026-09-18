#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."

if [[ -z "${STASH_CODESIGN_IDENTITY:-}" ]]; then
    print -u2 "STASH_CODESIGN_IDENTITY must name a Developer ID Application certificate."
    exit 2
fi

if [[ "$STASH_CODESIGN_IDENTITY" != Developer\ ID\ Application:* ]]; then
    print -u2 "Release signing requires a Developer ID Application identity."
    exit 2
fi

if [[ -z "${STASH_NOTARY_PROFILE:-}" ]] && \
   [[ -z "${STASH_NOTARY_KEY:-}" || -z "${STASH_NOTARY_KEY_ID:-}" || -z "${STASH_NOTARY_ISSUER_ID:-}" ]]; then
    print -u2 "Set STASH_NOTARY_PROFILE, or set STASH_NOTARY_KEY, STASH_NOTARY_KEY_ID, and STASH_NOTARY_ISSUER_ID."
    exit 2
fi

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
architecture="$(/usr/bin/uname -m)"
release_dir="$PWD/build/release"
submission_zip="$release_dir/Stash-${version}-${architecture}-submission.zip"
release_zip="$release_dir/Stash-${version}-${architecture}.zip"

STASH_CODESIGN_IDENTITY="$STASH_CODESIGN_IDENTITY" ./scripts/build.sh

signature_details="$(codesign -dv --verbose=4 build/Stash.app 2>&1)"
if [[ "$signature_details" != *"Authority=Developer ID Application:"* ]] || \
   [[ "$signature_details" == *"Signature=adhoc"* ]] || \
   [[ "$signature_details" == *"TeamIdentifier=not set"* ]]; then
    print -u2 "The app does not have a valid Developer ID Application signature."
    exit 3
fi

mkdir -p "$release_dir"
ditto -c -k --sequesterRsrc --keepParent build/Stash.app "$submission_zip"

if [[ -n "${STASH_NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$submission_zip" \
        --keychain-profile "$STASH_NOTARY_PROFILE" \
        --wait
else
    xcrun notarytool submit "$submission_zip" \
        --key "$STASH_NOTARY_KEY" \
        --key-id "$STASH_NOTARY_KEY_ID" \
        --issuer "$STASH_NOTARY_ISSUER_ID" \
        --wait
fi

xcrun stapler staple build/Stash.app
xcrun stapler validate build/Stash.app
codesign --verify --deep --strict --verbose=2 build/Stash.app
spctl --assess --type execute --verbose=4 build/Stash.app

ditto -c -k --sequesterRsrc --keepParent build/Stash.app "$release_zip"
shasum -a 256 "$release_zip"
print "Notarized release: $release_zip"
