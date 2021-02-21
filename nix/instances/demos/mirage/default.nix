{ mkInstance
, icecapSrcAbsSplit
, libs, bins, liboutline
, buildIceCapCrateBin, crateUtils, globalCrates
, mkMirageBinary, splitDebug, deviceTree, icecapPlat
}:

mkInstance (self: with self; {

  linux = callPackage ./linux {};
  inherit (linux) host realm;

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

      mirage.image = splitDebug "${mirageBinary}/bin/mirage.elf";
    };
  };

  mirageLibrary = callPackage ./mirage.nix {};
  mirageBinary = mkMirageBinary mirageLibrary;

  src = ./cdl;

})
