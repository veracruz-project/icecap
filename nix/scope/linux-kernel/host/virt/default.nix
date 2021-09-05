{ linux-ng
, linuxKernelUnifiedSource
}:

with linux-ng;

let

  source = linuxKernelUnifiedSource;

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
    allconfig = ./defconfig;
  };

in
doKernel rec {
  inherit source config;
  modules = false;
  dtbs = true;
}
