# Restore Dotfiles with yadm

This repository restores the same dotfiles on macOS and Linux. The yadm work
tree is `$HOME`, and restored devices use the `master` branch.

Install Git and yadm, and make sure the device can access this repository over
SSH.

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
