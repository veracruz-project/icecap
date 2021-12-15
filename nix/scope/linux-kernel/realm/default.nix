{ icecapSrc, icecapExternalSrc
, linux-ng
}:

with linux-ng;

let

  source = icecapExternalSrc.linux.unified;

  # TODO crypto acceleration <- y for net stack

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/hypervisor/realm/linux.defconfig";
  };

in
doKernel rec {
  inherit source config;
  modules = false;
  dtbs = false;
}
