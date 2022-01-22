{ runCommand
, linuxHelpers
, icecapSrc, icecapExternalSrc
, diffutils
}:

with linuxHelpers.linux;

let

  source = icecapExternalSrc.linux.rpi4;

  configBase = makeConfig {
    inherit source;
    target = "bcm2711_defconfig";
  };

  # CONFIG_LOCALVERSION=""
  # CONFIG_ICECAP=y
  # CONFIG_TUN=y

  # TODO configure for nf_tables (see virt defconfig)

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/hypervisor/host/rpi4/linux.defconfig";
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
buildKernel rec {
  inherit source config;
  modules = false; # TODO
  dtbs = true;
  passthru = {
    inherit configDiff defconfigDiff;
  };
}
