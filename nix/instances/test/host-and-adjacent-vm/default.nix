{ mkInstance, lib
, compose
, icecapSrcAbsSplit
, bins, liboutline
, buildIceCapCrateBin, crateUtils, globalCrates
, deviceTree, icecapPlat, mkFilesObj
, kernel, repos
}:

mkInstance (self: with self; {

  linux = callPackage ./linux.nix {};
  inherit (linux) host guest;

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

        guest_vmm.image = bins.vmm.split;
        guest_vm.bootargs = guest.bootargs;
        guest_vm.kernel = guest.linuxImage;
        guest_vm.initrd = guest.initrd;
        guest_vm.dtb = deviceTree.guest.${icecapPlat};
      };
    };
  };

  # kernel = kernel.override' (attrs: {
  #   source = attrs.source.override' (attrs': {
  #     src = with repos; local.seL4;
  #   });
  # });

})
