from capdl import ObjectType, Cap, ARMIRQMode
from icecap_framework import GenericElfComponent
from icecap_framework.utils import PAGE_SIZE, PAGE_SIZE_BITS

BADGE_IRQ = 1 << 0
BADGE_CLIENT = 1 << 1

class SerialServer(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        paddr = 0x9000000
        irq = 33
        trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL

        self.align(PAGE_SIZE)
        self.skip(PAGE_SIZE)
        vaddr = self.cur_vaddr
        self.skip(PAGE_SIZE)
        self.skip(PAGE_SIZE)

        self.map_page(vaddr, paddr=paddr, label='serial_mmio', read=True, write=True, cached=False)

        self.event_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='event_nfn')

        irq_handler = self.cspace().alloc(
                self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}_handler'.format(irq), number=irq, trigger=trigger, notification=Cap(self.event_nfn, badge=BADGE_IRQ))
                )

        self._arg = {
            'dev_vaddr': vaddr,
            'event_nfn': self.cspace().alloc(self.event_nfn, read=True),
            'irq_handler': irq_handler,
            'badges': {
                'irq': BADGE_IRQ,
                'client': BADGE_CLIENT,
                },
            }

    def register_client(self, client, kick_nfn, kick_nfn_badge):
        server_rb_objs, client_rb_objs = self.composition.alloc_ring_buffer(
            a_name=self.name, a_size_bits=PAGE_SIZE_BITS,
            b_name=client.name, b_size_bits=PAGE_SIZE_BITS,
            )
        kick_cap = self.cspace().alloc(kick_nfn, badge=kick_nfn_badge, write=True)
        self._arg['client_ring_buffer'] = {
            'ring_buffer': self.map_ring_buffer(server_rb_objs),
            'kicks': {
                'read': kick_cap,
                'write': kick_cap,
                },
            }
        return client_rb_objs, client.cspace().alloc(self.event_nfn, badge=BADGE_CLIENT, write=True)

    def arg_json(self):
        return self._arg
