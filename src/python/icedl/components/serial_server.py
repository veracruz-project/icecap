from capdl import ObjectType, Cap, ARMIRQMode
from icedl.components.elf import ElfComponent
from icedl.utils import as_list, PAGE_SIZE

HACK_AFFINITY = 1 # HACK

class SerialServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=HACK_AFFINITY, **kwargs)
        self.clients = []

    def connect_raw(self, client_name):
        a, b = self.composition.alloc_ring_buffer(
                a_name='serial_server', a_size_bits=12,
                b_name=client_name, b_size_bits=12,
                )
        self.clients.append(self.map_ring_buffer(a))
        return b

    def connect(self, client, interface='con', mapped=True):
        b = self.connect_raw('{}_{}'.format(client.name, interface))
        tag = 'RingBuffer'
        if mapped:
            tag = 'Mapped' + tag
        client.connections[interface] = {
            tag: client.map_ring_buffer_with(b, mapped),
            }

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

        @as_list
        def clients():
            for i, client in enumerate(self.clients):
                yield {
                    'ring_buffer': client,
                    'thread': self.secondary_thread('client_{}'.format(i)).endpoint,
                    }

        ep = self.cspace().alloc(
                self.alloc(ObjectType.seL4_EndpointObject, name='event_ep'),
                read=True, write=True, grantreply=True,
                )

        config = {
            'cnode': self.cspace().alloc(self.cspace().cnode, write=True),
            'reply_ep': self.cspace().alloc(None),
            'dev_vaddr': vaddr,
            'ep': ep,
            'clients': clients(),
            'irq_nfn': self.cspace().alloc(irq_nfn, read=True),
            'irq_handler': irq_handler,
            'irq_thread': self.secondary_thread('irq_{}'.format(irq)).endpoint,
            'timer_ep_write': self.connections['timer']['TimerClient']['ep_write'],
            'timer_wait': self.connections['timer']['TimerClient']['wait'],
            'timer_thread': self.secondary_thread('serial_timer').endpoint,
            }

        return config
