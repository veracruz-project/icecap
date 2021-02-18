use core::ops::Deref;
use core::ptr::write_bytes;
use register::{mmio::ReadWrite, register_structs};

// TODO
// - see libsel4vm: Completely emulate vgicv2 distributor

pub const GIC_DIST_SIZE: usize = 0x1000;

register_structs! {
    pub DistributorRegisterBlock {
        (0x000 => enable: ReadWrite<u32>),
        (0x004 => ic_type: ReadWrite<u32>),
        (0x008 => dist_ident: ReadWrite<u32>),

        (0x080 => security: [ReadWrite<u32>; 32]),

        (0x100 => enable_set: [ReadWrite<u32>; 32]),
        (0x180 => enable_clr: [ReadWrite<u32>; 32]),
        (0x200 => pending_set: [ReadWrite<u32>; 32]),
        (0x280 => pending_clr: [ReadWrite<u32>; 32]),
        (0x300 => active: [ReadWrite<u32>; 32]),

        (0x400 => priority: [ReadWrite<u32>; 255]),

        (0x800 => targets: [ReadWrite<u32>; 255]),

        (0xC00 => config: [ReadWrite<u32>; 64]),

        (0xD00 => spi: [ReadWrite<u32>; 32]),
        (0xDD4 => legacy_int: ReadWrite<u32>),
        (0xDE0 => match_d: ReadWrite<u32>),
        (0xDE4 => enable_d: ReadWrite<u32>),

        (0xF00 => sgi_control: ReadWrite<u32>),
        (0xF10 => sgi_pending_clr: [ReadWrite<u32>; 4]),

        (0xFC0 => periph_id: [ReadWrite<u32>; 12]),
        (0xFF0 => component_id: [ReadWrite<u32>; 4]),

        (0xFFF => @END),
    }
}

pub type IRQ = u64;

pub struct Distributor {
    pub base_addr: usize,
}

impl Distributor {

    pub fn new(base_addr: usize) -> Self {
        Self {
            base_addr,
        }
    }

    fn ptr(&self) -> *const DistributorRegisterBlock {
        self.base_addr as *const _
    }

    pub fn set_pending(&self, irq: IRQ, v: bool) {
        if v {
            self.pending_set[irq_idx(irq)].set(self.pending_set[irq_idx(irq)].get() | irq_bit(irq));
            self.pending_clr[irq_idx(irq)].set(self.pending_clr[irq_idx(irq)].get() | irq_bit(irq));
        } else {
            self.pending_set[irq_idx(irq)].set(self.pending_set[irq_idx(irq)].get() & !irq_bit(irq));
            self.pending_clr[irq_idx(irq)].set(self.pending_clr[irq_idx(irq)].get() & !irq_bit(irq));
        }
    }

    pub fn is_pending(&self, irq: IRQ) -> bool {
        self.pending_set[irq_idx(irq)].get() & irq_bit(irq) != 0
    }

    pub fn set_enable(&self, irq: IRQ, v: bool) {
        if v {
            self.enable_set[irq_idx(irq)].set(self.enable_set[irq_idx(irq)].get() | irq_bit(irq));
            self.enable_clr[irq_idx(irq)].set(self.enable_clr[irq_idx(irq)].get() | irq_bit(irq));
        } else {
            self.enable_set[irq_idx(irq)].set(self.enable_set[irq_idx(irq)].get() & !irq_bit(irq));
            self.enable_clr[irq_idx(irq)].set(self.enable_clr[irq_idx(irq)].get() & !irq_bit(irq));
        }
    }

    pub fn is_enabled(&self, irq: IRQ) -> bool {
        self.enable_set[irq_idx(irq)].get() & irq_bit(irq) != 0
    }

    pub fn set_active(&self, irq: IRQ, v: bool) {
        if v {
            self.active[irq_idx(irq)].set(self.active[irq_idx(irq)].get() | irq_bit(irq));
        } else {
            self.active[irq_idx(irq)].set(self.active[irq_idx(irq)].get() & !irq_bit(irq));
        }
    }

    pub fn is_active(&self, irq: IRQ) -> bool {
        self.active[irq_idx(irq)].get() & irq_bit(irq) != 0
    }

    // TODO rename
    pub fn is_dist_enabled(&self) -> bool {
        self.enable.get() != 0
    }

    pub fn enable(&self) {
        self.enable.set(1);
    }

    pub fn disable(&self) {
        self.enable.set(0);
    }

    pub fn reset(&self) {
        unsafe {
            write_bytes(self.base_addr as *mut u8, 0, 0xfff);
        }

        self.ic_type.set(0x0000fce7); // RO
        self.dist_ident.set(0x0200043b); // RO
        self.enable_set[0].set(0x0000ffff); // 16-bit RO
        self.enable_clr[0].set(0x0000ffff); // 16-bit RO
        self.config[0].set(0xaaaaaaaa); // RO

        // Reset value depends on GIC configuration
        self.config[1].set(0x55540000);
        self.config[2].set(0x55555555);
        self.config[3].set(0x55555555);
        self.config[4].set(0x55555555);
        self.config[5].set(0x55555555);
        self.config[6].set(0x55555555);
        self.config[7].set(0x55555555);
        self.config[8].set(0x55555555);
        self.config[9].set(0x55555555);
        self.config[10].set(0x55555555);
        self.config[11].set(0x55555555);
        self.config[12].set(0x55555555);
        self.config[13].set(0x55555555);
        self.config[14].set(0x55555555);
        self.config[15].set(0x55555555);

        // Identification
        self.periph_id[4].set(0x00000004); // RO
        self.periph_id[8].set(0x00000090); // RO
        self.periph_id[9].set(0x000000b4); // RO
        self.periph_id[10].set(0x0000002b); // RO
        self.component_id[0].set(0x0000000d); // RO
        self.component_id[1].set(0x000000f0); // RO
        self.component_id[2].set(0x00000005); // RO
        self.component_id[3].set(0x000000b1); // RO

        // This tells Linux that all IRQs are routed to CPU0.
        // When we eventually support multiple vCPUs per guest, this will need to be updated.
        for target in self.targets.iter() {
            target.set(0x01010101);
        }
    }
}

impl Deref for Distributor {
    type Target = DistributorRegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe {
            &*self.ptr()
        }
    }
}

fn irq_idx(irq: IRQ) -> usize {
    (irq as usize) / 32
}

fn irq_bit(irq: IRQ) -> u32 {
    1 << (irq % 32)
}

#[derive(Debug)]
pub enum Action {
    ReadOnly,
    Passthru,
    Enable,
    EnableSet,
    EnableClr,
    PendingSet,
    PendingClr,
    SGI,
}

impl Action {
    pub fn at(offset: usize) -> Self {
        // The only fields we care about are enable_set/clr
        // We have 2 options for other registers:
        //  a) ignore writes and hope the VM acts appropriately (ReadOnly)
        //  b) allow write access so the VM thinks there is no problem,
        //     but do not honour them (Passthru)
        match offset {
            0x000..0x004 => Action::Enable, // enable
            0x080..0x100 => Action::Passthru, // security
            0x100..0x180 => Action::EnableSet, // enable_set
            0x180..0x200 => Action::EnableClr, // enable_clr
            0x200..0x280 => Action::PendingSet, // pending_set
            0x280..0x300 => Action::PendingClr, // pending_clr
            0xC00..0xD00 => Action::Passthru, // config
            0xF00..0xF04 => Action::Passthru, // sgi_control
            0xF10..0xF20 => Action::SGI, // sgi_pending_clr
            _ => Action::ReadOnly,
        }
    }
}
