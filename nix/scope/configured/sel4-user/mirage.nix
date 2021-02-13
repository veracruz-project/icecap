{ lib, icecapSrcRelSplit
, libs, muslc, liboutline, stdenv
, buildIceCapCrateBin, crateUtils, globalCrates
}:

{

  mkMirageBinary = mirageLibrary:
    buildIceCapCrateBin {
      rootCrate = crateUtils.mkGeneric {
        name = "mirage";
        src = icecapSrcRelSplit "rust/components/mirage";
        isBin = true;
        deps = with globalCrates; [
          icecap-linux-syscall
          icecap-std
        ];
        dependencies = {
          serde = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
        };
        buildScript = {
          # doesn't work because of circular dependencies. rustc deduplicates these
          # rustc-link-lib = [
          #   "icecap_mirage_glue" "mirage" "sel4asmrun" "c" "gcc"
          # ];
          rustc-link-search = [
            (let cc = stdenv.cc.cc; in "${cc}/lib/gcc/${cc.targetConfig}/${cc.version}") # TODO shouldn't be necessary
          ];
        };
      };
      extraLayers = [ [ "icecap-std" ] ];
      # HACK (see above)
      RUSTFLAGS = lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
        "icecap_mirage_glue" "sel4asmrun" "mirage" "sel4asmrun" "icecap_mirage_glue" "c" "gcc"
        "icecap_utils" # HACK
      ];
      buildInputs = [
        liboutline
      ];
      extraLastLayerBuildInputs = with libs; [
        icecap-autoconf
        icecap-runtime
        icecap-utils icecap-pure # TODO
        icecap-mirage-glue
        muslc
        mirageLibrary
      ];
    };

}
