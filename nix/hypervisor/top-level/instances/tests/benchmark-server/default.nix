{ mkInstance
, icecapSrc
, icecapExternalSrc
, icecap-serialize-builtin-config
}:

mkInstance { benchmark = true; } (self: with self.configured; with self; {

  composition = compose {
    # inherit (self) kernel;
    script = icecapSrc.absolute ./cdl.py;
    config = {
      components = {
        test.image = test.split;
        benchmark_server.image = hypervisorComponents.benchmark-server.split;
      };
    };

    extraNativeBuildInputs = [
      icecap-serialize-builtin-config
    ];
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
