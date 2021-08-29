{ mkInstance
, icecapPlat
, mkMirageBinary, stripElfSplit
, mkDynDLSpec, mkIceDL
, linuxPkgs
}:

mkInstance (self: with self; {

  inherit (linux) host;

  linux = callPackage ./linux {};

  icecapPlatArgs.rpi4.extraBootPartitionCommands = ''
    ln -s ${spec} $out/spec.bin
  '';

  mirageLibrary = callPackage ./mirage.nix {};
  mirageBinary = mkMirageBinary mirageLibrary;

  ddl = mkIceDL {
    src = ./ddl;
    config = {
      components = {
        mirage.image = stripElfSplit "${mirageBinary}/bin/mirage.elf";
      };
    };
  };

  spec = mkDynDLSpec {
    cdl = "${ddl}/icecap.cdl";
    root = "${ddl}/links";
    extraPassthru = {
      inherit ddl;
    };
  };

  payload = linuxPkgs.icecap.uBoot.${icecapPlat}.mkDefaultPayload {
    linuxImage = host.linuxImage;
    initramfs = host.initrd;
    bootargs = host.bootargs;
    dtb = composition.host-dtb;
  };

})
