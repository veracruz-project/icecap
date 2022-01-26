{ compose, makeOverridable'
, icecapSrc
, lib, runCommand
, callPackage
, dtbHelpers
, linuxPkgs
, deviceTree, platUtils, cpioUtils, elfUtils
, icecapPlat
, mkIceDL, mkCapDLLoader
, kernel, elfloader, hypervisorComponents

, icecap-append-devices
, icecap-serialize-builtin-config
, icecap-serialize-event-server-out-index
}:



let
  uBoot = linuxPkgs.icecap.uBoot.host.${icecapPlat};
in



makeOverridable' compose (rec {

  action.whole = "bash -c 'python3 -m icecap_hypervisor.cli firmware $CONFIG -o $OUT_DIR'";

  config = {

    num_cores = platUtils.${icecapPlat}.numCores;
    num_realms = 2;
    default_affinity = 1;

    hack_realm_affinity = 1;

    components = {
      idle.image = hypervisorComponents.idle.split;
      fault_handler.image = hypervisorComponents.fault-handler.split;
      timer_server.image = hypervisorComponents.timer-server.split;
      serial_server.image = hypervisorComponents.serial-server.split;
      event_server.image = hypervisorComponents.event-server.split;
      benchmark_server.image = hypervisorComponents.benchmark-server.split;

      resource_server.image = hypervisorComponents.resource-server.split;
      resource_server.heap_size = 128 * 1048576; # HACK

      host_vmm.image = hypervisorComponents.host-vmm.split;
      host_vm.kernel = u-boot;
      host_vm.dtb = deviceTree.host.${icecapPlat}.dtb;
    };
  };

  u-boot = "${uBoot}/u-boot.bin";

  extra = self: {

    host-dtb = "${self.attrs.cdl}/links/host_vm.dtb";
    host-dts = dtbHelpers.decompileForce self.host-dtb;

    mkDefaultPayload = args: uBoot.mkDefaultPayload ({ dtb = self.host-dtb; } // args);
  };

  extraNativeBuildInputs = [
    icecap-append-devices
    icecap-serialize-builtin-config
    icecap-serialize-event-server-out-index
  ];

})
