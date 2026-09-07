# Personal workstation commands and environment. Skipped by the Agent class.

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8
LANG=en_US.UTF-8
LC_ADDRESS=en_US.UTF-8
LC_IDENTIFICATION=en_US.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_PAPER=en_US.UTF-8
LC_TELEPHONE=en_US.UTF-8
LC_TIME=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

##############################################################################

# Aliases
alias ce="claude -p 'concisely explain the root cause of this build error'"
alias p="proxychains -f $HOME/.config/proxychains/proxychains.conf"
alias t='asynctask -f'
# alias docker='podman'
# alias docker-compose='podman-compose'
alias nvid='neovide --neovim-bin $HOME/Tools/bin/nvim'
# alias redis-cli="$HOME/Workspace/sourcecode/github/redis/src/redis-cli"

alias ll='lsd -l --color=auto'
alias l='ll -a'

alias rm='rm -i'
alias mv='mv -i'

# Environments
export WS="$HOME/Workspace"
export EDITOR='nvim'
path=("${(@)path:#$HOME/DotFiles/bin}")
export PATH="$HOME/.local/bin:$HOME/Tools/bin:/snap/bin/:$PATH:$HOME/.cargo/bin"

# # Proxy Enable
# export http_proxy=http://127.0.0.1:8889
# export HTTP_PROXY=http://127.0.0.1:8889
# export https_proxy=http://127.0.0.1:8889
# export HTTPS_PROXY=http://127.0.0.1:8889
# export ftp_proxy=http://127.0.0.1:8889
# export FTP_PROXY=http://127.0.0.1:8889
# export no_proxy=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16
# export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16
#
# # Proxy Disable
# unset http_proxy
# unset HTTP_PROXY
# unset https_proxy
# unset HTTPS_PROXY
# unset ftp_proxy
# unset FTP_PROXY
# unset no_proxy
# unset NO_PROXY

# Window
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5

# Gradle
export GRADLE_USER_HOME=$HOME/.gradle

# Flutter
export CHROME_EXECUTABLE='/usr/bin/google-chrome-stable'

# golang
if command -v go &>/dev/null; then
  export GOROOT=$(go env GOROOT)
  export GOPATH=$(go env GOPATH)
  export PATH=$PATH:$(go env GOPATH)/bin
else
  echo 'command "go" could not be found'
fi
# npm
if ! (command -v npm &>/dev/null); then
  echo 'command "npm" could not be found'
fi

# fzf keymaps
# autoload -Uz fzf-cd-widget
# zle -N fzf-cd-widget
# bindkey '^F' fzf-cd-widget

# fshow - git commit browser
fshow() {
  local out sha q
  while out=$(
    git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" |
      fzf --ansi --multi --no-sort --reverse --query="$q" --print-query
  ); do
    q=$(head -1 <<<"$out")
    while read sha; do
      [ -n "$sha" ] && git show --color=always $sha | less -R
    done < <(sed '1d;s/^[^a-z0-9]*//;/^$/d' <<<"$out" | awk '{print $1}')
  done
}

function runbuild() {
  TARGET=$(fzf --prompt="Select file to compile: ")
  if [[ -z "$TARGET" ]]; then
    echo "No file selected."
    return 1
  fi

  # Select the compiler based on the file suffix
  case "$TARGET" in
  *.c) COMPILER="gcc" ;;
  *.cpp) COMPILER="g++" ;;
  *.go) COMPILER="go build -o" ;;
  *.rs) COMPILER="rustc" ;;
  *.py) COMPILER="python3" ;;
  *.java) COMPILER="javac" ;;
  *) echo "Unsupported file type." && return 1 ;;
  esac

  CMD="$COMPILER \"$TARGET\" -o \"${TARGET%.*}.out\" && \"./${TARGET%.*}.out\" && rm \"./${TARGET%.*}.out\" #auto_run"

  print -s "$CMD"
  eval "$CMD"
}

# c-f
fzf-ls-cd-widget() {
  local cmd="ls -al --color=yes | sed 1,2d"
  # local cmd="exa -bglHh --all --all --color=always | sed 2,2d"
  setopt localoptions pipefail no_aliases 2>/dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--ansi --bind change:top --nth=9 --height ${FZF_TMUX_HEIGHT:-60%} --reverse --preview='if [ -f {9} ]; then bat -pn --color=always {9}; else ls -alH --color=yes {9}; fi' | awk '{ print \$9 }' --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" $(__fzfcmd) +m | awk '{ print $9 }')"

  # skip
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi

  # push to buffer
  if [[ -f "$dir" ]]; then
    zle redisplay
    BUFFER="$dir"
    return 0
  fi

  # cd to directory
  zle push-line
  BUFFER="builtin cd -- ${dir}"
  zle accept-line
  local ret=$?
  unset dir
  zle reset-prompt
  return $ret
}
# autoload -Uz fzf-ls-cd-widget
# zle -N fzf-ls-cd-widget
# bindkey '^F' fzf-ls-cd-widget

