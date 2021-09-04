from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icedl.common import Composition as BaseComposition, FaultHandler
from icedl.firmware.components.idle import Idle
from icedl.firmware.components.timer_server import TimerServer
from icedl.firmware.components.serial_server import SerialServer
from icedl.firmware.components.resource_server import ResourceServer
from icedl.firmware.components.event_server import EventServer
from icedl.firmware.components.vm import VMM, VM, HostVM

NUM_NODES = 3
NUM_REALMS = 2

HACK_AFFINITY = 1

class Composition(BaseComposition):

    @classmethod
    def run(cls):
        cls.from_env().complete()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.compose()

    def compose(self):
        self.idle = self.component(Idle, 'idle', affinity=self.num_nodes(), prio=255)
        self.fault_handler = self.component(FaultHandler, 'fault_handler', affinity=HACK_AFFINITY, prio=250)
        self.timer_server = self.component(TimerServer, 'timer_server', prio=175, fault_handler=self.fault_handler)
        self.event_server = self.component(EventServer, 'event_server', prio=200, fault_handler=self.fault_handler)
        self.resource_server = self.component(ResourceServer, 'resource_server', prio=150, max_prio=255, fault_handler=self.fault_handler)
        self.serial_server = self.component(SerialServer, 'serial_server', affinity=HACK_AFFINITY, prio=180, fault_handler=self.fault_handler)
        self.host_vm = self.component(HostVM, name='host_vm', vmm_name='host_vmm')

        cfg = self.serial_server.register_host(self.host_vm.vmm)
        self.host_vm.map_con(cfg['ring_buffer_objs'], { 'Notification': cfg['kick'] }, { 'SerialServer': None })

        self.event_server.register_host_notifications(self.host_vm.vmm.event_server_targets)

        for i in range(self.num_realms()):

            self.resource_server.add_extern('realm_{}_gic_vcpu_frame'.format(i), 'SmallPage', self.resource_server.cspace().alloc(self.gic_vcpu_frame(), read=True, write=True))

            serial_server_config = self.serial_server.register_realm(self.resource_server)
            self.resource_server.add_extern('realm_{}_serial_server_kick'.format(i), 'Notification', serial_server_config['kick'])
            self.resource_server.add_extern_ring_buffer('realm_{}_serial_server_ring_buffer'.format(i), serial_server_config['ring_buffer_objs'])

            event_server_client = self.event_server.register_client(self.resource_server, {
                'Realm': i,
            })
            for j, ep in enumerate(event_server_client):
                self.resource_server.add_extern('realm_{}_event_server_client_endpoint_{}'.format(i, j), 'Endpoint', ep)

            nfns = []
            for j in range(self.num_nodes()):
                name = 'realm_{}_nfn_for_core_{}'.format(i, j)
                nfn = self.alloc(ObjectType.seL4_NotificationObject, name)
                self.resource_server.add_extern(name, 'Notification', self.resource_server.cspace().alloc(nfn, read=True))
                nfns.append((nfn, 0))
            self.event_server.register_realm_notifications(nfns)

            host_realm_net_objs, realm_host_net_objs = self.alloc_ring_buffer(
                a_name='host_realm_{}_net_rb'.format(i), a_size_bits=21 + 3,
                b_name='realm_{}_host_net_rb'.format(i), b_size_bits=21 + 3,
                )

            self.resource_server.add_extern_ring_buffer('realm_{}_net_ring_buffer'.format(i), realm_host_net_objs)
            self.host_vm.map_net(host_realm_net_objs, { 'OutIndex': { 'RingBuffer': { 'Realm': i }}}, { 'Realm': i })

        # host_resource_server_objs, resource_server_host_objs = composition.alloc_ring_buffer(
        #     a_name='host_resource_server_rb', a_size_bits=21,
        #     b_name='resource_server_host_rb', b_size_bits=21,
        #     )

        # host_realm_raw_objs, realm_host_raw_objs = composition.alloc_ring_buffer(
        #     a_name='host_realm_raw_rb', a_size_bits=21,
        #     b_name='realm_host_raw_rb', b_size_bits=21,
        #     )

        # resource_server.map_host(resource_server_host_objs)
        # host_vm.map_rb(host_resource_server_objs, id=0, name='rb_resource_server')
        # resource_server.add_extern_ring_buffer('host_net', realm_host_net_objs)
        # host_vm.map_net(host_realm_net_objs)
        # resource_server.add_extern_ring_buffer('host_raw', realm_host_raw_objs)
        # host_vm.map_rb(host_realm_raw_objs, id=1, name='rb_realm')

        # host_vm.map_con(serial_server.connect_raw('host_vm_con'))
        # resource_server.add_extern_ring_buffer('realm_vm_con', serial_server.connect_raw('realm_vm_con'))
        # serial_server.connect(host_vmm)
        # resource_server.add_extern_ring_buffer('realm_vmm_con', serial_server.connect_raw('realm_vmm_con'))

    def create_gic_vcpu_frame(self):
        if self.plat == 'virt':
            GIC_PADDR = 0x8000000
            GIC_VCPU_PADDR = GIC_PADDR + 0x40000
        elif self.plat == 'rpi4':
            GIC_VCPU_PADDR = 0xff846000
        frame = self.alloc(ObjectType.seL4_FrameObject, name='gic_vcpu', paddr=GIC_VCPU_PADDR, size=4096)
        return frame

    def num_nodes(self):
        return NUM_NODES

    def num_realms(self):
        return NUM_REALMS
