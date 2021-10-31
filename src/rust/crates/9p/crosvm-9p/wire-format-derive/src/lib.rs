// Copyright 2018 The Chromium OS Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the chromiumos.LICENSE file.

//! Derives a 9P wire format encoding for a struct by recursively calling
//! `WireFormat::encode` or `WireFormat::decode` on the fields of the struct.
//! This is only intended to be used from within the `p9` crate.

#![recursion_limit = "256"]

extern crate proc_macro;
extern crate proc_macro2;

#[macro_use]
extern crate quote;

#[macro_use]
extern crate syn;

use proc_macro2::{Span, TokenStream};
use syn::spanned::Spanned;
use syn::{Data, DeriveInput, Fields, Ident};

/// The function that derives the actual implementation.
#[proc_macro_derive(P9WireFormat)]
pub fn p9_wire_format(input: proc_macro::TokenStream) -> proc_macro::TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    p9_wire_format_inner(input).into()
}

fn p9_wire_format_inner(input: DeriveInput) -> TokenStream {
    if !input.generics.params.is_empty() {
        return quote! {
            compile_error!("derive(P9WireFormat) does not support generic parameters");
        };
    }

    let container = input.ident;

    let byte_size_impl = byte_size_sum(&input.data);
    let encode_impl = encode_wire_format(&input.data);
    let decode_impl = decode_wire_format(&input.data, &container);

    let scope = format!("wire_format_{}", container).to_lowercase();
    let scope = Ident::new(&scope, Span::call_site());
    quote! {
        mod #scope {
            extern crate std;
            use self::std::io;
            use self::std::result::Result::Ok;

            use super::#container;

            use super::protocol::WireFormat;

            impl WireFormat for #container {
                fn byte_size(&self) -> u32 {
                    #byte_size_impl
                }

                fn encode<W: io::Write>(&self, _writer: &mut W) -> io::Result<()> {
                    #encode_impl
                }

                fn decode<R: io::Read>(_reader: &mut R) -> io::Result<Self> {
                    #decode_impl
                }
            }
        }
    }
}

// Generate code that recursively calls byte_size on every field in the struct.
fn byte_size_sum(data: &Data) -> TokenStream {
    if let Data::Struct(ref data) = *data {
        if let Fields::Named(ref fields) = data.fields {
            let fields = fields.named.iter().map(|f| {
                let field = &f.ident;
                let span = field.span();
                quote_spanned! {span=>
                    WireFormat::byte_size(&self.#field)
                }
            });

            quote! {
                0 #(+ #fields)*
            }
        } else {
            unimplemented!();
        }
    } else {
        unimplemented!();
    }
}

// Generate code that recursively calls encode on every field in the struct.
fn encode_wire_format(data: &Data) -> TokenStream {
    if let Data::Struct(ref data) = *data {
        if let Fields::Named(ref fields) = data.fields {
            let fields = fields.named.iter().map(|f| {
                let field = &f.ident;
                let span = field.span();
                quote_spanned! {span=>
                    WireFormat::encode(&self.#field, _writer)?;
                }
            });

            quote! {
                #(#fields)*

                Ok(())
            }
        } else {
            unimplemented!();
        }
    } else {
        unimplemented!();
    }
}

// Generate code that recursively calls decode on every field in the struct.
fn decode_wire_format(data: &Data, container: &Ident) -> TokenStream {
    if let Data::Struct(ref data) = *data {
        if let Fields::Named(ref fields) = data.fields {
            let values = fields.named.iter().map(|f| {
                let field = &f.ident;
                let span = field.span();
                quote_spanned! {span=>
                    let #field = WireFormat::decode(_reader)?;
                }
            });

            let members = fields.named.iter().map(|f| {
                let field = &f.ident;
                quote! {
                    #field: #field,
                }
            });

            quote! {
                #(#values)*

                Ok(#container {
                    #(#members)*
                })
            }
        } else {
            unimplemented!();
        }
    } else {
        unimplemented!();
    }
}
