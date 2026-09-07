#!/usr/bin/env python3
"""Check a partial restore against existing unrelated files in a temporary HOME."""
import os
import shutil
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[3]
with tempfile.TemporaryDirectory(prefix="dotfiles-restore-test.") as temp:
    root = Path(temp)
    target = root / "home"
    target.mkdir()
    bin_dir = root / "bin"
    bin_dir.mkdir()
    wrapper = bin_dir / "yadm"
    # Global overrides isolate yadm without changing the process HOME.
    wrapper.write_text(
        '#!/bin/sh\nexec /usr/bin/env bash "${DOTFILES_TEST_YADM}" '
        '-Y "$DOTFILES_TEST_ROOT/home/.config/yadm" '
        '--yadm-data "$DOTFILES_TEST_ROOT/data" "$@"\n'
    )
    wrapper.chmod(0o755)
    yadm = shutil.which("yadm")
    if not yadm:
        raise SystemExit("yadm is required")
    env = dict(os.environ, DOTFILES_TEST_ROOT=str(root), DOTFILES_TEST_YADM=yadm)
    env["PATH"] = str(bin_dir) + os.pathsep + env["PATH"]

    def run(*args, input=None):
        result = subprocess.run(
            [str(wrapper), *args], cwd=target, env=env, input=input,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        if result.returncode:
            raise RuntimeError(f"yadm {args}:\n{result.stdout}\n{result.stderr}")
        return result.stdout

    fixtures = [
        ".config/nvim/init.lua", ".config/ranger/rc.conf",
        ".claude/commands/optimize.md", ".config/proxychains/proxychains.conf",
    ]
    for name in fixtures:
        path = target / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("existing unrelated config\n")

    run("config", "yadm.auto-alt", "false")
    run("init", "-w", str(target))
    run("gitconfig", "sparse.expectFilesOutsideOfPatterns", "true")
    run("remote", "add", "origin", str(repo))
    run("fetch", "origin", "HEAD")
    run("config", "local.class", "Agent")
    run("config", "local.components", "zsh tmux")
    run("sparse-checkout", "set", "--no-cone", "--stdin",
        input=(repo / ".config/yadm/sparse-shell").read_text())
    run("switch", "--detach", "FETCH_HEAD")
    run("alt")

    assert (target / ".config/zsh/profile.zsh").is_symlink()
    assert (target / ".zshrc").is_file()
    for name in fixtures:
        assert (target / name).read_text() == "existing unrelated config\n", name
    for name in [".gdbinit", ".local/bin/redis-cli", ".config/gdb"]:
        assert not os.path.lexists(target / name), name
    assert run("status", "--porcelain") == ""
    # Repeated alternate generation must preserve the same boundary.
    run("alt")
    assert run("status", "--porcelain") == ""
print("Partial restore preserved existing editor/agent files; yadm status is clean.")
