{ lib, fetchgit, linux-ng
, linuxKernelUnifiedSource
}:

with linux-ng;

let

  # source = linuxKernelUnifiedSource;

  source = doSource {
    version = "5.3.18";
    src = builtins.fetchGit {
      url = https://kernel.googlesource.com/pub/scm/linux/kernel/git/stable/linux.git;
      ref = "linux-5.3.y";
      rev = "d4f3318ed8fab6316cb7a269b8f42306632a3876";
    };
  };

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
    # allconfig = ./defconfig.old;
  };

in
doKernel rec {
  inherit source config;
  # modules = true;
  modules = false;
  dtbs = false;
  # dtbs = true;
}
