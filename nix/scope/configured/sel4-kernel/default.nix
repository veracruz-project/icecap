{ lib, writeText, runCommand, linkFarm
, cmake, ninja, rsync
, dtc, libxml2, python3, python3Packages

, dtb-helpers
, patchSrc, virtUtils, raspbian

, stdenvBoot, repos, makeOverridable'

, cmakeConfig
, icecapPlat
}:

let

  dts = {

    virt = with dtb-helpers; decompile virtUtils.dtb;

    rpi4 = with dtb-helpers; decompile (applyOverlays "${raspbian.latest.boot}/bcm2711-rpi-4-b.dtb" [
      (compileOverlay (writeText "dtso" ''
        /dts-v1/;
        / {
          fragment@0 {
            target-path = "/soc/gic400@40041000"; /* TODO ? */
            __overlay__ {
              interrupts = <0x1 0x9 0xf04>;
            };
          };
          fragment@1 {
            target-path = "/soc";
            __overlay__ {
              timer@7e003000 {
                compatible = "brcm,bcm2835-system-timer";
                reg = <0x7e003000 0x1000>;
                clock-frequency = <0xf4240>;
                interrupts = <0x0 0x40 0x4 0x0 0x41 0x4 0x0 0x42 0x4 0x0 0x43 0x4>;
              };
            };
          };
        };
      ''))

      # "${raspbian.latest.boot}/overlays/pi3-disable-bt.dtbo"
    ]);

  }.${icecapPlat};

  _source = makeOverridable' patchSrc {
    name = "sel4-kernel-source";
    src = repos.clean.seL4;
    nativeBuildInputs = [ python3 ];

    postPatch = ''
      # patchShebangs can't handle env -S
      rm configs/*_verified.cmake

      patchShebangs --build .
      cp ${dts} tools/dts/${cmakeConfig.KernelPlatform.value}.dts
    '';
  };

  configPrefixes = [
    "Kernel"
    "LibSel4"
    "HardwareDebugAPI"
  ];

  extraConfig = ''
    include(${repos.clean.seL4}/configs/seL4Config.cmake)
  '';

  cacheScript = writeText "config.cmake" ''
    ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
      set(${k} ${v.value} CACHE ${v.type} "")
    '') (filterInitConfig cmakeConfig configPrefixes))}

    ${extraConfig}
  '';

  filterInitConfig = with lib;
    all: prefixes: filterAttrs (k: v: any (prefix: hasPrefix prefix k) prefixes) all;

in
makeOverridable' ({ source }: stdenvBoot.mkDerivation rec {
  name = "sel4";

  nativeBuildInputs = [
    cmake ninja rsync
    dtc libxml2
    python3Packages.sel4-deps
  ];

  phases = [
    "configurePhase" "buildPhase" "installPhase"
    # would fixupPhase be safe and beneficial?
  ];

  cmakeDir = linkFarm "x" [
    { name = "CMakeLists.txt";
      path = writeText "CMakeLists.txt" ''
        cmake_minimum_required(VERSION 3.13)
        project(seL4 ASM C)
        add_subdirectory(${source} kernel)
        add_subdirectory(${source}/libsel4 libsel4)
        install(TARGETS sel4 ARCHIVE DESTINATION lib)
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
    ninja kernel.elf kernel/kernel.dtb sel4
  '';

  postInstall = ''
    install -D -t $out/boot kernel/kernel.elf kernel/kernel.dtb
    install -D -t $out/lib staging/lib/libsel4.a
    install -D -t $out/sel4-aux kernel/gen_headers/plat/machine/platform_gen.yaml

    mkdir -p $out/include

    includePrefixes="${lib.concatStringsSep " " [
      "libsel4" "${source}/libsel4"
    ]}"

    includeSuffixes="${lib.concatStringsSep " " [
      "include"
      "arch_include/arm"
      "sel4_arch_include/aarch64"
      "sel4_plat_include/${cmakeConfig.KernelPlatform.value}"
      "mode_include/64"
    ]}"

    for p in $includePrefixes; do
      for s in $includeSuffixes; do
        if [ -d $p/$s ]; then
          echo "installing headers from $p/$s"
          rsync -a $p/$s/ $out/include/
        fi
      done
    done

    rsync -a kernel/gen_config/ $out/include/ # is this necessary?
    rsync -a libsel4/gen_config/ $out/include/

    # HACK for access to generated source files during debugging
    mkdir -p $out/debug-aux/src
    cp -r kernel libsel4 $out/debug-aux/src

    # HACK propagate config for sel4test

    $AR r $out/lib/libsel4_autoconf.a

    mkdir -p $out/sel4-config
    sed -n '/^\([A-Za-z0-9][^:]*\):\([^=]*\)=\(.*\)$/p' CMakeCache.txt \
      | (grep -e '$.^' ${lib.concatMapStringsSep " " (prefix: "-e ^${prefix}") configPrefixes} || true) \
      | sort \
      | tee $out/sel4-config/kernel.txt \
      | sed 's/^\([^:]*\):\([^=]*\)=\(.*\)$/set(\1 "\3" CACHE \2 "")/' \
      > $out/sel4-config/kernel.cmake

    cat ${writeText "x" extraConfig} >> $out/sel4-config/kernel.cmake
  '';

  passthru = {
    inherit dts source;
    providesLibs = [ "sel4" ]; # HACK for sel4test
  };

}) {
  source = _source;
}
