#!/bin/python3

import os
import sys
import re
from typing import Optional


class bcolors:
    OK = '\033[94m'
    ENDC = '\033[0m'


class Module:

    def __init__(self, name: str) -> None:
        self.name: str = name
        self.path: Optional[str] = None
        self.url: Optional[str] = None
        self.shallow: Optional[str] = None

    def __repr__(self) -> str:
        return f'Module(name={self.name}, ' + \
            f'path={self.path}, ' + \
            f'url={self.url}, ' + \
            f'shallow={self.shallow})'


def load_config(filename) -> list[Module]:
    modules: list[Module] = []
    with open(os.path.expandvars(filename)) as f:
        if not f.readable:
            return []

        module: Optional[Module] = None
        for line in f.readlines():
            if line.startswith('[submodule '):
                name = re.findall('\[submodule "(.*)"\]', line)[0]
                module = Module(name)
                modules.append(module)
            else:
                item = line.strip().split(' ')
                if len(item) != 3:
                    continue
                key = item[0]
                val = item[2]
                setattr(module, key, val)

    return modules


def sync(module: Module, skip: bool = False):
    print(f'{bcolors.OK}SYNC: {module.name}{bcolors.ENDC}')
    if skip:
        print('SKIPPED')
        return
    if module.shallow:
        os.system(
            f'git submodule update --recursive --remote --depth 1 {module.name}'
        )
    else:
        os.system(f'git submodule update --recursive --remote {module.name}')


def main():
    all = False
    if len(sys.argv) > 1 and sys.argv[1] == 'all':
        all = True

    modules: list[Module] = load_config('$DOT_FILES/.gitmodules')
    for module in modules:
        sync(module, not all and not module.shallow)


if __name__ == "__main__":
    main()
