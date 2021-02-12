from icedl import *

composition = start()

gic_vcpu_frame = composition.gic_vcpu_frame()

fault_handler = composition.component(FaultHandler, 'fault_handler')
timer_server = composition.component(TimerServer, 'timer_server', fault_handler=fault_handler)
serial_server = composition.component(SerialServer, 'serial_server', fault_handler=fault_handler)
host_vm = composition.component(HostVM, 'host_vm', 'host_vmm', affinity=0, gic_vcpu_frame=gic_vcpu_frame)
host_vmm = host_vm.vmm

timer_server.connect(serial_server)
timer_server.connect(host_vmm)

host_vm.map_con(serial_server.connect_raw('host_vm_con'))
serial_server.connect(host_vmm, mapped=True)

composition.complete()
