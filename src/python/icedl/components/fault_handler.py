from capdl import ObjectType
from icedl.components.elf import ElfComponent

class FaultHandler(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.primary_thread.tcb.affinity = 1
        self.ep = self.alloc(ObjectType.seL4_EndpointObject, name='{}_ep'.format(self.name))
        self.ep_slot = self.cspace().alloc(self.ep, read=True)
        self.cur_badge = 16
        self.client_threads = {}

    def handle(self, thread):
        badge = self.cur_badge
        self.cur_badge += 1
        slot = thread.component.cspace().alloc(self.ep, name='fault_handler', badge=badge, write=True, grant=True)
        thread.tcb.fault_ep_slot = slot
        self.client_threads[str(badge)] = {
            'name': thread.full_name(),
            'tcb': self.cspace().alloc(thread.tcb),
            }

    def serialize_arg(self):
        return 'serialize-fault-handler-config'

    def arg_json(self):
        return {
            'ep': self.ep_slot,
            'threads': self.client_threads,
            }
