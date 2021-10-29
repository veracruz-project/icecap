{ lib, hostPlatform, buildPackages, runCommandCC, linkFarm, writeText
, bindgen, rustfmt, python3
, libsel4, libs
, rustTargetName
}:

let
  libs' = [
    libsel4 libs.icecap-autoconf
    libs.icecap-runtime libs.icecap-utils libs.icecap-pure # TODO these should be elsewhere
  ];

  allProp = x:
    let
      g = lib.concatMap f;
      f = { outPath, propagatedBuildInputs ? [], ... }:
        [ outPath ] ++ g propagatedBuildInputs;
    in lib.unique (g x);

  inputs = allProp libs';

  preprocessed = runCommandCC "icecap-raw.h" {
    buildInputs = libs';
  } ''
    $CC -E -P ${./bindgen.h} | tr '\n' ' ' > $out
  '';

  prefix = "OUTLINE_MAGIC_";

  outline = runCommandCC "icecap-outline.c" {
    nativeBuildInputs = [
      python3
    ];
  } ''
    mkdir -p $out/src $out/include
    h=$out/include/outline.h
    c=$out/src/outline.c

    echo '#include "${./bindgen.h}"' > $h
    echo '#include <outline.h>' > $c

    python3 ${./outline.py} ${preprocessed} --prefix=${prefix} --out-c=$c --out-h=$h
  '';

  liboutline = libs.mk {
    name = "icecap_outline";
    root.store = linkFarm "outline" [
      { name = "icecap.mk";
        path = writeText "icecap.mk" ''
          libs += outline
          src-outline := ${outline}/src
          inc-outline := ${outline}/include
        '';
      }
    ];
    propagatedBuildInputs = libs';
    extraCFlagsCompile = [
      "-Wno-deprecated-declarations"
    ];
  };

in
runCommandCC "icecap-gen.rs" {
  nativeBuildInputs = [
    bindgen rustfmt
  ];
  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
  buildInputs = libs' ++ [
    liboutline
  ];
  passthru = {
    inherit preprocessed outline liboutline;
  };
} ''
  bindgen ${liboutline}/include/outline.h -o $out --use-core --ctypes-prefix=c_types --with-derive-default --rust-target nightly -- -target ${rustTargetName} $NIX_CFLAGS_COMPILE
  sed -i 's,^    pub fn ${prefix}\([a-zA-Z_][a-zA-Z0-9_]*\)(,    #[link_name = "${prefix}\1"]\n    pub fn \1(,' $out
''
