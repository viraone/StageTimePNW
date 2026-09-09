#!/usr/bin/env bash
# Report the active Xcode, or select the one pinned in XCODE_VERSION.
#
# The runner image's default Xcode is the right one to use: macos-26 defaults
# to Xcode 26.6, which carries the iOS 26.5 runtime this app's deployment
# target needs. Hunting for a "better" Xcode is what broke earlier attempts —
# an Xcode cannot be judged by its version or even its SDK version, because
# whether a simulator is usable also depends on the project's deployment
# target. prepare-simulator.sh settles that question against xcodebuild.
#
# Set XCODE_VERSION (e.g. "26.6") to pin an exact Xcode for reproducibility.
set -euo pipefail

if [ -n "${XCODE_VERSION:-}" ]; then
  # Images carry both Xcode_26.6.app and Xcode_26.6.0.app; accept either so a
  # pin does not hinge on which naming form a given image happens to use.
  app=""
  for candidate in "/Applications/Xcode_${XCODE_VERSION}.app" "/Applications/Xcode_${XCODE_VERSION}.0.app"; do
    if [ -d "$candidate" ]; then app="$candidate"; break; fi
  done
  if [ -z "$app" ]; then
    echo "::error::Pinned XCODE_VERSION=$XCODE_VERSION not installed" >&2
    ls -d /Applications/Xcode*.app >&2 2>/dev/null || true
    exit 1
  fi
  sudo xcode-select -s "$app/Contents/Developer"
  echo "Pinned to $app"
else
  echo "Using the image default Xcode ($(xcode-select -p))"
fi

xcodebuild -version
xcodebuild -showsdks 2>/dev/null | grep -i iphonesimulator || true
