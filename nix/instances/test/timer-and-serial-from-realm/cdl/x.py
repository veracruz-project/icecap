from icedl import *

composition = start()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
caput = composition.component(Caput, 'caput', fault_handler=fault_handler)

timer_server.connect(serial_server)
timer_server.connect(caput)

caput.map_spec()

caput.add_extern_ring_buffer('con', serial_server.connect_raw('realm_con'))

host_caput_objs, caput_host_objs = composition.alloc_ring_buffer(
    a_name='host_caput_rb', a_size_bits=21,
    b_name='caput_host_rb', b_size_bits=21,
    )

caput.map_host(caput_host_objs)

composition.complete()
