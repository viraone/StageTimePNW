#!/usr/bin/env bash
# Print an xcodebuild -destination specifier for the newest available iPhone
# simulator, as `destination=platform=iOS Simulator,id=<udid>`.
#
# Resolving a concrete UDID beats hard-coding a device name: GitHub's macOS
# images rename and retire simulators between releases, and `OS=latest` only
# helps once the device name itself still exists.
set -euo pipefail

devices_json=$(xcrun simctl list devices available --json)

# Runtime keys look like com.apple.CoreSimulator.SimRuntime.iOS-26-5. Sort them
# by numeric version so we land on the newest installed iOS runtime, which is
# what `OS=latest` used to express. Lexicographic order would rank 9 above 26.
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
  xcrun simctl list devices available >&2
  exit 1
fi

echo "Using simulator: $name ($udid)" >&2
echo "destination=platform=iOS Simulator,id=$udid"
