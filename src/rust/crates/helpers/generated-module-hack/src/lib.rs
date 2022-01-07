use proc_macro::TokenStream;
use quote::quote;
use std::env;
use std::path::Path;
use syn::{parse, ItemMod};

/// For now, the following doesn't work:
/// ```
/// #[path = concat!(env!("OUT_DIR"), "/foo.rs")]
/// mod foo
/// ```
/// This macro does the same thing:
/// ```
/// #[generated_module]
/// mod foo
/// ```
#[proc_macro_attribute]
pub fn generated_module(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let item = parse::<ItemMod>(item).unwrap();
    let path = Path::new(&env::var("OUT_DIR").unwrap())
        .join(item.ident.to_string())
        .with_extension("rs")
        .to_str()
        .unwrap()
        .to_string();
    quote!(
        #[path = #path]
        #item
    )
    .into()
}
