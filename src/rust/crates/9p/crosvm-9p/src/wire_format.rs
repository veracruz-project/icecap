// Copyright 2018 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the chromiumos.LICENSE file.

use std;
use std::fmt;
use std::io;
use std::io::{ErrorKind, Read, Write};
use std::mem;
use std::ops::{Deref, DerefMut};
use std::string::String;
use std::vec::Vec;

/// A type that can be encoded on the wire using the 9P protocol.
pub trait WireFormat: std::marker::Sized {
    /// Returns the number of bytes necessary to fully encode `self`.
    fn byte_size(&self) -> u32;

    /// Encodes `self` into `writer`.
    fn encode<W: Write>(&self, writer: &mut W) -> io::Result<()>;

    /// Decodes `Self` from `reader`.
    fn decode<R: Read>(reader: &mut R) -> io::Result<Self>;
}

// This doesn't really _need_ to be a macro but unfortunately there is no trait bound to
// express "can be casted to another type", which means we can't write `T as u8` in a trait
// based implementation.  So instead we have this macro, which is implemented for all the
// stable unsigned types with the added benefit of not being implemented for the signed
// types which are not allowed by the protocol.
macro_rules! uint_wire_format_impl {
    ($Ty:ty) => {
        impl WireFormat for $Ty {
            fn byte_size(&self) -> u32 {
                mem::size_of::<$Ty>() as u32
            }

            fn encode<W: Write>(&self, writer: &mut W) -> io::Result<()> {
                let mut buf = [0u8; mem::size_of::<$Ty>()];

                // Encode the bytes into the buffer in little endian order.
                for idx in 0..mem::size_of::<$Ty>() {
                    buf[idx] = (self >> (8 * idx)) as u8;
                }

                writer.write_all(&buf)
            }

            fn decode<R: Read>(reader: &mut R) -> io::Result<Self> {
                let mut buf = [0u8; mem::size_of::<$Ty>()];
                reader.read_exact(&mut buf)?;

                // Read bytes from the buffer in little endian order.
                let mut result = 0;
                for idx in 0..mem::size_of::<$Ty>() {
                    result |= (buf[idx] as $Ty) << (8 * idx);
                }

                Ok(result)
            }
        }
    };
}
uint_wire_format_impl!(u8);
uint_wire_format_impl!(u16);
uint_wire_format_impl!(u32);
uint_wire_format_impl!(u64);

// The 9P protocol requires that strings are UTF-8 encoded.  The wire format is a u16
// count |N|, encoded in little endian, followed by |N| bytes of UTF-8 data.
impl WireFormat for String {
    fn byte_size(&self) -> u32 {
        (mem::size_of::<u16>() + self.len()) as u32
    }

    fn encode<W: Write>(&self, writer: &mut W) -> io::Result<()> {
        if self.len() > std::u16::MAX as usize {
            return Err(io::Error::new(
                ErrorKind::InvalidInput,
                "string is too long",
            ));
        }

        (self.len() as u16).encode(writer)?;
        writer.write_all(self.as_bytes())
    }

    fn decode<R: Read>(reader: &mut R) -> io::Result<Self> {
        let len: u16 = WireFormat::decode(reader)?;
        let mut result = String::with_capacity(len as usize);
        reader.take(len as u64).read_to_string(&mut result)?;
        Ok(result)
    }
}

// The wire format for repeated types is similar to that of strings: a little endian
// encoded u16 |N|, followed by |N| instances of the given type.
impl<T: WireFormat> WireFormat for Vec<T> {
    fn byte_size(&self) -> u32 {
        mem::size_of::<u16>() as u32 + self.iter().map(|elem| elem.byte_size()).sum::<u32>()
    }

    fn encode<W: Write>(&self, writer: &mut W) -> io::Result<()> {
        if self.len() > std::u16::MAX as usize {
            return Err(io::Error::new(
                ErrorKind::InvalidInput,
                "too many elements in vector",
            ));
        }

        (self.len() as u16).encode(writer)?;
        for elem in self {
            elem.encode(writer)?;
        }

        Ok(())
    }

    fn decode<R: Read>(reader: &mut R) -> io::Result<Self> {
        let len: u16 = WireFormat::decode(reader)?;
        let mut result = Vec::with_capacity(len as usize);

        for _ in 0..len {
            result.push(WireFormat::decode(reader)?);
        }

        Ok(result)
    }
}

/// A type that encodes an arbitrary number of bytes of data.  Typically used for Rread
/// Twrite messages.  This differs from a `Vec<u8>` in that it encodes the number of bytes
/// using a `u32` instead of a `u16`.
#[derive(PartialEq)]
pub struct Data(pub Vec<u8>);

// The maximum length of a data buffer that we support.  In practice the server's max message
// size should prevent us from reading too much data so this check is mainly to ensure a
// malicious client cannot trick us into allocating massive amounts of memory.
const MAX_DATA_LENGTH: u32 = 32 * 1024 * 1024;

impl fmt::Debug for Data {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        // There may be a lot of data and we don't want to spew it all out in a trace.  Instead
        // just print out the number of bytes in the buffer.
        write!(f, "Data({} bytes)", self.len())
    }
}

// Implement Deref and DerefMut so that we don't have to use self.0 everywhere.
impl Deref for Data {
    type Target = Vec<u8>;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for Data {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

// Same as Vec<u8> except that it encodes the length as a u32 instead of a u16.
impl WireFormat for Data {
    fn byte_size(&self) -> u32 {
        mem::size_of::<u32>() as u32 + self.iter().map(|elem| elem.byte_size()).sum::<u32>()
    }

    fn encode<W: Write>(&self, writer: &mut W) -> io::Result<()> {
        if self.len() > std::u32::MAX as usize {
            return Err(io::Error::new(ErrorKind::InvalidInput, "data is too large"));
        }
        (self.len() as u32).encode(writer)?;
        writer.write_all(self)
    }

    fn decode<R: Read>(reader: &mut R) -> io::Result<Self> {
        let len: u32 = WireFormat::decode(reader)?;
        if len > MAX_DATA_LENGTH {
            return Err(io::Error::new(
                ErrorKind::InvalidData,
                format!("data length ({} bytes) is too large", len),
            ));
        }

        let mut buf = Vec::with_capacity(len as usize);
        reader.take(len as u64).read_to_end(&mut buf)?;

        if buf.len() == len as usize {
            Ok(Data(buf))
        } else {
            Err(io::Error::new(
                ErrorKind::UnexpectedEof,
                format!(
                    "unexpected end of data: want: {} bytes, got: {} bytes",
                    len,
                    buf.len()
                ),
            ))
        }
    }
}
