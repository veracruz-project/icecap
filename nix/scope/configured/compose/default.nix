{ lib, runCommand
, deviceTree, uBoot
, kernel, elfloader, mkCapDLLoader, bins
, mkCpioFrom, mkIceDL, dtb-helpers
, stripElf, stripElfSplit
, icecapPlat
}:

let
  _u-boot = "${uBoot.${icecapPlat}}/u-boot.bin";
  _kernel = kernel;
in

args:

let

  components = lib.fix (self: with self; {

    loader-elf = stripElfSplit "${loader}/bin/elfloader";

    loader = elfloader {
      inherit kernel-dtb;
      kernel-elf = kernel-elf.min;
      app-elf = app-elf.min;
    };

    kernel-dtb = "${kernel}/boot/kernel.dtb";
    kernel-elf = stripElfSplit "${kernel}/boot/kernel.elf";
    app-elf = stripElfSplit "${app}/bin/capdl-loader.elf";

    app = mkCapDLLoader {
      cdl = "${cdl}/icecap.cdl";
      elfs-cpio = mkCpioFrom "${cdl}/links";
    };

    cdl = mkIceDL {
      inherit src config;
    };

    src = ./cdl;

    config = {
      components = {
        fault_handler.image = bins.fault-handler.split;
        timer_server.image = bins.timer-server.split;
        serial_server.image = bins.serial-server.split;

        caput.image = bins.caput.split;
        caput.heap_size = 128 * 1048576;

        host_vmm.image = bins.vmm.split;
        host_vm.kernel = u-boot;
        host_vm.dtb = deviceTree.host.${icecapPlat};
      };
    };

    u-boot = _u-boot;
    kernel = _kernel;

  } // args);

in with components;
let

  images = {
    loader = loader-elf;
    kernel = kernel-elf;
    app = app-elf;
  };
  
  cdlImages = lib.mapAttrs'
    (k: v: lib.nameValuePair k v.image)
    (lib.filterAttrs (k: lib.hasAttr "image") config.components);

  debugFilesOf = lib.mapAttrs' (k: v: lib.nameValuePair "${k}.elf" v.full);

  debugLinksOf = files: runCommand "links" {} ''
    mkdir $out
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
        ln -s ${v} $out/${k}
    '') files)}
  '';

in rec {
  inherit cdl app loader;
  inherit components;

  image = loader-elf.min;

  inherit images cdlImages;

  debugFiles = debugFilesOf images;
  debugLinks = debugLinksOf debugFiles;
  cdlDebugFiles = debugFilesOf cdlImages;
  cdlDebugLinks = debugLinksOf cdlDebugFiles;
  allDebugFiles = debugFilesOf (cdlImages // images);
  allDebugLinks = debugLinksOf allDebugFiles;

  host-dtb = "${cdl}/links/host_vm.dtb";
  host-dts = dtb-helpers.decompile host-dtb;
}
