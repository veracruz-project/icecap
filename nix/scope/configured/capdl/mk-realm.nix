{ mkIceDL, mkDynDLSpec
, icecapPlat, icecapSrc
}:

{ script, config }:

let
  ddl = mkIceDL {
    action.script = icecapSrc.absoluteSplit script;
    inherit config;
  };

in
mkDynDLSpec {
  cdl = "${ddl}/icecap.cdl";
  root = "${ddl}/links";
  extraPassthru = {
    inherit ddl;
  };
}
