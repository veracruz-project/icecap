{ mkInstance
, commonModules
, linuxPkgs

, withUtilization ? false
}:

mkInstance { benchmark = withUtilization; } (self: with self;

let
  inherit (configured) icecapPlat mkLinuxRealm;

  autostart = true;

in {

  payload = composition.mkDefaultPayload {
    kernel = linuxPkgs.icecap.linuxKernel.host.${icecapPlat}.kernel;
    initramfs = hostUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
    ];
  };

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  spec = mkLinuxRealm {
    kernel = linuxPkgs.icecap.linuxKernel.realm.minimal.kernel;
    initramfs = realmUser.config.build.initramfs;
    bootargs = commonBootargs;
  };

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=6"
  ];

  hostUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      commonModulesForInstance
      {
        instance.host.enable = true;
        instance.host.plat = icecapPlat;
      }
      ./host.nix
    ];
  };

  realmUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      commonModulesForInstance
      {
        instance.realm.enable = true;
        instance.hasNat = icecapPlat == "virt";
      }
      ./realm.nix
    ];
  };

  commonModulesForInstance = {
    imports = [
      ./common.nix
      {
        instance.autostart.enable = autostart;
      }
    ];
  };

})
