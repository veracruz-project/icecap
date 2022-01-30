{ mkInstance
, icecapSrc
, rustTargetName
}:

mkInstance {} (self: with self.configured; with self; {

  composition = compose {
    script = icecapSrc.absolute ./cdl.py;
    config = {
      components = {
        test.image = test.split;
      };
    };
  };

  test = buildIceCapComponent {
    rootCrate = callPackage ./test/crate.nix {};
    debug = true;
    modifyExtraCargoConfig = config: config // {
      target.${rustTargetName}.rustflags = (config.target.${rustTargetName}.rustflags or []) ++ [
        "--sysroot" configured.sysroot-rs
        "-C" "link-arg=-licecap-some-libc"
      ];
    };
    modifyExtra = attrs: attrs // {
      buildInputs = (attrs.buildInputs or []) ++ [
        configured.userC.nonRootLibs.icecap-some-libc
      ];
    };
  };

})
