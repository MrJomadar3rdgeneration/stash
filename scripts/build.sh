#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."

signing_identity="${STASH_CODESIGN_IDENTITY:--}"

swift build -c release
mkdir -p build/Stash.app/Contents/MacOS build/Stash.app/Contents/Resources
cp .build/release/Stash build/Stash.app/Contents/MacOS/Stash
cp Resources/Info.plist build/Stash.app/Contents/Info.plist
cp LICENSE build/Stash.app/Contents/Resources/LICENSE
swift scripts/icon.swift build/Stash.iconset
iconutil -c icns build/Stash.iconset -o build/Stash.app/Contents/Resources/Stash.icns

if [[ "$signing_identity" == "-" ]]; then
    codesign --force --sign - build/Stash.app
    print "Built with an ad-hoc development signature: $PWD/build/Stash.app"
else
    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$signing_identity" \
        build/Stash.app
    print "Built with Developer ID: $PWD/build/Stash.app"
fi

codesign --verify --deep --strict --verbose=2 build/Stash.app
