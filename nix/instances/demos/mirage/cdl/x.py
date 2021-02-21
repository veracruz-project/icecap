import os
from capdl import ObjectType, Cap
from icedl import *

class Mirage(GenericElfComponent):

    def arg_json(self):
        return {
            'event_ep': self.cspace().alloc(self.alloc(ObjectType.seL4_EndpointObject, 'event'), read=True, write=True),

            'timer': self.connections['timer']['TimerClient'],
            'con': self.connections['con']['MappedRingBuffer'],
            'net': self.connections['net']['MappedRingBuffer'],

            'timer_thread': self.secondary_thread('timer').endpoint,
            'net_thread': self.secondary_thread('net').endpoint,

            'passthru': {
                'mac': '00:0a:95:9d:68:16',
                'ip': '192.168.1.2',
                'network': '192.168.1.0/24',
                'gateway': '192.168.1.1',
            },
        }

composition = start()

gic_vcpu_frame = composition.gic_vcpu_frame()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
host_vm = composition.component(HostVM, 'host_vm', 'host_vmm', affinity=0, gic_vcpu_frame=gic_vcpu_frame)
host_vmm = host_vm.vmm
mirage = composition.component(Mirage, 'mirage', affinity=3, fault_handler=fault_handler)

timer_server.connect(serial_server)
timer_server.connect(host_vmm)
timer_server.connect(mirage)

host_vm.map_con(serial_server.connect_raw('host_vm_con'))
serial_server.connect(host_vmm)
serial_server.connect(mirage)

a, b = composition.alloc_ring_buffer(
    a_name='host_vm_net', a_size_bits=20,
    b_name='mirage_net', b_size_bits=20,
    )

host_vm.map_net(a)
mirage.connections['net'] = {
    'MappedRingBuffer': mirage.map_ring_buffer(b),
}

composition.complete()
