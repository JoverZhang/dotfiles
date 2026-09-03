#!/bin/bash

SHOW='Ω'
HIDE='ω'

function get_state() {
	if [ ! -f /tmp/polybar/cpu-toggle ]; then
		mkdir -p /tmp/polybar
		echo "$HIDE" >/tmp/polybar/cpu-toggle
	fi
	echo $(cat /tmp/polybar/cpu-toggle)
}

function toggle() {
	state="$(get_state)"

	case $state in
	"$SHOW")
		polybar-msg action cpu-summary module_show >/dev/null
		polybar-msg action cpu module_hide >/dev/null
		state=$HIDE
		;;
	"$HIDE")
		polybar-msg action cpu-summary module_hide >/dev/null
		polybar-msg action cpu module_show >/dev/null
		state=$SHOW
		;;
	esac

	echo "$state" >/tmp/polybar/cpu-toggle
}

case "$1" in
"toggle")
	toggle
	polybar-msg action toggle hook 0
	;;
"state")
	get_state
	;;
*)
	echo 'error'
	;;
esac
