use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo:rustc-link-lib=sel4");

    println!("cargo:rerun-if-changed=wrapper.h");

    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .use_core()
        .ctypes_prefix("c_types")
        .derive_default(true)
        .rust_target(bindgen::RustTarget::Nightly)
        .rustfmt_bindings(true)
        .generate_comments(false)
        .blocklist_item("__sel4_ipc_buffer") // bindgen doesn't support thead-local symbols
        .generate()
        .unwrap();

    let out_dir = env::var("OUT_DIR").unwrap();
    let out_path = PathBuf::from(out_dir).join("bindings.rs");
    bindings.write_to_file(out_path).unwrap();
}
