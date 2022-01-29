from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icecap_framework import BaseComposition
from icecap_hypervisor.common import FaultHandler
from icecap_hypervisor.firmware.components.idle import Idle
from icecap_hypervisor.firmware.components.timer_server import TimerServer
from icecap_hypervisor.firmware.components.serial_server import SerialServer
from icecap_hypervisor.firmware.components.resource_server import ResourceServer
from icecap_hypervisor.firmware.components.event_server import EventServer
from icecap_hypervisor.firmware.components.benchmark_server import BenchmarkServer
from icecap_hypervisor.firmware.components.vm import VMM, VM, HostVM

class FirmwareComposition(BaseComposition):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._num_cores = self.config['num_cores']
        self._num_realms = self.config['num_realms']
        self._default_affinity = self.config['default_affinity']
        self._hack_realm_affinity = self.config['hack_realm_affinity']

    def compose(self):
        self.idle = self.component(Idle, 'idle', affinity=self.num_nodes(), prio=251)
        self.benchmark_server = self.component(BenchmarkServer, 'benchmark_server', prio=252)
        self.fault_handler = self.component(FaultHandler, 'fault_handler', affinity=self._default_affinity, prio=250)
        self.timer_server = self.component(TimerServer, 'timer_server', prio=175, fault_handler=self.fault_handler)
        self.event_server = self.component(EventServer, 'event_server', prio=200, fault_handler=self.fault_handler)
        self.resource_server = self.component(ResourceServer, 'resource_server', prio=150, max_prio=255, fault_handler=self.fault_handler)
        self.serial_server = self.component(SerialServer, 'serial_server', affinity=self._default_affinity, prio=180, fault_handler=self.fault_handler)
        self.host_vm = self.component(HostVM, name='host_vm', vmm_name='host_vmm')

        cfg = self.serial_server.register_host(self.host_vm)
        self.host_vm.map_con(cfg['ring_buffer_objs'], { 'Raw': { 'notification': cfg['kick'] } }, { 'SerialServer': None })

        self.event_server.register_host_notifications(self.host_vm.vmm.event_server_targets)

        for i in range(self.num_realms()):

            self.resource_server.add_extern('realm_{}_gic_vcpu_frame'.format(i), 'SmallPage', self.resource_server.cspace().alloc(self.gic_vcpu_frame(), read=True, write=True))

            serial_server_config = self.serial_server.register_realm(self.resource_server)
            self.resource_server.add_extern('realm_{}_serial_server_kick'.format(i), 'Notification', serial_server_config['kick'])
            self.resource_server.add_extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(i), serial_server_config['ring_buffer_objs'])

            event_server_client = self.event_server.register_client(self.resource_server, self.resource_server, {
                'Realm': i,
            })
            for j, eps in enumerate(event_server_client):
                self.resource_server.add_extern('realm_{}_event_server_client_endpoint_{}'.format(i, j), 'Endpoint', eps[0])
                self.resource_server.add_extern('realm_{}_event_server_client_endpoint_out_{}'.format(i, j), 'Endpoint', eps[1])

            nfns = []
            for j in range(self.num_nodes()):
                name = 'realm_{}_nfn_for_core_{}'.format(i, j)
                nfn = self.alloc(ObjectType.seL4_NotificationObject, name)
                bitfield_name = 'realm_{}_event_bitfield_for_core_{}'.format(i, j)
                bitfield = self.alloc(ObjectType.seL4_FrameObject, name=bitfield_name, size_bits=12)
                self.resource_server.add_extern(name, 'Notification', self.resource_server.cspace().alloc(nfn, read=True))
                self.resource_server.add_extern(bitfield_name, 'SmallPage', self.resource_server.cspace().alloc(bitfield, read=True, write=True))
                nfns.append((nfn, bitfield))
            self.event_server.register_realm_notifications(nfns)

            host_realm_net_objs, realm_host_net_objs = self.alloc_ring_buffer(
                a_name='host_realm_{}_net_rb'.format(i), a_size_bits=21 + 3,
                b_name='realm_{}_host_net_rb'.format(i), b_size_bits=21 + 3,
                )

            self.resource_server.add_extern_ring_buffer('realm_{}_net_ring_buffer'.format(i), realm_host_net_objs)
            self.host_vm.map_net(
                host_realm_net_objs,
                { 'Managed': {
                    'message': self.serialize_event_server_out('host', { 'RingBuffer': { 'Realm': [i, { 'Net': None }] }}),
                    'endpoints': self.host_vm.event_server_out_endpoints,
                    },
                },
                { 'Realm': [i, { 'Net': None }] }
                )

            host_realm_channel_objs, realm_host_channel_objs = self.alloc_ring_buffer(
                a_name='host_realm_{}_channel_rb'.format(i), a_size_bits=21,
                b_name='realm_{}_host_channel_rb'.format(i), b_size_bits=21,
                )

            self.resource_server.add_extern_ring_buffer('realm_{}_channel_ring_buffer'.format(i), realm_host_channel_objs)
            self.host_vm.map_channel(
                'icecap_channel_realm_{}'.format(i),
                host_realm_channel_objs,
                { 'Managed': {
                    'message': self.serialize_event_server_out('host', { 'RingBuffer': { 'Realm': [i, { 'Channel': None }] }}),
                    'endpoints': self.host_vm.event_server_out_endpoints,
                    },
                },
                { 'Realm': [i, { 'Channel': None }] }
                )

    def create_gic_vcpu_frame(self):
        if self.plat == 'virt':
            GIC_PADDR = 0x8000000
            GIC_VCPU_PADDR = GIC_PADDR + 0x40000
        elif self.plat == 'rpi4':
            GIC_VCPU_PADDR = 0xff846000
        frame = self.alloc(ObjectType.seL4_FrameObject, name='gic_vcpu', paddr=GIC_VCPU_PADDR, size=4096)
        return frame

    def num_nodes(self):
        return self._num_cores - 1

    def num_realms(self):
        return self._num_realms
