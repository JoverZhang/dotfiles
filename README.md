# Restore Dotfiles with yadm

This repository restores the same dotfiles on macOS and Linux. The yadm work
tree is `$HOME`, and restored devices use the `master` branch.

Install Git and yadm, and make sure the device can access this repository over
SSH. To restore only the terminal configuration on an agent account, use
[the partial restore](#restore-only-zsh-and-tmux) instead of the full clone below.

## Clone the Repository

Disable automatic alternates until the platform has been selected, then clone
without running the bootstrap script:

```bash
yadm config yadm.auto-alt false

yadm clone -b master --no-bootstrap \
  git@github.com:JoverZhang/dotfiles.git
```

On a new device, continue with [Select the Platform](#select-the-platform).

On an existing device, first inspect any files that differ from the repository:

```bash
cd "$HOME"
yadm status --short
yadm diff
```

Back up each conflicting file outside `$HOME`, then restore only the paths you
intend to replace:

```bash
yadm checkout -- .path/to/file
```

Do not run `yadm checkout "$HOME"` or move the entire `.config` directory.

## Select the Platform

yadm detects the operating system automatically from `uname`; it matches macOS
as `Darwin` and Linux as `Linux`. Only Linux desktop systems need an additional
class.

| Platform | Selection |
| --- | --- |
| macOS | `os=Darwin`, detected automatically |
| Standard Linux or server | `os=Linux`, detected automatically |
| Linux desktop | `os=Linux` plus `class=Desktop` |

For a Linux desktop, set the local class:

```bash
yadm config --replace-all local.class Desktop
```

For macOS or standard Linux, clear any class left from an earlier setup:

```bash
yadm config --unset-all local.class 2>/dev/null || true
```

The class is stored only in the device's local yadm configuration and is not
committed to the repository.

## Complete the Restore

Generate the files for the selected platform and install the tracked submodules
and external dependencies:

```bash
cd "$HOME"
yadm alt
yadm bootstrap

yadm config yadm.auto-alt true
```

Verify the restored repository:

```bash
yadm status --short
yadm submodule status --recursive
```

`yadm status --short` should produce no output.

## Restore Only zsh and tmux

This uses yadm's Git sparse checkout, the `Agent` class, and a local bootstrap
component selection. All three are needed: sparse checkout selects files, the
class excludes platform alternates and workstation shell commands, and the
component selection limits dependency installation. Existing editor and agent
configuration is outside this checkout.

On an account without a yadm repository, first back up any existing `.zshrc`,
`.gitignore`, and files in `.config/zsh` and `.config/tmux` that will be replaced.
Use an empty yadm index until sparse checkout is configured, so unrelated files
already in HOME are never treated as files to remove.

```bash
yadm config yadm.auto-alt false
yadm init
yadm remote add origin git@github.com:JoverZhang/dotfiles.git
yadm fetch origin master
yadm config local.class Agent
yadm config local.components 'zsh tmux'
yadm show origin/master:.config/yadm/sparse-shell |
  yadm sparse-checkout set --no-cone --stdin
yadm switch -c master --track origin/master
yadm alt
yadm config yadm.auto-alt true
yadm bootstrap
```

For an independently maintained fork, use its URL and branch in these commands
and keep this repository as the `upstream` remote. The initial checkout refuses
to overwrite conflicting files; resolve only the named conflicts using the
backups. Do not force checkout the entire HOME.

`Agent` uses a small prompt and disables Oh My Zsh update prompts. Without that
class, the existing custom prompt and workstation commands remain enabled.
Account-specific paths, runtime initialization, and aliases can be tracked as
`.config/yadm/alt/.config/zsh/local.zsh##user.<username>` in your fork. Run
`yadm alt` after adding one. It is loaded after the shared shell configuration
and before ccmux/zoxide initialization. Keep credentials out of these files.

The default bootstrap selection is `all`. Other supported components are
`submodules`, `zsh`, `tmux`, and `gdb`. Set `local.components` to a space-separated
list, or override one run with `DOTFILES_COMPONENTS='zsh tmux' yadm bootstrap`.
The zsh component requires an installed fzf binary; modern versions provide
their own shell integration. History substring search is bundled with Oh My Zsh.
Dependency failures produce a nonzero exit status.

To return to a full restore, first inspect and back up conflicts outside the
current sparse selection. Then disable sparse checkout, clear `local.components`,
select the intended platform class, and follow the full restore instructions.

## Shared Shell Behavior

The tracked `.zshrc` loads `.config/zsh/zshrc.sh` for interactive shells.

| Key | Behavior |
| --- | --- |
| Tab | Search zsh completion candidates with fzf-tab; `,` / `.` switch groups |
| Ctrl-R | Search command history with fuzzy matching in a half-height list |
| Up/Down, Ctrl-P/N | Cycle history entries containing the current input |
| Ctrl-F | Open ranger and change to the selected directory, preserving input |
| Alt-C outside tmux | Select a directory with fzf and change into it |
| Alt-C inside tmux | Open the ccmux popup |

History retains repeated commands in order, with a 200,000-entry save limit;
search results are deduplicated. Autosuggestions try history, then completion.
The shared configuration also enables bracket highlighting and directory
previews on Linux/macOS. Optional tools are loaded only when available.

tmux retains the existing C-a prefix, pane/window bindings, clipboard settings,
Catppuccin colors, and resurrect bindings. Starting or reloading tmux does not
update plugins; run `yadm bootstrap` or use `<prefix> u` explicitly. Clipboard
forwarding and icon rendering also depend on the connecting terminal.
