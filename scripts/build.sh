#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
swift build -c release
mkdir -p build/Stash.app/Contents/MacOS build/Stash.app/Contents/Resources
cp .build/release/Stash build/Stash.app/Contents/MacOS/Stash
cp Resources/Info.plist build/Stash.app/Contents/Info.plist
cp LICENSE build/Stash.app/Contents/Resources/LICENSE
swift scripts/icon.swift build/Stash.iconset
iconutil -c icns build/Stash.iconset -o build/Stash.app/Contents/Resources/Stash.icns
codesign --force --sign - build/Stash.app
print "Built: $PWD/build/Stash.app"
