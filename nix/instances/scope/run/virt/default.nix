{ lib, writeScript, runCommand, runPkgs
, show-backtrace
, virtUtils
, icecapExtraConfig
}:

let
  basicScript = { kernel, extraArgs ? [] }:
    writeScript "run.sh" (with runPkgs; with virtUtils; ''
      #!${runtimeShell}
      debug=
      if [ "$1" = "d" ]; then
        debug="${join debugArgs}"
      fi
      exec ${cmdPrefix} \
        -d unimp,guest_errors \
        ${join extraArgs} \
        $debug \
        -kernel ${kernel}
    '');

in

{ composition, payload, extraLinks ? {}, icecapPlatArgs ? {}, allDebugFiles }:

let

  inherit (composition) image;

  run = basicScript {
    kernel = image;
  };

  links = {
    inherit run image;
    "show-backtrace" = "${show-backtrace.nativeDrv}/bin/show-backtrace";
  } // composition.debugFiles
    // lib.optionalAttrs allDebugFiles composition.cdlDebugFiles
    // extraLinks;

in
runCommand "run" {} ''
  mkdir $out
  ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
    ln -s ${v} $out/${k}
  '') links)}

  mkdir $out/payload
  ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
    ln -s ${v} $out/payload/${k}
  '') payload)}
''
