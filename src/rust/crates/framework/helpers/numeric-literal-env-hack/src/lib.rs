use std::env;
use std::fmt::Debug;
use std::marker::PhantomData;
use std::str::FromStr;

use proc_macro::TokenStream;
use quote::{quote, ToTokens};
use syn::{parse, ExprLit, Lit};

// HACK workaround for the fact that 'env!()' can only be used for string constants

fn env_generic<T>(_phantom: PhantomData<T>, var: TokenStream) -> TokenStream
where
    T: FromStr + ToTokens,
    <T as FromStr>::Err: Debug,
{
    let var = match parse::<ExprLit>(var).unwrap().lit {
        Lit::Str(var) => var.value(),
        _ => panic!(),
    };
    let val = env::var(var).unwrap().parse::<T>().unwrap();
    quote!(
        #val
    )
    .into()
}

#[proc_macro]
pub fn env_usize(var: TokenStream) -> TokenStream {
    env_generic::<usize>(PhantomData, var)
}
