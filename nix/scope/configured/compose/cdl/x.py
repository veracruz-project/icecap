from icedl import *

composition = start()

gic_vcpu_frame = composition.gic_vcpu_frame()

idle = composition.component(Idle, 'idle', affinity=3, prio=255)
fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
resource_server = composition.component(ResourceServer, 'resource_server', fault_handler=fault_handler)
host_vm = composition.component(HostVM, name='host_vm', vmm_name='host_vmm', affinity=0, gic_vcpu_frame=gic_vcpu_frame)
host_vmm = host_vm.vmm

timer_server.connect(serial_server)
timer_server.connect(host_vmm)
timer_server.connect(resource_server)

resource_server.add_extern('gic_vcpu_frame', 'SmallPage', resource_server.cspace().alloc(gic_vcpu_frame, read=True, write=True))

host_resource_server_objs, resource_server_host_objs = composition.alloc_ring_buffer(
    a_name='host_resource_server_rb', a_size_bits=21,
    b_name='resource_server_host_rb', b_size_bits=21,
    )

host_realm_objs, realm_host_objs = composition.alloc_ring_buffer(
    a_name='host_realm_rb', a_size_bits=21,
    b_name='realm_host_rb', b_size_bits=21,
    )

resource_server.map_host(resource_server_host_objs)
host_vm.map_rb(host_resource_server_objs, id=0, name='rb_resource_server')
resource_server.add_extern_ring_buffer('host_net', realm_host_objs)
host_vm.map_net(host_realm_objs)

host_vm.map_con(serial_server.connect_raw('host_vm_con'))
resource_server.add_extern_ring_buffer('realm_vm_con', serial_server.connect_raw('realm_vm_con'))
serial_server.connect(host_vmm)
resource_server.add_extern_ring_buffer('realm_vmm_con', serial_server.connect_raw('realm_vmm_con'))

host_vmm._arg['resource_server_ep_write'] = host_vmm.cspace().alloc(resource_server.host_ep, write=True, grantreply=True)

composition.complete()
