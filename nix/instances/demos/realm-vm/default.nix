{ mkInstance
, deviceTree, bins, uBoot
, compose, mkLinuxRealm
, icecapPlat
, emptyFile

, kernel, repos
}:

mkInstance (self: with self; {

  linux = callPackage ./linux {};
  inherit (linux) host realm;
  inherit (spec) ddl;

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  # spec = host.linuxImage;
  spec = mkLinuxRealm {
    bootargs = realm.bootargs;
    kernel = realm.linuxImage;
    initrd = realm.initrd;
  };

  payload = uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = host.linuxImage;
    initramfs = host.initrd;
    bootargs = host.bootargs;
    dtb = composition.host-dtb;
  };

  # composition = compose {
  #   kernel = kernel.override' (attrs: {
  #     source = attrs.source.override' (attrs': {
  #       src = with repos; local.seL4;
  #     });
  #   });
  # };

})
