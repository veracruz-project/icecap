{ linux-ng
, linuxKernelRpi4Source
}:

with linux-ng;

let

  source = linuxKernelRpi4Source;

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
  modules = false; # TODO
  dtbs = true;
}
