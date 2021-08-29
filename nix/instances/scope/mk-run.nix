{ lib
, platUtils
, icecapPlat
, icecap-show-backtrace
}:

{ composition, payload, extraLinks ? {}, icecapPlatArgs ? {}, allDebugFiles }:

platUtils.${icecapPlat}.bundle {
  firmware = composition.image;
  inherit payload;
  platArgs = icecapPlatArgs.${icecapPlat} or {};
  extraLinks = {
    } // lib.mapAttrs' (k: lib.nameValuePair "debug/${k}") ({
        icecap-show-backtrace = "${icecap-show-backtrace.nativeDrv}/bin/show-backtrace";
      } // composition.debugFiles // lib.optionalAttrs allDebugFiles composition.cdlDebugFiles
    ) // extraLinks;
}
