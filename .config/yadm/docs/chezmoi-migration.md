# 从 chezmoi 迁移到 yadm

> 状态：yadm 架构已在 macOS 验证并启用；Linux 主机待按第 12 节切换
>
> 最后审阅：2026-09-04
>
> 原则：保留 Git 历史、不重写提交、不在验证前改变现有 dotfiles 的管理方式

## 1. 结论

迁移先在独立的 `yadm` 分支完成和验证，验证通过后将其 fast-forward 合入
`master`。最终分支策略为：

- `master` 是后续日常使用的 yadm 分支，新机器从这里 clone。
- `chezmoi-final-20260903` tag 指向最后可工作的 chezmoi 提交，是旧架构回滚入口。
- `yadm` 保留为迁移过程分支；确认所有机器均使用 `master` 后可以再删除。
- 不使用 `git filter-branch`、`git filter-repo` 或 force-push。
- 新机器通过 `yadm clone -b master --no-bootstrap` 分阶段切换。

这个方案保留完整历史，但存在一个明确边界：`master` 中的转换提交之前仍然采用
`dot_config`、`executable_` 等 chezmoi source-state 命名。因此，不能在真实 `$HOME`
yadm worktree 中直接 checkout 转换前的提交；查看旧历史应使用普通 Git
clone/worktree。

## 2. 目标与非目标

### 目标

- macOS 和 Linux 上的最终文件内容与当前 chezmoi target state 等价。
- 保留当前 OS 差异：
  - macOS：Kitty、Hammerspoon。
  - Linux：GDB。
  - Linux 桌面配置：仅在显式启用 `Desktop` class 时部署。
- 保留 Neovim 和 zsh-file-manager 两个 Git submodule。
- 将依赖仓库同步脚本迁移为幂等的 yadm bootstrap。
- 保留可执行位和 tmux 符号链接语义。
- 可以在临时 worktree/临时 HOME 中验证，不直接试错真实配置。

### 非目标

- 不重写旧提交中的路径。
- 不迁移不存在的密钥或加密配置；当前仓库未使用 chezmoi 加密属性。
- 不在本次迁移中重新设计所有 shell、tmux、GDB 或 Neovim 配置。
- 不默认增加 `post_pull` hook；拉取 dotfiles 不应隐式触发多个外部仓库和 TPM 的联网更新。
- 第一阶段不删除 chezmoi 源目录、不卸载 chezmoi。

## 3. 当前状态审计

当前仓库的迁移面较小：初始审计时共有 45 个已跟踪 Git 索引条目（不含本文档）、3 个 gitlink、2 个实际 chezmoi 内容模板、1 个条件忽略模板、1 个 `run_onchange` 脚本、1 个符号链接描述文件和 5 个 `executable_` 文件。

### 3.1 迁移前必须处理的状态

截至 2026-09-03 的初始只读检查发现：

- chezmoi target state 已无内容差异。
- 主仓库将 `dot_config/nvim` 报告为修改：
  - 父仓库记录 `563c7f2`。
  - 当前 submodule checkout 为 `59ac92a`。
  - submodule 内 `lazy-lock.json` 仍有未提交修改。
- Git 索引包含 `dot_claude/skills-upstream` gitlink，但 `.gitmodules` 已没有对应条目；因此 `git submodule status` 会失败。

用户已选择并在本地完成以下收口：

- 保留 Neovim 当前状态：`lazy-lock.json` 已提交为 `bdd35c7`，父仓库已在 `b6594b1` 更新 gitlink。
- `dot_claude/skills-upstream` 孤立 gitlink 已在 `b6594b1` 删除。
- GDB 模板问题已在 `f8ffea4` 修复。
- 本文档收录在最后的 chezmoi 基线提交 `23d6ef8` 中。

Neovim 的 `bdd35c7`、dotfiles 的 chezmoi 基线以及
`chezmoi-final-20260903` tag 均已由用户推送，构成可用的远端回滚点。

在创建 `yadm` 基线之前，必须达到：

```text
git status --short                 无输出
chezmoi status                     无输出
git submodule status --recursive   成功且无错误
```

在创建本地 `yadm` 分支前只要求上述三个状态检查通过；在推送或供其他机器 clone 之前，还必须完成前述 submodule-first 推送顺序。

### 3.2 已发现的配置问题

原 `dot_config/gdb/gdbinit` 包含：

```text
source {{ .chezmoi.homeDir }}.config/gdb/gdb-dashboard/.gdbinit
```

该文件没有 `.tmpl` 后缀，而且 HOME 与 `.config` 之间缺少路径分隔符。最终 chezmoi 基线已将它重命名为 `gdbinit.tmpl`，并改用 `joinPath`；本地模板验证得到正确的 `/Users/jover/.config/gdb/gdb-dashboard/.gdbinit`。迁移到 yadm 时再将同一处表达式转换为 `{{ env.HOME }}`。文件中其他已有的 `/home/jover/...` 硬编码暂不扩展为本次迁移范围，后续可独立清理。

## 4. 分支与历史策略

### 4.1 最终拓扑

```text
... existing history ... -- C -- M1 -- M2 -- M3 -- M4 -- D  master
                           ^                       ^
                           |                       yadm（迁移分支）
                           tag: chezmoi-final-20260903
```

- `C`：修复 submodule 状态后，最后一个完整可用的 chezmoi 提交。
- `M1`：机械路径、文件模式和 submodule 路径转换。
- `M2`：alternates、templates 和 OS/class 语义转换。
- `M3`/`M4`：bootstrap、ignore 规则和验证修正。
- `D`：将文档和新机器操作入口切换为 `master`。

建议先创建 tag 和分支，再创建独立 worktree；以下命令仅作为执行阶段参考，本方案阶段不运行：

```bash
git tag -a chezmoi-final-YYYYMMDD -m "Final chezmoi-managed state"
git branch yadm
git worktree add <temporary-worktree-path> yadm
```

### 4.2 日常分支选择

最终约定：

- `master`：yadm 日常使用和远端默认分支。
- `chezmoi-final-20260903`：chezmoi 归档 tag。
- `yadm`：临时迁移分支，不再承载后续提交。
- 新机器明确执行 `yadm clone -b master ...`。

合并只使用 `git merge --ff-only yadm`，推送也不需要 force。确认远端 `master`
和各机器均已切换后，再决定是否删除 `yadm` 分支。

## 5. yadm 仓库布局

yadm 以 `$HOME` 为 worktree。推荐将普通共享文件直接放在真实目标路径，将 alternate/template 源文件集中放进 `.config/yadm/alt`，避免在实际配置目录旁出现带 `##` 的文件名。

```text
$HOME/
├── .claude/
├── .codex/
├── .config/
│   ├── bottom/
│   ├── h_command/
│   ├── lazygit/
│   ├── nvim/                         # submodule
│   ├── ranger/
│   ├── tmux/
│   ├── zsh/
│   │   └── zsh-file-manager/         # submodule
│   └── yadm/
│       ├── alt/                      # OS/class alternates 和 templates
│       ├── bootstrap                 # executable
│       └── docs/chezmoi-migration.md
├── .hammerspoon/                     # macOS alternate 生成目标
├── .local/bin/
├── .gitignore                        # 只忽略精确列出的依赖/管理器目录
└── .gitmodules
```

yadm 自身的 bare repository 位于 `.local/share/yadm/repo.git`，绝不能被 yadm 仓库再次跟踪。

本文档已随转换移动到 `.config/yadm/docs/chezmoi-migration.md`。

## 6. 路径转换

### 6.1 普通路径

| chezmoi source | yadm 路径 | 处理 |
|---|---|---|
| `dot_claude/**` | `.claude/**` | 普通移动；孤立 gitlink 除外 |
| `dot_codex/**` | `.codex/**` | 普通移动 |
| `dot_config/**` | `.config/**` | 先机械移动，再分离 alternates |
| `dot_hammerspoon/**` | `.config/yadm/alt/.hammerspoon/**##os.Darwin` | macOS alternate |
| `dot_local/**` | `.local/**` | 普通移动 |

应先做机械 `git mv` 并提交或至少检查 rename detection，再做模板内容改写。这样审阅时更容易区分“路径变化”和“行为变化”。

### 6.2 chezmoi 特殊属性

| 现有 source | yadm 结果 |
|---|---|
| `dot_config/tmux/symlink_tmux.conf` | 真正的 `.config/tmux/tmux.conf` symlink，目标仍为 `./oh-my-tmux/.tmux.conf` |
| `dot_config/polybar/executable_launch.sh` | `.config/polybar/launch.sh`，Git mode `100755` |
| `dot_config/polybar/scripts/executable_nvidia-state.sh` | `.config/polybar/scripts/nvidia-state.sh`，Git mode `100755` |
| `dot_config/polybar/scripts/executable_toggle-cpu.sh` | `.config/polybar/scripts/toggle-cpu.sh`，Git mode `100755` |
| `dot_config/ranger/executable_scope.sh` | `.config/ranger/scope.sh`，Git mode `100755` |
| `dot_local/bin/executable_launch_mira` | `.local/bin/launch_mira`，Git mode `100755` |
| `run_onchange_after_sync_deps.sh.tmpl` | `.config/yadm/bootstrap`，Git mode `100755` |
| `.chezmoidata.yaml` | 内容并入 alternate/template/bootstrap 后删除 |
| `.chezmoiignore.tmpl` | 规则迁移完成后删除 |

`dot_codex/skills/patch-review-loop/tests/run.sh` 已经是 Git mode `100755`，只需在路径移动后保持模式。

## 7. OS 与机器类型转换

yadm alternate 条件使用 `##os.<OS>` 和 `##class.<Class>`。方案使用 yadm 内建 OS 值 `Darwin`/`Linux`，并引入本机 class `Desktop`。

### 7.1 alternate 清单

所有下列 source 都放入 `.config/yadm/alt`，并按相对于 `$HOME` 的路径组织：

| 当前配置 | yadm alternate source | 目标 |
|---|---|---|
| Kitty | `.config/yadm/alt/.config/kitty/kitty.conf##os.Darwin` | `.config/kitty/kitty.conf` |
| Hammerspoon | `.config/yadm/alt/.hammerspoon/init.lua##os.Darwin` | `.hammerspoon/init.lua` |
| GDB | `.config/yadm/alt/.config/gdb/gdbinit##os.Linux,template` | `.config/gdb/gdbinit` |
| i3 全部文件 | 每个文件添加 `##os.Linux,class.Desktop` | 原路径 |
| Polybar 全部文件 | 每个文件添加 `##os.Linux,class.Desktop` | 原路径 |
| XFCE4 全部文件 | 每个文件添加 `##os.Linux,class.Desktop` | 原路径 |
| libinput-gestures | 文件添加 `##os.Linux,class.Desktop` | 原路径 |
| picom | 文件添加 `##os.Linux,class.Desktop` | 原路径 |

使用逐文件 alternate，而不是给整个目录添加条件，原因是：

- `.config/gdb`、`.config/tmux` 等目录内还会出现 bootstrap 管理但不由 yadm 跟踪的仓库。
- 逐文件链接不会占用整个目录，运行时生成的缓存或插件可以共存。
- 切换和回滚时可以逐文件核对，降低误覆盖目录的风险。

默认保留 yadm 的 symlink alternate 行为，不设置 `yadm.alt-copy=true`。这样修改目标文件就是修改受版本控制的 alternate source，不会产生“改了生成副本但 Git 看不到”的漂移。模板输出仍是生成的普通文件。

### 7.2 Desktop class

`Desktop` 是每台机器的本地设置，不进入 Git：

```bash
yadm config --add local.class Desktop
yadm alt
```

服务器或无 GUI 的 Linux 不设置该 class。`.config/yadm/config` 保持未跟踪，因为它包含每台机器不同的 `local.class`。

## 8. 模板转换

优先使用 yadm 内置模板处理器，不增加 Jinja、envtpl 或 esh 依赖。

### 8.1 proxychains

source 路径：

```text
.config/yadm/alt/.config/proxychains/proxychains.conf##template,extension.conf
```

文件主体保持不变，只将末尾端口逻辑替换为：

```jinja
{% if yadm.os == "Darwin" %}
socks5 127.0.0.1 7981
{% else %}
socks5 127.0.0.1 7890
{% endif %}
```

这里的 `else` 表示非 Darwin 使用现有 Linux 默认值。若未来加入 WSL 或其他系统，再改为显式 alternate/模板分支。

### 8.2 GDB

GDB source 同时带 Linux 和 template 条件：

```text
.config/yadm/alt/.config/gdb/gdbinit##os.Linux,template
```

首行改为：

```text
source {{ env.HOME }}/.config/gdb/gdb-dashboard/.gdbinit
```

这同时修复当前缺失 `.tmpl` 导致的未渲染问题。

## 9. Submodule 策略

保留两个有效 submodule，并只改变 worktree 路径：

| 当前路径 | yadm 路径 |
|---|---|
| `dot_config/nvim` | `.config/nvim` |
| `dot_config/zsh/zsh-file-manager` | `.config/zsh/zsh-file-manager` |

`.gitmodules` 中的 `path` 一并修改，URL 保持不变。`dot_claude/skills-upstream` 残留 gitlink 在最终 chezmoi 基线中删除，不进入 yadm 分支。

bootstrap 的第一个关键步骤应为：

```bash
cd "$HOME"
yadm submodule sync --recursive
yadm submodule update --init --recursive
```

submodule 初始化失败应使 bootstrap 失败；它不同于可选插件更新，不能静默忽略。

## 10. Bootstrap 策略

将现有 `run_onchange_after_sync_deps.sh.tmpl` 改为不依赖 chezmoi 模板的 `.config/yadm/bootstrap`：

1. 初始化两个 yadm submodule。
2. clone 或 fast-forward 更新以下外部依赖：
   - oh-my-zsh
   - zsh-autosuggestions
   - zsh-syntax-highlighting
   - fzf
   - oh-my-tmux
   - TPM
3. 仅当 `uname -s` 为 `Linux` 时处理 gdb-dashboard。
4. 执行 TPM install/update。
5. 保持幂等，允许多次运行。

错误策略：

- submodule 初始化属于关键步骤，失败即返回非零。
- 外部插件 pull 和 TPM 更新延续当前 best-effort 策略，但最终摘要必须准确报告失败项，不能无条件打印“全部完成”。

不默认创建 `post_pull` hook。依赖清单变化后手动执行：

```bash
yadm bootstrap
```

新机器首次 clone 时也先用 `--no-bootstrap` 完成 class、alternates 和内容核对，再显式运行 bootstrap。

## 11. Ignore 策略

yadm 默认不显示未跟踪文件，但仍应跟踪一个仅含精确绝对模式的 `$HOME/.gitignore`，防止误执行 `yadm add .config` 时把插件仓库或管理器自身加入索引。

建议规则：

```gitignore
/.local/share/yadm/
/.local/share/chezmoi/
/.config/yadm/config

/.config/zsh/ohmyzsh/
/.config/zsh/zsh-autosuggestions/
/.config/zsh/zsh-syntax-highlighting/
/.config/zsh/fzf/
/.config/tmux/oh-my-tmux/
/.config/tmux/plugins/
/.config/gdb/gdb-dashboard/
```

不要忽略 `.config/nvim` 或 `.config/zsh/zsh-file-manager`，它们是正式 submodule。

日常操作约束：

- 使用 `yadm add <明确路径>` 或 `yadm add -u :/`。
- 不从 `$HOME` 运行 `yadm add .` 或 `yadm add -A`。
- 需要审计未跟踪文件时使用 `yadm status -unormal`，预期输出可能很多。

## 12. 实施阶段

### 阶段 0：冻结有效 chezmoi 基线

- 解决 Neovim submodule checkout、`lazy-lock.json` 和父仓库指针。
- 删除 `dot_claude/skills-upstream` 孤立 gitlink。
- 确认主仓库、所有 submodule、chezmoi target state 都干净。
- 创建并推送 `chezmoi-final-YYYYMMDD` tag。

退出条件：第 3.1 节三个检查全部通过。

### 阶段 1：创建隔离的 yadm 工作区

- 从最终 chezmoi 提交创建 `yadm` 分支。
- 在临时目录创建 Git worktree。
- 当前 `~/.local/share/chezmoi` 工作目录保持在 `master`。

退出条件：两个 worktree 分支互不切换，chezmoi 仍可正常 diff/apply。

### 阶段 2：机械转换

- 将 `dot_*` 路径改成真实 `$HOME` 相对路径。
- 移除 `executable_`/`symlink_` 命名并设置正确 Git mode/type。
- 修改两个 submodule 路径和 `.gitmodules`。
- 将本方案文档移到 `.config/yadm/docs/chezmoi-migration.md`。

退出条件：所有路径都能映射到预期目标，没有内容逻辑修改混入本阶段。

### 阶段 3：行为转换

- 将 OS/desktop 条件文件移入 `.config/yadm/alt`。
- 转换 proxychains 和 GDB 模板。
- 添加 bootstrap 和精确 `.gitignore`。
- 删除 `.chezmoidata.yaml`、`.chezmoiignore.tmpl` 和原 `run_onchange` source。

退出条件：分支 HEAD 不再含任何 chezmoi 特殊 source-state 名称或 Go-template 引用。

可使用以下静态扫描作为检查：

```bash
git ls-files | rg '(^|/)(dot_|executable_|symlink_|run_)|\.tmpl$|^\.chezmoi'
git grep -n -E '\{\{[^}]*chezmoi|\.chezmoi\.' -- ':!*.md'
```

两条命令均应无输出；第二条排除迁移文档，只检查非 Markdown 文件中的残留 Go-template 引用。

### 阶段 4：隔离验证

使用临时 worktree 和独立 yadm data 目录 clone，不改真实 `$HOME`。示意：

```bash
YADM_TEST_ROOT="$(mktemp -d)"
mkdir -p "$YADM_TEST_ROOT/home" "$YADM_TEST_ROOT/data"

yadm_test() {
  yadm \
    --yadm-dir "$YADM_TEST_ROOT/home/.config/yadm" \
    --yadm-data "$YADM_TEST_ROOT/data" \
    "$@"
}

# 必须在 clone 之前写入 yadm 自身的配置文件。
yadm_test config yadm.auto-alt false

yadm_test clone -w "$YADM_TEST_ROOT/home" -b master --no-bootstrap \
  <repository-url-or-local-path>

# clone 已结束，新进程会从 repo 的 core.worktree 读取临时 HOME。
yadm_test alt
```

这一步不能只向底层 `git clone` 传入 `-c yadm.auto-alt=false`；`yadm.auto-alt`
读取的是 `$YADM_TEST_ROOT/home/.config/yadm/config`。yadm 3.5.0 在同一进程执行
`clone -w` 后的自动 alternate 阶段仍可能以进程真实 `$HOME` 计算路径，因此必须在
clone 前按上例关闭自动 alternate，再于 clone 完成后的新进程中显式运行 `yadm alt`。

此隔离 clone 只验证 checkout、alternate、template、mode 和 symlink。不要在这里直接运行 bootstrap，因为 bootstrap 默认以进程真实 `$HOME` 为目标。完整 bootstrap 应在一次性用户、容器或 VM 中验证。

OS 矩阵优先为每个场景创建新的 `YADM_TEST_ROOT`。yadm 3.5.0 会清理不再匹配的
symlink alternate，但不会自动删除先前渲染的普通模板输出；如果复用同一测试根从
Linux 切回 Darwin，应先将临时的 `.config/gdb/gdbinit` 移出 worktree，再运行
`yadm_test alt`。真实 HOME 遇到同类情况时也只能先备份，不能直接删除。

分别验证：

#### Darwin

- proxychains 端口为 `7981`。
- Kitty、Hammerspoon 目标存在。
- GDB、i3、Polybar、XFCE4、picom、libinput-gestures 目标不存在。
- tmux symlink 目标正确。
- 所有应执行脚本具有 executable bit。

#### Linux，无 Desktop class

在临时 yadm 配置中执行 `yadm_test config local.os Linux`，然后运行
`yadm_test alt`：

- proxychains 端口为 `7890`。
- GDB 存在且 `env.HOME` 已渲染。
- Kitty、Hammerspoon 和桌面配置不存在。

#### Linux，Desktop class

再执行 `yadm_test config local.class Desktop` 和 `yadm_test alt`：

- i3、Polybar、XFCE4、picom、libinput-gestures 全部存在。
- Polybar 脚本 executable bit 正确。

#### 通用检查

- `yadm list -a` 只包含预期文件。
- `yadm status` 干净。
- 两个 submodule 路径和记录的 commit 正确。
- `bash -n .config/yadm/bootstrap` 通过。
- 在 disposable Linux/macOS 环境中，bootstrap 连续运行两次都成功。
- bootstrap 管理的第三方仓库没有被 yadm 索引跟踪。

### 阶段 5：真实机器切换

切换前准备两类回滚点：

- 已推送的 `chezmoi-final-*` tag。
- 将本次会被替换的 submodule 目录和 alternate 目标定点备份到 `$HOME` 外。
- `chezmoi archive` 是可选的额外保险；当 chezmoi 状态干净、基线和 tag 均已推送时，
  它不是切换的前置条件。

切换原则：

1. 安装 yadm，但保留 chezmoi。
2. 先在本机 yadm 配置中关闭自动 alternate：

   ```bash
   yadm config yadm.auto-alt false
   ```

3. 不使用 `-f`，clone `master` 且不运行 bootstrap：

   ```bash
   yadm clone -b master --no-bootstrap git@github.com:JoverZhang/dotfiles.git
   ```

4. 用 `yadm status`/`yadm diff` 处理直接跟踪文件与现有 `$HOME` 文件的差异。
5. 对当前 OS 的 alternate 目标逐文件比较并移动到备份位置；不要删除整个 `.config` 子目录，也不要移动其中的插件仓库或运行时数据。
6. Linux 桌面机设置 `local.class=Desktop`；其他机器不设置。
7. 重新启用自动 alternate 并生成目标：

   ```bash
   yadm config yadm.auto-alt true
   yadm alt
   ```

8. 再次检查 status、内容、symlink 和 executable bit。
9. 显式执行 `yadm bootstrap`。
10. 打开新 shell，验证 zsh、tmux、Neovim 和相关 GUI 配置。

至少稳定运行数天后，才清理旧 chezmoi 环境、定点备份或 `yadm` 迁移分支。

### 12.1 Linux 主机切换清单

以下步骤适用于仍由 chezmoi 管理、尚未初始化 yadm 的 Linux。先确认远端
`master` 已包含迁移提交，再开始：

1. 确认旧状态干净，并检查 bootstrap 管理的第三方仓库是否有本地修改：

   ```bash
   chezmoi status
   git -C "$HOME/.local/share/chezmoi" status --short
   ```

   两项应无输出。第三方仓库若有修改，先导出 patch 或单独备份；bootstrap 使用
   `git pull --ff-only`，不会 reset 本地修改，但更新可能失败并被列入最终摘要。

2. 安装 yadm，关闭自动 alternate，然后安全 clone：

   ```bash
   yadm config yadm.auto-alt false
   test "$(yadm config --bool yadm.auto-alt)" = false
   yadm clone -b master --no-bootstrap \
     git@github.com:JoverZhang/dotfiles.git
   yadm status --short
   ```

   clone 提示 HOME 中已有不同文件是预期的；不要执行 `yadm checkout "$HOME"`。
   先逐项核对差异。

3. 在 `$HOME` 外创建 mode `0700` 的定点备份目录，并移动以下已存在目标：

   - 两个普通目录：`.config/nvim`、`.config/zsh/zsh-file-manager`。
   - 通用 alternate 目标：`.config/proxychains/proxychains.conf`。
   - Linux alternate 目标：`.config/gdb/gdbinit`。
   - 若为桌面机，再处理这些具体目标：
     - `.config/i3/config`
     - `.config/i3/jover/autostart.conf`
     - `.config/i3/jover/black-2880x1800.png`
     - `.config/i3/jover/i3status.conf`
     - `.config/polybar/config.ini`
     - `.config/polybar/launch.sh`
     - `.config/polybar/scripts/nvidia-state.sh`
     - `.config/polybar/scripts/toggle-cpu.sh`
     - `.config/polybar/test-fonts.py`
     - `.config/xfce4/terminal/accels.scm`
     - `.config/xfce4/terminal/terminalrc`
     - `.config/libinput-gestures.conf`
     - `.config/picom.conf`

   只移动清单中的文件或两个明确的 submodule 目录，不要整体移动 `.config`、i3、
   Polybar、XFCE4 或 GDB 目录，因为其中可能有不受 yadm 管理的运行时文件。

4. 设置机器 class。桌面 Linux 使用：

   ```bash
   yadm config --replace-all local.class Desktop
   ```

   服务器或无 GUI Linux 不设置 class；若曾设置过，执行：

   ```bash
   yadm config --unset-all local.class
   ```

5. 初始化 submodule，再显式生成 alternates：

   ```bash
   cd "$HOME"
   yadm submodule sync --recursive
   yadm submodule update --init --recursive
   yadm alt
   yadm status --short
   ```

6. 验证 Linux 结果：proxychains 端口为 `7890`；GDB 首行含当前 `$HOME`；
   Kitty 和 Hammerspoon 的 Darwin 目标没有被创建；桌面机的 i3/Polybar/XFCE4、
   picom 和 libinput-gestures 目标存在。确认无误后启用自动 alternate：

   ```bash
   yadm config yadm.auto-alt true
   yadm alt
   ```

7. 最后运行依赖同步并做启动检查：

   ```bash
   yadm bootstrap
   yadm status --short
   ```

   新开 shell，并验证 zsh、tmux 和 Neovim；桌面机再验证相应 GUI 配置。稳定运行前
   保留 chezmoi、`chezmoi-final-*` tag 和 `$HOME` 外的定点备份。

## 13. 验收标准

迁移仅在全部满足时视为完成：

- `yadm status` 干净。
- 从 `$YADM_TEST_ROOT/home` 运行 `yadm_test submodule status --recursive` 成功。
- 当前 OS 不应部署的 alternate 目标不存在。
- `proxychains.conf` 端口与 OS 匹配。
- `.config/tmux/tmux.conf` 是预期相对 symlink。
- Ranger、Polybar、`.local/bin` 和 bootstrap 的 executable bit 正确。
- bootstrap 首次运行和第二次幂等运行均无关键失败。
- zsh、tmux、Neovim 可正常启动。
- `yadm list -a` 不包含插件 clone、yadm bare repo、chezmoi source repo、缓存或密钥。
- chezmoi tag 和 `$HOME` 外的定点备份均可用于回滚；若额外创建了 target archive，
  也保留到稳定期结束。

## 14. 回滚

第一阶段回滚不删除任何数据：

1. 停止执行 yadm pull/checkout/bootstrap。
2. 将 yadm 创建的 alternate symlink 或模板输出移动到隔离备份目录。
3. 保留 `.local/share/yadm`，不要立即删除 bare repo。
4. 在普通 Git worktree 中从 `chezmoi-final-*` tag 恢复 chezmoi source；不要在真实
   `$HOME` 的 yadm worktree checkout 该 tag。
5. 先运行 `chezmoi diff`，确认结果后再运行 `chezmoi apply`。
6. 若 target 内容仍不符合预期，从迁移前的 chezmoi archive 恢复。
7. 远端 `master` 保留 yadm 历史；不需要为本机回滚强推或改写远端分支。

只有在回滚验证完成或 yadm 长期稳定后，才清理临时 worktree、备份或旧管理器数据。

## 15. 官方参考

- [yadm Overview](https://yadm.io/docs/overview)
- [yadm Alternate Files](https://yadm.io/docs/alternates)
- [yadm Templates](https://yadm.io/docs/templates)
- [yadm Bootstrap](https://yadm.io/docs/bootstrap)
- [yadm Hooks](https://yadm.io/docs/hooks)
- [yadm Getting Started](https://yadm.io/docs/getting_started)
- [yadm manual](https://github.com/yadm-dev/yadm/blob/develop/yadm.1)
- [chezmoi source-state attributes](https://www.chezmoi.io/reference/source-state-attributes/)
- [chezmoi scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
