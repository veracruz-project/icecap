from icecap_framework import *

from serial_server import SerialServer
from timer_server import TimerServer
from application import Application

class Composition(BaseComposition):

    def compose(self):
        self.serial_server = self.component(SerialServer, 'serial_server')
        self.timer_server = self.component(TimerServer, 'timer_server')
        self.component(Application, 'application')

Composition.from_env().run()
