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
    - cat
    - rg
    - sed
    - awk
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
   - Tell user where the diff file is and ask if they want adjustments.

## Review comment format
- User will add comments in the diff file using:
  - "### CV: <comment>"
  - "### CV:<n> <comment>" means the line <n> lines below the marker is referenced (1-based offset).
- Comments may span multiple lines, up to ~10 lines total.

## Phase B: Check review loop
When the user says "check review", do:
1) Find CV blocks:
   - Use scripts/scan_review.sh <diff_file>
   - Parse all "### CV" markers and capture context (or the referenced line for "### CV:<n>").
2) Present 4 options:
   (1) Report review findings only
   (2) Apply fixes based on review
   (3) Approve merge (prepare squash plan)
   (4) Other (ask for extra prompt)
3) If option (2):
   - Apply fixes, run minimal tests, create a new "patch: ..." commit, export a new diff file, then ask for review again.
4) If option (3):
   - Propose 3 final squash commit message options.
   - Ask user to provide the final commit message they want.
   - Compute number of consecutive "patch:" commits from HEAD and print:
     - git rebase -i HEAD~<n>
   - Remind user to squash them into one commit with their final message.
