---
name: patch-review-loop
description: "Implement code changes, create a 'patch:' commit, export a diff file under .patches/, then run a GitHub-PR-style review loop driven by ### CV comments."
capabilities:
  allow_commands:
    - git status
    - git diff
    - git add
    - git commit
    - git show
    - git log
    - git format-patch
    - cat
    - rg
    - sed
    - awk
    - bash
    - python3
    - mkdir
    - date
    - ls
    - head
---

## When to use
- Use when the user asks you to modify code AND wants a patch: commit + exported diff + review loop.

## Invariants (must follow)
0) Explicit invocation only: Do not run this skill unless the user explicitly says "use $patch-review-loop" (or provides the exact keyword RUN_PATCH_REVIEW_LOOP).
1) Never commit unrelated changes.
2) Commit message subject MUST start with "patch: " and be a concise summary (<72 chars).
3) After committing, export a diff file to:
   .patches/<timestamp>_<summary>.diff
4) After export, stop and ask the user to review and add ### CV: comments.
5) When asked to "check review", only read review comments via ripgrep/targeted reads; do not read the entire diff unless necessary.
6) Review-driven changes should be *systemic when appropriate*: treat CV comments as signals to fix root causes, apply consistent changes across the codebase (search for similar patterns), and keep the patch series coherent (not just tiny local edits).
7) Before editing in Phase B, do a short "synthesis pass": summarize the review into a small plan (what to change, where, and why). Then implement the plan.

## Phase A: Implement + Commit + Export
1) Inspect working tree:
   - git status --porcelain
2) Make the minimal changes needed.
3) Run the smallest relevant tests/linters (choose based on repo conventions).
4) Show summary of changes:
   - git diff --stat
5) Stage and commit:
   - git add -A
   - git commit -m "patch: <summary>"
6) Export patch:
   - Ensure .patches exists
   - Use scripts/export_patch.sh to write the diff file and print its path.
7) Hand control back:
   - Tell user where the diff file is and ask them to review it (add ### CV comments) and then say "check review".

## Review comment format
- User will add comments in the diff file using:
  - "### CV: <comment>"
  - "### CV:<n> <comment>" means the line <n> lines below the marker is referenced (1-based offset).
- Comments may span multiple lines, up to ~10 lines total.

## Phase B: Check review loop
When the user says "check review", do:
1) Find CV blocks:
   - If user did not specify a diff file path, default to the most recent one:
     - ls -t .patches/*.diff | head -1
   - Use scripts/scan_review.sh <diff_file>
   - Parse all "### CV" markers and capture context (or the referenced line for "### CV:<n>").
2) Synthesis pass (write it out):
   - Summarize each CV comment into: "Issue" → "Decision" → "Files/areas touched" → "Risk/tests".
   - Propose a cohesive plan (prefer root-cause fixes and consistency across similar code paths).
   - If the plan is larger than the comment suggests, ask for confirmation before making sweeping changes.
3) Default action:
   - Unless the user explicitly asked for "report only", proceed to apply fixes based on the plan:
     - Apply fixes, run minimal tests, create a new "patch: ..." commit, export a new diff file, then ask for review again.
4) If the user asks to "approve merge" / "squash plan":
   - Propose 3 final squash commit message options.
   - Ask user to provide the final commit message they want.
   - Compute number of consecutive "patch:" commits from HEAD and print:
     - git rebase -i HEAD~<n>
   - Remind user to squash them into one commit with their final message.
