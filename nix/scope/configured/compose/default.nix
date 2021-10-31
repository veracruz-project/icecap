{ lib, runCommand
, dtb-helpers
, linuxPkgs
, deviceTree, platUtils, cpioUtils, elfUtils
, icecapPlat
, mkIceDL, mkCapDLLoader
, kernel, elfloader, bins
}:

let
  uBoot = linuxPkgs.icecap.uBoot.host.${icecapPlat};
in

args:

let

  components = lib.fix (self: {

    loader-elf = elfUtils.split "${self.loader}/boot/elfloader";

    loader = elfloader {
      inherit (self) kernel;
      app-elf = self.app-elf.min;
    };

    inherit kernel;

    app-elf = elfUtils.split "${self.app}/bin/capdl-loader.elf";

    app = mkCapDLLoader {
      cdl = "${self.cdl}/icecap.cdl";
      elfs-cpio = cpioUtils.mkFrom "${self.cdl}/links";
    };

    cdl = mkIceDL {
      inherit (self) action config;
    };

    action = "firmware";

    config = {

      num_cores = platUtils.${icecapPlat}.numCores;
      num_realms = 2;
      default_affinity = 1;

      components = {
        idle.image = bins.idle.split;
        fault_handler.image = bins.fault-handler.split;
        timer_server.image = bins.timer-server.split;
        serial_server.image = bins.serial-server.split;
        event_server.image = bins.event-server.split;
        benchmark_server.image = bins.benchmark-server.split;

        resource_server.image = bins.resource-server.split;
        resource_server.heap_size = 128 * 1048576;

        host_vmm.image = bins.host-vmm.split;
        host_vm.kernel = self.u-boot;
        host_vm.dtb = deviceTree.host.${icecapPlat};
      };
    };

    u-boot = "${uBoot}/u-boot.bin";

  } // args);

in with components;
let

  images = {
    loader = components.loader-elf;
    kernel = components.kernel.elf;
    app = components.app-elf;
  };

  cdlImages = lib.mapAttrs'
    (k: v: lib.nameValuePair k v.image)
    (lib.filterAttrs (k: lib.hasAttr "image") components.config.components);

  debugFilesOf = lib.mapAttrs' (k: v: lib.nameValuePair "${k}.elf" v.full);

  debugLinksOf = files: runCommand "links" {} ''
    mkdir $out
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        ln -s ${v} $out/${k}
    '') files)}
  '';

in rec {
  inherit components;
  inherit (components) cdl app loader;

  image = loader-elf.min;

  inherit images cdlImages;

  debugFiles = debugFilesOf images;
  debugLinks = debugLinksOf debugFiles;
  cdlDebugFiles = debugFilesOf cdlImages;
  cdlDebugLinks = debugLinksOf cdlDebugFiles;
  allDebugFiles = debugFilesOf (cdlImages // images);
  allDebugLinks = debugLinksOf allDebugFiles;

  host-dtb = "${cdl}/links/host_vm.dtb";
  host-dts = dtb-helpers.decompileForce host-dtb;

  mkDefaultPayload = args: uBoot.mkDefaultPayload ({ dtb = host-dtb; } // args);
}
