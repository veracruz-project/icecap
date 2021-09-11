{ mkInstance
, elfUtils
}:

mkInstance { debug = true; } (self: with self.configured; with self; {

  composition = compose {
    src = ./cdl;
    config = {
      components = {
        test.image = elfUtils.split "${test}/bin/test.elf";
      };
    };
  };

  test = bins.mk null {
    rootCrate = callPackage ./test/cargo.nix {};
    debug = true;
  };

})
