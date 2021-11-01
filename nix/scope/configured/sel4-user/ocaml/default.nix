{ lib, stdenv
, musl, libs, libsel4
, buildIceCapComponent, globalCrates
}:

{
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
      # NOTE affects fingerprints, so causes last layer to build too much.
      RUSTFLAGS = lib.concatMap (x: [ "-C" "link-arg=-l${x}" ]) [
        "icecap-mirage-glue" "sel4asmrun" "mirage" "sel4asmrun" "icecap-mirage-glue" "c" "gcc"
      ] ++ [
        # TODO shouldn't be necessary
        "-C" (let cc = stdenv.cc.cc; in "link-arg=-L${cc}/lib/gcc/${cc.targetConfig}/${cc.version}")
      ];
    };
  };
}
