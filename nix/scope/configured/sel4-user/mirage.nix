{ lib
, libs, musl, liboutline, stdenv
, buildIceCapCrate, crateUtils, globalCrates
}:

{

  mkMirageBinary = mirageLibrary:
    buildIceCapCrate {
      rootCrate = globalCrates.mirage;
      extraLayers = [ [ globalCrates.icecap-std ] ];
      extraManifest = {
        profile.release = {
          codegen-units = 1;
          opt-level = 3;
          lto = true;
        };
      };
      extraLastLayer = attrs: {
        buildInputs = (attrs.buildInputs or []) ++ (with libs; [
          icecap-autoconf
          icecap-runtime
          icecap-utils icecap-pure # TODO
          icecap-mirage-glue
          musl
          mirageLibrary
        ]);
      };
      extra = attrs: {
        buildInputs = (attrs.buildInputs or []) ++ [
          liboutline
        ];
        passthru = attrs.passthru // {
          inherit mirageLibrary;
        };
      };
      # HACK
      # extraLastLayer = {
      #   RUSTFLAGS = lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
      #     "icecap_mirage_glue" "sel4asmrun" "mirage" "sel4asmrun" "icecap_mirage_glue" "c" "gcc"
      #     "icecap_utils" # HACK
      #   ];
      # };
    };

}
