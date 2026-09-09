#!/usr/bin/env bash
# Select an Xcode whose iOS Simulator SDK matches a simulator runtime that is
# actually installed.
#
# Newest-installed is not safe on GitHub's macOS images. macos-15 carries nine
# Xcodes (16.0 through 26.3) but iOS runtimes only up to 26.2, so the newest
# Xcode has no runtime to pair with and xcodebuild offers nothing but
# placeholder destinations: "Unable to find a destination matching the provided
# destination specifier".
#
# simctl cannot arbitrate this. It reports runtimes registered with
# CoreSimulator machine-wide, independent of the selected Xcode, so it lists
# iOS 26.2 devices just as happily under Xcode 26.3, which cannot drive them.
# Matching the Xcode's own SDK version against the installed runtimes is the
# cheap, project-independent way to pair them correctly; prepare-simulator.sh
# then confirms the pairing against xcodebuild before any test runs.
#
# Candidates are probed with DEVELOPER_DIR rather than switching the machine
# with sudo nine times, so only the winner is actually selected.
#
# Usage: select-xcode.sh [tests|build]
#   tests  (default) requires an SDK matching an installed runtime.
#   build  only requires an iOS Simulator SDK. A compile-only job targeting
#          generic/platform=iOS Simulator never touches a device, so demanding
#          a runtime would fail a job that can build perfectly well.
#
# Set XCODE_VERSION (e.g. "26.2") to pin an exact Xcode; the same check runs,
# so a bad pin fails loudly rather than silently building on the wrong tools.
set -uo pipefail

# Overridable so the selection logic can be exercised against a simulated
# layout in tests; production always uses /Applications.
xcode_root="${XCODE_SEARCH_ROOT:-/Applications}"

mode="${1:-tests}"
case "$mode" in
  tests|build) ;;
  *) echo "::error::Unknown mode '$mode' (expected 'tests' or 'build')" >&2; exit 2 ;;
esac

# Versions of every installed, available iOS runtime, e.g. "26.2".
runtime_versions=$(
  xcrun simctl list runtimes --json 2>/dev/null \
    | jq -r '.runtimes[]? | select(.identifier | test("SimRuntime\\.iOS")) | select(.isAvailable) | .version' \
    | sort -Vr
)

# The iOS Simulator SDK version an Xcode ships, e.g. "26.2".
sdk_version_of() {
  DEVELOPER_DIR="$1/Contents/Developer" xcodebuild -showsdks 2>/dev/null \
    | sed -n 's/.*-sdk iphonesimulator\([0-9.]*\).*/\1/p' \
    | head -1
}

qualifies() {
  local sdk="$1"
  [ -n "$sdk" ] || return 1
  [ "$mode" = "build" ] && return 0
  printf '%s\n' "$runtime_versions" | grep -qx "$sdk"
}

use_xcode() {
  local app="$1" sdk="$2"
  if ! sudo xcode-select -s "$app/Contents/Developer"; then
    echo "::error::Could not select $app" >&2
    return 1
  fi
  echo "Using $app (iOS Simulator SDK $sdk)"
  xcodebuild -version
  return 0
}

report_and_fail() {
  echo "::error::$1" >&2
  {
    echo "--- installed iOS runtimes ---"
    printf '%s\n' "$runtime_versions"
    echo "--- Xcode SDK versions ---"
    while IFS= read -r app; do
      [ -d "$app" ] || continue
      echo "$app -> $(sdk_version_of "$app")"
    done < <(printf '%s\n' "$xcode_root"/Xcode*.app | sort -Vr)
  } >&2
  exit 1
}

if [ -n "${XCODE_VERSION:-}" ]; then
  pinned="$xcode_root/Xcode_${XCODE_VERSION}.app"
  [ -d "$pinned" ] || report_and_fail "Pinned XCODE_VERSION=$XCODE_VERSION not installed ($pinned)"
  sdk=$(sdk_version_of "$pinned")
  qualifies "$sdk" || report_and_fail "Pinned XCODE_VERSION=$XCODE_VERSION has SDK '${sdk:-none}' with no matching installed runtime"
  use_xcode "$pinned" "$sdk" || exit 1
  exit 0
fi

# Newest first. The images carry symlink pairs (Xcode_26.3.app and
# Xcode_26.3.0.app are one install), so resolve and skip duplicates.
seen=""
while IFS= read -r app; do
  real=$(cd "$app" 2>/dev/null && pwd -P) || continue
  case "$seen" in *"|$real|"*) continue ;; esac
  seen="$seen|$real|"

  sdk=$(sdk_version_of "$app")
  if qualifies "$sdk"; then
    use_xcode "$app" "$sdk" && exit 0
  fi
  echo "Skipping $app (SDK ${sdk:-none})"
done < <(printf '%s\n' "$xcode_root"/Xcode*.app | sort -Vr)

report_and_fail "No installed Xcode pairs an iOS Simulator SDK with an installed runtime"
