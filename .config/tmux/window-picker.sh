#!/usr/bin/env bash
# Search windows across sessions; preview the active pane without sending input.
set -euo pipefail

if [[ ${1-} == --preview ]]; then
    exec tmux capture-pane -p -t "$2" -S -120
fi

client=${TMUX_PICKER_CLIENT:?missing tmux client}
printf -v preview '%q --preview {2}' "$0"
selection=$(tmux list-windows -a -F '#{session_id}:#{window_id}	#{pane_id}	#{session_name}:#{window_index}  #{window_name}' |
    fzf --delimiter '\t' --with-nth 3.. --layout reverse --border --height 100% --no-multi \
        --prompt 'Window > ' --header 'Enter: switch · Esc: cancel · Ctrl-/: toggle preview' \
        --preview "bash $preview" --preview-window 'right,60%,wrap,follow' \
        --bind 'ctrl-/:toggle-preview') || exit 0
[[ -n $selection ]] || exit 0
target=${selection%%$'\t'*}
tmux switch-client -c "$client" -t "$target"
