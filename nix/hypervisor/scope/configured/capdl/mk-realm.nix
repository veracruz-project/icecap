{ mkIceDL, mkDynDLSpec
, icecapPlat, icecapSrc

, icecap-append-devices
, icecap-serialize-builtin-config
, icecap-serialize-event-server-out-index
}:

{ script, config }:

let
  ddl = mkIceDL {
    action.script = icecapSrc.absoluteSplit script;
    config = {
      # TODO
      hack_realm_affinity = 1;
    } // config;
    extraNativeBuildInputs = [
      icecap-append-devices
      icecap-serialize-builtin-config
      icecap-serialize-event-server-out-index
    ];
  };

in
mkDynDLSpec {
  cdl = "${ddl}/icecap.cdl";
  root = "${ddl}/links";
  extraPassthru = {
    inherit ddl;
  };
}
