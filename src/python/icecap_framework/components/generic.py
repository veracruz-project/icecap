from icecap_framework.components.elf import ElfComponent

class GenericElfComponent(ElfComponent):

    def serialize_arg(self):
        return 'cat'
