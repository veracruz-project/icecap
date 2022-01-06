from capdl import ObjectType, Cap, ARMIRQMode
from icecap_framework import GenericElfComponent
from icecap_framework.utils import PAGE_SIZE, PAGE_SIZE_BITS

BADGE_IRQ = 1 << 0
BADGE_CLIENT = 1 << 1

class TimerServer(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        paddr = 0x9090000
        irq = 208
        trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL

        self.align(PAGE_SIZE)
        self.skip(PAGE_SIZE)
        vaddr = self.cur_vaddr
        self.skip(PAGE_SIZE)

        self.map_page(vaddr, paddr=paddr, label='timer_mmio', read=True, write=True, cached=False)

        event_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='event_nfn')

        irq_handler = self.cspace().alloc(
                self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}_handler'.format(irq), number=irq, trigger=trigger, notification=Cap(event_nfn, badge=BADGE_IRQ))
                )

        self.primary_thread.tcb['bound_notification'] = Cap(event_nfn, read=True)

        self.loop_ep = self.alloc(ObjectType.seL4_EndpointObject, name='loop_ep')

        self._arg = {
            'loop_ep': self.cspace().alloc(self.loop_ep, read=True),
            'dev_vaddr': vaddr,
            'irq_handler': irq_handler,
            'badges': {
                'irq': BADGE_IRQ,
                'client': BADGE_CLIENT,
                },
            }

    def register_client(self, client, timeout_nfn, timeout_nfn_badge):
        self._arg['client_timeout'] = self.cspace().alloc(timeout_nfn, badge=timeout_nfn_badge, write=True)
        return client.cspace().alloc(self.loop_ep, badge=BADGE_CLIENT, write=True)

    def arg_json(self):
        return self._arg
