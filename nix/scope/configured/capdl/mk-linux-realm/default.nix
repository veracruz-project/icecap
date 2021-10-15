{ deviceTree, bins
, mkIceDL, mkDynDLSpec
, icecapPlat
}:

{ kernel, initrd ? null, bootargs ? [] }:

let
  ddl = mkIceDL {
    src = ./ddl;
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        fault_handler.image = bins.fault-handler.split;
        realm_vmm.image = bins.realm-vmm.split;
        realm_vm.bootargs = bootargs;
        realm_vm.kernel = kernel;
        realm_vm.initrd = initrd;
        realm_vm.dtb = deviceTree.realm.${icecapPlat};
      };
    };
  };

in
mkDynDLSpec {
  cdl = "${ddl}/icecap.cdl";
  root = "${ddl}/links";
  extraPassthru = {
    inherit ddl;
  };
}
