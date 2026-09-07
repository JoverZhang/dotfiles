#!/usr/bin/env bash

polybar-msg cmd quit

polybar-msg cmd quit
polybar 2>&1 | tee -a /tmp/polybar.log &
disown

echo "Polybar launched..."
