import sys
import json
from pathlib import Path
from argparse import ArgumentParser, FileType
import logging
logger = logging.getLogger(__name__)

from icecap_hypervisor.firmware import FirmwareComposition
from icecap_hypervisor.realm import LinuxRealmComposition, MirageRealmComposition

ICECAP_PLAT_ENV = 'ICECAP_PLAT'

LOG_LEVELS = [logging.WARNING, logging.INFO, logging.DEBUG]

def parse_args():
    parser = ArgumentParser()
    parser.add_argument('-v', '--verbose', dest='log_level', action='count', default=0)

    subparsers = parser.add_subparsers(dest='cmd', required=True)

    def add_common_arguments(subparser):
        subparser.add_argument('config', metavar='CONFIG', nargs='?', type=FileType('r'), default=sys.stdin)
        subparser.add_argument('-o', '--out-dir', metavar='OUT_DIR', type=Path)

    subparser = subparsers.add_parser('firmware')
    add_common_arguments(subparser)

    subparser = subparsers.add_parser('linux-realm')
    add_common_arguments(subparser)

    subparser = subparsers.add_parser('mirage-realm')
    add_common_arguments(subparser)

    return parser.parse_args()

def update_args_from_env(args):
    # TODO
    # args.x = arg_or_env(args.x, X_ENV)
    pass

def arg_or_env(arg, env_name):
    return arg if arg is not None else os.getenv(env_name)

def apply_verbosity(args):
    level = LOG_LEVELS[min(args.log_level, len(LOG_LEVELS) - 1)]
    logging.basicConfig(level=level)

def main():
    args = parse_args()
    update_args_from_env(args)
    apply_verbosity(args)
    run(args)

def run(args):

    if args.cmd == 'firmware':
        config = json.load(args.config)
        args.config.close()
        FirmwareComposition(args.out_dir, config).run()

    elif args.cmd == 'linux-realm':
        config = json.load(args.config)
        args.config.close()
        LinuxRealmComposition(args.out_dir, config).run()

    elif args.cmd == 'mirage-realm':
        config = json.load(args.config)
        args.config.close()
        MirageRealmComposition(args.out_dir, config).run()

    else:
        assert False


if __name__ == '__main__':
    main()
