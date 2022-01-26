{ lib, runCommand
, callPackage
, platUtils, cpioUtils, elfUtils
, icecapPlat
, mkIceDL, mkCapDLLoader
, kernel, elfloader
}:

args:

let

  components = lib.fix (self: {

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

    cdl = mkIceDL {
      inherit (self) action config extraNativeBuildInputs;
    };

    extraNativeBuildInputs = [];

    extra = _self: {};

  } // args);

in with components;
let

  images = {
    loader = components.loader-elf;
    kernel = components.kernel.elf;
    app = components.app-elf;
  };

  cdlImages = lib.mapAttrs'
    (k: v: lib.nameValuePair k v.image)
    (lib.filterAttrs (k: lib.hasAttr "image") components.config.components);

  debugFilesOf = lib.mapAttrs' (k: v: lib.nameValuePair "${k}.elf" v.full);

  debugLinksOf = files: runCommand "links" {} ''
    mkdir $out
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        ln -s ${v} $out/${k}
    '') files)}
  '';

in lib.fix (self: with self; {
  inherit components;
  inherit (components) cdl app loader;

  image = loader-elf.min;

  inherit images cdlImages;

  debugFiles = debugFilesOf images;
  debugLinks = debugLinksOf debugFiles;
  cdlDebugFiles = debugFilesOf cdlImages;
  cdlDebugLinks = debugLinksOf cdlDebugFiles;
  allDebugFiles = debugFilesOf (cdlImages // images);
  allDebugLinks = debugLinksOf allDebugFiles;

  display = callPackage ./display.nix {
    composition = self;
  };
} // components.extra self)
