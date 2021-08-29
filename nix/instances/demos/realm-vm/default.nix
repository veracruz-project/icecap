{ mkInstance
, icecapPlat
, mkLinuxRealm
, pkgs_linux
}:

mkInstance (self: with self; {

  inherit (linux) host realm;
  inherit (spec) ddl;

  linux = callPackage ./linux {};

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  spec = mkLinuxRealm {
    bootargs = realm.bootargs;
    kernel = realm.linuxImage;
    initrd = realm.initrd;
  };

  payload = pkgs_linux.icecap.uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = host.linuxImage;
    initramfs = host.initrd;
    bootargs = host.bootargs;
    dtb = composition.host-dtb;
  };

})
