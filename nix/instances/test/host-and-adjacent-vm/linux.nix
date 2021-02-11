{ lib, writeText, writeScript
, linuxKernel
, icecapPlat
, icecapExtraConfig
, pkgs_linux
}:

with lib;
let

  # TODO adjust cpu freq at boot on rpi4

  # Configurable:
  useLocalLinuxImages = false;

  pkgs = pkgs_linux;
  inherit (pkgs_linux) nixosLite;

in rec {

  bootargs_common = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
    # "boot.shell_on_fail"
    # "boot.trace"
  ];

  host = rec {
    role = "host";
    bootargs = bootargs_common;
    # bootargs = bootargs_common ++ [
    #   "init=${nx.config.build.nextInit}"
    # ];
    initrd = nx.config.build.initramfs;
    linuxImage =
      # ../../../../../../local/linux/arch/arm64/boot/Image;
      if useLocalLinuxImages
      then localLinuxImages.${icecapPlat}
      else linuxKernel.host.${icecapPlat}.kernel;

    nx = nixosLite.mk1Stage {
      modules = [
        (import ./host-1-stage.nix {
          inherit icecapPlat;
        })
      ];
    };

    # nx = nixosLite.mk2Stage {
    #   modules = [
    #     ./host.nix
    #     {
    #       icecap.plat = icecapPlat;
    #       rpi4._9p = {
    #         port = icecapExtraConfig.net.rpi4.p9.port;
    #         addr = icecapExtraConfig.net.rpi4.p9.addr;
    #       };
    #     }
    #   ];
    # };

  };

  guest = rec {
    role = "guest";
    bootargs = bootargs_common;
    initrd = nx.config.build.initramfs;
    linuxImage =
      if useLocalLinuxImages
      then localLinuxImages.virt
      else linuxKernel.guest.kernel;

    nx = nixosLite.mk1Stage {
      modules = [
        ./guest.nix
        {
          # initramfs.profile = ''
          #   mt() {
          #     mkdir -p mnt
          #     mount -t nfs -o nolock,ro ${icecapExtraConfig.nfs_dev} mnt
          #   }
          # '';
        }
      ];
    };
  };

  # localLinuxImages = {
  #   virt = ../../../../../../local/linux/arch/arm64/boot/Image;
  #   rpi4 = ../../../../../../local/linux-rpi/arch/arm64/boot/Image;
  # };

}
