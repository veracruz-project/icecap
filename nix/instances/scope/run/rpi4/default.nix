{ lib, runCommand
, rpi4Utils
, icecapPlat
, icecap-show-backtrace
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
  } // lib.mapAttrs' (k: lib.nameValuePair "debug/${k}") ({
      icecap-show-backtrace = "${icecap-show-backtrace.nativeDrv}/bin/show-backtrace";
    } // composition.debugFiles // lib.optionalAttrs allDebugFiles composition.cdlDebugFiles
  ) // extraLinks;

in
runCommand "run" {
  passthru = {
    inherit boot;
  };
} ''
  mkdir $out
  ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
    mkdir -p $out/$(dirname ${k})
    ln -s ${v} $out/${k}
  '') links)}
''
