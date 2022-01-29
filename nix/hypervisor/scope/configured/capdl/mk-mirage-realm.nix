{ deviceTree, hypervisorComponents
, mkHypervisorIceDL, mkDynDLSpec, mkMirageBinary
, icecapPlat
, globalCrates
, elfUtils
}:

{ mirageLibrary, passthru }:

let
  mirageBinary = mkMirageBinary {
    inherit mirageLibrary;
    crate = globalCrates.hypervisor-mirage;
  };

  ddl = mkHypervisorIceDL {
    subcommand = "mirage-realm";
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        mirage.image = elfUtils.split "${mirageBinary}/bin/${mirageBinary.crate.name}.elf";
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
