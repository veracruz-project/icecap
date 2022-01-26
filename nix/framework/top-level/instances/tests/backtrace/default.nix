{ mkInstance
, icecapSrc
}:

mkInstance { debug = true; } (self: with self.configured; with self; {

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
  };

})
