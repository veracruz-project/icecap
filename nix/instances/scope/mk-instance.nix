{ lib, mkRun
, mkCapDLLoader, mkCpioFrom
, mkIceDL
}:

f: self:

let
  attrs = f self;
in

with self; {

  loader = mkCapDLLoader {
    cdl = "${cdl}/icecap.cdl";
    elfs-cpio = mkCpioFrom "${cdl}/links";
  };

  payload = "${loader}/bin/capdl-loader.elf";

  run = mkRun ({
    inherit (self) payload;
    extraLinks =
      lib.optionalAttrs
        (attrs ? "config")
        (lib.mapAttrs'
          (k: v: lib.nameValuePair "${k}.elf" v.image.full)
          (lib.filterAttrs (k: lib.hasAttr "image") attrs.config.components))
      // attrs.extraLinks or {};
  } // lib.optionalAttrs (lib.hasAttr "kernel" attrs) {
    inherit (attrs) kernel;
  } // lib.optionalAttrs (lib.hasAttr "icecapPlatArgs" attrs) {
    inherit (attrs) icecapPlatArgs;
  });

  cdl = mkIceDL {
    inherit (attrs) config src;
  };

} // attrs
