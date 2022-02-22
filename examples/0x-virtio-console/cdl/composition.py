from argparse import ArgumentParser
from pathlib import Path
import os
from xxlimited import Str

from icecap_framework import BaseComposition

from serial_server import SerialServer
from timer_server import TimerServer
from application import Application

class Composition(BaseComposition):

    def compose(self):
        self.serial_server = self.component(SerialServer, 'serial_server')
        self.timer_server = self.component(TimerServer, 'timer_server')
        self.component(Application, 'application')

parser = ArgumentParser()
parser.add_argument('-c', '--components', metavar='COMPONENTS', type=Path)
parser.add_argument('-o', '--out-dir', metavar='OUT_DIR', type=Path)
parser.add_argument('-p', '--plat', metavar='PLAT', type=Str)
parser.add_argument('-s', '--object-sizes', metavar='OBJECT_SIZES', type=Path)
args = parser.parse_args()

components_path = os.path.abspath(args.components)

config = {
    "plat": args.plat,
    "num_cores": 4,
    "num_realms": 2,
    "default_affinity": 1,
    "hack_realm_affinity": 1,
    "object_sizes": args.object_sizes,
    "components": {
        "application": {
            "image": {
                "full": os.path.join(components_path, "application.full.elf"),
                "min": os.path.join(components_path, "application.min.elf"),
            }
        },
        "serial_server": {
            "image": {
                "full": os.path.join(components_path, "serial-server.full.elf"),
                "min": os.path.join(components_path, "serial-server.min.elf"),
            }

        },
        "timer_server": {
            "image": {
                "full": os.path.join(components_path, "timer-server.full.elf"),
                "min": os.path.join(components_path, "timer-server.min.elf"),
            }
        },
    }
}

Composition(args.out_dir, config).run()