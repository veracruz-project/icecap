{ mkTest
, commonModules
, linuxPkgs
, icecapExternalSrc
}:

mkTest { benchmark = true; } (self: with self;

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
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs;
  };

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
  ];

  hostUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      ./host.nix
      {
        instance.plat = icecapPlat;
      }
    ];
  };

  realmUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      ./realm.nix
    ];
  };

  # NOTE example of how to develop on the seL4 kernel source

  # kernel = configured.kernel.override' {
  #   source = icecapExternalSrc.seL4.forceLocal;
  # };

  # composition = configured.icecapFirmware.override' {
  #   inherit (self) kernel;
  # };

})
