#!/bin/python3
import os
import shutil
import sys
import tempfile
from argparse import Namespace, ArgumentParser
from typing import Dict, Optional, List, ClassVar, Tuple


class Logger:
    _HEADER = '\033[95m'
    _TIPS = '\033[94m'
    _WARN = '\033[93m'
    _ERROR = '\033[91m'
    _BOLD = '\033[1m'
    _UNDERLINE = '\033[4m'
    _END = '\033[0m'

    enable_debug: bool

    def __init__(self, enable_debug: bool = False):
        self.enable_debug = enable_debug

    @staticmethod
    def tips(msg: str):
        print(Logger._TIPS + msg + Logger._END)

    def debug(self, msg: str):
        self.enable_debug and print(Logger._HEADER + msg + Logger._END)

    @staticmethod
    def warn(msg: str):
        print(Logger._WARN + msg + Logger._END)

    @staticmethod
    def error(msg: str):
        print(Logger._ERROR + msg + Logger._END)


log: Optional[Logger] = None


class Util:
    @staticmethod
    def replace_env(s: Optional[str]) -> Optional[str]:
        if not s:
            return None
        for k in list(os.environ.keys()):
            s = s.replace(f'${k}', os.getenv(k))
        return os.path.expanduser(s)

    @staticmethod
    def read_file(filename: str, encoding: str = 'utf-8') -> str:
        filename = Util.replace_env(filename.strip())
        assert os.path.exists(filename), f'the file "{filename}" does not exist'
        content = None
        for encoding in [encoding, 'latin1', 'gbk']:
            try:
                with open(filename, mode='r', encoding=encoding) as f:
                    content = f.read()
                    break
            except Exception:
                pass
        assert content, f'unable to read file "{filename}"'
        return content


class Arguments:
    command_title: Optional[str]
    command_args: Optional[Dict[str | int, str]]

    config_file: str
    debug: bool
    no_history: bool

    def __init__(self):
        parser: ArgumentParser = ArgumentParser(
            prog='h',
            usage='%(prog)s [options] [TITLE [arg]...]')

        parser.add_argument('title',
                            type=str, nargs='*',
                            help='command title')

        parser.add_argument('-f',
                            dest='config_file',
                            type=str, default='~/.config/h_command/config.toml',
                            help='config file')
        parser.add_argument('--no-history',
                            dest='no_history', action='store_true',
                            help="do not append command to the history log")
        parser.add_argument('--debug',
                            dest='debug', action='store_true',
                            help='print debug log')

        args: Namespace = parser.parse_args()

        self.command_title, self.command_args = self._parse_title(args.title)
        self.config_file = Util.replace_env(args.config_file)
        self.no_history = args.no_history
        self.debug = args.debug

    @staticmethod
    def _parse_title(title: List[str]) \
            -> Tuple[Optional[str], Optional[Dict[str | int, str]]]:
        if not title:
            return None, None
        rst = {}
        cmd = title[0]
        args = title[1:]
        for i, arg in enumerate(args):
            name, eq, val = arg.partition('=')
            if eq:
                rst[name] = val
            else:
                rst[i] = name
        return cmd, rst


class ConfigItem:
    title: str
    command: str

    # Global fields
    tool: Optional[str]
    flags: Optional[str]
    includes: Optional[List[str]]

    def __init__(self, title: str):
        self.title = title
        self.command = ''
        self.tool = None
        self.flags = None
        self.includes = None

    def __str__(self):
        if not self.tool:
            return f'{self.title}: command="{self.command}"'
        return f'{self.title}: tool="{self.tool}", includes={self.includes}'


class Config:
    SETTINGS: ClassVar[str] = '__SETTINGS__'
    _root_config_file: str
    _config: dict[str, ConfigItem]

    def __init__(self, root_config_file: str):
        self._root_config_file = root_config_file

        # load config items
        self._config = {}
        self._load_config(self._config, root_config_file)
        for filename in self.get_settings().includes:
            self._load_config(self._config, filename)

        # debug log for config items
        log.debug('config items:')
        for k, v in self._config.items():
            log.debug(' ' * 4 + v.__str__())

    def __iter__(self):
        return iter(self._config)

    def item(self, title) -> Optional[ConfigItem]:
        return self._config.get(title)

    def get_settings(self):
        return self.item(Config.SETTINGS)

    def _load_config(self, config: Dict[str, ConfigItem],
                     filename: str, encoding: str = 'utf-8'):
        content = Util.read_file(filename, encoding)
        title: str = Config.SETTINGS
        line_num: int = 0
        for line in content.split('\n'):
            line_num += 1
            line = line.strip('\r\n\t ')
            # skip empty or comment line
            if not line or line[:1] in ('#', ';'):
                continue
            # title
            elif line.startswith('['):
                assert line.endswith(']'), \
                    f'invalid syntax "{line}" in "{filename}:{line_num}"'
                title = line[1:-1].strip('\r\n\t ')
                if title not in config:
                    config[title] = ConfigItem(title)
            # fields
            else:
                pos = line.find('=')
                if pos >= 0:
                    field = line[:pos].strip('\r\n\t ')
                    value = line[pos + 1:].strip('\r\n\t ')
                    if title not in config:
                        config[title] = ConfigItem(title)
                    if field == 'command':
                        config[title].command = value
                    elif field == 'tool':
                        config[title].tool = value
                    elif field == 'flags':
                        config[title].flags = value
                    elif field == 'includes':
                        config[title].includes = value.split(',')


class Core:
    config: Config

    # variables mark
    mark_open = '$(?'
    mark_close = ')'

    def __init__(self, config: Config):
        self.config = config

    def run(self, title: str, args: Dict[str | int, str]):
        log.debug(f'run({title}, {args})')

        item = self.config.item(title)
        if not item:
            assert False, f'title "{title}" not found'

        log.tips(item.command)
        command = self._handle_variables(item.command, args)
        if command != item.command:
            log.tips(command)

        os.system(command)

    def interactive(self) -> bool:
        log.debug('interactive()')
        tool = self.config.get_settings().tool or 'fzf'
        flags = '--nth=1 --reverse +s --inline-info --height 35% --no-mouse'
        flags = self.config.get_settings().flags or flags

        # calc title print width
        width = 0
        for title in self.config:
            if len(title) > width:
                width = len(title)

        # create temp directory
        tmpdir = tempfile.mkdtemp('h')
        tmp_commands = os.path.join(tmpdir, 'commands.tmp')
        tmp_output = os.path.join(tmpdir, 'output.tmp')

        try:
            # write command list
            with open(tmp_commands, mode='w', encoding='utf-8') as f:
                for title in self.config:
                    if title == Config.SETTINGS:
                        continue
                    item = self.config.item(title)
                    title = title + ' ' * (width - len(title) + 2)
                    row = f'{title}:{item.command}'
                    f.write(row + '\n')

            # run tool
            log.debug(f'current platform: {sys.platform}')
            cmd = f'{tool} {flags}'
            if sys.platform[:3] != 'win':
                cmd += f' < "{tmp_commands}" > {tmp_output}'
            else:
                # TODO: support windows
                assert False, 'unsupported windows platform'
            log.debug(cmd)
            code = os.system(cmd)
            if code:
                return False

            # read command from tmp_output, and run
            with open(tmp_output, mode='r', encoding='utf-8') as f:
                line = f.read().strip('\r\n\t ')
                ops = line.find(':')
                if ops < 0:
                    return False
                title = line[:ops].strip()
                log.tips(f'[{title}]')
                self.run(title, {})
            return True
        # remove temp directory
        finally:
            if tmpdir:
                shutil.rmtree(tmpdir)

    def _handle_variables(self, command: str,
                          args: Dict[str | int, str]) -> str:
        mark_open = self.mark_open
        mark_close = self.mark_close

        variables = {}
        i = 0
        while True:
            p1 = command.find(mark_open, i)
            if p1 < 0:
                break
            p2 = command.find(mark_close, p1)
            if p2 < 0:
                break

            full_name = command[p1 + len(mark_open):p2]

            # handle default variable
            name, _, default = full_name.strip().partition(':')
            variables[name] = {
                'name': name,
                'default': default,
                'full_name': full_name,
                'mark': mark_open + full_name + mark_close,
            }
            i = p2

        # handle args
        for name in list(args.keys()):
            v = variables.get(name)
            if not v:
                continue
            command = command.replace(v['mark'], args[name])
            args.pop(name)
            variables.pop(name)

        # handle anonymous args
        values = [v for k, v in args.items() if type(k) is int]
        for v in list(variables.values()):
            if not values:
                break
            command = command.replace(v['mark'], values.pop(0))
            variables.pop(v['name'])

        # handle unspecified variables
        for name, v in variables.items():
            data = input(f'input variable ({v["full_name"]}): ')
            if not data:
                data = v['default'] or ''
            command = command.replace(v['mark'], data)

        return command


def main():
    arguments = Arguments()

    global log
    log = Logger(arguments.debug)

    try:
        core = Core(Config(arguments.config_file))

        if arguments.command_title:
            core.run(arguments.command_title, arguments.command_args)
        else:
            core.interactive()
    except Exception as e:
        if e.__str__():
            log.error(f'error: {e}')
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
