#!/usr/bin/env bash
# Move the invoking window to another session and follow it in that client.
set -euo pipefail

client=${1:?missing tmux client}
source_session=${2:?missing source session}
source_window=${3:?missing source window}
source_target="${source_session}:${source_window}"

menu=()
shortcuts=1234567890abcdefghijklmnopqrstuvwxyz
index=0
while IFS=$'\t' read -r session_id window_count session_name; do
    [[ $session_id == "$source_session" ]] && continue

    # Session names are labels only; use IDs in commands and escape formats.
    label=" ${session_name//#/##} (${window_count} windows)"
    key=${shortcuts:index:1}
    # Switch first so moving the source session's last window cannot detach us.
    command="switch-client -t '$session_id' ; move-window -s '$source_target' -t '$session_id:'"
    menu+=("$label" "$key" "$command")
    index=$((index + 1))
done < <(tmux list-sessions -F $'#{session_id}\t#{session_windows}\t#{session_name}')

if (( ${#menu[@]} == 0 )); then
    tmux display-message -c "$client" 'No other sessions available'
    exit 0
fi

exec tmux display-menu -c "$client" -t "$source_target" \
    -T 'Move window to session' -x C -y C "${menu[@]}"
