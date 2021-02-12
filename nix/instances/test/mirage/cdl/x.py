import os
from capdl import ObjectType, Cap
from icedl import *

class Mirage(GenericElfComponent):

    def arg_json(self):
        return {
            'test': 'Hello, World!',
        }

composition = start()

mirage = composition.component(Mirage, 'mirage')

# fault_handler = composition.component(FaultHandler, 'fault_handler')
# timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
# serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
# mirage = composition.component(Mirage, 'mirage', fault_handler=fault_handler)

# timer_server.connect(serial_server)

composition.complete()
