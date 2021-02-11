{ lib, writeText, writeScript
, linuxKernel
, icecapPlat
, icecapExtraConfig
, pkgs_linux
}:

with lib;
let

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
      linuxKernel.host.${icecapPlat}.kernel;

    nx = nixosLite.mk1Stage {
      modules = [
        ./host-1-stage.nix
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

}
