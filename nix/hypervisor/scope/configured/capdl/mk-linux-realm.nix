{ deviceTree, hypervisorComponents
, mkHypervisorIceDL, mkDynDLSpec
, icecapPlat
}:

{ kernel, initramfs ? null, bootargs ? [] }:

let
  ddl = mkHypervisorIceDL {
    subcommand = "linux-realm";
    config = {
      realm_id = 0;
      num_cores = 1;
      components = {
        fault_handler.image = hypervisorComponents.fault-handler.split;
        realm_vmm.image = hypervisorComponents.realm-vmm.split;
        realm_vm.bootargs = bootargs;
        realm_vm.kernel = kernel;
        realm_vm.initrd = initramfs;
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
