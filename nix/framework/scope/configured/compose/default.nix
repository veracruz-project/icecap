{ lib, runCommand
, callPackage
, platUtils, cpioUtils, elfUtils
, icecapPlat
, mkIceDL, mkCapDLLoader
, kernel, elfloader
}:

args:

let

  attrs = lib.fix (self: {

    loader-elf = elfUtils.split "${self.loader}/boot/elfloader";

    loader = elfloader {
      inherit (self) kernel;
      app-elf = self.app-elf.min;
    };

    inherit kernel;

    app-elf = elfUtils.split "${self.app}/bin/capdl-loader.elf";

    app = mkCapDLLoader {
      cdl = "${self.cdl}/icecap.cdl";
      elfs-cpio = cpioUtils.mkFrom "${self.cdl}/links";
    };

    script = null;
    config = null;

    cdl = mkIceDL {
      inherit (self) config script;
    };

    extra = _self: {};

  } // args);

  bootImages = {
    loader = attrs.loader-elf;
    kernel = attrs.kernel.elf;
    app = attrs.app-elf;
  };

  cdlImages = lib.mapAttrs'
    (k: v: lib.nameValuePair k v.image)
    (lib.filterAttrs (k: lib.hasAttr "image") attrs.cdl.config.components);

in lib.fix (self: with self; {
  inherit attrs;
  inherit (attrs) cdl;

  image = attrs.loader-elf.min;

  inherit bootImages cdlImages;

  display = callPackage ./display.nix {
    composition = self;
  };
} // attrs.extra self)
