{ lib, fetchgit, linux-ng
, linuxKernelUnifiedSource
}:

with linux-ng;

let

  source = linuxKernelUnifiedSource;

  # TODO
  # y crypto acceleration for net stack
  # n debug symbols
  # expert: n multiuser, n block

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
  };

in
doKernel rec {
  inherit source config;
  # modules = true;
  modules = false;
  dtbs = true;
}
