from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icedl.common import Composition as BaseComposition, FaultHandler
from icedl.realm.components.vm import RealmVM

NUM_NODES = 1

class Composition(BaseComposition):

    @classmethod
    def run(cls):
        cls.from_env().complete()

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.compose()

    def compose(self):
        self.fault_handler = self.component(FaultHandler, 'fault_handler', affinity=1, prio=250)
        # self.realm_vm = self.component(RealmVM, name='realm_vm', vmm_name='realm_vmm')

    def num_nodes(self):
        return NUM_NODES
