extern crate proc_macro;

use proc_macro::TokenStream;
use quote::quote;

#[proc_macro_derive(IsCap)]
pub fn cap_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_cap(&ast)
}

fn impl_cap(ast: &syn::DeriveInput) -> TokenStream {
    let name = &ast.ident;
    let gen = quote! {
        impl<'a> TryFrom<&'a Cap> for &'a #name {
            type Error = ();
            fn try_from(obj: &'a Cap) -> Result<Self, ()> {
                match obj {
                    Cap::#name(obj) => Ok(&obj),
                    _ => Err(()),
                }
            }
        }
        impl Into<Cap> for #name {
            fn into(self) -> Cap {
                Cap::#name(self)
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(IsObj)]
pub fn obj_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_obj(&ast)
}

fn impl_obj(ast: &syn::DeriveInput) -> TokenStream {
    let name = &ast.ident;
    let gen = quote! {
        impl<'a> TryFrom<&'a Obj> for &'a #name {
            type Error = ();
            fn try_from(cap: &'a Obj) -> Result<Self, ()> {
                match cap {
                    Obj::#name(cap) => Ok(&cap),
                    _ => Err(()),
                }
            }
        }
        impl Into<Obj> for #name {
            fn into(self) -> Obj {
                Obj::#name(self)
            }
        }
    };
    gen.into()
}
