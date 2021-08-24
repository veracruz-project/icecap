from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icedl.common import Composition as BaseComposition, FaultHandler, RingBufferObjects, RingBufferSideObjects
from icedl.realm.components.vm import RealmVM
from icedl.utils import as_, as_list, BLOCK_SIZE, BLOCK_SIZE_BITS, PAGE_SIZE, PAGE_SIZE_BITS

NUM_NODES = 1

REALM_ID = 0

class Composition(BaseComposition):

    @classmethod
    def run(cls):
        cls.from_env().complete()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.compose()

    def compose(self):
        # self.fault_handler = self.component(FaultHandler, 'fault_handler', affinity=1, prio=250)
        self.realm_vm = self.component(RealmVM, name='realm_vm', vmm_name='realm_vmm')

        realm_vm_con = self.extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(self.realm_id()), size=4096)
        realm_vm_con_kick = self.extern(ObjectType.seL4_NotificationObject, 'realm_{}_serial_server_kick'.format(self.realm_id()))
        self.realm_vm.map_con(realm_vm_con, { 'Notification': self.realm_vm.vmm.cspace().alloc(realm_vm_con_kick, write=True) }, { 'SerialServer': None })

        net = self.extern_ring_buffer('realm_{}_net_ring_buffer'.format(self.realm_id()), size=1<<(21 + 3))
        self.realm_vm.map_net(net, { 'OutIndex': { 'RingBuffer': { 'Host': None }}}, { 'Host': None })

    def extern(self, ty, name, **obj_kwargs):
        return self.alloc(ty, name='extern_{}'.format(name), **obj_kwargs)

    @as_list
    def extern_region(self, name, size_bits, region_size):
        ty = ObjectType.seL4_FrameObject
        size = 1 << size_bits
        for i in range(region_size // (1 << size_bits)):
            yield self.extern(ty, '{}_{}'.format(name, i), size=size), size_bits

    def extern_ring_buffer(self, tag, size):
        ctrl_size = 4096
        data_size = size
        # HACK
        if size & (BLOCK_SIZE - 1) == 0:
            frame_size_bits = BLOCK_SIZE_BITS
        else:
            frame_size_bits = PAGE_SIZE_BITS
        return RingBufferObjects(
            read=RingBufferSideObjects(
                size=data_size,
                ctrl=self.extern_region('{}_read_ctrl'.format(tag), PAGE_SIZE_BITS, ctrl_size),
                data=self.extern_region('{}_read_data'.format(tag), frame_size_bits, data_size),
                ),
            write=RingBufferSideObjects(
                size=data_size,
                ctrl=self.extern_region('{}_write_ctrl'.format(tag), PAGE_SIZE_BITS, ctrl_size),
                data=self.extern_region('{}_write_data'.format(tag), frame_size_bits, data_size),
                ),
            )

    def create_gic_vcpu_frame(self):
        return self.extern(ObjectType.seL4_FrameObject, 'realm_{}_gic_vcpu_frame'.format(self.realm_id()))

    def num_nodes(self):
        return NUM_NODES

    def realm_id(self):
        return REALM_ID

    # HACK
    def virt_to_phys_node_map(self, virt_node):
        return ({
            0: 1,
        })[virt_node]
