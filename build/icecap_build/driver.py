from pathlib import Path
import shutil
import subprocess
import logging
logger = logging.getLogger(__name__)

EXPORT = Path(__file__).parent.parent / 'export'

class Driver:

    def __init__(self, plat=None):
        self.exe = find_exe()
        self.plat = plat

    def require_plat(self):
        if self.plat is None:
            raise Exception('missing --plat or ICECAP_PLAT')

    def invoke(self, out_link, target, attrs):
        args = [self.exe, str(EXPORT), '--out-link', out_link, '--attr', target]
        for k, v in attrs.items():
            args.extend(['--argstr', k, v])
        env = filter_attrs(ICECAP_PLAT=self.plat)
        subprocess.run(args, env=env, check=True)

    def target(self, out_link, target):
        self.invoke(out_link, target, {})

    def host(self, out_link, kernel=None, initramfs=None, bootargs=None):
        self.require_plat()
        self.invoke(out_link, 'host', filter_attrs(
            kernel=map_absolute(kernel),
            initramfs=map_absolute(initramfs),
            bootargs=args.bootargs,
            ))

    def realm(self, out_link, kernel=None, initramfs=None, bootargs=None):
        self.require_plat()
        self.invoke(out_link, 'realm', filter_attrs(
            kernel=map_absolute(kernel),
            initramfs=map_absolute(initramfs),
            bootargs=args.bootargs,
            ))


def filter_attrs(**kwargs):
    return { k: v for k, v in kwargs.items() if v is not None }

def map_absolute(path):
    return path if path is None else path.absolute()

def find_exe():
    exe = shutil.which('nix-build')
    if exe is None:
        raise Exception('nix-build not found in PATH')
    return exe
