{ deviceTree, bins
, mkIceDL, mkDynDLSpec
, icecapPlat
}:

{ kernel, initrd ? null, bootargs ? [] }:

let
  ddl = mkIceDL {
    src = ./ddl;
    config = {
      components = {
        fault_handler.image = bins.fault-handler.split;
        realm_vmm.image = bins.realm-vmm.split;
        realm_vm.bootargs = bootargs;
        realm_vm.kernel = kernel;
        realm_vm.initrd = initrd;
        realm_vm.dtb = deviceTree.guest.${icecapPlat};
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
