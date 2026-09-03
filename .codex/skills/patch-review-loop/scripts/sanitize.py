#!/usr/bin/env python3
import re, sys

s = sys.argv[1] if len(sys.argv) > 1 else "patch"
s = s.strip().lower()
s = re.sub(r"\s+", "_", s)
s = re.sub(r"[^a-z0-9._-]+", "", s)
s = s.strip("._-")
print(s[:60] or "patch")

