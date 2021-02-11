{ mkInstance
, icecapSrcAbsSplit
, buildIceCapCrateBin, crateUtils, globalCrates
, deviceTree, bins
, icecapPlat
, mkIceDL, mkDynDLSpec
}:

mkInstance (self: with self; {

  linux = callPackage ./linux {};
  inherit (linux) host realm;

  config = {
    components = {
      fault_handler.image = bins.fault-handler.split;
      timer_server.image = bins.timer-server.split;
      serial_server.image = bins.serial-server.split;

      caput.image = bins.caput.split;
      caput.heap_size = 128 * 1048576;

      host_vmm.image = bins.vmm.split;
      host_vm.bootargs = host.bootargs;
      host_vm.kernel = host.linuxImage;
      host_vm.initrd = host.initrd;
      host_vm.dtb = deviceTree.host.${icecapPlat};
    };
  };

  ddl = mkIceDL {
    src = ./ddl;
    config = {
      components = {
        realm_vmm.image = bins.vmm.split;
        realm_vm.bootargs = realm.bootargs;
        realm_vm.kernel = realm.linuxImage;
        realm_vm.initrd = realm.initrd;
        realm_vm.dtb = deviceTree.guest;
      };
    };
  };

  spec = mkDynDLSpec {
    cdl = "${ddl}/icecap.cdl";
    root = "${ddl}/links";
  };

  src = ./cdl;

})
