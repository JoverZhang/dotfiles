#!/bin/python3

import os


map = {
  '$HOME/DotFiles/config/i3': '$HOME/.config/i3',
  '$HOME/DotFiles/config/proxychains': '$HOME/.config/proxychains',
}


def expandvars(var):
    return os.path.expandvars(var)

def link(fm, to):
    if os.path.samefile(expandvars(fm), expandvars(to)):
        return
    os.system(f'ln -s {fm} {to}')


for key in map:
    link(key, map[key])

