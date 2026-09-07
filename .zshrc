# Managed by yadm. Interactive configuration only.
[[ -o interactive ]] || return 0
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshrc.sh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshrc.sh"
