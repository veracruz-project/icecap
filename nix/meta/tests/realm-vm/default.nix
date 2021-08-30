{ mkInstance
, deviceTree, bins
, compose, mkLinuxRealm
, icecapPlat
, emptyFile

, kernel, repos, linuxPkgs
}:

mkInstance (self: with self; {

  payload = linuxPkgs.icecap.uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = linuxPkgs.icecap.linuxKernel.host.${icecapPlat}.kernel;
    # linuxImage = ../../../../../local/linux/arch/arm64/boot/Image;
    # linuxImage = ../../../../../local/linux-rpi4/arch/arm64/boot/Image;
    initramfs = hostUser.config.build.initramfs;
    dtb = composition.host-dtb;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
    ];
  };

  spec = mkLinuxRealm {
    kernel = linuxPkgs.icecap.linuxKernel.guest.kernel;
    # kernel = ../../../../../local/linux/arch/arm64/boot/Image;
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "lamekaslr"
    ];
  };

  inherit (spec) ddl;

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

  hostUser = linuxPkgs.nixosLite.eval {
    modules = [
      (import ./host.nix {
        inherit icecapPlat spec;
      })
      includeHelpers
    ];
  };

  realmUser = linuxPkgs.nixosLite.eval {
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
