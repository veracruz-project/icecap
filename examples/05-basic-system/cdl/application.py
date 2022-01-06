from capdl import ObjectType
from icecap_framework import GenericElfComponent

BADGE_TIMEOUT = 1 << 1
BADGE_SERIAL_SERVER_RING_BUFFER = 1 << 2

class Application(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        event_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='event_nfn')

        timer_server_ep_cap = self.composition.timer_server.register_client(self, event_nfn, BADGE_TIMEOUT)

        serial_server_rb_objs, serial_server_kick_nfn_cap = self.composition.serial_server.register_client(self, event_nfn, BADGE_SERIAL_SERVER_RING_BUFFER)

        self._arg = {
            'event_nfn': self.cspace().alloc(event_nfn, read=True),
            'timer_server_ep': timer_server_ep_cap,
            'serial_server_ring_buffer': {
                'ring_buffer': self.map_ring_buffer(serial_server_rb_objs),
                'kicks': {
                    'read': serial_server_kick_nfn_cap,
                    'write': serial_server_kick_nfn_cap,
                    },
                },
            'badges': {
                'timeout': BADGE_TIMEOUT,
                'serial_server_ring_buffer': BADGE_SERIAL_SERVER_RING_BUFFER,
                },
            }

    def arg_json(self):
        return self._arg
