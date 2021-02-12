from capdl import ObjectType, Cap
from icedl.component.elf import ElfComponent, ElfThread
from icedl.utils import *

HACK_AFFINITY = 1 # HACK

class TimerServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=HACK_AFFINITY, **kwargs)
        self.ep = self.alloc(ObjectType.seL4_EndpointObject, name='{}_ep'.format(self.name))
        self.self_badge = 1
        self.ep_read = self.cspace().alloc(self.ep, read=True)
        self.ep_write = self.cspace().alloc(self.ep, write=True, grantreply=True, badge=self.self_badge)
        self.cur_badge = 2
        self.signals = []

        irq_thread = ElfThread(self, 'irq_handler',
            prio=130,
            affinity=self.primary_thread.tcb.affinity,
            alloc_endpoint=True,
            )

        self.irq_thread_ep = irq_thread.endpoint
        self.secondary_threads.append(irq_thread)

    def connect(self, client):
        badge = self.cur_badge
        self.cur_badge += 1
        client_ep = client.cspace().alloc(self.ep, name='timer_server', badge=badge, write=True, grantreply=True)
        nfn = self.alloc(ObjectType.seL4_NotificationObject, name='timer_{}_signal'.format(client.name))
        self.signals.append(self.cspace().alloc(nfn, write=True))
        client_nfn = client.cspace().alloc(nfn, read=True)
        client.connections['timer'] = {
            'TimerClient': {
                'ep_write': client_ep,
                'wait': client_nfn,
                },
            }

    def serialize_arg(self):
        return 'serialize-timer-server-config'

    def arg_json(self):
        if self.composition.plat == 'virt':
            paddr = 0x9090000
            irq = 208
        elif self.composition.plat == 'rpi4':
            paddr = 0xfe003000
            irq = 97

        self.align(PAGE_SIZE)
        self.skip(PAGE_SIZE)
        vaddr = self.cur_vaddr
        self.map_page(self.cur_vaddr, paddr=paddr, label='timer', read=True, write=True, cached=False)
        self.skip(PAGE_SIZE)
        self.skip(PAGE_SIZE)

        irq_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='irq_{}_nfn'.format(irq))
        irq_handler = self.cspace().alloc(
                self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}'.format(irq), number=irq, notification=Cap(irq_nfn))
                )

        config = {
            'cnode': self.cspace().alloc(self.cspace().cnode, write=True),
            'reply_ep': self.cspace().alloc(None),
            'dev_vaddr': vaddr,
            'ep_read': self.ep_read,
            'ep_write': self.ep_write,
            'clients': self.signals,
            'irq_thread': self.irq_thread_ep,
            'irq_nfn': self.cspace().alloc(irq_nfn, read=True),
            'irq_handler': irq_handler,
            }

        return config
