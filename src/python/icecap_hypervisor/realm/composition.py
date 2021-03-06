from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icecap_framework import BaseComposition, RingBufferObjects, RingBufferSideObjects
from icecap_hypervisor.common import FaultHandler
from icecap_hypervisor.realm.components.vm import RealmVM
from icecap_hypervisor.realm.components.mirage import Mirage
from icecap_framework.utils import as_, as_list, BLOCK_SIZE, BLOCK_SIZE_BITS, PAGE_SIZE, PAGE_SIZE_BITS

class BaseRealmComposition(BaseComposition):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._num_cores = self.config['num_cores']
        self._realm_id = self.config['realm_id']
        self._hack_realm_affinity = self.config['hack_realm_affinity']

    def compose(self):
        raise NotImplementedError

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
        return self._num_cores

    def realm_id(self):
        return self._realm_id

    # HACK
    def virt_to_phys_node_map(self, virt_node):
        return ({
            0: self._hack_realm_affinity,
        })[virt_node]


class LinuxRealmComposition(BaseRealmComposition):

    def compose(self):

        # TODO
        # self.fault_handler = self.component(FaultHandler, 'fault_handler', affinity=1, prio=250)

        self.realm_vm = self.component(RealmVM, name='realm_vm', vmm_name='realm_vmm')

        realm_vm_con = self.extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(self.realm_id()), size=4096)
        realm_vm_con_kick = self.extern(ObjectType.seL4_NotificationObject, 'realm_{}_serial_server_kick'.format(self.realm_id()))
        self.realm_vm.map_con(realm_vm_con,
            { 'Raw': { 'notification': self.realm_vm.cspace().alloc(realm_vm_con_kick, write=True) } },
            { 'SerialServer': None }
            )

        net = self.extern_ring_buffer('realm_{}_net_ring_buffer'.format(self.realm_id()), size=1<<(21 + 3))
        self.realm_vm.map_net(
            net,
            { 'Managed': {
                'message': self.serialize_event_server_out('realm', { 'RingBuffer': { 'Host': { 'Net': None } }}),
                'endpoints': self.realm_vm.event_server_out_endpoints,
                },
            },
            { 'Host': { 'Net': None } }
            )

        channel = self.extern_ring_buffer('realm_{}_channel_ring_buffer'.format(self.realm_id()), size=1<<21)
        self.realm_vm.map_channel(
            'icecap_channel_host',
            channel,
            { 'Managed': {
                'message': self.serialize_event_server_out('realm', { 'RingBuffer': { 'Host': { 'Channel': None } }}),
                'endpoints': self.realm_vm.event_server_out_endpoints,
                },
            },
            { 'Host': { 'Channel': None } }
            )


class MirageRealmComposition(BaseRealmComposition):

    def compose(self):
        self.component(Mirage, 'mirage')
