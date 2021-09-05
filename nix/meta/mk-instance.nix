{ lib, pkgs }:

{ configured }:

let
  inherit (configured) icecapPlat;
in

f: lib.fix (self:

  let
    attrs = f self;
  in

  with self; {

    inherit configured;

    composition = configured.icecapFirmware;
    payload = {};
    allDebugFiles = true;
    extraLinks = {};
    icecapPlatArgs = {};

    run = pkgs.none.icecap.platUtils.${icecapPlat}.bundle {
      firmware = composition.image;
      inherit payload;
      platArgs = icecapPlatArgs.${icecapPlat} or {};
      extraLinks = lib.mapAttrs' (k: lib.nameValuePair "debug/${k}") ({
          icecap-show-backtrace = "${pkgs.dev.icecap.icecap-show-backtrace}/bin/show-backtrace";
        } // composition.debugFiles // lib.optionalAttrs allDebugFiles composition.cdlDebugFiles
      ) // extraLinks;
    };

  } // attrs
)
