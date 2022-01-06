from capdl import ObjectType
from icecap_framework import BaseComposition, ElfComponent

class ExampleComponent(ElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        secondary_thread = self.secondary_thread('secondary_thread')
        lock_nfn = self.alloc(ObjectType.seL4_NotificationObject, name='lock_nfn')

        ep = self.alloc(ObjectType.seL4_EndpointObject, name='ep')

        self._arg = {
            'lock_nfn': self.cspace().alloc(lock_nfn, read=True, write=True),
            'primary_thread_ep_cap': self.cspace().alloc(ep, write=True, grantreply=True),
            'secondary_thread_ep_cap': self.cspace().alloc(ep, read=True),
            'secondary_thread': secondary_thread.endpoint,
            'foo': [1, 2, 3],
        }

    def arg_json(self):
        return self._arg

    def serialize_arg(self):
        return [self.composition.config['tools']['serialize-example-component-config']]

class Composition(BaseComposition):

    def compose(self):
        self.component(ExampleComponent, 'example_component')

Composition.from_env().run()
