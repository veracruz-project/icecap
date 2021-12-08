{ mkInstance
, emptyFile
, linuxPkgs
, icecapExternalSrc
, elfUtils, icecapSrc
}:

mkInstance { benchmark = true; } (self: with self.configured; with self; {

  composition = compose {
    # inherit (self) kernel;
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        test.image = elfUtils.split "${test}/bin/test.elf";
        benchmark_server.image = bins.benchmark-server.split;
      };
    };
  };

  test = buildIceCapComponent {
    rootCrate = callPackage ./test/cargo.nix {};
    debug = true;
  };

  # kernel = configured.kernel.override' {
  #   source = icecapExternalSrc.seL4.forceLocal;
  # };

})
