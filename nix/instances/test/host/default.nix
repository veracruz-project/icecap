{ mkInstance, lib
, compose
, icecapSrcAbsSplit
, bins
, deviceTree, icecapPlat
}:

mkInstance (self: with self; {

  linux = callPackage ./linux.nix {};
  inherit (linux) host;

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
      };
    };
  };

  # kernel = kernel.override' (attrs: {
  #   source = attrs.source.override' (attrs': {
  #     src = with repos; local.seL4;
  #   });
  # });

})
