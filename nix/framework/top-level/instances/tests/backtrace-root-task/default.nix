{ mkInstance
, icecapSrc
, platUtils
}:

mkInstance { debug = true; } (self: with self.configured; with self; {

  composition = compose {
    app-elf = test.split;
  };

  test = buildIceCapComponent {
    rootCrate = callPackage ./test/crate.nix {};
    isRoot = true;
    debug = true;
  };

})
