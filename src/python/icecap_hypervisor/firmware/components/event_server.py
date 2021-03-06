from pathlib import Path
from capdl import ObjectType, Cap, PageCollection, ARMIRQMode
from icecap_framework import ElfComponent
from icecap_framework.utils import BLOCK_SIZE, PAGE_SIZE, groups_of

BADGE_TYPE_SHIFT = 11
BADGE_TYPE_CLIENT = 3 << BADGE_TYPE_SHIFT
BADGE_TYPE_CLIENT_OUT = 2 << BADGE_TYPE_SHIFT
BADGE_TYPE_CONTROL = 1 << BADGE_TYPE_SHIFT

class EventServer(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, affinity=0, **kwargs)

        self.endpoints = [
            self.alloc(ObjectType.seL4_EndpointObject, 'ep_{}'.format(i))
            for i in range(self.composition.num_nodes())
            ]

        secondary_threads = []
        for i in range(self.composition.num_nodes()):
            if i != 0:
                thread = self.secondary_thread('secondary_thread_{}'.format(i), affinity=i, prio=self.primary_thread.tcb.prio)
                secondary_threads.append(thread.endpoint)
            else:
                thread = self.primary_thread

        host_badge = 1
        resource_server_badge = 2
        self.export_host_badge = BADGE_TYPE_CONTROL | host_badge
        self.export_resource_server_badge = BADGE_TYPE_CONTROL | resource_server_badge

        irqs, irq_threads = self.collect_irqs()

        self.cur_client_badge = 1

        self._arg = {
            'lock': self.cspace().alloc(self.alloc(ObjectType.seL4_NotificationObject, name='lock'), read=True, write=True),

            'endpoints': [ self.cspace().alloc(ep, read=True) for ep in self.endpoints ],
            'secondary_threads': secondary_threads,

            'badges': {
                'client_badges': [],
                'resource_server_badge': resource_server_badge,
                'host_badge': host_badge,
                },

            'host_notifications': None,
            'realm_notifications': [],
            'resource_server_subscriptions': [],

            'irqs': irqs,
            'irq_threads': irq_threads,
            }

    def serialize_arg(self):
        return ('hypervisor-serialize-component-config', 'event-server')

    def arg_json(self):
        return self._arg

    def register_host_notifications(self, nfns_and_badges):
        nfns = []
        for (nfn, bitfield) in nfns_and_badges:
            nfns.append({
                'nfn': [ self.cspace().alloc(nfn, badge=1<<i, write=True) for i in range(0, 32) ],
                'bitfield': self.map_region([(bitfield, 12)], read=True, write=True),
                })
        self._arg['host_notifications'] = nfns

    def register_realm_notifications(self, nfns_and_badges):
        nfns = []
        for (nfn, bitfield) in nfns_and_badges:
            nfns.append({
                'nfn': [ self.cspace().alloc(nfn, badge=1<<i, write=True) for i in range(0, 32) ],
                'bitfield': self.map_region([(bitfield, 12)], read=True, write=True),
                })
        self._arg['realm_notifications'].append(nfns)

    def register_client(self, client, client_out, id):
        client_badges = self._arg['badges']['client_badges']
        badge = BADGE_TYPE_CLIENT | len(client_badges)
        badge_out = BADGE_TYPE_CLIENT_OUT | len(client_badges)
        client_badges.append(id)
        return [
            (
                client.cspace().alloc(ep, badge=badge, write=True, grantreply=True),
                None if client_out is None else client_out.cspace().alloc(ep, badge=badge_out, write=True, grantreply=True)
            )
            for ep in self.endpoints
            ]

    def register_control_host(self, host):
        return [
            host.cspace().alloc(ep, badge=self.export_host_badge, write=True, grantreply=True)
            for ep in self.endpoints
            ]

    def register_control_resource_server(self, resource_server):
        return [
            resource_server.cspace().alloc(ep, badge=self.export_resource_server_badge, write=True, grantreply=True)
            for ep in self.endpoints
            ]

    def register_resource_server_subscription(self, nfn, badge):
        self._arg['resource_server_subscriptions'].append(self.cspace().alloc(nfn, badge=badge, write=True))

    def owned_irqs(self):
        if self.composition.plat == 'virt':
            edge_triggered = frozenset(range(48, 80))
            no = frozenset()
            whole = edge_triggered
        elif self.composition.plat == 'rpi4':
            edge_triggered = frozenset()
            no = [96, 97, 98, 99, 125]
            no.extend([48, 49, 50, 51]) # /arm-pmu
            no = frozenset(no)
            whole = range(32, 216) # TODO is this correct?
        for irq in whole:
            if irq not in no:
                if irq in edge_triggered:
                    trigger = ARMIRQMode.seL4_ARM_IRQ_EDGE
                else:
                    trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL
                yield irq, trigger

    def collect_irqs(self):
        irqs = {}
        irq_threads = []
        for i_group, group in enumerate(groups_of(48, self.owned_irqs())):
            nfns = [
                self.alloc(ObjectType.seL4_NotificationObject, 'irq_group_{}_nfn_for_core_{}'.format(i_group, i_core))
                for i_core in range(self.composition.num_nodes())
                ]

            bits = []
            for i_irq, (irq, trigger) in enumerate(group):
                bits.append(irq)
                badge = 1 << i_irq
                caps = [
                    self.cspace().alloc(nfns[i_core], badge=badge, read=True)
                    for i_core in range(self.composition.num_nodes())
                    ]
                initial_cap = Cap(nfns[0], badge=badge, write=True) # HACK
                handler = self.cspace().alloc(
                    self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}'.format(irq), number=irq, trigger=trigger, notification=initial_cap)
                    )
                irqs[irq] = (handler, caps)

            for i_core in range(self.composition.num_nodes()):
                irq_threads.append({
                    'thread': self.secondary_thread('irq_group_{}_thread_for_core_{}'.format(i_group, i_core), affinity=i_core).endpoint,
                    'notification': caps[i_core],
                    'irqs': bits,
                    })

        return irqs, irq_threads
