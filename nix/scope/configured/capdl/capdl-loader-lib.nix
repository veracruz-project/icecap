{ lib, libs, repos
, linkFarm, writeText
, libsel4
}:

libs.mk {
  name = "capdl-loader-lib";
  root = {
    store = repos.rel.capdl "capdl-loader-app";
    # store = repos.forceLocal.rel.capdl "capdl-loader-app";
  };
  propagatedBuildInputs = with libs; [
    libsel4
    icecap-autoconf
    icecap-runtime-root
    icecap-pure
    icecap-utils
    cpio
    capdl-support-hack
  ];
  extraCFlagsCompile = [
    # "-Wno-error=unused-variable"
    # "-Wno-error=unused-function"
    # "-Wno-error=unused-but-set-variable"
    "-Wno-unused-variable"
    "-Wno-unused-function"
    "-Wno-unused-but-set-variable"
  ];
  extra.CONFIG = linkFarm "config" [
    { name = "capdl_loader_app/gen_config.h";
      path = writeText "gen_config.h" ''
        #pragma once

        #define CONFIG_CAPDL_LOADER_CALLING_CONVENTION standard
        #define CONFIG_CAPDL_LOADER_CC_STANDARD 1
        #define CONFIG_CAPDL_LOADER_MAX_OBJECTS 10000 // is this enough?
        #define CONFIG_CAPDL_LOADER_FILLS_PER_FRAME 1 // is this enough?
        // #define CONFIG_CAPDL_LOADER_PRINT_UNTYPEDS 1
      '';
    }
  ];
}

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
