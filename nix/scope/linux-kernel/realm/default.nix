{ icecapSrc
, linux-ng
, linuxKernelUnifiedSource
}:

with linux-ng;

let

  source = linuxKernelUnifiedSource;

  # TODO crypto acceleration <- y for net stack

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/realm/linux.defconfig";
  };

in
doKernel rec {
  inherit source config;
  modules = false;
  dtbs = false;
}
