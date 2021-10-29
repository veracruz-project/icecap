{ lib, stdenv
, musl, libs, libsel4
, buildIceCapCrate, globalCrates
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
        buildInputs = (attrs.buildInputs or []) ++ [
          libsel4
          libs.icecap-autoconf
          libs.icecap-runtime
          libs.icecap-utils
          libs.icecap-pure # TODO
          libs.icecap-mirage-glue
          musl
          mirageLibrary
        ];
        passthru = attrs.passthru // {
          inherit mirageLibrary;
        };

        # HACK
        # NOTE affects fingerprints, so causes last layer to build too much.
        RUSTFLAGS = lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
          "icecap_mirage_glue" "sel4asmrun" "mirage" "sel4asmrun" "icecap_mirage_glue" "c" "gcc"
        ] ++ [
          # TODO shouldn't be necessary
          "-C" (let cc = stdenv.cc.cc; in "link-arg=-L${cc}/lib/gcc/${cc.targetConfig}/${cc.version}")
        ];
      };
    };

}
