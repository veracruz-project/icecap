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

    composition = null;
    payload = {};
    extraLinks = {};
    icecapPlatArgs = {};

    run = pkgs.none.icecap.platUtils.${icecapPlat}.bundle {
      inherit (composition) image;
      inherit payload;
      platArgs = icecapPlatArgs.${icecapPlat} or {};
      extraLinks = {
        composition = composition.display;
        "debug/icecap-show-backtrace" = "${pkgs.dev.icecap.icecap-show-backtrace}/bin/icecap-show-backtrace";
      } // extraLinks;
    };

  } // attrs
)
