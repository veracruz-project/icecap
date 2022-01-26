{ mkHypervisorIceDL, mkDynDLSpec
, icecapPlat, icecapSrc
}:

{ script, config }:

let
  ddl = mkHypervisorIceDL {
    script = icecapSrc.absolute script;
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
