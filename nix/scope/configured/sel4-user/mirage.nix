{ lib, icecapSrcRelSplit
, libs, muslc, liboutline, stdenv
, buildIceCapCrateBin, crateUtils, globalCrates
}:

{

  mkMirageBinary = mirageLibrary:
    buildIceCapCrateBin {
      rootCrate = globalCrates.mirage;
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
      extraPassthru = {
        inherit mirageLibrary;
      };
    };

}
