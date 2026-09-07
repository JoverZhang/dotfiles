# Migrating a TPM checkout modified by Oh My Tmux

Older Oh My Tmux installations may have patched TPM's installation, loading,
and update scripts. Bootstrap deliberately refuses to overwrite these changes.
Use this procedure once if it reports that TPM has local changes.

## Inspect and back up

For a yadm installation, locate the checkout with:

```bash
dotfiles_root=$(yadm rev-parse --show-toplevel)
tpm_dir="$dotfiles_root/.config/tmux/plugins/tpm"
git -C "$tpm_dir" remote -v
git -C "$tpm_dir" status --short
git -C "$tpm_dir" diff
git -C "$tpm_dir" diff --cached
```

For a normal Git checkout, run from that checkout and use
`dotfiles_root=$(git rev-parse --show-toplevel)` instead.

Confirm this is the expected TPM repository. Generated changes usually add
shallow cloning, parallel installation, or plugin error reporting in:

- `scripts/install_plugins.sh`
- `scripts/source_plugins.sh`
- `scripts/update_plugin.sh`

File names alone do not establish that a change was generated. Inspect both
staged and unstaged differences. If they include intentional edits, preserve
those in a TPM fork and adjust the submodule URL/version accordingly; do not
discard them using the restore command below.

Before restoring anything, make a complete snapshot. Copy the Git metadata
separately as well: a submodule's `.git` may be a pointer outside its directory.
This saves untracked files, the index, refs, objects, and nested module metadata.

```bash
backup_parent="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-backups"
mkdir -p "$backup_parent" &&
tpm_backup=$(mktemp -d "$backup_parent/tpm.XXXXXX") &&
tpm_gitdir=$(git -C "$tpm_dir" rev-parse --absolute-git-dir) &&
cp -a "$tpm_dir" "$tpm_backup/checkout" &&
cp -a "$tpm_gitdir" "$tpm_backup/gitdir" &&
printf '%s\n' "$tpm_gitdir" > "$tpm_backup/gitdir-location.txt" &&
git -C "$tpm_dir" diff --binary HEAD > "$tpm_backup/changes.patch" &&
printf 'Backup completed: %s\n' "$tpm_backup"
```

Stop if this does not print `Backup completed`. Keep the snapshot until the new
configuration works. Its Git pointers still describe the original layout;
inspect the saved patch or files directly, rather than running Git in the copy.

## Restore only confirmed generated changes

After reviewing the differences and completing the backup, restore the three
scripts only if their changes are entirely generated:

```bash
git -C "$tpm_dir" restore --source=HEAD --staged --worktree -- \
  scripts/install_plugins.sh \
  scripts/source_plugins.sh \
  scripts/update_plugin.sh &&
"$dotfiles_root/.local/bin/dotfiles-submodules" sync tpm
```

Other local changes still cause `sync` to stop. Inspect those separately; do not
use a blanket reset or clean to bypass the check. Once TPM is clean, rerun
`yadm bootstrap` (or `.config/yadm/bootstrap` in a normal checkout).

This procedure changes TPM's tracked files. Existing plugin repositories and
tmux sessions are preserved. Intentional customizations can be recovered from
the snapshot and maintained in a TPM fork.
