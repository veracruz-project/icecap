import os
from capdl import ObjectType, Cap
from icedl import *

composition = start()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)

for c in [timer_server, serial_server]:
    for thread in c.threads():
        fault_handler.handle(thread)

timer_server.connect(serial_server)

composition.complete()
