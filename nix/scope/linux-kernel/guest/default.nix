{ lib, fetchgit, linux-ng
, linuxKernelUnifiedSource
}:

with linux-ng;

let

  source = linuxKernelUnifiedSource;

  # TODO
  # y crypto acceleration for net stack

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
  };

in
doKernel rec {
  inherit source config;
  modules = false;
  dtbs = false;
}
