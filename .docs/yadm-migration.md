# 从 chezmoi 迁移到 yadm

> 状态：方案草案，尚未执行迁移
>
> 最后审阅：2026-09-03
>
> 原则：保留 Git 历史、不重写提交、不在验证前改变现有 dotfiles 的管理方式

## 1. 结论

采用一个长期存在的 `yadm` 分支，从当前 chezmoi `master` 分出：

- `master` 保留为最后可工作的 chezmoi 版本和回滚入口。
- `yadm` 包含一次普通的目录/语义转换提交以及后续 yadm 配置。
- 不使用 `git filter-branch`、`git filter-repo` 或 force-push。
- 迁移期间在单独的 Git worktree 中修改 `yadm` 分支，当前 chezmoi 工作目录继续停留在 `master`，避免影响日常使用。
- 验证通过后，正式机器通过 `yadm clone -b yadm` 使用新分支。是否将远端默认分支改为 `yadm`，留到稳定运行后决定。

这个方案保留完整历史，但存在一个明确边界：`yadm` 分支中，转换提交之前的提交仍然采用 `dot_config`、`executable_` 等 chezmoi source-state 命名。因此，不能在真实 `$HOME` yadm worktree 中直接 checkout 转换前的提交；查看旧历史应使用普通 Git clone/worktree。

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
- 本文档收录在最后的 chezmoi `master` 基线中。

以上提交均未推送。Neovim 的 `bdd35c7` 必须先由用户手动推送到 `neovim-config`，然后才能推送引用它的 dotfiles 父仓库提交和 final tag。

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

### 4.1 推荐拓扑

```text
... existing history ... -- C  master, tag: chezmoi-final-YYYYMMDD
                          \
                           M1 -- M2 -- M3  yadm
```

- `C`：修复 submodule 状态后，最后一个完整可用的 chezmoi 提交。
- `M1`：机械路径、文件模式和 submodule 路径转换。
- `M2`：alternates、templates 和 OS/class 语义转换。
- `M3`：bootstrap、ignore 规则、使用说明和验证修正。

建议先创建 tag 和分支，再创建独立 worktree；以下命令仅作为执行阶段参考，本方案阶段不运行：

```bash
git tag -a chezmoi-final-YYYYMMDD -m "Final chezmoi-managed state"
git branch yadm
git worktree add <temporary-worktree-path> yadm
```

### 4.2 稳定后的分支选择

优先保持：

- `master`：chezmoi 归档分支。
- `yadm`：日常使用分支。
- 新机器明确执行 `yadm clone -b yadm ...`。

稳定运行一段时间后可二选一：

1. 将远端默认分支改为 `yadm`，继续保留 `master`；这是推荐方案。
2. 将 `master` fast-forward 到 `yadm`，依靠 `chezmoi-final-*` tag 保存旧入口。

两种方式都不需要重写历史或 force-push。

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

当前方案文档暂存在 `.docs/yadm-migration.md`，因为隐藏目录不会被现有 chezmoi 当作 target。转换到 `yadm` 分支时，应将它移动为 `.config/yadm/docs/chezmoi-migration.md`。

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
mkdir -p "$YADM_TEST_ROOT/home/.config/yadm" "$YADM_TEST_ROOT/data"

yadm \
  --yadm-dir "$YADM_TEST_ROOT/home/.config/yadm" \
  --yadm-data "$YADM_TEST_ROOT/data" \
  clone -w "$YADM_TEST_ROOT/home" -b yadm --no-bootstrap \
  <repository-url-or-local-path>
```

此隔离 clone 只验证 checkout、alternate、template、mode 和 symlink。不要在这里直接运行 bootstrap，因为 bootstrap 默认以进程真实 `$HOME` 为目标。完整 bootstrap 应在一次性用户、容器或 VM 中验证。

分别验证：

#### Darwin

- proxychains 端口为 `7981`。
- Kitty、Hammerspoon 目标存在。
- GDB、i3、Polybar、XFCE4、picom、libinput-gestures 目标不存在。
- tmux symlink 目标正确。
- 所有应执行脚本具有 executable bit。

#### Linux，无 Desktop class

在临时 yadm 配置中执行 `yadm config local.os Linux`，然后运行 `yadm alt`：

- proxychains 端口为 `7890`。
- GDB 存在且 `env.HOME` 已渲染。
- Kitty、Hammerspoon 和桌面配置不存在。

#### Linux，Desktop class

再添加 `local.class=Desktop` 并运行 `yadm alt`：

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

切换前生成双重回滚点：

- 已推送的 `chezmoi-final-*` tag。
- 使用 `chezmoi archive --output=<outside-home-backup>.tar.gz` 保存当前渲染 target state。

切换原则：

1. 安装 yadm，但保留 chezmoi。
2. 先在本机 yadm 配置中关闭自动 alternate：

   ```bash
   yadm config yadm.auto-alt false
   ```

3. 不使用 `-f`，clone `yadm` 分支且不运行 bootstrap：

   ```bash
   yadm clone -b yadm --no-bootstrap git@github.com:JoverZhang/dotfiles.git
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

至少稳定运行数天后，才考虑更改远端默认分支或清理旧 chezmoi 环境。

## 13. 验收标准

迁移仅在全部满足时视为完成：

- `yadm status` 干净。
- `yadm submodule status --recursive` 成功。
- 当前 OS 不应部署的 alternate 目标不存在。
- `proxychains.conf` 端口与 OS 匹配。
- `.config/tmux/tmux.conf` 是预期相对 symlink。
- Ranger、Polybar、`.local/bin` 和 bootstrap 的 executable bit 正确。
- bootstrap 首次运行和第二次幂等运行均无关键失败。
- zsh、tmux、Neovim 可正常启动。
- `yadm list -a` 不包含插件 clone、yadm bare repo、chezmoi source repo、缓存或密钥。
- chezmoi tag、target archive 和旧 `master` 均可用于回滚。

## 14. 回滚

第一阶段回滚不删除任何数据：

1. 停止执行 yadm pull/checkout/bootstrap。
2. 将 yadm 创建的 alternate symlink 或模板输出移动到隔离备份目录。
3. 保留 `.local/share/yadm`，不要立即删除 bare repo。
4. 确认 chezmoi source 位于 `master` 或 `chezmoi-final-*` tag 对应提交。
5. 先运行 `chezmoi diff`，确认结果后再运行 `chezmoi apply`。
6. 若 target 内容仍不符合预期，从迁移前的 chezmoi archive 恢复。
7. 若已改变远端默认分支，将其改回 `master`。

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
