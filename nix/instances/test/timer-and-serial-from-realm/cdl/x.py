from icedl import *

composition = start()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
resource_server = composition.component(ResourceServer, 'resource_server', fault_handler=fault_handler)

timer_server.connect(serial_server)
timer_server.connect(resource_server)

resource_server.map_spec()

resource_server.add_extern_ring_buffer('con', serial_server.connect_raw('realm_con'))

host_resource_server_objs, resource_server_host_objs = composition.alloc_ring_buffer(
    a_name='host_resource_server_rb', a_size_bits=21,
    b_name='resource_server_host_rb', b_size_bits=21,
    )

resource_server.map_host(resource_server_host_objs)

composition.complete()
