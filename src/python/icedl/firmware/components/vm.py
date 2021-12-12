from pathlib import Path
import json
import subprocess
from collections import namedtuple

from capdl import ObjectType, Cap, PageCollection, ARMIRQMode

from icedl.common import BaseComponent
from icedl.common import ElfComponent
from icedl.utils import *

REAL_VIRTUAL_TIMER_IRQ = 27
VIRTUAL_TIMER_IRQ = 27

HACK_PRIO = 101

BADGE_VM = 0

class Addrs:

    def __init__(self, plat, is_host=False):
        if is_host:
            if plat == 'virt':
                self.ram_base    = 0x80000000
                self.ram_size    = 0x10000000
                self.kernel_addr = 0x80080000
                self.dtb_addr    = 0x82000000
                self.initrd_addr = 0x88000000
            elif plat == 'rpi4':
                self.ram_base    = 0x10000000
                self.ram_size    = 0x10000000
                self.kernel_addr = 0x10080000
                self.dtb_addr    = 0x18f00000 # TODO find out why u-boot was clobbering fdt in lower memory
                self.initrd_addr = 0x19000000
        else:
            self.ram_base    = 0x80000000
            self.ram_size    = 0x10000000
            self.kernel_addr = 0x80080000
            self.dtb_addr    = 0x82000000
            self.initrd_addr = 0x88000000

        if plat == 'virt':
            self.virq_0 = 90
            self.gic_paddr = 0x8000000
            self.gic_dist_paddr = self.gic_paddr + 0x00000
            self.gic_cpu_paddr = self.gic_paddr + 0x10000
            self.gic_vcpu_paddr = self.gic_paddr + 0x40000
        elif plat == 'rpi4':
            self.virq_0 = 130
            self.gic_paddr = 0xff841000
            self.gic_dist_paddr = self.gic_paddr + 0x0000
            self.gic_cpu_paddr = self.gic_paddr + 0x1000
            self.gic_vcpu_paddr = self.gic_paddr + 0x5000

VMNode = namedtuple('VMNode', 'tcb vcpu affinity')

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

    def map_phys(self):
        return False

    def get_addrs(self):
        return Addrs(self.composition.plat, is_host=False)

    def set_chosen_default(self):
        return True

    def __init__(self, composition, name, vmm_name, is_host=False):
        super().__init__(composition, name)
        self.kernel_fname = self.composition.register_file('{}_kernel.img'.format(self.name), self.config()['kernel'])
        if 'initrd' in self.config():
            self.initrd_fname = self.composition.register_file('{}_initrd.img'.format(self.name), self.config()['initrd'])

        # HACK cnodes have minimum size
        self.cspace().alloc(None)
        self.cspace().alloc(None)

        self.is_host = is_host

        self.devices = []
        self.nodes = []

        self.addrs = self.get_addrs()

        self.cur_vaddr = vaddr_at_block(3, 0, 0)
        self.cur_virq = self.addrs.virq_0
        self.cur_channel_id = 1

        self.map_passthru_devices()

        self.addr_space().add_hack_page(self.addrs.gic_cpu_paddr, PAGE_SIZE, Cap(self.composition.gic_vcpu_frame(), read=True, write=True, cached=False))

        SPSR_EL1 = 0x5

        # Establish IPC buffers, TCBs, and vCPUs for each node in the list of affinities.
        for node_index in range(self.composition.num_nodes()):
            affinity = node_index

            ipc_buffer_frame = self.alloc(ObjectType.seL4_FrameObject, '{}_ipc_buffer_frame_{}'.format(self.name, node_index), size=PAGE_SIZE)
            ipc_buffer_addr = vaddr_at_page(4, 0, 0, node_index)
            ipc_buffer_cap = Cap(ipc_buffer_frame, read=True, write=True)
            self.addr_space().add_hack_page(ipc_buffer_addr, PAGE_SIZE, ipc_buffer_cap)

            # Create a new seL4 VCPU object, and append it to the list of VPUs.
            # This will eventually be bound to the TCB. 'node_index' should match the
            # index of the new VCPU object in self.vcpu and the associated TCB
            # in self.tcb.
            vcpu = self.alloc(ObjectType.seL4_VCPU, name='{}_vcpu_{}'.format(self.name, node_index))

            # Create a new seL4 TCB object and append it to the list of TCBs,
            # then populate the TCB. 'node_index' should match the index of the new
            # TCB object in self.tcb.
            tcb = self.alloc(ObjectType.seL4_TCBObject, name='{}_tcb_{}'.format(self.name, node_index))
            tcb.resume = False

            tcb.ip = self.addrs.kernel_addr
            tcb.sp = 0
            tcb.addr = ipc_buffer_addr
            tcb.prio = 99
            tcb.max_prio = 0
            tcb.affinity = affinity
            tcb.spsr = SPSR_EL1

            tcb.init.append(self.addrs.dtb_addr)

            tcb['cspace'] = self.cnode_cap
            tcb['vspace'] = Cap(self.pd())
            tcb['ipc_buffer_slot'] = ipc_buffer_cap

            tcb['bound_vcpu'] = Cap(vcpu)

            self.nodes.append(VMNode(tcb=tcb, vcpu=vcpu, affinity=affinity))

        self.vmm = self.composition.component(VMM, vmm_name, vm=self, is_host=is_host)

        if self.is_host:
            self.devices.append({
                'ResourceServer': {
                    'bulk_region': self.map_region(self.composition.resource_server.host_bulk_region_frames, write=True),
                    'endpoints': self.resource_server_endpoints,
                    }
                })

    def device_tree(self):
        # TODO
        mod = {
            'devices': self.devices,
            'num_cpus': len(self.nodes),
            }

        if self.config().get('set_chosen', self.set_chosen_default()):
            mod['chosen'] = {}
            if 'bootargs' in self.config():
                mod['chosen']['bootargs'] = self.config()['bootargs']
            if 'initrd' in self.config():
                mod['chosen']['initrd'] = {
                    'start': self.addrs.initrd_addr,
                    'end': self.addrs.initrd_addr + self.composition.get_file(self.initrd_fname).stat().st_size,
                    }

        mod_path = self.composition.out_dir / '{}_device_tree_mod.json'.format(self.name)
        with mod_path.open('w') as f:
            json.dump(mod, f, indent=4)

        dtb_path_in = Path(self.config()['dtb'])
        dtb_path_out = self.composition.out_dir / '{}.dtb'.format(self.name)
        with dtb_path_in.open('r') as f_in:
            with dtb_path_out.open('wb') as f_out:
                subprocess.check_call(['icecap-append-devices', mod_path], stdin=f_in, stdout=f_out)

        self.dtb_fname = self.composition.register_file(dtb_path_out.name, dtb_path_out)

    def pre_finalize(self):
        self.device_tree()
        mappings = []
        mappings.append((self.addrs.kernel_addr, self.composition.get_file(self.kernel_fname).stat().st_size, self.kernel_fname))
        if 'initrd' in self.config():
            mappings.append((self.addrs.initrd_addr, self.composition.get_file(self.initrd_fname).stat().st_size, self.initrd_fname))
        mappings.append((self.addrs.dtb_addr, self.composition.get_file(self.dtb_fname).stat().st_size, self.dtb_fname))
        self.map_ram(self.addrs.ram_base, self.addrs.ram_size, mappings)

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
                self.map_block(vaddr=addr, paddr=addr, device=True, fill=fill, read=True, write=True, execute=True)
            else:
                self.map_block(vaddr=addr, fill=fill, device=False, read=True, write=True, execute=True)

    def map_ring_buffer(self, objs):
        read = objs.read
        write = objs.write

        rx_badge = 1
        tx_badge = 2

        return {
            'read': {
                'size': read.size,
                'ctrl': self.map_region(read.ctrl, read=True, write=True),
                'data': self.map_region(read.data, read=True),
                },
            'write': {
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

    def map_con(self, objs, kick, event):
        irq = self.next_virq()
        self.vmm._arg['spi_map'][irq] = ({ 'RingBuffer': event }, 0, False)

        ring_buffer = self.map_ring_buffer(objs)
        ring_buffer['kick'] = kick

        self.devices.append({
            'Con': {
                'ring_buffer': ring_buffer,
                'irq': irq - 32,
                },
            })

    def map_net(self, objs, kick, event):
        irq = self.next_virq()
        self.vmm._arg['spi_map'][irq] = ({ 'RingBuffer': event }, 0, False)

        ring_buffer = self.map_ring_buffer(objs)
        ring_buffer['kick'] = kick

        self.devices.append({
            'Net': {
                'ring_buffer': ring_buffer,
                'mtu': 65536,
                'mac_address': [0, 1] + list((abs(hash(self.name)) & ((1 << (8 * 4)) - 1)).to_bytes(4, 'little')), # HACK
                'irq': irq - 32,
                },
            })

    def map_channel(self, name, objs, kick, event):
        irq = self.next_virq()
        self.vmm._arg['spi_map'][irq] = ({ 'RingBuffer': event }, 0, False)

        ring_buffer = self.map_ring_buffer(objs)
        ring_buffer['kick'] = kick

        id = self.cur_channel_id
        self.cur_channel_id += 1

        self.devices.append({
            'Channel': {
                'ring_buffer': ring_buffer,
                'irq': irq - 32,
                'name': name,
                'id': id,
                },
            })


class VMM(ElfComponent):

    def __init__(self, *args, vm, is_host, **kwargs):
        super().__init__(*args, affinity=0, prio=HACK_PRIO, **kwargs)
        self.heap_size = 0x400000
        self.vm = vm
        self.is_host = is_host

        # The primary vmm thread will be associated with the 0th VM thread
        # managed by vm.tcb[0].
        self.primary_thread.tcb.prio = 101 # TODO

        nodes = []
        self.event_server_targets = []

        # Perform node-specific assignments:
        # each idx of self.vm.tcb corresponds to one node with a vm and a vmm thread.
        for node_index, node in enumerate(self.vm.nodes):
            # Create a new seL4 endpoint object, and append it to the list of
            # endpoints. 'idx' should match the index of the new endpoint object in
            # self.ep and the associated TCB in self.vm.tcb.
            ep = self.alloc(ObjectType.seL4_EndpointObject, name='vmm_event_ep_{}'.format(node_index))
            node.tcb.fault_ep_slot = self.vm.cspace().alloc(ep, badge=BADGE_VM, write=True, grant=True)

            if self.is_host:
                nfn = self.alloc(ObjectType.seL4_NotificationObject, name='vmm_event_nfn_{}'.format(node_index))
            else:
                nfn = self.composition.extern(ObjectType.seL4_NotificationObject, 'realm_{}_nfn_for_core_{}'.format(self.composition.realm_id(), node_index))

            if node_index != 0:
                full_thread = self.secondary_thread(name='node_{}'.format(node_index), affinity=node.affinity, prio=self.primary_thread.tcb.prio)
                thread = full_thread.endpoint
                start_ep = self.alloc(ObjectType.seL4_EndpointObject, name='vmm_start_ep_{}'.format(node_index))
                start_ep_read_write = self.cspace().alloc(start_ep, read=True, write=True)
            else:
                full_thread = self.primary_thread
                thread = 0
                start_ep_read_write = 0

            full_thread.tcb['bound_notification'] = Cap(nfn, read=True)
            if self.is_host:
                bitfield = self.alloc(ObjectType.seL4_FrameObject, name='event_bitfield_for_core_{}'.format(node_index), size_bits=12)
            else:
                bitfield = self.composition.extern(ObjectType.seL4_FrameObject, 'realm_{}_event_bitfield_for_core_{}'.format(self.composition.realm_id(), node_index))
            self.event_server_targets.append((nfn, bitfield))

            # Create and append a Node structure for each node
            nodes.append({
                'tcb': self.cspace().alloc(node.tcb, read=True, write=True, grant=True, grantreply=True),
                'vcpu': self.cspace().alloc(node.vcpu, read=True, write=True, grant=True, grantreply=True),
                'thread': thread,
                'ep_read': self.cspace().alloc(ep, read=True),
                'fault_reply_slot': self.cspace().alloc(None),
                'event_server_bitfield': self.map_region([(bitfield, 12)], read=True, write=True),
                })

        self._arg = {
            'cnode': self.cspace().alloc(self.cspace().cnode, write=True),
            'gic_lock': self.cspace().alloc(self.alloc(ObjectType.seL4_NotificationObject, name='gic_lock'), read=True, write=True),
            'nodes_lock': self.cspace().alloc(self.alloc(ObjectType.seL4_NotificationObject, name='nodes_lock'), read=True, write=True),
            'gic_dist_paddr': self.vm.addrs.gic_dist_paddr,
            'nodes': nodes,


            'ppi_map': {},
            'spi_map': { i: ({ 'SPI': i }, 0, True) for i in range(32, 1020) } if self.is_host else {},
        }

        if self.is_host:
            event_server_client_eps = self.composition.event_server.register_client(self, self.vm, { 'Host': None })
            resource_server_eps = list(self.composition.resource_server.register_host(self))
            self.vm.event_server_out_endpoints = [ eps[1] for eps in event_server_client_eps ]
            self.vm.resource_server_endpoints = [ eps[1] for eps in resource_server_eps ]
            self._arg.update({
                'event_server_client_ep': [ eps[0] for eps in event_server_client_eps ],
                'event_server_control_ep': self.composition.event_server.register_control_host(self),
                'resource_server_ep':  [ eps[0] for eps in resource_server_eps ],
                'benchmark_server_ep': self.cspace().alloc(self.composition.benchmark_server.ep, write=True, grantreply=True),
                'log_buffer': self.cspace().alloc(self.alloc(ObjectType.seL4_FrameObject, name='log_buffer', size_bits=21), read=True, write=True),
                })
        else:
            self.vm.event_server_out_endpoints = [
                self.vm.cspace().alloc(self.composition.extern(ObjectType.seL4_EndpointObject, 'realm_{}_event_server_client_endpoint_out_{}'.format(self.composition.realm_id(), self.composition.virt_to_phys_node_map(j))), write=True, grantreply=True)
                for j in range(self.composition.num_nodes())
                ]
            self._arg.update({
                'event_server_client_ep': [
                    self.cspace().alloc(self.composition.extern(ObjectType.seL4_EndpointObject, 'realm_{}_event_server_client_endpoint_{}'.format(self.composition.realm_id(), self.composition.virt_to_phys_node_map(j))), write=True, grantreply=True)
                    for j in range(self.composition.num_nodes())
                    ],
                })

    def serialize_arg(self):
        if self.is_host:
            ty = 'host-vmm'
        else:
            ty = 'realm-vmm'
        return self.serialize_builtin_arg(ty)

    def arg_json(self):
        return self._arg


class HostVM(VM):

    def __init__(self, composition, name, vmm_name):
        super().__init__(composition, name, vmm_name, is_host=True)

    def get_addrs(self):
        return Addrs(self.composition.plat, is_host=True)

    def set_chosen_default(self):
        return False

    def map_phys(self):
        return True

    def map_passthru_devices(self):
        def dev():
            # TODO extract from device tree? map larger ranges? 1GiB?

            if self.composition.plat == 'virt':
                yield 0xa000000, 0xa004000

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
