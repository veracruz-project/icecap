// Copyright 2020 Arm Limited
// Copyright 2018 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the chromiumos.LICENSE file.

/// Runs a [9P] server.
///
/// [9P]: http://man.cat-v.org/plan_9/5/0intro
extern crate getopts;
extern crate libc;
#[macro_use]
extern crate log;
extern crate icecap_p9_server_linux;

use icecap_p9_server_linux as p9;

use libc::gid_t;

use std::ffi::CString;
use std::fmt;
use std::fs::{remove_file, File};
use std::io::{self, BufReader, BufWriter};
use std::net;
use std::num::ParseIntError;
use std::os::unix::fs::FileTypeExt;
use std::os::unix::fs::PermissionsExt;
use std::os::unix::io::{AsRawFd, FromRawFd, IntoRawFd, RawFd};
use std::os::unix::net::{SocketAddr, UnixListener};
use std::path::{Path, PathBuf};
use std::result;
use std::str::FromStr;
use std::string;
use std::sync::Arc;
use std::thread;

const DEFAULT_BUFFER_SIZE: usize = 8192;

// Address family identifiers.
const UNIX: &'static str = "unix:";
const UNIX_FD: &'static str = "unix-fd:";

// Usage for this program.
const USAGE: &'static str = "9s [options] {unix:<path>|unix-fd:<fd>|<ip>:<port>}";

enum ListenAddress {
    Net(net::SocketAddr),
    Unix(String),
    UnixFd(RawFd),
}

#[derive(Debug)]
enum ParseAddressError {
    MissingUnixPath,
    MissingUnixFd,
    Net(net::AddrParseError),
    Unix(string::ParseError),
    UnixFd(ParseIntError),
}

impl fmt::Display for ParseAddressError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            &ParseAddressError::MissingUnixPath => write!(f, "missing unix path"),
            &ParseAddressError::MissingUnixFd => write!(f, "missing unix file descriptor"),
            &ParseAddressError::Net(ref e) => e.fmt(f),
            &ParseAddressError::Unix(ref e) => write!(f, "invalid unix path: {}", e),
            &ParseAddressError::UnixFd(ref e) => write!(f, "invalid file descriptor: {}", e),
        }
    }
}

impl FromStr for ListenAddress {
    type Err = ParseAddressError;

    fn from_str(s: &str) -> result::Result<Self, Self::Err> {
        if s.starts_with(UNIX) {
            if s.len() > UNIX.len() {
                Ok(ListenAddress::Unix(
                    s[UNIX.len()..].parse().map_err(ParseAddressError::Unix)?,
                ))
            } else {
                Err(ParseAddressError::MissingUnixPath)
            }
        } else if s.starts_with(UNIX_FD) {
            if s.len() > UNIX_FD.len() {
                Ok(ListenAddress::UnixFd(
                    s[UNIX_FD.len()..]
                        .parse()
                        .map_err(ParseAddressError::UnixFd)?,
                ))
            } else {
                Err(ParseAddressError::MissingUnixFd)
            }
        } else {
            Ok(ListenAddress::Net(
                s.parse().map_err(ParseAddressError::Net)?,
            ))
        }
    }
}

#[derive(Debug)]
enum Error {
    Address(ParseAddressError),
    Argument(getopts::Fail),
    IO(io::Error),
    SocketGid(ParseIntError),
    SocketPathNotAbsolute(PathBuf),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            &Error::Address(ref e) => e.fmt(f),
            &Error::Argument(ref e) => e.fmt(f),
            &Error::IO(ref e) => e.fmt(f),
            &Error::SocketGid(ref e) => write!(f, "invalid gid value: {}", e),
            &Error::SocketPathNotAbsolute(ref p) => {
                write!(f, "unix socket path must be absolute: {:?}", p)
            }
        }
    }
}

struct UnixSocketAddr(SocketAddr);
impl fmt::Display for UnixSocketAddr {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if let Some(path) = self.0.as_pathname() {
            write!(f, "{}", path.to_str().unwrap_or("<malformed path>"))
        } else {
            write!(f, "<unnamed or abstract socket>")
        }
    }
}

type Result<T> = result::Result<T, Error>;

fn handle_client<R: io::Read, W: io::Write>(
    root: Arc<str>,
    mut reader: R,
    mut writer: W,
) -> io::Result<()> {
    let mut server = p9::Server::new(PathBuf::from(&*root));

    loop {
        server.handle_message(&mut reader, &mut writer)?;
    }
}

fn spawn_server_thread<
    R: 'static + io::Read + Send,
    W: 'static + io::Write + Send,
    D: 'static + fmt::Display + Send,
>(
    root: &Arc<str>,
    reader: R,
    writer: W,
    peer: D,
) {
    let reader = BufReader::with_capacity(DEFAULT_BUFFER_SIZE, reader);
    let writer = BufWriter::with_capacity(DEFAULT_BUFFER_SIZE, writer);
    let server_root = root.clone();
    thread::spawn(move || {
        if let Err(e) = handle_client(server_root, reader, writer) {
            error!("error while handling client {}: {}", peer, e);
        }
    });
}

fn run_tcp_server(root: Arc<str>, addr: net::SocketAddr) -> io::Result<()> {
    let listener = net::TcpListener::bind(addr)?;
    loop {
        let (stream, peer) = listener.accept()?;
        spawn_server_thread(&root, stream.try_clone()?, stream, peer);
    }
}

fn adjust_socket_ownership(path: &Path, gid: gid_t) -> io::Result<()> {
    // At this point we expect valid path since we supposedly created
    // the socket, so any failure in transforming path is _really_ unexpected.
    let path_str = path.as_os_str().to_str().expect("invalid unix socket path");
    let path_cstr = CString::new(path_str).expect("malformed unix socket path");

    // Safe as kernel only reads from the path and we know it is properly
    // formed and we check the result for errors.
    // Note: calling chown with uid -1 will preserve current user ownership.
    let res = unsafe { libc::chown(path_cstr.as_ptr(), libc::uid_t::max_value(), gid) };
    if res < 0 {
        return Err(io::Error::last_os_error());
    }

    // Allow both owner and group read/write access to the socket, and
    // deny access to the rest of the world.
    let mut permissions = path.metadata()?.permissions();
    permissions.set_mode(0o660);

    Ok(())
}

fn run_unix_server(root: Arc<str>, listener: UnixListener) -> io::Result<()> {
    loop {
        let (stream, peer) = listener.accept()?;
        let peer = UnixSocketAddr(peer);

        info!("accepted connection from {}", peer);
        spawn_server_thread(&root, stream.try_clone()?, stream, peer);
    }
}

fn run_unix_server_with_path(
    root: Arc<str>,
    path: &Path,
    socket_gid: Option<gid_t>,
) -> io::Result<()> {
    if path.exists() {
        let metadata = path.metadata()?;
        if !metadata.file_type().is_socket() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "Requested socket path points to existing non-socket object",
            ));
        }
        remove_file(path)?;
    }

    let listener = UnixListener::bind(path)?;

    if let Some(gid) = socket_gid {
        adjust_socket_ownership(path, gid)?;
    }

    run_unix_server(root, listener)
}

fn run_unix_server_with_fd(root: Arc<str>, fd: RawFd) -> io::Result<()> {
    // This is safe as we are using our very own file descriptor.
    let file = unsafe { File::from_raw_fd(fd) };
    let metadata = file.metadata()?;
    if !metadata.file_type().is_socket() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "Supplied file descriptor is not a socket",
        ));
    }

    // This is safe as because we have validated that we are dealing with a socket and
    // we are checking the result.
    let ret = unsafe { libc::listen(file.as_raw_fd(), 128) };
    if ret < 0 {
        return Err(io::Error::last_os_error());
    }

    // This is safe because we are dealing with listening socket.
    let listener = unsafe { UnixListener::from_raw_fd(file.into_raw_fd()) };
    run_unix_server(root, listener)
}

fn main() -> Result<()> {
    let mut opts = getopts::Options::new();
    opts.optopt(
        "r",
        "root",
        "root directory for clients (default is \"/\")",
        "PATH",
    );
    opts.optopt(
        "",
        "socket_gid",
        "change socket group ownership to the specified ID",
        "GID",
    );
    opts.optflag("h", "help", "print this help menu");

    let matches = opts
        .parse(std::env::args_os().skip(1))
        .map_err(Error::Argument)?;

    if matches.opt_present("h") || matches.free.len() == 0 {
        print!("{}", opts.usage(USAGE));
        return Ok(());
    }

    let root: Arc<str> = Arc::from(matches.opt_str("r").unwrap_or_else(|| "/".into()));

    env_logger::init();

    // We already checked that |matches.free| has at least one item.
    match matches.free[0]
        .parse::<ListenAddress>()
        .map_err(Error::Address)?
    {
        ListenAddress::Net(addr) => {
            run_tcp_server(root, addr).map_err(Error::IO)?;
        }
        ListenAddress::Unix(path) => {
            let path = Path::new(&path);
            if !path.is_absolute() {
                return Err(Error::SocketPathNotAbsolute(path.to_owned()));
            }

            let socket_gid = matches
                .opt_get::<gid_t>("socket_gid")
                .map_err(Error::SocketGid)?;

            run_unix_server_with_path(root, path, socket_gid).map_err(Error::IO)?;
        }
        ListenAddress::UnixFd(fd) => {
            // Try duplicating the fd to verify that it is a valid file descriptor. It will also
            // ensure that we will not accidentally close file descriptor used by something else.
            // Safe because this doesn't modify any memory and we check the return value.
            let fd = unsafe { libc::fcntl(fd, libc::F_DUPFD_CLOEXEC, 0) };
            if fd < 0 {
                return Err(Error::IO(io::Error::last_os_error()));
            }

            run_unix_server_with_fd(root, fd).map_err(Error::IO)?;
        }
    }

    Ok(())
}
