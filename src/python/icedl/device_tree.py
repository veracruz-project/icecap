from pyfdt.pyfdt import FdtBlobParse, FdtNode, FdtPropertyStrings, FdtPropertyWords, FdtPropertyBytes

class DeviceTree:

    @classmethod
    def from_path(cls, path):
        with open(path, 'rb') as f:
            return cls.parse(f)

    @classmethod
    def parse(cls, f):
        return cls(FdtBlobParse(f).to_fdt())

    def __init__(self, dt):
        self.dt = dt

    def set_chosen(self, bootargs=None, initrd=None, stdout_path=None, kaslr_seed=None):
        chosen = FdtNode('chosen')
        if bootargs is not None:
            chosen.append(FdtPropertyStrings('bootargs', [' '.join(bootargs)]))
        if initrd is not None:
            chosen.append(FdtPropertyWords('linux,initrd-start', [initrd[0]]))
            chosen.append(FdtPropertyWords('linux,initrd-end', [initrd[1]]))
        if stdout_path is not None:
            chosen.append(FdtPropertyStrings('stdout-path', [stdout_path]))
        if kaslr_seed is not None:
            chosen.append(FdtPropertyWords('kaslr-seed', [kaslr_seed]))
        self.dt.rootnode.append(chosen)

    def add_device(self, device):
        self.dt.rootnode.append(device)

    def render(self):
        return self.dt.to_dtb()

    def show(self):
        print(self.dt.to_dts())
