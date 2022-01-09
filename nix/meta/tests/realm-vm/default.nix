{ mkTest
, commonModules
, linuxPkgs
}:

mkTest {} (self: with self;

let
  inherit (configured) icecapPlat selectIceCapPlat mkLinuxRealm;

  # NOTE example of how to develop on the linux kernel source
  localLinuxImages = {
    virt = ../../../../../local/linux/arch/arm64/boot/Image;
    rpi4 = ../../../../../local/linux-rpi4/arch/arm64/boot/Image;
  };

in {

  payload = composition.mkDefaultPayload {
    kernel = linuxPkgs.icecap.linuxKernel.host.${icecapPlat}.kernel;
    # kernel = selectIceCapPlat localLinuxImages;
    initramfs = hostUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
      "kaslr.disclose=1"
    ];
  };

  icecapPlatArgs.virt.devScript = true;
  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  spec = mkLinuxRealm {
    kernel = linuxPkgs.icecap.linuxKernel.realm.kernel;
    # kernel = localLinuxImages.virt;
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "kaslr.disclose=1"
      "kaslr.lame=1"
    ];
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
      includeHelpers
      ./host.nix
      {
        instance.plat = icecapPlat;
      }
    ];
  };

  realmUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      includeHelpers
      ./realm.nix
    ];
  };

  c-helper = linuxPkgs.icecap.callPackage ./helpers/c-helper {};
  rust-helper = linuxPkgs.icecap.callPackage ./helpers/rust-helper {};

  includeHelpers = { ... }: {
    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${c-helper}/bin/c-helper
      copy_bin_and_libs ${rust-helper}/bin/rust-helper
    '';
  };

})
