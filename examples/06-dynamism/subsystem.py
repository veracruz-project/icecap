from capdl import ObjectType
from icecap_framework import BaseComposition, GenericElfComponent

class Subcomponent(GenericElfComponent):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, prio=1, **kwargs)

        nfn = self.composition.alloc(ObjectType.seL4_NotificationObject, name='extern_nfn')

        self._arg = {
            'nfn': self.cspace().alloc(nfn, write=True),
            }

    def arg_json(self):
        return self._arg

class Composition(BaseComposition):

    def compose(self):
        self.component(Subcomponent, 'subcomponent')

Composition.from_env().run()
