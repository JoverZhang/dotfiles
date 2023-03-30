#!/bin/python3

import os


map = {
  '$HOME/DotFiles/config/h_command': '$HOME/.config/h_command',
  '$HOME/DotFiles/config/i3': '$HOME/.config/i3',
  '$HOME/DotFiles/config/neovim': '$HOME/.config/nvim',
  '$HOME/DotFiles/config/picom.conf': '$HOME/.config/picom.conf',
  '$HOME/DotFiles/config/proxychains': '$HOME/.config/proxychains',
  '$HOME/DotFiles/config/zsh': '$HOME/.config/zsh',
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

