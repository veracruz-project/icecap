{ mkInstance
, emptyFile
, linuxPkgs
, seL4EcosystemRepos
, elfUtils
}:

mkInstance { benchmark = true; } (self: with self.configured; with self; {

  composition = compose {
    # inherit (self) kernel;
    src = ./cdl;
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
  #   source = seL4EcosystemRepos.seL4.forceLocal;
  # };

})
