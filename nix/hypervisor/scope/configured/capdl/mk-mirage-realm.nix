{ deviceTree, hypervisorComponents
, mkHypervisorIceDL, mkDynDLSpec, mkMirageBinary
, icecapPlat
, elfUtils
}:

{ mirageLibrary, passthru }:

let
  mirageBinary = mkMirageBinary mirageLibrary;

  ddl = mkHypervisorIceDL {
    subcommand = "mirage-realm";
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        mirage.image = elfUtils.split "${mirageBinary}/bin/mirage.elf";
        mirage.passthru = passthru;
      };
    };
  };

in
mkDynDLSpec {
  cdl = "${ddl}/icecap.cdl";
  root = "${ddl}/links";
  extraPassthru = {
    inherit ddl mirageBinary;
  };
}
