# Shared interactive shell configuration. Loaded by ~/.zshrc.
[[ -o interactive ]] || return 0
ZSH_ROOT=${${(%):-%N}:A:h}
DOTFILES_ZSH_PERSONAL=true
[[ -r "$ZSH_ROOT/profile.zsh" ]] && source "$ZSH_ROOT/profile.zsh"

typeset -U path PATH
path=("$HOME/.local/bin" $path)

export ZSH="$ZSH_ROOT/ohmyzsh"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
export EDITOR="${EDITOR:-nvim}"
# Keep prompt/completion caches outside the yadm work tree's tracked paths.
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-${ZSH_VERSION}"
mkdir -p "$ZSH_CACHE_DIR"
fpath=("$HOME/.zfunc" $fpath)

HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=250000
SAVEHIST=200000
HIST_STAMPS="yyyy-mm-dd"
CASE_SENSITIVE=false
HYPHEN_INSENSITIVE=true
DISABLE_AUTO_TITLE=true

# fzf's shell widgets and fzf-tab have separate display settings.
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --cycle --info=inline"
export FZF_CTRL_R_OPTS="--height 50% --layout=reverse --border"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

if [ -z "$ZSH_THEME" ]; then
  # ZSH_THEME="kolo"

  # custom prompt
  autoload -Uz vcs_info

  zstyle ':vcs_info:*' stagedstr '%F{green}●'
  zstyle ':vcs_info:*' unstagedstr '%F{yellow}●'
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:svn:*' branchformat '%b'
  zstyle ':vcs_info:svn:*' formats ' [%b%F{1}:%F{11}%i%c%u%B%F{green}]'
  zstyle ':vcs_info:*' enable git svn

  theme_precmd() {
    if [[ -z $(git ls-files --other --exclude-standard 2>/dev/null) ]]; then
      zstyle ':vcs_info:git:*' formats ' [%b%c%u%B%F{green}]'
    else
      zstyle ':vcs_info:git:*' formats ' [%b%c%u%B%F{red}●%F{green}]'
    fi

    vcs_info
  }

  prompt_error() {
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
      echo "%F{red}✖ $RETVAL%f "
    else
      echo ""
    fi
  }

  setopt prompt_subst
  PROMPT='$(prompt_error)%B%F{magenta}%c%B%F{green}${vcs_info_msg_0_}%B %F{cyan}➜%{$reset_color%} '

  autoload -U add-zsh-hook
  add-zsh-hook precmd theme_precmd
fi

plugins=(git docker kubectl)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit -i -d "$ZSH_COMPDUMP"
fi

# Retain repeated events in chronological order; deduplicate search results.
setopt append_history extended_history share_history hist_ignore_space hist_verify
setopt hist_find_no_dups hist_reduce_blanks
unsetopt hist_ignore_all_dups hist_ignore_dups hist_expire_dups_first beep

# Configure completion after Oh My Zsh, which installs its own styles.
zstyle ':completion:*' menu no
zstyle ':completion:*:*:*:*:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --cycle --info=inline
zstyle ':fzf-tab:*' switch-group ',' '.'
if [[ "$OSTYPE" == darwin* ]]; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'CLICOLOR_FORCE=1 command ls -G -la -- "$realpath"'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'command ls --color=always -la -- "$realpath"'
fi

# Widgets require a line editor; zsh -ic automation may have none.
if [[ -o zle && -t 0 && -t 1 ]]; then
  # Load fzf exactly once, then fzf-tab before plugins that wrap ZLE widgets.
  if (( $+commands[fzf] )); then
    source <(fzf --zsh)
    [[ -r "$ZSH_ROOT/fzf-tab/fzf-tab.plugin.zsh" ]] && source "$ZSH_ROOT/fzf-tab/fzf-tab.plugin.zsh"
  fi
  [[ -r "$ZSH_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZSH_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r "$ZSH_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$ZSH_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -r "$ZSH/plugins/history-substring-search/history-substring-search.plugin.zsh" ]] && source "$ZSH/plugins/history-substring-search/history-substring-search.plugin.zsh"

  if (( ${+widgets[fzf-history-widget]} )); then
    bindkey '^R' fzf-history-widget
  fi
  if (( ${+widgets[history-substring-search-up]} )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
  fi
  # Alt-C remains available to fzf outside tmux; tmux reserves M-c for ccmux.

fi

ranger-cd() {
  local tmpfile dir result=0
  tmpfile=$(mktemp -t ranger-cwd.XXXXXX) || return
  {
    command ranger --choosedir="$tmpfile" "$@" < /dev/tty > /dev/tty 2>&1 || return
    dir=$(<"$tmpfile")
    if [[ -n "$dir" && "$dir" != "$PWD" ]]; then
      builtin cd -- "$dir" || result=$?
    fi
  } always {
    command rm -f -- "$tmpfile"
  }
  return $result
}
alias ra='ranger-cd'
ranger-cd-widget() {
  zle -I
  ranger-cd
  zle reset-prompt
}
if [[ -o zle && -t 0 && -t 1 ]]; then
  zle -N ranger-cd-widget
  bindkey '^F' ranger-cd-widget
fi

if [[ "$DOTFILES_ZSH_PERSONAL" == true ]]; then
  source "$ZSH_ROOT/personal.zsh"
fi
# Account-specific environment and aliases, selected by yadm alternates.
[[ -r "$ZSH_ROOT/local.zsh" ]] && source "$ZSH_ROOT/local.zsh"

(( $+commands[ccmux] )) && eval "$(ccmux completion zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
if [[ -o zle && -t 0 && -t 1 ]] && (( $+commands[navi] )); then
  eval "$(navi widget zsh)"
fi
return 0
