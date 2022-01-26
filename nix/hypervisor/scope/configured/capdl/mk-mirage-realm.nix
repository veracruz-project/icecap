{ deviceTree, hypervisorComponents
, mkIceDL, mkDynDLSpec, mkMirageBinary
, icecapPlat
, elfUtils

, icecap-append-devices
, icecap-serialize-builtin-config
, icecap-serialize-event-server-out-index
}:

{ mirageLibrary, passthru }:

let
  mirageBinary = mkMirageBinary mirageLibrary;

  ddl = mkIceDL {
    action.whole = "bash -c 'python3 -m icecap_hypervisor.cli mirage-realm $CONFIG -o $OUT_DIR'";
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        mirage.image = elfUtils.split "${mirageBinary}/bin/mirage.elf";
        mirage.passthru = passthru;
      };
      # TODO
      hack_realm_affinity = 1;
    };
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
    inherit ddl mirageBinary;
  };
}
