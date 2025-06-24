#!/bin/python3

import os

map = {
    '$HOME/DotFiles/config/bottom': '$HOME/.config/bottom',
    '$HOME/DotFiles/config/gdb/gdbinit': '$HOME/.gdbinit',
    '$HOME/DotFiles/config/h_command': '$HOME/.config/h_command',
    '$HOME/DotFiles/config/i3': '$HOME/.config/i3',
    '$HOME/DotFiles/config/neovim': '$HOME/.config/nvim',
    '$HOME/DotFiles/config/polybar': '$HOME/.config/polybar',
    '$HOME/DotFiles/config/proxychains': '$HOME/.config/proxychains',
    '$HOME/DotFiles/config/ranger': '$HOME/.config/ranger',
    '$HOME/DotFiles/config/tmux': '$HOME/.config/tmux',
    '$HOME/DotFiles/config/vim': '$HOME/.vim',
    '$HOME/DotFiles/config/xfce4/terminal': '$HOME/.config/xfce4/terminal',
    '$HOME/DotFiles/config/zsh': '$HOME/.config/zsh',
    '$HOME/DotFiles/config/libinput-gestures.conf': '$HOME/.config/libinput-gestures.conf',
    '$HOME/DotFiles/config/picom.conf': '$HOME/.config/picom.conf',
}


def expandvars(var):
    return os.path.expandvars(var)


def link(fm, to):
    fm = os.path.expandvars(fm)
    to = os.path.expandvars(to)

    if os.path.exists(to):
        if os.path.samefile(fm, to):
            print(f'SKIP: {to}')
        else:
            print(f'EXISTS: {to}')
        return
    os.system(f'ln -s {fm} {to}')
    print(f'INSTALL: {to}')


for key in map:
    link(key, map[key])

