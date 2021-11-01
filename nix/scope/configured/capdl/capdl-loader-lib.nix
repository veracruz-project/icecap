{ lib, linkFarm, writeText, runCommand
, python3, python3Packages
, seL4EcosystemRepos
, kernel, libsel4
, libs, icecapSrc
}:

let

  py = runCommand "x.py" {
    nativeBuildInputs = [ python3 ];
  } ''
    install -D -t $out ${seL4EcosystemRepos.seL4_tools.extendInnerSuffix "cmake-tool/helpers"}/*.py ${kernel.patchedSource}/tools/hardware_gen.py
    patchShebangs --build $out
    cp -r ${kernel.patchedSource}/tools/hardware $out
  '';

  platformInfo = linkFarm "platform-info" [
    { name = "include/capdl_loader_app/platform_info.h";
      path = runCommand "platform_info.h" {
        nativeBuildInputs = [ python3 python3Packages.sel4-deps ];
      } ''
        ${py}/platform_sift.py --emit-c-syntax ${libsel4}/sel4-aux/platform_gen.yaml > $out
      '';
    }
  ];

in
libs.mk {
  name = "capdl-loader-lib";
  root = icecapSrc.relativeSplit "c/boot/capdl-loader-core";
  buildInputs = [
    platformInfo
  ];
  propagatedBuildInputs = [
    libsel4
    libs.icecap-runtime-root
    libs.icecap-pure
    libs.icecap-utils
    libs.cpio
    libs.capdl-support-hack
  ];
  extraCFlagsCompile = [
    "-Wno-unused-variable"
    "-Wno-unused-function"
    "-Wno-unused-but-set-variable"
    # TODO
    # "-Wno-error=unused-variable"
    # "-Wno-error=unused-function"
    # "-Wno-error=unused-but-set-variable"
  ];
  extra.CAPDL_LOADER_EXTERNAL_SOURCE = seL4EcosystemRepos.capdl.extendInnerSuffix "capdl-loader-app";
  extra.CAPDL_LOADER_CONFIG_IN_H = writeText "config_in.h" ''
    #pragma once
    #define CONFIG_CAPDL_LOADER_MAX_OBJECTS 10000
  '';
  passthru = {
    x = platformInfo;
  };
}

# TODO
# CapDLLoaderCallingConvention-STRINGS:INTERNAL=standard;registers
# CapDLLoaderCallingConvention:STRING=standard
# CapDLLoaderCallingConventionRegisters:INTERNAL=OFF
# CapDLLoaderCallingConventionStandard:INTERNAL=ON
# CapDLLoaderCallingConvention_all_strings:INTERNAL=standard;registers
# CapDLLoaderFillsPerFrame:STRING=1
# CapDLLoaderMaxObjects:STRING=90000
# CapDLLoaderPrintCapDLObjects:BOOL=OFF
# CapDLLoaderPrintDeviceInfo:BOOL=OFF
# CapDLLoaderPrintUntypeds:BOOL=OFF
# CapDLLoaderStaticAlloc:BOOL=OFF
# CapDLLoaderWriteablePages:BOOL=OFF
