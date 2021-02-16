use core::cell::RefCell;
use alloc::vec::Vec;

use smoltcp::Result;
use smoltcp::time::Instant;
use smoltcp::phy::{self, Device, DeviceCapabilities};

use icecap_interfaces::NetDriver;

pub struct IceCapDevice {
    driver: RefCell<NetDriver>,
}

impl IceCapDevice {

    pub fn new(driver: NetDriver) -> Self {
        Self {
            driver: RefCell::new(driver),
        }
    }

    pub fn driver(&mut self) -> &mut RefCell<NetDriver> {
        &mut self.driver
    }

}

impl<'a> Device<'a> for IceCapDevice {
    type RxToken = RxToken;
    type TxToken = TxToken<'a>;

    fn capabilities(&self) -> DeviceCapabilities {
        let mut caps = DeviceCapabilities::default();
        caps.max_transmission_unit = 65535;
        caps
    }

    fn receive(&'a mut self) -> Option<(Self::RxToken, Self::TxToken)> {
        self.driver().get_mut().rx().map(move |buf| {
            let rx = RxToken {
                buf,
            };
            let tx = TxToken {
                driver: &self.driver,
            };
            (rx, tx)
        })
    }

    fn transmit(&'a mut self) -> Option<Self::TxToken> {
        Some(TxToken {
            driver: &self.driver,
        })
    }
}

pub struct RxToken {
    buf: Vec<u8>,
}

impl <'a>phy::RxToken for RxToken {
    fn consume<R, F>(mut self, _timestamp: Instant, f: F) -> Result<R>
    where
        F: FnOnce(&mut [u8]) -> Result<R>,
    {
        f(self.buf.as_mut_slice())
    }
}

pub struct TxToken<'a> {
    driver: &'a RefCell<NetDriver>,
}

impl<'a> phy::TxToken for TxToken<'a> {
    fn consume<R, F>(self, _timestamp: Instant, len: usize, f: F) -> Result<R>
    where
        F: FnOnce(&mut [u8]) -> Result<R>,
    {
        let mut buf = vec![0; len];
        let r = f(buf.as_mut_slice());
        self.driver.borrow_mut().tx(buf.as_slice());
        r
    }
}

// fn pp_packet(buf: &[u8]) -> String {
//     buf.to_vec().into_iter().map(|b| format!("{:02X}", b)).collect::<Vec<String>>().join(" ")
// }
