use std::env;
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse, ExprLit, Lit};

// HACK workaround for the fact that 'env!()' can only be used for string constants

#[proc_macro]
pub fn env_usize(var: TokenStream) -> TokenStream {
    let var = match parse::<ExprLit>(var).unwrap().lit {
        Lit::Str(var) => var.value(),
        _ => panic!(),
    };
    let val = env::var(var).unwrap().parse::<usize>().unwrap();
    quote!(
        #val
    ).into()
}
