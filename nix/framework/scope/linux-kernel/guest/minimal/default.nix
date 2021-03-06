{ icecapSrc, icecapExternalSrc
, linuxHelpers
}:

with linuxHelpers.linux;

let

  source = icecapExternalSrc.linux.unified;

  # TODO crypto acceleration <- y for net stack

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/framework/guest/minimal/linux.defconfig";
  };

in
buildKernel rec {
  inherit source config;
  modules = false;
  dtbs = false;
}
