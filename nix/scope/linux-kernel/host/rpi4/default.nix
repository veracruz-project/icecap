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
      rev = "d964307a898cad77fc766e87f4f0a68b06ebfe2a"; # branch: icecap-rpi-5.4 (TODO sync with branch "icecap")
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
