#!/usr/bin/env bash
set -euo pipefail

mkdir -p .patches

ts="$(date +%Y%m%d_%H%M%S)"
subject="$(git log -1 --format=%s)"
# remove "patch: " prefix if present
summary="${subject#patch: }"

safe_summary="$(python3 "$(dirname "$0")/sanitize.py" "$summary")"
out=".patches/${ts}_${safe_summary}.diff"

# Use format-patch to capture commit metadata + diff
git format-patch -1 HEAD --stdout > "$out"

echo "$out"
