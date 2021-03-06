{ mkInstance
, commonModules
, linuxPkgs
, icecapSrc, icecapExternalSrc
}:

mkInstance {} (self: with self;

let
  inherit (configured) icecapPlat selectIceCapPlat mkLinuxRealm;

  # NOTE example of how to develop on the linux kernel source
  localLinuxImages = {
    virt = icecapSrc.localPathOf "linux/arch/arm64/boot/Image";
    rpi4 = icecapSrc.localPathOf "linux-rpi4/arch/arm64/boot/Image";
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
    kernel = linuxPkgs.icecap.linuxKernel.realm.minimal.kernel;
    # kernel = linuxPkgs.icecap.linuxKernel.host.${icecapPlat}.kernel; # TODO why is this failing?
    # kernel = localLinuxImages.virt;
    initramfs = realmUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "kaslr.disclose=1"
      "kaslr.lame=1"
    ];
  };

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=8"
  ];

  hostUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      includeHelpers
      ./host.nix
      {
        instance.host.enable = true;
        instance.host.plat = icecapPlat;
      }
    ];
  };

  realmUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      commonModules
      includeHelpers
      ./realm.nix
      {
        instance.realm.enable = true;
      }
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

  # NOTE example of how to develop on the seL4 kernel source

  # kernel = configured.kernel.override' {
  #   source = icecapExternalSrc.seL4.forceLocal;
  # };

  # composition = configured.icecapFirmware.override' {
  #   inherit (self) kernel;
  # };

})
