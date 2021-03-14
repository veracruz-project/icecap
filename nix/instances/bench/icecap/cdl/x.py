from icedl import *

composition = start()

gic_vcpu_frame = composition.gic_vcpu_frame()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
caput = composition.component(Caput, 'caput', fault_handler=fault_handler)
host_vm = composition.component(HostVM, name='host_vm', vmm_name='host_vmm', affinity=0, gic_vcpu_frame=gic_vcpu_frame)
host_vmm = host_vm.vmm

timer_server.connect(serial_server)
timer_server.connect(host_vmm)
timer_server.connect(caput)

caput.add_extern('gic_vcpu_frame', 'SmallPage', caput.cspace().alloc(gic_vcpu_frame, read=True, write=True))

host_caput_objs, caput_host_objs = composition.alloc_ring_buffer(
    a_name='host_caput_rb', a_size_bits=21,
    b_name='caput_host_rb', b_size_bits=21,
    )

host_realm_objs, realm_host_objs = composition.alloc_ring_buffer(
    a_name='host_realm_rb', a_size_bits=21,
    b_name='realm_host_rb', b_size_bits=21,
    )

caput.map_host(caput_host_objs)
host_vm.map_rb(host_caput_objs, id=0, name='rb_caput')
caput.add_extern_ring_buffer('host_net', realm_host_objs)
host_vm.map_net(host_realm_objs)

host_vm.map_con(serial_server.connect_raw('host_vm_con'))
caput.add_extern_ring_buffer('realm_vm_con', serial_server.connect_raw('realm_vm_con'))
serial_server.connect(host_vmm)
caput.add_extern_ring_buffer('realm_vmm_con', serial_server.connect_raw('realm_vmm_con'))

composition.complete()
