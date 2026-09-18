#!/bin/zsh
set -euo pipefail

cd "${0:A:h}/.."

replace=false
if [[ "${1:-}" == "--replace" ]]; then
    replace=true
elif [[ -n "${1:-}" ]]; then
    print -u2 "Usage: ./scripts/install.sh [--replace]"
    exit 2
fi

install_root="${STASH_INSTALL_DIR:-/Applications}"
destination="$install_root/Stash.app"
backup="$HOME/.Trash/Stash-previous-$(date +%Y%m%d-%H%M%S).app"

if [[ "$install_root" != /* ]]; then
    print -u2 "STASH_INSTALL_DIR must be an absolute path."
    exit 2
fi

if pgrep -x Stash >/dev/null 2>&1; then
    print -u2 "Quit Stash before installing or updating it."
    exit 3
fi

if [[ -e "$destination" && "$replace" != true ]]; then
    print -u2 "$destination already exists. Quit Stash and rerun with --replace to update it."
    exit 3
fi

swift run StashChecks
./scripts/build.sh

if [[ ! -d "$install_root" ]]; then
    mkdir -p "$install_root"
fi

if [[ -w "$install_root" ]]; then
    if [[ "$replace" == true && -e "$destination" ]]; then
        mv "$destination" "$backup"
    fi
    ditto build/Stash.app "$destination"
else
    if [[ "$replace" == true && -e "$destination" ]]; then
        sudo mv "$destination" "$backup"
    fi
    sudo ditto build/Stash.app "$destination"
fi

codesign --verify --deep --strict --verbose=2 "$destination"
print "Installed Stash at $destination"
print "Open it from Applications, then enable Launch at login in Settings if desired."
