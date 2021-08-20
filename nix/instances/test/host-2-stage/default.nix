{ mkInstance
, icecapPlat
, mkLinuxRealm
, uBoot, linuxKernel
, pkgs_linux
}:

mkInstance (self: with self; {

  payload = uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = linuxKernel.host.${icecapPlat}.kernel;
    initramfs = userland.config.build.initramfs;
    bootargs = [
      "earlycon=icecap_vmm"
      "console=hvc0"
      "loglevel=7"
      "init=${userland.config.build.nextInit}"
    ];
    dtb = composition.host-dtb;
  };

  userland = pkgs_linux.nixosLite.mk2Stage {
    modules = [
      ./host.nix
      {
        icecap.plat = icecapPlat;
        rpi4._9p = {
          port = icecapExtraConfig.net.rpi4.p9.port;
          addr = icecapExtraConfig.net.rpi4.p9.addr;
        };
      }
    ];
  };

})
