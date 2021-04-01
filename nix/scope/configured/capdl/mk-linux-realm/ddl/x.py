from capdl import ObjectType
from icedl import *

composition = start()

gic_vcpu_frame = composition.extern(ObjectType.seL4_FrameObject, 'gic_vcpu_frame')

realm_vm = composition.component(VM, name='realm_vm', vmm_name='realm_vmm', affinity=1, gic_vcpu_frame=gic_vcpu_frame)
realm_vmm = realm_vm.vmm

realm_vmm_con = composition.extern_ring_buffer('realm_vmm_con', size=4096)
realm_vm_con = composition.extern_ring_buffer('realm_vm_con', size=4096)
host_rb = composition.extern_ring_buffer('host_net', 1 << 21)

realm_vm.map_con(realm_vm_con)
realm_vm.map_net(host_rb)

realm_vmm.connections['con'] = {
    'MappedRingBuffer': realm_vmm.map_ring_buffer_with(realm_vmm_con, mapped=True),
    }

composition.complete()
