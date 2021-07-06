from capdl import ObjectType, Cap, ARMIRQMode
from icedl.common import ElfComponent
from icedl.utils import as_list, PAGE_SIZE

class SerialServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.realm_clients = []

    def register_client(self, client_cspace, client_name):
        a, b = self.composition.alloc_ring_buffer(
            a_name='serial_server', a_size_bits=12,
            b_name=client_name, b_size_bits=12,
            )
        nfn = self.alloc(ObjectType.seL4_NotificationObject, name='rb_{}_nfn'.format(client_name))
        serial_server_config = {
            'thread': self.secondary_thread('client_{}'.format(client_name)).endpoint,
            'wait': self.cspace().alloc(nfn, read=True),
            'ring_buffer': self.map_ring_buffer(a),
            }
        client_config = {
            'nfn_write': client_cspace.alloc(nfn, badge=0, write=True),
            'nfn_read': client_cspace.alloc(nfn, badge=0, write=True),
            'ring_buffer_objs': b,
            }
        return serial_server_config, client_config

    def register_host(self, host):
        serial_server_config, client_config = self.register_client(host.cspace(), 'host')
        self.host_client = serial_server_config
        return client_config

    def register_realm(self, resource_server):
        serial_server_config, client_config = self.register_client(resource_server.cspace(), 'realm_{}'.format(len(self.realm_clients)))
        self.realm_clients.append(serial_server_config)
        return client_config

    def serialize_arg(self):
        return 'serialize-serial-server-config'

    def arg_json(self):
        if self.composition.plat == 'virt':
            paddr = 0x9000000
            irq = 33
            trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL
        elif self.composition.plat == 'rpi4':
            paddr = 0xfe215000
            irq = 125
            trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL

        self.align(PAGE_SIZE)
        self.skip(PAGE_SIZE)
        vaddr = self.cur_vaddr
        self.map_page(self.cur_vaddr, paddr=paddr, label='serial_device', read=True, write=True, cached=False)
        self.skip(PAGE_SIZE)
        self.skip(PAGE_SIZE)

        irq_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='irq_{}_nfn'.format(irq))
        irq_handler = self.cspace().alloc(
                self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}'.format(irq), number=irq, trigger=trigger, notification=Cap(irq_nfn, badge=1))
                )

        ep = self.cspace().alloc(
                self.alloc(ObjectType.seL4_EndpointObject, name='event_ep'),
                read=True, write=True, grantreply=True,
                )

        timer_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='timer_nfn')

        config = {
            'cnode': self.cspace().alloc(self.cspace().cnode, write=True),
            'reply_ep': self.cspace().alloc(None),
            'dev_vaddr': vaddr,
            'ep': ep,
            'event_server': self.composition.event_server.register_client(self, 'SerialServer')[self.primary_thread.tcb.affinity],
            'host_client': self.host_client,
            'realm_clients': self.realm_clients,
            'irq_nfn': self.cspace().alloc(irq_nfn, read=True),
            'irq_handler': irq_handler,
            'irq_thread': self.secondary_thread('irq_{}'.format(irq)).endpoint,
            'timer_ep_write': self.composition.timer_server.connect(self, self.primary_thread.tcb.affinity, timer_nfn, 0),
            'timer_wait': self.cspace().alloc(timer_nfn, read=True),
            'timer_thread': self.secondary_thread('serial_timer').endpoint,
            }

        return config
