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

# Fallback: simulator runtimes ship as lazily-mounted disk images, so if
# xcodebuild sees no concrete device, booting one can force the mount. This is
# a long shot once select-xcode.sh has already confirmed a usable destination,
# but it costs one boot and turns a hard failure into a recovery.
if [ -z "$best" ]; then
  echo "No destination from xcodebuild; trying to boot a simulator to force a runtime mount" >&2
  udid=$(xcrun simctl list devices available --json 2>/dev/null | jq -r '
    .devices
    | to_entries
    | map(select(.key | test("SimRuntime\\.iOS-")))
    | sort_by(.key | capture("iOS-(?<v>[0-9-]+)").v | split("-") | map(tonumber))
    | reverse
    | map(.value[] | select(.name | startswith("iPhone")))
    | if length == 0 then empty else .[0].udid end
  ' || true)

  if [ -n "${udid:-}" ]; then
    # Bounded so a runtime that will never mount cannot hang the job until the
    # 45-minute step timeout.
    xcrun simctl boot "$udid" 2>/dev/null || true
    ( xcrun simctl bootstatus "$udid" -b >&2 2>&1 || true ) &
    boot_pid=$!
    ( sleep 240; kill "$boot_pid" 2>/dev/null || true ) &
    wait "$boot_pid" 2>/dev/null || true
    best=$(best_destination)
  fi
fi

if [ -z "$best" ]; then
  echo "::error::xcodebuild lists no usable iOS Simulator destination for $SCHEME" >&2
  diagnostics
  exit 1
fi

IFS=$'\t' read -r os udid name <<<"$best"

echo "Using simulator: $name (iOS $os, $udid)" >&2
echo "destination=platform=iOS Simulator,id=$udid"
# Name-based fallback for the caller: if a UDID is ever rejected, this form
# lets xcodebuild re-resolve the device itself.
echo "destination_by_name=platform=iOS Simulator,name=$name,OS=$os"
