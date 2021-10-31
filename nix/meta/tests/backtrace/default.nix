{ mkInstance
, elfUtils, icecapSrc
}:

mkInstance { debug = true; } (self: with self.configured; with self; {

  composition = compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        test.image = elfUtils.split "${test}/bin/test.elf";
      };
    };
  };

  test = buildIceCapComponent {
    rootCrate = callPackage ./test/cargo.nix {};
    debug = true;
  };

})
