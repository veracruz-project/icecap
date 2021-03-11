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

  extraLinks = {};
  icecapPlatArgs = {};

  run = mkRun ({
    inherit composition payload allDebugFiles;
    inherit extraLinks icecapPlatArgs;
  });

} // attrs
