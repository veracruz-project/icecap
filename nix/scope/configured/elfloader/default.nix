# TODO build without CMake

{ lib, runCommand, writeText, linkFarm
, cmake, ninja, rsync
, dtc, libxml2, python3, python3Packages

, stdenvBoot, repos
, kernel, libsel4, libcpio
, mkCpio, mkCpioObj

, cmakeConfig
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

  configPrefixes = [
    "Elfloader"
  ];

  cacheScript = writeText "config.cmake" ''
    include(${kernel}/sel4-config/kernel.cmake)

    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
      set(${k} ${v.value} CACHE ${v.type} "")
    '') (filterInitConfig cmakeConfig configPrefixes))}
  '';

  filterInitConfig = with lib;
    all: prefixes: filterAttrs (k: v: any (prefix: hasPrefix prefix k) prefixes) all;

  autoconf = linkFarm "autoconf" [
    { name = "include/autoconf.h";
      path = writeText "autoconf.h" ''
        #pragma once
        #include <kernel/gen_config.h>
        #include <elfloader/gen_config.h>
      '';
    }
  ];

in
stdenvBoot.mkDerivation rec {
  name = "elfloader";

  source = repos.rel.seL4_tools "elfloader-tool";

  buildInputs = [
    libcpio kernel
    autoconf
    images
  ];

  nativeBuildInputs = [
    cmake ninja python3Packages.sel4-deps
  ];

  hardeningDisable = [ "all" ]; # TODO

  phases = [ "configurePhase" "buildPhase" "installPhase" "fixupPhase" /* TODO make sure fixupPhase is safe */ ];

  dontStrip = true;
  dontPatchELF = true;

  NIX_CFLAGS_COMPILE = [
    "-D__KERNEL_64__"
    "-Ielfloader/gen_config"
  ];

  NIX_CFLAGS_LINK = [
    "-limages"
  ];

  cmakeDir = linkFarm "x" [
    { name = "CMakeLists.txt";
      path = writeText "CMakeLists.txt" ''
        cmake_minimum_required(VERSION 3.13)

        project(elfloader ASM C)

        include(${repos.rel.seL4 "tools/helpers.cmake"})
        include(${repos.rel.seL4 "tools/internal.cmake"})

        # HACK
        if(DEFINED ENV{NIX_SHELL_SRC})
          set(source $ENV{NIX_SHELL_SRC})
        else()
          set(source ${source})
        endif()

        set(FOO_ARCHIVE_O ${images.archive-obj} CACHE STRING "")
        set(FOO_ELF_SIFT ${py}/elf_sift.py CACHE STRING "")
        set(FOO_SHOEHORN ${py}/shoehorn.py CACHE STRING "")
        set(FOO_PLATFORM_SIFT ${py}/platform_sift.py CACHE STRING "")
        set(FOO_KERNEL_DTB ${kernel}/boot/kernel.dtb CACHE STRING "")
        set(FOO_KERNEL_TOOLS ${kernel.source}/tools CACHE STRING "")
        set(FOO_HARDWARE_GEN ${py}/hardware_gen.py CACHE STRING "")
        set(platform_yaml ${libsel4}/sel4-aux/platform_gen.yaml CACHE STRING "")

        add_subdirectory(''${source} elfloader)

        install(TARGETS elfloader)
      '';
    }
  ];

  # TODO
  cmakeBuildType = "Debug";

  cmakeFlags = [
    "-G" "Ninja"
    "-C" cacheScript
    # TODO
    "-DCROSS_COMPILER_PREFIX=${stdenvBoot.cc.targetPrefix}"
  ];

  buildPhase = ''
    ninja elfloader
  '';

  postInstall = ''
    install -D -t $out/boot elfloader/elfloader
  '';

  passthru = {
    inherit kernel-source kernel-elf kernel-dtb app-elf;
  };

}
