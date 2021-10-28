import os
from pathlib import Path
from argparse import ArgumentParser
import subprocess
import logging
logger = logging.getLogger(__name__)

ICECAP_PLAT_ENV = 'ICECAP_PLAT'

EXPORT = Path(__file__).parent.parent / 'export'

LOG_LEVELS = [logging.WARNING, logging.INFO, logging.DEBUG]

def parse_args():
    parser = ArgumentParser()
    parser.add_argument('-v', '--verbose', dest='log_level', action='count', default=0)
    parser.add_argument('--plat', metavar='ICECAP_PLAT')

    subparsers = parser.add_subparsers(dest='cmd', required=True)

    subparser = subparsers.add_parser('host')
    subparser.add_argument('--kernel', metavar='KERNEL', type=Path)
    subparser.add_argument('--initramfs', metavar='INITRAMFS', type=Path, required=True)
    subparser.add_argument('--bootargs', metavar='BOOTARGS')
    subparser.add_argument('-o', '--out-link', metavar='OUT_LINK', required=True)

    subparser = subparsers.add_parser('realm')
    subparser.add_argument('--kernel', metavar='KERNEL', type=Path)
    subparser.add_argument('--initramfs', metavar='INITRAMFS', type=Path, required=True)
    subparser.add_argument('--bootargs', metavar='BOOTARGS')
    subparser.add_argument('-o', '--out-link', metavar='OUT_LINK', required=True)

    subparser = subparsers.add_parser('shadow-vmm')
    subparser.add_argument('-o', '--out-link', metavar='OUT_LINK', required=True)

    subparser = subparsers.add_parser('target')
    subparser.add_argument('target', metavar='TARGET')
    subparser.add_argument('-o', '--out-link', metavar='OUT_LINK', required=True)

    return parser.parse_args()

def update_args_from_env(args):
    args.plat = arg_or_env(args.plat, ICECAP_PLAT_ENV)

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

    if args.cmd == 'host':
        require_plat(args)
        invoke(args.plat, args.out_link, 'host', filter_attrs(
            kernel=map_absolute(args.kernel),
            initramfs=map_absolute(args.initramfs),
            bootargs=args.bootargs,
            ))

    elif args.cmd == 'realm':
        require_plat(args)
        invoke(args.plat, args.out_link, 'realm', filter_attrs(
            kernel=map_absolute(args.kernel),
            initramfs=map_absolute(args.initramfs),
            bootargs=args.bootargs,
            ))

    elif args.cmd == 'shadow-vmm':
        invoke(args.plat, args.out_link, 'shadow-vmm', {})

    elif args.cmd == 'target':
        invoke(args.plat, args.out_link, args.target, {})

    else:
        assert False

def filter_attrs(**kwargs):
    return { k: v for k, v in kwargs.items() if v is not None }

def require_plat(args):
    plat = args.plat
    assert plat is not None
    return plat

def map_absolute(path):
    return path if path is None else path.absolute()

def invoke(plat, out_link, target, attrs):
    nix_args = ['nix-build', str(EXPORT), '--out-link', out_link, '--attr', target]
    for k, v in attrs.items():
        nix_args.extend(['--argstr', k, v])
    env = filter_attrs(ICECAP_PLAT=plat)
    env['PATH'] = os.environ['PATH']
    subprocess.run(nix_args, env=env, check=True)

if __name__ == '__main__':
    main()
