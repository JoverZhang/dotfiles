export DOT_FILES="$HOME/DotFiles"
ZSH_ROOT=$(dirname $0)

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$ZSH_ROOT/oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
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

	setopt prompt_subst
	PROMPT='%B%F{magenta}%c%B%F{green}${vcs_info_msg_0_}%B %F{cyan}➜%{$reset_color%} '

	autoload -U add-zsh-hook
	add-zsh-hook precmd theme_precmd
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker kubectl)

source $ZSH/oh-my-zsh.sh
source $ZSH_ROOT/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH_ROOT/zsh-autosuggestions/zsh-autosuggestions.zsh
# source $ZSH_ROOT/zsh-file-manager/zsh-file-manager.zsh
source $DOT_FILES/fzf/shell/completion.zsh
source $DOT_FILES/fzf/shell/key-bindings.zsh

function ranger-cd {
	tempfile="$(mktemp -t tmp.ranger-cd.XXXXXX)"
	/usr/bin/ranger --choosedir="$tempfile" "${@:-$(pwd)}"
	test -f "$tempfile" &&
		if [ "$(cat -- "$tempfile")" != "$(echo -n $(pwd))" ]; then
			cd -- "$(cat "$tempfile")"
		fi
	rm -f -- "$tempfile"
}
bindkey -s '^F' 'ranger-cd\n'

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
alias p="proxychains -f $HOME/.config/proxychains/proxychains.conf"
alias t='asynctask -f'
alias docker='podman'
alias nvid='neovide --neovim-bin $HOME/Tools/bin/nvim'

alias ll='lsd -l --color=auto'
alias l='ll -a'

alias rm='rm -i'
alias mv='mv -i'

# Environments
export WS="$HOME/Workspace"
export EDITOR='/bin/nvim'
export PATH="$HOME/DotFiles/bin:$HOME/Tools/bin:/snap/bin/:$PATH:$HOME/.cargo/bin"

#export HTTP_PROXY=http://127.0.0.1:8889
#export HTTPS_PROXY=http://127.0.0.1:8889
export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.0.0/16

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

# c-f
fzf-ls-cd-widget() {
	# local cmd="ls -al --color=yes | sed 1,2d"
	local cmd="exa -bglHh --all --all --color=always | sed 1,2d"
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

##############################################################################

# fpath
fpath+=~/.zfunc

# commmon commands
declare -a COMMANDS=(
	# exa
	bat
	lsd
	dust # du
	duf  # df
	fd   # find
	rg
	ranger
	ag
	fzf
	choose
	jq
	sd   # sed
	tldr # man
	btm
	# hyperfine # time
	# gping
	curlie
	dog # dig
)
for cmd in "${COMMANDS[@]}"; do
	if ! command -v "$cmd" &>/dev/null; then
		echo "command \"$cmd\" could not be found"
	fi
done

# init zoxide
if command -v zoxide &>/dev/null; then
	eval "$(zoxide init zsh)"
else
	echo 'command "zoxide" could not be found'
fi

# auto start tmux
if command -v tmux &>/dev/null; then
	if [ -z "$TMUX" -a -z "$DONT_TMUX" ]; then
		tmux
	fi
else
	echo 'command "tmux" could not be found'
fi
