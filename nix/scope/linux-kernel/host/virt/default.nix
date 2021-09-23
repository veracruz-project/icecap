{ linux-ng
, linuxKernelUnifiedSource
, runCommand, diffutils
}:

with linux-ng;

let

  source = linuxKernelUnifiedSource;

  configBase = makeConfig {
    inherit source;
    target = "defconfig";
  };

  # CONFIG_ICECAP=y
  # CONFIG_TMPFS_POSIX_ACL=y
  # CONFIG_CRYPTO_USER_API_HASH=m
  # CONFIG_NETFILTER_XT_MATCH_BPF=m
  # CONFIG_IP_NF_IPTABLES=y

  # CONFIG_NF_CONNTRACK_FTP
  # CONFIG_NF_NAT_FTP
  # ...

  # TODO
  # CONFIG_LOCALVERSION_AUTO=n

  config = makeConfig {
    inherit source;
    target = "alldefconfig";
    # TODO reduce
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
    diff ${source}/arch/arm64/configs/defconfig ${./defconfig} > $out || true
  '';

in
doKernel rec {
  inherit source config;
  modules = false;
  dtbs = true;
  passthru = {
    inherit configDiff defconfigDiff;
  };
}
