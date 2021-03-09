{ mkInstance
, deviceTree, bins, uBoot
, compose, mkIceDL, mkDynDLSpec
, icecapPlat
}:

mkInstance (self: with self; {

  linux = callPackage ./linux {};
  inherit (linux) host realm;

  ddl = mkIceDL {
    src = ./ddl;
    config = {
      components = {
        realm_vmm.image = bins.vmm.split;
        realm_vm.bootargs = realm.bootargs;
        realm_vm.kernel = realm.linuxImage;
        realm_vm.initrd = realm.initrd;
        realm_vm.dtb = deviceTree.guest.${icecapPlat};
      };
    };
  };

  spec = mkDynDLSpec {
    cdl = "${ddl}/icecap.cdl";
    root = "${ddl}/links";
  };

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  payload = uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = host.linuxImage;
    initramfs = host.initrd;
    dtb = composition.host-dtb;
    bootargs = host.bootargs;
  };

})

  # composition = compose {
  #   u-boot = /home/x/i/local/u-boot/u-boot.bin;
  # };
