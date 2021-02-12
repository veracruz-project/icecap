from icedl import *

composition = start()

gic_vcpu_frame = composition.gic_vcpu_frame()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
host_vm = composition.component(HostVM, 'host_vm', 'host_vmm', affinity=0, gic_vcpu_frame=gic_vcpu_frame)
host_vmm = host_vm.vmm
guest_vm = composition.component(VM, 'guest_vm', 'guest_vmm', affinity=3, gic_vcpu_frame=gic_vcpu_frame)
guest_vmm = guest_vm.vmm

timer_server.connect(serial_server)
timer_server.connect(host_vmm)
timer_server.connect(guest_vmm)

host_vm.map_con(serial_server.connect_raw('host_vm_con'))
guest_vm.map_con(serial_server.connect_raw('guest_vm_con'))

serial_server.connect(host_vmm, mapped=True)
serial_server.connect(guest_vmm, mapped=True)

a, b = composition.alloc_ring_buffer(
    a_name='host_vm_net', a_size_bits=20,
    b_name='guest_vm_net', b_size_bits=20,
    )

host_vm.map_net(a)
guest_vm.map_net(b)

a, b = composition.alloc_ring_buffer(
    a_name='host_vm_rb', a_size_bits=12,
    b_name='guest_vm_rb', b_size_bits=12,
    )

host_vm.map_rb(a, id=0, name='foo')
guest_vm.map_rb(b, id=0, name='foo')

composition.complete()
