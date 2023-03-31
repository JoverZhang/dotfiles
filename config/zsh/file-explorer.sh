fileexplorer() {
	local cmd="exa -bglHh --all --all --color=always | sed 1,2d"
	setopt localoptions pipefail no_aliases 2>/dev/null

	local dir
	while dir=$(
		eval "$cmd" |
			$(__fzfcmd) +m \
				--border=top \
				--border-label="| $PWD |" \
				--ansi \
				--nth=9 \
				--height=60% \
				--reverse \
				--preview='if [ -f {9} ]; then bat -pn --color=always {9}; else ls -alH --color=yes {9}; fi' \
				--bind='change:top' \
				--bind='focus:transform-preview-label:echo "|" {9} "|"' \
				--bind='ctrl-f:abort' \
				--bind='ctrl-u:preview-half-page-up' \
				--bind='ctrl-d:preview-half-page-down' \
				--bind='ctrl-h:top+accept' \
				--bind='ctrl-l:accept' \
				--bind='ctrl-z:ignore' \
				--header='C-h: back C-l enter' |
			awk '{ print $9 }'
	); do
		# echo 'selected: ' $dir >>$WS/test.log

		# selected file
		# push it to BUFFER
		if [[ -f "$dir" ]]; then
			# echo 'push: ' $dir >>$WS/test.log
			zle reset-prompt
			BUFFER="$dir"
			unset dir
			return 0
		fi

		# selected directory
		# cd to dir
		# echo 'cd: ' $dir >>$WS/test.log
		BUFFER="builtin cd -- ${dir}"
		builtin cd $dir
		# zle accept-line
		zle redisplay
		unset dir
	done

	# exit
	# echo 'exit: ' $dir >>$WS/test.log
	BUFFER=""
	zle reset-prompt
	unset dir
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
