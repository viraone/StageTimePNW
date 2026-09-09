#!/usr/bin/env bash
# Resolve a concrete iPhone simulator, boot it, and print the xcodebuild
# destination for it as `destination=platform=iOS Simulator,id=<udid>`.
#
# Booting is not just a warm-up. Xcode ships simulator runtimes as disk images
# that are mounted lazily, and `simctl` will happily list devices for a runtime
# that xcodebuild cannot yet enumerate as a destination. That mismatch surfaces
# as "Unable to find a destination matching the provided destination specifier"
# with only placeholders listed, even though `simctl list devices available`
# showed the device. Booting forces the mount, and we then confirm against
# xcodebuild itself rather than trusting simctl.
set -euo pipefail

: "${PROJECT:?PROJECT must be set}"
: "${SCHEME:?SCHEME must be set}"

destinations() {
  xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>&1 || true
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
    echo "--- xcodebuild destinations ---"
    destinations
  } >&2
}

devices_json=$(xcrun simctl list devices available --json)

# Runtime keys look like com.apple.CoreSimulator.SimRuntime.iOS-26-5. Sort by
# numeric version so we land on the newest installed iOS runtime, which is what
# `OS=latest` used to express. Lexicographic order would rank 9 above 26.
if ! sim=$(printf '%s' "$devices_json" | jq -r '
      .devices
      | to_entries
      | map(select(.key | test("SimRuntime\\.iOS-")))
      | sort_by(.key | capture("iOS-(?<v>[0-9-]+)").v | split("-") | map(tonumber))
      | reverse
      | map(.value[] | select(.name | startswith("iPhone")))
      | if length == 0 then empty else "\(.[0].udid) \(.[0].name)" end
    '); then
  echo "::error::Could not parse the simctl device list" >&2
  printf '%s\n' "$devices_json" >&2
  exit 1
fi

read -r udid name <<<"$sim"

if [ -z "${udid:-}" ]; then
  echo "::error::No available iPhone simulator" >&2
  diagnostics
  exit 1
fi

echo "Booting $name ($udid)" >&2
# Already-booted is reported as an error; it is exactly what we want.
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >&2 || true

if ! destinations | grep -q "$udid"; then
  echo "::error::xcodebuild does not list simulator $udid as a destination" >&2
  diagnostics
  exit 1
fi

echo "Using simulator: $name ($udid)" >&2
echo "destination=platform=iOS Simulator,id=$udid"
