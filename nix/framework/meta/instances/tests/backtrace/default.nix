{ mkInstance
, icecapSrc
}:

mkInstance { debug = true; } (self: with self.configured; with self; {

  composition = compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        test.image = test.split;
      };
    };
  };

  test = buildIceCapComponent {
    rootCrate = callPackage ./test/crate.nix {};
    debug = true;
  };

})
