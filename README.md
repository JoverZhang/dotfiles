# Restore Dotfiles with yadm

Dotfiles for macOS and Linux, managed by yadm in `$HOME` on the `master` branch.

Install Git, yadm, zsh, tmux, and fzf with your system package manager. The
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

This installs all tracked submodules and external shell/tmux dependencies,
plus gdb-dashboard on Linux.

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

Start a new zsh session with `exec zsh`, then run `tmux` when needed.
`yadm status --short` shows local changes and is empty after a clean installation.

To update dotfiles and their dependencies:

```bash
yadm pull --ff-only
yadm bootstrap
```

Bootstrap uses the saved `local.components` selection, or `all` when unset.
It downloads dependencies; system packages are installed separately.
