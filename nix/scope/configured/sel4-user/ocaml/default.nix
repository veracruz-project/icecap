{ lib, stdenv
, musl, libs, libsel4
, buildIceCapComponent, globalCrates, rustTargetName
}:

let
  rustTargetNameForEnv = lib.toUpper (lib.replaceStrings ["-"] ["_"] rustTargetName);

in {
  mkMirageBinary = mirageLibrary: buildIceCapComponent {

    rootCrate = globalCrates.mirage;

    extraLastLayer = attrs: {
      buildInputs = (attrs.buildInputs or []) ++ [
        libs.icecap-pure # TODO
        libs.icecap-mirage-glue
        musl
        mirageLibrary
      ];
      passthru = attrs.passthru // {
        inherit mirageLibrary;
      };

      # HACK
      # NOTE
      #   Affects fingerprints, so causes last layer to build too much.
      # TODO
      #   If must use this hack, use extraLastLayerCargoConfig instead, which is
      #   more composable. Env vars override instead of composing.
      "CARGO_TARGET_${rustTargetNameForEnv}_RUSTFLAGS" = lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
        "icecap-mirage-glue" "sel4asmrun" "mirage" "sel4asmrun" "icecap-mirage-glue" "c" "gcc"
      ] ++ [
        # TODO shouldn't be necessary
        "-C" (let cc = stdenv.cc.cc; in "link-arg=-L${cc}/lib/gcc/${cc.targetConfig}/${cc.version}")
      ];
    };
  };
}
