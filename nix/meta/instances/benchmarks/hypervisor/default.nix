{ mkInstance
, commonModules
, linuxPkgs

, withUtilization ? false
}:

mkInstance { benchmark = withUtilization; } (self: with self;

let
  inherit (configured) icecapPlat mkLinuxRealm;

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
    kernel = linuxPkgs.icecap.linuxKernel.realm.kernel;
    initramfs = realmUser.config.build.initramfs;
    bootargs = commonBootargs;
  };

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
    "icecap_net.napi_weight=64" # global default
    # "icecap_net.napi_weight=128" # icecap default
    # "icecap_net.napi_weight=256"
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
      }
      ./realm.nix
    ];
  };

  commonModulesForInstance = {
    imports = [
      ./common.nix
      {
        instance.utlization.enable = withUtilization;
      }
    ];
  };

})
