#!/usr/bin/env bash
# Select the newest installed Xcode that actually has an iOS simulator runtime.
#
# Picking the newest Xcode outright is not safe on GitHub's macOS images: they
# ship a current Xcode (26.3 at the time of writing) with no iOS runtime
# installed. Selecting it leaves every concrete simulator destination
# unresolvable, and the build dies with "Unable to find a destination matching
# the provided destination specifier" listing only macOS and placeholders.
set -uo pipefail

# Iterate newest-first over a glob rather than parsing `ls`, so an Xcode whose
# path contains spaces still resolves as a single candidate.
while IFS= read -r app; do
  [ -d "$app" ] || continue

  if ! sudo xcode-select -s "$app/Contents/Developer" 2>/dev/null; then
    echo "Skipping $app (could not select)"
    continue
  fi

  if xcrun simctl list runtimes available 2>/dev/null | grep -q '^iOS '; then
    echo "Using $app"
    xcodebuild -version
    exit 0
  fi

  echo "Skipping $app (no iOS simulator runtime)"
done < <(printf '%s\n' /Applications/Xcode*.app | sort -Vr)

echo "::error::No installed Xcode has an iOS simulator runtime" >&2
exit 1
