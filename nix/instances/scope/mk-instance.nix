{ lib, mkRun
, icecapFirmware
}:

f: self:

let
  attrs = f self;
in

with self; {

  composition = icecapFirmware;
  payload = {};
  allDebugFiles = true;

  run = mkRun ({
    inherit composition payload allDebugFiles;
  } // lib.optionalAttrs (lib.hasAttr "extraLinks" attrs) {
    inherit (attrs) extraLinks;
  } // lib.optionalAttrs (lib.hasAttr "icecapPlatArgs" attrs) {
    inherit (attrs) icecapPlatArgs;
  });

} // attrs
