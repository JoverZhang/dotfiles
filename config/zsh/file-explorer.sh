fileexplorer() {
	setopt localoptions pipefail no_aliases 2>/dev/null

	local ops='9'
	local ls_dir="exa -bglHh --all --all --color=always"
	local cat_file="bat -pn --color=always"

	local tmp='/tmp/file-explorer'
	mkdir -p "$tmp"

	# preview_window config
	local preview_window_up='up,55%,wrap'
	local preview_window_right='right,55%,wrap'
	local tmp_preview_window="$tmp/preview_window"
	if [ ! -f $tmp_preview_window ]; then
		echo "$preview_window_right" >$tmp_preview_window
	fi

	local selected
	while selected=$(
		eval "$ls_dir" | sed 1,2d |
			$(__fzfcmd) +m \
				--ansi \
				--reverse \
				--nth=9 \
				--height=60% \
				--border=top \
				--border-label="| $PWD |" \
				--preview=" if [ -f {$ops} ]; then $cat_file {$ops}; else $ls_dir {$ops}; fi " \
				--preview-window="$(cat $tmp_preview_window)" \
				--color='label:#5555FF:200' \
				\
				--bind='change:top' \
				`# show "x -> y" for link file` \
				--bind="focus:transform-preview-label( echo '|' \$( if [ ! -z {$(($ops + 1))} ]; then echo {$ops} {$(($ops + 1))} {$(($ops + 2))}; else echo {$ops}; fi ) '|' )" \
				--bind="ctrl-s:change-preview-window(up)+execute(echo $preview_window_up>$tmp_preview_window)" \
				--bind="ctrl-v:change-preview-window(right)+execute(echo $preview_window_right>$tmp_preview_window)" \
				--bind='ctrl-u:preview-half-page-up' \
				--bind='ctrl-d:preview-half-page-down' \
				--bind='ctrl-f:abort' \
				--bind='ctrl-h:top+accept' \
				--bind='ctrl-l:accept' \
				--bind='ctrl-z:ignore' \
				\
				--header='C-h: back C-l enter' |
			awk "{ print \$$ops }"
	); do
		# echo 'selected: ' $dir >>$WS/test.log

		# selected file
		# push it to BUFFER
		if [[ -f "$selected" ]]; then
			# echo 'push: ' $dir >>$WS/test.log
			zle reset-prompt
			BUFFER="$selected"
			unset selected
			return 0
		fi

		# selected directory
		# cd to dir
		# echo 'cd: ' $dir >>$WS/test.log
		BUFFER="builtin cd -- ${selected}"
		builtin cd $selected
		# zle accept-line
		zle redisplay
		unset selected
	done

	# exit
	# echo 'exit: ' $dir >>$WS/test.log
	BUFFER=""
	zle reset-prompt
	unset selected
	return 0
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
