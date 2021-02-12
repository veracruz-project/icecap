import os
from capdl import ObjectType, Cap
from icedl import *

class Test(GenericElfComponent):

    def arg_json(self):
        return {
            'timer': self.connections['timer']['TimerClient'],
            'con': self.connections['con']['MappedRingBuffer'],
            }

composition = start()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
test = composition.component(Test, 'test', fault_handler=fault_handler)

timer_server.connect(serial_server)
timer_server.connect(test)
serial_server.connect(test)

composition.complete()
