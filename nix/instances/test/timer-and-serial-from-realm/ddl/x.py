from capdl import ObjectType, Cap
from icedl import *
from icedl.utils import as_list

class Test(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.primary_thread.tcb.prio = 1
        objs = self.composition.extern_ring_buffer('con', size=4096)
        self._arg = {
            'timer': {
                'ep_write': self.extern_cap(ObjectType.seL4_EndpointObject, 'timer_ep_write', write=True, grantreply=True),
                'wait': self.extern_cap(ObjectType.seL4_NotificationObject, 'timer_wait', read=True),
                },
            'con': self.map_ring_buffer(objs),
            'ctrl_ep_write': self.extern_cap(ObjectType.seL4_EndpointObject, 'ctrl_ep_write', write=True, grantreply=True),
            }

    def arg_json(self):
        return self._arg

composition = start()

test = composition.component(Test, 'test')

composition.complete()
