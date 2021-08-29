{ lib, pkgs }:

let

  mkInstance = configured:
  
    let
      inherit (configured) icecapPlat;
      inherit (pkgs.none.icecap) platUtils;
      inherit (pkgs.none.buildPackages.icecap) icecap-show-backtrace;
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

        run = platUtils.${icecapPlat}.bundle {
          firmware = composition.image;
          inherit payload;
          platArgs = icecapPlatArgs.${icecapPlat} or {};
          extraLinks = lib.mapAttrs' (k: lib.nameValuePair "debug/${k}") ({
              icecap-show-backtrace = "${icecap-show-backtrace}/bin/show-backtrace";
            } // composition.debugFiles // lib.optionalAttrs allDebugFiles composition.cdlDebugFiles
          ) // extraLinks;
        };

      } // attrs
    );

  tests = {
    realm-vm = ./realm-vm;
    firecracker = ./firecracker;
  };

in

lib.flip lib.mapAttrs tests (_: path:
  lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    configured.callPackage path {
      mkInstance = mkInstance configured;
    }
  )
)
