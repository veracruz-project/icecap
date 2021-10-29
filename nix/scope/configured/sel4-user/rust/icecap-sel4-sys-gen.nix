{ lib, buildPackages, runCommandCC
, bindgen, rustfmt
, icecapSrc
, libsel4, libs
, rustTargetName
}:

let
  wrapper = icecapSrc.relativeRaw "rust/icecap/icecap-sel4/sys/wrapper.h";

in
runCommandCC "icecap-gen.rs" {
  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
  nativeBuildInputs = [
    bindgen rustfmt
  ];
  buildInputs = [
    libsel4 libs.icecap-autoconf
  ];
} ''
  bindgen ${wrapper} -o $out \
    --use-core --ctypes-prefix=c_types --with-derive-default --rust-target nightly \
    -- -target ${rustTargetName} $NIX_CFLAGS_COMPILE
''
