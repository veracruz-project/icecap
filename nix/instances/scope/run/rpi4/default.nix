{ lib, runCommand
, rpi4Utils
, icecap-show-backtrace
, icecapPlat
}:

{ composition, payload, extraLinks ? {}, icecapPlatArgs ? {}, allDebugFiles }:

with (
  { extraBootPartitionCommands ? "" }:
  { inherit extraBootPartitionCommands; }
) (icecapPlatArgs.${icecapPlat} or {});

let

  inherit (composition) image;

  boot = rpi4Utils.bootPartitionLinks {
    inherit image payload extraBootPartitionCommands;
  };

  links = {
    inherit boot;
    "icecap-show-backtrace" = "${icecap-show-backtrace.nativeDrv}/bin/show-backtrace";
  } // composition.debugFiles
    // lib.optionalAttrs allDebugFiles composition.cdlDebugFiles
    // extraLinks;

in
runCommand "run" {
  passthru = {
    inherit boot;
  };
} ''
  mkdir $out
  ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
    ln -s ${v} $out/${k}
  '') links)}
''
