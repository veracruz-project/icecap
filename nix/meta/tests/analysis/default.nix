{ mkInstance
, deviceTree, bins
, compose, mkLinuxRealm
, icecapPlat
, emptyFile

, kernel, linuxPkgs
}:

mkInstance { benchmark = true; } (self: with self; {

  payload = composition.mkDefaultPayload {
    linuxImage = linuxPkgs.icecap.linuxKernel.host.${icecapPlat}.kernel;
    initramfs = hostUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
    ];
  };

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  spec = mkLinuxRealm {
    kernel = linuxPkgs.icecap.linuxKernel.guest.kernel;
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs;
  };

  inherit (spec) ddl;

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
  ];

  hostUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      ./host.nix
      {
        instance.plat = icecapPlat;
        instance.spec = spec;
      }
    ];
  };

  realmUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      ./realm.nix
    ];
  };

})
