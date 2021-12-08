# TODO build without CMake

{ lib, runCommand, writeText, linkFarm
, cmake, ninja, rsync
, dtc, libxml2, python3, python3Packages

, icecapExternalSrc, cpioUtils
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

  cmakeDir = icecapExternalSrc.seL4_tools.extendInnerSuffix "elfloader-tool";

  # TODO
  # cmakeBuildType = "Debug";

  cmakeFlags = [
    "-G" "Ninja"
    "-C" cacheScript

    "-DCROSS_COMPILER_PREFIX=${stdenvBoot.cc.targetPrefix}"
    "-DCMAKE_TOOLCHAIN_FILE=${kernel.patchedSource}/gcc.cmake"

    "-DPYTHON3=python3"
    "-DICECAP_HACK_CMAKE_HELPERS=${icecapExternalSrc.seL4.extendInnerSuffix "tools/helpers.cmake"}"
    "-DICECAP_HACK_CMAKE_INTERNAL=${icecapExternalSrc.seL4.extendInnerSuffix "tools/internal.cmake"}"
    "-DICECAP_HACK_CMAKE_TOOL_HELPERS_DIR=${icecapExternalSrc.seL4_tools.extendInnerSuffix "cmake-tool/helpers"}"
    "-DICECAP_HACK_KERNEL_TOOLS=${icecapExternalSrc.seL4.extendInnerSuffix "tools"}"
    "-DICECAP_HACK_KERNEL_DTB=${kernel}/boot/kernel.dtb"
    "-DICECAP_HACK_ARCHIVE_O=${images}"
    "-Dplatform_yaml=${kernel}/sel4-aux/platform_gen.yaml"
  ];

  buildPhase = ''
    ninja elfloader
  '';

  installPhase = ''
    install -D -t $out/boot elfloader
  '';

  passthru = {
    inherit kernel app-elf;
  };

}
