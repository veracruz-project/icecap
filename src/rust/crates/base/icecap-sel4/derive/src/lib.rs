use proc_macro::TokenStream;
use quote::quote;
use syn;

#[proc_macro_derive(LocalCPtr)]
pub fn local_cptr_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_local_cptr(&ast)
}

fn impl_local_cptr(ast: &syn::DeriveInput) -> TokenStream {
    let name = &ast.ident;
    let name_str = name.to_string();
    let gen = quote! {
        impl LocalCPtr for #name {
            fn cptr(self) -> CPtr {
                self.0
            }
            fn from_cptr(cptr: CPtr) -> Self {
                Self(cptr)
            }
        }
        impl fmt::Debug for #name {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                f.debug_tuple(#name_str).field(unsafe {
                    &(self.raw())
                }).finish()
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(ObjectFixedSize)]
pub fn obj_fixed_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_obj_fixed(&ast)
}

fn impl_obj_fixed(ast: &syn::DeriveInput) -> TokenStream {
    let name = &ast.ident;
    let gen = quote! {
        impl ObjectFixedSize for #name {
            fn blueprint() -> ObjectBlueprint {
                ObjectBlueprint::#name
            }
        }
    };
    gen.into()
}

#[proc_macro_derive(ObjectVariableSize)]
pub fn obj_variable_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    impl_obj_variable(&ast)
}

fn impl_obj_variable(ast: &syn::DeriveInput) -> TokenStream {
    let name = &ast.ident;
    let gen = quote! {
        impl ObjectVariableSize for #name {
            fn blueprint(size_bits: usize) -> ObjectBlueprint {
                ObjectBlueprint::#name { size_bits }
            }
            fn object_type() -> ObjectType {
                ObjectType::#name
            }
        }
    };
    gen.into()
}
