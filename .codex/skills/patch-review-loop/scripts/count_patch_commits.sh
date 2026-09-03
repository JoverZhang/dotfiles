#!/usr/bin/env bash
set -euo pipefail

max="${1:-200}"
n=0
while IFS= read -r subj; do
  if [[ "$subj" == patch:* ]]; then
    n=$((n+1))
  else
    break
  fi
done < <(git log -n "$max" --format=%s)

echo "$n"

