{ mkInstance
, icecapSrc
, icecapExternalSrc
}:

mkInstance { benchmark = true; } (self: with self.configured; with self; {

  composition = compose {
    # inherit (self) kernel;
    cdl = mkHypervisorIceDL {
      script = icecapSrc.absolute ./cdl.py;
      config = {
        components = {
          test.image = test.split;
          benchmark_server.image = hypervisorComponents.benchmark-server.split;
        };
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
