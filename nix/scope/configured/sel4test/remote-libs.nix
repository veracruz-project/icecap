{ repos, runCMakeToken, mkFakeConfig
, python3, protobuf
, muslc, libsel4runtime
, nanopbExternal
}:

rec {

  # util_libs

  libcpio = runCMakeToken rec {
    baseName = "cpio";
    source = repos.relLib.util_libs baseName;
  };

  libelf = runCMakeToken rec {
    baseName = "elf";
    source = repos.relLib.util_libs baseName;
    extraPropagatedBuildInputs = [
      muslc
    ];
  };

  libfdt = runCMakeToken rec {
    baseName = "fdt";
    source = repos.relLib.util_libs baseName;
    extraPropagatedBuildInputs = [
      muslc
    ];
    extraPostInstall = ''
      cp ${source}/*.h $out/include
    '';
  };

  libplatsupport = runCMakeToken rec {
    baseName = "platsupport";
    source = repos.relLib.util_libs baseName;
    extraPropagatedBuildInputs = [
      libutils
      libfdt
    ];
    extraCFlagsCompile = [
      "-Wall"
    ];
    configPrefixes = [
      "LibPlatSupport"
    ];
  };

  libutils = runCMakeToken rec {
    baseName = "utils";
    source = repos.relLib.util_libs baseName;
    extraPropagatedBuildInputs = [
      muslc
    ];
    configPrefixes = [
      "LibUtils"
    ];
  };

  # seL4_libs

  libsel4allocman = runCMakeToken rec {
    baseName = "sel4allocman";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libsel4vka
      libsel4utils
      libsel4vspace
    ];
  };

  libsel4debug = runCMakeToken rec {
    baseName = "sel4debug";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libutils
    ];
    configPrefixes = [
      "LibSel4Debug"
    ];
  };

  libsel4muslcsys = runCMakeToken rec {
    baseName = "sel4muslcsys";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libcpio
      libutils
      libsel4utils
    ];
    configPrefixes = [
      "LibSel4MuslcSys"
    ];
  };

  libsel4platsupport = runCMakeToken rec {
    baseName = "sel4platsupport";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libsel4runtime
      libsel4simple
      libutils
      libsel4vspace
      libplatsupport
      libsel4simple-default
    ];
    configPrefixes = [
      "LibSel4PlatSupport"
      "LibSel4Support"
    ];
    extraBuildInputs = [
      # TODO circular dependencies upstream
      (mkFakeConfig "sel4utils" {
        SEL4UTILS_STACK_SIZE = "65536";
      })
      (mkFakeConfig "sel4muslcsys" {
        # LIB_SEL4_MUSLC_SYS_ARCH_PUTCHAR_WEAK
      })
    ];
  };

  libsel4serialserver = runCMakeToken rec {
    baseName = "sel4serialserver";
    source = repos.relLib.seL4_libs baseName;
    targets = [ baseName "${baseName}_tests" ];
    extraPropagatedBuildInputs = [
      libsel4vspace
      libsel4simple
      libsel4platsupport
      libutils
      libsel4utils
      libsel4vka
      libsel4test
    ];
    configPrefixes = [
      "LibSel4Serial"
    ];
    selfGen = [
      baseName
    ];
  };

  libsel4simple-default = runCMakeToken rec {
    baseName = "sel4simple-default";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libsel4simple
      libsel4debug
      libsel4vspace
    ];
  };

  libsel4simple = runCMakeToken rec {
    baseName = "sel4simple";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libutils
      libsel4vka
    ];
  };

  libsel4sync = runCMakeToken rec {
    baseName = "sel4sync";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libsel4vka
      libsel4platsupport
      libutils
    ];
  };

  libsel4test = runCMakeToken rec {
    baseName = "sel4test";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libutils
      libsel4vka
      libsel4vspace
      libsel4platsupport
      libsel4rpc
      libsel4sync
      libsel4simple
      libsel4utils
    ];
    configPrefixes = [
      "LibSel4Test"
    ];
  };

  libsel4utils = runCMakeToken rec {
    baseName = "sel4utils";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libsel4vspace
      libsel4simple
      libsel4platsupport
      libelf
      libcpio
    ];
    configPrefixes = [
      "LibSel4Utils"
    ];
  };

  libsel4vka = runCMakeToken rec {
    baseName = "sel4vka";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libutils
    ];
    configPrefixes = [
      "LibVKA"
    ];
  };

  libsel4vspace = runCMakeToken rec {
    baseName = "sel4vspace";
    source = repos.relLib.seL4_libs baseName;
    extraPropagatedBuildInputs = [
      libsel4vka
    ];
    extraBuildInputs = [
      # TODO circular dependencies upstream
      (mkFakeConfig "sel4utils" {
        SEL4UTILS_STACK_SIZE = "65536";
      })
    ];
  };

  # seL4_projects_libs

  libsel4nanopb = runCMakeToken rec {
    baseName = "sel4nanopb";
    source = repos.relLib.seL4_projects_libs baseName;
    extraPropagatedBuildInputs = [
      libutils
      nanopbExternal
    ];
    configPrefixes = [
      # TODO
      # "LibNanopb"
    ];
  };

  libsel4rpc = runCMakeToken rec {
    baseName = "sel4rpc";
    source = repos.relLib.seL4_projects_libs baseName;

    extraCMakeBody = ''
      set(NANOPB_SRC_ROOT_FOLDER ${nanopbExternal.src})
      include(${nanopbExternal.cmake})
    '';

    extraNativeBuildInputs = [
      python3
      protobuf
      nanopbExternal
    ];

    extraPropagatedBuildInputs = [
      libutils
      libsel4nanopb
      libsel4utils
      libsel4vka
    ];

    extraPostInstall = ''
      chmod -R +w $out/include
      cp x/rpc.pb.h $out/include
    '';
  };

  # misc

  libsel4testsupport = runCMakeToken rec {
    baseName = "sel4testsupport";
    source = repos.relLib.sel4test baseName;
    extraPropagatedBuildInputs = [
      libutils
      libsel4test
      libsel4serialserver
    ];
  };
}
