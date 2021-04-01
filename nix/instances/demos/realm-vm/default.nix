{ mkInstance
, deviceTree, bins, uBoot
, compose, mkLinuxRealm
, icecapPlat
}:

mkInstance (self: with self; {

  linux = callPackage ./linux {};
  inherit (linux) host realm;
  inherit (spec) ddl;

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

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

})
