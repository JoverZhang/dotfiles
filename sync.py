#!/bin/python3

import os


map = {
  '$HOME/DotFiles/config/i3': '$HOME/.config/i3',
  '$HOME/DotFiles/config/neovim': '$HOME/.config/nvim',
  '$HOME/DotFiles/config/proxychains': '$HOME/.config/proxychains',
  '$HOME/DotFiles/config/zsh': '$HOME/.config/zsh',
}


def expandvars(var):
    return os.path.expandvars(var)

def link(fm, to):
    fm = os.path.expandvars(fm)
    to = os.path.expandvars(to)

    if os.path.exists(to) and os.path.samefile(fm, to):
        print(f'SKIP: {to}')
        return
    os.system(f'ln -s {fm} {to}')
    print(f'SYNC: {to}')


for key in map:
    link(key, map[key])

