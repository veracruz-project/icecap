{ lib, buildPackages, runCommandCC
, bindgen, rustfmt
, libsel4, libs
, rustTargetName
}:

runCommandCC "icecap-gen.rs" {
  nativeBuildInputs = [
    bindgen rustfmt
  ];
  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
  buildInputs = [
    libsel4 libs.icecap-autoconf
  ];
} ''
  bindgen ${./bindgen.h} -o $out --use-core --ctypes-prefix=c_types --with-derive-default --rust-target nightly -- -target ${rustTargetName} $NIX_CFLAGS_COMPILE
''
