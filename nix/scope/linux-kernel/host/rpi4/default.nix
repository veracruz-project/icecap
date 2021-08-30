{ lib, fetchgit, linux-ng
, linuxKernelUnifiedSource
, mkIceCapSrc
}:

with linux-ng;

let

  # source = linuxKernelUnifiedSource;
  source = doSource {
    version = "5.4.47";
    src = (mkIceCapSrc {
      repo = "linux";
      rev = "d681ecad8f55f5d6be411d410498ed5cf50ef546"; # branch: icecap-rpi4
    }).store;
  };

  # TODO
  #   configure for nf_tables (see virt defconfig)

  # config = makeConfig {
  #   inherit source;
  #   target = "bcm2711_defconfig";
  # };

  # LOCALVERSION=""
  # ICECAP=y

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
  };

in
doKernel rec {
  inherit source config;
  # modules = true;
  modules = false; # TODO
  dtbs = true;
}
