{ mkTest
, icecapSrc
, icecapExternalSrc
}:

mkTest { benchmark = true; } (self: with self.configured; with self; {

  composition = compose {
    # inherit (self) kernel;
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        test.image = test.split;
        benchmark_server.image = bins.benchmark-server.split;
      };
    };
  };

  test = buildIceCapComponent {
    rootCrate = callPackage ./test/crate.nix {};
    debug = true;
  };

  # NOTE example of how to develop on the seL4 kernel source
  # kernel = configured.kernel.override' {
  #   source = icecapExternalSrc.seL4.forceLocal;
  # };

})
