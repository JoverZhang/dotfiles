fileexplorer() {
	# Help Manual
	read -r -d '' HELP <<EOF
File-Explorer Manual

Base on "zsh" and "fzf", the File-Explorer is a lightweight tool that incorporates "exa" and "bat" for enhanced functionality.

Binding keys:

C-u                 preview window page up
C-d                 preview window page down
C-s                 preview window horizontally
C-v                 preview window vertically
C-k, C-p, up        up
C-j, C-n, down      down
C-h, left           back "cd .."
C-l, right enter    selected
                      if it is a directory, it enters it.
                      if it is a file, it adds the filename to the terminal BUFFER.
pgup                page up
pgdn                page down
C-c, C-f, C-g       quit

About fallback:

If "exa" is not installed, it will use "ls" as a fallback.
If "bat" is not installed, it will use "cat" as a fallback.
EOF

	setopt localoptions pipefail no_aliases 2>/dev/null

	# commands
	local ops='9'
	local ls_dir='exa -bglHh --all --all --color=always'
	local cat_file='bat -pn --color=always'

	# commands fallback
	if ! (command -v exa &>/dev/null); then
		ls_dir="ls -al --color=yes"
	fi
	if ! (command -v bat &>/dev/null); then
		cat_file='cat'
	fi

	#tmp file
	local TMP='/tmp/file-explorer'
	mkdir -p "$TMP"

	# debug log
	dbg() {
		return
		echo "$@" >>$TMP/dbg.log
	}

	# preview_window config
	local PREVIEW_WINDOW_H='down,55%,wrap'
	local PREVIEW_WINDOW_V='right,55%,wrap'
	local TMP_PREVIEW_WINDOW="$TMP/preview_window"
	if [ ! -f $TMP_PREVIEW_WINDOW ]; then
		echo "$PREVIEW_WINDOW_V" >$TMP_PREVIEW_WINDOW
	fi

	# main loop
	while :; do
		local fzf_args=(
			+m
			--ansi
			--reverse
			--nth=9
			--height=60%
			--border=top
			--border-label="| $PWD |"
			--preview=" if [ -f {$ops} ]; then $cat_file {$ops}; else $ls_dir {$ops}; fi "
			--preview-window="$(cat $TMP_PREVIEW_WINDOW)"
			--color='label:#5555FF:200'

			--bind='change:top'
			# show "x -> y" for link file
			--bind="focus:transform-preview-label( echo '|' \$( if [ ! -z {$(($ops + 1))} ]; then echo {$ops} {$(($ops + 1))} {$(($ops + 2))}; else echo {$ops}; fi ) '|' )"
			--bind="ctrl-s:change-preview-window(down)+execute(echo $PREVIEW_WINDOW_H>$TMP_PREVIEW_WINDOW)"
			--bind="ctrl-v:change-preview-window(right)+execute(echo $PREVIEW_WINDOW_V>$TMP_PREVIEW_WINDOW)"
			--bind='ctrl-u:preview-half-page-up'
			--bind='ctrl-d:preview-half-page-down'
			--bind='ctrl-f:abort'
			# go to ..
			--bind='ctrl-h:execute(echo "//BACK//")+abort'
			--bind='left:execute(echo "//BACK//")+abort'
			# selected
			--bind='ctrl-l:accept'
			--bind='right:accept'

			--bind='ctrl-z:ignore'
			--bind="?:preview(echo '$HELP')"
			--header='Press ? for help'
		)
		local selected=$(eval "$ls_dir" | sed 1,2d | $(__fzfcmd) "${fzf_args[@]}")
		dbg "selected: $selected"

		# quit
		if [ -z "$selected" ]; then
			dbg "quit: $selected"
			BUFFER=""
			zle reset-prompt
			return 0
		# back
		elif [[ "$selected" == '//BACK//' ]]; then
			selected='..'
		# get selected value
		else
			selected=$(echo $selected | awk "{ print \$$ops }")
		fi
		dbg "SELECTED: $selected"

		# selected file
		# push it to BUFFER
		if [[ -f "$selected" ]]; then
			dbg "push: $selected"
			zle reset-prompt
			BUFFER="$selected"
			return 0
		fi

		# selected directory
		# cd to dir
		dbg "cd: $selected"
		BUFFER="builtin cd -- ${selected}"
		builtin cd $selected
		# zle accept-line
		zle redisplay
	done
}
autoload -Uz fileexplorer
zle -N fileexplorer
bindkey '^F' fileexplorer

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
