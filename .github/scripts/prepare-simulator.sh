#!/usr/bin/env bash
# Print the xcodebuild destination for the best available iPhone simulator as
# `destination=platform=iOS Simulator,id=<udid>`.
#
# The device is discovered from `xcodebuild -showdestinations`, never assumed,
# so the workflow survives runner images renaming or retiring simulators.
set -euo pipefail

: "${PROJECT:?PROJECT must be set}"
: "${SCHEME:?SCHEME must be set}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

best_destination() {
  bash "$script_dir/list-simulator-destinations.sh" 2>/dev/null | head -1
}

diagnostics() {
  {
    echo "--- installed Xcodes ---"
    ls -d /Applications/Xcode*.app 2>/dev/null || true
    echo "--- active developer dir ---"
    xcode-select -p || true
    echo "--- simctl runtimes ---"
    xcrun simctl list runtimes || true
    echo "--- simctl devices (available) ---"
    xcrun simctl list devices available || true
    echo "--- deployment target vs installed runtimes ---"
    # The decisive pair: xcodebuild omits every simulator whose runtime is
    # older than the deployment target, and does not even list them as
    # ineligible, so simctl shows devices while destinations show placeholders.
    xcodebuild -showBuildSettings -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null \
      | grep IPHONEOS_DEPLOYMENT_TARGET | head -1 || true
    xcrun simctl list runtimes 2>/dev/null | grep "^iOS " || true
    echo "--- xcodebuild destinations (active Xcode) ---"
    xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>&1 || true

    # Which Xcodes, if any, can enumerate a real simulator for this scheme?
    # Packages are already resolved by now, so this is the cheap, truthful
    # probe. It answers "is this Xcode-specific or image-wide?" in one run
    # instead of costing another round trip to find out.
    echo "--- concrete iOS Simulator destinations per Xcode ---"
    seen=""
    while IFS= read -r app; do
      real=$(cd "$app" 2>/dev/null && pwd -P) || continue
      case "$seen" in *"|$real|"*) continue ;; esac
      seen="$seen|$real|"
      count=$(DEVELOPER_DIR="$app/Contents/Developer" \
        bash "$script_dir/list-simulator-destinations.sh" 2>/dev/null | wc -l | tr -d ' ')
      echo "$app -> ${count:-0}"
    done < <(printf '%s\n' /Applications/Xcode*.app | sort -Vr)
  } >&2
}

best=$(best_destination)

if [ -z "$best" ]; then
  echo "::error::xcodebuild lists no usable iOS Simulator destination for $SCHEME" >&2
  echo "If every Xcode below reports 0, this is image-wide: no installed simulator runtime is new enough for IPHONEOS_DEPLOYMENT_TARGET." >&2
  diagnostics
  exit 1
fi

IFS=$'\t' read -r os udid name <<<"$best"

echo "Using simulator: $name (iOS $os, $udid)" >&2
echo "destination=platform=iOS Simulator,id=$udid"
# Name-based fallback for the caller: if a UDID is ever rejected, this form
# lets xcodebuild re-resolve the device itself.
echo "destination_by_name=platform=iOS Simulator,name=$name,OS=$os"
