{ mkInstance
, deviceTree
, emptyFile
, linuxPkgs
}:

mkInstance {} (self: with self;

let
  inherit (self.configured) icecapPlat selectIceCapPlat compose kernel mkLinuxRealm bins;

  localLinuxImages = {
    virt = ../../../../../local/linux/arch/arm64/boot/Image;
    rpi4 = ../../../../../local/linux-rpi4/arch/arm64/boot/Image;
  };

in {

  payload = composition.mkDefaultPayload {
    linuxImage = linuxPkgs.icecap.linuxKernel.host.${icecapPlat}.kernel;
    # linuxImage = selectIceCapPlat localLinuxImages;
    initramfs = hostUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
      "kaslr.disclose=1"
    ];
  };

  spec = mkLinuxRealm {
    kernel = linuxPkgs.icecap.linuxKernel.realm.kernel;
    # kernel = localLinuxImages.virt;
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "kaslr.disclose=1"
      "kaslr.lame=1"
    ];
  };

  inherit (composition) cdl;
  inherit (spec) ddl;

  icecapPlatArgs.virt.devScript = true;
  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  c-helper = linuxPkgs.icecap.callPackage ./helpers/c-helper {};
  rust-helper = linuxPkgs.icecap.callPackage ./helpers/rust-helper {};

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
    "icecap_net.napi_weight=64" # global default
    # "icecap_net.napi_weight=128" # icecap default
    # "icecap_net.napi_weight=256"
  ];

  includeHelpers = { ... }: {
    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${c-helper}/bin/c-helper
      copy_bin_and_libs ${rust-helper}/bin/rust-helper
    '';
  };

  hostUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      (import ./host.nix {
        inherit icecapPlat spec;
      })
      includeHelpers
    ];
  };

  realmUser = linuxPkgs.icecap.nixosLite.eval {
    modules = [
      ./realm.nix
      includeHelpers
    ];
  };

  # composition = compose {
  #   kernel = kernel.override' (attrs: {
  #     source = attrs.source.override' (attrs': {
  #       src = with repos; local.seL4;
  #     });
  #   });
  # };

})
