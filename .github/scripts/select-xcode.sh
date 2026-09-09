#!/usr/bin/env bash
# Select an Xcode that can actually run iOS Simulator tests for this scheme.
#
# Newest-installed is not a safe choice on GitHub's macOS images. macos-15
# ships nine Xcodes (16.0 through 26.3) but iOS runtimes only up to 26.2, so
# the newest Xcode has no runtime it can use. Selecting it leaves xcodebuild
# with nothing but placeholder destinations and the build dies with "Unable to
# find a destination matching the provided destination specifier".
#
# `simctl` cannot arbitrate this: it lists runtimes installed anywhere on the
# machine regardless of the selected Xcode, so it reports devices that the
# selected Xcode cannot use. The only reliable test is asking xcodebuild
# whether it can enumerate a concrete simulator destination.
#
# Set XCODE_VERSION (e.g. "26.2") to pin an exact Xcode instead of discovering
# one; the same destination check still runs, so a bad pin fails loudly.
set -uo pipefail

: "${PROJECT:?PROJECT must be set}"
: "${SCHEME:?SCHEME must be set}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

can_run_simulator_tests() {
  [ -n "$(bash "$script_dir/list-simulator-destinations.sh" 2>/dev/null | head -1)" ]
}

try_xcode() {
  local app="$1"
  [ -d "$app" ] || return 1

  if ! sudo xcode-select -s "$app/Contents/Developer" 2>/dev/null; then
    echo "Skipping $app (could not select)"
    return 1
  fi

  if ! can_run_simulator_tests; then
    echo "Skipping $app (no usable iOS Simulator destination)"
    return 1
  fi

  echo "Using $app"
  xcodebuild -version
  return 0
}

if [ -n "${XCODE_VERSION:-}" ]; then
  pinned="/Applications/Xcode_${XCODE_VERSION}.app"
  if try_xcode "$pinned"; then
    exit 0
  fi
  echo "::error::Pinned XCODE_VERSION=$XCODE_VERSION cannot run simulator tests ($pinned)" >&2
  ls -d /Applications/Xcode*.app >&2 2>/dev/null || true
  exit 1
fi

# Iterate newest-first over a glob rather than parsing `ls`, so an Xcode whose
# path contains spaces still resolves as a single candidate. The images carry
# symlink pairs (Xcode_26.3.app and Xcode_26.3.0.app are one install), and each
# candidate costs a full destination lookup, so resolve and skip duplicates.
seen=""
while IFS= read -r app; do
  real=$(cd "$app" 2>/dev/null && pwd -P) || continue
  case "$seen" in
    *"|$real|"*) continue ;;
  esac
  seen="$seen|$real|"

  if try_xcode "$app"; then
    exit 0
  fi
done < <(printf '%s\n' /Applications/Xcode*.app | sort -Vr)

echo "::error::No installed Xcode can run iOS Simulator tests for $SCHEME" >&2
ls -d /Applications/Xcode*.app >&2 2>/dev/null || true
xcrun simctl list runtimes >&2 2>/dev/null || true
exit 1
