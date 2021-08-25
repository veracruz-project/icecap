{ mkInstance
, deviceTree, bins, uBoot
, compose, mkLinuxRealm
, icecapPlat
, emptyFile
, linuxKernel

, kernel, repos, pkgs_linux
}:

mkInstance (self: with self; {

  payload = uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = linuxKernel.host.${icecapPlat}.kernel;
    # linuxImage = ../../../../../../local/linux/arch/arm64/boot/Image;
    # linuxImage = ../../../../../../local/linux-rpi4/arch/arm64/boot/Image;
    initramfs = hostUser.config.build.initramfs;
    dtb = composition.host-dtb;
    bootargs = commonBootargs ++ [
      "spec=${spec}"
    ];
  };

  spec = mkLinuxRealm {
    kernel = linuxKernel.guest.kernel;
    # kernel = ../../../../../../local/linux/arch/arm64/boot/Image;
    initrd = realmUser.config.build.initramfs;
    bootargs = commonBootargs ++ [
      "lamekaslr"
    ];
  };

  inherit (spec) ddl;

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  c-helper = pkgs_linux.icecap.callPackage ./helpers/c-helper {};
  rust-helper = pkgs_linux.icecap.callPackage ./helpers/rust-helper {};

  commonBootargs = [
    "earlycon=icecap_vmm"
    "console=hvc0"
    "loglevel=7"
    # "icecap_net.napi_weight=128" # default
    "icecap_net.napi_weight=256"
  ];

  includeHelpers = { ... }: {
    initramfs.extraUtilsCommands = ''
      copy_bin_and_libs ${c-helper}/bin/c-helper
      copy_bin_and_libs ${rust-helper}/bin/rust-helper
    '';
  };

  hostUser = pkgs_linux.nixosLite.mk1Stage {
    modules = [
      (import ./host.nix {
        inherit icecapPlat spec;
      })
      includeHelpers
    ];
  };

  realmUser = pkgs_linux.nixosLite.mk1Stage {
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
