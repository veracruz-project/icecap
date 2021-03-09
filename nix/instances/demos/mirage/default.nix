{ mkInstance
, compose, stripElfSplit
, icecapSrcAbsSplit
, bins, mkMirageBinary, deviceTree
, icecapPlat
}:

mkInstance (self: with self; {

  linux = callPackage ./linux {};
  inherit (linux) host realm;

  composition = compose {
    src = ./cdl;
    config = {
      components = {
        fault_handler.image = bins.fault-handler.split;
        timer_server.image = bins.timer-server.split;
        serial_server.image = bins.serial-server.split;

        host_vmm.image = bins.vmm.split;
        host_vm.bootargs = host.bootargs;
        host_vm.kernel = host.linuxImage;
        host_vm.initrd = host.initrd;
        host_vm.dtb = deviceTree.host.${icecapPlat};
        host_vm.set_chosen = true;

        mirage.image = stripElfSplit "${mirageBinary}/bin/mirage.elf";
      };
    };
  };

  mirageLibrary = callPackage ./mirage.nix {};
  mirageBinary = mkMirageBinary mirageLibrary;

})
