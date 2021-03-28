from capdl import ObjectType
from icedl.components.elf import ElfComponent

class Idle(ElfComponent):

    def arg(self):
        path_base = self.composition.out_dir / '{}_arg'.format(self.name)
        path_bin = path_base.with_suffix('.bin')
        with path_bin.open('wb') as f_bin:
            pass
        self.composition.register_file(path_bin.name, path_bin)
        return path_bin.name
