#!/bin/python3

import os


def sync(module):
    print(f'SYNC: {module}')
    os.system(f'git submodule update --recursive --remote --depth 1 {module}')


modules = [
    'config/zsh/oh-my-zsh',
    'config/zsh/zsh-autosuggestions',
    'config/zsh/zsh-syntax-highlighting',
    'fzf',
]

for module in modules:
    sync(module)

