{ linux-ng
, linuxKernelRpi4Source
, runCommand, diffutils
}:

with linux-ng;

let

  source = linuxKernelRpi4Source;

  # TODO
  #   configure for nf_tables (see virt defconfig)

  configBase = makeConfig {
    inherit source;
    target = "bcm2711_defconfig";
  };

  # CONFIG_LOCALVERSION=""
  # CONFIG_ICECAP=y
  # CONFIG_TUN=y

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = ./defconfig;
  };

  configDiff = runCommand "diff" {
    nativeBuildInputs = [ diffutils ];
  } ''
    diff ${configBase} ${config} > $out || true
  '';

  defconfigDiff = runCommand "diff" {
    nativeBuildInputs = [ diffutils ];
  } ''
    diff ${source}/arch/arm64/configs/bcm2711_defconfig ${./defconfig} > $out || true
  '';

in
doKernel rec {
  inherit source config;
  modules = false; # TODO
  dtbs = true;
  passthru = {
    inherit configDiff defconfigDiff;
  };
}
