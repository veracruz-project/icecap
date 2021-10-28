import os
from pathlib import Path
from argparse import ArgumentParser
import logging
logger = logging.getLogger(__name__)

from icecap_build.driver import Driver

ICECAP_PLAT_ENV = 'ICECAP_PLAT'

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

    driver = Driver(plat=args.plat)

    if args.cmd == 'host':
        driver.host(
            args.out_link,
            kernel=args.kernel,
            initramfs=args.initramfs,
            bootargs=args.bootargs,
            )

    if args.cmd == 'realm':
        driver.realm(
            args.out_link,
            kernel=args.kernel,
            initramfs=args.initramfs,
            bootargs=args.bootargs,
            )

    elif args.cmd == 'shadow-vmm':
        driver.target(args.out_link, 'shadow-vmm')

    elif args.cmd == 'target':
        driver.target(args.out_link, args.target)

    else:
        assert False


if __name__ == '__main__':
    main()
