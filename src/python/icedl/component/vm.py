from pathlib import Path
import json
import subprocess

from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icedl.component.base import BaseComponent
from icedl.component.elf import ElfComponent
from icedl.utils import *

REAL_VIRTUAL_TIMER_IRQ = 27
VIRTUAL_TIMER_IRQ = 27

class Addrs:

    def __init__(self, plat):
        if plat == 'virt':
            self.ram_base    = 0xf0000000
            self.ram_size    = 0x10000000
            self.kernel_addr = 0xf0080000
            self.dtb_addr    = 0xf2000000
            self.initrd_addr = 0xf8000000
        elif plat == 'rpi4':
            self.ram_base    = 0x10000000
            self.ram_size    = 0x10000000
            self.kernel_addr = 0x10080000
            self.dtb_addr    = 0x12000000
            self.initrd_addr = 0x18000000

class VM(BaseComponent):

    def align(self, size):
        self.cur_vaddr = ((self.cur_vaddr - 1) | (size - 1)) + 1

    def skip(self, n):
        self.cur_vaddr += n

    def next_virq(self):
        virq = self.cur_virq
        self.cur_virq += 1
        return virq

    def map_passthru_devices(self):
        pass

    def get_passthru_irqs(self):
        yield from []

    def map_phys(self):
        return False

    def __init__(self, composition, name, vmm_name, affinity, gic_vcpu_frame):
        super().__init__(composition, name)
        self.kernel_fname = self.composition.register_file('{}_kernel.img'.format(self.name), self.config()['kernel'])
        self.initrd_fname = self.composition.register_file('{}_initrd.img'.format(self.name), self.config()['initrd'])
        self.devices = []

        self.addrs = Addrs(self.composition.plat)

        self.cur_vaddr = vaddr_at_block(3, 0, 0)
        if self.composition.plat == 'virt':
            self.cur_virq = 90
        elif self.composition.plat == 'rpi4':
            self.cur_virq = 130

        self.map_passthru_devices()

        # TODO these only apply for host. guest is platform-ind
        if self.composition.plat == 'virt':
            GIC_PADDR = 0x8000000
            GIC_DIST_PADDR = GIC_PADDR + 0x00000
            GIC_CPU_PADDR = GIC_PADDR + 0x10000
            GIC_VCPU_PADDR = GIC_PADDR + 0x40000
        elif self.composition.plat == 'rpi4':
            GIC_PADDR = 0xff841000
            GIC_DIST_PADDR = GIC_PADDR + 0x0000
            GIC_CPU_PADDR = GIC_PADDR + 0x1000
            GIC_VCPU_PADDR = GIC_PADDR + 0x5000
        # HACK
        self.GIC_DIST_PADDR = GIC_DIST_PADDR

        self.gic_dist_frame = self.alloc(ObjectType.seL4_FrameObject, '{}_gic_dist_frame'.format(self.name), size=PAGE_SIZE)
        self.addr_space().add_hack_page(GIC_DIST_PADDR, PAGE_SIZE, Cap(self.gic_dist_frame, read=True, write=False, cached=False))
        self.addr_space().add_hack_page(GIC_CPU_PADDR, PAGE_SIZE, Cap(gic_vcpu_frame, read=True, write=True, cached=False))

        ipc_buffer_frame = self.alloc(ObjectType.seL4_FrameObject, '{}_ipc_buffer_frame'.format(self.name), size=PAGE_SIZE)
        ipc_buffer_addr = vaddr_at_page(4, 0, 0, 0)
        ipc_buffer_cap = Cap(ipc_buffer_frame, read=True, write=True)
        self.addr_space().add_hack_page(ipc_buffer_addr, PAGE_SIZE, ipc_buffer_cap)

        self.tcb = self.alloc(ObjectType.seL4_TCBObject, name='{}_tcb'.format(self.name))
        self.tcb.resume = False

        SPSR_EL1 = 0x5

        self.tcb.ip = self.addrs.kernel_addr
        self.tcb.sp = 0
        self.tcb.addr = ipc_buffer_addr
        self.tcb.prio = 99
        self.tcb.max_prio = 0
        self.tcb.affinity = affinity
        self.tcb.spsr = SPSR_EL1;

        self.tcb.init.append(self.addrs.dtb_addr)

        self.tcb['cspace'] = self.cnode_cap
        self.tcb['vspace'] = Cap(self.pd())
        self.tcb['ipc_buffer_slot'] = ipc_buffer_cap

        self.vcpu = self.alloc(ObjectType.seL4_VCPU, name='{}_vcpu'.format(self.name))
        self.tcb['bound_vcpu'] = Cap(self.vcpu)

        self.vmm = self.composition.component(VMM, vmm_name, gic_vcpu_frame=gic_vcpu_frame, vm=self)

    def device_tree(self):
        # TODO
        mod = {
            'chosen': {
                'bootargs': self.config()['bootargs'],
                'initrd': {
                    'start': self.addrs.initrd_addr,
                    'end': self.addrs.initrd_addr + self.composition.get_file(self.initrd_fname).stat().st_size,
                    },
                },
            'devices': self.devices,
            'num_cpus': 1, # TODO
            }

        mod_path = self.composition.out_dir / '{}_device_tree_mod.json'.format(self.name)
        with mod_path.open('w') as f:
            json.dump(mod, f, indent=4)

        dtb_path_in = Path(self.config()['dtb'])
        dtb_path_out = self.composition.out_dir / '{}.dtb'.format(self.name)
        with dtb_path_in.open('r') as f_in:
            with dtb_path_out.open('wb') as f_out:
                subprocess.check_call(['append-icecap-devices', mod_path], stdin=f_in, stdout=f_out)

        self.dtb_fname = self.composition.register_file(dtb_path_out.name, dtb_path_out)

    # TODO connect ring buffers

    def pre_finalize(self):
        self.device_tree()
        self.map_ram(self.addrs.ram_base, self.addrs.ram_size, [
            (self.addrs.kernel_addr, self.composition.get_file(self.kernel_fname).stat().st_size, self.kernel_fname),
            (self.addrs.initrd_addr, self.composition.get_file(self.initrd_fname).stat().st_size, self.initrd_fname),
            (self.addrs.dtb_addr, self.composition.get_file(self.dtb_fname).stat().st_size, self.dtb_fname),
            ])

    def finalize(self):
        pages = PageCollection(self.name, arch=self.composition.arch.capdl_name(), infer_asid=False, vspace_root=self.addr_space().vspace_root)
        for (vaddr, (size, cap, fill)) in self.addr_space().get_hack_pages_and_clear().items():
            pages.add_page(vaddr, read=cap.read, write=cap.write, size=size, elffill=fill)
            self.addr_space().add_region_with_caps(vaddr, [size], [cap])
        spec = pages.get_spec(self.addr_space().get_regions_and_clear())
        self.obj_space().merge(spec, label=self.key)
        super().finalize()

    def map_ram(self, ram_start, ram_size, images):
        assert ram_start % BLOCK_SIZE == 0
        assert ram_size % BLOCK_SIZE == 0
        ram_end = ram_start + ram_size
        for addr in range(ram_start, ram_end, BLOCK_SIZE):
            fill = []
            for start, size, fname in images:
                end = start + size
                if start < addr + BLOCK_SIZE and addr < end:
                    frame_offset = max(0, start-addr)
                    fill = mk_fill(
                        frame_offset=frame_offset,
                        length=min(BLOCK_SIZE-frame_offset, end-addr),
                        fname=fname,
                        file_offset=max(0, addr-start),
                        )
                    break
            if self.map_phys():
                self.map_block(vaddr=addr, paddr=addr, fill=fill, read=True, write=True, execute=True)
            else:
                self.map_block(vaddr=addr, fill=fill, read=True, write=True, execute=True)

    def map_ring_buffer(self, objs):
        read = objs.read
        write = objs.write

        rx_badge = 1;
        tx_badge = 2;

        return {
            'read': {
                'signal': self.cspace().alloc(write.nfn, write=True, badge=rx_badge),
                'size': read.size,
                'ctrl': self.map_region(read.ctrl, read=True),
                'data': self.map_region(read.data, read=True),
                },
            'write': {
                'signal': self.cspace().alloc(write.nfn, write=True, badge=tx_badge),
                'size': write.size,
                'ctrl': self.map_region(write.ctrl, read=True, write=True),
                'data': self.map_region(write.data, read=True, write=True),
                },
            }

    def map_region(self, region, **perms):
        self.skip(4096)
        self.align(1 << region[0][1]) # HACK
        start = self.cur_vaddr
        vaddr = start
        for frame, size_bits in region:
            assert vaddr & ((1 << size_bits) - 1) == 0
            cap = Cap(frame, **perms)
            self.addr_space().add_hack_page(vaddr, 1 << size_bits, cap)
            vaddr += 1 << size_bits
        self.cur_vaddr = vaddr
        return {
            'start': start,
            'end': vaddr,
            }

    def map_con(self, objs):
        rx_badge = 1;
        tx_badge = 2;

        irq = self.next_virq()

        self.vmm._arg['virtual_irqs'].append({
            'nfn': self.vmm.cspace().alloc(objs.read.nfn, read=True),
            'thread': self.vmm.secondary_thread('virq_{}'.format(irq)).endpoint,
            'irqs': [irq, irq],
            })

        self.devices.append({
            'Con': {
                'ring_buffer': self.map_ring_buffer(objs),
                'irq': irq - 32,
                },
            })

    def map_net(self, objs):
        rx_badge = 1;
        tx_badge = 2;

        rx_irq = self.next_virq()
        tx_irq = self.next_virq()

        self.vmm._arg['virtual_irqs'].append({
            'nfn': self.vmm.cspace().alloc(objs.read.nfn, read=True),
            'thread': self.vmm.secondary_thread('virq_{}_{}'.format(rx_irq, tx_irq)).endpoint,
            'irqs': [rx_irq, tx_irq],
            })

        self.devices.append({
            'Net': {
                'ring_buffer': self.map_ring_buffer(objs),
                'mtu': 65536,
                'mac_address': [0, 1] + list((abs(hash(self.name)) & ((1 << (8 * 4)) - 1)).to_bytes(4, 'little')), # HACK
                'irq_read': rx_irq - 32,
                'irq_write': tx_irq - 32,
                },
            })

    def map_rb(self, objs, id, name):
        rx_badge = 1;
        tx_badge = 2;

        irq = self.next_virq()

        self.vmm._arg['virtual_irqs'].append({
            'nfn': self.vmm.cspace().alloc(objs.read.nfn, read=True),
            'thread': self.vmm.secondary_thread('virq_{}'.format(irq)).endpoint,
            'irqs': [irq, irq],
            })

        self.devices.append({
            'Raw': {
                'ring_buffer': self.map_ring_buffer(objs),
                'irq': irq - 32,
                'name': name,
                'id': id,
                },
            })


class VMM(ElfComponent):

    def __init__(self, *args, gic_vcpu_frame, vm, **kwargs):
        super().__init__(*args, **kwargs)
        self.heap_size = 0x400000
        self.primary_thread.tcb.prio = 101
        self.primary_thread.tcb.affinity = vm.tcb.affinity
        self.gic_vcpu_frame = gic_vcpu_frame
        self.vm = vm

        self.ep = self.alloc(ObjectType.seL4_EndpointObject, name='vmm_event_ep')

        self.vm.tcb.fault_ep_slot = self.vm.cspace().alloc(self.ep, badge=1, write=True, grant=True)

        gic_dist_vaddr = vaddr_at_block(8, 510, 0)
        self.addr_space().add_hack_page(gic_dist_vaddr, PAGE_SIZE, Cap(self.vm.gic_dist_frame, read=True, write=True, cached=False))

        self._arg = {
            'cnode': self.cspace().alloc(self.cspace().cnode, write=True),

            'timer_thread': self.secondary_thread('timer').endpoint,

            'gic_dist_vaddr': gic_dist_vaddr,
            'gic_dist_paddr': self.vm.GIC_DIST_PADDR,

            'real_virtual_timer_irq': REAL_VIRTUAL_TIMER_IRQ,
            'virtual_timer_irq': VIRTUAL_TIMER_IRQ,
            'virtual_irqs': [],
            'passthru_irqs': [],

            'ep_write': self.cspace().alloc(self.ep, write=True, badge=0),
            'ep_read': self.cspace().alloc(self.ep, read=True),
            'reply_ep': self.cspace().alloc(None),
            'tcb': self.cspace().alloc(self.vm.tcb, read=True, write=True, grant=True, grantreply=True),
            'vcpu': self.cspace().alloc(self.vm.vcpu, read=True, write=True, grant=True, grantreply=True),
            }

        passthru_irqs = self._arg['passthru_irqs']

        for i_group, group in enumerate(groups_of(48, self.vm.get_passthru_irqs())):
            nfn = self.alloc(ObjectType.seL4_NotificationObject, 'vmm_irq_group_{}_nfn'.format(i_group))

            @as_list
            def x():
                for i, (irq, trigger) in enumerate(group):
                    badge = 1 << i
                    cap = Cap(nfn, badge=badge, write=True, grant=True, grantreply=True)
                    handler = self.cspace().alloc(
                        self.alloc(ObjectType.seL4_IRQHandler, name='irq_{}'.format(irq), number=irq, trigger=trigger, notification=cap)
                        )
                    yield {
                        'irq': irq,
                        'handler': handler,
                        }

            passthru_irqs.append({
                'nfn': self.cspace().alloc(nfn, read=True),
                'thread': self.secondary_thread('irq_group_{}'.format(i_group)).endpoint,
                'irqs': x(),
                })

    def serialize_arg(self):
        return 'serialize-vmm-config'

    def arg_json(self):
        self._arg['timer'] = self.connections['timer']['TimerClient']
        self._arg['con'] = self.connections['con']['MappedRingBuffer']
        return self._arg


class HostVM(VM):

    def map_phys(self):
        return True

    def get_passthru_irqs(self):
        if self.composition.plat == 'virt':
            edge_triggered = frozenset()
            no = frozenset()
            whole = [78, 79]
        elif self.composition.plat == 'rpi4':
            edge_triggered = frozenset()
            no = frozenset([96, 97, 98, 99, 125])
            whole = range(32, 256)
        for irq in whole:
            if irq not in no:
                if irq in edge_triggered:
                    trigger = ARMIRQMode.seL4_ARM_IRQ_EDGE
                else:
                    trigger = ARMIRQMode.seL4_ARM_IRQ_LEVEL
                yield irq, trigger

    def map_passthru_devices(self):
        def dev():
            # TODO extract from device tree? map larger ranges? 1GiB?

            if self.composition.plat == 'virt':
                yield 0xa003000, 0xa004000

            elif self.composition.plat == 'rpi4':
                start, end = 0xfd000000, 0xff000000
                timer = 0xfe003000
                uart = 0xfe215000

                yield start, timer
                yield timer + PAGE_SIZE, uart
                yield uart + PAGE_SIZE, end

                yield 0x600000000, 0x604000000

        for start, end in dev():
            assert start % PAGE_SIZE == 0
            assert end % PAGE_SIZE == 0
            while start < end:
                if start % BLOCK_SIZE == 0 and start + BLOCK_SIZE < end:
                    size = BLOCK_SIZE
                else:
                    size = PAGE_SIZE
                paddr = start
                self.map_with_size(size, vaddr=paddr, paddr=paddr, read=True, write=True, cached=False)
                start += size
