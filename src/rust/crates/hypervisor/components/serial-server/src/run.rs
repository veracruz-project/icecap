use alloc::collections::VecDeque;
use core::fmt::Write;

use icecap_driver_interfaces::SerialDevice;
use icecap_std::prelude::*;
use icecap_std::ring_buffer::{BufferedRingBuffer, RingBuffer};
use icecap_std::rpc;
use icecap_timer_server_client::*;

use crate::{
    color::{Color, COLORS},
    event::Event,
    out,
};

pub type ClientId = usize;

struct SerialServer<T: SerialDevice> {
    clients: Vec<Client>,
    active_input_client: Option<ClientId>,
    last_output_client: Option<ClientId>,
    output_since_last_timeout: bool,
    input_state: InputState,
    dev: T,
}

struct Client {
    driver: BufferedRingBuffer,
    buffer: VecDeque<u8>,
    color: &'static Color,
}

#[derive(Clone, Copy, Debug)]
enum InputState {
    Start,
    NewLine,
    Escape,
}

const ESCAPE: u8 = b'@';

const MAX_NUM_CLIENTS: usize = COLORS.len();
const BUFFER_LIMIT: usize = 0x1000;

impl<T: SerialDevice> SerialServer<T> {
    fn new(dev: T, clients: Vec<RingBuffer>) -> Self {
        assert!(clients.len() <= MAX_NUM_CLIENTS);

        // for (i, c) in COLORS.iter().enumerate() {
        //     set_color(*c);
        //     out!(&self.dev, "COLORS[{}]", i);
        // }
        // clear_color();

        let clients_ = clients
            .into_iter()
            .enumerate()
            .map(|(i, client)| Client {
                driver: BufferedRingBuffer::new(client),
                buffer: VecDeque::with_capacity(BUFFER_LIMIT),
                color: &COLORS[i],
            })
            .collect::<Vec<_>>();

        let active_input_client = if clients_.is_empty() { None } else { Some(0) };

        Self {
            clients: clients_,
            active_input_client,
            last_output_client: None,
            output_since_last_timeout: false,
            input_state: InputState::Start,
            dev,
        }
    }

    fn run(&mut self, timer: TimerClient, event_ep: Endpoint, cspace: CNode, reply_ep: Endpoint) {
        // TODO for (i, client) in self.clients.iter_mut().enumerate()
        for i in 0..self.clients.len() {
            self.clients[i].driver.ring_buffer().enable_notify_read();
            self.clients[i].driver.ring_buffer().enable_notify_write();
            self.handle_rx(i);
            self.handle_tx(i);
        }

        timer.periodic(0, 500000000).unwrap();

        loop {
            let (info, _) = event_ep.recv();
            cspace.relative(reply_ep).save_caller().unwrap();

            match rpc::server::recv::<Event>(&info) {
                Event::Interrupt => {
                    self.dev.handle_interrupt();
                    loop {
                        match self.dev.get_char() {
                            Some(c) => {
                                self.handle_char(c);
                            }
                            None => break,
                        }
                    }
                }
                Event::Timeout => {
                    self.handle_timeout();
                }
                Event::Con(client_id) => {
                    self.handle_rx(client_id);
                    self.handle_tx(client_id);
                }
            }

            rpc::Client::<()>::new(reply_ep).send(&());
        }
    }

    fn handle_timeout(&mut self) {
        if self.output_since_last_timeout {
            self.output_since_last_timeout = false;
        } else {
            let mut flushed_outer = false;
            loop {
                let mut flushed_inner = false;
                for i in 0..self.clients.len() {
                    if self.flush_line(i) {
                        flushed_outer = true;
                        flushed_inner = true;
                    }
                }
                if !flushed_inner {
                    break;
                }
            }
            if !flushed_outer {
                for i in 0..self.clients.len() {
                    self.flush(i);
                }
            }
        }
    }

    fn handle_rx(&mut self, client_id: ClientId) {
        // TODO
        // let client = &mut self.clients[client_id];
        self.clients[client_id].driver.rx_callback();
        let mut buf = [0];
        for _ in 0..self.clients[client_id].driver.poll() {
            self.clients[client_id].driver.rx_into(&mut buf);
            self.handle_client_char(client_id, buf[0]);
        }
        self.clients[client_id]
            .driver
            .ring_buffer()
            .enable_notify_read()
    }

    fn handle_tx(&mut self, client_id: ClientId) {
        self.clients[client_id].driver.tx_callback();
        self.clients[client_id]
            .driver
            .ring_buffer()
            .enable_notify_write();
    }

    fn handle_client_char(&mut self, client_id: ClientId, c: u8) {
        self.clients[client_id].buffer.push_back(c);
        if self.clients[client_id].buffer.len() == BUFFER_LIMIT {
            self.flush(client_id);
            let mut is_done = false;
            self.last_output_client.map(|i| self.flush_line(i));
            while !is_done {
                is_done = true;
                for i in 0..self.clients.len() {
                    if self.flush_line(i) {
                        is_done = false;
                    }
                }
            }
            if self.clients[client_id].buffer.len() == BUFFER_LIMIT {
                for i in 0..self.clients.len() {
                    self.flush(i);
                }
            }
            self.set_output_client(client_id);
        } else {
            let mut any_else = false;
            for i in 0..self.clients.len() {
                if i != client_id {
                    if !self.clients[i].buffer.is_empty() {
                        any_else = true;
                    }
                }
            }
            if c == b'\n' || (self.last_output_client == Some(client_id) && !any_else) {
                self.flush(client_id);
            }
        }
    }

    fn flush(&mut self, client_id: ClientId) {
        if self.clients[client_id].buffer.is_empty() {
            return;
        }
        self.set_output_client(client_id);
        for c in self.clients[client_id].buffer.drain(..) {
            self.dev.put_char(c);
        }
        self.output_since_last_timeout = true;
    }

    fn flush_line(&mut self, client_id: ClientId) -> bool {
        let i = match self.clients[client_id]
            .buffer
            .iter()
            .position(|c| *c == b'\n')
        {
            None => return false,
            Some(i) => i,
        };
        self.set_output_client(client_id);
        for c in self.clients[client_id].buffer.drain(..=i) {
            self.dev.put_char(c);
        }
        self.output_since_last_timeout = true;
        true
    }

    fn handle_char(&mut self, c: u8) {
        use InputState::*;
        let raw = |c| {
            if let b'\r' | b'\n' = c {
                NewLine
            } else {
                Start
            }
        };
        self.input_state = match self.input_state {
            Start => {
                self.forward(c);
                raw(c)
            }
            NewLine => match c {
                ESCAPE => Escape,
                _ => {
                    self.forward(c);
                    raw(c)
                }
            },
            Escape => match c {
                ESCAPE => {
                    self.forward(c);
                    Start
                }
                b'?' => {
                    self.clear_output_client();
                    out!(
                        &self.dev,
                        "--- SerialServer help ---
Escape char: {}
0 - {} switches input to that client
?      shows this help\n",
                        ESCAPE,
                        self.clients.len() - 1
                    );
                    NewLine
                }
                _ => {
                    let client_id = (c as ClientId).wrapping_sub(b'0' as ClientId);
                    if client_id < self.clients.len() {
                        self.set_input_client(client_id);
                        NewLine
                    } else {
                        self.forward(ESCAPE);
                        self.forward(c);
                        Start
                    }
                }
            },
        };
    }

    fn forward(&mut self, c: u8) {
        let buf = [c];
        if let Some(i) = self.active_input_client {
            self.clients[i].driver.tx(&buf);
        }
    }

    fn set_output_client(&mut self, client_id: ClientId) {
        if self.last_output_client != Some(client_id) {
            self.last_output_client = Some(client_id);
            self.clients[client_id].color.set();
        }
    }

    fn clear_output_client(&mut self) {
        if let Some(_) = self.last_output_client {
            self.last_output_client = None;
            Color::clear();
        }
    }

    fn set_input_client(&mut self, client_id: ClientId) {
        self.clear_output_client();
        out!(&self.dev, "Switching input to {}\n", client_id);
        self.active_input_client = Some(client_id);
    }
}

pub fn run(
    clients: Vec<RingBuffer>,
    timer: TimerClient,
    event_ep: Endpoint,
    cspace: CNode,
    reply_ep: Endpoint,
    dev: impl SerialDevice,
) {
    SerialServer::new(dev, clients).run(timer, event_ep, cspace, reply_ep)
}
