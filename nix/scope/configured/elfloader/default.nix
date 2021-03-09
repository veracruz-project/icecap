# TODO build without CMake

{ stdenvBoot, repos
, kernel, libsel4
, mkCpio, mkCpioObj

, lib, runCommand
, dtc, python3, python3Packages

, runCMake, libcpio
}:

{ app-elf, kernel-elf, kernel-dtb, kernel-source ? kernel.source }:

let

  images = mkCpioObj {
    symbolName = "_archive_start";
    libName = "images";
    archive-cpio = mkCpio [
      { path = "kernel.elf"; contents = kernel-elf; }
      { path = "kernel.dtb"; contents = kernel-dtb; }
      { path = "app.elf"; contents = app-elf; }
    ];
  };

  py = runCommand "x.py" {
    nativeBuildInputs = [ python3 ];
  } ''
    install -D -t $out ${repos.rel.seL4_tools "cmake-tool/helpers"}/*.py ${kernel.source}/tools/hardware_gen.py
    patchShebangs --build $out
    cp -r ${kernel-source}/tools/hardware $out
  '';

in
runCMake stdenvBoot rec {
  baseName = "elfloader";
  name = "sel4-elfloader";

  source = repos.rel.seL4_tools "elfloader-tool";

  extraNativeBuildInputs = [
    dtc python3Packages.sel4-deps
  ];

  propagatedBuildInputs = [
    libcpio
    libsel4
    images
  ];

  configPrefixes = [
    "Elfloader"
  ];

  extraCMakeBody = ''
    set(FOO_ARCHIVE_O ${images.archive-obj} CACHE STRING "")
    set(FOO_ELF_SIFT ${py}/elf_sift.py CACHE STRING "")
    set(FOO_SHOEHORN ${py}/shoehorn.py CACHE STRING "")
    set(FOO_PLATFORM_SIFT ${py}/platform_sift.py CACHE STRING "")
    set(FOO_KERNEL_DTB ${kernel}/boot/kernel.dtb CACHE STRING "")
    set(FOO_KERNEL_TOOLS ${kernel.source}/tools CACHE STRING "")
    set(FOO_HARDWARE_GEN ${py}/hardware_gen.py CACHE STRING "")
    set(platform_yaml ${libsel4}/sel4-aux/platform_gen.yaml CACHE STRING "")
  '';

  extraPostInstall = ''
    $STRIP -s $out/bin/elfloader
  '';

  passthru = {
    inherit kernel-source kernel-elf kernel-dtb app-elf;
  };

}
