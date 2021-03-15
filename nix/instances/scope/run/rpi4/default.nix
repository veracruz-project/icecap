{ lib, writeScript, runCommand, runPkgs
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

  syncSimple = src: writeScript "sync" ''
    #!${runPkgs.runtimeShell}
    set -e

    # if [ -z "$1" ]; then
    #   echo "usage: $0 DEV" >&2
    #   exit 1
    # fi

    # dev="$1"

    dev=/dev/disk/by-label/icecap-boot

    mkdir -p mnt
    sudo mount $dev ./mnt
    sudo rm -r ./mnt/* || true
    sudo cp -rvL ${src}/* ./mnt
    sudo umount ./mnt
  '';

  sync = syncSimple boot;

  links = {
    run = sync;
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
