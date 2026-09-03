#!/usr/bin/env bash
set -euo pipefail

file="${1:?usage: scan_review.sh <diff_file>}"

# Show each CV marker with context.
# - "### CV: ..." shows up to 10 following lines.
# - "### CV:<n> ..." shows the line <n> lines below the marker (1-based offset).
awk '
  { lines[NR] = $0 }
  END {
    for (i = 1; i <= NR; i++) {
      line = lines[i]
      if (line ~ /^### CV([[:space:]]|$|:)/) {
        offset = 0
        if (line ~ /^### CV:[0-9]+/) {
          tmp = line
          sub(/^### CV:/, "", tmp)
          if (match(tmp, /^[0-9]+/)) offset = substr(tmp, RSTART, RLENGTH) + 0
        }

        printf "%d:%s\n", i, line

        if (offset > 0) {
          target = i + offset
          if (target <= NR) {
            printf "%d:%s\n", target, lines[target]
          } else {
            printf "%d:%s\n", target, "(out of range)"
          }
        } else {
          for (j = i + 1; j <= i + 10 && j <= NR; j++) {
            if (lines[j] ~ /^### CV([[:space:]]|$|:)/) break
            printf "%d:%s\n", j, lines[j]
          }
        }

        printf "\n"
      }
    }
  }
' "$file" || true
