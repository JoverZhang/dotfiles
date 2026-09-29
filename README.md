# Restore Dotfiles with yadm

Dotfiles for macOS and Linux, managed by yadm in `$HOME` on the `master` branch.

Install Git, yadm, zsh, tmux, and fzf 0.48.0+ with your system package manager. The
commands below require GitHub SSH access. If using a fork, substitute its URL.

Choose one installation method below for a fresh account without a yadm repository.

## Full Installation

```bash
yadm config yadm.auto-alt false
yadm clone -b master --no-bootstrap \
  git@github.com:JoverZhang/dotfiles.git
```

macOS and Linux are detected automatically. On a Linux desktop, also select
the desktop configuration:

```bash
yadm config local.class Desktop
```

Create the platform-specific links and install dependencies:

```bash
yadm alt
yadm config yadm.auto-alt true
yadm bootstrap
```

This initializes all tracked submodules, installs Oh My Zsh if missing,
and installs gdb-dashboard on Linux.

## zsh and tmux Only

Use the `Agent` profile for terminal configuration with a simple prompt,
without editor configurations or workstation-specific shell initialization.

```bash
yadm config yadm.auto-alt false
yadm init
yadm gitconfig sparse.expectFilesOutsideOfPatterns true
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

## Use and Update

Keep machine-specific environment variables and aliases in
`~/.config/zsh/local.zsh`, a private regular file ignored by yadm. It is loaded
after the shared and optional personal configuration. Create it if needed;
yadm does not provide or synchronize it.

Start a new zsh session with `exec zsh`, then run `tmux` when needed.
Antidote installs the zsh plugins on the first interactive startup. In tmux,
press `Ctrl-A`, then `I` to install plugins with TPM.
`yadm status --short` shows local changes and is empty after a clean installation.

To update dotfiles and synchronize their recorded framework versions:

```bash
yadm pull --ff-only
yadm bootstrap
```

Bootstrap uses the saved `local.components` selection, or `all` when unset.
System packages are installed and updated separately.

Use `dotfiles-submodules` to manage framework versions:

```bash
dotfiles-submodules status
dotfiles-submodules update oh-my-tmux tpm   # fetch newer upstream versions
```

`dotfiles-submodules pin NAME TAG_OR_COMMIT` selects a specific version.
`dotfiles-submodules sync oh-my-tmux tpm` restores the recorded versions.
Names include `oh-my-tmux`, `tpm`, and `antidote`. Changes are left
unstaged: review with `yadm diff --submodule=log`, then use `yadm add` and
`yadm commit` to record the selected versions. Run `dotfiles-submodules --help`
for usage from a normal Git checkout.

Oh My Zsh manages its own updates, prompting periodically by default; run
`omz update` to update it manually. Bootstrap leaves an existing OMZ checkout alone.
Update zsh plugins with `antidote update --bundles`; update tmux plugins with
`Ctrl-A`, then `u`. Plugin versions are maintained by their plugin managers.
