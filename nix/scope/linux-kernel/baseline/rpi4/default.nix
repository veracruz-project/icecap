{ lib, fetchgit, linux-ng
, linuxKernelUnifiedSource
, mkIceCapSrc
}:

with linux-ng;

let

  # source = linuxKernelUnifiedSource;
  # source = doSource {
  #   version = "5.4.47";
  #   src = (mkIceCapSrc {
  #     repo = "linux";
  #     rev = "dec0ddc506ab5d93a7de4b8a7c8dc98e0a96f85c"; # branch: icecap-rpi-5.4 (TODO sync with branch "icecap")
  #   }).store;
  # };

  # source = doSource {
  #   version = "5.10.60";
  #   src = builtins.fetchGit {
  #     url = "https://github.com/raspberrypi/linux";
  #     ref = "rpi-5.10.y";
  #     rev = "2dd846fe1a7266153e129b55c01b6ac59119d395";
  #   };
  # };

  source = doSource {
    version = "5.4.83";
    src = builtins.fetchGit {
      url = "https://github.com/raspberrypi/linux";
      ref = "rpi-5.4.y";
      rev = "ec0dcf3064b8ba99f226438214407fcea9870f76";
    };
  };

  # TODO
  #   configure for nf_tables (see virt defconfig)

  defconfig = makeConfig {
    inherit source;
    target = "bcm2711_defconfig";
  };

  config = modifyConfig {
    inherit source;
    config = defconfig;
    args = [ "--set-str" "CONFIG_LOCALVERSION" "''" ];
  };

in
doKernel rec {
  inherit source config;
  # modules = true;
  modules = false; # TODO
  dtbs = true;
  passthru = {
    inherit defconfig config;
  };
}
