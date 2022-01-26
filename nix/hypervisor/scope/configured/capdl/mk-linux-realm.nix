{ deviceTree, hypervisorComponents
, mkIceDL, mkDynDLSpec
, icecapPlat

, icecap-append-devices
, icecap-serialize-builtin-config
, icecap-serialize-event-server-out-index
}:

{ kernel, initramfs ? null, bootargs ? [] }:

let
  ddl = mkIceDL {
    action.whole = "bash -c 'python3 -m icecap_hypervisor.cli linux-realm $CONFIG -o $OUT_DIR'";
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
    inherit ddl;
  };
}
