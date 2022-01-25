{ runCommand
, icecapSrc, icecapExternalSrc
, linuxHelpers
, diffutils
}:

with linuxHelpers.linux;

let

  source = icecapExternalSrc.linux.unified;

  configBase = makeConfig {
    inherit source;
    target = "defconfig";
  };

  # CONFIG_ICECAP=y
  # CONFIG_LOCALVERSION_AUTO=n
  # CONFIG_IPV6=y
  # CONFIG_NF_TABLES
  # CONFIG_NF_TABLES_INET
  # CONFIG_NF_CONNTRACK=y
  # CONFIG_NFT_NAT=y
  # CONFIG_NFT_MASQ=y

  # may be useful:
  # CONFIG_SCHEDSTATS=y

  # do we need to add this?
  # CONFIG_PM_DEVFREQ=y

  # do we need to add this?
  # CONFIG_CRYPTO_USER_API_HASH=y

  # config = configBase;

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    allconfig = icecapSrc.relative "support/hypervisor/host/virt/linux.defconfig";
  };

  configDiff = runCommand "diff" {
    nativeBuildInputs = [ diffutils ];
  } ''
    diff ${configBase} ${config} > $out || true
  '';

  defconfigDiff = runCommand "diff" {
    nativeBuildInputs = [ diffutils ];
  } ''
    diff ${source}/arch/arm64/configs/defconfig ${./defconfig} > $out || true
  '';

in
buildKernel rec {
  inherit source config;
  modules = false;
  dtbs = true;
  passthru = {
    inherit configDiff defconfigDiff;
  };
}
