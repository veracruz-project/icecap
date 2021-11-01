# TODO build without CMake

{ lib, runCommand, writeText, linkFarm
, cmake, ninja, rsync
, dtc, libxml2, python3, python3Packages

, seL4EcosystemRepos, cpioUtils
, stdenvBoot

, kernel, libsel4, libcpio
, cmakeConfig
}:

{ kernel, app-elf }:

let

  images = cpioUtils.mkObj {
    symbolName = "_archive_start";
    archive-cpio = cpioUtils.mk [
      { name = "kernel.elf"; path = kernel.elf.min; }
      { name = "kernel.dtb"; path = kernel.dtb; }
      { name = "app.elf"; path = app-elf; }
    ];
  };

  py = runCommand "x.py" {
    nativeBuildInputs = [ python3 ];
  } ''
    install -D -t $out ${seL4EcosystemRepos.seL4_tools.extendInnerSuffix "cmake-tool/helpers"}/*.py ${kernel.patchedSource}/tools/hardware_gen.py
    patchShebangs --build $out
    cp -r ${kernel.patchedSource}/tools/hardware $out
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

in
stdenvBoot.mkDerivation rec {
  name = "elfloader";

  source = seL4EcosystemRepos.seL4_tools.extendInnerSuffix "elfloader-tool";

  buildInputs = [
    libcpio libsel4
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
    images
  ];

  cmakeDir = linkFarm "x" [
    { name = "CMakeLists.txt";
      path = writeText "CMakeLists.txt" ''
        cmake_minimum_required(VERSION 3.13)

        project(elfloader ASM C)

        include(${seL4EcosystemRepos.seL4.extendInnerSuffix "tools/helpers.cmake"})
        include(${seL4EcosystemRepos.seL4.extendInnerSuffix "tools/internal.cmake"})

        set(FOO_ARCHIVE_O ${images} CACHE STRING "")
        set(FOO_ELF_SIFT ${py}/elf_sift.py CACHE STRING "")
        set(FOO_SHOEHORN ${py}/shoehorn.py CACHE STRING "")
        set(FOO_PLATFORM_SIFT ${py}/platform_sift.py CACHE STRING "")
        set(FOO_KERNEL_DTB ${kernel}/boot/kernel.dtb CACHE STRING "")
        set(FOO_KERNEL_TOOLS ${kernel.patchedSource}/tools CACHE STRING "")
        set(FOO_HARDWARE_GEN ${py}/hardware_gen.py CACHE STRING "")
        set(platform_yaml ${kernel}/sel4-aux/platform_gen.yaml CACHE STRING "")

        add_subdirectory(${source} elfloader)
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
    "-DCMAKE_TOOLCHAIN_FILE=${kernel.patchedSource}/gcc.cmake"
  ];

  buildPhase = ''
    ninja elfloader
  '';

  installPhase = ''
    install -D -t $out/boot elfloader/elfloader
  '';

  passthru = {
    inherit kernel app-elf;
  };

}
