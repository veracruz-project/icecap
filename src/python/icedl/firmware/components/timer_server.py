from capdl import ObjectType, Cap, ARMIRQMode
from icedl.common import ElfComponent
from icedl.utils import *

INTERRUPT_BADGE = 1

class TimerServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=0, **kwargs)
        self.endpoints = [
            self.alloc(ObjectType.seL4_EndpointObject, name='{}_ep_for_node_{}'.format(self.name, i))
            for i in range(self.composition.num_nodes())
            ]
        self.cur_client_badge = INTERRUPT_BADGE + 1
        self.clients = []

        if self.composition.plat == 'virt':
            paddr = 0x9090000
            irq = 208
            trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL
        elif self.composition.plat == 'rpi4':
            paddr = 0xfe003000
            irq = 97
            trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL

        self.align(PAGE_SIZE)
        self.skip(PAGE_SIZE)
        vaddr = self.cur_vaddr
        self.map_page(self.cur_vaddr, paddr=paddr, label='timer', read=True, write=True, cached=False)
        self.skip(PAGE_SIZE)
        self.skip(PAGE_SIZE)

        secondary_threads = []
        irq_handlers = []
        for i in range(self.composition.num_nodes()):
            if i != 0:
                thread = self.secondary_thread('secondary_thread_{}'.format(i), affinity=i, prio=self.primary_thread.tcb.prio)
                secondary_threads.append(thread.endpoint)
            else:
                thread = self.primary_thread

            # HACK
            # if i == 0:
            if i == 1:
                irq_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='irq_{}_nfn'.format(irq))
                thread.tcb['bound_notification'] = Cap(irq_nfn, badge=INTERRUPT_BADGE, read=True)
                irq_handler = self.cspace().alloc(
                        self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}'.format(irq), number=irq, trigger=trigger, target=i, notification=Cap(irq_nfn, badge=1))
                        )
            else:
                irq_handler = 0
            irq_handlers.append(irq_handler)

        self._arg = {
            'lock': self.cspace().alloc(self.alloc(ObjectType.seL4_NotificationObject, name='lock'), read=True, write=True),
            'dev_vaddr': vaddr,
            'irq_handlers': irq_handlers,

            'endpoints': [ self.cspace().alloc(ep, read=True) for ep in self.endpoints ],
            'secondary_threads': secondary_threads,
            }

    def connect(self, client, node_index, nfn, nfn_badge):
        badge = self.cur_client_badge
        self.cur_client_badge += 1
        client_endpoint_cap = client.cspace().alloc(self.endpoints[node_index], badge=badge, write=True, grantreply=True)
        self.clients.append(self.cspace().alloc(nfn, badge=nfn_badge, write=True))
        return client_endpoint_cap

    def serialize_arg(self):
        return 'serialize-timer-server-config'

    def arg_json(self):
        self._arg.update({
            'clients': self.clients,
        })
        return self._arg
