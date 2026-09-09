#!/usr/bin/env bash
# Print the concrete iOS Simulator destinations xcodebuild will accept for the
# scheme, best first, as TSV: <os>\t<udid>\t<name>.
#
# xcodebuild is the only authority worth asking. `simctl` reports simulator
# runtimes installed anywhere on the machine, independent of which Xcode is
# selected, so it cheerfully lists devices that the selected Xcode cannot use.
# Placeholder destinations ("Any iOS Simulator Device") are dropped because
# tests cannot run on them.
set -uo pipefail

: "${PROJECT:?PROJECT must be set}"
: "${SCHEME:?SCHEME must be set}"

tab=$(printf '\t')

xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>&1 \
  | awk '
      /Available destinations/  { avail = 1; next }
      /Ineligible destinations/ { avail = 0; next }
      !avail                    { next }
      !/platform:iOS Simulator/ { next }
      /placeholder/             { next }
      {
        line = $0
        sub(/[[:space:]]*}[[:space:]]*$/, "", line)

        id = ""
        if (match(line, /id:[^,}]+/)) { id = substr(line, RSTART + 3, RLENGTH - 3) }
        if (id == "") next

        os = "0"
        if (match(line, /OS:[^,}]+/)) { os = substr(line, RSTART + 3, RLENGTH - 3) }

        name = ""
        n = index(line, "name:")
        if (n) { name = substr(line, n + 5) }

        gsub(/^[ \t]+|[ \t]+$/, "", id)
        gsub(/^[ \t]+|[ \t]+$/, "", os)
        gsub(/^[ \t]+|[ \t]+$/, "", name)

        # Rank iPhones first, then newest OS, so the default matches what a
        # developer would pick by hand.
        printf "%d\t%s\t%s\t%s\n", (name ~ /^iPhone/) ? 1 : 0, os, id, name
      }
    ' \
  | sort -t"$tab" -k1,1nr -k2,2Vr \
  | cut -f2-
