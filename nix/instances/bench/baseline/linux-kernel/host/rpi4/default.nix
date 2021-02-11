{ lib, fetchgit, linux-ng
, linuxKernelUnifiedSource
}:

with linux-ng;

let

  # source = linuxKernelUnifiedSource;

  source = doSource {
    version = "5.3.18";
    src = builtins.fetchGit {
      url = https://github.com/raspberrypi/linux;
      ref = "rpi-5.3.y";
      rev = "32ba05a62a8071d091d7582cc37b4bac2962b1dd";
    };
    patches = with kernelPatches; [
      scriptconfig
    ];
  };

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
